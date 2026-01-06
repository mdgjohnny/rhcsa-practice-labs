#!/usr/bin/env python3
"""Fix task check scripts to use run_ssh for remote execution."""

import re
import os
from pathlib import Path

CHECKS_DIR = Path('./checks')

# Patterns that indicate local execution (need to be wrapped in run_ssh)
LOCAL_PATTERNS = [
    (r"check '(id \w+)", r'check \'run_ssh "$NODE1_IP" "\1"'),
    (r"check '\[?\[? -d (/[^\]]+)\]?\]?'", r'check \'run_ssh "$NODE1_IP" "test -d \1"\''),
    (r"check '\[?\[? -f (/[^\]]+)\]?\]?'", r'check \'run_ssh "$NODE1_IP" "test -f \1"\''),
    (r"check '(getent \w+ \w+)", r'check \'run_ssh "$NODE1_IP" "\1"'),
    (r"check '(systemctl \w+ \w+)", r'check \'run_ssh "$NODE1_IP" "\1"'),
    (r"check '(rpm -q \w+)", r'check \'run_ssh "$NODE1_IP" "\1"'),
    (r"check '(lvs \w+)", r'check \'run_ssh "$NODE1_IP" "\1"'),
    (r"check '(vgs \w+)", r'check \'run_ssh "$NODE1_IP" "\1"'),
    (r"check '(swapon --show)", r'check \'run_ssh "$NODE1_IP" "\1"'),
    (r"check '(podman ps)", r'check \'run_ssh "$NODE1_IP" "\1"'),
    (r"check '(getenforce)", r'check \'run_ssh "$NODE1_IP" "\1"'),
    (r"check '(semanage \w+)", r'check \'run_ssh "$NODE1_IP" "\1"'),
    (r"check '(timedatectl \w+)", r'check \'run_ssh "$NODE1_IP" "\1"'),
    (r"check '(stat -c %\w+ /[^\s]+)", r'check \'run_ssh "$NODE1_IP" "\1"'),
    (r"check '(grep \w+ /[^\s]+)", r'check \'run_ssh "$NODE1_IP" "\1"'),
    (r"check '(crontab -\w+ \w+)", r'check \'run_ssh "$NODE1_IP" "\1"'),
]

def analyze_task(filepath):
    """Analyze a task file and identify issues."""
    content = filepath.read_text()
    issues = []

    # Check if it already uses run_ssh
    uses_ssh = 'run_ssh' in content

    # Check for target comment
    target_match = re.search(r'# Target:\s*(\w+)', content)
    target = target_match.group(1) if target_match else None

    # Check for local command patterns
    if not uses_ssh:
        for pattern, _ in LOCAL_PATTERNS:
            if re.search(pattern, content):
                issues.append(f"Uses local pattern: {pattern}")
                break

    # Check for obvious parsing errors
    broken_checks = [
        ('id should', 'Parsed word "should" as username'),
        ('id password', 'Parsed word "password" as username'),
        ('id use', 'Parsed word "use" as username'),
        ('id account', 'Parsed word "account" as username'),
        ('id initialization', 'Parsed word "initialization" as username'),
        ('id container', 'Parsed word "container" as username'),
        ('vgs mount', 'Parsed word "mount" as VG name'),
        ('vgs in', 'Parsed word "in" as VG name'),
        ('lvs that', 'Parsed word "that" as LV name'),
    ]

    for check, msg in broken_checks:
        if check in content:
            issues.append(msg)

    return {
        'file': filepath.name,
        'uses_ssh': uses_ssh,
        'target': target,
        'issues': issues
    }


def main():
    tasks = sorted(CHECKS_DIR.glob('task-*.sh'))

    broken = []
    for task in tasks:
        result = analyze_task(task)
        if result['issues'] or not result['uses_ssh']:
            broken.append(result)

    print(f"Found {len(broken)} tasks that may need fixing:\n")
    for b in broken:
        print(f"{b['file']}: target={b['target']}, uses_ssh={b['uses_ssh']}")
        for issue in b['issues']:
            print(f"  - {issue}")
        print()


if __name__ == '__main__':
    main()
