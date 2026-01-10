# Handover Summary - RHCSA Practice Labs

## Current Status: 76/158 tasks passing (48%)

**Session:** sess-8a1ffcc54cf2
- Node1: 144.22.216.182  
- Node2: 163.176.146.113
- SSH Key: /tmp/session_key

## PASSED TASKS (76)

| Task | Target | Category | Title |
|------|--------|----------|-------|
| task-03 | node1 | networking | Set System Hostname |
| task-04 | node2 | networking | Set System Hostname |
| task-05 | node1 | networking | Configure Host Resolution |
| task-05b | node2 | networking | Configure Host Resolution |
| task-06 | node1 | security | Add SELinux HTTP Port |
| task-07 | node1 | deploy-maintain | Set System Timezone |
| task-09 | node1 | users-groups | Configure Skeleton Directory |
| task-10 | node1 | users-groups | Set Password Aging Policy |
| task-11 | node1 | users-groups | Create Users and Groups |
| task-12 | node1 | file-systems | Create Shared Directories with SetGID |
| task-13 | node1 | essential-tools | Find Files by Owner |
| task-14 | node1 | users-groups | Create Restricted User |
| task-15 | node1 | deploy-maintain | List Package Files |
| task-16 | node1 | deploy-maintain | Set Default Boot Target |
| task-16b | node2 | deploy-maintain | Set Default Boot Target |
| task-18 | node1 | essential-tools | Search Files with grep |
| task-19 | node1 | essential-tools | Customize Shell Prompt |
| task-21 | node1 | users-groups | Create Group with Members |
| task-23 | node1 | file-systems | Create Collaborative Directory |
| task-24 | node1 | users-groups | Create User with Attributes |
| task-25 | node1 | users-groups | Create Non-interactive User |
| task-26 | node1 | deploy-maintain | Schedule Cron Job |
| task-28 | node1 | local-storage | Create VFAT Logical Volume |
| task-30 | node1 | file-systems | Set Directory Group |
| task-31 | node1 | users-groups | Create Group with GID |
| task-32 | node1 | file-systems | Create Directory with Sticky Bit |
| task-38 | node2 | essential-tools | Create Hard Links |
| task-42 | node1 | users-groups | Create Group with Members |
| task-44 | node2 | security | Apply SELinux Contexts |
| task-45 | node2 | essential-tools | Find Recently Modified Files |
| task-46 | node2 | deploy-maintain | Configure atd Access |
| task-47 | node2 | operate-systems | Add Custom Log Message |
| task-53 | node2 | deploy-maintain | Set Bootloader Timeout |
| task-54 | node1 | deploy-maintain | Enable Boot Messages |
| task-55 | node2 | operate-systems | Apply Tuned Profile |
| task-62 | node1 | deploy-maintain | Configure Time Synchronization |
| task-80 | node1 | operate-systems | Disable Graphical Interface |
| task-90 | node1 | users-groups | Create System Users |
| task-93 | node1 | users-groups | Set Password and UID Defaults |
| task-95 | node1 | users-groups | Create Shared Directories |
| task-96 | node1 | file-systems | Create Volume Group and LV |
| task-97 | node1 | essential-tools | Find Files by Owner |
| task-98 | node1 | operate-systems | Schedule Cron Job |
| task-100 | node1 | users-groups | Create Restricted Shell User |
| task-106 | node1 | file-systems | Create VFAT Partition |
| task-107 | node1 | users-groups | Configure Skeleton Directory |
| task-108 | node1 | users-groups | Create Users with Group Membership |
| task-109 | node1 | users-groups | Create Shared Directories |
| task-110 | node1 | file-systems | Create Swap Partition |
| task-112 | node1 | essential-tools | Find Files by Owner |
| task-113 | node1 | users-groups | Create User with Custom UID |
| task-116 | node1 | users-groups | Set Password Complexity Policy |
| task-117 | node1 | users-groups | Create Users in Groups |
| task-118 | node1 | networking | Configure SSH Server |
| task-119 | node1 | networking | Enable Root SSH Login |
| task-120 | node1 | users-groups | Create Shared Group Directories |
| task-122 | node1 | users-groups | Configure Sudo Group |
| task-123 | node1 | operate-systems | Apply Tuned Performance Profile |
| task-124 | node1 | file-systems | Create LVM Swap |
| task-125 | node1 | users-groups | Create Directory Structure |
| task-129 | node1 | file-systems | Create Labeled Partition |
| task-131 | node1 | users-groups | Create Users with Custom UIDs |
| task-132 | node1 | users-groups | Create Shared Directories |
| task-133 | node1 | users-groups | Find SetUID Files |
| task-137 | node1 | users-groups | Grant Sudo Access |
| task-139 | node1 | networking | Set FQDN Hostname |
| task-140 | node1 | operate-systems | Set Boot Target |
| task-141 | node1 | security | Set SELinux Mode |
| task-142 | node1 | essential-tools | Search with grep |
| task-143 | node1 | essential-tools | Customize Shell Prompt |
| task-144 | node1 | users-groups | Create Users with Password Expiry |
| task-145 | node1 | users-groups | Create Group with Members |
| task-146 | node1 | users-groups | Create User with Specific UID |
| task-149 | node1 | users-groups | Set Directory Permissions |
| task-151 | node1 | essential-tools | Create Compressed Archive |
| task-153 | node1 | operate-systems | Configure atd Access |

## FAILED TASKS BY CATEGORY (82 total)

### 🚫 IMPOSSIBLE/BLOCKED (27 tasks)

**Container tasks (need 2GB+ RAM):** 16 tasks
- task-68, 69, 70, 71, 72, 73, 75, 76, 85, 102, 103, 115, 127, 128, 157, 158

**ISO/Repo tasks (no ISO available):** 3 tasks  
- task-08, 91, 147

**Secondary IP (would break SSH):** 3 tasks
- task-01, 02, 138

**Special requirements:** 5 tasks
- task-81, 82: Bidirectional SSH (complex multi-node)
- task-89: Install RHEL 9 VM (needs nested virt)
- task-92: Reset Root Password (needs console)
- task-ssh: Verify SSH Access (test task)

### ⚠️ INFRASTRUCTURE NEEDED (20 tasks)

**Package install (slow on 1GB):** 5 tasks
- task-29, 63, 101, 114, 126, 136 (httpd, vsftpd, package groups)

**NFS tasks (need inter-node setup):** 7 tasks
- task-17, 17b, 22, 86, 87, 104, 105

**LVM/Disk (loopbacks consumed):** 8 tasks
- task-27, 33, 34, 35, 36, 37, 111, 121, 134, 148, 150
- task-99, 135 (Stratis - needs stratisd)

### ✅ POTENTIALLY DOABLE (~35 tasks)

These could pass with proper task execution:

**Users/Groups:**
- task-20: Create Users with Expiry
- task-39: Create Group Directories  
- task-48: Configure Passwordless Sudo
- task-64: Lock User Account
- task-83: Create Users in Groups
- task-84: Configure Limited Sudo
- task-94: Create Users in Groups
- task-130: Configure Password Aging
- task-154: Log Custom Message
- task-155: Configure Passwordless Sudo
- task-156: Create User Script

**SELinux:**
- task-49: Apply SELinux Contexts
- task-50: Set SELinux File Type
- task-51: Toggle SELinux Boolean
- task-88: Fix Apache SELinux
- task-152: Apply SELinux Contexts

**System:**
- task-41: Create Gzip Archive
- task-43: Search Man Pages
- task-52: Enable Persistent Journaling
- task-56: Set Powersave Tuned Profile
- task-77: Set Environment Variable
- task-78: Redirect Output Streams
- task-79: Create Archive with Hard Link

**Security:**
- task-65, 65b: Configure Passwordless SSH
- task-66: Add Firewall UDP Port
- task-67: Add Firewall Service
- task-74: Configure SSH (node2)

## Quick Wins for Next Session

Execute these on node1 to get easy passes:
```bash
ssh -i /tmp/session_key opc@144.22.216.182 "sudo -i bash << 'EOF'
# task-20 - already done users, just check expiry
chage -E 2025-12-31 user10
chage -E 2025-12-31 user30

# task-39 - create directories
mkdir -p /groups/group1 /groups/group2

# task-41 - gzip archive
tar czf /tmp/etc-backup.tar.gz /etc 2>/dev/null

# task-51 - SELinux boolean
setsebool -P httpd_enable_homedirs on

# task-52 - persistent journal
mkdir -p /var/log/journal
systemctl restart systemd-journald

# task-64 - lock user
usermod -L user30

# task-66, task-67 - firewall
firewall-cmd --permanent --add-port=2022/udp
firewall-cmd --permanent --add-service=https
firewall-cmd --reload
EOF
"
```

## Commands Reference

```bash
# Start server
cd /home/exedev/rhcsa-practice-labs
source .venv/bin/activate  
python api/app_socketio.py &

# Grade tasks
python -m api.grader.cli grade task-XX
python -m api.grader.cli list

# SSH to nodes
ssh -i /tmp/session_key opc@144.22.216.182  # node1
ssh -i /tmp/session_key opc@163.176.146.113  # node2

# Destroy session when done
curl -X DELETE http://localhost:8080/api/sessions/sess-8a1ffcc54cf2
```

## Summary

- **76 tasks DONE** - mostly users, groups, permissions, basic system config
- **27 tasks IMPOSSIBLE** - containers, ISO, secondary IP
- **20 tasks need infrastructure** - packages, NFS, more loopbacks
- **~35 tasks DOABLE** - could reach ~100/158 (63%) with effort

The main blockers are:
1. 1GB RAM insufficient for containers
2. No ISO file for repo tasks
3. Loopback devices consumed by LVM tasks done earlier
4. Package installs timeout on limited bandwidth
