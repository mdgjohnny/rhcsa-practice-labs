"""Pytest fixtures for RHCSA Practice Labs tests.

This module provides reusable fixtures for testing Flask routes,
mocking SSH connections, and setting up test databases.
"""

import os
import sys
import tempfile
from pathlib import Path
from typing import Generator
from unittest.mock import MagicMock, patch

import pytest

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent))


# =============================================================================
# Flask App Fixtures
# =============================================================================

@pytest.fixture
def app():
    """Create Flask application for testing.
    
    Yields:
        Flask: Configured test application.
    """
    # Set test configuration before importing app
    os.environ['RHCSA_DEBUG'] = 'false'
    os.environ['RHCSA_LOG_LEVEL'] = 'WARNING'
    
    from api.app import app as flask_app
    
    flask_app.config.update({
        'TESTING': True,
        'DEBUG': False,
    })
    
    yield flask_app


@pytest.fixture
def client(app):
    """Flask test client.
    
    Args:
        app: Flask application fixture.
        
    Yields:
        FlaskClient: Test client for making HTTP requests.
    """
    with app.test_client() as test_client:
        yield test_client


@pytest.fixture
def app_context(app):
    """Flask application context.
    
    Args:
        app: Flask application fixture.
        
    Yields:
        AppContext: Application context for database access.
    """
    with app.app_context():
        yield


# =============================================================================
# Database Fixtures
# =============================================================================

@pytest.fixture
def temp_db() -> Generator[Path, None, None]:
    """Create a temporary SQLite database.
    
    Yields:
        Path: Path to the temporary database file.
    """
    with tempfile.NamedTemporaryFile(suffix='.db', delete=False) as f:
        db_path = Path(f.name)
    
    yield db_path
    
    # Cleanup
    if db_path.exists():
        db_path.unlink()


@pytest.fixture
def mock_sessions_db(temp_db, monkeypatch):
    """Mock the sessions database with a temporary file.
    
    Args:
        temp_db: Temporary database path.
        monkeypatch: Pytest monkeypatch fixture.
        
    Returns:
        Path: Path to the mock database.
    """
    monkeypatch.setenv('RHCSA_SESSIONS_DB', str(temp_db))
    return temp_db


# =============================================================================
# SSH Mocking Fixtures
# =============================================================================

@pytest.fixture
def mock_ssh_client():
    """Mock SSH client for unit tests.
    
    Returns:
        MagicMock: Mock SSH client that returns success by default.
    """
    with patch('paramiko.SSHClient') as mock_class:
        mock_client = MagicMock()
        mock_class.return_value = mock_client
        
        # Mock successful connection
        mock_client.connect.return_value = None
        
        # Mock successful command execution
        mock_stdout = MagicMock()
        mock_stdout.read.return_value = b'success\n'
        mock_stdout.channel.recv_exit_status.return_value = 0
        
        mock_stderr = MagicMock()
        mock_stderr.read.return_value = b''
        
        mock_client.exec_command.return_value = (MagicMock(), mock_stdout, mock_stderr)
        
        yield mock_client


@pytest.fixture
def mock_ssh_failure():
    """Mock SSH client that fails to connect.
    
    Returns:
        MagicMock: Mock SSH client that raises connection errors.
    """
    import paramiko
    
    with patch('paramiko.SSHClient') as mock_class:
        mock_client = MagicMock()
        mock_class.return_value = mock_client
        mock_client.connect.side_effect = paramiko.SSHException("Connection refused")
        
        yield mock_client


# =============================================================================
# Grader Fixtures
# =============================================================================

@pytest.fixture
def mock_grader_service():
    """Mock grader service for API tests.
    
    Returns:
        MagicMock: Mock grader service with common methods.
    """
    with patch('api.app.get_grader_service') as mock_get:
        mock_service = MagicMock()
        mock_get.return_value = mock_service
        
        # Default responses
        mock_service.list_tasks.return_value = [
            {
                'id': 'task-01',
                'title': 'Test Task',
                'category': 'test',
                'description': 'A test task',
                'target': 'node1',
                'points': 10,
            }
        ]
        
        mock_service.grade_task.return_value = {
            'task_id': 'task-01',
            'passed': True,
            'checks': [
                {'check': 'Test passed', 'passed': True, 'points': 10}
            ],
        }
        
        yield mock_service


# =============================================================================
# Task Fixtures
# =============================================================================

@pytest.fixture
def sample_task_file(tmp_path) -> Path:
    """Create a sample task check script.
    
    Args:
        tmp_path: Pytest temporary path fixture.
        
    Returns:
        Path: Path to the sample task file.
    """
    task_content = '''#!/usr/bin/env bash
# Task: Create a test file
# Title: Create Test File
# Category: test
# Target: node1

check '[[ -f /tmp/testfile ]]' \\
    "Test file exists" \\
    "Test file not found"
'''
    
    task_file = tmp_path / 'checks' / 'task-test.sh'
    task_file.parent.mkdir(parents=True, exist_ok=True)
    task_file.write_text(task_content)
    task_file.chmod(0o755)
    
    return task_file


@pytest.fixture
def checks_dir(tmp_path, sample_task_file) -> Path:
    """Create a checks directory with sample tasks.
    
    Args:
        tmp_path: Pytest temporary path fixture.
        sample_task_file: Sample task file fixture.
        
    Returns:
        Path: Path to the checks directory.
    """
    return sample_task_file.parent


# =============================================================================
# Configuration Fixtures
# =============================================================================

@pytest.fixture
def clean_env(monkeypatch):
    """Clear all RHCSA environment variables.
    
    Args:
        monkeypatch: Pytest monkeypatch fixture.
    """
    env_vars = [
        'RHCSA_HOST', 'RHCSA_PORT', 'RHCSA_DEBUG',
        'RHCSA_LOG_LEVEL', 'RHCSA_SECRET_KEY',
        'RHCSA_SSH_TIMEOUT', 'RHCSA_SSH_USER',
        'RHCSA_SESSIONS_DB', 'RHCSA_RESULTS_DB',
    ]
    for var in env_vars:
        monkeypatch.delenv(var, raising=False)


@pytest.fixture
def custom_config(monkeypatch):
    """Set custom configuration via environment.
    
    Args:
        monkeypatch: Pytest monkeypatch fixture.
        
    Returns:
        dict: The configuration values that were set.
    """
    config = {
        'RHCSA_PORT': '9999',
        'RHCSA_DEBUG': 'true',
        'RHCSA_LOG_LEVEL': 'DEBUG',
        'RHCSA_SSH_TIMEOUT': '60',
    }
    
    for key, value in config.items():
        monkeypatch.setenv(key, value)
    
    return config
