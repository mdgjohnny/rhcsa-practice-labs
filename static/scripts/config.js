
// Config Functions

async function loadConfig() {
    try {
        const res = await fetch('/api/config');
        const config = await res.json();
        window.cachedConfig = config; // Cache for quick access

        document.getElementById('node1').value = config.node1 || 'rhcsa1';
        document.getElementById('node1_ip').value = config.node1_ip || '';
        document.getElementById('node2').value = config.node2 || 'rhcsa2';
        document.getElementById('node2_ip').value = config.node2_ip || '';
        // Password is not returned for security - show placeholder if set
        const pwField = document.getElementById('root_password');
        pwField.value = '';
        pwField.placeholder = config.has_password ? '••••••• (password set)' : 'VM root password';

        // Update header VM indicators
        document.getElementById('vm1-name').textContent = config.node1 || 'node1';
        document.getElementById('vm2-name').textContent = config.node2 || 'node2';
        document.getElementById('vm1-ip-display').textContent = config.node1_ip || '-';
        document.getElementById('vm2-ip-display').textContent = config.node2_ip || '-';
    } catch (e) {
        console.error('Failed to load config:', e);
    }
}

async function saveConfig() {
    const config = {
        node1: document.getElementById('node1').value,
        node1_ip: document.getElementById('node1_ip').value,
        node2: document.getElementById('node2').value,
        node2_ip: document.getElementById('node2_ip').value,
        root_password: document.getElementById('root_password').value
    };

    await fetch('/api/config', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(config)
    });

    // Update cache and header displays
    window.cachedConfig = config;
    document.getElementById('vm1-name').textContent = config.node1;
    document.getElementById('vm2-name').textContent = config.node2;
    document.getElementById('vm1-ip-display').textContent = config.node1_ip || '-';
    document.getElementById('vm2-ip-display').textContent = config.node2_ip || '-';

    document.getElementById('connection-result').innerHTML =
        '<div class="alert alert-info">Configuration saved.</div>';
}

async function refreshVmInfo() {
    // Test connection and update status
    try {
        const res = await fetch('/api/test-connection', { method: 'POST' });
        const data = await res.json();

        document.getElementById('vm1-status').className = 'dot ' + (data.node1 ? 'ok' : 'fail');
        document.getElementById('vm2-status').className = 'dot ' + (data.node2 ? 'ok' : 'fail');

        updateVmInfoModal();
        showToast('info', 'Status Refreshed', `Node 1: ${data.node1 ? 'Online' : 'Offline'}, Node 2: ${data.node2 ? 'Online' : 'Offline'}`);
    } catch (e) {
        showToast('error', 'Refresh Failed', 'Could not check VM status');
    }
}

async function discoverAndUpdateIps() {
    showToast('info', 'Discovering...', 'Attempting to discover VM IPs via virsh...');

    try {
        const res = await fetch('/api/discover-ips', { method: 'POST' });
        const data = await res.json();

        let message = '';

        if (data.node1_ip || data.node2_ip) {
            // Update config with discovered IPs
            const config = {
                node1: window.cachedConfig?.node1 || document.getElementById('node1')?.value || 'rhcsa1',
                node1_ip: data.node1_ip || window.cachedConfig?.node1_ip || '',
                node2: window.cachedConfig?.node2 || document.getElementById('node2')?.value || 'rhcsa2',
                node2_ip: data.node2_ip || window.cachedConfig?.node2_ip || '',
                root_password: '' // Don't overwrite password
            };

            await fetch('/api/config', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(config)
            });

            // Update local state
            window.cachedConfig = { ...window.cachedConfig, ...config };

            // Update header displays
            if (data.node1_ip) {
                document.getElementById('vm1-ip-display').textContent = data.node1_ip;
                // Update form field if on setup page
                const node1IpField = document.getElementById('node1_ip');
                if (node1IpField) node1IpField.value = data.node1_ip;
                message += `Node 1: ${data.node1_ip}`;
            }
            if (data.node2_ip) {
                document.getElementById('vm2-ip-display').textContent = data.node2_ip;
                // Update form field if on setup page
                const node2IpField = document.getElementById('node2_ip');
                if (node2IpField) node2IpField.value = data.node2_ip;
                message += message ? ', ' : '';
                message += `Node 2: ${data.node2_ip}`;
            }

            updateVmInfoModal();
            showToast('success', 'IPs Discovered', `${message} (via ${data.method})`);

            // Also refresh status
            refreshVmInfo();
        } else {
            showToast('warning', 'No IPs Found', 'Could not discover VM IPs. Make sure VMs are running and virsh is available.');
        }
    } catch (e) {
        console.error('IP discovery failed:', e);
        showToast('error', 'Discovery Failed', 'Could not discover IPs. Check if virsh is available.');
    }
}

async function quickTestConnection() {
    const btn = document.getElementById('refresh-conn-btn');
    if (btn.classList.contains('spinning')) return; // Already running

    btn.classList.add('spinning');

    // Set dots to gray/loading
    document.getElementById('vm1-status').className = 'dot';
    document.getElementById('vm2-status').className = 'dot';
    document.getElementById('vm1-status').style.backgroundColor = 'var(--text-muted)';
    document.getElementById('vm2-status').style.backgroundColor = 'var(--text-muted)';

    try {
        const res = await fetch('/api/test-connection', { method: 'POST' });
        const data = await res.json();

        // Clear manual styles
        document.getElementById('vm1-status').style.backgroundColor = '';
        document.getElementById('vm2-status').style.backgroundColor = '';

        document.getElementById('vm1-status').className = 'dot ' + (data.node1 ? 'ok' : 'fail');
        document.getElementById('vm2-status').className = 'dot ' + (data.node2 ? 'ok' : 'fail');

        if (data.node1 && data.node2) {
            showToast('success', 'Connected', 'VM connection verified.');
        } else {
            showToast('warning', 'Connection Issue', 'One or more VMs are unreachable.');
        }

    } catch (e) {
        showToast('error', 'Error', 'Failed to test connectivity.');
    } finally {
        setTimeout(() => btn.classList.remove('spinning'), 500);
    }
}

async function testConnection() {
    // Re-using the implementation below for the main Setup page "Test Connection" button
    const result = document.getElementById('connection-result');
    const node1Name = document.getElementById('node1').value || 'Node 1';
    const node2Name = document.getElementById('node2').value || 'Node 2';

    // Sleek loading state
    result.innerHTML = `
        <div style="display: flex; align-items: center; gap: 1rem; color: var(--text-muted); padding: 1rem; background: rgba(255,255,255,0.03); border-radius: 6px;">
            <div class="spinner-large" style="width: 20px; height: 20px; border-width: 2px;"></div>
            <span>Pinging VMs...</span>
        </div>
    `;

    try {
        const res = await fetch('/api/test-connection', { method: 'POST' });
        const data = await res.json();

        document.getElementById('vm1-status').className = 'dot ' + (data.node1 ? 'ok' : 'fail');
        document.getElementById('vm2-status').className = 'dot ' + (data.node2 ? 'ok' : 'fail');

        // Sleek result card
        const rowStyle = 'display: flex; align-items: center; justify-content: space-between; padding: 0.5rem 0;';
        const borderStyle = 'border-bottom: 1px solid rgba(255,255,255,0.05); margin-bottom: 0.5rem;';

        result.innerHTML = `
            <div style="margin-top: 0.5rem; padding: 1.25rem; background: var(--bg-card); border-radius: 8px; border: var(--glass-border); box-shadow: var(--shadow-md);">
                <div style="${rowStyle} ${borderStyle}">
                    <span style="color: var(--text-main); font-weight: 500;">${node1Name}</span>
                    <span style="display: flex; align-items: center; gap: 0.5rem; color: ${data.node1 ? 'var(--success)' : 'var(--error)'};">
                        ${data.node1 ? '✓ Online' : '✗ Unreachable'}
                    </span>
                </div>
                <div style="${rowStyle}">
                    <span style="color: var(--text-main); font-weight: 500;">${node2Name}</span>
                    <span style="display: flex; align-items: center; gap: 0.5rem; color: ${data.node2 ? 'var(--success)' : 'var(--error)'};">
                        ${data.node2 ? '✓ Online' : '✗ Unreachable'}
                    </span>
                </div>
            </div>
        `;

        if (data.node1 && data.node2) {
            showToast('success', 'Connected', 'Both VMs are online and reachable.');
        } else {
            showToast('warning', 'Connection Issue', 'One or more VMs are unreachable.');
        }

    } catch (e) {
        result.innerHTML = `
            <div style="margin-top: 0.5rem; padding: 1rem; background: rgba(239, 68, 68, 0.1); border: 1px solid var(--error); border-radius: 6px; color: var(--error);">
                ⚠ Integration Request Failed
            </div>
        `;
    }
}

// Helper for consistent VM checks across modes
async function checkVmReady() {
    try {
        // Use cached config if available
        let config = window.cachedConfig;
        if (!config) {
            const configRes = await fetch('/api/config');
            if (!configRes.ok) return false;
            config = await configRes.json();
            window.cachedConfig = config;
        }

        if (!config.node1_ip || !config.node2_ip || !config.has_password) {
            return { ready: false, reason: 'config' };
        }

        // Test connection
        const connRes = await fetch('/api/test-connection', { method: 'POST' });
        const data = await connRes.json();

        if (data.node1 && data.node2) {
            return { ready: true };
        } else {
            return { ready: false, reason: 'connection' };
        }

    } catch (e) {
        console.error('VM Ready check failed:', e);
        return { ready: false, reason: 'error' };
    }
}
