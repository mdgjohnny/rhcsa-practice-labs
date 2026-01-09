"""Session manager for RHCSA practice labs."""

import json
import logging
import sqlite3
import threading
import uuid
from dataclasses import dataclass, asdict
from datetime import datetime, timedelta
from enum import Enum
from pathlib import Path
from typing import Optional, List

from .terraform_wrapper import TerraformWrapper, WorkspaceManager

logger = logging.getLogger(__name__)


class SessionState(Enum):
    """Session lifecycle states."""
    PENDING = "pending"          # Session created, waiting to provision
    PROVISIONING = "provisioning"  # Terraform apply in progress
    READY = "ready"              # VMs are up and ready
    ACTIVE = "active"            # User is connected
    TERMINATING = "terminating"  # Terraform destroy in progress
    TERMINATED = "terminated"    # Resources destroyed
    FAILED = "failed"            # Provisioning failed


@dataclass
class SessionInfo:
    """Session information."""
    session_id: str
    state: SessionState
    created_at: datetime
    expires_at: datetime
    node1_ip: Optional[str] = None
    node2_ip: Optional[str] = None
    node1_private_ip: Optional[str] = None
    node2_private_ip: Optional[str] = None
    ssh_private_key: Optional[str] = None
    error: Optional[str] = None

    def to_dict(self) -> dict:
        """Convert to dictionary."""
        return {
            "session_id": self.session_id,
            "state": self.state.value,
            "created_at": self.created_at.isoformat(),
            "expires_at": self.expires_at.isoformat(),
            "node1_ip": self.node1_ip,
            "node2_ip": self.node2_ip,
            "node1_private_ip": self.node1_private_ip,
            "node2_private_ip": self.node2_private_ip,
            "time_remaining_seconds": max(0, (self.expires_at - datetime.utcnow()).total_seconds()),
            "error": self.error,
        }

    def is_expired(self) -> bool:
        """Check if session has expired."""
        return datetime.utcnow() > self.expires_at


class SessionManager:
    """
    Manages RHCSA practice sessions with OCI infrastructure.

    Handles:
    - Session creation and lifecycle
    - Terraform operations for VM provisioning
    - Automatic cleanup of expired sessions
    - Concurrent session isolation
    """

    def __init__(
        self,
        db_path: Path,
        infra_dir: Path,
        workspaces_dir: Path,
        timeout_minutes: int = 30,
    ):
        """
        Initialize session manager.

        Args:
            db_path: Path to SQLite database
            infra_dir: Path to Terraform infrastructure directory
            workspaces_dir: Path to store session workspaces
            timeout_minutes: Default session timeout
        """
        self.db_path = Path(db_path)
        self.infra_dir = Path(infra_dir)
        self.timeout_minutes = timeout_minutes

        self.workspace_manager = WorkspaceManager(workspaces_dir, infra_dir)

        self._init_db()
        self._lock = threading.Lock()

    def _init_db(self):
        """Initialize sessions table."""
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()
        c.execute("""
            CREATE TABLE IF NOT EXISTS sessions (
                session_id TEXT PRIMARY KEY,
                state TEXT NOT NULL,
                created_at TEXT NOT NULL,
                expires_at TEXT NOT NULL,
                node1_ip TEXT,
                node2_ip TEXT,
                node1_private_ip TEXT,
                node2_private_ip TEXT,
                ssh_private_key TEXT,
                error TEXT,
                terraform_outputs TEXT
            )
        """)
        conn.commit()
        conn.close()

    def _get_db(self) -> sqlite3.Connection:
        """Get database connection."""
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn

    def create_session(self, timeout_minutes: Optional[int] = None) -> SessionInfo:
        """
        Create a new practice session.

        Args:
            timeout_minutes: Session timeout (uses default if not specified)

        Returns:
            SessionInfo for the new session
        """
        session_id = f"sess-{uuid.uuid4().hex[:12]}"
        timeout = timeout_minutes or self.timeout_minutes
        now = datetime.utcnow()
        expires_at = now + timedelta(minutes=timeout)

        session = SessionInfo(
            session_id=session_id,
            state=SessionState.PENDING,
            created_at=now,
            expires_at=expires_at,
        )

        # Save to database
        conn = self._get_db()
        c = conn.cursor()
        c.execute("""
            INSERT INTO sessions (session_id, state, created_at, expires_at)
            VALUES (?, ?, ?, ?)
        """, (session_id, session.state.value, now.isoformat(), expires_at.isoformat()))
        conn.commit()
        conn.close()

        logger.info(f"Created session {session_id}, expires at {expires_at}")
        return session

    def provision_session(self, session_id: str) -> SessionInfo:
        """
        Provision OCI resources for a session.

        This is a blocking operation that can take several minutes.

        Args:
            session_id: Session to provision

        Returns:
            Updated SessionInfo
        """
        session = self.get_session(session_id)
        if not session:
            raise ValueError(f"Session {session_id} not found")

        if session.state != SessionState.PENDING:
            raise ValueError(f"Session {session_id} is not in PENDING state")

        # Update state to provisioning
        self._update_session_state(session_id, SessionState.PROVISIONING)

        try:
            # Create isolated workspace
            workspace_dir = self.workspace_manager.create_workspace(session_id)
            terraform = TerraformWrapper(workspace_dir)

            # Initialize and apply
            if not terraform.init():
                raise RuntimeError("Terraform init failed")

            result = terraform.apply(session_id)

            if not result.success:
                self._update_session_state(
                    session_id,
                    SessionState.FAILED,
                    error=result.error
                )
                raise RuntimeError(f"Terraform apply failed: {result.error}")

            # Extract connection info from outputs
            outputs = result.outputs
            node1_ip = outputs.get("node1_public_ip")
            node2_ip = outputs.get("node2_public_ip")
            node1_private_ip = outputs.get("node1_private_ip")
            node2_private_ip = outputs.get("node2_private_ip")
            ssh_private_key = outputs.get("ssh_private_key")

            # Update session with connection info
            conn = self._get_db()
            c = conn.cursor()
            c.execute("""
                UPDATE sessions SET
                    state = ?,
                    node1_ip = ?,
                    node2_ip = ?,
                    node1_private_ip = ?,
                    node2_private_ip = ?,
                    ssh_private_key = ?,
                    terraform_outputs = ?
                WHERE session_id = ?
            """, (
                SessionState.READY.value,
                node1_ip,
                node2_ip,
                node1_private_ip,
                node2_private_ip,
                ssh_private_key,
                json.dumps(outputs),
                session_id
            ))
            conn.commit()
            conn.close()

            logger.info(f"Session {session_id} provisioned successfully")
            return self.get_session(session_id)

        except Exception as e:
            logger.error(f"Failed to provision session {session_id}: {e}")
            self._update_session_state(session_id, SessionState.FAILED, error=str(e))
            raise

    def terminate_session(self, session_id: str) -> bool:
        """
        Terminate a session and destroy its resources.

        Args:
            session_id: Session to terminate

        Returns:
            True if termination succeeds
        """
        session = self.get_session(session_id)
        if not session:
            logger.warning(f"Session {session_id} not found")
            return False

        if session.state in (SessionState.TERMINATED, SessionState.TERMINATING):
            logger.info(f"Session {session_id} already terminated/terminating")
            return True

        self._update_session_state(session_id, SessionState.TERMINATING)

        try:
            workspace_dir = self.workspace_manager.get_workspace(session_id)
            if workspace_dir:
                terraform = TerraformWrapper(workspace_dir)
                terraform.destroy(session_id)

            # Clean up workspace
            self.workspace_manager.delete_workspace(session_id)

            self._update_session_state(session_id, SessionState.TERMINATED)
            logger.info(f"Session {session_id} terminated successfully")
            return True

        except Exception as e:
            logger.error(f"Failed to terminate session {session_id}: {e}")
            self._update_session_state(session_id, SessionState.FAILED, error=str(e))
            return False

    def get_session(self, session_id: str) -> Optional[SessionInfo]:
        """Get session information."""
        conn = self._get_db()
        c = conn.cursor()
        c.execute("SELECT * FROM sessions WHERE session_id = ?", (session_id,))
        row = c.fetchone()
        conn.close()

        if not row:
            return None

        return SessionInfo(
            session_id=row["session_id"],
            state=SessionState(row["state"]),
            created_at=datetime.fromisoformat(row["created_at"]),
            expires_at=datetime.fromisoformat(row["expires_at"]),
            node1_ip=row["node1_ip"],
            node2_ip=row["node2_ip"],
            node1_private_ip=row["node1_private_ip"],
            node2_private_ip=row["node2_private_ip"],
            ssh_private_key=row["ssh_private_key"],
            error=row["error"],
        )

    def list_sessions(self, include_terminated: bool = False) -> List[SessionInfo]:
        """List all sessions."""
        conn = self._get_db()
        c = conn.cursor()

        if include_terminated:
            c.execute("SELECT * FROM sessions ORDER BY created_at DESC")
        else:
            c.execute("""
                SELECT * FROM sessions
                WHERE state NOT IN (?, ?)
                ORDER BY created_at DESC
            """, (SessionState.TERMINATED.value, SessionState.FAILED.value))

        rows = c.fetchall()
        conn.close()

        return [
            SessionInfo(
                session_id=row["session_id"],
                state=SessionState(row["state"]),
                created_at=datetime.fromisoformat(row["created_at"]),
                expires_at=datetime.fromisoformat(row["expires_at"]),
                node1_ip=row["node1_ip"],
                node2_ip=row["node2_ip"],
                node1_private_ip=row["node1_private_ip"],
                node2_private_ip=row["node2_private_ip"],
                ssh_private_key=row["ssh_private_key"],
                error=row["error"],
            )
            for row in rows
        ]

    def get_active_session(self) -> Optional[SessionInfo]:
        """Get the currently active session (if any)."""
        sessions = self.list_sessions()
        for session in sessions:
            if session.state in (SessionState.READY, SessionState.ACTIVE):
                return session
        return None

    def cleanup_expired_sessions(self) -> int:
        """
        Terminate all expired sessions.

        Returns:
            Number of sessions cleaned up
        """
        sessions = self.list_sessions()
        cleaned = 0

        for session in sessions:
            if session.is_expired() and session.state not in (
                SessionState.TERMINATED,
                SessionState.TERMINATING,
            ):
                logger.info(f"Cleaning up expired session {session.session_id}")
                if self.terminate_session(session.session_id):
                    cleaned += 1

        return cleaned

    def extend_session(self, session_id: str, minutes: int = 30) -> Optional[SessionInfo]:
        """
        Extend a session's timeout.

        Args:
            session_id: Session to extend
            minutes: Additional minutes to add

        Returns:
            Updated SessionInfo or None if session not found
        """
        session = self.get_session(session_id)
        if not session:
            return None

        new_expires = session.expires_at + timedelta(minutes=minutes)

        conn = self._get_db()
        c = conn.cursor()
        c.execute("""
            UPDATE sessions SET expires_at = ? WHERE session_id = ?
        """, (new_expires.isoformat(), session_id))
        conn.commit()
        conn.close()

        logger.info(f"Extended session {session_id} by {minutes} minutes")
        return self.get_session(session_id)

    def _update_session_state(
        self,
        session_id: str,
        state: SessionState,
        error: Optional[str] = None
    ):
        """Update session state in database."""
        conn = self._get_db()
        c = conn.cursor()
        c.execute("""
            UPDATE sessions SET state = ?, error = ? WHERE session_id = ?
        """, (state.value, error, session_id))
        conn.commit()
        conn.close()
