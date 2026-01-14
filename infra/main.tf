# =============================================================================
# RHCSA Practice Labs - OCI Infrastructure
# =============================================================================

provider "oci" {
  tenancy_ocid = var.tenancy_ocid
  user_ocid    = var.user_ocid
  fingerprint  = var.fingerprint
  region       = var.region
  private_key  = file(var.private_key_path)
}

# =============================================================================
# Data Sources
# =============================================================================

# Get availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# Get latest Oracle Linux 8 image (RHEL-compatible)
data "oci_core_images" "oracle_linux" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

locals {
  # Use provided image or latest Oracle Linux 8
  image_id = var.os_image_id != "" ? var.os_image_id : data.oci_core_images.oracle_linux.images[0].id

  # Use first availability domain
  ad = data.oci_identity_availability_domains.ads.availability_domains[0].name

  # Common tags
  common_tags = {
    "Project"   = "rhcsa-practice-labs"
    "SessionID" = var.session_id
    "ManagedBy" = "terraform"
  }
}

# =============================================================================
# SSH Key Generation (per-session)
# =============================================================================

resource "tls_private_key" "session_key" {
  count     = var.ssh_public_key == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  ssh_public_key  = var.ssh_public_key != "" ? var.ssh_public_key : tls_private_key.session_key[0].public_key_openssh
  ssh_private_key = var.ssh_public_key != "" ? "" : tls_private_key.session_key[0].private_key_pem
}

# =============================================================================
# Network Resources
# =============================================================================

# Virtual Cloud Network
resource "oci_core_vcn" "practice_vcn" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = [var.vcn_cidr]
  display_name   = "rhcsa-practice-vcn-${var.session_id}"
  dns_label      = "rhcsa${replace(substr(var.session_id, 0, 8), "-", "")}"
  freeform_tags  = local.common_tags
}

# Internet Gateway
resource "oci_core_internet_gateway" "practice_igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.practice_vcn.id
  display_name   = "rhcsa-practice-igw-${var.session_id}"
  enabled        = true
  freeform_tags  = local.common_tags
}

# Route Table
resource "oci_core_route_table" "practice_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.practice_vcn.id
  display_name   = "rhcsa-practice-rt-${var.session_id}"
  freeform_tags  = local.common_tags

  route_rules {
    network_entity_id = oci_core_internet_gateway.practice_igw.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

# Security List
resource "oci_core_security_list" "practice_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.practice_vcn.id
  display_name   = "rhcsa-practice-sl-${var.session_id}"
  freeform_tags  = local.common_tags

  # Allow all egress
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
  }

  # Allow SSH from anywhere (for web terminal access)
  ingress_security_rules {
    source    = "0.0.0.0/0"
    protocol  = "6" # TCP
    stateless = false
    tcp_options {
      min = 22
      max = 22
    }
  }

  # Allow ICMP (ping) for troubleshooting
  ingress_security_rules {
    source    = "0.0.0.0/0"
    protocol  = "1" # ICMP
    stateless = false
    icmp_options {
      type = 8 # Echo request
    }
  }

  # Allow all traffic within VCN (node1 <-> node2)
  ingress_security_rules {
    source    = var.vcn_cidr
    protocol  = "all"
    stateless = false
  }
}

# Public Subnet
resource "oci_core_subnet" "practice_subnet" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.practice_vcn.id
  cidr_block                 = var.subnet_cidr
  display_name               = "rhcsa-practice-subnet-${var.session_id}"
  dns_label                  = "subnet"
  route_table_id             = oci_core_route_table.practice_rt.id
  security_list_ids          = [oci_core_security_list.practice_sl.id]
  prohibit_public_ip_on_vnic = false
  freeform_tags              = local.common_tags
}

# =============================================================================
# Compute Instances
# =============================================================================

# Cloud-init script for initial setup
locals {
  cloud_init_node1 = <<-EOF
#!/bin/bash
# RHCSA Practice Lab - Node 1 Setup

# PHASE 1: KILL BLOATWARE IMMEDIATELY
pkill -9 -f "oracle-cloud-agent" 2>/dev/null &
pkill -9 -f "ksplice" 2>/dev/null &
pkill -9 -f "pmcd|pmlogger" 2>/dev/null &
wait

# PHASE 2: MASK SERVICES (prevents ANY restart)
KILL_SERVICES="oracle-cloud-agent oracle-cloud-agent-updater ksplice pmcd pmlogger pmie pmproxy cockpit cockpit.socket dnf-makecache.timer dnf-automatic.timer iscsi iscsid"
for svc in $KILL_SERVICES; do
    systemctl stop "$svc" 2>/dev/null
    systemctl disable "$svc" 2>/dev/null  
    systemctl mask "$svc" 2>/dev/null
done
rm -f /etc/cron.d/ksplice /etc/cron.d/oracle* /etc/cron.daily/oracle*

# PHASE 2b: DISABLE BLOATED REPOS (saves 400MB+ downloads)
# Keep ONLY BaseOS and AppStream - that's all RHCSA needs
# dnf config-manager --disable doesn't work reliably, use sed instead
for f in /etc/yum.repos.d/ksplice-ol8.repo \
         /etc/yum.repos.d/mysql-ol8.repo \
         /etc/yum.repos.d/oci-included-ol8.repo \
         /etc/yum.repos.d/uek-ol8.repo \
         /etc/yum.repos.d/oraclelinux-developer-ol8.repo; do
    [ -f "$f" ] && sed -i 's/^enabled=1/enabled=0/' "$f"
done
# Disable addons in main oracle-linux repo
sed -i '/^\[ol8_addons\]/,/^\[/{s/^enabled=1/enabled=0/}' /etc/yum.repos.d/oracle-linux-ol8.repo 2>/dev/null || true

# PHASE 3: HOSTNAME AND HOSTS
hostnamectl set-hostname rhcsa1
echo "${cidrhost(var.subnet_cidr, 11)} rhcsa1" >> /etc/hosts
echo "${cidrhost(var.subnet_cidr, 12)} rhcsa2" >> /etc/hosts

# PHASE 4: USER SETUP
useradd -m student
echo "student:student" | chpasswd
echo "student ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/student
chmod 440 /etc/sudoers.d/student
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

# PHASE 5: MEMORY OPTIMIZATION
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/size.conf << 'JOURNAL'
[Journal]
SystemMaxUse=20M
RuntimeMaxUse=20M
MaxRetentionSec=1day
JOURNAL
systemctl restart systemd-journald

cat >> /etc/sysctl.conf << 'SYSCTL'
vm.swappiness=60
vm.vfs_cache_pressure=200
vm.dirty_ratio=5
vm.dirty_background_ratio=2
SYSCTL
sysctl -p 2>/dev/null

# PHASE 6: SETUP EXTRA SWAP FOR PACKAGE INSTALLATION
# Key insight from previous session: create swap FIRST, then dnf works!
# NOTE: Must use dd or fallocate, NOT truncate (sparse files don't work for swap)
mkdir -p /var/practice-disks
dd if=/dev/zero of=/var/practice-disks/swap.img bs=1M count=1024 status=none
chmod 600 /var/practice-disks/swap.img
mkswap /var/practice-disks/swap.img
swapon /var/practice-disks/swap.img
echo "/var/practice-disks/swap.img swap swap defaults 0 0" >> /etc/fstab

# Enable atd (pre-installed)
systemctl enable atd 2>/dev/null || true
systemctl start atd 2>/dev/null || true

# Create helper script for additional packages
cat > /usr/local/bin/safe-install << 'SCRIPT'
#!/bin/bash
echo "Clearing caches before install..."
sync && echo 3 > /proc/sys/vm/drop_caches
rm -rf /var/cache/dnf/* 2>/dev/null
echo "Installing $@..."
dnf install -y --setopt=install_weak_deps=False "$@"
rm -rf /var/cache/dnf/*
sync && echo 3 > /proc/sys/vm/drop_caches
SCRIPT
chmod +x /usr/local/bin/safe-install

# PHASE 7: CREATE PRACTICE DISKS (LOOPBACK) - sparse files for LVM/partition practice
truncate -s 10G /var/practice-disks/disk0.img  # loop0 - main practice disk
truncate -s 5G /var/practice-disks/disk1.img   # loop1 - ext4/vfat tasks  
truncate -s 2G /var/practice-disks/disk2.img   # loop2 - GPT partition
truncate -s 2G /var/practice-disks/disk3.img   # loop3 - MBR partition
truncate -s 1G /var/practice-disks/disk4.img   # loop4 - PV practice
truncate -s 1G /var/practice-disks/disk5.img   # loop5 - VG practice

losetup /dev/loop0 /var/practice-disks/disk0.img
losetup /dev/loop1 /var/practice-disks/disk1.img
losetup /dev/loop2 /var/practice-disks/disk2.img
losetup /dev/loop3 /var/practice-disks/disk3.img
losetup /dev/loop4 /var/practice-disks/disk4.img
losetup /dev/loop5 /var/practice-disks/disk5.img

# Persist loopback across reboots
cat > /etc/systemd/system/practice-disks.service << 'SERVICE'
[Unit]
Description=Setup practice disk loopback devices
After=local-fs.target
[Service]
Type=oneshot
ExecStart=/bin/bash -c 'for i in 0 1 2 3 4 5; do losetup /dev/loop$i /var/practice-disks/disk$i.img 2>/dev/null || true; done'
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
SERVICE
systemctl daemon-reload
systemctl enable practice-disks.service

# PHASE 8: TASK SCENARIO SETUP
# Create broken scenarios for troubleshooting tasks
echo "Setting up practice task scenarios..."

# Install packages needed for tasks (in background to not block)
(
  dnf install -y httpd mod_ssl vsftpd nfs-utils policycoreutils-python-utils &>/dev/null
  
  # Task-197: Apache reverse proxy setup
  cat > /etc/httpd/conf.d/backend-proxy.conf << 'PROXY'
<Location "/backend">
    ProxyPass "http://127.0.0.1:8888/"
    ProxyPassReverse "http://127.0.0.1:8888/"
</Location>
PROXY

  # Backend server for proxy task
  cat > /usr/local/bin/backend-server.py << 'PYBACK'
#!/usr/bin/python3
from http.server import HTTPServer, BaseHTTPRequestHandler
class H(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'BACKEND_OK')
    def log_message(self, *a): pass
HTTPServer(('127.0.0.1', 8888), H).serve_forever()
PYBACK
  chmod +x /usr/local/bin/backend-server.py
  
  cat > /etc/systemd/system/backend-server.service << 'SVC'
[Unit]
Description=Backend Server
After=network.target
[Service]
ExecStart=/usr/local/bin/backend-server.py
Restart=always
[Install]
WantedBy=multi-user.target
SVC
  systemctl daemon-reload
  systemctl enable --now backend-server

  # Task-208: Web file with wrong SELinux context
  mkdir -p /var/www/html
  echo '<html><body>SELINUX_CONTEXT_OK</body></html>' > /var/www/html/index.html
  chcon -t user_home_t /var/www/html/index.html
  chmod 644 /var/www/html/index.html

  # Task-218: UserDir setup
  useradd -m webdev 2>/dev/null || true
  mkdir -p /home/webdev/public_html
  echo '<html><body>USERDIR_WORKS</body></html>' > /home/webdev/public_html/index.html
  chmod 711 /home/webdev
  chmod 755 /home/webdev/public_html
  sed -i 's/UserDir disabled$/UserDir public_html/' /etc/httpd/conf.d/userdir.conf
  sed -i 's/Require method GET POST OPTIONS/Require all granted/' /etc/httpd/conf.d/userdir.conf

  # Task-220: FTP setup
  mkdir -p /var/ftp/uploads
  chmod 777 /var/ftp/uploads
  cat > /etc/vsftpd/vsftpd.conf << 'VSFTPD'
anonymous_enable=YES
local_enable=YES
write_enable=YES
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_root=/var/ftp
listen=YES
listen_ipv6=NO
pam_service_name=vsftpd
VSFTPD
  systemctl enable --now vsftpd

  # Task-51: NFS setup
  mkdir -p /srv/nfsdata
  chmod 755 /srv/nfsdata
  grep -q '/srv/nfsdata' /etc/exports || echo '/srv/nfsdata *(rw,sync,no_root_squash)' >> /etc/exports
  systemctl enable --now nfs-server
  exportfs -ra

  # Start httpd and ensure SELinux booleans are OFF for practice
  systemctl enable --now httpd
  setsebool httpd_can_network_connect off
  setsebool httpd_enable_homedirs off
  setsebool ftpd_full_access off
  setsebool nfs_export_all_rw off

  # Task-222: SSH on alternate port
  grep -q '^Port 2222' /etc/ssh/sshd_config || sed -i '/^#Port 22/a Port 2222' /etc/ssh/sshd_config

  touch /root/.task-setup-complete
) &

# PHASE 9: CLEANUP
dnf clean all 2>/dev/null || true
rm -rf /var/cache/dnf/*
sync && echo 3 > /proc/sys/vm/drop_caches

# Signal that setup is complete (VM is usable)
touch /root/.cloud-init-complete
  EOF

  cloud_init_node2 = <<-EOF
#!/bin/bash
# RHCSA Practice Lab - Node 2 Setup

# PHASE 1: KILL BLOATWARE IMMEDIATELY
pkill -9 -f "oracle-cloud-agent" 2>/dev/null &
pkill -9 -f "ksplice" 2>/dev/null &
pkill -9 -f "pmcd|pmlogger" 2>/dev/null &
wait

# PHASE 2: MASK SERVICES
KILL_SERVICES="oracle-cloud-agent oracle-cloud-agent-updater ksplice pmcd pmlogger pmie pmproxy cockpit cockpit.socket dnf-makecache.timer dnf-automatic.timer iscsi iscsid"
for svc in $KILL_SERVICES; do
    systemctl stop "$svc" 2>/dev/null
    systemctl disable "$svc" 2>/dev/null  
    systemctl mask "$svc" 2>/dev/null
done
rm -f /etc/cron.d/ksplice /etc/cron.d/oracle* /etc/cron.daily/oracle*

# PHASE 2b: DISABLE BLOATED REPOS (saves 400MB+ downloads)
# Keep ONLY BaseOS and AppStream - that's all RHCSA needs
for f in /etc/yum.repos.d/ksplice-ol8.repo \
         /etc/yum.repos.d/mysql-ol8.repo \
         /etc/yum.repos.d/oci-included-ol8.repo \
         /etc/yum.repos.d/uek-ol8.repo \
         /etc/yum.repos.d/oraclelinux-developer-ol8.repo; do
    [ -f "$f" ] && sed -i 's/^enabled=1/enabled=0/' "$f"
done
sed -i '/^\[ol8_addons\]/,/^\[/{s/^enabled=1/enabled=0/}' /etc/yum.repos.d/oracle-linux-ol8.repo 2>/dev/null || true

# PHASE 3: HOSTNAME AND HOSTS
hostnamectl set-hostname rhcsa2
echo "${cidrhost(var.subnet_cidr, 11)} rhcsa1" >> /etc/hosts
echo "${cidrhost(var.subnet_cidr, 12)} rhcsa2" >> /etc/hosts

# PHASE 4: USER SETUP
useradd -m student
echo "student:student" | chpasswd
echo "student ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/student
chmod 440 /etc/sudoers.d/student
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

# PHASE 5: MEMORY OPTIMIZATION
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/size.conf << 'JOURNAL'
[Journal]
SystemMaxUse=20M
RuntimeMaxUse=20M
MaxRetentionSec=1day
JOURNAL
systemctl restart systemd-journald

cat >> /etc/sysctl.conf << 'SYSCTL'
vm.swappiness=60
vm.vfs_cache_pressure=200
vm.dirty_ratio=5
vm.dirty_background_ratio=2
SYSCTL
sysctl -p 2>/dev/null

# PHASE 6: SETUP EXTRA SWAP AND INSTALL PACKAGES (node2)
mkdir -p /var/practice-disks
dd if=/dev/zero of=/var/practice-disks/swap.img bs=1M count=1024 status=none
chmod 600 /var/practice-disks/swap.img
mkswap /var/practice-disks/swap.img
swapon /var/practice-disks/swap.img
echo "/var/practice-disks/swap.img swap swap defaults 0 0" >> /etc/fstab

systemctl enable atd 2>/dev/null || true
systemctl start atd 2>/dev/null || true

cat > /usr/local/bin/safe-install << 'SCRIPT'
#!/bin/bash
echo "Clearing caches before install..."
sync && echo 3 > /proc/sys/vm/drop_caches
rm -rf /var/cache/dnf/* 2>/dev/null
echo "Installing $@..."
dnf install -y --setopt=install_weak_deps=False "$@"
rm -rf /var/cache/dnf/*
sync && echo 3 > /proc/sys/vm/drop_caches
SCRIPT
chmod +x /usr/local/bin/safe-install

# PHASE 7: CREATE PRACTICE DISKS (LOOPBACK)
truncate -s 10G /var/practice-disks/disk0.img
truncate -s 5G /var/practice-disks/disk1.img
truncate -s 2G /var/practice-disks/disk2.img
truncate -s 2G /var/practice-disks/disk3.img
truncate -s 1G /var/practice-disks/disk4.img
truncate -s 1G /var/practice-disks/disk5.img

losetup /dev/loop0 /var/practice-disks/disk0.img
losetup /dev/loop1 /var/practice-disks/disk1.img
losetup /dev/loop2 /var/practice-disks/disk2.img
losetup /dev/loop3 /var/practice-disks/disk3.img
losetup /dev/loop4 /var/practice-disks/disk4.img
losetup /dev/loop5 /var/practice-disks/disk5.img

cat > /etc/systemd/system/practice-disks.service << 'SERVICE'
[Unit]
Description=Setup practice disk loopback devices
After=local-fs.target
[Service]
Type=oneshot
ExecStart=/bin/bash -c 'for i in 0 1 2 3 4 5; do losetup /dev/loop$i /var/practice-disks/disk$i.img 2>/dev/null || true; done'
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
SERVICE
systemctl daemon-reload
systemctl enable practice-disks.service

# PHASE 8: CLEANUP
dnf clean all 2>/dev/null || true
rm -rf /var/cache/dnf/*
sync && echo 3 > /proc/sys/vm/drop_caches

# Signal that setup is complete (VM is usable)
touch /root/.cloud-init-complete
  EOF
}


# Node 1 (rhcsa1)
resource "oci_core_instance" "node1" {
  compartment_id      = var.compartment_ocid
  availability_domain = local.ad
  display_name        = "rhcsa1-${var.session_id}"
  shape               = var.instance_shape
  freeform_tags       = local.common_tags

  # For flex shapes, configure OCPUs and memory
  dynamic "shape_config" {
    for_each = can(regex("Flex", var.instance_shape)) ? [1] : []
    content {
      ocpus         = var.instance_ocpus
      memory_in_gbs = var.instance_memory_gb
    }
  }

  source_details {
    source_type = "image"
    source_id   = local.image_id
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.practice_subnet.id
    display_name     = "rhcsa1-vnic"
    assign_public_ip = true
    private_ip       = cidrhost(var.subnet_cidr, 11) # 10.0.1.11
    hostname_label   = "rhcsa1"
  }

  # Preemptible instances: ~50% cheaper, can be reclaimed with 30s notice
  # Perfect for practice labs where interruption is acceptable
  dynamic "preemptible_instance_config" {
    for_each = var.use_preemptible ? [1] : []
    content {
      preemption_action {
        type                 = "TERMINATE"
        preserve_boot_volume = false
      }
    }
  }

  metadata = {
    ssh_authorized_keys = local.ssh_public_key
    user_data           = base64encode(local.cloud_init_node1)
  }

  # Preserve boot volume on termination for debugging (optional)
  preserve_boot_volume = false
}

# Node 2 (rhcsa2)
resource "oci_core_instance" "node2" {
  compartment_id      = var.compartment_ocid
  availability_domain = local.ad
  display_name        = "rhcsa2-${var.session_id}"
  shape               = var.instance_shape
  freeform_tags       = local.common_tags

  dynamic "shape_config" {
    for_each = can(regex("Flex", var.instance_shape)) ? [1] : []
    content {
      ocpus         = var.instance_ocpus
      memory_in_gbs = var.instance_memory_gb
    }
  }

  source_details {
    source_type = "image"
    source_id   = local.image_id
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.practice_subnet.id
    display_name     = "rhcsa2-vnic"
    assign_public_ip = true
    private_ip       = cidrhost(var.subnet_cidr, 12) # 10.0.1.12
    hostname_label   = "rhcsa2"
  }

  # Preemptible instances: ~50% cheaper, can be reclaimed with 30s notice
  dynamic "preemptible_instance_config" {
    for_each = var.use_preemptible ? [1] : []
    content {
      preemption_action {
        type                 = "TERMINATE"
        preserve_boot_volume = false
      }
    }
  }

  metadata = {
    ssh_authorized_keys = local.ssh_public_key
    user_data           = base64encode(local.cloud_init_node2)
  }

  preserve_boot_volume = false
}
