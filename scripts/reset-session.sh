#!/bin/bash
# Reset session after VM recreation
# Usage: ./reset-session.sh [session_id]

set -e

cd "$(dirname "$0")/.."
SESSION_ID="${1:-manual-reset}"
SSH_KEY_FILE="${HOME}/.ssh/rhcsa_practice_key"

echo "=== Getting VM IPs from Terraform ==="
cd infra
NODE1_IP=$(terraform output -raw node1_public_ip 2>/dev/null)
NODE2_IP=$(terraform output -raw node2_public_ip 2>/dev/null)
NODE1_PRIVATE=$(terraform output -raw node1_private_ip 2>/dev/null)
NODE2_PRIVATE=$(terraform output -raw node2_private_ip 2>/dev/null)

if [ -z "$NODE1_IP" ] || [ -z "$NODE2_IP" ]; then
    echo "ERROR: Could not get VM IPs from terraform. Run 'terraform apply' first."
    exit 1
fi

echo "Node1: $NODE1_IP (private: $NODE1_PRIVATE)"
echo "Node2: $NODE2_IP (private: $NODE2_PRIVATE)"

echo ""
echo "=== Testing SSH connectivity ==="
ssh -i "$SSH_KEY_FILE" -o ConnectTimeout=5 -o StrictHostKeyChecking=no opc@$NODE1_IP 'hostname' || {
    echo "ERROR: Cannot SSH to node1"
    exit 1
}
ssh -i "$SSH_KEY_FILE" -o ConnectTimeout=5 -o StrictHostKeyChecking=no opc@$NODE2_IP 'hostname' || {
    echo "ERROR: Cannot SSH to node2"  
    exit 1
}
echo "SSH OK"

echo ""
echo "=== Updating static_vms.json ==="
cd ..
cat > static_vms.json << VMSJSON
{
    "enabled": true,
    "node1_ip": "$NODE1_IP",
    "node2_ip": "$NODE2_IP",
    "node1_private_ip": "$NODE1_PRIVATE",
    "node2_private_ip": "$NODE2_PRIVATE",
    "ssh_private_key_path": "$SSH_KEY_FILE"
}
VMSJSON
echo "Updated static_vms.json"
cat static_vms.json

echo ""
echo "=== Updating session database ==="

python3 << PYEOF
import sqlite3
import sys
from datetime import datetime, timedelta

# Add api to path for imports
sys.path.insert(0, 'api')

session_id = "$SESSION_ID"
node1_ip = "$NODE1_IP"
node2_ip = "$NODE2_IP"
node1_private = "$NODE1_PRIVATE"
node2_private = "$NODE2_PRIVATE"

# Read SSH key
with open("$SSH_KEY_FILE", 'r') as f:
    ssh_key = f.read()

# Encrypt the key for consistency with normal sessions
try:
    from oci_manager.session_manager import KeyEncryption
    key_encryption = KeyEncryption()
    encrypted_key = key_encryption.encrypt(ssh_key)
    print("SSH key encrypted successfully")
except Exception as e:
    print(f"Warning: Could not encrypt key ({e}), storing unencrypted")
    encrypted_key = ssh_key

conn = sqlite3.connect('sessions.db')

# Delete any existing session with this ID
conn.execute("DELETE FROM sessions WHERE session_id = ?", (session_id,))

# Also terminate any other active sessions (since VMs changed)
conn.execute("UPDATE sessions SET state = 'terminated' WHERE state IN ('ready', 'pending', 'provisioning')")

# Create new session
now = datetime.now()
expires = now + timedelta(hours=4)

conn.execute("""
    INSERT INTO sessions (session_id, state, created_at, expires_at, 
                         node1_ip, node2_ip, node1_private_ip, node2_private_ip, 
                         ssh_private_key)
    VALUES (?, 'ready', ?, ?, ?, ?, ?, ?, ?)
""", (session_id, now.isoformat(), expires.isoformat(), 
      node1_ip, node2_ip, node1_private, node2_private, encrypted_key))

conn.commit()
conn.close()

print(f"Session '{session_id}' created successfully!")
print(f"Expires: {expires}")
PYEOF

echo ""
echo "=== Done! ==="
echo ""
echo "IMPORTANT: Restart the app to pick up new static_vms.json:"
echo "  pkill -f 'python api/app_socketio.py'"
echo "  cd ~/rhcsa-practice-labs && python api/app_socketio.py > /tmp/app.log 2>&1 &"
