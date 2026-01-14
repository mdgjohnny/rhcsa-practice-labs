# VM Recovery Guide

## When VMs become unresponsive

If VMs stop responding (e.g., due to SELinux relabeling, OOM, preemption), follow these steps:

### Option 1: Wait and retry
- SELinux relabeling can take 15-20 minutes on first boot with `SELINUX=enforcing`
- Preempted instances may auto-restart
- Check with: `ssh -i ~/.ssh/rhcsa_practice_key opc@<IP> 'uptime'`

### Option 2: Recreate VMs via Terraform

```bash
cd ~/rhcsa-practice-labs/infra

# Destroy and recreate specific node
terraform destroy -target=oci_core_instance.node1 -auto-approve
terraform apply -auto-approve

# Wait for cloud-init to complete (2-3 minutes)
# Check with:
ssh -i ~/.ssh/rhcsa_practice_key opc@<NEW_IP> 'cat /root/.cloud-init-complete'
```

### Option 3: Reset session after VM recreation

After recreating VMs, the session database needs updating with new IPs:

```bash
cd ~/rhcsa-practice-labs
./scripts/reset-session.sh [session_id]
```

This script:
1. Gets new IPs from terraform output
2. Verifies SSH connectivity
3. Updates the session database with correct IPs and SSH key

### Common Issues

#### "No SSH key available for session"
The session in the database doesn't have the SSH key. Run:
```bash
./scripts/reset-session.sh
```

#### "error in libcrypto" when grading
SSH key format issue. The key needs to be stored correctly in the database.
Use Python to update (not sqlite3 shell - it mangles newlines):

```python
import sqlite3
with open('/home/exedev/.ssh/rhcsa_practice_key', 'r') as f:
    key = f.read()
conn = sqlite3.connect('sessions.db')
conn.execute("UPDATE sessions SET ssh_private_key = ? WHERE session_id = ?", (key, 'SESSION_ID'))
conn.commit()
```

#### SELinux broke the VM
Never delete `/etc/selinux/` directory! To recover:
1. Use OCI Console serial connection
2. Boot to rescue mode
3. Recreate `/etc/selinux/config` with `SELINUX=permissive` first
4. Or just destroy and recreate the VM

### Prevention

- **Always use `SELINUX=permissive` first** when re-enabling SELinux
- SELinux permissive/disabled tasks are on node2 to avoid breaking semanage
- Keep the SSH key file at `~/.ssh/rhcsa_practice_key` - never delete it
