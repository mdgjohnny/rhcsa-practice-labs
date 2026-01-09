# RHCSA Practice Labs

## Project Overview

A SadServers-style web platform for RHCSA (Red Hat Certified System Administrator) exam practice. Users get a web terminal connected to real cloud VMs where they can practice Linux administration tasks.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Browser                                                        │
│  ┌─────────────────┐  ┌─────────────────────────────────────┐  │
│  │  Practice UI    │  │  xterm.js Terminal                  │  │
│  │  (tasks/grader) │  │  (WebSocket → SSH → VMs)            │  │
│  └─────────────────┘  └─────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Flask Backend (api/app_socketio.py)                            │
│  ├── REST API: /api/tasks, /api/grade, /api/sessions            │
│  ├── WebSocket: /terminal namespace (Flask-SocketIO)            │
│  └── Session Manager: Terraform wrapper for VM lifecycle        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Oracle Cloud Infrastructure (Free Tier)                        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  VCN (10.0.0.0/16) + Public Subnet                      │   │
│  │  ┌──────────────┐      ┌──────────────┐                 │   │
│  │  │   rhcsa1     │      │   rhcsa2     │                 │   │
│  │  │  (node1)     │◄────►│  (node2)     │                 │   │
│  │  │ Oracle Linux │      │ Oracle Linux │                 │   │
│  │  └──────────────┘      └──────────────┘                 │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Current State (as of Jan 2026)

### ✅ Completed

1. **OCI Infrastructure (Terraform)** - `infra/`
   - Full working Terraform config for Oracle Cloud
   - Creates: VCN, subnet, security lists, internet gateway, 2 compute instances
   - Oracle Linux 8 (RHEL-compatible, free tier)
   - Auto-generated SSH keys per session
   - Cloud-init for hostname setup (`rhcsa1`, `rhcsa2`)
   - Credentials configured in `~/.oci/` and `infra/terraform.tfvars`
   - **Tested and working** - VMs provision in ~40 seconds

2. **Session Management** - `api/oci_manager/`
   - `session_manager.py`: SQLite-backed session lifecycle
   - `terraform_wrapper.py`: Python wrapper for Terraform CLI
   - Session states: `pending` → `provisioning` → `ready` → `terminated`
   - SSH keys stored in DB (never exposed to browser)
   - 30-minute default timeout

3. **API Endpoints** - `api/app_socketio.py`
   - `POST /api/sessions` - Create new session
   - `GET /api/sessions/<id>` - Get session details
   - `POST /api/sessions/<id>/provision` - Start VM provisioning
   - `DELETE /api/sessions/<id>` - Destroy session & VMs
   - `GET /api/sessions/active` - Get current active session

4. **Web Terminal Foundation** - `api/terminal.py`, `static/terminal-test.html`
   - xterm.js frontend terminal emulator
   - Flask-SocketIO WebSocket backend
   - Paramiko SSH bridge
   - Session-based auth (connects via session_id, not raw keys)

5. **Original Practice System** (pre-existing)
   - 150+ RHCSA tasks in `checks/task-*.sh`
   - Grader script `exam-grader.sh`
   - Flask API in `api/app.py`
   - Web UI in `static/index.html`

### ⚠️ Known Issues

1. **WebSocket Terminal Instability**
   - The `start_session_terminal` event sometimes doesn't reach the handler
   - Connections drop after ~25 seconds (ping timeout)
   - Likely cause: Flask's dev server + threading mode not ideal for WebSocket
   - **Fix needed**: Use production WSGI server (gunicorn + eventlet/gevent) or debug further

### 🔲 TODO

1. **Fix WebSocket Terminal** (HIGH PRIORITY)
   - Debug why `start_session_terminal` events aren't received
   - Consider: gunicorn with eventlet worker, or switch to polling fallback
   - Test with: `gunicorn -k eventlet -w 1 api.app_socketio:app`

2. **Integrate Terminal into Main UI**
   - Add split-pane view to `static/index.html`: tasks on left, terminal on right
   - Session controls in header (create/destroy/time remaining)
   - Tab switching between node1/node2

3. **Connect Grader to Cloud VMs**
   - Currently grader uses local `config` file for VM IPs
   - Need to update to use active session's IPs
   - Modify `api/app.py` grade endpoints to inject session IPs

4. **Background Session Cleanup**
   - Add background worker/cron to terminate expired sessions
   - `session_manager.cleanup_expired_sessions()` exists but isn't called

5. **Production Hardening**
   - Proper WSGI server (gunicorn)
   - Rate limiting on session creation
   - Max 1 active session per user
   - Secure session token handling

## Key Files

```
rhcsa-practice-labs/
├── api/
│   ├── app.py              # Original Flask API (tasks, grading)
│   ├── app_socketio.py     # Extended API with WebSocket + sessions
│   ├── terminal.py         # WebSocket terminal handler
│   └── oci_manager/        # OCI/Terraform session management
│       ├── session_manager.py
│       └── terraform_wrapper.py
├── infra/                  # Terraform configs
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars    # OCI credentials (gitignored)
├── static/
│   ├── index.html          # Main practice UI
│   └── terminal-test.html  # Terminal test page
├── checks/                 # 150+ task verification scripts
└── exam-grader.sh          # CLI grader
```

## Running Locally

```bash
cd rhcsa-practice-labs
source .venv/bin/activate

# Start the app with WebSocket support
python api/app_socketio.py

# Or original app without terminal/sessions
python api/app.py
```

## Testing Sessions Manually

```bash
# Create session
curl -X POST -H "Content-Type: application/json" \
  http://localhost:8080/api/sessions -d '{}'

# Provision VMs (takes 2-5 min)
curl -X POST http://localhost:8080/api/sessions/<session_id>/provision

# Check status
curl http://localhost:8080/api/sessions/<session_id>

# Destroy when done
curl -X DELETE http://localhost:8080/api/sessions/<session_id>
```

## OCI Free Tier Limits

- 2x VM.Standard.E2.1.Micro (1 OCPU, 1GB RAM each)
- Region: sa-saopaulo-1
- Credentials in `~/.oci/config`

## Production Notes

- Remove `/api/mock-stats` endpoint before production
- WebSocket needs production WSGI server
- Consider Redis for session state in multi-worker setup

## Commit Messages

- Do not include Claude Code attribution in commit messages
