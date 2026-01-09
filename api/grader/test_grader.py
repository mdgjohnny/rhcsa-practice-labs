#!/usr/bin/env python3
"""Tests for the grader module.

Run with: python -m pytest api/grader/test_grader.py -v
Or: python api/grader/test_grader.py
"""

import json
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock, patch, MagicMock

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from api.grader.bundler import TaskBundler, TaskMetadata
from api.grader.executor import LocalExecutor, RemoteExecutor, ExecutionResult
from api.grader.grader import Grader, TaskResult, CheckResult, GraderResult


class TestTaskMetadata(unittest.TestCase):
    """Test TaskMetadata extraction."""
    
    def test_extract_metadata(self):
        content = '''#!/usr/bin/env bash
# Task: Create user bob
# Title: Create User
# Category: users-groups
# Target: node1

check 'id bob' 'User exists' 'User not found'
'''
        metadata = TaskMetadata.from_content('task-100', content)
        
        self.assertEqual(metadata.id, 'task-100')
        self.assertEqual(metadata.title, 'Create User')
        self.assertEqual(metadata.category, 'users-groups')
        self.assertEqual(metadata.description, 'Create user bob')
        self.assertEqual(metadata.target, 'node1')
    
    def test_infer_target_from_description(self):
        content = '''#!/usr/bin/env bash
# Task: Configure something on node2
# Title: Node2 Task
# Category: test

check 'true' 'ok' 'fail'
'''
        metadata = TaskMetadata.from_content('task-test', content)
        self.assertEqual(metadata.target, 'node2')
    
    def test_infer_both_target(self):
        content = '''#!/usr/bin/env bash
# Task: Configure /etc/hosts so node1 can ping node2 and node2 can ping node1
# Title: Configure hosts
# Category: networking

check 'true' 'ok' 'fail'
'''
        metadata = TaskMetadata.from_content('task-test', content)
        self.assertEqual(metadata.target, 'both')


class TestTaskBundler(unittest.TestCase):
    """Test TaskBundler."""
    
    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.checks_dir = Path(self.temp_dir)
        
        # Create a test task
        task_content = '''#!/usr/bin/env bash
# Task: Test task
# Title: Test
# Category: test

check 'true' 'Check passed' 'Check failed'
'''
        (self.checks_dir / 'task-01.sh').write_text(task_content)
        
        # Create a second task
        task2 = '''#!/usr/bin/env bash
# Task: Second task
# Title: Task 2
# Category: networking
# Target: node2

check 'hostname' 'Got hostname' 'No hostname'
'''
        (self.checks_dir / 'task-02.sh').write_text(task2)
        
        self.bundler = TaskBundler(self.checks_dir)
    
    def tearDown(self):
        import shutil
        shutil.rmtree(self.temp_dir)
    
    def test_load_task(self):
        content = self.bundler.load_task('task-01')
        self.assertIsNotNone(content)
        self.assertIn('Test task', content)
    
    def test_load_task_without_prefix(self):
        content = self.bundler.load_task('01')
        self.assertIsNotNone(content)
        self.assertIn('Test task', content)
    
    def test_load_nonexistent_task(self):
        content = self.bundler.load_task('task-999')
        self.assertIsNone(content)
    
    def test_bundle_basic(self):
        script = self.bundler.bundle('task-01')
        self.assertIsNotNone(script)
        self.assertIn('#!/bin/bash', script)
        self.assertIn('check()', script)
        self.assertIn('Check passed', script)
    
    def test_bundle_with_env_vars(self):
        script = self.bundler.bundle('task-01', env_vars={'NODE1_IP': '10.0.0.1'})
        self.assertIn("NODE1_IP='10.0.0.1'", script)
    
    def test_bundle_second_task(self):
        script = self.bundler.bundle('task-02')
        self.assertIsNotNone(script)
        self.assertIn('hostname', script)
    
    def test_list_tasks(self):
        tasks = self.bundler.list_tasks()
        self.assertEqual(len(tasks), 2)
        self.assertEqual(tasks[0]['id'], 'task-01')
        self.assertEqual(tasks[1]['id'], 'task-02')


class TestLocalExecutor(unittest.TestCase):
    """Test LocalExecutor."""
    
    def test_execute_simple(self):
        executor = LocalExecutor()
        result = executor.execute('echo hello')
        self.assertTrue(result.success)
        self.assertIn('hello', result.stdout)
    
    def test_execute_failure(self):
        executor = LocalExecutor()
        result = executor.execute('exit 1')
        self.assertFalse(result.success)
        self.assertEqual(result.returncode, 1)
    
    def test_is_available(self):
        executor = LocalExecutor()
        self.assertTrue(executor.is_available())


class TestCheckFunctionOutput(unittest.TestCase):
    """Test that bundled scripts produce correct JSON output."""
    
    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.checks_dir = Path(self.temp_dir)
    
    def tearDown(self):
        import shutil
        shutil.rmtree(self.temp_dir)
    
    def test_check_produces_json(self):
        # Create task that always passes
        task = '''#!/usr/bin/env bash
check 'true' 'This passed' 'This failed' 5
'''
        (self.checks_dir / 'task-01.sh').write_text(task)
        
        bundler = TaskBundler(self.checks_dir)
        script = bundler.bundle('task-01')
        
        executor = LocalExecutor()
        result = executor.execute(script)
        
        self.assertTrue(result.success)
        
        # Parse JSON output
        for line in result.stdout.split('\n'):
            if line.strip().startswith('{'):
                data = json.loads(line)
                self.assertEqual(data['check'], 'This passed')
                self.assertTrue(data['passed'])
                self.assertEqual(data['points'], 5)
                break
        else:
            self.fail('No JSON output found')
    
    def test_check_failure_json(self):
        # Create task that always fails
        task = '''#!/usr/bin/env bash
check 'false' 'This passed' 'This failed' 10
'''
        (self.checks_dir / 'task-01.sh').write_text(task)
        
        bundler = TaskBundler(self.checks_dir)
        script = bundler.bundle('task-01')
        
        executor = LocalExecutor()
        result = executor.execute(script)
        
        # Script should still succeed (exit 0) even if check fails
        self.assertTrue(result.success)
        
        for line in result.stdout.split('\n'):
            if line.strip().startswith('{'):
                data = json.loads(line)
                self.assertEqual(data['check'], 'This failed')
                self.assertFalse(data['passed'])
                break
    
    def test_multiple_checks(self):
        task = '''#!/usr/bin/env bash
check 'true' 'Check 1 passed' 'Check 1 failed'
check 'false' 'Check 2 passed' 'Check 2 failed'
check 'true' 'Check 3 passed' 'Check 3 failed'
'''
        (self.checks_dir / 'task-01.sh').write_text(task)
        
        bundler = TaskBundler(self.checks_dir)
        script = bundler.bundle('task-01')
        
        executor = LocalExecutor()
        result = executor.execute(script)
        
        checks = []
        for line in result.stdout.split('\n'):
            if line.strip().startswith('{'):
                checks.append(json.loads(line))
        
        self.assertEqual(len(checks), 3)
        self.assertTrue(checks[0]['passed'])
        self.assertFalse(checks[1]['passed'])
        self.assertTrue(checks[2]['passed'])


class TestGrader(unittest.TestCase):
    """Test Grader class."""
    
    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.checks_dir = Path(self.temp_dir)
        
        # Create test tasks
        (self.checks_dir / 'task-01.sh').write_text('''#!/usr/bin/env bash
# Task: Test 1
# Category: cat1
check 'true' 'Pass' 'Fail'
''')
        
        (self.checks_dir / 'task-02.sh').write_text('''#!/usr/bin/env bash
# Task: Test 2
# Category: cat1
check 'false' 'Pass' 'Fail'
''')
        
        (self.checks_dir / 'task-03.sh').write_text('''#!/usr/bin/env bash
# Task: Test 3
# Category: cat2
check 'true' 'Pass 1' 'Fail 1'
check 'true' 'Pass 2' 'Fail 2'
''')
        
        self.grader = Grader(self.checks_dir)
        self.grader.add_executor('default', LocalExecutor())
    
    def tearDown(self):
        import shutil
        shutil.rmtree(self.temp_dir)
    
    def test_evaluate_passing_task(self):
        result = self.grader.evaluate_task('task-01')
        
        self.assertEqual(result.task_id, 'task-01')
        self.assertTrue(result.passed)
        self.assertEqual(len(result.checks), 1)
        self.assertEqual(result.points_earned, 10)
        self.assertEqual(result.points_possible, 10)
    
    def test_evaluate_failing_task(self):
        result = self.grader.evaluate_task('task-02')
        
        self.assertFalse(result.passed)
        self.assertEqual(result.points_earned, 0)
        self.assertEqual(result.points_possible, 10)
    
    def test_evaluate_multi_check_task(self):
        result = self.grader.evaluate_task('task-03')
        
        self.assertTrue(result.passed)
        self.assertEqual(len(result.checks), 2)
        self.assertEqual(result.points_earned, 20)
        self.assertEqual(result.points_possible, 20)
    
    def test_evaluate_nonexistent_task(self):
        result = self.grader.evaluate_task('task-999')
        
        self.assertFalse(result.passed)
        self.assertIsNotNone(result.error)
    
    def test_grade_all_tasks(self):
        result = self.grader.grade()
        
        self.assertEqual(len(result.task_results), 3)
        self.assertEqual(result.total, 40)  # 10 + 10 + 20
        self.assertEqual(result.score, 30)  # 10 + 0 + 20
        self.assertTrue(result.passed)  # 30/40 = 75% >= 70%
    
    def test_grade_specific_tasks(self):
        result = self.grader.grade(['task-01', 'task-03'])
        
        self.assertEqual(len(result.task_results), 2)
        self.assertEqual(result.score, 30)
        self.assertEqual(result.total, 30)
        self.assertTrue(result.passed)  # 100%
    
    def test_categories_aggregated(self):
        result = self.grader.grade()
        
        self.assertIn('cat1', result.categories)
        self.assertIn('cat2', result.categories)
        self.assertEqual(result.categories['cat1']['possible'], 20)
        self.assertEqual(result.categories['cat1']['earned'], 10)
        self.assertEqual(result.categories['cat2']['possible'], 20)
        self.assertEqual(result.categories['cat2']['earned'], 20)
    
    def test_result_to_dict(self):
        result = self.grader.grade(['task-01'])
        d = result.to_dict()
        
        self.assertIn('timestamp', d)
        self.assertIn('score', d)
        self.assertIn('total', d)
        self.assertIn('passed', d)
        self.assertIn('checks', d)
        self.assertIn('categories', d)
        self.assertEqual(d['passing_threshold'], 70)


class TestGraderResultSerialization(unittest.TestCase):
    """Test result serialization for API compatibility."""
    
    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.checks_dir = Path(self.temp_dir)
        
        (self.checks_dir / 'task-01.sh').write_text('''#!/usr/bin/env bash
# Task: Test
# Category: cat1
check 'true' 'Pass' 'Fail' 10
''')
    
    def tearDown(self):
        import shutil
        shutil.rmtree(self.temp_dir)
    
    def test_result_has_required_fields(self):
        """API response should have all required fields."""
        grader = Grader(self.checks_dir)
        grader.add_executor('default', LocalExecutor())
        
        result = grader.grade(['task-01'])
        d = result.to_dict()
        
        required = ['timestamp', 'score', 'total', 'passed', 'passing_threshold', 'categories', 'checks']
        for field in required:
            self.assertIn(field, d, f"Missing required field: {field}")
    
    def test_checks_have_required_fields(self):
        """Each check should have required fields."""
        grader = Grader(self.checks_dir)
        grader.add_executor('default', LocalExecutor())
        
        result = grader.grade(['task-01'])
        d = result.to_dict()
        
        self.assertGreater(len(d['checks']), 0)
        check = d['checks'][0]
        
        required = ['task', 'category', 'check', 'passed', 'points']
        for field in required:
            self.assertIn(field, check, f"Check missing field: {field}")
    
    def test_categories_aggregated(self):
        """Categories should have earned and possible."""
        grader = Grader(self.checks_dir)
        grader.add_executor('default', LocalExecutor())
        
        result = grader.grade(['task-01'])
        d = result.to_dict()
        
        self.assertIn('cat1', d['categories'])
        cat = d['categories']['cat1']
        self.assertIn('earned', cat)
        self.assertIn('possible', cat)


class TestRealTasks(unittest.TestCase):
    """Test with actual task files from checks/ directory."""
    
    @classmethod
    def setUpClass(cls):
        # Find the actual checks directory
        cls.checks_dir = Path(__file__).parent.parent.parent / 'checks'
        if not cls.checks_dir.exists():
            raise unittest.SkipTest('checks/ directory not found')
    
    def test_bundle_task_100(self):
        """Test bundling task-100 (create user bob)."""
        bundler = TaskBundler(self.checks_dir)
        script = bundler.bundle('task-100')
        
        self.assertIsNotNone(script)
        self.assertIn('id bob', script)
        self.assertIn('check', script)
    
    def test_bundle_task_03(self):
        """Test bundling task-03 (hostname check)."""
        bundler = TaskBundler(self.checks_dir)
        script = bundler.bundle('task-03')
        
        self.assertIsNotNone(script)
        self.assertIn('hostname', script)
    
    def test_bundle_task_07(self):
        """Test bundling task-07 (has variable assignment before check)."""
        bundler = TaskBundler(self.checks_dir)
        script = bundler.bundle('task-07')
        
        self.assertIsNotNone(script)
        self.assertIn('TIMEZONE=', script)
        self.assertIn('timedatectl', script)
    
    def test_list_all_tasks(self):
        bundler = TaskBundler(self.checks_dir)
        tasks = bundler.list_tasks()
        
        self.assertGreater(len(tasks), 100)
        
        # Check required fields
        for task in tasks:
            self.assertIn('id', task)
            self.assertIn('category', task)
            self.assertIn('target', task)


class TestVariableTasks(unittest.TestCase):
    """Test tasks with variable assignments before check()."""
    
    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.checks_dir = Path(self.temp_dir)
    
    def tearDown(self):
        import shutil
        shutil.rmtree(self.temp_dir)
    
    def test_variable_in_check(self):
        """Variables assigned before check() should be available."""
        task = '''#!/usr/bin/env bash
EXPECTED="hello"
ACTUAL="hello"
check '[[ "$ACTUAL" == "$EXPECTED" ]]' 'Values match' 'Values differ'
'''
        (self.checks_dir / 'task-01.sh').write_text(task)
        
        bundler = TaskBundler(self.checks_dir)
        grader = Grader(self.checks_dir)
        grader.add_executor('default', LocalExecutor())
        
        result = grader.evaluate_task('task-01')
        self.assertTrue(result.passed)
        self.assertEqual(result.checks[0].check, 'Values match')
    
    def test_command_substitution(self):
        """Command substitution in variables should work."""
        task = '''#!/usr/bin/env bash
HOSTNAME=$(hostname)
check '[[ -n "$HOSTNAME" ]]' 'Got hostname' 'No hostname'
'''
        (self.checks_dir / 'task-01.sh').write_text(task)
        
        grader = Grader(self.checks_dir)
        grader.add_executor('default', LocalExecutor())
        
        result = grader.evaluate_task('task-01')
        self.assertTrue(result.passed)
    
    def test_complex_condition(self):
        """Complex bash conditions should work."""
        task = '''#!/usr/bin/env bash
check '[[ -d /tmp && -r /tmp ]]' '/tmp is dir and readable' '/tmp check failed'
'''
        (self.checks_dir / 'task-01.sh').write_text(task)
        
        grader = Grader(self.checks_dir)
        grader.add_executor('default', LocalExecutor())
        
        result = grader.evaluate_task('task-01')
        self.assertTrue(result.passed)


class TestSpecialCharacters(unittest.TestCase):
    """Test handling of special characters in check messages."""
    
    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.checks_dir = Path(self.temp_dir)
    
    def tearDown(self):
        import shutil
        shutil.rmtree(self.temp_dir)
    
    def test_quotes_in_message(self):
        """Messages with quotes should be properly escaped."""
        task = '''#!/usr/bin/env bash
check 'true' 'File "test.txt" exists' 'File not found'
'''
        (self.checks_dir / 'task-01.sh').write_text(task)
        
        grader = Grader(self.checks_dir)
        grader.add_executor('default', LocalExecutor())
        
        result = grader.evaluate_task('task-01')
        self.assertTrue(result.passed)
        # JSON should parse correctly
        self.assertIn('"test.txt"', result.checks[0].check)
    
    def test_path_in_message(self):
        """File paths with slashes in messages."""
        task = '''#!/usr/bin/env bash
check 'true' '/etc/passwd is readable' 'Cannot read /etc/passwd'
'''
        (self.checks_dir / 'task-01.sh').write_text(task)
        
        grader = Grader(self.checks_dir)
        grader.add_executor('default', LocalExecutor())
        
        result = grader.evaluate_task('task-01')
        self.assertTrue(result.passed)
        self.assertEqual(result.checks[0].check, '/etc/passwd is readable')


class TestEnvVarInjection(unittest.TestCase):
    """Test environment variable injection."""
    
    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.checks_dir = Path(self.temp_dir)
    
    def tearDown(self):
        import shutil
        shutil.rmtree(self.temp_dir)
    
    def test_env_vars_available(self):
        """Injected env vars should be available in script."""
        task = '''#!/usr/bin/env bash
check '[[ "$MY_VAR" == "test_value" ]]' 'Env var correct' 'Env var wrong'
'''
        (self.checks_dir / 'task-01.sh').write_text(task)
        
        grader = Grader(self.checks_dir)
        grader.add_executor('default', LocalExecutor())
        grader.set_env('MY_VAR', 'test_value')
        
        result = grader.evaluate_task('task-01')
        self.assertTrue(result.passed)
    
    def test_node_ip_injection(self):
        """NODE1_IP and NODE2_IP should be injectable."""
        task = '''#!/usr/bin/env bash
check '[[ "$NODE1_IP" == "10.0.0.1" ]]' 'Node1 IP correct' 'Node1 IP wrong'
check '[[ "$NODE2_IP" == "10.0.0.2" ]]' 'Node2 IP correct' 'Node2 IP wrong'
'''
        (self.checks_dir / 'task-01.sh').write_text(task)
        
        grader = Grader(self.checks_dir)
        grader.add_executor('default', LocalExecutor())
        grader.set_env('NODE1_IP', '10.0.0.1')
        grader.set_env('NODE2_IP', '10.0.0.2')
        
        result = grader.evaluate_task('task-01')
        self.assertTrue(result.passed)
        self.assertEqual(len(result.checks), 2)


def run_tests():
    """Run all tests."""
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    
    # Add all test cases
    suite.addTests(loader.loadTestsFromTestCase(TestTaskMetadata))
    suite.addTests(loader.loadTestsFromTestCase(TestTaskBundler))
    suite.addTests(loader.loadTestsFromTestCase(TestLocalExecutor))
    suite.addTests(loader.loadTestsFromTestCase(TestCheckFunctionOutput))
    suite.addTests(loader.loadTestsFromTestCase(TestGrader))
    suite.addTests(loader.loadTestsFromTestCase(TestRealTasks))
    suite.addTests(loader.loadTestsFromTestCase(TestGraderResultSerialization))
    suite.addTests(loader.loadTestsFromTestCase(TestVariableTasks))
    suite.addTests(loader.loadTestsFromTestCase(TestSpecialCharacters))
    suite.addTests(loader.loadTestsFromTestCase(TestEnvVarInjection))
    
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    return 0 if result.wasSuccessful() else 1


if __name__ == '__main__':
    sys.exit(run_tests())
