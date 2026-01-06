#!/usr/bin/env python3
"""
Automatically fix task check scripts to use run_ssh for remote execution.
Identifies the target VM from comments and wraps check commands appropriately.
"""

import re
import os
from pathlib import Path

CHECKS_DIR = Path('./checks')

def get_target(content):
    """Extract target VM from comment."""
    match = re.search(r'# Target:\s*(\w+)', content)
    if match:
        return match.group(1).lower()
    return 'node1'  # default

def fix_check_line(line, target):
    """Fix a single check line to use run_ssh."""
    # Skip if already uses run_ssh
    if 'run_ssh' in line:
        return line, False

    # Skip if it's not a check line
    if not line.strip().startswith('check '):
        return line, False

    # Get the node IP variable
    if target == 'node2':
        node_ip = '$NODE2_IP'
    else:
        node_ip = '$NODE1_IP'

    # Pattern: check 'command' \
    # We need to extract the command and wrap it

    # Handle [[ -d /path ]] patterns - convert to test -d
    line = re.sub(
        r"check '\[\[? -d ([^\]]+?) \]\]?'",
        rf'check \'run_ssh "{node_ip}" "test -d \1"\'',
        line
    )

    # Handle [[ -f /path ]] patterns - convert to test -f
    line = re.sub(
        r"check '\[\[? -f ([^\]]+?) \]\]?'",
        rf'check \'run_ssh "{node_ip}" "test -f \1"\'',
        line
    )

    # Handle [[ -e /path ]] patterns - convert to test -e
    line = re.sub(
        r"check '\[\[? -e ([^\]]+?) \]\]?'",
        rf'check \'run_ssh "{node_ip}" "test -e \1"\'',
        line
    )

    # Handle [[ -L /path ]] patterns - convert to test -L (symlink)
    line = re.sub(
        r"check '\[\[? -L ([^\]]+?) \]\]?'",
        rf'check \'run_ssh "{node_ip}" "test -L \1"\'',
        line
    )

    # Handle getent commands
    line = re.sub(
        r"check '(getent \w+ \w+)( [^']*)?'",
        rf'check \'run_ssh "{node_ip}" "\1"\2\'',
        line
    )

    # Handle id commands (but not "id should", "id password" etc.)
    line = re.sub(
        r"check '(id [a-z][a-z0-9_-]+)( [^']*)?'",
        rf'check \'run_ssh "{node_ip}" "\1"\2\'',
        line
    )

    # Handle systemctl commands
    line = re.sub(
        r"check '(systemctl [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )

    # Handle rpm commands
    line = re.sub(
        r"check '(rpm -[qV][a-z]* [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )

    # Handle vgs/lvs/pvs commands
    line = re.sub(
        r"check '(vgs [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )
    line = re.sub(
        r"check '(lvs [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )
    line = re.sub(
        r"check '(pvs [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )

    # Handle swapon commands
    line = re.sub(
        r"check '(swapon [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )

    # Handle mount/findmnt commands
    line = re.sub(
        r"check '(mount [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )
    line = re.sub(
        r"check '(findmnt [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )

    # Handle df commands
    line = re.sub(
        r"check '(df [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )

    # Handle stat commands
    line = re.sub(
        r"check '(stat [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )

    # Handle grep on remote files
    line = re.sub(
        r"check '(grep [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )

    # Handle cat commands
    line = re.sub(
        r"check '(cat [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )

    # Handle ls commands
    line = re.sub(
        r"check '(ls [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )

    # Handle crontab commands
    line = re.sub(
        r"check '(crontab [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )

    # Handle podman/docker commands
    line = re.sub(
        r"check '(podman [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )
    line = re.sub(
        r"check '(docker [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )

    # Handle firewall-cmd commands
    line = re.sub(
        r"check '(firewall-cmd [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )

    # Handle sestatus/getenforce/semanage commands
    line = re.sub(
        r"check '(getenforce[^']*)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )
    line = re.sub(
        r"check '(sestatus[^']*)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )
    line = re.sub(
        r"check '(semanage [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )

    # Handle timedatectl/chronyc commands
    line = re.sub(
        r"check '(timedatectl[^']*)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )
    line = re.sub(
        r"check '(chronyc [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )

    # Handle hostname commands
    line = re.sub(
        r"check '(hostname[^']*)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )

    # Handle nmcli/ip commands
    line = re.sub(
        r"check '(nmcli [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )
    line = re.sub(
        r"check '(ip [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )

    # Handle tuned-adm commands
    line = re.sub(
        r"check '(tuned-adm [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )

    # Handle journalctl commands
    line = re.sub(
        r"check '(journalctl [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )

    # Handle loginctl commands
    line = re.sub(
        r"check '(loginctl [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )

    # Handle passwd/chage/usermod commands
    line = re.sub(
        r"check '(chage [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )

    # Handle tar/file commands
    line = re.sub(
        r"check '(tar [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )
    line = re.sub(
        r"check '(file [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )

    # Handle blkid commands
    line = re.sub(
        r"check '(blkid [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )

    # Handle lsblk commands
    line = re.sub(
        r"check '(lsblk [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )

    # Handle getfacl commands
    line = re.sub(
        r"check '(getfacl [^']+)'",
        rf'check \'run_ssh "{node_ip}" "\1"\'',
        line
    )

    return line, True


def fix_task_file(filepath):
    """Fix a single task file."""
    content = filepath.read_text()
    target = get_target(content)

    # Skip if already fully converted
    if 'run_ssh' in content and "check '" not in content.replace("run_ssh", ""):
        return False, "Already uses run_ssh"

    lines = content.split('\n')
    new_lines = []
    changed = False

    for line in lines:
        new_line, was_changed = fix_check_line(line, target)
        new_lines.append(new_line)
        if was_changed:
            changed = True

    if changed:
        filepath.write_text('\n'.join(new_lines))
        return True, f"Fixed (target: {target})"

    return False, "No changes needed"


def main():
    tasks = sorted(CHECKS_DIR.glob('task-*.sh'))

    fixed = []
    skipped = []

    for task in tasks:
        was_fixed, reason = fix_task_file(task)
        if was_fixed:
            fixed.append((task.name, reason))
        else:
            skipped.append((task.name, reason))

    print(f"Fixed {len(fixed)} task files:\n")
    for name, reason in fixed:
        print(f"  ✓ {name}: {reason}")

    print(f"\nSkipped {len(skipped)} task files:")
    for name, reason in skipped[:10]:  # Show first 10
        print(f"  - {name}: {reason}")
    if len(skipped) > 10:
        print(f"  ... and {len(skipped) - 10} more")


if __name__ == '__main__':
    main()
