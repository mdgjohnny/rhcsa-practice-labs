#!/usr/bin/env python3
"""
RHCSA Practice Labs API with WebSocket support.

This is a wrapper around the main Flask app that adds Socket.IO support
for the web terminal functionality.
"""

import logging
import os
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from flask_socketio import SocketIO

# Import the main Flask app
from app import app, DEBUG, LOG_LEVEL, logger

# Initialize Socket.IO
socketio = SocketIO(
    app,
    cors_allowed_origins="*",  # Configure appropriately for production
    async_mode="eventlet",
    logger=DEBUG,
    engineio_logger=DEBUG
)

# Make socketio available for terminal.py
import builtins
builtins.socketio = socketio

# Initialize terminal handlers
from terminal import init_terminal_handlers
init_terminal_handlers(socketio)

# Add session management endpoints
from oci_manager import SessionManager, SessionState

BASE_DIR = Path(__file__).parent.parent
session_manager = None

# Only initialize session manager if infra is configured
if (BASE_DIR / 'infra' / 'terraform.tfvars').exists():
    session_manager = SessionManager(
        db_path=BASE_DIR / 'sessions.db',
        infra_dir=BASE_DIR / 'infra',
        workspaces_dir=BASE_DIR / 'workspaces',
        timeout_minutes=30
    )
    logger.info("Session manager initialized")
else:
    logger.warning("OCI not configured - session management disabled")


@app.route('/api/sessions', methods=['GET'])
def list_sessions():
    """List active sessions."""
    from flask import jsonify
    if not session_manager:
        return jsonify({'error': 'OCI not configured'}), 503
    
    sessions = session_manager.list_sessions()
    return jsonify([s.to_dict() for s in sessions])


@app.route('/api/sessions', methods=['POST'])
def create_session():
    """Create a new practice session."""
    from flask import jsonify, request
    if not session_manager:
        return jsonify({'error': 'OCI not configured'}), 503
    
    data = request.get_json() or {}
    timeout = data.get('timeout_minutes', 30)
    
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
    from flask import jsonify
    if not session_manager:
        return jsonify({'error': 'OCI not configured'}), 503
    
    session = session_manager.get_session(session_id)
    if not session:
        return jsonify({'error': 'Session not found'}), 404
    
    return jsonify(session.to_dict())


@app.route('/api/sessions/<session_id>/provision', methods=['POST'])
def provision_session(session_id):
    """Start provisioning VMs for a session."""
    from flask import jsonify
    if not session_manager:
        return jsonify({'error': 'OCI not configured'}), 503
    
    try:
        # This is a blocking operation - in production, use a task queue
        session = session_manager.provision_session(session_id)
        return jsonify(session.to_dict())
    except ValueError as e:
        return jsonify({'error': str(e)}), 400
    except RuntimeError as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/sessions/<session_id>', methods=['DELETE'])
def terminate_session_endpoint(session_id):
    """Terminate a session."""
    from flask import jsonify
    if not session_manager:
        return jsonify({'error': 'OCI not configured'}), 503
    
    success = session_manager.terminate_session(session_id)
    if success:
        return jsonify({'status': 'terminated'})
    return jsonify({'error': 'Failed to terminate session'}), 500


@app.route('/api/sessions/<session_id>/extend', methods=['POST'])
def extend_session(session_id):
    """Extend session timeout."""
    from flask import jsonify, request
    if not session_manager:
        return jsonify({'error': 'OCI not configured'}), 503
    
    data = request.get_json() or {}
    minutes = data.get('minutes', 30)
    
    session = session_manager.extend_session(session_id, minutes)
    if session:
        return jsonify(session.to_dict())
    return jsonify({'error': 'Session not found'}), 404


# Serve terminal test page
@app.route('/terminal-test')
def terminal_test():
    """Serve terminal test page."""
    return app.send_static_file('terminal-test.html')


if __name__ == '__main__':
    logger.info(f"Starting RHCSA Practice Labs API with WebSocket support")
    logger.info(f"Debug: {DEBUG}, Log Level: {LOG_LEVEL}")
    
    # Use eventlet for WebSocket support
    socketio.run(
        app,
        host='0.0.0.0',
        port=8080,
        debug=DEBUG,
        use_reloader=DEBUG
    )
