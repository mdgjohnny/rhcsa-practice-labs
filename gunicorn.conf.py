# Gunicorn configuration for RHCSA Practice Labs
# Run with: gunicorn -c gunicorn.conf.py api.app_socketio:app

import os

# Server socket
bind = os.environ.get('BIND', '0.0.0.0:8080')
backlog = 2048

# Worker processes
# For eventlet, use 1 worker (async handles concurrency)
workers = 1
worker_class = 'eventlet'
worker_connections = 1000

# Timeout
timeout = 120
keepalive = 5

# Logging
accesslog = '-'
errorlog = '-'
loglevel = os.environ.get('LOG_LEVEL', 'info').lower()

# Process naming
proc_name = 'rhcsa-labs'

# Security
limit_request_line = 4096
limit_request_fields = 100
limit_request_field_size = 8190
