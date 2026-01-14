#!/usr/bin/env bash
# Task: A user "webdev" has created content in their ~/public_html directory, and Apache is configured with UserDir enabled. However, accessing http://localhost/~webdev/ returns a 403 Forbidden error. The file permissions are correct (checked with ls -la). Diagnose and fix the SELinux issue. The fix must persist across reboots. (Click "Check Task" to set up the scenario)
# Title: Troubleshoot Apache UserDir Access (SELinux)
# Category: security
# Target: node1

# Self-contained setup
if ! rpm -q httpd &>/dev/null; then
    dnf install -y httpd &>/dev/null
fi

# Create webdev user if not exists
if ! id webdev &>/dev/null; then
    useradd webdev
fi

# Create public_html with content
mkdir -p /home/webdev/public_html
echo "<html><body>USERDIR_WORKS</body></html>" > /home/webdev/public_html/index.html
chmod 711 /home/webdev
chmod 755 /home/webdev/public_html
chmod 644 /home/webdev/public_html/index.html

# Enable UserDir in Apache - modify the main userdir.conf
if grep -q "UserDir disabled$" /etc/httpd/conf.d/userdir.conf 2>/dev/null; then
    sed -i 's/UserDir disabled$/UserDir public_html/' /etc/httpd/conf.d/userdir.conf
    sed -i 's/Require method GET POST OPTIONS/Require all granted/' /etc/httpd/conf.d/userdir.conf
    systemctl reload httpd 2>/dev/null
fi

# Ensure httpd is running
systemctl is-active httpd &>/dev/null || systemctl start httpd &>/dev/null

# THE CHECKS
check 'curl -sf --max-time 3 http://127.0.0.1/~webdev/ 2>/dev/null | grep -q "USERDIR_WORKS"' \
    "Apache successfully serves user home directory content" \
    "UserDir access failing - 403 Forbidden (hint: check audit.log for AVC denials)"

check 'getsebool httpd_enable_homedirs 2>/dev/null | grep -q " on$"' \
    "Correct SELinux boolean is enabled" \
    "Required SELinux boolean is not enabled"

check 'semanage boolean -l 2>/dev/null | grep "httpd_enable_homedirs " | grep -qE "\(on[[:space:]]*,[[:space:]]*on\)"' \
    "Boolean is configured persistently" \
    "Boolean may not survive reboot (did you use -P?)"
