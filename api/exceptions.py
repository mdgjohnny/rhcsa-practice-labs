"""Custom exceptions for RHCSA Practice Labs.

This module defines a hierarchy of exceptions for better error handling
and more informative error messages throughout the application.

Exception Hierarchy:
    RHCSALabsError (base)
    ├── ConfigurationError
    ├── SSHError
    │   ├── SSHConnectionError
    │   ├── SSHAuthenticationError
    │   └── SSHCommandError
    ├── SessionError
    │   ├── SessionNotFoundError
    │   ├── SessionExpiredError
    │   └── SessionProvisioningError
    ├── GraderError
    │   ├── TaskNotFoundError
    │   └── GradingTimeoutError
    └── TerraformError
"""

from typing import Optional


class RHCSALabsError(Exception):
    """Base exception for all RHCSA Practice Labs errors.
    
    All custom exceptions should inherit from this class to allow
    catching all application-specific errors with a single except clause.
    
    Example:
        try:
            do_something()
        except RHCSALabsError as e:
            logger.error(f"Application error: {e}")
    """
    pass


# =============================================================================
# Configuration Errors
# =============================================================================

class ConfigurationError(RHCSALabsError):
    """Invalid or missing configuration.
    
    Raised when required configuration is missing or has invalid values.
    
    Example:
        if not config.ssh.host:
            raise ConfigurationError("SSH host not configured")
    """
    pass


# =============================================================================
# SSH Errors
# =============================================================================

class SSHError(RHCSALabsError):
    """Base class for SSH-related errors."""
    pass


class SSHConnectionError(SSHError):
    """Failed to establish SSH connection.
    
    Raised when the SSH client cannot connect to the remote host.
    This could be due to network issues, firewall rules, or the
    remote host being unavailable.
    
    Attributes:
        host: The hostname or IP that couldn't be reached.
        port: The port that was attempted.
    """
    
    def __init__(
        self, 
        message: str, 
        host: Optional[str] = None, 
        port: Optional[int] = None
    ):
        super().__init__(message)
        self.host = host
        self.port = port
    
    def __str__(self) -> str:
        base = super().__str__()
        if self.host:
            return f"{base} (host={self.host}, port={self.port or 22})"
        return base


class SSHAuthenticationError(SSHError):
    """SSH authentication failed.
    
    Raised when SSH connection is established but authentication fails.
    This could be due to wrong password, invalid key, or permission issues.
    
    Attributes:
        user: The username that failed to authenticate.
        auth_method: The authentication method that was attempted.
    """
    
    def __init__(
        self, 
        message: str, 
        user: Optional[str] = None,
        auth_method: Optional[str] = None
    ):
        super().__init__(message)
        self.user = user
        self.auth_method = auth_method


class SSHCommandError(SSHError):
    """SSH command execution failed.
    
    Raised when an SSH command returns a non-zero exit code or
    fails to execute properly.
    
    Attributes:
        command: The command that was executed.
        exit_code: The exit code returned by the command.
        stdout: Standard output from the command.
        stderr: Standard error from the command.
    """
    
    def __init__(
        self,
        message: str,
        command: Optional[str] = None,
        exit_code: Optional[int] = None,
        stdout: Optional[str] = None,
        stderr: Optional[str] = None
    ):
        super().__init__(message)
        self.command = command
        self.exit_code = exit_code
        self.stdout = stdout
        self.stderr = stderr
    
    def __str__(self) -> str:
        base = super().__str__()
        parts = [base]
        if self.exit_code is not None:
            parts.append(f"exit_code={self.exit_code}")
        if self.stderr:
            # Truncate long stderr
            stderr_preview = self.stderr[:200] + '...' if len(self.stderr) > 200 else self.stderr
            parts.append(f"stderr={stderr_preview!r}")
        return " | ".join(parts)


# =============================================================================
# Session Errors
# =============================================================================

class SessionError(RHCSALabsError):
    """Base class for session management errors."""
    pass


class SessionNotFoundError(SessionError):
    """Session does not exist.
    
    Raised when attempting to access a session that doesn't exist
    in the database or has been deleted.
    
    Attributes:
        session_id: The session ID that wasn't found.
    """
    
    def __init__(self, session_id: str):
        super().__init__(f"Session not found: {session_id}")
        self.session_id = session_id


class SessionExpiredError(SessionError):
    """Session has expired.
    
    Raised when attempting to use a session that has exceeded
    its time limit.
    
    Attributes:
        session_id: The expired session ID.
        expired_at: When the session expired.
    """
    
    def __init__(self, session_id: str, expired_at: Optional[str] = None):
        msg = f"Session expired: {session_id}"
        if expired_at:
            msg += f" (at {expired_at})"
        super().__init__(msg)
        self.session_id = session_id
        self.expired_at = expired_at


class SessionProvisioningError(SessionError):
    """Failed to provision session resources.
    
    Raised when cloud resources (VMs, networks, etc.) cannot be
    created or configured for a session.
    
    Attributes:
        session_id: The session that failed provisioning.
        stage: The provisioning stage where failure occurred.
    """
    
    def __init__(
        self, 
        message: str, 
        session_id: Optional[str] = None,
        stage: Optional[str] = None
    ):
        super().__init__(message)
        self.session_id = session_id
        self.stage = stage


# =============================================================================
# Grader Errors
# =============================================================================

class GraderError(RHCSALabsError):
    """Base class for grading errors."""
    pass


class TaskNotFoundError(GraderError):
    """Task does not exist.
    
    Raised when attempting to grade or access a task that doesn't
    exist in the checks directory.
    
    Attributes:
        task_id: The task ID that wasn't found.
    """
    
    def __init__(self, task_id: str):
        super().__init__(f"Task not found: {task_id}")
        self.task_id = task_id


class GradingTimeoutError(GraderError):
    """Task grading timed out.
    
    Raised when a task takes too long to grade, usually due to
    slow network or unresponsive VMs.
    
    Attributes:
        task_id: The task that timed out.
        timeout_seconds: The timeout that was exceeded.
    """
    
    def __init__(self, task_id: str, timeout_seconds: int):
        super().__init__(f"Grading timed out for {task_id} after {timeout_seconds}s")
        self.task_id = task_id
        self.timeout_seconds = timeout_seconds


# =============================================================================
# Terraform Errors
# =============================================================================

class TerraformError(RHCSALabsError):
    """Terraform operation failed.
    
    Raised when a Terraform command (init, plan, apply, destroy)
    fails to execute successfully.
    
    Attributes:
        operation: The Terraform operation that failed (init, apply, etc.).
        stdout: Standard output from Terraform.
        stderr: Standard error from Terraform.
        workspace: The Terraform workspace where the error occurred.
    """
    
    def __init__(
        self,
        message: str,
        operation: Optional[str] = None,
        stdout: Optional[str] = None,
        stderr: Optional[str] = None,
        workspace: Optional[str] = None
    ):
        super().__init__(message)
        self.operation = operation
        self.stdout = stdout
        self.stderr = stderr
        self.workspace = workspace
    
    def __str__(self) -> str:
        base = super().__str__()
        if self.operation:
            base = f"terraform {self.operation}: {base}"
        return base
