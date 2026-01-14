# Local VM Setup Guide

This guide explains how to run RHCSA Practice Labs with local VMs instead of cloud VMs.

## Option 1: Vagrant (Recommended)

Vagrant automatically provisions and configures VMs with all practice scenarios.

### Prerequisites

```bash
# Install Vagrant and libvirt (Linux)
sudo dnf install vagrant libvirt qemu-kvm virt-manager

# Or with VirtualBox (any OS)
# Download from virtualbox.org and vagrantup.com

# Install Vagrant plugins
vagrant plugin install vagrant-libvirt
vagrant plugin install vagrant-disksize
```

### Start VMs

```bash
cd rhcsa-practice-labs
vagrant up
```

This creates two VMs:
- **rhcsa1** (node1): 192.168.99.11 - Primary practice node with most scenarios
- **rhcsa2** (node2): 192.168.99.12 - Secondary node for multi-node tasks

Both VMs:
- User: root, Password: vagrant
- Auto-provisioned with practice scenarios
- SELinux enforcing, firewall enabled

### Configure App for Local VMs

Create `static_vms.json`:

```json
{
  "session_id": "local-session",
  "rhcsa1_ip": "192.168.99.11",
  "rhcsa2_ip": "192.168.99.12",
  "ssh_user": "root",
  "ssh_password": "vagrant"
}
```

Start the app:

```bash
source .venv/bin/activate
python api/app_socketio.py
```

Open http://localhost:8080

### VM Lifecycle

```bash
vagrant halt       # Stop VMs (preserves state)
vagrant up         # Start VMs
vagrant destroy    # Delete VMs completely
vagrant provision  # Re-run setup scripts
```

---

## Option 2: Manual VMs

If you have existing VMs or prefer manual setup.

### Requirements

- Rocky Linux 9, AlmaLinux 9, Oracle Linux 8/9, or RHEL 8/9
- Root SSH access
- 2GB+ RAM, 12GB+ disk recommended

### Setup Steps

1. **Start your VMs** (VMware, VirtualBox, libvirt, cloud, etc.)

2. **Run the setup script on each VM:**

   ```bash
   # On node1 (primary):
   curl -sSL https://raw.githubusercontent.com/mdgjohnny/rhcsa-practice-labs/main/scripts/setup-local-tasks.sh | sudo bash -s node1
   
   # On node2 (secondary, optional):
   curl -sSL https://raw.githubusercontent.com/mdgjohnny/rhcsa-practice-labs/main/scripts/setup-local-tasks.sh | sudo bash -s node2
   ```

   Or copy the script manually:

   ```bash
   scp scripts/setup-local-tasks.sh root@VM_IP:/tmp/
   ssh root@VM_IP 'bash /tmp/setup-local-tasks.sh node1'
   ```

3. **Create `static_vms.json`:**

   ```json
   {
     "session_id": "manual-vms",
     "rhcsa1_ip": "YOUR_VM1_IP",
     "rhcsa2_ip": "YOUR_VM2_IP",
     "ssh_user": "root",
     "ssh_password": "YOUR_PASSWORD"
   }
   ```

   Or with SSH key:

   ```json
   {
     "session_id": "manual-vms",
     "rhcsa1_ip": "YOUR_VM1_IP",
     "rhcsa2_ip": "YOUR_VM2_IP",
     "ssh_user": "root",
     "ssh_key_path": "/path/to/your/key"
   }
   ```

4. **Start the app:**

   ```bash
   python api/app_socketio.py
   ```

---

## What the Setup Script Creates

### On node1 (rhcsa1):

| Task | Scenario | What's Broken |
|------|----------|---------------|
| 197 | Apache reverse proxy | httpd_can_network_connect=off |
| 208 | Web file access | Wrong SELinux context (user_home_t) |
| 218 | UserDir access | httpd_enable_homedirs=off |
| 220 | FTP anonymous upload | ftpd_full_access=off |
| 51 | NFS write access | nfs_export_all_rw=off |
| 222 | SSH on port 2222 | Port not in SELinux policy |

### On both nodes:

- Practice disks: `/dev/loop0` through `/dev/loop5`
- Practice users: alice, bob, charlie (password: `password`)
- Practice groups: developers, sysadmins, dbadmins
- Directories: `/data/projects`, `/data/shared`, `/scripts`

---

## Re-running Setup

The setup script is idempotent - safe to run multiple times.

To force a fresh setup:

```bash
ssh root@VM_IP 'rm /root/.task-setup-complete && bash /path/to/setup-local-tasks.sh node1'
```

With Vagrant:

```bash
vagrant destroy -f && vagrant up
```

---

## Troubleshooting

### "Connection refused" in terminal

- Check VM is running: `vagrant status` or `ping VM_IP`
- Check SSH works: `ssh root@VM_IP`
- Check firewall allows SSH: `firewall-cmd --list-all`

### Tasks don't work as expected

- Verify setup completed: `ls /root/.task-setup-complete`
- Check setup log: `cat /var/log/task-setup.log`
- Re-run setup: `rm /root/.task-setup-complete && bash setup-local-tasks.sh node1`

### SELinux not enforcing

```bash
getenforce              # Should say "Enforcing"
sudo setenforce 1       # Enable temporarily
sudo grubby --update-kernel ALL --args selinux=1  # Enable permanently
```

### Practice disks not available

```bash
# Check loopback devices
losetup -a

# Manually setup if missing
for i in 0 1 2 3 4 5; do
    losetup /dev/loop$i /var/practice-disks/disk$i.img
done
```
