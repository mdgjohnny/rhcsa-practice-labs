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
#   Then run: make install && sudo make run

# Provisioner to set root password for SSH access
$set_root_password = <<-SCRIPT
echo 'root:vagrant' | chpasswd
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.boot_timeout = 600
  config.ssh.connect_timeout = 60
  config.disksize.size = '12GB'

  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = 2048
    libvirt.cpus = 2
    libvirt.graphics_type = "spice"
    libvirt.video_type = "qxl"
    libvirt.channel :type => 'spicevmc', :target_name => 'com.redhat.spice.0', :target_type => 'virtio'
  end

  # Node 1 - Primary practice node
  config.vm.define :node1, primary: true do |node1|
    node1.vm.box = "rockylinux/9"
    node1.vm.network :private_network, ip: "192.168.99.11"
    node1.vm.provision "root_ssh", type: "shell", inline: $set_root_password
  end

  # Node 2 - Secondary node for multi-node tasks
  config.vm.define :node2 do |node2|
    node2.vm.box = "rockylinux/9"
    node2.vm.network :private_network, ip: "192.168.99.12"
    node2.vm.provision "root_ssh", type: "shell", inline: $set_root_password
  end
end
