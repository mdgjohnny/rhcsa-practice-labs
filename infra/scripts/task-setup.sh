#!/bin/bash
# Task Setup Script - Run once during cloud-init to prepare practice scenarios
# This creates "broken" scenarios that students must fix

set -e
LOG="/var/log/task-setup.log"
exec > >(tee -a "$LOG") 2>&1
echo "=== Task Setup Started: $(date) ==="

# Only run once
if [[ -f /root/.task-setup-complete ]]; then
    echo "Task setup already complete, skipping"
    exit 0
fi

NODE=$(hostname)
echo "Setting up tasks for $NODE"

###############################################################################
# COMMON SETUP (both nodes)
###############################################################################

# Ensure policycoreutils-python-utils for semanage
dnf install -y policycoreutils-python-utils &>/dev/null || true

###############################################################################
# NODE1 (rhcsa1) SPECIFIC SETUP
###############################################################################
if [[ "$NODE" == "rhcsa1" ]]; then

    echo "=== Setting up Apache/SELinux tasks ==="
    
    # Install httpd for web-related tasks
    dnf install -y httpd mod_ssl &>/dev/null || true
    systemctl enable httpd &>/dev/null || true
    
    # Task-197: Apache reverse proxy (broken - SELinux blocks network connect)
    cat > /etc/httpd/conf.d/backend-proxy.conf << 'PROXY'
<Location "/backend">
    ProxyPass "http://127.0.0.1:8888/"
    ProxyPassReverse "http://127.0.0.1:8888/"
</Location>
PROXY

    # Backend service for proxy task
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
    
    # Systemd service for backend
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
    systemctl enable --now backend-server &>/dev/null || true

    # Task-208: Web file with wrong context (broken - 403 error)
    mkdir -p /var/www/html
    echo "<html><body>SELINUX_CONTEXT_OK</body></html>" > /var/www/html/index.html
    chcon -t user_home_t /var/www/html/index.html  # Wrong context!
    chmod 644 /var/www/html/index.html

    # Task-218: UserDir setup (broken - SELinux blocks home access)
    useradd -m webdev 2>/dev/null || true
    mkdir -p /home/webdev/public_html
    echo "<html><body>USERDIR_WORKS</body></html>" > /home/webdev/public_html/index.html
    chmod 711 /home/webdev
    chmod 755 /home/webdev/public_html
    chmod 644 /home/webdev/public_html/index.html
    # Enable UserDir in Apache
    sed -i 's/UserDir disabled$/UserDir public_html/' /etc/httpd/conf.d/userdir.conf 2>/dev/null || true
    sed -i 's/Require method GET POST OPTIONS/Require all granted/' /etc/httpd/conf.d/userdir.conf 2>/dev/null || true

    # Start httpd (will have SELinux issues until student fixes them)
    systemctl start httpd &>/dev/null || true

    # Ensure SELinux booleans are OFF for practice
    setsebool httpd_can_network_connect off 2>/dev/null || true
    setsebool httpd_enable_homedirs off 2>/dev/null || true

    echo "=== Setting up FTP task ==="
    # Task-220: FTP uploads (broken - SELinux blocks writes)
    dnf install -y vsftpd &>/dev/null || true
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
    systemctl enable --now vsftpd &>/dev/null || true
    setsebool ftpd_full_access off 2>/dev/null || true

    echo "=== Setting up NFS task ==="
    # Task-51: NFS exports
    dnf install -y nfs-utils &>/dev/null || true
    mkdir -p /srv/nfsdata
    chmod 755 /srv/nfsdata
    echo "/srv/nfsdata *(rw,sync,no_root_squash)" >> /etc/exports
    systemctl enable --now nfs-server &>/dev/null || true
    exportfs -ra 2>/dev/null || true
    setsebool nfs_export_all_rw off 2>/dev/null || true

    echo "=== Setting up SSH alternate port task ==="
    # Task-222: SSH on port 2222 (broken - SELinux blocks)
    if ! grep -q "^Port 2222" /etc/ssh/sshd_config; then
        sed -i '/^#Port 22/a Port 2222' /etc/ssh/sshd_config
    fi
    # Don't restart sshd - it will fail until student fixes SELinux

fi

###############################################################################
# NODE2 (rhcsa2) SPECIFIC SETUP  
###############################################################################
if [[ "$NODE" == "rhcsa2" ]]; then
    echo "Node2 setup - minimal (kept clean for other tasks)"
fi

###############################################################################
# MARK COMPLETE
###############################################################################
touch /root/.task-setup-complete
echo "=== Task Setup Complete: $(date) ==="
