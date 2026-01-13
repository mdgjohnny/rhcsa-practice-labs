"""WebSocket terminal handler for SSH connections.

The terminal connects using session_id - SSH keys are stored securely
in the backend session database, never exposed to the browser.

Uses threading instead of eventlet (eventlet is deprecated).
"""

import logging
import os
import select
import threading
import time
from io import StringIO
from typing import Optional, TYPE_CHECKING

import paramiko
from flask import request
from flask_socketio import SocketIO, emit, disconnect

if TYPE_CHECKING:
    from oci_manager import SessionManager

logger = logging.getLogger(__name__)

# Store active terminal sessions: sid -> TerminalSession
active_terminals = {}

# Reference to session manager (set during init)
_session_manager: Optional["SessionManager"] = None


class TerminalSession:
    """Manages an SSH terminal session."""

    def __init__(self, sid: str, host: str, username: str = "opc",
                 private_key: Optional[str] = None, port: int = 22):
        """
        Initialize terminal session.

        Args:
            sid: Socket.IO session ID
            host: SSH host
            username: SSH username (default: opc for OCI instances)
            private_key: SSH private key content (PEM format)
            port: SSH port
        """
        self.sid = sid
        self.host = host
        self.username = username
        self.private_key = private_key
        self.port = port

        self.ssh_client: Optional[paramiko.SSHClient] = None
        self.channel: Optional[paramiko.Channel] = None
        self.reader_thread: Optional[threading.Thread] = None
        self.running = False
        self._socketio = None  # Set during connect

    def connect(self, socketio: SocketIO) -> bool:
        """
        Establish SSH connection.

        Returns:
            True if connection successful
        """
        self._socketio = socketio
        try:
            self.ssh_client = paramiko.SSHClient()
            self.ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

            # Load private key from string
            key_file = StringIO(self.private_key)
            try:
                pkey = paramiko.RSAKey.from_private_key(key_file)
            except:
                key_file.seek(0)
                pkey = paramiko.Ed25519Key.from_private_key(key_file)

            logger.info(f"Connecting to {self.username}@{self.host}:{self.port}")
            self.ssh_client.connect(
                hostname=self.host,
                port=self.port,
                username=self.username,
                pkey=pkey,
                timeout=30,
                allow_agent=False,
                look_for_keys=False,
            )

            # Request PTY
            self.channel = self.ssh_client.invoke_shell(
                term="xterm-256color",
                width=80,
                height=24
            )
            self.channel.setblocking(0)

            # Start reader thread
            self.running = True
            self.reader_thread = threading.Thread(target=self._read_output, daemon=True)
            self.reader_thread.start()

            logger.info(f"SSH connection established for {self.sid}")
            return True

        except Exception as e:
            logger.error(f"SSH connection failed for {self.sid}: {e}")
            self.close()
            return False

    def write(self, data: str):
        """Send input to the terminal."""
        if self.channel and self.running:
            try:
                self.channel.send(data)
            except Exception as e:
                logger.error(f"Failed to write to terminal {self.sid}: {e}")
                self.close()

    def resize(self, cols: int, rows: int):
        """Resize the terminal."""
        if self.channel:
            try:
                self.channel.resize_pty(width=cols, height=rows)
            except Exception as e:
                logger.warning(f"Failed to resize terminal {self.sid}: {e}")

    def _read_output(self):
        """Background thread that reads SSH output and emits to client."""
        while self.running and self.channel:
            try:
                # Use select to wait for data with timeout
                if self.channel.recv_ready():
                    data = self.channel.recv(4096)
                    if data:
                        # Emit data to the specific client
                        if self._socketio:
                            self._socketio.emit(
                                "terminal_output",
                                {"data": data.decode("utf-8", errors="replace")},
                                room=self.sid,
                                namespace="/terminal"
                            )
                    else:
                        # Connection closed
                        logger.info(f"SSH channel closed for {self.sid}")
                        break
                else:
                    # Sleep briefly to avoid busy waiting
                    time.sleep(0.05)
            except Exception as e:
                if self.running:
                    logger.error(f"Error reading from terminal {self.sid}: {e}")
                break

        # Notify client of disconnection
        if self.running and self._socketio:
            self._socketio.emit(
                "terminal_disconnected",
                {"reason": "SSH connection closed"},
                room=self.sid,
                namespace="/terminal"
            )
        self.running = False

    def close(self):
        """Close the SSH connection."""
        self.running = False

        if self.channel:
            try:
                self.channel.close()
            except:
                pass
            self.channel = None

        if self.ssh_client:
            try:
                self.ssh_client.close()
            except:
                pass
            self.ssh_client = None

        logger.info(f"Terminal session {self.sid} closed")


def init_terminal_handlers(socketio: SocketIO, session_manager: Optional["SessionManager"] = None):
    """Initialize Socket.IO event handlers for terminal."""
    global _session_manager
    _session_manager = session_manager

    @socketio.on("connect", namespace="/terminal")
    def handle_connect():
        """Handle new terminal connection."""
        sid = request.sid
        logger.info(f"Terminal client connected: {sid}")
        emit("connected", {"sid": sid})

    @socketio.on("disconnect", namespace="/terminal")
    def handle_disconnect():
        """Handle terminal disconnection."""
        sid = request.sid
        logger.info(f"Terminal client disconnected: {sid}")

        if sid in active_terminals:
            active_terminals[sid].close()
            del active_terminals[sid]

    @socketio.on("start_session_terminal", namespace="/terminal")
    def handle_start_session_terminal(data):
        """
        Start terminal for a practice session.
        
        Expected data:
        {
            "session_id": "sess-xxxx",
            "node": "node1" or "node2",
            "cols": 80,
            "rows": 24
        }
        """
        sid = request.sid
        session_id = data.get("session_id")
        node = data.get("node", "node1")
        cols = data.get("cols", 80)
        rows = data.get("rows", 24)

        logger.info(f"start_session_terminal: session={session_id}, node={node}")

        if not session_id:
            emit("terminal_error", {"error": "session_id is required"})
            return

        if not _session_manager:
            emit("terminal_error", {"error": "Session manager not available"})
            return

        # Get session info
        session = _session_manager.get_session(session_id)
        if not session:
            emit("terminal_error", {"error": f"Session {session_id} not found"})
            return

        if session.state.value not in ("ready", "active"):
            emit("terminal_error", {"error": f"Session not ready (state: {session.state.value})"})
            return

        # Get connection info based on node
        if node == "node1":
            host = session.node1_ip
        elif node == "node2":
            host = session.node2_ip
        else:
            emit("terminal_error", {"error": f"Invalid node: {node}"})
            return

        if not host:
            emit("terminal_error", {"error": f"No IP for {node}"})
            return

        private_key = session.ssh_private_key
        if not private_key:
            emit("terminal_error", {"error": "No SSH key available for session"})
            return

        # Close existing terminal if any
        if sid in active_terminals:
            active_terminals[sid].close()
            del active_terminals[sid]

        # Create terminal session
        terminal = TerminalSession(
            sid=sid,
            host=host,
            username="opc",
            private_key=private_key
        )

        if terminal.connect(socketio):
            terminal.resize(cols, rows)
            active_terminals[sid] = terminal
            emit("terminal_ready", {"host": host, "node": node})
        else:
            emit("terminal_error", {"error": f"Failed to connect to {node} ({host})"})

    @socketio.on("terminal_input", namespace="/terminal")
    def handle_terminal_input(data):
        """Handle terminal input from client."""
        sid = request.sid
        terminal = active_terminals.get(sid)

        if terminal:
            input_data = data.get("data", "")
            terminal.write(input_data)
        else:
            emit("terminal_error", {"error": "No active terminal session"})

    @socketio.on("terminal_resize", namespace="/terminal")
    def handle_terminal_resize(data):
        """Handle terminal resize."""
        sid = request.sid
        terminal = active_terminals.get(sid)

        if terminal:
            cols = data.get("cols", 80)
            rows = data.get("rows", 24)
            terminal.resize(cols, rows)

    @socketio.on("stop_terminal", namespace="/terminal")
    def handle_stop_terminal():
        """Stop the terminal session."""
        sid = request.sid

        if sid in active_terminals:
            active_terminals[sid].close()
            del active_terminals[sid]
            emit("terminal_stopped", {})


def get_active_terminal_count() -> int:
    """Get the number of active terminal sessions."""
    return len(active_terminals)
