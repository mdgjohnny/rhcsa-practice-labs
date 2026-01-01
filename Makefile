.PHONY: install run dev clean help

VENV := .venv
PYTHON := $(VENV)/bin/python
PIP := $(VENV)/bin/pip
FLASK := $(VENV)/bin/flask

help:
	@echo "RHCSA Practice Labs"
	@echo ""
	@echo "Usage:"
	@echo "  make install    Install dependencies"
	@echo "  make run        Run the web interface"
	@echo "  make dev        Run in development mode"
	@echo "  make clean      Remove virtual environment and cache"
	@echo ""
	@echo "Quick start:"
	@echo "  1. cp config.example config"
	@echo "  2. Edit config with your VM IPs"
	@echo "  3. make install && make run"
	@echo "  4. Open http://localhost:5000"

$(VENV)/bin/activate:
	python3 -m venv $(VENV)
	$(PIP) install --upgrade pip

install: $(VENV)/bin/activate
	$(PIP) install -r api/requirements.txt
	@echo ""
	@echo "Installation complete!"
	@echo "Run 'make run' to start the web interface"

run: $(VENV)/bin/activate
	@if [ ! -f config ]; then \
		echo "Warning: config file not found. Copy config.example to config first."; \
		cp config.example config; \
	fi
	@echo "Starting RHCSA Practice Labs..."
	@echo "Open http://localhost:5000 in your browser"
	@echo ""
	$(PYTHON) api/app.py

dev: $(VENV)/bin/activate
	FLASK_DEBUG=1 $(PYTHON) api/app.py

clean:
	rm -rf $(VENV) __pycache__ api/__pycache__ results.db
	@echo "Cleaned up"

# CLI shortcuts
list-tasks:
	./exam-grader.sh --list-tasks

dry-run:
	./exam-grader.sh --dry-run

test:
	./exam-grader.sh --skip-reboot
