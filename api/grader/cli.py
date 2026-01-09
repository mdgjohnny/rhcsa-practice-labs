#!/usr/bin/env python3
"""CLI for the RHCSA grader.

Usage:
    python -m api.grader.cli list                    # List all tasks
    python -m api.grader.cli grade task-100          # Grade single task
    python -m api.grader.cli grade task-01 task-02   # Grade multiple tasks
    python -m api.grader.cli bundle task-100         # Show bundled script
    python -m api.grader.cli test                    # Run tests
"""

import argparse
import json
import sys
from pathlib import Path

# Add parent directories to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from api.grader.bundler import TaskBundler
from api.grader.executor import LocalExecutor, RemoteExecutor
from api.grader.grader import Grader, create_grader_from_session, create_local_grader


def get_base_dir() -> Path:
    """Get the project base directory."""
    return Path(__file__).parent.parent.parent


def cmd_list(args):
    """List all available tasks."""
    bundler = TaskBundler(get_base_dir() / 'checks')
    tasks = bundler.list_tasks()
    
    if args.json:
        print(json.dumps(tasks, indent=2))
    else:
        print(f"Found {len(tasks)} tasks:\n")
        for t in tasks:
            target = f"[{t['target']}]".ljust(8)
            print(f"{t['id']:12} {target} {t['category']:18} {t['title']}")


def cmd_grade(args):
    """Grade one or more tasks."""
    base_dir = get_base_dir()
    checks_dir = base_dir / 'checks'
    sessions_db = base_dir / 'sessions.db'
    
    # Try to create grader from session first
    grader = create_grader_from_session(checks_dir, sessions_db)
    
    if grader is None:
        print("No cloud session found, using local executor")
        grader = create_local_grader(checks_dir, as_root=False)
    else:
        print("Using cloud session for grading")
    
    if len(args.tasks) == 1:
        # Single task
        result = grader.evaluate_task(args.tasks[0])
        
        if args.json:
            print(json.dumps(result.to_dict(), indent=2))
        else:
            print(f"\nTask: {result.task_id}")
            print(f"Category: {result.category}")
            print(f"Passed: {'YES' if result.passed else 'NO'}")
            print(f"Points: {result.points_earned}/{result.points_possible}")
            if result.error:
                print(f"Error: {result.error}")
            print("\nChecks:")
            for c in result.checks:
                status = "\u2713" if c.passed else "\u2717"
                print(f"  {status} {c.check} ({c.points} pts)")
    else:
        # Multiple tasks
        result = grader.grade(args.tasks)
        
        if args.json:
            print(json.dumps(result.to_dict(), indent=2))
        else:
            print(f"\nGraded {len(result.task_results)} tasks")
            print(f"Score: {result.score}/{result.total} ({result.pass_percentage:.1f}%)")
            print(f"Passed: {'YES' if result.passed else 'NO'}")
            print("\nBy Category:")
            for cat, stats in sorted(result.categories.items()):
                pct = (stats['earned'] / stats['possible'] * 100) if stats['possible'] > 0 else 0
                print(f"  {cat}: {stats['earned']}/{stats['possible']} ({pct:.0f}%)")
            print("\nBy Task:")
            for tr in result.task_results:
                status = "\u2713" if tr.passed else "\u2717"
                print(f"  {status} {tr.task_id}: {tr.points_earned}/{tr.points_possible}")


def cmd_bundle(args):
    """Show the bundled script for a task."""
    bundler = TaskBundler(get_base_dir() / 'checks')
    
    env_vars = {}
    if args.node1_ip:
        env_vars['NODE1_IP'] = args.node1_ip
    if args.node2_ip:
        env_vars['NODE2_IP'] = args.node2_ip
    
    script = bundler.bundle(args.task, env_vars=env_vars or None)
    
    if script:
        print(script)
    else:
        print(f"Error: Task '{args.task}' not found", file=sys.stderr)
        sys.exit(1)


def cmd_test(args):
    """Run the test suite."""
    from api.grader.test_grader import run_tests
    sys.exit(run_tests())


def main():
    parser = argparse.ArgumentParser(description='RHCSA Grader CLI')
    subparsers = parser.add_subparsers(dest='command', help='Commands')
    
    # list command
    list_parser = subparsers.add_parser('list', help='List all tasks')
    list_parser.add_argument('--json', action='store_true', help='Output as JSON')
    
    # grade command
    grade_parser = subparsers.add_parser('grade', help='Grade tasks')
    grade_parser.add_argument('tasks', nargs='+', help='Task IDs to grade')
    grade_parser.add_argument('--json', action='store_true', help='Output as JSON')
    
    # bundle command
    bundle_parser = subparsers.add_parser('bundle', help='Show bundled script')
    bundle_parser.add_argument('task', help='Task ID')
    bundle_parser.add_argument('--node1-ip', help='Node1 IP address')
    bundle_parser.add_argument('--node2-ip', help='Node2 IP address')
    
    # test command
    test_parser = subparsers.add_parser('test', help='Run tests')
    
    args = parser.parse_args()
    
    if args.command == 'list':
        cmd_list(args)
    elif args.command == 'grade':
        cmd_grade(args)
    elif args.command == 'bundle':
        cmd_bundle(args)
    elif args.command == 'test':
        cmd_test(args)
    else:
        parser.print_help()


if __name__ == '__main__':
    main()
