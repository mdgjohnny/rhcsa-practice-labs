#!/usr/bin/env python3
"""
RHCSA Practice Labs API
Flask backend for the web interface
"""

import json
import os
import random
import sqlite3
import subprocess
from datetime import datetime
from pathlib import Path

from flask import Flask, jsonify, request, send_from_directory

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
    result = subprocess.run(
        [str(GRADER_SCRIPT), '--list-tasks', '--json'],
        capture_output=True,
        text=True,
        cwd=str(BASE_DIR)
    )
    if result.returncode != 0:
        return jsonify({'error': result.stderr}), 500

    # Parse the JSON output (fix formatting issues)
    try:
        tasks = json.loads(result.stdout.replace('\n,', ','))
    except json.JSONDecodeError:
        # Fallback: clean up the output
        cleaned = result.stdout.replace('\n', '').replace(',]', ']')
        tasks = json.loads(cleaned)

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
    data = request.json
    mode = data.get('mode', 'practice')  # practice or exam
    tasks = data.get('tasks', [])  # List of task IDs

    # Build command
    cmd = [str(GRADER_SCRIPT), '--skip-reboot', '--json']

    if tasks:
        # Extract task numbers - handles both "task-01" and "01" formats
        task_nums = []
        for t in tasks:
            # Strip 'task-' prefix if present, keep the rest
            num = t.replace('task-', '') if t.startswith('task-') else t
            task_nums.append(num)
        cmd.append(f"--tasks={','.join(task_nums)}")

    # Run the grader
    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        cwd=str(BASE_DIR)
    )

    if result.returncode != 0:
        return jsonify({'error': result.stderr or 'Grader failed'}), 500

    try:
        grader_result = json.loads(result.stdout)
    except json.JSONDecodeError as e:
        return jsonify({'error': f'Failed to parse grader output: {e}', 'raw': result.stdout}), 500

    return jsonify(grader_result)


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

    # Category performance
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

    # Calculate percentages
    category_stats = {}
    for cat, stats in category_totals.items():
        if stats['possible'] > 0:
            category_stats[cat] = {
                'earned': stats['earned'],
                'possible': stats['possible'],
                'percentage': round(stats['earned'] / stats['possible'] * 100, 1)
            }

    # Sort by percentage (weakest first)
    weak_areas = sorted(category_stats.items(), key=lambda x: x[1]['percentage'])

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

    # Get all tasks
    result = subprocess.run(
        [str(GRADER_SCRIPT), '--list-tasks', '--json'],
        capture_output=True,
        text=True,
        cwd=str(BASE_DIR)
    )

    try:
        tasks = json.loads(result.stdout.replace('\n,', ','))
    except json.JSONDecodeError:
        cleaned = result.stdout.replace('\n', '').replace(',]', ']')
        tasks = json.loads(cleaned)

    # Exclude task-ssh (it's a prereq check)
    tasks = [t for t in tasks if t['id'] != 'task-ssh']

    # Select random tasks
    selected = random.sample(tasks, min(count, len(tasks)))

    return jsonify(selected)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
