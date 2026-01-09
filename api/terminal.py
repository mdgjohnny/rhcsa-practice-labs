"""WebSocket terminal handler for SSH connections."""

import logging
import os
import select
import socket
import threading
from io import StringIO
from typing import Optional

import paramiko
from flask import request
from flask_socketio import SocketIO, emit, disconnect

logger = logging.getLogger(__name__)

# Store active terminal sessions: sid -> TerminalSession
active_terminals = {}


class TerminalSession:
    """Manages an SSH terminal session."""

    def __init__(self, sid: str, host: str, username: str = "opc",
                 private_key: Optional[str] = None, password: Optional[str] = None,
                 port: int = 22):
        """
        Initialize terminal session.

        Args:
            sid: Socket.IO session ID
            host: SSH host
            username: SSH username (default: opc for OCI instances)
            private_key: SSH private key content (PEM format)
            password: SSH password (alternative to private_key)
            port: SSH port
        """
        self.sid = sid
        self.host = host
        self.username = username
        self.private_key = private_key
        self.password = password
        self.port = port

        self.ssh_client: Optional[paramiko.SSHClient] = None
        self.channel: Optional[paramiko.Channel] = None
        self.reader_thread: Optional[threading.Thread] = None
        self.running = False

    def connect(self) -> bool:
        """
        Establish SSH connection.

        Returns:
            True if connection successful
        """
        try:
            self.ssh_client = paramiko.SSHClient()
            self.ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

            connect_kwargs = {
                "hostname": self.host,
                "port": self.port,
                "username": self.username,
                "timeout": 30,
                "allow_agent": False,
                "look_for_keys": False,
            }

            if self.private_key:
                # Load private key from string
                key_file = StringIO(self.private_key)
                pkey = paramiko.RSAKey.from_private_key(key_file)
                connect_kwargs["pkey"] = pkey
            elif self.password:
                connect_kwargs["password"] = self.password
            else:
                raise ValueError("Either private_key or password must be provided")

            logger.info(f"Connecting to {self.username}@{self.host}:{self.port}")
            self.ssh_client.connect(**connect_kwargs)

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
        from app import socketio  # Import here to avoid circular import

        while self.running and self.channel:
            try:
                # Use select for non-blocking read
                readable, _, _ = select.select([self.channel], [], [], 0.1)
                if readable:
                    data = self.channel.recv(4096)
                    if data:
                        # Emit data to the specific client
                        socketio.emit(
                            "terminal_output",
                            {"data": data.decode("utf-8", errors="replace")},
                            room=self.sid,
                            namespace="/terminal"
                        )
                    else:
                        # Connection closed
                        logger.info(f"SSH channel closed for {self.sid}")
                        break
            except socket.timeout:
                continue
            except Exception as e:
                if self.running:
                    logger.error(f"Error reading from terminal {self.sid}: {e}")
                break

        # Notify client of disconnection
        if self.running:
            socketio.emit(
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


def init_terminal_handlers(socketio: SocketIO):
    """Initialize Socket.IO event handlers for terminal."""

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

    @socketio.on("start_terminal", namespace="/terminal")
    def handle_start_terminal(data):
        """
        Start a new terminal session.

        Expected data:
        {
            "host": "ip_address",
            "username": "opc",
            "private_key": "-----BEGIN RSA PRIVATE KEY-----...",
            "password": "optional_password",
            "cols": 80,
            "rows": 24
        }
        """
        sid = request.sid

        # Close existing session if any
        if sid in active_terminals:
            active_terminals[sid].close()
            del active_terminals[sid]

        host = data.get("host")
        username = data.get("username", "opc")
        private_key = data.get("private_key")
        password = data.get("password")
        cols = data.get("cols", 80)
        rows = data.get("rows", 24)

        if not host:
            emit("terminal_error", {"error": "Host is required"})
            return

        if not private_key and not password:
            emit("terminal_error", {"error": "Either private_key or password is required"})
            return

        # Create terminal session
        terminal = TerminalSession(
            sid=sid,
            host=host,
            username=username,
            private_key=private_key,
            password=password
        )

        if terminal.connect():
            terminal.resize(cols, rows)
            active_terminals[sid] = terminal
            emit("terminal_ready", {"host": host})
        else:
            emit("terminal_error", {"error": f"Failed to connect to {host}"})

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
