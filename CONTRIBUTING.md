# Contributing to RHCSA Practice Labs

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/mdgjohnny/rhcsa-practice-labs.git
   cd rhcsa-practice-labs
   ```

2. **Create a virtual environment**
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # Linux/macOS
   ```

3. **Install development dependencies**
   ```bash
   pip install -e ".[dev]"
   ```

4. **Run tests**
   ```bash
   pytest tests/ -v
   ```

## Project Structure

```
rhcsa-practice-labs/
├── api/                    # Flask backend
│   ├── app.py              # Main Flask application
│   ├── config.py           # Configuration management
│   ├── exceptions.py       # Custom exception hierarchy
│   ├── terminal.py         # WebSocket terminal handler
│   ├── grader/             # Task grading system
│   └── oci_manager/        # Oracle Cloud integration
├── static/                 # Frontend files
│   ├── index.html          # Main HTML (views only)
│   └── js/                 # JavaScript modules
├── tasks/                  # Task YAML definitions
├── checks/                 # Task grading scripts
├── tests/                  # Test files
└── docs/                   # Documentation
```

## Code Style

### Python

- Use **type hints** for all function parameters and return values
- Follow **PEP 8** style guidelines
- Use **ruff** for linting: `ruff check api/`
- Run **mypy** for type checking: `mypy api/ --ignore-missing-imports`

### JavaScript

- Use **JSDoc comments** for function documentation
- Keep functions in appropriate module files (`static/js/`)
- No global state outside of `state.js`

## Testing

- Write tests for all new functionality
- Tests are in `tests/` directory
- Use `pytest` fixtures from `tests/conftest.py`
- Run tests: `pytest tests/ -v`
- Check coverage: `pytest tests/ --cov=api`

## Submitting Changes

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Write tests for new functionality
   - Ensure all tests pass
   - Follow code style guidelines

3. **Commit your changes**
   ```bash
   git commit -m "Add feature: brief description"
   ```

4. **Push and create a pull request**
   ```bash
   git push origin feature/your-feature-name
   ```

## Adding New Tasks

1. Create a YAML file in `tasks/` with task metadata:
   ```yaml
   id: task-xxx
   title: Your Task Title
   category: category-name
   target: node1  # or node2
   description: |
     Your task description here.
   ```

2. Create a grading script in `checks/task-xxx.sh`:
   ```bash
   #!/usr/bin/env bash
   check '[[ condition ]]' "Success message" "Failure message"
   ```

3. Test the task locally with the grader

## Questions?

Open an issue on GitHub for questions or suggestions.
