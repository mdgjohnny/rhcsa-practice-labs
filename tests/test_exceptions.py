"""Tests for the exceptions module."""

import pytest

from api.exceptions import (
    RHCSALabsError,
    ConfigurationError,
    SSHError,
    SSHConnectionError,
    SSHAuthenticationError,
    SSHCommandError,
    SessionError,
    SessionNotFoundError,
    SessionExpiredError,
    SessionProvisioningError,
    GraderError,
    TaskNotFoundError,
    GradingTimeoutError,
    TerraformError,
)


class TestExceptionHierarchy:
    """Test exception class hierarchy."""
    
    def test_all_inherit_from_base(self):
        """Test all exceptions inherit from RHCSALabsError."""
        exceptions = [
            ConfigurationError("test"),
            SSHError("test"),
            SSHConnectionError("test"),
            SSHAuthenticationError("test"),
            SSHCommandError("test"),
            SessionError("test"),
            SessionNotFoundError("test-id"),
            SessionExpiredError("test-id"),
            SessionProvisioningError("test"),
            GraderError("test"),
            TaskNotFoundError("task-01"),
            GradingTimeoutError("task-01", 30),
            TerraformError("test"),
        ]
        
        for exc in exceptions:
            assert isinstance(exc, RHCSALabsError)
    
    def test_ssh_hierarchy(self):
        """Test SSH exceptions inherit from SSHError."""
        assert issubclass(SSHConnectionError, SSHError)
        assert issubclass(SSHAuthenticationError, SSHError)
        assert issubclass(SSHCommandError, SSHError)
    
    def test_session_hierarchy(self):
        """Test session exceptions inherit from SessionError."""
        assert issubclass(SessionNotFoundError, SessionError)
        assert issubclass(SessionExpiredError, SessionError)
        assert issubclass(SessionProvisioningError, SessionError)
    
    def test_grader_hierarchy(self):
        """Test grader exceptions inherit from GraderError."""
        assert issubclass(TaskNotFoundError, GraderError)
        assert issubclass(GradingTimeoutError, GraderError)


class TestSSHConnectionError:
    """Tests for SSHConnectionError."""
    
    def test_basic_message(self):
        """Test basic error message."""
        exc = SSHConnectionError("Connection failed")
        assert str(exc) == "Connection failed"
    
    def test_with_host_info(self):
        """Test error message includes host info."""
        exc = SSHConnectionError("Connection failed", host="192.168.1.10", port=22)
        assert "192.168.1.10" in str(exc)
        assert "22" in str(exc)
    
    def test_attributes(self):
        """Test exception attributes."""
        exc = SSHConnectionError("test", host="example.com", port=2222)
        assert exc.host == "example.com"
        assert exc.port == 2222


class TestSSHCommandError:
    """Tests for SSHCommandError."""
    
    def test_basic_message(self):
        """Test basic error message."""
        exc = SSHCommandError("Command failed")
        assert str(exc) == "Command failed"
    
    def test_with_exit_code(self):
        """Test error includes exit code."""
        exc = SSHCommandError("Command failed", exit_code=1)
        assert "exit_code=1" in str(exc)
    
    def test_with_stderr(self):
        """Test error includes stderr."""
        exc = SSHCommandError("Command failed", stderr="Permission denied")
        assert "Permission denied" in str(exc)
    
    def test_stderr_truncation(self):
        """Test long stderr is truncated."""
        long_stderr = "x" * 500
        exc = SSHCommandError("Command failed", stderr=long_stderr)
        error_str = str(exc)
        assert len(error_str) < 500  # Should be truncated
        assert "..." in error_str
    
    def test_attributes(self):
        """Test exception attributes."""
        exc = SSHCommandError(
            "test",
            command="ls -la",
            exit_code=2,
            stdout="out",
            stderr="err"
        )
        assert exc.command == "ls -la"
        assert exc.exit_code == 2
        assert exc.stdout == "out"
        assert exc.stderr == "err"


class TestSessionErrors:
    """Tests for session-related exceptions."""
    
    def test_session_not_found(self):
        """Test SessionNotFoundError."""
        exc = SessionNotFoundError("abc-123")
        assert "abc-123" in str(exc)
        assert exc.session_id == "abc-123"
    
    def test_session_expired(self):
        """Test SessionExpiredError."""
        exc = SessionExpiredError("abc-123", expired_at="2024-01-15 10:30:00")
        assert "abc-123" in str(exc)
        assert "2024-01-15" in str(exc)
        assert exc.session_id == "abc-123"
        assert exc.expired_at == "2024-01-15 10:30:00"
    
    def test_session_provisioning(self):
        """Test SessionProvisioningError."""
        exc = SessionProvisioningError(
            "Failed to create VM",
            session_id="abc-123",
            stage="terraform_apply"
        )
        assert exc.session_id == "abc-123"
        assert exc.stage == "terraform_apply"


class TestGraderErrors:
    """Tests for grader-related exceptions."""
    
    def test_task_not_found(self):
        """Test TaskNotFoundError."""
        exc = TaskNotFoundError("task-999")
        assert "task-999" in str(exc)
        assert exc.task_id == "task-999"
    
    def test_grading_timeout(self):
        """Test GradingTimeoutError."""
        exc = GradingTimeoutError("task-01", timeout_seconds=30)
        assert "task-01" in str(exc)
        assert "30" in str(exc)
        assert exc.task_id == "task-01"
        assert exc.timeout_seconds == 30


class TestTerraformError:
    """Tests for TerraformError."""
    
    def test_basic_message(self):
        """Test basic error message."""
        exc = TerraformError("Apply failed")
        assert str(exc) == "Apply failed"
    
    def test_with_operation(self):
        """Test error includes operation."""
        exc = TerraformError("Resource not found", operation="apply")
        assert "terraform apply" in str(exc)
    
    def test_attributes(self):
        """Test exception attributes."""
        exc = TerraformError(
            "Failed",
            operation="destroy",
            stdout="stdout content",
            stderr="stderr content",
            workspace="session-123"
        )
        assert exc.operation == "destroy"
        assert exc.stdout == "stdout content"
        assert exc.stderr == "stderr content"
        assert exc.workspace == "session-123"


class TestExceptionCatching:
    """Test that exceptions can be caught at various levels."""
    
    def test_catch_all_with_base(self):
        """Test catching all app exceptions with base class."""
        exceptions_to_try = [
            SSHConnectionError("test"),
            SessionNotFoundError("test"),
            TaskNotFoundError("test"),
            TerraformError("test"),
        ]
        
        for exc in exceptions_to_try:
            try:
                raise exc
            except RHCSALabsError as caught:
                assert caught is exc
    
    def test_catch_ssh_group(self):
        """Test catching SSH exceptions as a group."""
        try:
            raise SSHCommandError("test", exit_code=1)
        except SSHError as caught:
            assert isinstance(caught, SSHCommandError)
    
    def test_specific_catch_takes_precedence(self):
        """Test specific exception catch takes precedence."""
        exc = SSHConnectionError("test")
        caught_type = None
        
        try:
            raise exc
        except SSHConnectionError:
            caught_type = "specific"
        except SSHError:
            caught_type = "general"
        except RHCSALabsError:
            caught_type = "base"
        
        assert caught_type == "specific"
