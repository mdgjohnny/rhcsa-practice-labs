# RHCSA Practice Labs - Vagrant Configuration
# Spins up two Rocky Linux 9 VMs for RHCSA exam practice
#
# Prerequisites:
#   - Vagrant with a supported provider. Provider-specific config blocks are
#     defined below for libvirt (Linux), virtualbox (Intel Mac / Linux),
#     qemu (free Apple Silicon path) and parallels (Apple Silicon Mac). See
#     docs/local-vm-setup.md for the platform-specific setup, especially the
#     macOS / Apple Silicon caveats.
#   - Linux: vagrant plugin install vagrant-libvirt
#   - vagrant-disksize plugin (all platforms): vagrant plugin install vagrant-disksize
#
# Usage:
#   vagrant up                        # uses the default provider
#   vagrant up --provider=virtualbox  # Intel Mac
#   vagrant up --provider=qemu        # Apple Silicon Mac (free, slower)
#   vagrant up --provider=parallels   # Apple Silicon Mac (commercial)
#   Then configure the app with static_vms.json (see docs/vm-recovery.md)
#
# After VMs are up:
#   - rhcsa1: 192.168.99.11 (SSH root:vagrant)
#   - rhcsa2: 192.168.99.12 (SSH root:vagrant)

# Enable root SSH login with password
$set_root_password = <<-SCRIPT
echo 'root:vagrant' | chpasswd
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd
SCRIPT

# Task setup script - creates broken scenarios for troubleshooting practice
$task_setup = <<-SCRIPT
#!/bin/bash
# Run the task setup script (idempotent)
cd /vagrant 2>/dev/null || cd /tmp
if [[ -f /vagrant/scripts/setup-local-tasks.sh ]]; then
    bash /vagrant/scripts/setup-local-tasks.sh "$1"
else
    # Download if not available via shared folder
    curl -sSL https://raw.githubusercontent.com/mdgjohnny/rhcsa-practice-labs/main/scripts/setup-local-tasks.sh | bash -s "$1"
fi
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.boot_timeout = 600
  config.ssh.connect_timeout = 60
  config.disksize.size = '12GB'
  
  # Mount project for task setup script access
  config.vm.synced_folder ".", "/vagrant", type: "rsync", rsync__exclude: [".git/", "__pycache__/", ".venv/", "workspaces/", "sessions.db"]

  # Provider-specific config. Vagrant only applies the block matching the
  # provider that is actually active (selected via --provider or VAGRANT_DEFAULT_PROVIDER),
  # so defining all four is purely additive and safe across platforms.
  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = 2048
    libvirt.cpus = 2
    libvirt.graphics_type = "spice"
    libvirt.video_type = "qxl"
    libvirt.channel :type => 'spicevmc', :target_name => 'com.redhat.spice.0', :target_type => 'virtio'
  end

  # VirtualBox: Intel Macs and Linux. Does NOT work on Apple Silicon (no x86_64
  # guest support on ARM hosts) - see docs/local-vm-setup.md.
  config.vm.provider :virtualbox do |vb|
    vb.memory = 2048
    vb.cpus = 2
  end

  # Parallels Desktop: Apple Silicon (and Intel) Macs.
  # Requires: vagrant plugin install vagrant-parallels
  config.vm.provider :parallels do |prl|
    prl.memory = 2048
    prl.cpus = 2
  end

  # QEMU: free path for Apple Silicon (arch mismatch -> TCG software emulation,
  # so noticeably slower than the accelerated/commercial paths). x86_64 guest on
  # an arm64 host needs the arch/machine/cpu/net_device settings below.
  # Requires: brew install qemu && vagrant plugin install vagrant-qemu
  # Note: vagrant-qemu uses string memory ("2G") and smp (CPU count), not the
  # integer memory/cpus used by the other providers.
  config.vm.provider :qemu do |qe|
    qe.memory = "2G"
    qe.smp = "2"
    qe.arch = "x86_64"
    qe.machine = "q35"
    qe.cpu = "qemu64"
    qe.net_device = "virtio-net-pci"
  end

  # Node 1 - Primary practice node (most tasks)
  config.vm.define :node1, primary: true do |node1|
    node1.vm.box = "generic/rocky9"
    node1.vm.hostname = "rhcsa1"
    node1.vm.network :private_network, ip: "192.168.99.11"
    node1.vm.provision "root_ssh", type: "shell", inline: $set_root_password
    node1.vm.provision "task_setup", type: "shell", inline: $task_setup, args: "node1"
  end

  # Node 2 - Secondary node for multi-node tasks (NFS client, etc.)
  config.vm.define :node2 do |node2|
    node2.vm.box = "generic/rocky9"
    node2.vm.hostname = "rhcsa2"
    node2.vm.network :private_network, ip: "192.168.99.12"
    node2.vm.provision "root_ssh", type: "shell", inline: $set_root_password
    node2.vm.provision "task_setup", type: "shell", inline: $task_setup, args: "node2"
  end
end
