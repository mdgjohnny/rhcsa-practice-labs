/**
 * RHCSA Practice Labs - Configuration API
 * VM configuration loading and saving
 */

async function loadConfig() {
    try {
        const res = await fetch('/api/config');
        const config = await res.json();
        document.getElementById('node1').value = config.node1 || 'rhcsa1';
        document.getElementById('node1_ip').value = config.node1_ip || '';
        document.getElementById('node2').value = config.node2 || 'rhcsa2';
        document.getElementById('node2_ip').value = config.node2_ip || '';
        cachedConfig = config;
    } catch (e) {
        showToast('error', 'Failed to load config', e.message);
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
    
    try {
        const res = await fetch('/api/config', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(config)
        });
        if (res.ok) {
            showToast('success', 'Configuration Saved');
            cachedConfig = config;
        } else {
            const err = await res.json();
            showToast('error', 'Save Failed', err.error);
        }
    } catch (e) {
        showToast('error', 'Save Failed', e.message);
    }
}

