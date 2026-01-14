#!/usr/bin/env bash
# Task: Apache has been configured as a reverse proxy to a backend service on port 8888, but connections are failing. The configuration and backend are correct - this is an SELinux issue. Diagnose the problem and fix it. The fix must persist across reboots. (Click "Check Task" to set up the scenario)
# Title: Troubleshoot Apache Reverse Proxy (SELinux)
# Category: security
# Target: node1

# Self-contained setup - creates the broken scenario
if ! rpm -q httpd &>/dev/null; then
    dnf install -y httpd &>/dev/null
fi

# Create proxy config if not exists
if [[ ! -f /etc/httpd/conf.d/backend-proxy.conf ]]; then
    cat > /etc/httpd/conf.d/backend-proxy.conf << 'PROXY'
# Proxy to backend app - this will fail until SELinux is fixed
<Location "/backend">
    ProxyPass "http://127.0.0.1:8888/"
    ProxyPassReverse "http://127.0.0.1:8888/"
</Location>
PROXY
    systemctl reload httpd 2>/dev/null
fi

# Create Python-based backend (more reliable than nc)
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

# Start backend if not running
if ! ss -tlnp 2>/dev/null | grep -q ':8888 '; then
    nohup /usr/local/bin/backend-server.py &>/dev/null &
    sleep 1
fi

# Ensure httpd is running
systemctl is-active httpd &>/dev/null || systemctl start httpd &>/dev/null

# THE CHECKS
check 'curl -sf --max-time 3 http://127.0.0.1/backend 2>/dev/null | grep -q "BACKEND_OK"' \
    "Apache successfully proxies to backend service" \
    "Proxy connection failing (hint: check /var/log/audit/audit.log)"

check 'getsebool httpd_can_network_connect 2>/dev/null | grep -q " on$"' \
    "Correct SELinux boolean is enabled" \
    "Required SELinux boolean is not enabled"

check 'semanage boolean -l 2>/dev/null | grep "httpd_can_network_connect " | grep -qE "\(on[[:space:]]*,[[:space:]]*on\)"' \
    "Boolean is configured persistently" \
    "Boolean may not survive reboot (did you use -P?)"
