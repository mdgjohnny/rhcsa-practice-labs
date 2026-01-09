"""Execution backends for running grading scripts locally or remotely.

This module provides a clean abstraction for executing bash scripts either
locally or on remote VMs via SSH. The same script can run anywhere.
"""

import logging
import os
import subprocess
import tempfile
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Optional

logger = logging.getLogger(__name__)

# SSH options for reliable non-interactive connections
SSH_OPTS = [
    '-o', 'ConnectTimeout=10',
    '-o', 'StrictHostKeyChecking=no',
    '-o', 'UserKnownHostsFile=/dev/null',
    '-o', 'BatchMode=yes',
    '-o', 'LogLevel=ERROR',
]


@dataclass
class ExecutionResult:
    """Result of script execution."""
    stdout: str
    stderr: str
    returncode: int
    success: bool

    @classmethod
    def from_completed_process(cls, result: subprocess.CompletedProcess) -> 'ExecutionResult':
        return cls(
            stdout=result.stdout,
            stderr=result.stderr,
            returncode=result.returncode,
            success=result.returncode == 0
        )

    @classmethod
    def error(cls, message: str) -> 'ExecutionResult':
        return cls(stdout='', stderr=message, returncode=1, success=False)


class Executor(ABC):
    """Abstract base class for script execution."""
    
    @abstractmethod
    def execute(self, script: str, timeout: int = 60) -> ExecutionResult:
        """Execute a bash script and return the result."""
        pass
    
    @abstractmethod
    def is_available(self) -> bool:
        """Check if this executor can run (e.g., SSH connectivity)."""
        pass


class LocalExecutor(Executor):
    """Execute scripts locally on this machine."""
    
    def __init__(self, as_root: bool = False):
        self.as_root = as_root
    
    def execute(self, script: str, timeout: int = 60) -> ExecutionResult:
        """Execute script locally."""
        try:
            cmd = ['sudo', 'bash', '-c', script] if self.as_root else ['bash', '-c', script]
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=timeout
            )
            return ExecutionResult.from_completed_process(result)
        except subprocess.TimeoutExpired:
            return ExecutionResult.error(f'Script timed out after {timeout}s')
        except Exception as e:
            return ExecutionResult.error(str(e))
    
    def is_available(self) -> bool:
        return True


class RemoteExecutor(Executor):
    """Execute scripts on a remote VM via SSH."""
    
    def __init__(
        self,
        host: str,
        user: str = 'root',
        key_file: Optional[str] = None,
        password: Optional[str] = None,
        use_sudo: bool = False
    ):
        self.host = host
        self.user = user
        self.key_file = key_file
        self.password = password
        self.use_sudo = use_sudo or (user != 'root')
        
        # Temporary key file if key content is provided
        self._temp_key_file: Optional[str] = None
    
    def _get_key_file(self) -> Optional[str]:
        """Get the path to the SSH key file."""
        if self.key_file and os.path.exists(self.key_file):
            return self.key_file
        return self._temp_key_file
    
    def set_key_content(self, key_content: str) -> None:
        """Set SSH key from content (will create temp file)."""
        if self._temp_key_file:
            os.unlink(self._temp_key_file)
        
        fd, path = tempfile.mkstemp(suffix='.pem')
        try:
            os.write(fd, key_content.encode())
            os.chmod(path, 0o600)
            self._temp_key_file = path
        finally:
            os.close(fd)
    
    def cleanup(self) -> None:
        """Clean up temporary files."""
        if self._temp_key_file and os.path.exists(self._temp_key_file):
            os.unlink(self._temp_key_file)
            self._temp_key_file = None
    
    def _build_ssh_command(self) -> list:
        """Build the base SSH command."""
        cmd = ['ssh'] + SSH_OPTS
        
        key_file = self._get_key_file()
        if key_file:
            cmd.extend(['-i', key_file])
        
        cmd.append(f'{self.user}@{self.host}')
        return cmd
    
    def execute(self, script: str, timeout: int = 60) -> ExecutionResult:
        """Execute script on remote host via SSH."""
        try:
            ssh_cmd = self._build_ssh_command()
            
            # Wrap script in sudo if needed
            if self.use_sudo:
                # Escape the script for sudo bash -c
                remote_cmd = f'sudo bash -s'
            else:
                remote_cmd = 'bash -s'
            
            ssh_cmd.append(remote_cmd)
            
            # Use sshpass if password-based auth
            if self.password and not self._get_key_file():
                ssh_cmd = ['sshpass', '-p', self.password] + ssh_cmd
            
            logger.debug(f"Executing on {self.host}: {remote_cmd}")
            
            result = subprocess.run(
                ssh_cmd,
                input=script,
                capture_output=True,
                text=True,
                timeout=timeout
            )
            return ExecutionResult.from_completed_process(result)
            
        except subprocess.TimeoutExpired:
            return ExecutionResult.error(f'Remote execution timed out after {timeout}s')
        except FileNotFoundError as e:
            if 'sshpass' in str(e):
                return ExecutionResult.error('sshpass not installed (required for password auth)')
            return ExecutionResult.error(str(e))
        except Exception as e:
            return ExecutionResult.error(str(e))
    
    def is_available(self) -> bool:
        """Check SSH connectivity."""
        result = self.execute('echo ok', timeout=10)
        return result.success and 'ok' in result.stdout
    
    def __del__(self):
        self.cleanup()


class ExecutorFactory:
    """Factory for creating executors based on configuration."""
    
    @staticmethod
    def create_local(as_root: bool = False) -> LocalExecutor:
        return LocalExecutor(as_root=as_root)
    
    @staticmethod
    def create_remote(
        host: str,
        user: str = 'root',
        key_file: Optional[str] = None,
        key_content: Optional[str] = None,
        password: Optional[str] = None
    ) -> RemoteExecutor:
        executor = RemoteExecutor(
            host=host,
            user=user,
            key_file=key_file,
            password=password
        )
        if key_content:
            executor.set_key_content(key_content)
        return executor
