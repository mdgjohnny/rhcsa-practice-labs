# Local VM Setup Guide

This guide explains how to run RHCSA Practice Labs with local VMs instead of cloud VMs.

## Option 1: Vagrant (Recommended)

Vagrant automatically provisions and configures VMs with all practice scenarios.

### Prerequisites

```bash
# Install Vagrant and libvirt (Linux)
sudo dnf install vagrant libvirt qemu-kvm virt-manager

# Install Vagrant plugins (Linux)
vagrant plugin install vagrant-libvirt
vagrant plugin install vagrant-disksize
```

> **On macOS?** libvirt is Linux-only. See the [macOS setup](#macos-setup)
> section below to pick the right provider for your Mac's chip. The
> `vagrant-disksize` plugin is still required regardless of platform.

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
  "node1_ip": "192.168.99.11",
  "node2_ip": "192.168.99.12",
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

### macOS Setup

The `generic/rocky9` box publishes prebuilt images for multiple providers, so
the box itself is not a blocker on macOS. But libvirt is Linux-only, so on a
Mac you must use a different provider — and **which provider works depends on
your Mac's chip.**

**First, confirm your chip.** Apple menu → About This Mac. Look for either
"Apple M1/M2/M3/M4" (Apple Silicon / ARM) or "Intel". This determines which
provider will actually work — the guidance below is split accordingly.

#### Apple Silicon Mac (M1/M2/M3/M4) — the common case today

**VirtualBox will NOT work here.** It is a type-2 hypervisor with no
instruction-set translation, so it cannot run x86_64 guest VMs on an ARM host.
Do not waste time installing it. Your options, in priority order:

**Option A — QEMU (free, slower).** This is the free path and it preserves the
normal Vagrantfile-driven workflow (no GUI, no manual VM setup). The
`generic/rocky9` box publishes a dedicated `qemu`/amd64 image, and the
`vagrant-qemu` plugin drives it:

```bash
brew install qemu
vagrant plugin install vagrant-qemu
vagrant plugin install vagrant-disksize
vagrant up --provider=qemu
```

Honest caveat: the box is an x86_64 (amd64) guest and your Mac is arm64, so
QEMU has to fully software-emulate the CPU (TCG) — there is no hardware
acceleration across differing architectures. It works, but expect it to feel
noticeably slower than the native KVM path on Linux or the commercial
Parallels/VMware paths. (No specific benchmark here — just plan for "usable but
not snappy.") The Vagrantfile already ships a `:qemu` provider block with the
`arch`/`machine`/`cpu`/`net_device` settings required to run the x86_64 guest
on an arm64 host, so no extra config is needed.

**Option B — Parallels Desktop or VMware Fusion (commercial, faster).** If the
emulation speed is a problem and licensing/policy allows, these commercial
hypervisors are faster:

- **Parallels Desktop:**

  ```bash
  vagrant plugin install vagrant-parallels
  vagrant plugin install vagrant-disksize
  vagrant up --provider=parallels
  ```

- **VMware Fusion:** requires the separately-licensed `vagrant-vmware-utility`
  helper in addition to the plugin.

  ```bash
  vagrant plugin install vagrant-vmware-desktop
  vagrant plugin install vagrant-disksize
  # Also install the vagrant-vmware-utility (see HashiCorp's docs), then:
  vagrant up --provider=vmware_desktop
  ```

  > The Vagrantfile does not ship a `vmware_desktop` provider block, so the VM
  > will boot with VMware's default memory/CPU rather than the intended
  > 2048MB / 2 CPU. Add one if you need the guaranteed allocation.

#### Intel Mac — use VirtualBox (simplest path)

```bash
# Install VirtualBox (free) from https://www.virtualbox.org and Vagrant from
# https://www.vagrantup.com, then:
vagrant plugin install vagrant-disksize
vagrant up --provider=virtualbox
```

> **Licensing (Apple Silicon providers):** Parallels Desktop and VMware Fusion
> are commercial products.
> Their licensing terms (including any free/personal-use tiers) change over
> time — check the current terms on the vendors' sites before you install, and
> **confirm your employer's software-installation policy before putting either
> on a work laptop.**

**Host `rsync` requirement (all Macs).** The Vagrantfile uses an `rsync`-type
synced folder, which needs the `rsync` binary on the host. macOS ships one by
default, so this normally just works; only a minimal/custom shell environment
would need `rsync` installed manually.

### Notes for reusing config on a new machine

- **`static_vms.json` and `config` are gitignored** (they hold a plaintext
  practice password) and will not transfer via `git clone`. Recreate
  `static_vms.json` on the new machine using the JSON format shown in the
  [Configure App for Local VMs](#configure-app-for-local-vms) section above.
- **Stale SSH host keys:** if you reuse the same private-network IPs
  (192.168.99.11 / .12) on a fresh machine, old `known_hosts` entries will
  trigger a host-key-changed warning. Clear them with
  `ssh-keygen -R 192.168.99.11` (and `.12`).

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
     "node1_ip": "YOUR_VM1_IP",
     "node2_ip": "YOUR_VM2_IP",
     "ssh_user": "root",
     "ssh_password": "YOUR_PASSWORD"
   }
   ```

   Or with SSH key:

   ```json
   {
     "session_id": "manual-vms",
     "node1_ip": "YOUR_VM1_IP",
     "node2_ip": "YOUR_VM2_IP",
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
