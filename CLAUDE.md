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

### ✅ Recently Completed (Jan 2026)

1. **Fix WebSocket Terminal** ✅
   - Switched from `threading` to `eventlet` async mode in SocketIO
   - Added eventlet monkey-patching at module start
   - Replaced threading.Thread with eventlet.spawn for SSH reader
   - Terminal connections now stable, no timeout issues

2. **Integrate Terminal into Main UI** ✅
   - Added split-pane layout: task panel left, terminal panel right
   - Added node tabs (rhcsa1/rhcsa2) for switching between VMs
   - Added cloud session management in Settings page
   - Terminal connects automatically when cloud session is ready

### ✅ Recently Completed (Jan 2026)

3. **End-to-End Grading** ✅
   - Grader now connects to cloud VMs automatically
   - `get_grading_env()` injects session IPs from sessions.db
   - `exam-grader.sh` supports SSH_KEY_FILE + SSH_USER for OCI auth
   - Remote checks executed via SSH with sudo
   - Tested: task-100 (create user bob) completed and graded successfully

### 🔲 TODO

1. **Modular Cloud VM Setup / User Onboarding**
   - Make the cloud VM integration self-service for GitHub users
   - Don't expose/commit any credentials - keep `terraform.tfvars` gitignored
   - Create clear onboarding documentation:
     - How to set up OCI free tier account
     - How to configure `~/.oci/config` and API keys
     - How to create `infra/terraform.tfvars` with user's own credentials
     - Alternative: support other cloud providers (AWS, GCP, local VMs)
   - Add setup wizard or validation script to check prerequisites
   - Consider environment variable support as alternative to tfvars file

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
