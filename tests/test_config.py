"""Tests for the configuration module."""

import os
import tempfile
from pathlib import Path

import pytest


class TestServerConfig:
    """Tests for ServerConfig."""
    
    def test_default_values(self, clean_env):
        """Test default configuration values."""
        # Import fresh to get defaults
        from importlib import reload
        import api.config
        reload(api.config)
        
        from api.config import config
        
        assert config.server.host == '127.0.0.1'
        assert config.server.port == 8080
        assert config.server.debug is False
    
    def test_environment_override(self, monkeypatch):
        """Test that environment variables override defaults."""
        monkeypatch.setenv('RHCSA_HOST', '127.0.0.1')
        monkeypatch.setenv('RHCSA_PORT', '9000')
        monkeypatch.setenv('RHCSA_DEBUG', 'true')
        
        # Reload to pick up new env vars
        from importlib import reload
        import api.config
        reload(api.config)
        
        from api.config import config
        
        assert config.server.host == '127.0.0.1'
        assert config.server.port == 9000
        assert config.server.debug is True
    
    def test_invalid_port_uses_default(self, monkeypatch):
        """Test that invalid port value falls back to default."""
        monkeypatch.setenv('RHCSA_PORT', 'not-a-number')
        
        from importlib import reload
        import api.config
        reload(api.config)
        
        from api.config import config
        
        assert config.server.port == 8080


class TestLoggingConfig:
    """Tests for LoggingConfig."""
    
    def test_default_level(self, clean_env):
        """Test default log level."""
        from importlib import reload
        import api.config
        reload(api.config)
        
        from api.config import config
        import logging
        
        assert config.logging.level == 'INFO'
        assert config.logging.get_level() == logging.INFO
    
    def test_custom_level(self, monkeypatch):
        """Test custom log level."""
        monkeypatch.setenv('RHCSA_LOG_LEVEL', 'DEBUG')
        
        from importlib import reload
        import api.config
        reload(api.config)
        
        from api.config import config
        import logging
        
        assert config.logging.level == 'DEBUG'
        assert config.logging.get_level() == logging.DEBUG


class TestPathsConfig:
    """Tests for PathsConfig."""
    
    def test_paths_exist(self, clean_env):
        """Test that path properties return Path objects."""
        from importlib import reload
        import api.config
        reload(api.config)
        
        from api.config import config
        
        assert isinstance(config.paths.base_dir, Path)
        assert isinstance(config.paths.checks_dir, Path)
        assert isinstance(config.paths.static_dir, Path)
    
    def test_checks_dir_is_subdir(self, clean_env):
        """Test that checks_dir is under base_dir."""
        from importlib import reload
        import api.config
        reload(api.config)
        
        from api.config import config
        
        assert config.paths.checks_dir.parent == config.paths.base_dir
        assert config.paths.checks_dir.name == 'checks'


class TestSSHConfig:
    """Tests for SSHConfig."""
    
    def test_default_timeout(self, clean_env):
        """Test default SSH timeout."""
        from importlib import reload
        import api.config
        reload(api.config)
        
        from api.config import config
        
        assert config.ssh.timeout == 30
        assert config.ssh.connect_timeout == 10
    
    def test_custom_timeout(self, monkeypatch):
        """Test custom SSH timeout."""
        monkeypatch.setenv('RHCSA_SSH_TIMEOUT', '60')
        
        from importlib import reload
        import api.config
        reload(api.config)
        
        from api.config import config
        
        assert config.ssh.timeout == 60


class TestStaticVMsConfig:
    """Tests for StaticVMsConfig."""
    
    def test_disabled_by_default(self, clean_env):
        """Test that static VMs are disabled by default."""
        from importlib import reload
        import api.config
        reload(api.config)
        
        from api.config import StaticVMsConfig
        
        config = StaticVMsConfig()
        assert config.enabled is False
        assert config.node1_ip is None
    
    def test_load_from_json(self, tmp_path):
        """Test loading config from JSON file."""
        import json
        from api.config import StaticVMsConfig
        
        config_data = {
            'enabled': True,
            'node1_ip': '192.168.1.10',
            'node2_ip': '192.168.1.11',
            'ssh_user': 'testuser',
            'ssh_password': 'testpass',
        }
        
        config_file = tmp_path / 'static_vms.json'
        config_file.write_text(json.dumps(config_data))
        
        config = StaticVMsConfig.from_json_file(config_file)
        
        assert config.enabled is True
        assert config.node1_ip == '192.168.1.10'
        assert config.node2_ip == '192.168.1.11'
        assert config.ssh_user == 'testuser'
        assert config.ssh_password == 'testpass'
    
    def test_load_missing_file(self, tmp_path):
        """Test loading from non-existent file returns defaults."""
        from api.config import StaticVMsConfig
        
        config_file = tmp_path / 'nonexistent.json'
        config = StaticVMsConfig.from_json_file(config_file)
        
        assert config.enabled is False
        assert config.node1_ip is None
    
    def test_load_invalid_json(self, tmp_path):
        """Test loading from invalid JSON returns defaults."""
        from api.config import StaticVMsConfig
        
        config_file = tmp_path / 'invalid.json'
        config_file.write_text('not valid json {')
        
        config = StaticVMsConfig.from_json_file(config_file)
        
        assert config.enabled is False


class TestBackwardsCompatibility:
    """Tests for backwards compatibility exports."""
    
    def test_legacy_exports(self, clean_env):
        """Test that legacy exports are available."""
        from importlib import reload
        import api.config
        reload(api.config)
        
        from api.config import BASE_DIR, CHECKS_DIR, STATIC_DIR, DEBUG, LOG_LEVEL
        
        assert isinstance(BASE_DIR, Path)
        assert isinstance(CHECKS_DIR, Path)
        assert isinstance(STATIC_DIR, Path)
        assert isinstance(DEBUG, bool)
        assert isinstance(LOG_LEVEL, str)
