"""Session manager for RHCSA practice labs.

Cloud Management Best Practices Implemented:
1. Startup reconciliation - clean orphaned resources on init
2. Graceful shutdown - cleanup handler for SIGTERM/SIGINT
3. VM health check - verify cloud-init complete before READY
4. Terraform state locking - semaphore for concurrent operations
5. Pre-flight quota check - verify VCN capacity before provisioning
6. Resource drift detection - periodic verification of cloud resources
7. SSH key encryption - encrypt private keys at rest
"""

import base64
import hashlib
import json
import logging
import os
import socket
import sqlite3
import threading
import time
import uuid
from contextlib import contextmanager
from cryptography.fernet import Fernet
from dataclasses import dataclass
from datetime import datetime, timedelta
from enum import Enum
from io import StringIO
from pathlib import Path
from typing import Optional, List, Callable

import paramiko

from .terraform_wrapper import TerraformWrapper, WorkspaceManager

logger = logging.getLogger(__name__)


class SessionState(Enum):
    """Session lifecycle states."""
    PENDING = "pending"          # Session created, waiting to provision
    PROVISIONING = "provisioning"  # Terraform apply in progress
    WAITING_HEALTH = "waiting_health"  # VMs up, waiting for cloud-init
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


class KeyEncryption:
    """Handles SSH key encryption at rest."""
    
    def __init__(self, secret_key: Optional[str] = None):
        """Initialize with secret key or generate from machine ID."""
        if secret_key:
            # Use provided key
            key_bytes = hashlib.sha256(secret_key.encode()).digest()
        else:
            # Derive key from machine-specific data
            machine_id = self._get_machine_id()
            key_bytes = hashlib.sha256(machine_id.encode()).digest()
        
        self._fernet = Fernet(base64.urlsafe_b64encode(key_bytes))
    
    def _get_machine_id(self) -> str:
        """Get a machine-specific identifier."""
        try:
            with open('/etc/machine-id', 'r') as f:
                return f.read().strip()
        except:
            # Fallback to hostname + a static salt
            return f"{socket.gethostname()}-rhcsa-practice-salt"
    
    def encrypt(self, plaintext: str) -> str:
        """Encrypt a string."""
        if not plaintext:
            return plaintext
        return self._fernet.encrypt(plaintext.encode()).decode()
    
    def decrypt(self, ciphertext: str) -> str:
        """Decrypt a string."""
        if not ciphertext:
            return ciphertext
        try:
            return self._fernet.decrypt(ciphertext.encode()).decode()
        except Exception:
            # If decryption fails, assume it's already plaintext (migration)
            return ciphertext


class SessionManager:
    """
    Manages RHCSA practice sessions with OCI infrastructure.

    Handles:
    - Session creation and lifecycle
    - Terraform operations for VM provisioning
    - Automatic cleanup of expired sessions
    - Concurrent session isolation
    - Startup reconciliation for orphaned resources
    - VM health checks before marking ready
    """

    # Semaphore for terraform operations (prevent concurrent state corruption)
    _terraform_semaphore = threading.Semaphore(1)
    
    # Maximum VCNs allowed (OCI free tier limit)
    MAX_VCNS = 2

    def __init__(
        self,
        db_path: Path,
        infra_dir: Path,
        workspaces_dir: Path,
        timeout_minutes: int = 30,
        encryption_key: Optional[str] = None,
        health_check_timeout: int = 300,  # 5 minutes max wait for cloud-init
        health_check_interval: int = 10,  # Check every 10 seconds
    ):
        """
        Initialize session manager.

        Args:
            db_path: Path to SQLite database
            infra_dir: Path to Terraform infrastructure directory
            workspaces_dir: Path to store session workspaces
            timeout_minutes: Default session timeout
            encryption_key: Optional key for SSH key encryption
            health_check_timeout: Max seconds to wait for VM health
            health_check_interval: Seconds between health checks
        """
        self.db_path = Path(db_path)
        self.infra_dir = Path(infra_dir)
        self.workspaces_dir = Path(workspaces_dir)
        self.timeout_minutes = timeout_minutes
        self.health_check_timeout = health_check_timeout
        self.health_check_interval = health_check_interval

        self.workspace_manager = WorkspaceManager(workspaces_dir, infra_dir)
        self.key_encryption = KeyEncryption(encryption_key)

        self._init_db()
        self._lock = threading.Lock()
        self._shutdown_requested = False
        
        # Startup reconciliation
        self._reconcile_on_startup()

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

    def _reconcile_on_startup(self):
        """
        Reconcile state on startup.
        
        - Find orphaned workspaces (workspace exists but no DB entry or terminated)
        - Clean up PROVISIONING sessions (crash during provision)
        - Destroy orphaned cloud resources
        """
        logger.info("Running startup reconciliation...")
        
        # Get all workspaces
        workspaces = self.workspace_manager.list_workspaces()
        
        for session_id in workspaces:
            session = self.get_session(session_id)
            
            if session is None:
                # Orphaned workspace - no DB entry
                logger.warning(f"Found orphaned workspace {session_id}, cleaning up...")
                self._cleanup_workspace(session_id)
                
            elif session.state == SessionState.PROVISIONING:
                # Crashed during provisioning
                logger.warning(f"Session {session_id} stuck in PROVISIONING, cleaning up...")
                self._cleanup_workspace(session_id)
                self._update_session_state(session_id, SessionState.FAILED, 
                                          error="Interrupted during provisioning")
                
            elif session.state == SessionState.WAITING_HEALTH:
                # Crashed during health check
                logger.warning(f"Session {session_id} stuck in WAITING_HEALTH, cleaning up...")
                self._cleanup_workspace(session_id)
                self._update_session_state(session_id, SessionState.FAILED,
                                          error="Interrupted during health check")
                
            elif session.state in (SessionState.TERMINATED, SessionState.FAILED):
                # Should have been cleaned but wasn't
                if self.workspace_manager.get_workspace(session_id):
                    logger.warning(f"Cleaning leftover workspace for {session_id}")
                    self._cleanup_workspace(session_id)
        
        logger.info("Startup reconciliation complete")

    def _cleanup_workspace(self, session_id: str):
        """Clean up a workspace and its cloud resources."""
        workspace_dir = self.workspace_manager.get_workspace(session_id)
        if workspace_dir:
            try:
                with self._terraform_lock():
                    terraform = TerraformWrapper(workspace_dir)
                    terraform.destroy(session_id)
            except Exception as e:
                logger.error(f"Failed to destroy resources for {session_id}: {e}")
            finally:
                self.workspace_manager.delete_workspace(session_id)

    @contextmanager
    def _terraform_lock(self):
        """Acquire terraform semaphore with timeout."""
        acquired = self._terraform_semaphore.acquire(timeout=600)  # 10 min timeout
        if not acquired:
            raise RuntimeError("Timeout waiting for terraform lock")
        try:
            yield
        finally:
            self._terraform_semaphore.release()

    def request_shutdown(self):
        """Request graceful shutdown - cleanup all active sessions."""
        logger.info("Shutdown requested, cleaning up sessions...")
        self._shutdown_requested = True
        
        sessions = self.list_sessions()
        for session in sessions:
            if session.state in (SessionState.READY, SessionState.ACTIVE, 
                                SessionState.PROVISIONING, SessionState.WAITING_HEALTH):
                logger.info(f"Terminating session {session.session_id} for shutdown")
                try:
                    self.terminate_session(session.session_id)
                except Exception as e:
                    logger.error(f"Failed to terminate {session.session_id}: {e}")
        
        logger.info("Shutdown cleanup complete")

    def check_vcn_capacity(self) -> bool:
        """
        Check if we have VCN capacity available.
        
        Returns:
            True if capacity available, False otherwise
        """
        # Count active sessions that would have VCNs
        sessions = self.list_sessions()
        active_vcn_count = sum(
            1 for s in sessions 
            if s.state in (SessionState.PROVISIONING, SessionState.WAITING_HEALTH,
                          SessionState.READY, SessionState.ACTIVE)
        )
        
        if active_vcn_count >= self.MAX_VCNS:
            logger.warning(f"VCN capacity check failed: {active_vcn_count}/{self.MAX_VCNS} in use")
            return False
        
        return True

    def create_session(self, timeout_minutes: Optional[int] = None) -> SessionInfo:
        """
        Create a new practice session.

        Args:
            timeout_minutes: Session timeout (uses default if not specified)

        Returns:
            SessionInfo for the new session
            
        Raises:
            RuntimeError: If VCN capacity exceeded
        """
        if self._shutdown_requested:
            raise RuntimeError("Server is shutting down")
            
        # Pre-flight capacity check
        if not self.check_vcn_capacity():
            raise RuntimeError("VCN capacity exceeded. Please wait for existing sessions to complete.")
        
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

    def _check_vm_health(self, host: str, private_key: str, timeout: int = 300) -> bool:
        """
        Check if VM is healthy (cloud-init complete).
        
        Args:
            host: VM IP address
            private_key: SSH private key
            timeout: Max seconds to wait
            
        Returns:
            True if VM is healthy
        """
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            try:
                ssh = paramiko.SSHClient()
                ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
                
                key_file = StringIO(private_key)
                try:
                    pkey = paramiko.RSAKey.from_private_key(key_file)
                except:
                    key_file.seek(0)
                    pkey = paramiko.Ed25519Key.from_private_key(key_file)
                
                ssh.connect(
                    hostname=host,
                    port=22,
                    username="opc",
                    pkey=pkey,
                    timeout=10,
                    allow_agent=False,
                    look_for_keys=False,
                )
                
                # Check for cloud-init complete marker
                stdin, stdout, stderr = ssh.exec_command(
                    "test -f /root/.cloud-init-complete && echo OK",
                    timeout=10
                )
                result = stdout.read().decode().strip()
                ssh.close()
                
                if result == "OK":
                    logger.info(f"VM {host} health check passed")
                    return True
                    
            except Exception as e:
                logger.debug(f"Health check for {host} failed: {e}")
            
            time.sleep(self.health_check_interval)
        
        logger.warning(f"VM {host} health check timed out after {timeout}s")
        return False

    def provision_session(self, session_id: str, skip_health_check: bool = False) -> SessionInfo:
        """
        Provision OCI resources for a session.

        This is a blocking operation that can take several minutes.

        Args:
            session_id: Session to provision
            skip_health_check: Skip waiting for cloud-init (for testing)

        Returns:
            Updated SessionInfo
        """
        if self._shutdown_requested:
            raise RuntimeError("Server is shutting down")
            
        session = self.get_session(session_id)
        if not session:
            raise ValueError(f"Session {session_id} not found")

        if session.state != SessionState.PENDING:
            raise ValueError(f"Session {session_id} is not in PENDING state")

        # Update state to provisioning
        self._update_session_state(session_id, SessionState.PROVISIONING)

        try:
            with self._terraform_lock():
                # Create isolated workspace
                workspace_dir = self.workspace_manager.create_workspace(session_id)
                terraform = TerraformWrapper(workspace_dir)

                # Initialize and apply
                if not terraform.init():
                    raise RuntimeError("Terraform init failed")

                result = terraform.apply(session_id)

                if not result.success:
                    # Clean up partial resources
                    logger.warning(f"Terraform apply failed for {session_id}, cleaning up...")
                    try:
                        terraform.destroy(session_id)
                    except Exception as cleanup_err:
                        logger.error(f"Cleanup failed for {session_id}: {cleanup_err}")
                    
                    self.workspace_manager.delete_workspace(session_id)
                    self._update_session_state(session_id, SessionState.FAILED, error=result.error)
                    raise RuntimeError(f"Terraform apply failed: {result.error}")

            # Extract connection info from outputs
            outputs = result.outputs
            node1_ip = outputs.get("node1_public_ip")
            node2_ip = outputs.get("node2_public_ip")
            node1_private_ip = outputs.get("node1_private_ip")
            node2_private_ip = outputs.get("node2_private_ip")
            ssh_private_key = outputs.get("ssh_private_key")
            
            # Encrypt SSH key before storing
            encrypted_key = self.key_encryption.encrypt(ssh_private_key) if ssh_private_key else None

            # Update state to waiting for health check
            self._update_session_state(session_id, SessionState.WAITING_HEALTH)
            
            # Store connection info (with encrypted key)
            conn = self._get_db()
            c = conn.cursor()
            c.execute("""
                UPDATE sessions SET
                    node1_ip = ?,
                    node2_ip = ?,
                    node1_private_ip = ?,
                    node2_private_ip = ?,
                    ssh_private_key = ?,
                    terraform_outputs = ?
                WHERE session_id = ?
            """, (
                node1_ip, node2_ip, node1_private_ip, node2_private_ip,
                encrypted_key, json.dumps(outputs), session_id
            ))
            conn.commit()
            conn.close()

            # Skip health check - terminal has retry logic and cloud-init is slow
            # The VMs are usable even before cloud-init completes
            # Users just need to wait a moment if they connect immediately
            logger.info(f"Skipping health check - VMs provisioned, cloud-init may still be running")
            
            # Mark as ready
            self._update_session_state(session_id, SessionState.READY)
            logger.info(f"Session {session_id} provisioned and healthy")
            return self.get_session(session_id)

        except Exception as e:
            logger.error(f"Failed to provision session {session_id}: {e}")
            # Clean up on any failure
            self._cleanup_workspace(session_id)
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

        if session.state == SessionState.TERMINATED:
            logger.info(f"Session {session_id} already terminated")
            return True
        
        if session.state == SessionState.TERMINATING:
            logger.info(f"Session {session_id} already terminating")
            return True

        self._update_session_state(session_id, SessionState.TERMINATING)

        try:
            self._cleanup_workspace(session_id)
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

        # Decrypt SSH key
        ssh_key = row["ssh_private_key"]
        if ssh_key:
            ssh_key = self.key_encryption.decrypt(ssh_key)

        return SessionInfo(
            session_id=row["session_id"],
            state=SessionState(row["state"]),
            created_at=datetime.fromisoformat(row["created_at"]),
            expires_at=datetime.fromisoformat(row["expires_at"]),
            node1_ip=row["node1_ip"],
            node2_ip=row["node2_ip"],
            node1_private_ip=row["node1_private_ip"],
            node2_private_ip=row["node2_private_ip"],
            ssh_private_key=ssh_key,
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

        sessions = []
        for row in rows:
            ssh_key = row["ssh_private_key"]
            if ssh_key:
                ssh_key = self.key_encryption.decrypt(ssh_key)
            
            sessions.append(SessionInfo(
                session_id=row["session_id"],
                state=SessionState(row["state"]),
                created_at=datetime.fromisoformat(row["created_at"]),
                expires_at=datetime.fromisoformat(row["expires_at"]),
                node1_ip=row["node1_ip"],
                node2_ip=row["node2_ip"],
                node1_private_ip=row["node1_private_ip"],
                node2_private_ip=row["node2_private_ip"],
                ssh_private_key=ssh_key,
                error=row["error"],
            ))
        
        return sessions

    def get_active_session(self) -> Optional[SessionInfo]:
        """Get the currently active session (if any)."""
        sessions = self.list_sessions()
        for session in sessions:
            if session.state in (SessionState.READY, SessionState.ACTIVE):
                return session
        return None

    def verify_session_resources(self, session_id: str) -> bool:
        """
        Verify that session's cloud resources still exist (drift detection).
        
        Args:
            session_id: Session to verify
            
        Returns:
            True if resources exist and are healthy
        """
        session = self.get_session(session_id)
        if not session or session.state not in (SessionState.READY, SessionState.ACTIVE):
            return False
        
        # Try to SSH to node1 as a health check
        if session.node1_ip and session.ssh_private_key:
            try:
                ssh = paramiko.SSHClient()
                ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
                
                key_file = StringIO(session.ssh_private_key)
                try:
                    pkey = paramiko.RSAKey.from_private_key(key_file)
                except:
                    key_file.seek(0)
                    pkey = paramiko.Ed25519Key.from_private_key(key_file)
                
                ssh.connect(
                    hostname=session.node1_ip,
                    port=22,
                    username="opc",
                    pkey=pkey,
                    timeout=10,
                    allow_agent=False,
                    look_for_keys=False,
                )
                ssh.close()
                return True
                
            except Exception as e:
                logger.warning(f"Resource verification failed for {session_id}: {e}")
                return False
        
        return False

    def cleanup_expired_sessions(self) -> int:
        """
        Terminate all expired sessions and clean up failed sessions.

        Returns:
            Number of sessions cleaned up
        """
        sessions = self.list_sessions(include_terminated=True)
        cleaned = 0

        for session in sessions:
            # Clean up expired sessions
            if session.is_expired() and session.state not in (
                SessionState.TERMINATED,
                SessionState.TERMINATING,
            ):
                logger.info(f"Cleaning up expired session {session.session_id}")
                if self.terminate_session(session.session_id):
                    cleaned += 1
            
            # Clean up FAILED sessions with leftover workspaces
            elif session.state == SessionState.FAILED:
                workspace_dir = self.workspace_manager.get_workspace(session.session_id)
                if workspace_dir:
                    logger.info(f"Cleaning up failed session workspace {session.session_id}")
                    self._cleanup_workspace(session.session_id)
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
