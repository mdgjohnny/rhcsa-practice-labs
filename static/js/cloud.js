/**
 * RHCSA Practice Labs - Cloud Session Management
 * Oracle Cloud Infrastructure session lifecycle management
 */

async function refreshCloudSessionUI() {
    const session = await checkCloudSession();
    renderCloudSessionUI(session);
}

function renderCloudSessionUI(session) {
    const infoEl = document.getElementById('cloud-session-info');
    const ctrlEl = document.getElementById('cloud-session-controls');
    
    if (!infoEl || !ctrlEl) return;

    if (!session) {
        infoEl.innerHTML = `<p class="text-gray-400 text-sm">No active cloud session. Create one to get instant VMs.</p>`;
        ctrlEl.innerHTML = `
            <button onclick="createCloudSession()" class="px-5 py-2.5 rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-sm transition-all flex items-center gap-2">
                <span class="material-symbols-outlined text-lg">add_circle</span> Create Cloud Session
            </button>
        `;
    } else if (session.state === 'pending') {
        infoEl.innerHTML = `
            <p class="text-gray-400 text-sm">Session created. Click "Provision" to start VMs.</p>
            <p class="text-xs text-gray-500 mt-1">Session ID: ${session.session_id}</p>
        `;
        ctrlEl.innerHTML = `
            <button onclick="provisionCloudSession()" class="px-5 py-2.5 rounded-lg bg-primary hover:bg-primary-hover text-white font-bold text-sm transition-all flex items-center gap-2">
                <span class="material-symbols-outlined text-lg">rocket_launch</span> Provision VMs
            </button>
            <button onclick="destroyCloudSession()" class="px-5 py-2.5 rounded-lg border border-white/10 text-gray-400 hover:text-white hover:border-white/20 text-sm transition-all">
                Cancel
            </button>
        `;
    } else if (session.state === 'provisioning' || session.state === 'waiting_health') {
        // Calculate elapsed time from when provisioning started
        const startTime = provisioningStartTime || Date.now();
        const elapsed = Math.floor((Date.now() - startTime) / 1000);
        const elapsedMin = Math.floor(elapsed / 60);
        const elapsedSec = elapsed % 60;
        const elapsedStr = `${elapsedMin}:${String(elapsedSec).padStart(2, '0')}`;
        
        // Progress stages (waiting_health comes after VMs are up)
        let stage = 'Initializing';
        let progress = 10;
        if (session.state === 'waiting_health') {
            stage = 'Waiting for VMs to be ready';
            progress = 85;
        } else if (elapsed > 15) { stage = 'Creating network'; progress = 25; }
        if (elapsed > 30) { stage = 'Launching VMs'; progress = 45; }
        if (elapsed > 60) { stage = 'Configuring instances'; progress = 65; }
        if (elapsed > 90) { stage = 'Installing packages'; progress = 80; }
        if (elapsed > 120) { stage = 'Finalizing setup'; progress = 90; }
        
        infoEl.innerHTML = `
            <div class="space-y-3">
                <p class="text-amber-400 text-sm flex items-center gap-2">
                    <span class="animate-spin">⟳</span> Provisioning VMs...
                </p>
                <div class="w-full bg-gray-700 rounded-full h-2">
                    <div class="bg-primary h-2 rounded-full transition-all duration-500" style="width: ${progress}%"></div>
                </div>
                <div class="flex justify-between text-xs text-gray-500">
                    <span>${stage}</span>
                    <span>${elapsedStr} elapsed</span>
                </div>
                <p class="text-xs text-gray-500">Typically takes 1-2 minutes. Session: ${session.session_id.slice(-8)}</p>
            </div>
        `;
        ctrlEl.innerHTML = `
            <button onclick="destroyCloudSession()" class="text-xs text-gray-500 hover:text-red-400 transition-colors">
                Cancel provisioning
            </button>
        `;
    } else if (session.state === 'ready' || session.state === 'active') {
        // Local static VMs (Vagrant/libvirt) don't have a cost-control timeout,
        // so there's nothing to count down or extend against. Show a plain
        // "Local VM" status instead of the cloud time-remaining/extend UI.
        const timeRemaining = Math.max(0, Math.floor(session.time_remaining_seconds / 60));
        const statusCell = session.is_static
            ? `
                <div>
                    <p class="text-gray-500">Type</p>
                    <p class="text-white">Local VM</p>
                </div>
            `
            : `
                <div>
                    <p class="text-gray-500">Time Remaining</p>
                    <p class="text-white">${timeRemaining} minutes</p>
                </div>
            `;
        infoEl.innerHTML = `
            <div class="grid grid-cols-2 gap-4 text-sm">
                <div>
                    <p class="text-gray-500">Node 1 (rhcsa1)</p>
                    <p class="text-white font-mono">${session.node1_ip || 'N/A'}</p>
                </div>
                <div>
                    <p class="text-gray-500">Node 2 (rhcsa2)</p>
                    <p class="text-white font-mono">${session.node2_ip || 'N/A'}</p>
                </div>
                <div>
                    <p class="text-gray-500">Status</p>
                    <p class="text-emerald-400">● Ready</p>
                </div>
                ${statusCell}
            </div>
        `;
        // The "Extend +30min" button is meaningless for local static VMs
        // (nothing to extend against) - only render it for cloud sessions.
        const extendBtn = session.is_static
            ? ''
            : `
            <button onclick="extendCloudSession()" class="px-5 py-2.5 rounded-lg bg-white/5 hover:bg-white/10 text-white font-medium text-sm transition-all flex items-center gap-2">
                <span class="material-symbols-outlined text-lg">more_time</span> Extend +30min
            </button>`;
        ctrlEl.innerHTML = `${extendBtn}
            <button onclick="destroyCloudSession()" class="px-5 py-2.5 rounded-lg border border-red-500/50 text-red-400 hover:bg-red-500/10 text-sm transition-all flex items-center gap-2">
                <span class="material-symbols-outlined text-lg">delete</span> Destroy Session
            </button>
        `;
    } else if (session.state === 'failed') {
        infoEl.innerHTML = `
            <p class="text-red-400 text-sm">Session failed: ${session.error || 'Unknown error'}</p>
            <p class="text-xs text-gray-500 mt-1">Session ID: ${session.session_id}</p>
        `;
        ctrlEl.innerHTML = `
            <button onclick="destroyCloudSession()" class="px-5 py-2.5 rounded-lg border border-white/10 text-gray-400 hover:text-white text-sm transition-all">
                Clear Failed Session
            </button>
        `;
    }
}

async function createCloudSession() {
    try {
        showToast('info', 'Creating session...');
        const resp = await fetch('/api/sessions', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
        const data = await resp.json();
        if (resp.ok) {
            showToast('success', 'Session Created', 'Click Provision to start VMs');
            refreshCloudSessionUI();
        } else {
            showToast('error', 'Failed', data.error || 'Could not create session');
        }
    } catch (e) {
        showToast('error', 'Error', e.message);
    }
}

async function provisionCloudSession() {
    if (!cloudSession) return;
    const sessionId = cloudSession.session_id;
    
    showToast('info', 'Starting VM provisioning...', 'This takes 1-2 minutes');
    
    // Optimistically show provisioning state immediately
    cloudSession.state = 'provisioning';
    provisioningStartTime = Date.now(); // Global timer start
    renderCloudSessionUI(cloudSession);
    
    // Start timer to update UI every second
    if (provisioningTimer) clearInterval(provisioningTimer);
    provisioningTimer = setInterval(() => {
        // Continue timer for provisioning and waiting_health states
        if (cloudSession && (cloudSession.state === 'provisioning' || cloudSession.state === 'waiting_health')) {
            renderCloudSessionUI(cloudSession);
        } else {
            clearInterval(provisioningTimer);
            provisioningTimer = null;
        }
    }, 1000);
    
    // Start provisioning (don't await - let it run in background)
    fetch(`/api/sessions/${sessionId}/provision`, { method: 'POST' })
        .then(resp => resp.json())
        .then(data => {
            // Stop the timer
            if (provisioningTimer) { clearInterval(provisioningTimer); provisioningTimer = null; }
            provisioningStartTime = null;
            
            if (data.error) {
                showToast('error', 'Provisioning Failed', data.error);
                cloudSession.state = 'failed';
                stopSessionMonitor();
            } else {
                showToast('success', 'VMs Ready!', 'You can now use the terminal');
                cloudSession = data; // Update with actual data from server
                startSessionMonitor();  // Start monitoring for expiry
                expiryWarningShown = false;  // Reset warning flag
            }
            renderCloudSessionUI(cloudSession);
            updateTerminalUI();
        })
        .catch(e => {
            if (provisioningTimer) { clearInterval(provisioningTimer); provisioningTimer = null; }
            showToast('error', 'Error', e.message);
            refreshCloudSessionUI();
        });
}

async function destroyCloudSession() {
    if (!cloudSession) return;
    if (!confirm('Destroy this cloud session? All VMs will be terminated.')) return;
    
    const sessionId = cloudSession.session_id;
    
    // Immediately clear UI without re-fetching
    termDisconnect();
    stopSessionMonitor();  // Stop monitoring
    cloudSession = null;
    renderCloudSessionUI(null);  // Render empty state directly
    updateTerminalUI();
    showToast('info', 'Destroying session...', 'VMs are being terminated');
    
    // Destroy in background
    fetch(`/api/sessions/${sessionId}`, { method: 'DELETE' })
        .then(() => showToast('success', 'Session Destroyed'))
        .catch(e => showToast('error', 'Error destroying session', e.message));
}

function extendCloudSession() {
    if (!cloudSession) return;
    document.getElementById('extend-modal').classList.remove('hidden');
}

function hideExtendModal() {
    document.getElementById('extend-modal').classList.add('hidden');
}

async function doExtendSession(minutes) {
    if (!cloudSession) return;
    hideExtendModal();
    try {
        const resp = await fetch(`/api/sessions/${cloudSession.session_id}/extend`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ minutes })
        });
        if (resp.ok) {
            const hrs = Math.floor(minutes / 60);
            const mins = minutes % 60;
            const timeStr = hrs > 0 ? (mins > 0 ? `${hrs}h ${mins}m` : `${hrs} hour${hrs > 1 ? 's' : ''}`) : `${mins} minutes`;
            showToast('success', `Extended +${timeStr}`);
            expiryWarningShown = false;  // Reset so warning can show again
            refreshCloudSessionUI();
        } else {
            const data = await resp.json();
            showToast('error', 'Failed', data.error);
        }
    } catch (e) {
        showToast('error', 'Error', e.message);
    }
}

async function testConnection() {
    showToast('info', 'Testing connection...');
    try {
        const res = await fetch('/api/test-connection', { method: 'POST' });
        const result = await res.json();
        if (result.ok) {
            showToast('success', 'Connection OK', 'Both nodes are reachable');
        } else {
            showToast('warning', 'Connection Issues', 
                `Node1: ${result.node1 ? '✓' : '✗'}, Node2: ${result.node2 ? '✓' : '✗'}`);
        }
    } catch (e) {
        showToast('error', 'Connection Test Failed', e.message);
    }
}

// Reboot Modal
function showRebootModal() { document.getElementById('reboot-modal').classList.remove('hidden'); }
function hideRebootModal() { document.getElementById('reboot-modal').classList.add('hidden'); }

async function rebootNode(node) {
    const statusEl = document.getElementById(`status-${node}`);
    statusEl.textContent = 'Rebooting...';
    statusEl.className = 'text-xs text-amber-500';
    
    try {
        const res = await fetch('/api/reboot-vm', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ node })
        });
        const result = await res.json();
        if (result.online) {
            statusEl.textContent = 'Online';
            statusEl.className = 'text-xs text-emerald-500';
            showToast('success', `${node} Rebooted`, 'Node is back online');
        } else {
            statusEl.textContent = 'Offline';
            statusEl.className = 'text-xs text-red-500';
            showToast('error', 'Reboot Failed', result.message);
        }
    } catch (e) {
        statusEl.textContent = 'Error';
        statusEl.className = 'text-xs text-red-500';
        showToast('error', 'Reboot Failed', e.message);
    }
}

