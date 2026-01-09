"""Flask API integration for the new grader.

This module provides functions to integrate the grader with Flask endpoints.
It handles session management, executor configuration, and result formatting.
"""

import logging
import sqlite3
from pathlib import Path
from typing import Dict, Any, List, Optional

from .grader import Grader, GraderResult, create_grader_from_session, create_local_grader
from .executor import LocalExecutor, RemoteExecutor

logger = logging.getLogger(__name__)


class GraderService:
    """Service layer for grading operations.
    
    Manages grader lifecycle and provides a clean API for Flask endpoints.
    """
    
    def __init__(self, base_dir: Path):
        self.base_dir = Path(base_dir)
        self.checks_dir = self.base_dir / 'checks'
        self.sessions_db = self.base_dir / 'sessions.db'
        self.config_file = self.base_dir / 'config'
    
    def _create_grader(self, session_id: Optional[str] = None) -> Grader:
        """Create a grader, preferring cloud session if available."""
        # Try cloud session first
        grader = create_grader_from_session(
            self.checks_dir,
            self.sessions_db,
            session_id
        )
        
        if grader:
            logger.info("Using cloud session grader")
            return grader
        
        # Fall back to config file for local VMs
        grader = Grader(self.checks_dir)
        
        if self.config_file.exists():
            config = self._load_config()
            if config.get('node1_ip') and config.get('root_password'):
                # Create remote executors using password auth
                node1_exec = RemoteExecutor(
                    host=config['node1_ip'],
                    user='root',
                    password=config['root_password']
                )
                grader.add_executor('node1', node1_exec)
                grader.add_executor('default', node1_exec)
                
                if config.get('node2_ip'):
                    node2_exec = RemoteExecutor(
                        host=config['node2_ip'],
                        user='root',
                        password=config['root_password']
                    )
                    grader.add_executor('node2', node2_exec)
                
                # Set environment variables
                grader.set_env('NODE1', config.get('node1', 'rhcsa1'))
                grader.set_env('NODE2', config.get('node2', 'rhcsa2'))
                grader.set_env('NODE1_IP', config['node1_ip'])
                grader.set_env('NODE2_IP', config.get('node2_ip', ''))
                grader.set_env('ROOT_PASSWORD', config['root_password'])
                
                logger.info("Using config file grader")
                return grader
        
        # Last resort: local execution
        logger.warning("No remote configuration found, using local executor")
        grader.add_executor('default', LocalExecutor())
        return grader
    
    def _load_config(self) -> Dict[str, str]:
        """Load configuration from config file."""
        config = {}
        if not self.config_file.exists():
            return config
        
        with open(self.config_file) as f:
            for line in f:
                line = line.strip()
                if line.startswith('#') or '=' not in line:
                    continue
                key, value = line.split('=', 1)
                key = key.strip().lower()
                value = value.strip().strip('"\'')
                config[key] = value
        
        return config
    
    def list_tasks(self) -> List[Dict[str, Any]]:
        """List all available tasks."""
        grader = Grader(self.checks_dir)
        return grader.list_tasks()
    
    def grade_task(
        self,
        task_id: str,
        session_id: Optional[str] = None,
        target: Optional[str] = None,
        timeout: int = 60
    ) -> Dict[str, Any]:
        """Grade a single task and return the result."""
        grader = self._create_grader(session_id)
        result = grader.evaluate_task(task_id, target_override=target, timeout=timeout)
        
        # Format for API response
        return {
            'task_id': result.task_id,
            'passed': result.passed,
            'points': result.points_earned,
            'max_points': result.points_possible,
            'checks_passed': sum(1 for c in result.checks if c.passed),
            'checks_total': len(result.checks),
            'details': [
                f"{'✓' if c.passed else '✗'} {c.check}"
                for c in result.checks
            ],
            'message': f"{sum(1 for c in result.checks if c.passed)}/{len(result.checks)} checks passed",
            'error': result.error,
        }
    
    def grade_tasks(
        self,
        task_ids: List[str],
        session_id: Optional[str] = None,
        timeout_per_task: int = 60
    ) -> Dict[str, Any]:
        """Grade multiple tasks and return aggregated results."""
        grader = self._create_grader(session_id)
        result = grader.grade(task_ids, timeout_per_task=timeout_per_task)
        return result.to_dict()
    
    def get_session_status(self) -> Dict[str, Any]:
        """Get status of cloud session, if any."""
        if not self.sessions_db.exists():
            return {'has_session': False, 'mode': 'local'}
        
        try:
            conn = sqlite3.connect(str(self.sessions_db))
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute("""
                SELECT session_id, state, node1_ip, node2_ip, created_at
                FROM sessions
                WHERE state IN ('ready', 'active', 'provisioning')
                ORDER BY created_at DESC
                LIMIT 1
            """)
            row = cursor.fetchone()
            conn.close()
            
            if row:
                return {
                    'has_session': True,
                    'mode': 'cloud',
                    'session_id': row['session_id'],
                    'state': row['state'],
                    'node1_ip': row['node1_ip'],
                    'node2_ip': row['node2_ip'],
                    'created_at': row['created_at'],
                }
            
            return {'has_session': False, 'mode': 'local'}
            
        except Exception as e:
            logger.error(f"Failed to get session status: {e}")
            return {'has_session': False, 'mode': 'local', 'error': str(e)}


# Global service instance (created lazily)
_service: Optional[GraderService] = None


def get_grader_service(base_dir: Optional[Path] = None) -> GraderService:
    """Get or create the global grader service."""
    global _service
    if _service is None:
        if base_dir is None:
            base_dir = Path(__file__).parent.parent.parent
        _service = GraderService(base_dir)
    return _service
