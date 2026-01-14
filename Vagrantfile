# RHCSA Practice Labs - Vagrant Configuration
# Spins up two Rocky Linux 9 VMs for RHCSA exam practice
#
# Prerequisites:
#   - Vagrant with libvirt provider
#   - vagrant-libvirt plugin: vagrant plugin install vagrant-libvirt
#   - vagrant-disksize plugin: vagrant plugin install vagrant-disksize
#
# Usage:
#   vagrant up
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

  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = 2048
    libvirt.cpus = 2
    libvirt.graphics_type = "spice"
    libvirt.video_type = "qxl"
    libvirt.channel :type => 'spicevmc', :target_name => 'com.redhat.spice.0', :target_type => 'virtio'
  end

  # Node 1 - Primary practice node (most tasks)
  config.vm.define :node1, primary: true do |node1|
    node1.vm.box = "rockylinux/9"
    node1.vm.hostname = "rhcsa1"
    node1.vm.network :private_network, ip: "192.168.99.11"
    node1.vm.provision "root_ssh", type: "shell", inline: $set_root_password
    node1.vm.provision "task_setup", type: "shell", inline: $task_setup, args: "node1"
  end

  # Node 2 - Secondary node for multi-node tasks (NFS client, etc.)
  config.vm.define :node2 do |node2|
    node2.vm.box = "rockylinux/9"
    node2.vm.hostname = "rhcsa2"
    node2.vm.network :private_network, ip: "192.168.99.12"
    node2.vm.provision "root_ssh", type: "shell", inline: $set_root_password
    node2.vm.provision "task_setup", type: "shell", inline: $task_setup, args: "node2"
  end
end
