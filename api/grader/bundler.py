"""Task bundler - creates self-contained grading scripts.

This module takes a task file and bundles it with the check() function and
any required helpers into a single script that can run anywhere.
"""

import logging
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Optional, Dict, Any

logger = logging.getLogger(__name__)

# The check function that outputs JSON
# This replaces the bash check() with one that produces structured output
CHECK_FUNCTION = r'''
# JSON-output check function
# Usage: check 'condition' 'ok_msg' 'fail_msg' [points]
check() {
    local condition="$1"
    local ok_msg="$2"
    local fail_msg="$3"
    local points="${4:-10}"
    local passed=false
    
    if eval "$condition" &>/dev/null; then
        passed=true
    fi
    
    # Output JSON line (one per check)
    local msg
    if [[ "$passed" == true ]]; then
        msg="$ok_msg"
    else
        msg="$fail_msg"
    fi
    
    # Escape quotes in message for JSON
    msg="${msg//\\/\\\\}"
    msg="${msg//\"/\\\"}"
    
    echo "{\"check\":\"$msg\",\"passed\":$passed,\"points\":$points}"
}
'''




@dataclass
class TaskMetadata:
    """Metadata extracted from task file comments."""
    id: str
    title: str = ''
    category: str = 'uncategorized'
    description: str = ''
    target: str = 'node1'  # node1, node2, or both
    cloud_compatible: bool = True  # False if task can't run in cloud (e.g., changes primary IP)
    
    @classmethod
    def from_content(cls, task_id: str, content: str) -> 'TaskMetadata':
        """Extract metadata from task file content."""
        metadata = cls(id=task_id)
        
        for line in content.split('\n'):
            line = line.strip()
            if line.startswith('# Title:'):
                metadata.title = line.replace('# Title:', '').strip()
            elif line.startswith('# Category:'):
                metadata.category = line.replace('# Category:', '').strip()
            elif line.startswith('# Task:'):
                metadata.description = line.replace('# Task:', '').strip()
            elif line.startswith('# Target:'):
                metadata.target = line.replace('# Target:', '').strip()
            elif line.startswith('# CloudCompatible:'):
                val = line.replace('# CloudCompatible:', '').strip().lower()
                metadata.cloud_compatible = val not in ('false', 'no', '0')
        
        # Infer target from description if not specified
        if not metadata.target or metadata.target == 'node1':
            desc = metadata.description.lower()
            if 'node2' in desc and 'node1' not in desc:
                metadata.target = 'node2'
            elif 'both' in desc or ('node1' in desc and 'node2' in desc):
                metadata.target = 'both'
        
        return metadata


class TaskBundler:
    """Creates self-contained grading scripts from task files."""
    
    def __init__(self, checks_dir: Path):
        self.checks_dir = Path(checks_dir)
    
    def load_task(self, task_id: str) -> Optional[str]:
        """Load task file content by ID."""
        # Handle both "task-01" and "01" formats
        if not task_id.startswith('task-'):
            task_id = f'task-{task_id}'
        
        task_file = self.checks_dir / f'{task_id}.sh'
        if not task_file.exists():
            logger.error(f"Task file not found: {task_file}")
            return None
        
        return task_file.read_text()
    
    def get_metadata(self, task_id: str) -> Optional[TaskMetadata]:
        """Get metadata for a task."""
        content = self.load_task(task_id)
        if not content:
            return None
        
        # Normalize task_id
        if not task_id.startswith('task-'):
            task_id = f'task-{task_id}'
        
        return TaskMetadata.from_content(task_id, content)
    
    def bundle(
        self,
        task_id: str,
        env_vars: Optional[Dict[str, str]] = None
    ) -> Optional[str]:
        """Bundle a task into a self-contained script.
        
        Args:
            task_id: Task identifier (e.g., "task-01" or "01")
            env_vars: Environment variables to inject (e.g., NODE1_IP, NODE2_IP)
        
        Returns:
            Complete bash script string, or None if task not found
        """
        content = self.load_task(task_id)
        if not content:
            return None
        
        # Normalize task_id for output
        if not task_id.startswith('task-'):
            task_id = f'task-{task_id}'
        
        metadata = TaskMetadata.from_content(task_id, content)
        
        # Build the script
        parts = [
            '#!/bin/bash',
            '# Bundled grading script for ' + task_id,
            # 'set -o pipefail',  # Disabled: breaks grep -q in pipes
            '',
        ]
        
        # Add environment variables
        if env_vars:
            parts.append('# Environment variables')
            for key, value in env_vars.items():
                # Escape value for bash
                escaped = value.replace("'", "'\"'\"'")
                parts.append(f"export {key}='{escaped}'")
            parts.append('')
        
        # Add check function
        parts.append('# Check function (outputs JSON)')
        parts.append(CHECK_FUNCTION)
        
        # Add metadata as variables
        parts.append('# Task metadata')
        parts.append(f'TASK_ID="{task_id}"')
        parts.append(f'TASK_CATEGORY="{metadata.category}"')
        parts.append('')
        
        # Add task content (strip shebang if present)
        parts.append('# Task checks')
        task_lines = content.split('\n')
        if task_lines and task_lines[0].startswith('#!'):
            task_lines = task_lines[1:]
        parts.extend(task_lines)
        
        return '\n'.join(parts)
    
    def list_tasks(self) -> list:
        """List all available tasks with metadata."""
        tasks = []
        for task_file in sorted(self.checks_dir.glob('task-*.sh')):
            task_id = task_file.stem
            content = task_file.read_text()
            metadata = TaskMetadata.from_content(task_id, content)
            tasks.append({
                'id': metadata.id,
                'title': metadata.title,
                'category': metadata.category,
                'description': metadata.description,
                'target': metadata.target,
                'cloud_compatible': metadata.cloud_compatible,
            })
        return tasks
