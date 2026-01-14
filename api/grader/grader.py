"""Main grader module - orchestrates task evaluation.

This is the primary interface for grading tasks. It coordinates between
the bundler (creates scripts) and executor (runs them) to evaluate tasks.
"""

import json
import logging
import sqlite3
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any

# Add parent directory for oci_manager import
sys.path.insert(0, str(Path(__file__).parent.parent))

from .bundler import TaskBundler, TaskMetadata
from .executor import Executor, LocalExecutor, RemoteExecutor, ExecutionResult

logger = logging.getLogger(__name__)


@dataclass
class CheckResult:
    """Result of a single check within a task."""
    check: str  # Description of what was checked
    passed: bool
    points: int = 10
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            'check': self.check,
            'passed': self.passed,
            'points': self.points,
        }


@dataclass
class TaskResult:
    """Result of evaluating a task."""
    task_id: str
    category: str
    passed: bool  # All checks passed
    checks: List[CheckResult] = field(default_factory=list)
    points_earned: int = 0
    points_possible: int = 0
    error: Optional[str] = None
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            'task': self.task_id,
            'category': self.category,
            'passed': self.passed,
            'points_earned': self.points_earned,
            'points_possible': self.points_possible,
            'checks': [c.to_dict() for c in self.checks],
            'error': self.error,
        }


@dataclass
class GraderResult:
    """Aggregate result of grading multiple tasks."""
    timestamp: str
    score: int
    total: int
    passed: bool  # Overall pass (>= 70%)
    task_results: List[TaskResult] = field(default_factory=list)
    categories: Dict[str, Dict[str, int]] = field(default_factory=dict)
    
    @property
    def pass_percentage(self) -> float:
        if self.total == 0:
            return 0.0
        return (self.score / self.total) * 100
    
    def to_dict(self) -> Dict[str, Any]:
        # Flatten checks for compatibility with existing UI
        all_checks = []
        for tr in self.task_results:
            for c in tr.checks:
                all_checks.append({
                    'task': tr.task_id,
                    'category': tr.category,
                    'check': c.check,
                    'passed': c.passed,
                    'points': c.points,
                })
        
        return {
            'timestamp': self.timestamp,
            'score': self.score,
            'total': self.total,
            'passed': self.passed,
            'passing_threshold': 70,
            'categories': self.categories,
            'checks': all_checks,
        }


class Grader:
    """Main grader class - evaluates tasks on local or remote targets."""
    
    def __init__(self, checks_dir: Path):
        self.checks_dir = Path(checks_dir)
        self.bundler = TaskBundler(checks_dir)
        
        # Executors for different targets
        self._executors: Dict[str, Executor] = {}
        
        # Environment variables for script execution
        self._env_vars: Dict[str, str] = {}
    
    def set_env(self, key: str, value: str) -> None:
        """Set an environment variable for script execution."""
        self._env_vars[key] = value
    
    def set_env_from_dict(self, env: Dict[str, str]) -> None:
        """Set multiple environment variables."""
        self._env_vars.update(env)
    
    def add_executor(self, name: str, executor: Executor) -> None:
        """Add an executor for a named target."""
        self._executors[name] = executor
    
    def get_executor(self, target: str) -> Optional[Executor]:
        """Get executor for a target, with fallback to 'default'."""
        return self._executors.get(target) or self._executors.get('default')
    
    def _parse_check_output(self, output: str) -> List[CheckResult]:
        """Parse JSON lines from script output into CheckResults."""
        results = []
        for line in output.split('\n'):
            line = line.strip()
            if not line or not line.startswith('{'):
                continue
            try:
                data = json.loads(line)
                results.append(CheckResult(
                    check=data.get('check', 'Unknown check'),
                    passed=data.get('passed', False),
                    points=data.get('points', 10),
                ))
            except json.JSONDecodeError as e:
                logger.warning(f"Failed to parse check output: {line[:100]} - {e}")
        return results
    
    def evaluate_task(
        self,
        task_id: str,
        target_override: Optional[str] = None,
        timeout: int = 60
    ) -> TaskResult:
        """Evaluate a single task.
        
        Args:
            task_id: Task identifier
            target_override: Override the task's target (node1, node2)
            timeout: Execution timeout in seconds
        
        Returns:
            TaskResult with check results
        """
        # Get task metadata
        metadata = self.bundler.get_metadata(task_id)
        if not metadata:
            return TaskResult(
                task_id=task_id,
                category='unknown',
                passed=False,
                error=f'Task not found: {task_id}'
            )
        
        # Determine target
        target = target_override or metadata.target
        if target == 'both':
            # For 'both' targets, run on node1 (task uses run_ssh for node2)
            target = 'node1'
        
        # Get executor
        executor = self.get_executor(target)
        if not executor:
            return TaskResult(
                task_id=metadata.id,
                category=metadata.category,
                passed=False,
                error=f'No executor configured for target: {target}'
            )
        
        # Bundle the task
        script = self.bundler.bundle(task_id, env_vars=self._env_vars)
        if not script:
            return TaskResult(
                task_id=metadata.id,
                category=metadata.category,
                passed=False,
                error='Failed to bundle task'
            )
        
        # Execute
        logger.info(f"Evaluating {metadata.id} on {target}")
        result = executor.execute(script, timeout=timeout)
        
        if not result.success and not result.stdout:
            return TaskResult(
                task_id=metadata.id,
                category=metadata.category,
                passed=False,
                error=result.stderr or 'Execution failed'
            )
        
        # Parse results
        checks = self._parse_check_output(result.stdout)
        
        if not checks:
            return TaskResult(
                task_id=metadata.id,
                category=metadata.category,
                passed=False,
                error=f'No check output parsed. stderr: {result.stderr[:200]}'
            )
        
        # Calculate points
        points_earned = sum(c.points for c in checks if c.passed)
        points_possible = sum(c.points for c in checks)
        all_passed = all(c.passed for c in checks)
        
        return TaskResult(
            task_id=metadata.id,
            category=metadata.category,
            passed=all_passed,
            checks=checks,
            points_earned=points_earned,
            points_possible=points_possible,
        )
    
    def grade(
        self,
        task_ids: Optional[List[str]] = None,
        timeout_per_task: int = 60
    ) -> GraderResult:
        """Grade multiple tasks.
        
        Args:
            task_ids: List of task IDs to grade (None = all tasks)
            timeout_per_task: Timeout for each task
        
        Returns:
            GraderResult with aggregated results
        """
        # Get tasks to grade
        if task_ids is None:
            all_tasks = self.bundler.list_tasks()
            task_ids = [t['id'] for t in all_tasks]
        
        # Evaluate each task
        task_results = []
        for task_id in task_ids:
            result = self.evaluate_task(task_id, timeout=timeout_per_task)
            task_results.append(result)
        
        # Calculate totals
        score = sum(tr.points_earned for tr in task_results)
        total = sum(tr.points_possible for tr in task_results)
        
        # Calculate category stats
        categories: Dict[str, Dict[str, int]] = {}
        for tr in task_results:
            if tr.category not in categories:
                categories[tr.category] = {'earned': 0, 'possible': 0}
            categories[tr.category]['earned'] += tr.points_earned
            categories[tr.category]['possible'] += tr.points_possible
        
        # Overall pass/fail
        passed = total > 0 and (score / total) >= 0.7
        
        return GraderResult(
            timestamp=datetime.now().isoformat(),
            score=score,
            total=total,
            passed=passed,
            task_results=task_results,
            categories=categories,
        )
    
    def list_tasks(self) -> List[Dict[str, Any]]:
        """List all available tasks."""
        return self.bundler.list_tasks()


def create_grader_from_session(
    checks_dir: Path,
    sessions_db: Path,
    session_id: Optional[str] = None
) -> Optional[Grader]:
    """Create a grader configured with executors from a cloud session.
    
    Args:
        checks_dir: Path to checks/ directory
        sessions_db: Path to sessions.db
        session_id: Specific session ID, or None for most recent active session
    
    Returns:
        Configured Grader, or None if no session found
    """
    if not sessions_db.exists():
        logger.debug("No sessions.db found")
        return None
    
    try:
        conn = sqlite3.connect(str(sessions_db))
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        # Get session
        if session_id:
            cursor.execute("""
                SELECT session_id, node1_ip, node2_ip, node1_private_ip, node2_private_ip, 
                       ssh_private_key, ssh_password, ssh_user
                FROM sessions WHERE session_id = ?
            """, (session_id,))
        else:
            cursor.execute("""
                SELECT session_id, node1_ip, node2_ip, node1_private_ip, node2_private_ip,
                       ssh_private_key, ssh_password, ssh_user
                FROM sessions 
                WHERE state IN ('ready', 'active')
                ORDER BY created_at DESC
                LIMIT 1
            """)
        
        row = cursor.fetchone()
        conn.close()
        
        if not row:
            logger.debug("No active session found")
            return None
        
        # Create grader
        grader = Grader(checks_dir)
        
        # Set environment variables
        grader.set_env('NODE1', 'rhcsa1')
        grader.set_env('NODE2', 'rhcsa2')
        if row['node1_ip']:
            grader.set_env('NODE1_IP', row['node1_ip'])
        if row['node2_ip']:
            grader.set_env('NODE2_IP', row['node2_ip'])
        
        # Set private IPs (useful for tasks that need to reference other nodes)
        if row['node1_private_ip']:
            grader.set_env('NODE1_PRIVATE_IP', row['node1_private_ip'])
        if row['node2_private_ip']:
            grader.set_env('NODE2_PRIVATE_IP', row['node2_private_ip'])
        
        # Create remote executors
        ssh_key = None
        ssh_password = row['ssh_password'] if 'ssh_password' in row.keys() else None
        ssh_user = row['ssh_user'] if 'ssh_user' in row.keys() else None
        
        # Default user based on auth method
        if not ssh_user:
            ssh_user = 'root' if ssh_password else 'opc'
        
        if row['ssh_private_key']:
            # Decrypt SSH key (all keys must be encrypted)
            ssh_key = row['ssh_private_key']
            if not ssh_key.startswith('gAAAAA'):
                logger.error("SSH key is not encrypted - all keys must be Fernet encrypted")
                return None
            try:
                from oci_manager.session_manager import KeyEncryption
                key_encryption = KeyEncryption()
                ssh_key = key_encryption.decrypt(ssh_key)
                logger.debug("Decrypted SSH key")
            except Exception as e:
                logger.error(f"Failed to decrypt SSH key: {e}")
                return None
        
        if ssh_key or ssh_password:
            use_sudo = ssh_user != 'root'
            
            node1_executor = RemoteExecutor(
                host=row['node1_ip'],
                user=ssh_user,
                password=ssh_password,
                use_sudo=use_sudo
            )
            if ssh_key:
                node1_executor.set_key_content(ssh_key)
            grader.add_executor('node1', node1_executor)
            grader.add_executor('default', node1_executor)
            
            if row['node2_ip']:
                node2_executor = RemoteExecutor(
                    host=row['node2_ip'],
                    user=ssh_user,
                    password=ssh_password,
                    use_sudo=use_sudo
                )
                if ssh_key:
                    node2_executor.set_key_content(ssh_key)
                grader.add_executor('node2', node2_executor)
        
        logger.info(f"Created grader from session {row['session_id']}")
        return grader
        
    except Exception as e:
        logger.error(f"Failed to create grader from session: {e}")
        return None


def create_local_grader(checks_dir: Path, as_root: bool = True) -> Grader:
    """Create a grader for local execution (when running on the VM itself)."""
    grader = Grader(checks_dir)
    executor = LocalExecutor(as_root=as_root)
    grader.add_executor('default', executor)
    grader.add_executor('node1', executor)
    grader.add_executor('node2', executor)
    return grader
