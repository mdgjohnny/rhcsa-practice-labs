# Handover Summary - RHCSA Practice Labs

## Final Status: 130/158 passing (82.2%)

**Session:** sess-acac55e7ef48
- Node1: 144.22.170.134
- Node2: 152.70.219.53
- SSH Key: /tmp/session_key
- Extended until: ~23:48 UTC

## Achievements

### Pass Rate Progress:
- Started session: 0/158
- After basic setup: ~80/158
- After packages + containers: ~115/158
- After NFS + SSH keys: **130/158 (82.2%)**

### What Works:
- **Users/Groups:** 50+ tasks
- **File Permissions:** ACLs, setgid, sticky bit
- **LVM:** Both nodes configured
- **Containers:** httpd, mariadb, alpine, ubi8, ubi9
- **NFS:** Server + client mounts
- **SSH:** Key-based auth between nodes
- **SELinux:** Contexts, booleans, permissive mode
- **Services:** httpd, vsftpd, nfs-server, autofs, mariadb

## Remaining 28 Tasks (17.8%)

### Impossible/Very Risky (9 tasks):
| Task | Reason |
|------|--------|
| task-01, task-02, task-138 | Secondary IP (breaks SSH) |
| task-74 | SSH port change (risky) |
| task-89 | Install VM (nested virt) |
| task-92 | Reset root password (console) |
| task-ssh | Test task |
| task-81, task-82 | Bidirectional SSH complex |

### Conflicting Tasks (11 tasks):
| Task | Conflict |
|------|----------|
| task-27, task-33, task-34, task-121, task-148 | Different VG on same loop device |
| task-111, task-134, task-150 | LVM extend/swap conflicts |
| task-126, task-29, task-136 | Different Apache DocumentRoot |
| task-130, task-144 | Password policy 90 vs 120 days |
| task-56 | Tuned profile throughput vs powersave |

### Need More Work (8 tasks):
| Task | Requirement |
|------|-------------|
| task-63 | Development Tools group (slow install) |
| task-99 | Stratis (stratisd not installed) |
| task-105, task-147 | Autofs complex config |

## Bug Fixes Applied This Session:
- task-30, task-149: Permission check using wrong string index for 4-digit modes (2770)
- task-51: SELinux boolean regex
- task-68, task-76: Container service file checks

## Commands

```bash
# SSH
ssh -i /tmp/session_key opc@144.22.170.134  # node1
ssh -i /tmp/session_key opc@152.70.219.53   # node2

# Grade
source .venv/bin/activate
python -m api.grader.cli grade task-XX

# Count passing
passed=0; for t in $(python -m api.grader.cli list | awk '{print $1}' | grep task-); do
  [[ $(python -m api.grader.cli grade $t 2>/dev/null | grep "^Passed:" | awk '{print $2}') == "YES" ]] && ((passed++))
done; echo "Passed: $passed/158"
```

## Key Learnings

1. **Containers work on 1GB RAM** with extra swap
2. **Tasks can conflict** - same device, different configs
3. **NFS needs firewall ports** (nfs, mountd, rpc-bind)
4. **Permission checks need to handle setgid** (4-digit modes)
5. **SSH key setup is straightforward** once users exist on both nodes

## Recommendations

1. **Add more loop devices** in cloud-init for parallel LVM tasks
2. **Pre-install packages** (podman, httpd, nfs-utils, autofs, stratisd)
3. **Mark conflicting tasks** in UI so users know they're mutually exclusive
4. **Consider task dependencies** - some tasks build on others
