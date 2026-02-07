# Architecture Documentation

This document describes the architecture of RHCSA Practice Labs.

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                       Browser (SPA)                          │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐│
│  │ views.js │ │ tasks.js │ │terminal.js│ │ flashcards.js   ││
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────────┬─────────┘│
│       │            │            │                │           │
│       └────────────┴────────────┴────────────────┘           │
│                            │                                 │
└────────────────────────────┼─────────────────────────────────┘
                             │ HTTP/WebSocket
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                    Flask Backend (api/)                      │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                     app.py                            │   │
│  │  • REST API endpoints (/api/v2/*)                    │   │
│  │  • Result storage (SQLite)                           │   │
│  │  • Flashcard spaced repetition                       │   │
│  └───────────────────────┬──────────────────────────────┘   │
│                          │                                   │
│  ┌───────────────────────┼──────────────────────────────┐   │
│  │     app_socketio.py   │                               │   │
│  │  • WebSocket terminal │                               │   │
│  │  • Cloud session mgmt │                               │   │
│  └───────────────────────┴──────────────────────────────┘   │
│            │                          │                      │
│            ▼                          ▼                      │
│  ┌─────────────────┐     ┌────────────────────────────────┐ │
│  │    grader/      │     │     oci_manager/               │ │
│  │  • Task parsing │     │  • Terraform for OCI           │ │
│  │  • SSH grading  │     │  • Session lifecycle           │ │
│  └─────────────────┘     └────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                             │
                             │ SSH
                             ▼
               ┌─────────────────────────┐
               │     Practice VMs        │
               │  ┌─────────┐ ┌─────────┐│
               │  │ rhcsa1  │ │ rhcsa2  ││
               │  │ (node1) │ │ (node2) ││
               │  └─────────┘ └─────────┘│
               └─────────────────────────┘
```

## Components

### Frontend (static/)

Single-page application with modular JavaScript:

| Module | Purpose |
|--------|---------|
| `state.js` | Global state variables |
| `utils.js` | Toast notifications, formatting |
| `views.js` | View switching, session persistence |
| `config.js` | VM configuration management |
| `cloud.js` | OCI session lifecycle |
| `tasks.js` | Task loading, filtering |
| `practice.js` | Practice/exam modes, grading |
| `stats.js` | Statistics display |
| `terminal.js` | xterm.js integration |
| `flashcards.js` | Spaced repetition system |
| `app.js` | Initialization |

### Backend (api/)

Flask application with:

**Core Files:**
- `app.py` - REST API, results storage, flashcards
- `app_socketio.py` - WebSocket server with terminal support
- `config.py` - Centralized configuration
- `exceptions.py` - Custom exception hierarchy
- `terminal.py` - SSH terminal handler

**Grader Module (api/grader/):**
- `grader.py` - Core grading logic
- `executor.py` - SSH command execution
- `bundler.py` - Task bundling/unbundling
- `api_integration.py` - Service layer for Flask

**OCI Module (api/oci_manager/):**
- `session_manager.py` - Cloud session lifecycle
- `terraform_wrapper.py` - Terraform integration

### Data Storage

**SQLite Databases:**
- `results.db` - Practice/exam results, flashcard progress
- `sessions.db` - Cloud session state

**Configuration:**
- `config` - VM IP addresses, hostnames
- `static_vms.json` - Pre-configured static VMs

## API Endpoints

### v2 API

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v2/tasks` | GET | List all tasks |
| `/api/v2/tasks/<id>` | GET | Get single task |
| `/api/v2/grade/<id>` | POST | Grade single task |
| `/api/v2/grade` | POST | Grade multiple tasks |

### Results API

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/results` | GET | List results (paginated) |
| `/api/results` | POST | Save new result |
| `/api/results/<id>` | DELETE | Delete result |
| `/api/results` | DELETE | Clear all results |
| `/api/stats` | GET | Get aggregated stats |

### Flashcard API

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/flashcards/progress` | GET | Get all progress |
| `/api/flashcards/review` | POST | Record review |
| `/api/flashcards/stats` | GET | Get statistics |
| `/api/flashcards/due` | GET | Get due cards |
| `/api/flashcards/reset` | POST | Reset progress |

## Task System

### Task Definition

Tasks are defined in YAML files (`tasks/`) with grading scripts in `checks/`:

```yaml
# tasks/task-01.yaml
id: task-01
title: Configure Secondary IP
category: networking
target: node1
points: 20
description: |
  Add a secondary IP address...
```

```bash
# checks/task-01.sh
#!/usr/bin/env bash
check '[[ $(ip -4 addr show) =~ "10.0.99.1" ]]' \
    "Secondary IP configured" \
    "Secondary IP not found"
```

### Grading Flow

1. Frontend calls `/api/v2/grade/<task_id>`
2. Grader service loads task and check script
3. SSH connection to target VM
4. Execute check script, parse results
5. Return pass/fail with details

## Security Considerations

- Root password stored in local config file only
- SSH keys encrypted at rest (when using cloud sessions)
- Input validation on all config values
- No shell command injection via config

## Configuration

Environment variables (prefix: `RHCSA_`):

| Variable | Default | Description |
|----------|---------|-------------|
| `RHCSA_PORT` | 8080 | Server port |
| `RHCSA_DEBUG` | false | Debug mode |
| `RHCSA_LOG_LEVEL` | INFO | Logging level |
| `RHCSA_SSH_TIMEOUT` | 30 | SSH timeout (seconds) |
