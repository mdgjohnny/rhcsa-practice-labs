#!/usr/bin/env python3
"""
RHCSA Practice Labs API
Flask backend for the web interface
"""

import json
import logging
import os
import random
import re
import sqlite3
import subprocess
import sys
from contextlib import contextmanager
from datetime import datetime
from pathlib import Path

from flask import Flask, jsonify, request, send_from_directory

# Environment configuration
DEBUG = os.environ.get('FLASK_DEBUG', 'false').lower() in ('true', '1', 'yes')
LOG_LEVEL = os.environ.get('LOG_LEVEL', 'DEBUG' if DEBUG else 'INFO').upper()

# Subprocess timeouts (seconds)
TIMEOUT_LIST_TASKS = 30
TIMEOUT_GRADER = 300  # 5 minutes for full grading
TIMEOUT_SINGLE_TASK = 60  # 1 minute per task
TIMEOUT_SSH_CHECK = 10

# Configure logging
LOG_FILE = Path(__file__).parent.parent / 'api.log'
logging.basicConfig(
    level=getattr(logging, LOG_LEVEL, logging.INFO),
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler(sys.stderr)
    ]
)
logger = logging.getLogger(__name__)

app = Flask(__name__, static_folder='../static', static_url_path='')

BASE_DIR = Path(__file__).parent.parent
GRADER_SCRIPT = BASE_DIR / 'exam-grader.sh'
CONFIG_FILE = BASE_DIR / 'config'
CONFIG_EXAMPLE = BASE_DIR / 'config.example'
DB_FILE = BASE_DIR / 'results.db'


def init_db():
    """Initialize SQLite database for storing results."""
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    c.execute('''
        CREATE TABLE IF NOT EXISTS results (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            mode TEXT NOT NULL,
            score INTEGER NOT NULL,
            total INTEGER NOT NULL,
            passed INTEGER NOT NULL,
            duration_seconds INTEGER,
            categories TEXT NOT NULL,
            checks TEXT NOT NULL
        )
    ''')
    conn.commit()
    conn.close()


def get_db():
    """Get database connection."""
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    return conn


@contextmanager
def db_connection():
    """Context manager for database connections."""
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def parse_grader_json(output):
    """Parse JSON output from grader script, handling formatting quirks."""
    try:
        return json.loads(output)
    except json.JSONDecodeError:
        # Try cleaning up common formatting issues
        cleaned = output.replace('\n,', ',').replace(',]', ']').replace(',}', '}')
        return json.loads(cleaned)


# Initialize DB on startup
init_db()


@app.route('/')
def index():
    """Serve the main page."""
    return send_from_directory(app.static_folder, 'index.html')


@app.route('/favicon.svg')
def favicon():
    """Serve favicon."""
    return send_from_directory(app.static_folder, 'favicon.svg')


@app.route('/api/tasks', methods=['GET'])
def list_tasks():
    """List all available tasks."""
    logger.debug("list_tasks called")
    try:
        result = subprocess.run(
            [str(GRADER_SCRIPT), '--list-tasks', '--json'],
            capture_output=True,
            text=True,
            cwd=str(BASE_DIR),
            timeout=TIMEOUT_LIST_TASKS
        )
    except subprocess.TimeoutExpired:
        logger.error("list_tasks timed out")
        return jsonify({'error': 'Request timed out'}), 504

    if result.returncode != 0:
        logger.error(f"list_tasks failed: {result.stderr}")
        return jsonify({'error': result.stderr}), 500

    try:
        tasks = parse_grader_json(result.stdout)
    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse task list: {e}")
        return jsonify({'error': 'Failed to parse task list'}), 500

    logger.debug(f"Returning {len(tasks)} tasks")
    return jsonify(tasks)


@app.route('/api/config', methods=['GET'])
def get_config():
    """Get current configuration."""
    config = {
        'node1': 'rhcsa1',
        'node1_ip': '',
        'node2': 'rhcsa2',
        'node2_ip': '',
        'has_password': False
    }

    if CONFIG_FILE.exists():
        with open(CONFIG_FILE) as f:
            for line in f:
                line = line.strip()
                if line.startswith('#') or '=' not in line:
                    continue
                key, value = line.split('=', 1)
                key = key.strip().lower()
                value = value.strip().strip('"\'')
                if key == 'node1':
                    config['node1'] = value
                elif key == 'node1_ip':
                    config['node1_ip'] = value
                elif key == 'node2':
                    config['node2'] = value
                elif key == 'node2_ip':
                    config['node2_ip'] = value
                elif key == 'root_password':
                    # Don't expose password, just indicate if set
                    config['has_password'] = bool(value)

    return jsonify(config)


def sanitize_config_value(value):
    """Sanitize config values to prevent injection."""
    if not value:
        return ''
    # Remove quotes and shell metacharacters
    dangerous_chars = ['"', "'", '`', '$', '\\', ';', '&', '|', '>', '<', '\n', '\r']
    result = str(value)
    for char in dangerous_chars:
        result = result.replace(char, '')
    return result.strip()


def validate_ip(ip):
    """Validate IP address format."""
    if not ip:
        return True  # Empty is ok
    pattern = r'^(\d{1,3}\.){3}\d{1,3}$'
    if not re.match(pattern, ip):
        return False
    parts = ip.split('.')
    return all(0 <= int(p) <= 255 for p in parts)


def validate_hostname(name):
    """Validate hostname format."""
    if not name:
        return False
    # Allow alphanumeric, hyphens, max 63 chars per label
    pattern = r'^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$'
    return bool(re.match(pattern, name))


@app.route('/api/config', methods=['POST'])
def save_config():
    """Save configuration."""
    data = request.json or {}

    # Validate and sanitize inputs
    node1 = sanitize_config_value(data.get('node1', 'rhcsa1'))
    node2 = sanitize_config_value(data.get('node2', 'rhcsa2'))
    node1_ip = sanitize_config_value(data.get('node1_ip', ''))
    node2_ip = sanitize_config_value(data.get('node2_ip', ''))
    root_password = sanitize_config_value(data.get('root_password', ''))

    # Validate hostnames
    if not validate_hostname(node1):
        return jsonify({'error': 'Invalid node1 hostname'}), 400
    if not validate_hostname(node2):
        return jsonify({'error': 'Invalid node2 hostname'}), 400

    # Validate IPs if provided
    if node1_ip and not validate_ip(node1_ip):
        return jsonify({'error': 'Invalid node1 IP address'}), 400
    if node2_ip and not validate_ip(node2_ip):
        return jsonify({'error': 'Invalid node2 IP address'}), 400

    # If password not provided, preserve existing
    if not root_password and CONFIG_FILE.exists():
        with open(CONFIG_FILE) as f:
            for line in f:
                if line.strip().startswith('ROOT_PASSWORD='):
                    root_password = line.split('=', 1)[1].strip().strip('"\'')
                    break

    config_content = f'''# RHCSA Practice Labs Configuration
NODE1="{node1}"
NODE1_IP="{node1_ip}"
NODE2="{node2}"
NODE2_IP="{node2_ip}"
ROOT_PASSWORD="{root_password}"
'''

    with open(CONFIG_FILE, 'w') as f:
        f.write(config_content)

    return jsonify({'status': 'ok'})


@app.route('/api/test-connection', methods=['POST'])
def test_connection():
    """Test SSH connectivity to nodes."""
    data = request.json or {}
    target = data.get('target') # node1, node2, or None (both)
    
    cmd = [str(GRADER_SCRIPT), '--check-ssh']
    if target in ('node1', 'node2'):
        cmd.append(f"--target={target}")

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            cwd=str(BASE_DIR),
            timeout=TIMEOUT_SSH_CHECK
        )
    except subprocess.TimeoutExpired:
        return jsonify({
            'node1': False,
            'node2': False,
            'ok': False,
            'error': 'SSH check timed out'
        }), 504

    try:
        ssh_results = json.loads(result.stdout)
    except json.JSONDecodeError:
        return jsonify({
            'node1': False,
            'node2': False,
            'ok': False,
            'error': 'Failed to parse SSH check output'
        }), 500

    node1_ok = next((n.get('ok', False) for n in ssh_results if n['node'] == 'node1'), False)
    node2_ok = next((n.get('ok', False) for n in ssh_results if n['node'] == 'node2'), False)

    return jsonify({
        'node1': node1_ok,
        'node2': node2_ok,
        'ok': (node1_ok or target == 'node2') and (node2_ok or target == 'node1'),
        'details': ssh_results
    })


@app.route('/api/reboot-vm', methods=['POST'])
def reboot_vm():
    """Reboot a specific VM and wait for it to come back online."""
    import time

    data = request.get_json() or {}
    target = data.get('node', 'node1')  # Default to node1

    if target not in ('node1', 'node2'):
        return jsonify({'error': 'Invalid node. Use "node1" or "node2"'}), 400

    logger.info(f"Rebooting {target}")

    # Load config
    if not CONFIG_FILE.exists():
        return jsonify({'error': 'Config file not found'}), 400

    config = {}
    with open(CONFIG_FILE) as f:
        for line in f:
            line = line.strip()
            if line.startswith('#') or '=' not in line:
                continue
            key, value = line.split('=', 1)
            config[key.strip()] = value.strip().strip('"\'')

    node_ip = config.get(f'{target.upper()}_IP', '')
    password = config.get('ROOT_PASSWORD', '')

    if not node_ip:
        return jsonify({'error': f'{target} IP not configured'}), 400
    if not password:
        return jsonify({'error': 'Root password not configured'}), 400

    result = {'node': target, 'rebooted': False, 'online': False}

    # Send reboot command
    try:
        reboot_cmd = ['sshpass', '-p', password, 'ssh', '-o', 'ConnectTimeout=10',
                      '-o', 'StrictHostKeyChecking=no', f'root@{node_ip}',
                      'nohup reboot &>/dev/null &']
        subprocess.run(reboot_cmd, timeout=15, capture_output=True)
        result['rebooted'] = True
        logger.info(f"Reboot command sent to {target} ({node_ip})")
    except Exception as e:
        logger.error(f"Failed to reboot {target}: {e}")
        return jsonify({'error': f'Failed to send reboot command: {e}', **result}), 500

    # Wait for node to go down
    time.sleep(5)

    # Wait for node to come back (up to 90 seconds)
    max_wait = 90
    start_time = time.time()

    while time.time() - start_time < max_wait:
        try:
            check_cmd = ['sshpass', '-p', password, 'ssh', '-o', 'ConnectTimeout=5',
                         '-o', 'StrictHostKeyChecking=no', f'root@{node_ip}', 'echo ok']
            check_result = subprocess.run(check_cmd, timeout=10, capture_output=True, text=True)
            if check_result.returncode == 0 and 'ok' in check_result.stdout:
                result['online'] = True
                logger.info(f"{target} is back online")
                break
        except Exception:
            pass
        time.sleep(5)

    logger.info(f"Reboot complete: {target} online={result['online']}")

    return jsonify({
        'ok': result['online'],
        **result,
        'message': f'{target} rebooted and online' if result['online'] else f'{target} failed to come back online'
    })


@app.route('/api/healthcheck', methods=['GET'])
def healthcheck():
    """Comprehensive system health check."""
    try:
        result = subprocess.run(
            [str(GRADER_SCRIPT), '--dry-run', '--json'],
            capture_output=True,
            text=True,
            cwd=str(BASE_DIR),
            timeout=TIMEOUT_LIST_TASKS
        )
    except subprocess.TimeoutExpired:
        return jsonify({'ok': False, 'error': 'Health check timed out'}), 504

    try:
        health = json.loads(result.stdout)
    except json.JSONDecodeError:
        return jsonify({
            'ok': False,
            'error': 'Failed to parse healthcheck output',
            'raw': result.stdout
        }), 500

    return jsonify(health)


@app.route('/api/run', methods=['POST'])
def run_grader():
    """Run the exam grader."""
    data = request.json or {}
    mode = data.get('mode', 'practice')
    tasks = data.get('tasks', [])

    logger.info(f"run_grader called: mode={mode}, tasks={tasks}")

    # Validate tasks
    if not tasks or len(tasks) == 0:
        logger.warning("run_grader: No tasks provided")
        return jsonify({
            'error': 'No tasks selected',
            'message': 'Please select at least one task to grade.'
        }), 400

    # Extract task numbers - handles both "task-01" and "01" formats
    task_nums = []
    for t in tasks:
        num = t.replace('task-', '') if isinstance(t, str) and t.startswith('task-') else str(t)
        task_nums.append(num)

    # Build command (Flask must be run with sudo for SSH access to VMs)
    cmd = [str(GRADER_SCRIPT), '--skip-reboot', '--json', f"--tasks={','.join(task_nums)}"]
    logger.debug(f"Running grader command: {' '.join(cmd)}")

    # Run the grader with timeout
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            cwd=str(BASE_DIR),
            timeout=TIMEOUT_GRADER
        )
    except subprocess.TimeoutExpired:
        logger.error(f"Grader timed out after {TIMEOUT_GRADER}s")
        return jsonify({
            'error': 'Grading timed out',
            'message': f'Grading took longer than {TIMEOUT_GRADER} seconds. Try fewer tasks.'
        }), 504

    logger.debug(f"Grader returncode: {result.returncode}")
    if result.stderr:
        logger.debug(f"Grader stderr: {result.stderr[:500]}")

    if result.returncode != 0:
        error_msg = result.stderr.strip() if result.stderr else 'Grader process failed'
        logger.error(f"Grader failed: {error_msg}")
        logger.error(f"Grader stdout: {result.stdout[:500] if result.stdout else 'empty'}")

        # Check for common errors and provide helpful messages
        if 'must be run as root' in (result.stdout or ''):
            error_msg = 'Flask must be run with sudo: sudo python app.py'

        return jsonify({
            'error': 'Grader failed',
            'message': error_msg,
            'details': result.stdout[:500] if result.stdout else None
        }), 500

    try:
        grader_result = json.loads(result.stdout)
        logger.info(f"Grader success: score={grader_result.get('score', 'N/A')}/{grader_result.get('total', 'N/A')}")
    except json.JSONDecodeError as e:
        logger.error(f"JSON parse error: {e}")
        logger.error(f"Raw output: {result.stdout[:500]}")
        return jsonify({
            'error': 'Invalid grader output',
            'message': f'Failed to parse grader response: {str(e)}',
            'raw': result.stdout[:1000]
        }), 500

    return jsonify(grader_result)


@app.route('/api/grade-task/<task_id>', methods=['POST'])
def grade_single_task(task_id):
    """Grade a single task and return the result."""
    # Get optional target VM override
    target = request.args.get('target', None)
    if target and target not in ('node1', 'node2', 'both'):
        return jsonify({'error': 'Invalid target', 'message': 'Target must be node1, node2, or both'}), 400

    logger.info(f"grade_single_task called: task_id={task_id}, target={target}")

    # Extract task number
    task_num = task_id.replace('task-', '') if task_id.startswith('task-') else task_id

    # Build command for single task
    cmd = [str(GRADER_SCRIPT), '--skip-reboot', '--json', f"--tasks={task_num}"]
    if target:
        cmd.append(f"--target={target}")
    logger.debug(f"Running single task grader: {' '.join(cmd)}")

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            cwd=str(BASE_DIR),
            timeout=TIMEOUT_SINGLE_TASK
        )
    except subprocess.TimeoutExpired:
        logger.error(f"Single task grader timed out after {TIMEOUT_SINGLE_TASK}s")
        return jsonify({
            'error': 'Grading timed out',
            'message': f'Task grading took longer than {TIMEOUT_SINGLE_TASK} seconds.',
            'task_id': task_id
        }), 504

    logger.debug(f"Single task grader returncode: {result.returncode}")

    if result.returncode != 0:
        error_msg = result.stderr.strip() if result.stderr else 'Grader process failed'
        logger.error(f"Single task grader failed: {error_msg}")

        # Check for common errors
        if 'must be run as root' in (result.stdout or ''):
            error_msg = 'Flask must be run with sudo: sudo python app.py'

        return jsonify({
            'error': 'Grader failed',
            'message': error_msg,
            'task_id': task_id
        }), 500

    try:
        grader_result = json.loads(result.stdout)

        # Extract all checks for this task (tasks can have multiple checks)
        task_checks = [c for c in grader_result.get('checks', [])
                       if c.get('task') == task_id or c.get('task') == f"task-{task_num}"]

        if task_checks:
            # Aggregate results
            total_points = sum(c.get('points', 0) for c in task_checks if c.get('passed'))
            max_points = sum(c.get('points', 0) for c in task_checks)
            all_passed = all(c.get('passed', False) for c in task_checks)
            passed_count = sum(1 for c in task_checks if c.get('passed'))
            total_count = len(task_checks)

            # Build detailed message
            check_details = [f"{'✓' if c.get('passed') else '✗'} {c.get('check', 'Check')}"
                             for c in task_checks]

            logger.info(f"Task {task_id}: {passed_count}/{total_count} checks passed, {total_points}/{max_points} points")
            return jsonify({
                'task_id': task_id,
                'passed': all_passed,
                'points': total_points,
                'max_points': max_points,
                'checks_passed': passed_count,
                'checks_total': total_count,
                'details': check_details,
                'message': f"{passed_count}/{total_count} checks passed"
            })
        else:
            return jsonify({
                'task_id': task_id,
                'passed': False,
                'message': 'Task not found in grader output'
            })

    except json.JSONDecodeError as e:
        logger.error(f"JSON parse error for single task: {e}")
        return jsonify({
            'error': 'Invalid grader output',
            'message': str(e),
            'task_id': task_id
        }), 500


@app.route('/api/results', methods=['POST'])
def save_result():
    """Save exam/practice result to database."""
    data = request.json

    with db_connection() as conn:
        c = conn.cursor()
        c.execute('''
            INSERT INTO results (timestamp, mode, score, total, passed, duration_seconds, categories, checks)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            data.get('timestamp', datetime.now().isoformat()),
            data.get('mode', 'practice'),
            data.get('score', 0),
            data.get('total', 0),
            1 if data.get('passed') else 0,
            data.get('duration_seconds'),
            json.dumps(data.get('categories', {})),
            json.dumps(data.get('checks', []))
        ))
        result_id = c.lastrowid

    return jsonify({'id': result_id, 'status': 'saved'})


@app.route('/api/results', methods=['GET'])
def get_results():
    """Get stored results with optional pagination."""
    # Pagination parameters
    limit = request.args.get('limit', 20, type=int)
    offset = request.args.get('offset', 0, type=int)
    limit = max(1, min(100, limit))  # Clamp between 1-100
    offset = max(0, offset)

    with db_connection() as conn:
        c = conn.cursor()

        # Get total count
        c.execute('SELECT COUNT(*) as count FROM results')
        total = c.fetchone()['count']

        # Get paginated results
        c.execute('SELECT * FROM results ORDER BY timestamp DESC LIMIT ? OFFSET ?', (limit, offset))
        rows = c.fetchall()

        results = []
        for row in rows:
            results.append({
                'id': row['id'],
                'timestamp': row['timestamp'],
                'mode': row['mode'],
                'score': row['score'],
                'total': row['total'],
                'passed': bool(row['passed']),
                'duration_seconds': row['duration_seconds'],
                'categories': json.loads(row['categories']),
                'checks': json.loads(row['checks'])
            })

    return jsonify({
        'results': results,
        'total': total,
        'limit': limit,
        'offset': offset,
        'has_more': offset + len(results) < total
    })


@app.route('/api/results/<int:result_id>', methods=['DELETE'])
def delete_result(result_id):
    """Delete a specific result by ID."""
    logger.info(f"Deleting result id={result_id}")
    with db_connection() as conn:
        c = conn.cursor()
        c.execute('DELETE FROM results WHERE id = ?', (result_id,))
        if c.rowcount == 0:
            return jsonify({'error': 'Result not found'}), 404
    return jsonify({'status': 'deleted', 'id': result_id})


@app.route('/api/results', methods=['DELETE'])
def clear_all_results():
    """Clear all stored results."""
    logger.info("Clearing all results")
    with db_connection() as conn:
        c = conn.cursor()
        c.execute('DELETE FROM results')
        deleted_count = c.rowcount
    return jsonify({'status': 'cleared', 'deleted': deleted_count})


@app.route('/api/stats', methods=['GET'])
def get_stats():
    """Get aggregated statistics."""
    with db_connection() as conn:
        c = conn.cursor()

        # Overall stats
        c.execute('SELECT COUNT(*) as total, SUM(passed) as passed FROM results')
        overall = c.fetchone()

        # Category performance from results
        c.execute('SELECT categories FROM results')
        rows = c.fetchall()

    category_totals = {}
    for row in rows:
        cats = json.loads(row['categories'])
        for cat, stats in cats.items():
            if cat not in category_totals:
                category_totals[cat] = {'earned': 0, 'possible': 0}
            category_totals[cat]['earned'] += stats.get('earned', 0)
            category_totals[cat]['possible'] += stats.get('possible', 0)

    # Get all available categories from tasks
    all_categories = set()
    try:
        result = subprocess.run(
            [str(GRADER_SCRIPT), '--list-tasks', '--json'],
            capture_output=True,
            text=True,
            cwd=str(BASE_DIR),
            timeout=TIMEOUT_LIST_TASKS
        )
        tasks = json.loads(result.stdout)
        all_categories = {t['category'] for t in tasks if t.get('category')}
    except (subprocess.TimeoutExpired, json.JSONDecodeError, KeyError):
        pass

    # Calculate percentages for all categories
    category_stats = {}
    for cat in all_categories:
        if cat in category_totals and category_totals[cat]['possible'] > 0:
            stats = category_totals[cat]
            category_stats[cat] = {
                'earned': stats['earned'],
                'possible': stats['possible'],
                'percentage': round(stats['earned'] / stats['possible'] * 100, 1),
                'tested': True
            }
        else:
            category_stats[cat] = {
                'earned': 0,
                'possible': 0,
                'percentage': 0,
                'tested': False
            }

    # Sort by percentage (weakest first), but only include tested categories in weak_areas
    tested_cats = {k: v for k, v in category_stats.items() if v['tested']}
    weak_areas = sorted(tested_cats.items(), key=lambda x: x[1]['percentage'])

    return jsonify({
        'total_attempts': overall['total'] or 0,
        'passed': overall['passed'] or 0,
        'pass_rate': round((overall['passed'] or 0) / (overall['total'] or 1) * 100, 1),
        'categories': category_stats,
        'weak_areas': [{'category': k, **v} for k, v in weak_areas[:3]]
    })





@app.route('/api/random-tasks', methods=['GET'])
def random_tasks():
    """Get random task selection for exam mode."""
    count = request.args.get('count', 15, type=int)
    count = max(13, min(20, count))  # Clamp between 13-20

    logger.info(f"random_tasks called: count={count}")

    # Get all tasks
    try:
        result = subprocess.run(
            [str(GRADER_SCRIPT), '--list-tasks', '--json'],
            capture_output=True,
            text=True,
            cwd=str(BASE_DIR),
            timeout=TIMEOUT_LIST_TASKS
        )
    except subprocess.TimeoutExpired:
        logger.error("random_tasks: list-tasks timed out")
        return jsonify({'error': 'Request timed out'}), 504

    logger.debug(f"list-tasks returncode: {result.returncode}")
    if result.returncode != 0:
        logger.error(f"list-tasks failed: {result.stderr}")
        return jsonify({'error': 'Failed to list tasks', 'message': result.stderr}), 500

    try:
        tasks = parse_grader_json(result.stdout)
    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse task list: {e}")
        return jsonify({'error': 'Failed to parse tasks', 'message': str(e)}), 500

    logger.debug(f"Found {len(tasks)} tasks")

    # Exclude task-ssh (it's a prereq check)
    tasks = [t for t in tasks if t['id'] != 'task-ssh']

    # Select random tasks
    selected = random.sample(tasks, min(count, len(tasks)))
    logger.info(f"Selected {len(selected)} random tasks for exam")

    return jsonify(selected)


@app.route('/api/discover-ips', methods=['POST'])
def discover_ips():
    """Discover VM IPs using virsh or other methods."""
    logger.info("discover_ips called")

    # Load current config to get VM names
    config = {}
    if CONFIG_FILE.exists():
        with open(CONFIG_FILE) as f:
            for line in f:
                line = line.strip()
                if line.startswith('#') or '=' not in line:
                    continue
                key, value = line.split('=', 1)
                config[key.strip()] = value.strip().strip('"\'')

    node1_name = config.get('NODE1', 'rhcsa1')
    node2_name = config.get('NODE2', 'rhcsa2')

    discovered = {'node1': None, 'node2': None, 'method': None}

    # Try virsh domifaddr first
    try:
        for node_key, vm_name in [('node1', node1_name), ('node2', node2_name)]:
            result = subprocess.run(
                ['virsh', 'domifaddr', vm_name],
                capture_output=True,
                text=True,
                timeout=10
            )
            if result.returncode == 0:
                # Parse virsh output to find IP
                for line in result.stdout.split('\n'):
                    if 'ipv4' in line.lower():
                        parts = line.split()
                        for part in parts:
                            if '/' in part:  # IP with CIDR notation
                                ip = part.split('/')[0]
                                if re.match(r'^(\d{1,3}\.){3}\d{1,3}$', ip):
                                    discovered[node_key] = ip
                                    discovered['method'] = 'virsh'
                                    break
    except (subprocess.TimeoutExpired, FileNotFoundError) as e:
        logger.debug(f"virsh method failed: {e}")

    # Try arp-scan or nmap as fallback (if virsh didn't work)
    if not discovered['node1'] and not discovered['node2']:
        # Try to get IPs from arp cache if we have current IPs configured
        current_ip1 = config.get('NODE1_IP', '')
        current_ip2 = config.get('NODE2_IP', '')

        if current_ip1 or current_ip2:
            # Ping to refresh arp cache then check
            for ip in [current_ip1, current_ip2]:
                if ip:
                    try:
                        subprocess.run(['ping', '-c', '1', '-W', '1', ip],
                                      capture_output=True, timeout=2)
                    except:
                        pass

            # If ping succeeds, the IP is still valid
            pass

        # Heuristic Scan: Check for EXPECTED_IPs from task files
        # Dynamic discovery based on available tasks
        candidates = []
        # Always check configured IPs first if they are different from what we found
        if config.get('NODE1_IP'): candidates.append(('node1', config['NODE1_IP']))
        if config.get('NODE2_IP'): candidates.append(('node2', config['NODE2_IP']))

        try:
            checks_dir = Path('./checks')
            if checks_dir.exists():
                for task_file in checks_dir.glob('task-*.sh'):
                    try:
                        content = task_file.read_text()
                        # Extract EXPECTED_IP and Target
                        expected_ip_match = re.search(r'# EXPECTED_IP:\s*([\d\.]+)', content)
                        if expected_ip_match:
                            ip = expected_ip_match.group(1)
                            # Determine target node
                            target_match = re.search(r'# Target:\s*(node\d)', content)
                            target = target_match.group(1) if target_match else 'node1'
                            
                            # Add to candidates
                            candidates.append((target, ip))
                    except:
                        continue
        except Exception as e:
            logger.error(f"Failed to scan task files: {e}")
            
        # Add basic fallbacks just in case
        candidates.extend([
            ('node2', '192.168.122.131'), ('node1', '192.168.122.141')
        ])
        
        # Deduplicate while preserving order
        seen = set()
        unique_candidates = []
        for c in candidates:
            if c not in seen:
                unique_candidates.append(c)
                seen.add(c)
        
        for node_key, ip in unique_candidates:
            if not discovered[node_key]:
                try:
                    # Ping check with short timeout
                    ping_res = subprocess.run(
                        ['ping', '-c', '1', '-W', '1', ip],
                        capture_output=True
                    )
                    if ping_res.returncode == 0:
                        discovered[node_key] = ip
                        if not discovered['method']:
                             discovered['method'] = 'scan'
                except:
                    pass

        # If we found IPs, update the results
        if discovered['node1'] or discovered['node2']:
            # We found something
            pass

            if current_ip1:
                try:
                    result = subprocess.run(
                        ['ping', '-c', '1', '-W', '2', current_ip1],
                        capture_output=True, timeout=5
                    )
                    if result.returncode == 0:
                        discovered['node1'] = current_ip1
                        discovered['method'] = 'ping'
                except:
                    pass

            if current_ip2:
                try:
                    result = subprocess.run(
                        ['ping', '-c', '1', '-W', '2', current_ip2],
                        capture_output=True, timeout=5
                    )
                    if result.returncode == 0:
                        discovered['node2'] = current_ip2
                        discovered['method'] = 'ping'
                except:
                    pass

    # Update config object for return
    if discovered['node1']:
        config['node1_ip'] = discovered['node1']
    if discovered['node2']:
        config['node2_ip'] = discovered['node2']

    # Update the actual config file if we found anything
    if discovered['node1'] or discovered['node2']:
        start_key = None
        new_lines = []
        if CONFIG_FILE.exists():
            with open(CONFIG_FILE) as f:
                new_lines = f.readlines()
        else:
             new_lines = ["NODE1=rhcsa1\n", "NODE2=rhcsa2\n"]

        # Simple update or append
        updated_n1 = False
        updated_n2 = False
        final_lines = []
        
        for line in new_lines:
            if line.startswith('NODE1_IP=') and discovered['node1']:
                final_lines.append(f"NODE1_IP={discovered['node1']}\n")
                updated_n1 = True
            elif line.startswith('NODE2_IP=') and discovered['node2']:
                final_lines.append(f"NODE2_IP={discovered['node2']}\n")
                updated_n2 = True
            else:
                final_lines.append(line)
        
        if discovered['node1'] and not updated_n1:
            final_lines.append(f"NODE1_IP={discovered['node1']}\n")
        if discovered['node2'] and not updated_n2:
            final_lines.append(f"NODE2_IP={discovered['node2']}\n")
            
        with open(CONFIG_FILE, 'w') as f:
            f.writelines(final_lines)

    logger.info(f"IP discovery result: {discovered}")
    return jsonify({
        'node1': node1_name,
        'node1_ip': config.get('node1_ip', ''),
        'node2': node2_name,
        'node2_ip': config.get('node2_ip', ''),
        'method': discovered['method'] or 'none'
    })


if __name__ == '__main__':
    logger.info(f"Starting RHCSA Practice Labs API (debug={DEBUG}, log_level={LOG_LEVEL})")
    app.run(host='0.0.0.0', port=5000, debug=DEBUG)
