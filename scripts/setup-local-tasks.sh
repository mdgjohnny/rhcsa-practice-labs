#!/bin/bash
#
# Setup Local VMs for RHCSA Practice Tasks
#
# This script prepares a VM with "broken" scenarios that students must fix.
# It creates the same environment as cloud-init does for OCI VMs.
#
# Usage:
#   1. SSH to your VM as root
#   2. Run: curl -sSL https://raw.githubusercontent.com/mdgjohnny/rhcsa-practice-labs/main/scripts/setup-local-tasks.sh | bash
#   Or:
#   1. Copy this script to the VM
#   2. Run: sudo bash setup-local-tasks.sh [node1|node2]
#
# Supports: Rocky Linux 9, AlmaLinux 9, Oracle Linux 8/9, RHEL 8/9
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[!]${NC} $1"; exit 1; }

# Check if running as root
[[ $EUID -eq 0 ]] || error "This script must be run as root"

# Determine node type from hostname or argument
NODE="${1:-$(hostname | grep -q '2' && echo 'node2' || echo 'node1')}"
log "Configuring as: $NODE"

# Check if already setup
if [[ -f /root/.task-setup-complete ]]; then
    warn "Task setup already completed. To re-run, delete /root/.task-setup-complete"
    exit 0
fi

LOG="/var/log/task-setup.log"
exec > >(tee -a "$LOG") 2>&1
echo "=== Task Setup Started: $(date) ==="

###############################################################################
# PHASE 1: SYSTEM PREPARATION
###############################################################################
log "Phase 1: System preparation..."

# Detect OS
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS_ID="$ID"
    OS_VERSION="${VERSION_ID%%.*}"
    log "Detected: $NAME $VERSION_ID"
else
    error "Cannot detect OS version"
fi

# Install required packages
log "Installing required packages..."
dnf install -y \
    policycoreutils-python-utils \
    selinux-policy-targeted \
    setroubleshoot-server \
    httpd mod_ssl \
    vsftpd \
    nfs-utils \
    tar gzip bzip2 xz \
    vim nano \
    curl wget \
    &>/dev/null || warn "Some packages may have failed to install"

###############################################################################
# PHASE 2: PRACTICE DISK SETUP
###############################################################################
log "Phase 2: Setting up practice disks..."

mkdir -p /var/practice-disks

# Create sparse disk images for LVM/partition practice
DISKS=(
    "disk0.img:10G"  # Main practice disk
    "disk1.img:5G"   # ext4/vfat tasks
    "disk2.img:2G"   # GPT partition
    "disk3.img:2G"   # MBR partition
    "disk4.img:1G"   # PV practice
    "disk5.img:1G"   # VG practice
)

for disk_spec in "${DISKS[@]}"; do
    name="${disk_spec%%:*}"
    size="${disk_spec##*:}"
    path="/var/practice-disks/$name"
    if [[ ! -f "$path" ]]; then
        truncate -s "$size" "$path"
        log "Created $path ($size)"
    fi
done

# Setup loopback devices
for i in {0..5}; do
    img="/var/practice-disks/disk$i.img"
    if [[ -f "$img" ]] && ! losetup -j "$img" | grep -q loop; then
        losetup "/dev/loop$i" "$img" 2>/dev/null || warn "loop$i already in use"
    fi
done

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
log "Practice disks configured"

###############################################################################
# PHASE 3: NODE-SPECIFIC SETUP
###############################################################################

if [[ "$NODE" == "node1" ]]; then
    log "Phase 3: Setting up node1-specific scenarios..."
    
    #--------------------------------------------------------------------------
    # Task-197: Apache reverse proxy (broken - SELinux blocks network connect)
    #--------------------------------------------------------------------------
    log "Setting up Apache reverse proxy scenario..."
    
    cat > /etc/httpd/conf.d/backend-proxy.conf << 'PROXY'
<Location "/backend">
    ProxyPass "http://127.0.0.1:8888/"
    ProxyPassReverse "http://127.0.0.1:8888/"
</Location>
PROXY

    # Backend server
    cat > /usr/local/bin/backend-server.py << 'PYBACK'
#!/usr/bin/python3
from http.server import HTTPServer, BaseHTTPRequestHandler
class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(b'BACKEND_OK')
    def log_message(self, *args): pass
HTTPServer(('127.0.0.1', 8888), Handler).serve_forever()
PYBACK
    chmod +x /usr/local/bin/backend-server.py
    
    cat > /etc/systemd/system/backend-server.service << 'SVC'
[Unit]
Description=Backend Server for Practice Tasks
After=network.target

[Service]
ExecStart=/usr/local/bin/backend-server.py
Restart=always

[Install]
WantedBy=multi-user.target
SVC
    systemctl daemon-reload
    systemctl enable --now backend-server 2>/dev/null || true

    #--------------------------------------------------------------------------
    # Task-208: Web file with wrong SELinux context (403 error)
    #--------------------------------------------------------------------------
    log "Setting up SELinux context scenario..."
    
    mkdir -p /var/www/html
    echo '<html><body>SELINUX_CONTEXT_OK</body></html>' > /var/www/html/index.html
    chcon -t user_home_t /var/www/html/index.html  # Wrong context!
    chmod 644 /var/www/html/index.html

    #--------------------------------------------------------------------------
    # Task-218: UserDir setup (broken - SELinux blocks home access)
    #--------------------------------------------------------------------------
    log "Setting up UserDir scenario..."
    
    useradd -m webdev 2>/dev/null || true
    mkdir -p /home/webdev/public_html
    echo '<html><body>USERDIR_WORKS</body></html>' > /home/webdev/public_html/index.html
    chmod 711 /home/webdev
    chmod 755 /home/webdev/public_html
    chmod 644 /home/webdev/public_html/index.html
    
    # Enable UserDir in Apache
    if [[ -f /etc/httpd/conf.d/userdir.conf ]]; then
        sed -i 's/UserDir disabled$/UserDir public_html/' /etc/httpd/conf.d/userdir.conf
        sed -i 's/Require method GET POST OPTIONS/Require all granted/' /etc/httpd/conf.d/userdir.conf
    fi

    #--------------------------------------------------------------------------
    # Task-220: FTP uploads (broken - SELinux blocks writes)
    #--------------------------------------------------------------------------
    log "Setting up FTP scenario..."
    
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
    systemctl enable --now vsftpd 2>/dev/null || true

    #--------------------------------------------------------------------------
    # Task-51: NFS exports (broken - SELinux blocks read/write)
    #--------------------------------------------------------------------------
    log "Setting up NFS scenario..."
    
    mkdir -p /srv/nfsdata
    chmod 755 /srv/nfsdata
    echo "Test NFS file" > /srv/nfsdata/testfile
    grep -q '/srv/nfsdata' /etc/exports || echo '/srv/nfsdata *(rw,sync,no_root_squash)' >> /etc/exports
    systemctl enable --now nfs-server 2>/dev/null || true
    exportfs -ra 2>/dev/null || true

    #--------------------------------------------------------------------------
    # Task-222: SSH on alternate port (broken - SELinux blocks)
    #--------------------------------------------------------------------------
    log "Setting up SSH alternate port scenario..."
    
    if ! grep -q '^Port 2222' /etc/ssh/sshd_config; then
        sed -i '/^#*Port 22/a Port 2222' /etc/ssh/sshd_config
    fi
    # Note: sshd won't bind to 2222 until student fixes SELinux

    #--------------------------------------------------------------------------
    # Start services and set broken SELinux state
    #--------------------------------------------------------------------------
    log "Starting services with broken SELinux state..."
    
    systemctl enable --now httpd 2>/dev/null || true
    
    # Ensure SELinux booleans are OFF for practice
    setsebool httpd_can_network_connect off 2>/dev/null || true
    setsebool httpd_enable_homedirs off 2>/dev/null || true
    setsebool ftpd_full_access off 2>/dev/null || true
    setsebool nfs_export_all_rw off 2>/dev/null || true

else
    log "Phase 3: Setting up node2 (secondary node)..."
    # node2 is kept cleaner for multi-node tasks (NFS client, etc.)
    
    # Enable NFS client
    systemctl enable --now nfs-client.target 2>/dev/null || true
fi

###############################################################################
# PHASE 4: COMMON SETUP (BOTH NODES)
###############################################################################
log "Phase 4: Common setup..."

# Create practice users
for user in alice bob charlie; do
    useradd -m "$user" 2>/dev/null || true
    echo "$user:password" | chpasswd
done

# Create practice groups
for group in developers sysadmins dbadmins; do
    groupadd "$group" 2>/dev/null || true
done

# Create practice directories
mkdir -p /data/{projects,shared,backup}
mkdir -p /scripts
chmod 755 /data /scripts

# Ensure SELinux is enforcing
if [[ $(getenforce) != "Enforcing" ]]; then
    warn "SELinux is not enforcing! Setting to enforcing mode..."
    setenforce 1 2>/dev/null || warn "Could not set enforcing mode"
fi

# Configure firewall (allow SSH)
systemctl enable --now firewalld 2>/dev/null || true
firewall-cmd --permanent --add-service=ssh 2>/dev/null || true
firewall-cmd --reload 2>/dev/null || true

###############################################################################
# COMPLETE
###############################################################################
touch /root/.task-setup-complete

log "=== Task Setup Complete ==="
log "Node configured as: $NODE"
log "Log file: $LOG"
log ""
log "Scenarios created:"
if [[ "$NODE" == "node1" ]]; then
    echo "  - Apache reverse proxy (Task-197): SELinux blocks network connect"
    echo "  - Web file context (Task-208): Wrong SELinux context causes 403"
    echo "  - UserDir (Task-218): SELinux blocks home directory access"
    echo "  - FTP uploads (Task-220): SELinux blocks anonymous writes"
    echo "  - NFS exports (Task-51): SELinux blocks NFS read/write"
    echo "  - SSH port 2222 (Task-222): SELinux blocks alternate port"
fi
echo "  - Practice disks: /dev/loop0 through /dev/loop5"
echo "  - Practice users: alice, bob, charlie (password: password)"
echo "  - Practice groups: developers, sysadmins, dbadmins"
echo ""
log "VM is ready for practice!"
