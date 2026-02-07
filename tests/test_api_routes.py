"""Tests for Flask API routes in api/app.py."""

import json
import sqlite3
import tempfile
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest


class TestStaticRoutes:
    """Test static file serving routes."""

    def test_index_returns_html(self, client):
        """GET / should return the index.html page."""
        response = client.get('/')
        assert response.status_code == 200
        assert b'<!DOCTYPE html>' in response.data

    def test_favicon_returns_svg(self, client):
        """GET /favicon.svg should return an SVG file."""
        response = client.get('/favicon.svg')
        assert response.status_code == 200
        # SVG files start with either <?xml or <svg
        assert response.data.startswith(b'<svg') or b'<svg' in response.data[:100]


class TestConfigRoutes:
    """Test configuration API routes."""

    def test_get_config_returns_defaults(self, client):
        """GET /api/config should return default config when no config file exists."""
        with patch('api.app.CONFIG_FILE', Path('/nonexistent/config')):
            response = client.get('/api/config')
            assert response.status_code == 200
            data = response.get_json()
            assert data['node1'] == 'rhcsa1'
            assert data['node2'] == 'rhcsa2'
            assert data['node1_ip'] == ''
            assert data['node2_ip'] == ''
            assert data['has_password'] is False

    def test_save_config_validates_hostname(self, client):
        """POST /api/config should validate hostnames."""
        response = client.post('/api/config', 
            data=json.dumps({'node1': ''}),
            content_type='application/json')
        assert response.status_code == 400
        data = response.get_json()
        assert 'Invalid' in data.get('error', '') and 'hostname' in data.get('error', '')

    def test_save_config_validates_ip(self, client):
        """POST /api/config should validate IP addresses."""
        response = client.post('/api/config',
            data=json.dumps({'node1': 'valid', 'node1_ip': 'invalid.ip'}),
            content_type='application/json')
        assert response.status_code == 400
        data = response.get_json()
        assert 'Invalid' in data.get('error', '') and 'IP' in data.get('error', '')


class TestResultsRoutes:
    """Test results API routes."""

    @pytest.fixture(autouse=True)
    def setup_db(self, app, tmp_path):
        """Setup temporary database for each test."""
        db_path = tmp_path / 'results.db'
        with patch('api.app.DB_FILE', db_path):
            # Initialize database
            from api.app import init_db
            init_db()
            yield db_path

    def test_save_result(self, client):
        """POST /api/results should save a result."""
        result_data = {
            'mode': 'practice',
            'score': 80,
            'total': 100,
            'passed': True,
            'categories': {'test': 10},
            'checks': [{'task': 'task-01', 'passed': True}]
        }
        response = client.post('/api/results',
            data=json.dumps(result_data),
            content_type='application/json')
        assert response.status_code == 200
        data = response.get_json()
        assert data['status'] == 'saved'
        assert 'id' in data

    def test_get_results_empty(self, client):
        """GET /api/results should return empty list when no results."""
        response = client.get('/api/results')
        assert response.status_code == 200
        data = response.get_json()
        assert data['results'] == []
        assert data['total'] == 0

    def test_get_results_pagination(self, client):
        """GET /api/results should support pagination."""
        # Save multiple results first
        for i in range(5):
            client.post('/api/results',
                data=json.dumps({'mode': 'practice', 'score': i*10, 'total': 100, 
                                 'passed': i >= 3, 'categories': {}, 'checks': []}),
                content_type='application/json')
        
        # Get with pagination
        response = client.get('/api/results?limit=2&offset=0')
        assert response.status_code == 200
        data = response.get_json()
        assert len(data['results']) == 2
        assert data['total'] == 5

    def test_delete_result(self, client):
        """DELETE /api/results/<id> should delete a specific result."""
        # Save a result first
        save_resp = client.post('/api/results',
            data=json.dumps({'mode': 'practice', 'score': 100, 'total': 100, 
                             'passed': True, 'categories': {}, 'checks': []}),
            content_type='application/json')
        result_id = save_resp.get_json()['id']
        
        # Delete it
        response = client.delete(f'/api/results/{result_id}')
        assert response.status_code == 200
        assert response.get_json()['status'] == 'deleted'
        
        # Verify it's gone
        get_resp = client.get('/api/results')
        assert get_resp.get_json()['total'] == 0

    def test_delete_nonexistent_result(self, client):
        """DELETE /api/results/<id> should return 404 for nonexistent result."""
        response = client.delete('/api/results/99999')
        assert response.status_code == 404

    def test_clear_all_results(self, client):
        """DELETE /api/results should clear all results."""
        # Save some results
        for i in range(3):
            client.post('/api/results',
                data=json.dumps({'mode': 'practice', 'score': 50, 'total': 100, 
                                 'passed': False, 'categories': {}, 'checks': []}),
                content_type='application/json')
        
        # Clear all
        response = client.delete('/api/results')
        assert response.status_code == 200
        data = response.get_json()
        assert data['status'] == 'cleared'
        assert data['deleted'] == 3


class TestStatsRoute:
    """Test statistics API route."""

    @pytest.fixture(autouse=True)
    def setup_db(self, app, tmp_path):
        """Setup temporary database for each test."""
        db_path = tmp_path / 'results.db'
        with patch('api.app.DB_FILE', db_path):
            from api.app import init_db
            init_db()
            yield db_path

    def test_get_stats_empty(self, client):
        """GET /api/stats should return zeros when no results."""
        response = client.get('/api/stats')
        assert response.status_code == 200
        data = response.get_json()
        assert data['total_attempts'] == 0
        assert data['passed'] == 0

    def test_get_stats_with_data(self, client):
        """GET /api/stats should aggregate results correctly."""
        # Save some results with categories (using proper dict format)
        client.post('/api/results',
            data=json.dumps({
                'mode': 'exam', 'score': 80, 'total': 100, 'passed': True,
                'categories': {
                    'networking': {'earned': 30, 'possible': 40},
                    'storage': {'earned': 20, 'possible': 30}
                },
                'checks': [
                    {'task': 't1', 'passed': True, 'points': 50},
                    {'task': 't2', 'passed': True, 'points': 30},
                ]
            }),
            content_type='application/json')
        
        client.post('/api/results',
            data=json.dumps({
                'mode': 'exam', 'score': 50, 'total': 100, 'passed': False,
                'categories': {'networking': {'earned': 10, 'possible': 40}},
                'checks': [
                    {'task': 't1', 'passed': False, 'points': 0},
                ]
            }),
            content_type='application/json')
        
        response = client.get('/api/stats')
        assert response.status_code == 200
        data = response.get_json()
        assert data['total_attempts'] == 2
        assert data['passed'] == 1


class TestValidationHelpers:
    """Test input validation helper functions."""

    def test_sanitize_removes_dangerous_chars(self):
        """sanitize_config_value should remove shell metacharacters."""
        from api.app import sanitize_config_value
        
        assert sanitize_config_value('test') == 'test'
        assert sanitize_config_value('test;echo bad') == 'testecho bad'
        assert sanitize_config_value('test`id`') == 'testid'
        assert sanitize_config_value("test'quote") == 'testquote'
        assert sanitize_config_value('test$VAR') == 'testVAR'

    def test_validate_ip_accepts_valid(self):
        """validate_ip should accept valid IP addresses."""
        from api.app import validate_ip
        
        assert validate_ip('192.168.1.1') is True
        assert validate_ip('10.0.0.1') is True
        assert validate_ip('255.255.255.255') is True
        assert validate_ip('') is True  # Empty is allowed
        assert validate_ip(None) is True

    def test_validate_ip_rejects_invalid(self):
        """validate_ip should reject invalid IP addresses."""
        from api.app import validate_ip
        
        assert validate_ip('256.1.1.1') is False
        assert validate_ip('192.168.1') is False
        assert validate_ip('192.168.1.1.1') is False
        assert validate_ip('abc.def.ghi.jkl') is False
        assert validate_ip('192.168.1.1/24') is False

    def test_validate_hostname_accepts_valid(self):
        """validate_hostname should accept valid hostnames."""
        from api.app import validate_hostname
        
        assert validate_hostname('rhcsa1') is True
        assert validate_hostname('server-01') is True
        assert validate_hostname('web123') is True
        assert validate_hostname('a') is True

    def test_validate_hostname_rejects_invalid(self):
        """validate_hostname should reject invalid hostnames."""
        from api.app import validate_hostname
        
        assert validate_hostname('') is False
        assert validate_hostname(None) is False
        assert validate_hostname('-invalid') is False
        assert validate_hostname('invalid-') is False
        assert validate_hostname('has space') is False
        assert validate_hostname('has.dot') is False
