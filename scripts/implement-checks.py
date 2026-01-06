#!/usr/bin/env python3
"""
Generate check implementations for placeholder task scripts.
"""

import os
import re
from pathlib import Path

# Check templates based on common patterns
TEMPLATES = {
    'user_exists': lambda user: f"check 'id {user} &>/dev/null' \\\n    \"User {user} exists\" \\\n    \"User {user} does not exist\"",
    'group_exists': lambda group: f"check 'getent group {group} &>/dev/null' \\\n    \"Group {group} exists\" \\\n    \"Group {group} does not exist\"",
    'user_in_group': lambda user, group: f"check 'id {user} 2>/dev/null | grep -q \"{group}\"' \\\n    \"User {user} is member of {group}\" \\\n    \"User {user} is not member of {group}\"",
    'file_exists': lambda path: f"check '[[ -f {path} ]]' \\\n    \"File {path} exists\" \\\n    \"File {path} does not exist\"",
    'dir_exists': lambda path: f"check '[[ -d {path} ]]' \\\n    \"Directory {path} exists\" \\\n    \"Directory {path} does not exist\"",
    'service_active': lambda svc: f"check 'systemctl is-active {svc} &>/dev/null' \\\n    \"Service {svc} is running\" \\\n    \"Service {svc} is not running\"",
    'service_enabled': lambda svc: f"check 'systemctl is-enabled {svc} &>/dev/null' \\\n    \"Service {svc} is enabled\" \\\n    \"Service {svc} is not enabled\"",
}

def parse_task_description(filepath):
    """Extract task description from script."""
    with open(filepath) as f:
        for line in f:
            if line.startswith('# Task:'):
                return line.replace('# Task:', '').strip()
    return ""

def generate_checks(desc):
    """Generate check code based on task description."""
    checks = []
    desc_lower = desc.lower()

    # User creation patterns
    users = re.findall(r'user[s]?\s+(\w+(?:,\s*\w+)*)', desc_lower)
    for match in users:
        for user in re.split(r'[,\s]+', match):
            user = user.strip()
            if user and len(user) > 1 and user not in ('with', 'and', 'the', 'to', 'as', 'that', 'accounts'):
                checks.append(TEMPLATES['user_exists'](user))

    # Specific user patterns
    for user in re.findall(r'(?:user|create)\s+(\w+)\s+with', desc_lower):
        if user not in ('student', 'the'):
            checks.append(TEMPLATES['user_exists'](user))

    # UID pattern
    uid_match = re.search(r'uid\s+(\d+)', desc_lower)
    if uid_match:
        uid = uid_match.group(1)
        user_match = re.search(r'user\s+(\w+).*uid', desc_lower)
        if user_match:
            user = user_match.group(1)
            checks.append(f"check '[[ $(id -u {user} 2>/dev/null) == \"{uid}\" ]]' \\\n    \"User {user} has UID {uid}\" \\\n    \"User {user} does not have UID {uid}\"")

    # Group patterns
    groups = re.findall(r'group[s]?\s+(?:called\s+)?(\w+)', desc_lower)
    for group in groups:
        if group not in ('membership', 'members', 'directories', 'owner', 'owned', 'the', 'to'):
            checks.append(TEMPLATES['group_exists'](group))

    # Directory patterns
    dirs = re.findall(r'directory\s+([/\w]+)', desc)
    for d in dirs:
        if d.startswith('/'):
            checks.append(TEMPLATES['dir_exists'](d))

    # Service patterns
    services = re.findall(r'(httpd|nginx|nfs-server|autofs|vsftpd|sshd|mariadb|mysql|atd|crond)\s', desc_lower)
    for svc in set(services):
        checks.append(TEMPLATES['service_active'](svc))
        if 'automatically' in desc_lower or 'boot' in desc_lower or 'enabled' in desc_lower:
            checks.append(TEMPLATES['service_enabled'](svc))

    # LVM patterns
    if 'volume group' in desc_lower or 'logical volume' in desc_lower:
        vg_match = re.search(r'volume group.*?(\w+)', desc_lower)
        if vg_match:
            vg = vg_match.group(1)
            if vg not in ('with', 'the', 'using', 'name'):
                checks.append(f"check 'vgs {vg} &>/dev/null' \\\n    \"Volume group {vg} exists\" \\\n    \"Volume group {vg} does not exist\"")

        lv_match = re.search(r'logical volume.*?(?:name\s+)?(\w+)', desc_lower)
        if lv_match:
            lv = lv_match.group(1)
            if lv not in ('with', 'the', 'called', 'name'):
                checks.append(f"check 'lvs | grep -q {lv}' \\\n    \"Logical volume {lv} exists\" \\\n    \"Logical volume {lv} does not exist\"")

    # Mount patterns
    mount_match = re.search(r'mount.*?persistently.*?([/\w]+)', desc_lower)
    if mount_match:
        mnt = mount_match.group(1)
        if mnt.startswith('/'):
            checks.append(f"check 'grep -q \"{mnt}\" /etc/fstab' \\\n    \"{mnt} is in /etc/fstab for persistent mount\" \\\n    \"{mnt} is not in /etc/fstab\"")
            checks.append(f"check 'mountpoint -q {mnt} 2>/dev/null' \\\n    \"{mnt} is mounted\" \\\n    \"{mnt} is not mounted\"")

    # Swap patterns
    if 'swap' in desc_lower:
        checks.append("check 'swapon --show | grep -q .' \\\n    \"Swap is active\" \\\n    \"No swap is active\"")
        if 'persistent' in desc_lower:
            checks.append("check 'grep -q swap /etc/fstab' \\\n    \"Swap is configured in /etc/fstab\" \\\n    \"Swap is not in /etc/fstab\"")

    # SELinux patterns
    if 'selinux' in desc_lower:
        if 'permissive' in desc_lower:
            checks.append("check 'getenforce | grep -qi permissive' \\\n    \"SELinux is in permissive mode\" \\\n    \"SELinux is not in permissive mode\"")
        if 'context' in desc_lower:
            ctx_match = re.search(r'context.*?(\w+_t)', desc_lower)
            if ctx_match:
                ctx = ctx_match.group(1)
                checks.append(f"# Check SELinux context contains {ctx}")

    # Container patterns
    if 'container' in desc_lower:
        checks.append("check 'podman ps 2>/dev/null | grep -q . || docker ps 2>/dev/null | grep -q .' \\\n    \"Container is running\" \\\n    \"No container is running\"")

        port_match = re.search(r'port\s+(\d+)', desc_lower)
        if port_match:
            port = port_match.group(1)
            checks.append(f"check 'ss -tlnp | grep -q \":{port}\"' \\\n    \"Port {port} is listening\" \\\n    \"Port {port} is not listening\"")

    # Cron/schedule patterns
    if 'schedule' in desc_lower or 'cron' in desc_lower:
        checks.append("check 'crontab -l 2>/dev/null | grep -q . || ls /etc/cron.d/* 2>/dev/null | grep -q .' \\\n    \"Cron job is configured\" \\\n    \"No cron job found\"")

    # sudo patterns
    if 'sudo' in desc_lower:
        user_match = re.search(r'(?:user|allow)\s+(\w+).*sudo', desc_lower)
        if user_match:
            user = user_match.group(1)
            checks.append(f"check 'grep -rq \"{user}\" /etc/sudoers /etc/sudoers.d/ 2>/dev/null' \\\n    \"Sudo config for {user} exists\" \\\n    \"No sudo config for {user}\"")

    # Password defaults
    if 'default' in desc_lower and 'password' in desc_lower:
        checks.append("# Check /etc/login.defs for password policies")
        if 'validity' in desc_lower or 'lifetime' in desc_lower or 'days' in desc_lower:
            days_match = re.search(r'(\d+)\s*days', desc_lower)
            if days_match:
                days = days_match.group(1)
                checks.append(f"check 'grep -q \"PASS_MAX_DAYS.*{days}\" /etc/login.defs' \\\n    \"PASS_MAX_DAYS is set to {days}\" \\\n    \"PASS_MAX_DAYS is not {days}\"")

    # Default: generic placeholder
    if not checks:
        checks.append("# TODO: Add specific checks for this task")
        checks.append("check 'true' \\\n    \"Task verification placeholder\" \\\n    \"Task not completed\"")

    return checks

def update_task_script(filepath):
    """Update a task script with generated checks."""
    with open(filepath) as f:
        content = f.read()

    # Skip if already implemented
    if 'TODO: Implement' not in content:
        return False

    desc = parse_task_description(filepath)
    if not desc:
        return False

    checks = generate_checks(desc)

    # Build new content
    lines = content.split('\n')
    new_lines = []
    for line in lines:
        if line.startswith('# TODO:') or line.startswith('echo "Task') or line.startswith('exit 1'):
            continue
        new_lines.append(line)

    # Remove trailing empty lines
    while new_lines and not new_lines[-1].strip():
        new_lines.pop()

    # Add checks
    new_lines.append('')
    new_lines.extend(checks)
    new_lines.append('')

    with open(filepath, 'w') as f:
        f.write('\n'.join(new_lines))

    return True

def main():
    checks_dir = Path(__file__).parent.parent / 'checks'

    updated = 0
    for task_file in sorted(checks_dir.glob('task-*.sh')):
        # Only process task-89 onwards (new tasks)
        match = re.search(r'task-(\d+)\.sh', task_file.name)
        if match and int(match.group(1)) >= 89:
            if update_task_script(task_file):
                print(f"Updated {task_file.name}")
                updated += 1

    print(f"\nUpdated {updated} task files")

if __name__ == '__main__':
    main()
