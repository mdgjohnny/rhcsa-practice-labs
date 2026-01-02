#!/usr/bin/env python3
"""
RHCSA Practice Labs API
Flask backend for the web interface
"""

import json
import logging
import os
import random
import sqlite3
import subprocess
import sys
from datetime import datetime
from pathlib import Path

from flask import Flask, jsonify, request, send_from_directory

# Configure logging
LOG_FILE = Path(__file__).parent.parent / 'api.log'
logging.basicConfig(
    level=logging.DEBUG,
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


# Initialize DB on startup
init_db()


@app.route('/')
def index():
    """Serve the main page."""
    return send_from_directory(app.static_folder, 'index.html')


@app.route('/api/tasks', methods=['GET'])
def list_tasks():
    """List all available tasks."""
    logger.debug("list_tasks called")
    result = subprocess.run(
        [str(GRADER_SCRIPT), '--list-tasks', '--json'],
        capture_output=True,
        text=True,
        cwd=str(BASE_DIR)
    )
    if result.returncode != 0:
        logger.error(f"list_tasks failed: {result.stderr}")
        return jsonify({'error': result.stderr}), 500

    # Parse the JSON output (fix formatting issues)
    try:
        tasks = json.loads(result.stdout.replace('\n,', ','))
    except json.JSONDecodeError as e:
        logger.warning(f"JSON cleanup needed: {e}")
        # Fallback: clean up the output
        cleaned = result.stdout.replace('\n', '').replace(',]', ']')
        tasks = json.loads(cleaned)

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
        'root_password': ''
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
                    config['root_password'] = value

    return jsonify(config)


@app.route('/api/config', methods=['POST'])
def save_config():
    """Save configuration."""
    data = request.json

    config_content = f'''# RHCSA Practice Labs Configuration
NODE1="{data.get('node1', 'rhcsa1')}"
NODE1_IP="{data.get('node1_ip', '')}"
NODE2="{data.get('node2', 'rhcsa2')}"
NODE2_IP="{data.get('node2_ip', '')}"
ROOT_PASSWORD="{data.get('root_password', '')}"
'''

    with open(CONFIG_FILE, 'w') as f:
        f.write(config_content)

    return jsonify({'status': 'ok'})


@app.route('/api/test-connection', methods=['POST'])
def test_connection():
    """Test SSH connectivity to nodes."""
    result = subprocess.run(
        [str(GRADER_SCRIPT), '--check-ssh'],
        capture_output=True,
        text=True,
        cwd=str(BASE_DIR)
    )

    try:
        ssh_results = json.loads(result.stdout)
    except json.JSONDecodeError:
        return jsonify({
            'node1': False,
            'node2': False,
            'ok': False,
            'error': 'Failed to parse SSH check output'
        }), 500

    node1_ok = next((n['ok'] for n in ssh_results if n['node'] == 'node1'), False)
    node2_ok = next((n['ok'] for n in ssh_results if n['node'] == 'node2'), False)

    return jsonify({
        'node1': node1_ok,
        'node2': node2_ok,
        'ok': node1_ok and node2_ok,
        'details': ssh_results
    })


@app.route('/api/healthcheck', methods=['GET'])
def healthcheck():
    """Comprehensive system health check."""
    result = subprocess.run(
        [str(GRADER_SCRIPT), '--dry-run', '--json'],
        capture_output=True,
        text=True,
        cwd=str(BASE_DIR)
    )

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

    # Run the grader
    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        cwd=str(BASE_DIR)
    )

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
    logger.info(f"grade_single_task called: task_id={task_id}")

    # Extract task number
    task_num = task_id.replace('task-', '') if task_id.startswith('task-') else task_id

    # Build command for single task
    cmd = [str(GRADER_SCRIPT), '--skip-reboot', '--json', f"--tasks={task_num}"]
    logger.debug(f"Running single task grader: {' '.join(cmd)}")

    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        cwd=str(BASE_DIR)
    )

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

    conn = get_db()
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
    conn.commit()
    result_id = c.lastrowid
    conn.close()

    return jsonify({'id': result_id, 'status': 'saved'})


@app.route('/api/results', methods=['GET'])
def get_results():
    """Get all stored results."""
    conn = get_db()
    c = conn.cursor()
    c.execute('SELECT * FROM results ORDER BY timestamp DESC')
    rows = c.fetchall()
    conn.close()

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

    return jsonify(results)


@app.route('/api/stats', methods=['GET'])
def get_stats():
    """Get aggregated statistics."""
    conn = get_db()
    c = conn.cursor()

    # Overall stats
    c.execute('SELECT COUNT(*) as total, SUM(passed) as passed FROM results')
    overall = c.fetchone()

    # Category performance from results
    c.execute('SELECT categories FROM results')
    rows = c.fetchall()
    conn.close()

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
    result = subprocess.run(
        [str(GRADER_SCRIPT), '--list-tasks', '--json'],
        capture_output=True,
        text=True,
        cwd=str(BASE_DIR)
    )
    try:
        tasks = json.loads(result.stdout)
        all_categories = {t['category'] for t in tasks if t.get('category')}
    except (json.JSONDecodeError, KeyError):
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


@app.route('/api/mock-stats', methods=['GET'])
def mock_stats():
    """Generate mock stats data for UI testing."""
    # Simulate varied performance across categories
    mock_categories = {
        'essential-tools': {'earned': 45, 'possible': 60, 'percentage': 75.0, 'tested': True},
        'file-systems': {'earned': 30, 'possible': 50, 'percentage': 60.0, 'tested': True},
        'users-groups': {'earned': 70, 'possible': 80, 'percentage': 87.5, 'tested': True},
        'networking': {'earned': 25, 'possible': 40, 'percentage': 62.5, 'tested': True},
        'security': {'earned': 15, 'possible': 40, 'percentage': 37.5, 'tested': True},
        'containers': {'earned': 10, 'possible': 30, 'percentage': 33.3, 'tested': True},
        'local-storage': {'earned': 35, 'possible': 50, 'percentage': 70.0, 'tested': True},
        'deploy-maintain': {'earned': 40, 'possible': 60, 'percentage': 66.7, 'tested': True},
        'operate-systems': {'earned': 0, 'possible': 0, 'percentage': 0, 'tested': False},
    }

    # Calculate weak areas (lowest percentages among tested)
    tested = {k: v for k, v in mock_categories.items() if v['tested']}
    weak_areas = sorted(tested.items(), key=lambda x: x[1]['percentage'])[:3]

    return jsonify({
        'total_attempts': 12,
        'passed': 7,
        'pass_rate': 58.3,
        'categories': mock_categories,
        'weak_areas': [{'category': k, **v} for k, v in weak_areas]
    })


@app.route('/api/random-tasks', methods=['GET'])
def random_tasks():
    """Get random task selection for exam mode."""
    count = request.args.get('count', 15, type=int)
    count = max(13, min(20, count))  # Clamp between 13-20

    logger.info(f"random_tasks called: count={count}")

    # Get all tasks
    result = subprocess.run(
        [str(GRADER_SCRIPT), '--list-tasks', '--json'],
        capture_output=True,
        text=True,
        cwd=str(BASE_DIR)
    )

    logger.debug(f"list-tasks returncode: {result.returncode}")
    if result.returncode != 0:
        logger.error(f"list-tasks failed: {result.stderr}")
        return jsonify({'error': 'Failed to list tasks', 'message': result.stderr}), 500

    try:
        tasks = json.loads(result.stdout.replace('\n,', ','))
    except json.JSONDecodeError as e:
        logger.warning(f"JSON parse needed cleanup: {e}")
        try:
            cleaned = result.stdout.replace('\n', '').replace(',]', ']')
            tasks = json.loads(cleaned)
        except json.JSONDecodeError as e2:
            logger.error(f"Failed to parse task list: {e2}")
            logger.error(f"Raw output: {result.stdout[:500]}")
            return jsonify({'error': 'Failed to parse tasks', 'message': str(e2)}), 500

    logger.debug(f"Found {len(tasks)} tasks")

    # Exclude task-ssh (it's a prereq check)
    tasks = [t for t in tasks if t['id'] != 'task-ssh']

    # Select random tasks
    selected = random.sample(tasks, min(count, len(tasks)))
    logger.info(f"Selected {len(selected)} random tasks for exam")

    return jsonify(selected)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
