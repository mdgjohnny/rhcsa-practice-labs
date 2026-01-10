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

# PHASE 6: CREATE PRACTICE DISKS (LOOPBACK) - sparse files
mkdir -p /var/practice-disks
truncate -s 10G /var/practice-disks/disk1.img
truncate -s 10G /var/practice-disks/disk2.img  
truncate -s 5G /var/practice-disks/disk3.img
losetup /dev/loop0 /var/practice-disks/disk1.img
losetup /dev/loop1 /var/practice-disks/disk2.img
losetup /dev/loop2 /var/practice-disks/disk3.img

# Persist loopback across reboots
cat > /etc/systemd/system/practice-disks.service << 'SERVICE'
[Unit]
Description=Setup practice disk loopback devices
After=local-fs.target
[Service]
Type=oneshot
ExecStart=/bin/bash -c 'losetup /dev/loop0 /var/practice-disks/disk1.img; losetup /dev/loop1 /var/practice-disks/disk2.img; losetup /dev/loop2 /var/practice-disks/disk3.img; exit 0'
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
SERVICE
systemctl daemon-reload
systemctl enable practice-disks.service

# PHASE 7: CLEANUP
dnf clean all 2>/dev/null || true
sync && echo 3 > /proc/sys/vm/drop_caches
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

# PHASE 6: CREATE PRACTICE DISKS (LOOPBACK)
mkdir -p /var/practice-disks
truncate -s 10G /var/practice-disks/disk1.img
truncate -s 10G /var/practice-disks/disk2.img  
truncate -s 5G /var/practice-disks/disk3.img
losetup /dev/loop0 /var/practice-disks/disk1.img
losetup /dev/loop1 /var/practice-disks/disk2.img
losetup /dev/loop2 /var/practice-disks/disk3.img

cat > /etc/systemd/system/practice-disks.service << 'SERVICE'
[Unit]
Description=Setup practice disk loopback devices
After=local-fs.target
[Service]
Type=oneshot
ExecStart=/bin/bash -c 'losetup /dev/loop0 /var/practice-disks/disk1.img; losetup /dev/loop1 /var/practice-disks/disk2.img; losetup /dev/loop2 /var/practice-disks/disk3.img; exit 0'
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
SERVICE
systemctl daemon-reload
systemctl enable practice-disks.service

# PHASE 7: CLEANUP
dnf clean all 2>/dev/null || true
sync && echo 3 > /proc/sys/vm/drop_caches
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

  metadata = {
    ssh_authorized_keys = local.ssh_public_key
    user_data           = base64encode(local.cloud_init_node2)
  }

  preserve_boot_volume = false
}
