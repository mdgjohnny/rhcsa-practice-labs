#!/usr/bin/env python3
"""
Parse questions from more-questions.md and create task shell scripts.
Sanitizes input and assigns appropriate categories.
"""

import os
import re
from pathlib import Path

# Category mapping based on keywords
CATEGORY_KEYWORDS = {
    'containers': ['container', 'podman', 'docker', 'rootless', 'systemd user', 'mariadb container', 'mysql container', 'ubi8', 'ubi9'],
    'networking': ['network', 'ip address', 'gateway', 'dns', 'hostname', 'ssh', 'nfs', 'port', 'firewall'],
    'users-groups': ['user', 'group', 'password', 'uid', 'gid', 'sudo', 'account', 'member', 'secondary group', 'primary group'],
    'file-systems': ['mount', 'partition', 'ext4', 'xfs', 'vfat', 'fstab', 'label', 'swap', 'lvm', 'logical volume', 'volume group', 'stratis'],
    'local-storage': ['disk', 'partition', 'lvm', 'volume', 'stratis', 'swap', 'extent'],
    'security': ['selinux', 'context', 'permissive', 'enforcing', 'firewall', 'sudo', 'permission', 'acl'],
    'essential-tools': ['tar', 'archive', 'compress', 'grep', 'find', 'redirect', 'pipe', 'regex', 'search', 'copy', 'script', 'bash'],
    'operate-systems': ['boot', 'target', 'systemd', 'service', 'reboot', 'grub', 'rescue', 'emergency', 'runlevel', 'cron', 'at', 'schedule', 'tuned', 'profile'],
    'deploy-maintain': ['yum', 'dnf', 'repo', 'repository', 'install', 'package', 'kernel', 'update', 'web server', 'httpd', 'apache', 'automount', 'autofs'],
}

def sanitize_text(text):
    """Clean up text from markdown quirks."""
    # Remove carriage returns
    text = text.replace('\r', '').replace('␍', '')
    # Remove chapter/exercise references like (Chapter 12, topic: ...) or (Exercise 4-1)
    text = re.sub(r'\s*\(Chapter[^)]+\)', '', text)
    text = re.sub(r'\s*\(Exercise[^)]+\)', '', text)
    text = re.sub(r'\s*\(Exercises?[^)]+\)', '', text)
    # Remove lone periods and dots
    text = re.sub(r'\s*\.\s*$', '', text)
    text = re.sub(r'\s+\.(?:\s|$)', ' ', text)
    # Remove multiple spaces
    text = re.sub(r' +', ' ', text)
    # Remove leading/trailing whitespace
    text = text.strip()
    # Remove bullet points at start
    text = re.sub(r'^[-■•]\s*', '', text)
    # Remove task numbering at start (1., 2., Task 01:, etc.)
    text = re.sub(r'^(Task\s*\d+[:.]\s*|\d+[.)]\s*)', '', text)
    # Normalize quotes
    text = text.replace('"', '"').replace('"', '"').replace(''', "'").replace(''', "'")
    # Remove trailing colons
    text = re.sub(r':\s*$', '', text)
    return text

def categorize(description):
    """Assign category based on keywords in description."""
    desc_lower = description.lower()

    # Score each category
    scores = {}
    for category, keywords in CATEGORY_KEYWORDS.items():
        score = sum(1 for kw in keywords if kw in desc_lower)
        if score > 0:
            scores[category] = score

    if scores:
        # Return category with highest score
        return max(scores, key=scores.get)
    return 'essential-tools'  # Default

def parse_questions(filepath):
    """Parse questions from markdown file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    questions = []

    # Split by various patterns
    lines = content.split('\n')
    current_question = []

    # Patterns to skip entirely
    skip_patterns = [
        r'Humble Bundle',
        r'Cert Guide',
        r'Prerequisites',
        r'Do Not Distribute',
        r'^\d+ Red Hat',
        r'^After applying',
        r'^After completing',
        r'^word here',
        r'^Server with GUI',
        r'^\d+ GB of RAM',
        r'^\d+ GB of disk',
        r'^One additional',
        r'^Install a RHEL',
        r'^Use different IP',
        r'^Exam Questions',
        r'^\d+ MiB',
        r'^password\s*$',
        r'^Some questions',
    ]
    skip_regex = re.compile('|'.join(skip_patterns), re.IGNORECASE)

    for line in lines:
        # Skip headers and separators
        if line.startswith('#') or line.startswith('---') or line.startswith('=='):
            if current_question:
                questions.append(' '.join(current_question))
                current_question = []
            continue

        # Skip empty lines
        if not line.strip():
            if current_question:
                questions.append(' '.join(current_question))
                current_question = []
            continue

        # Skip metadata/junk lines
        stripped = line.strip()
        if skip_regex.search(stripped):
            continue

        # Check if this is a new question (starts with bullet, number, or Task)
        is_new_question = bool(re.match(r'^([-■•]|\d+[.):]|Task\s*\d+)', stripped))

        # Check if this is a sub-item (indented bullet for requirements)
        is_subitem = bool(re.match(r'^\s+[-■•]', line))

        if is_new_question and not is_subitem:
            if current_question:
                questions.append(' '.join(current_question))
            current_question = [sanitize_text(stripped)]
        elif current_question:
            # Continue previous question (merge sub-items)
            sanitized = sanitize_text(stripped)
            if sanitized:
                current_question.append(sanitized)

    # Don't forget last question
    if current_question:
        questions.append(' '.join(current_question))

    # Clean up questions
    cleaned = []
    for q in questions:
        q = sanitize_text(q)
        # Skip very short or meaningless entries
        if len(q) < 30:
            continue
        # Skip entries that are fragments or not actionable
        q_lower = q.lower()
        skip_fragments = [
            'password',
            'members of the group',
            'the container',
            'the server offers',
            'gb of ram',
            'gb of disk',
            'installation pattern',
        ]
        if any(frag in q_lower for frag in skip_fragments) and len(q) < 50:
            continue
        # Skip if it's just describing a requirement without action verb
        if q_lower.startswith(('it ', 'the ', 'a ', 'members ', 'users ', 'others ', 'new files')):
            continue
        # Must start with an action verb or task-like pattern
        action_starters = (
            'create', 'configure', 'set', 'install', 'add', 'modify', 'ensure',
            'find', 'write', 'launch', 'allow', 'change', 'enable', 'disable',
            'schedule', 'resize', 'attach', 'use', 'perform', 'reboot', 'assume',
            'from your', 'as the user', 'on rhcsa', 'using a', 'optimize'
        )
        if not q_lower.startswith(action_starters):
            # Check if it's still a valid question by looking for verbs
            if not any(verb in q_lower[:50] for verb in ['create', 'configure', 'set up', 'mount', 'install']):
                continue
        cleaned.append(q)

    return cleaned

def create_task_script(task_num, description, category, target='node1'):
    """Create a task shell script."""
    # Escape special characters in description for shell
    desc_escaped = description.replace("'", "'\\''")

    script = f'''#!/usr/bin/env bash
# Task: {description}
# Category: {category}
# Target: {target}

# TODO: Implement checks for this task
# This is a placeholder - add actual verification logic

echo "Task {task_num:02d} check not yet implemented"
exit 1
'''
    return script

def main():
    base_dir = Path(__file__).parent.parent
    checks_dir = base_dir / 'checks'
    questions_file = Path.home() / 'more-questions.md'

    if not questions_file.exists():
        print(f"Questions file not found: {questions_file}")
        return

    # Find next task number
    existing = list(checks_dir.glob('task-*.sh'))
    max_num = 0
    for f in existing:
        match = re.search(r'task-(\d+)\.sh', f.name)
        if match:
            max_num = max(max_num, int(match.group(1)))

    next_num = max_num + 1
    print(f"Starting from task-{next_num:02d}")

    # Parse questions
    questions = parse_questions(questions_file)
    print(f"Found {len(questions)} questions")

    # Deduplicate similar questions
    seen = set()
    unique_questions = []
    for q in questions:
        # Create a normalized key for deduplication
        key = re.sub(r'\d+', 'N', q.lower())[:100]
        if key not in seen:
            seen.add(key)
            unique_questions.append(q)

    print(f"After deduplication: {len(unique_questions)} unique questions")

    # Create task scripts
    created = 0
    for i, question in enumerate(unique_questions):
        task_num = next_num + i
        category = categorize(question)

        # Determine target based on content
        target = 'node1'
        if 'node2' in question.lower() or 'rhcsa2' in question.lower():
            target = 'node2'
        elif 'both' in question.lower():
            target = 'both'

        script = create_task_script(task_num, question, category, target)
        task_file = checks_dir / f'task-{task_num:02d}.sh'

        with open(task_file, 'w') as f:
            f.write(script)
        os.chmod(task_file, 0o755)

        print(f"Created task-{task_num:02d}.sh [{category}]: {question[:60]}...")
        created += 1

    print(f"\nCreated {created} new task files")

if __name__ == '__main__':
    main()
