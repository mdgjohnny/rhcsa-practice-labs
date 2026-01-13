#!/usr/bin/env python3
"""IMPORTANT: eventlet monkey-patching must happen FIRST."""
import eventlet
eventlet.monkey_patch()

"""
RHCSA Practice Labs API with WebSocket support.

This is a wrapper around the main Flask app that adds Socket.IO support
for the web terminal functionality.

Cloud Management Best Practices:
- Graceful shutdown handler for SIGTERM/SIGINT
- Startup reconciliation for orphaned resources
- VM health checks before marking sessions ready
- Terraform state locking
- SSH key encryption at rest
"""

import atexit
import logging
import os
import signal
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from flask import jsonify, request
from flask_socketio import SocketIO
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

# Import the main Flask app
from app import app, DEBUG, LOG_LEVEL, logger

# Initialize rate limiter
limiter = Limiter(
    key_func=get_remote_address,
    app=app,
    default_limits=["10000 per day", "2000 per hour"],
    storage_uri="memory://",
)

# Initialize Socket.IO with eventlet async mode
socketio = SocketIO(
    app,
    cors_allowed_origins="*",
    async_mode="eventlet",
    logger=DEBUG,
    engineio_logger=DEBUG,
    ping_timeout=60,
    ping_interval=25
)

BASE_DIR = Path(__file__).parent.parent

# Initialize session manager if OCI is configured
from oci_manager import SessionManager, SessionState
import json

# Check for static VM configuration (reuse existing VMs)
static_vms_config = None
static_vms_path = BASE_DIR / 'static_vms.json'
if static_vms_path.exists():
    try:
        with open(static_vms_path) as f:
            static_vms_config = json.load(f)
        if static_vms_config.get('enabled'):
            logger.info(f"Static VMs mode enabled: {static_vms_config.get('node1_ip')}, {static_vms_config.get('node2_ip')}")
        else:
            static_vms_config = None
    except Exception as e:
        logger.warning(f"Failed to load static_vms.json: {e}")
        static_vms_config = None

session_manager = None
if (BASE_DIR / 'infra' / 'terraform.tfvars').exists():
    session_manager = SessionManager(
        db_path=BASE_DIR / 'sessions.db',
        infra_dir=BASE_DIR / 'infra',
        workspaces_dir=BASE_DIR / 'workspaces',
        timeout_minutes=120,  # 2 hours default
        static_vms=static_vms_config  # Pass static VM config
    )
    logger.info("Session manager initialized")
else:
    logger.warning("OCI not configured - session management disabled")

# Initialize terminal handlers with session manager
from terminal import init_terminal_handlers
init_terminal_handlers(socketio, session_manager)


# =============================================================================
# Session Management API Endpoints
# =============================================================================

@app.route('/api/sessions', methods=['GET'])
def list_sessions():
    """List active sessions."""
    if not session_manager:
        return jsonify({'error': 'OCI not configured'}), 503
    
    sessions = session_manager.list_sessions()
    return jsonify([s.to_dict() for s in sessions])


@app.route('/api/sessions/active', methods=['GET'])
def get_active_session():
    """Get the currently active session (if any)."""
    if not session_manager:
        return jsonify({'error': 'OCI not configured'}), 503
    
    session = session_manager.get_active_session()
    if session:
        return jsonify(session.to_dict())
    return jsonify(None)


@app.route('/api/sessions', methods=['POST'])
@limiter.limit("5 per hour")  # Rate limit session creation
def create_session():
    """Create a new practice session."""
    if not session_manager:
        return jsonify({'error': 'OCI not configured'}), 503
    
    data = request.get_json() or {}
    timeout = data.get('timeout_minutes', 120)  # 2 hours default
    
    # Check for existing active session
    active = session_manager.get_active_session()
    if active:
        return jsonify({
            'error': 'Active session exists',
            'session': active.to_dict()
        }), 409
    
    session = session_manager.create_session(timeout_minutes=timeout)
    return jsonify(session.to_dict()), 201


@app.route('/api/sessions/<session_id>', methods=['GET'])
def get_session(session_id):
    """Get session details."""
    if not session_manager:
        return jsonify({'error': 'OCI not configured'}), 503
    
    session = session_manager.get_session(session_id)
    if not session:
        return jsonify({'error': 'Session not found'}), 404
    
    return jsonify(session.to_dict())


@app.route('/api/sessions/<session_id>/provision', methods=['POST'])
def provision_session(session_id):
    """
    Start provisioning VMs for a session.
    
    Note: This is a blocking operation that can take 2-5 minutes.
    In production, use a task queue (Celery, etc.)
    """
    if not session_manager:
        return jsonify({'error': 'OCI not configured'}), 503
    
    try:
        session = session_manager.provision_session(session_id)
        return jsonify(session.to_dict())
    except ValueError as e:
        return jsonify({'error': str(e)}), 400
    except RuntimeError as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/sessions/<session_id>', methods=['DELETE'])
def terminate_session_endpoint(session_id):
    """Terminate a session and destroy its VMs."""
    if not session_manager:
        return jsonify({'error': 'OCI not configured'}), 503
    
    success = session_manager.terminate_session(session_id)
    if success:
        return jsonify({'status': 'terminated'})
    return jsonify({'error': 'Failed to terminate session'}), 500


@app.route('/api/sessions/<session_id>/extend', methods=['POST'])
def extend_session(session_id):
    """Extend session timeout."""
    if not session_manager:
        return jsonify({'error': 'OCI not configured'}), 503
    
    data = request.get_json() or {}
    minutes = data.get('minutes', 30)
    
    session = session_manager.extend_session(session_id, minutes)
    if session:
        return jsonify(session.to_dict())
    return jsonify({'error': 'Session not found'}), 404


# =============================================================================
# Terminal Test Page
# =============================================================================

@app.route('/terminal-test')
def terminal_test():
    """Serve terminal test page."""
    return app.send_static_file('terminal-test.html')


# =============================================================================
# Background Session Cleanup
# =============================================================================

SESSION_CLEANUP_INTERVAL = 300  # 5 minutes

def session_cleanup_worker():
    """Background worker that periodically cleans up expired sessions."""
    while True:
        eventlet.sleep(SESSION_CLEANUP_INTERVAL)
        if session_manager:
            try:
                cleaned = session_manager.cleanup_expired_sessions()
                if cleaned > 0:
                    logger.info(f"Session cleanup: terminated {cleaned} expired session(s)")
            except Exception as e:
                logger.error(f"Session cleanup error: {e}")


# =============================================================================
# Graceful Shutdown Handler
# =============================================================================

def graceful_shutdown(signum, frame):
    """Handle shutdown signals gracefully."""
    sig_name = signal.Signals(signum).name
    logger.info(f"Received {sig_name}, initiating graceful shutdown...")
    
    if session_manager:
        try:
            session_manager.request_shutdown()
        except Exception as e:
            logger.error(f"Error during shutdown cleanup: {e}")
    
    logger.info("Graceful shutdown complete, exiting.")
    sys.exit(0)


def register_shutdown_handlers():
    """Register signal handlers for graceful shutdown."""
    # Note: eventlet may interfere with signal handling, so we use atexit as backup
    signal.signal(signal.SIGTERM, graceful_shutdown)
    signal.signal(signal.SIGINT, graceful_shutdown)
    
    # Also register atexit handler as backup
    def cleanup_on_exit():
        if session_manager:
            logger.info("atexit cleanup triggered")
            try:
                session_manager.request_shutdown()
            except Exception as e:
                logger.error(f"atexit cleanup error: {e}")
    
    atexit.register(cleanup_on_exit)


# =============================================================================
# Main Entry Point
# =============================================================================

if __name__ == '__main__':
    logger.info(f"Starting RHCSA Practice Labs API with WebSocket support")
    logger.info(f"Debug: {DEBUG}, Log Level: {LOG_LEVEL}")
    logger.info(f"Session manager: {'enabled' if session_manager else 'disabled'}")
    
    # Register graceful shutdown handlers
    register_shutdown_handlers()
    logger.info("Graceful shutdown handlers registered")
    
    # Start background session cleanup worker
    if session_manager:
        eventlet.spawn(session_cleanup_worker)
        logger.info(f"Session cleanup worker started (interval: {SESSION_CLEANUP_INTERVAL}s)")
    
    socketio.run(
        app,
        host='0.0.0.0',
        port=8080,
        debug=DEBUG,
        use_reloader=False
    )
