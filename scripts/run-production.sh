#!/bin/bash
# Run RHCSA Practice Labs in production mode with gunicorn

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/.."

cd "$PROJECT_DIR"

# Activate virtual environment
if [ -d .venv ]; then
    source .venv/bin/activate
else
    echo "Error: .venv not found. Run: python3 -m venv .venv && pip install -r requirements.txt"
    exit 1
fi

# Set defaults
export BIND="${BIND:-0.0.0.0:8080}"
export LOG_LEVEL="${LOG_LEVEL:-info}"

echo "Starting RHCSA Practice Labs (production mode)"
echo "  Bind: $BIND"
echo "  Log level: $LOG_LEVEL"
echo ""

# Run with gunicorn
exec gunicorn \
    --config gunicorn.conf.py \
    --chdir "$PROJECT_DIR" \
    "api.app_socketio:app"
