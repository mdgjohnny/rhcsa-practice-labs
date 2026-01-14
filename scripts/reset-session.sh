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
echo "=== Updating session database ==="
cd ..

python3 << PYEOF
import sqlite3
from datetime import datetime, timedelta

session_id = "$SESSION_ID"
node1_ip = "$NODE1_IP"
node2_ip = "$NODE2_IP"
node1_private = "$NODE1_PRIVATE"
node2_private = "$NODE2_PRIVATE"

# Read SSH key
with open("$SSH_KEY_FILE", 'r') as f:
    ssh_key = f.read()

conn = sqlite3.connect('sessions.db')

# Delete any existing session with this ID
conn.execute("DELETE FROM sessions WHERE session_id = ?", (session_id,))

# Create new session
now = datetime.now()
expires = now + timedelta(hours=4)

conn.execute("""
    INSERT INTO sessions (session_id, state, created_at, expires_at, 
                         node1_ip, node2_ip, node1_private_ip, node2_private_ip, 
                         ssh_private_key)
    VALUES (?, 'ready', ?, ?, ?, ?, ?, ?, ?)
""", (session_id, now.isoformat(), expires.isoformat(), 
      node1_ip, node2_ip, node1_private, node2_private, ssh_key))

conn.commit()
conn.close()

print(f"Session '{session_id}' created successfully!")
print(f"Expires: {expires}")
PYEOF

echo ""
echo "=== Done! ==="
echo "Restart the app if needed: pkill -f 'python api/app_socketio.py' && python api/app_socketio.py &"
