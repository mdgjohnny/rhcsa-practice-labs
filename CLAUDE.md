# RHCSA Practice Labs

## Project Overview

A SadServers-style web platform for RHCSA (Red Hat Certified System Administrator) exam practice. Users get a web terminal connected to real cloud VMs where they can practice Linux administration tasks.

**Live:** https://sun-indigo.exe.xyz:8080/

## Current State (Jan 12, 2026)

### ✅ Working Features

1. **247 Practice Tasks** - All with verification criteria shown upfront
2. **Cloud VM Sessions** - OCI free tier, 2 VMs (rhcsa1/rhcsa2), ~2 min provision
3. **Web Terminal** - xterm.js + Flask-SocketIO + Paramiko SSH bridge
4. **Python Grader** - Bundles scripts, runs on VMs via SSH, detailed results
5. **Challenge Mode** - Custom time (5-240 min) and task count (1-50)
6. **Practice Mode** - No timer, select specific tasks or categories
7. **Exam Mode** - 3 hours, 15-20 random tasks

### Task Quality

- Descriptions describe GOALS, not methods (no answer giveaways)
- Verification criteria shown before attempting each task
- Detailed pass/fail feedback after grading
- Points breakdown per check (typically 10 pts each)

## Architecture

```
Browser (xterm.js) → Flask-SocketIO → Paramiko SSH → OCI VMs (rhcsa1/rhcsa2)
                  → REST API → Python Grader → SSH → VMs
```

## Key Files

```
rhcsa-practice-labs/
├── api/
│   ├── app_socketio.py      # Main app with WebSocket terminal
│   ├── grader/              # Python grader module
│   │   ├── bundler.py       # Task script bundling + check extraction
│   │   ├── executor.py      # Local/Remote SSH execution
│   │   ├── grader.py        # Grading orchestration
│   │   └── api_integration.py
│   └── oci_manager/         # Session/Terraform management
├── checks/                  # 141 task-*.sh verification scripts
├── static/index.html        # Complete UI (single file)
├── infra/                   # Terraform for OCI
└── sessions.db              # SQLite session storage
```

## Running

```bash
cd /home/exedev/rhcsa-practice-labs
source .venv/bin/activate
python api/app_socketio.py   # Port 8080
```

## CLI Commands

```bash
python -m api.grader.cli list              # List all tasks
python -m api.grader.cli grade task-01     # Grade single task
python -m api.grader.cli bundle task-01    # Show bundled script
```

## Task File Format

```bash
#!/usr/bin/env bash
# Task: Description of what to accomplish (no hints!)
# Title: Short Title
# Category: networking|users-groups|file-systems|security|...
# Target: node1|node2|both

check 'test command' \
    "Pass message" \
    "Fail message"
```

## Session Management

- Sessions auto-expire after 30 minutes
- Max 1 active session enforced
- VMs destroyed on session end
- SSH keys stored in sessions.db (never exposed to browser)

## Recent Fixes (Jan 12)

1. Removed answer hints from task descriptions
2. Added verification criteria display
3. Fixed secondary IP persistence checks
4. Added Challenge mode with presets
5. Improved grading feedback (shows each check)

## Git

Branch: `dev-antigravity` (ahead of origin)

## Recent Updates (Jan 12 - Later)

### Task Expansion (141 → 247 tasks)
Added comprehensive coverage for all RHCSA objectives:

- **Shell Scripts (18 tasks)**: if/test, for/while loops, $1/$@, command substitution
- **SELinux (43 tasks)**: modes, contexts, ports, booleans, troubleshooting  
- **Containers (37 tasks)**: pull, inspect, skopeo, Containerfile, volumes
- **Process Management**: kill, nice, renice
- **rd.break Simulation**: 5 tasks testing recovery knowledge without boot access

### Objective Coverage
Every RHCSA objective bullet point now has 5+ tasks where possible.
See coverage report in conversation for detailed matrix.

### rd.break Workaround
Since cloud VMs can't interrupt boot:
- Task 255: Password reset via sudo user
- Task 256-259: Document/script the recovery procedure

## OCI Free Tier Limitations (Important!)

**1GB RAM micro instances cannot reliably run `dnf install`:**
- DNF metadata download needs ~500MB+ memory
- Package installation causes swap thrashing
- VM becomes unresponsive or crashes
- Even small packages like `autofs` fail to install

**Workaround Options:**
1. Use pre-installed packages only (nfs-utils, at, tuned, chrony, tar, vim)
2. Use larger ARM A1.Flex instances (4 OCPUs, 24GB free tier total)
3. For package installation tasks, users need local VMs or larger cloud instances

**Tasks Affected:**
- Container tasks (need podman/skopeo/buildah)
- Autofs tasks (need autofs package)  
- httpd/vsftpd tasks
- SELinux troubleshooting (setroubleshoot-server)

**Recommendation:** 
For full RHCSA practice, use VirtualBox/libvirt locally with 2GB+ RAM per VM.
Cloud micro instances are suitable only for tasks using pre-installed packages.
