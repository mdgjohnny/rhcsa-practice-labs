"""Centralized configuration for RHCSA Practice Labs.

All configuration values can be overridden via environment variables.
See .env.example for documentation of all available options.
"""

import logging
import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

# Try to load .env file if python-dotenv is available
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass


def _get_bool(key: str, default: bool = False) -> bool:
    """Get boolean from environment variable."""
    value = os.getenv(key, str(default)).lower()
    return value in ('true', '1', 'yes', 'on')


def _get_int(key: str, default: int) -> int:
    """Get integer from environment variable."""
    try:
        return int(os.getenv(key, str(default)))
    except ValueError:
        return default


@dataclass
class ServerConfig:
    """HTTP server configuration."""
    host: str = field(default_factory=lambda: os.getenv('RHCSA_HOST', '0.0.0.0'))
    port: int = field(default_factory=lambda: _get_int('RHCSA_PORT', 8080))
    debug: bool = field(default_factory=lambda: _get_bool('RHCSA_DEBUG', False))
    secret_key: str = field(
        default_factory=lambda: os.getenv('RHCSA_SECRET_KEY', 'dev-secret-change-in-production')
    )


@dataclass
class LoggingConfig:
    """Logging configuration."""
    level: str = field(default_factory=lambda: os.getenv('RHCSA_LOG_LEVEL', 'INFO'))
    format: str = field(
        default_factory=lambda: os.getenv(
            'RHCSA_LOG_FORMAT',
            '%(asctime)s [%(levelname)s] %(message)s'
        )
    )
    
    def get_level(self) -> int:
        """Convert string level to logging constant."""
        return getattr(logging, self.level.upper(), logging.INFO)


@dataclass
class PathsConfig:
    """File and directory paths."""
    base_dir: Path = field(default_factory=lambda: Path(__file__).parent.parent)
    
    @property
    def checks_dir(self) -> Path:
        """Directory containing task check scripts."""
        return self.base_dir / 'checks'
    
    @property
    def static_dir(self) -> Path:
        """Directory containing static files."""
        return self.base_dir / 'static'
    
    @property
    def infra_dir(self) -> Path:
        """Directory containing Terraform infrastructure."""
        return self.base_dir / 'infra'
    
    @property
    def workspaces_dir(self) -> Path:
        """Directory for Terraform workspaces."""
        return self.base_dir / 'workspaces'


@dataclass
class DatabaseConfig:
    """Database configuration."""
    sessions_db: Path = field(
        default_factory=lambda: Path(
            os.getenv('RHCSA_SESSIONS_DB', str(Path(__file__).parent.parent / 'sessions.db'))
        )
    )
    results_db: Path = field(
        default_factory=lambda: Path(
            os.getenv('RHCSA_RESULTS_DB', str(Path(__file__).parent.parent / 'results.db'))
        )
    )
    flashcards_db: Path = field(
        default_factory=lambda: Path(
            os.getenv('RHCSA_FLASHCARDS_DB', str(Path(__file__).parent.parent / 'flashcards.db'))
        )
    )


@dataclass
class SSHConfig:
    """SSH connection defaults."""
    timeout: int = field(default_factory=lambda: _get_int('RHCSA_SSH_TIMEOUT', 30))
    connect_timeout: int = field(default_factory=lambda: _get_int('RHCSA_SSH_CONNECT_TIMEOUT', 10))
    default_user: str = field(default_factory=lambda: os.getenv('RHCSA_SSH_USER', 'root'))
    default_port: int = field(default_factory=lambda: _get_int('RHCSA_SSH_PORT', 22))


@dataclass
class SessionConfig:
    """Session management configuration."""
    default_timeout_minutes: int = field(
        default_factory=lambda: _get_int('RHCSA_SESSION_TIMEOUT', 120)
    )
    max_timeout_minutes: int = field(
        default_factory=lambda: _get_int('RHCSA_SESSION_MAX_TIMEOUT', 480)
    )
    cleanup_interval_seconds: int = field(
        default_factory=lambda: _get_int('RHCSA_CLEANUP_INTERVAL', 300)
    )
    health_check_interval_seconds: int = field(
        default_factory=lambda: _get_int('RHCSA_HEALTH_CHECK_INTERVAL', 60)
    )


@dataclass
class StaticVMsConfig:
    """Configuration for static/local VMs (non-cloud)."""
    enabled: bool = False
    node1_ip: Optional[str] = None
    node2_ip: Optional[str] = None
    node1_private_ip: Optional[str] = None
    node2_private_ip: Optional[str] = None
    ssh_user: str = 'root'
    ssh_password: Optional[str] = None
    ssh_private_key_path: Optional[str] = None
    
    @classmethod
    def from_json_file(cls, path: Path) -> 'StaticVMsConfig':
        """Load configuration from static_vms.json."""
        import json
        
        if not path.exists():
            return cls()
        
        try:
            with open(path) as f:
                data = json.load(f)
            
            return cls(
                enabled=data.get('enabled', True),
                node1_ip=data.get('node1_ip'),
                node2_ip=data.get('node2_ip'),
                node1_private_ip=data.get('node1_private_ip'),
                node2_private_ip=data.get('node2_private_ip'),
                ssh_user=data.get('ssh_user', 'root'),
                ssh_password=data.get('ssh_password'),
                ssh_private_key_path=data.get('ssh_private_key_path'),
            )
        except (json.JSONDecodeError, KeyError) as e:
            logging.warning(f"Failed to load static_vms.json: {e}")
            return cls()


@dataclass
class Config:
    """Main application configuration.
    
    Usage:
        from api.config import config
        
        print(config.server.port)  # 8080
        print(config.paths.checks_dir)  # /path/to/checks
    """
    server: ServerConfig = field(default_factory=ServerConfig)
    logging: LoggingConfig = field(default_factory=LoggingConfig)
    paths: PathsConfig = field(default_factory=PathsConfig)
    database: DatabaseConfig = field(default_factory=DatabaseConfig)
    ssh: SSHConfig = field(default_factory=SSHConfig)
    session: SessionConfig = field(default_factory=SessionConfig)
    static_vms: StaticVMsConfig = field(default_factory=StaticVMsConfig)
    
    def __post_init__(self) -> None:
        """Load static VMs config if file exists."""
        static_vms_path = self.paths.base_dir / 'static_vms.json'
        if static_vms_path.exists():
            self.static_vms = StaticVMsConfig.from_json_file(static_vms_path)
    
    def setup_logging(self) -> "logging.Logger":
        """Configure application logging and return the root logger."""
        logging.basicConfig(
            level=self.logging.get_level(),
            format=self.logging.format,
        )
        return logging.getLogger('rhcsa-labs')


# Global configuration instance
config = Config()

# Convenience exports for backwards compatibility
BASE_DIR = config.paths.base_dir
CHECKS_DIR = config.paths.checks_dir
STATIC_DIR = config.paths.static_dir
DEBUG = config.server.debug
LOG_LEVEL = config.logging.level
