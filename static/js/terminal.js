/**
 * RHCSA Practice Labs - Terminal Integration
 * xterm.js terminal with Socket.IO backend
 */

// Note: cloudSession is defined in state.js

// Terminal-specific state
let termSocket = null;
let terminal = null;
let termFitAddon = null;
let termCurrentNode = 'node1';
let termRetryCount = 0;
let provisioningTimer = null;
let provisioningStartTime = null;
let sessionMonitorTimer = null;
let expiryWarningShown = false;  // Track if we've shown the 10-min warning

function initTerminal() {
    if (terminal) return;
    
    terminal = new Terminal({
        cursorBlink: true,
        fontSize: 13,
        fontFamily: '"Cascadia Code", "Fira Code", Menlo, Monaco, monospace',
        theme: {
            background: '#000000',
            foreground: '#ffffff',
            cursor: '#ffffff',
            selection: 'rgba(255, 255, 255, 0.3)',
        }
    });

    termFitAddon = new FitAddon.FitAddon();
    terminal.loadAddon(termFitAddon);
    terminal.open(document.getElementById('terminal'));
    termFitAddon.fit();

    // Handle input
    terminal.onData(data => {
        if (termSocket && termSocket.connected) {
            termSocket.emit('terminal_input', { data });
        }
    });

    // Handle resize
    window.addEventListener('resize', () => {
        if (termFitAddon && terminal) {
            termFitAddon.fit();
            if (termSocket && termSocket.connected) {
                termSocket.emit('terminal_resize', {
                    cols: terminal.cols,
                    rows: terminal.rows
                });
            }
        }
    });
}

function termUpdateStatus(status, color = 'gray') {
    const el = document.getElementById('term-status');
    if (el) {
        el.textContent = status;
        el.className = `text-xs text-${color}-500`;
    }
}

async function termConnectNode(node) {
    // Don't trust a possibly-stale cached cloudSession (e.g. set once on page
    // load, or never set if a session was created out-of-band via the API
    // rather than through this tab). Re-check with the server first.
    if (!cloudSession || !['ready', 'active'].includes(cloudSession.state)) {
        await checkCloudSession();
    }
    if (!cloudSession || !['ready', 'active'].includes(cloudSession.state)) {
        showToast('warning', 'No Cloud Session', 'Provision VMs first from Settings');
        return;
    }

    termCurrentNode = node;
    
    // Update tab UI
    document.getElementById('term-tab-node1').className = node === 'node1' 
        ? 'px-3 py-1 text-xs font-medium rounded-sm bg-primary text-white transition-colors'
        : 'px-3 py-1 text-xs font-medium rounded-sm bg-surface-dark text-gray-400 hover:text-white transition-colors';
    document.getElementById('term-tab-node2').className = node === 'node2' 
        ? 'px-3 py-1 text-xs font-medium rounded-sm bg-primary text-white transition-colors'
        : 'px-3 py-1 text-xs font-medium rounded-sm bg-surface-dark text-gray-400 hover:text-white transition-colors';

    // Initialize terminal if needed
    initTerminal();
    terminal.clear();
    terminal.write(`\r\nConnecting to ${node}...\r\n`);
    termUpdateStatus('Connecting...', 'amber');

    // Disconnect existing socket
    if (termSocket) {
        termSocket.disconnect();
    }

    // Connect to WebSocket
    termSocket = io('/terminal', {
        transports: ['polling', 'websocket']
    });

    termSocket.on('connect', () => {
        console.log('Socket connected, starting terminal...');
        termSocket.emit('start_session_terminal', {
            session_id: cloudSession.session_id,
            node: node,
            cols: terminal ? terminal.cols : 80,
            rows: terminal ? terminal.rows : 24
        });
    });

    termSocket.on('connect_error', (err) => {
        console.error('Socket connect_error:', err);
        termUpdateStatus('Connection failed', 'red');
        if (terminal) {
            terminal.write(`\r\n\x1b[31mError: Failed to connect to terminal server (${err && err.message ? err.message : err}).\x1b[0m\r\n`);
            terminal.write(`\r\n\x1b[33mTip: This can happen if the server is unreachable or rejected the connection (e.g. CORS). Check that you're accessing the app from an allowed origin and that the server is running, then click refresh.\x1b[0m\r\n`);
        }
    });

    termSocket.on('terminal_ready', (data) => {
        console.log('Terminal ready:', data);
        termRetryCount = 0; // Reset retry count on success
        termUpdateStatus(`${data.node} connected`, 'green');
        if (terminal) {
            terminal.clear();
            terminal.focus();
        }
    });

    termSocket.on('terminal_output', (data) => {
        if (terminal) {
            terminal.write(data.data);
        }
    });

    termSocket.on('terminal_error', (data) => {
        console.error('Terminal error:', data.error);
        const isConnectionError = data.error.includes('Failed to connect') || data.error.includes('timed out');
        
        if (isConnectionError && termRetryCount < 3) {
            termRetryCount++;
            termUpdateStatus(`Retrying (${termRetryCount}/3)...`, 'amber');
            if (terminal) {
                terminal.write(`\r\n\x1b[33mVM still booting, retrying in 10 seconds... (${termRetryCount}/3)\x1b[0m\r\n`);
            }
            setTimeout(() => termConnectNode(termCurrentNode), 10000);
        } else {
            termUpdateStatus('Error', 'red');
            termRetryCount = 0;
            if (terminal) {
                terminal.write(`\r\n\x1b[31mError: ${data.error}\x1b[0m\r\n`);
                if (isConnectionError) {
                    terminal.write(`\r\n\x1b[33mTip: VM may still be booting. Wait 30 seconds and click refresh.\x1b[0m\r\n`);
                }
            }
        }
    });

    termSocket.on('terminal_disconnected', (data) => {
        console.log('Terminal disconnected:', data);
        termUpdateStatus('Disconnected', 'gray');
    });

    termSocket.on('disconnect', () => {
        console.log('Socket disconnected');
        termUpdateStatus('Disconnected', 'gray');
    });
}

function termReconnect() {
    termConnectNode(termCurrentNode);
}

function termDisconnect() {
    if (termSocket) {
        termSocket.disconnect();
        termSocket = null;
    }
    termUpdateStatus('Disconnected', 'gray');
}

async function checkCloudSession() {
    try {
        // Get all sessions, not just active ones (to include pending/provisioning)
        const resp = await fetch('/api/sessions');
        const sessions = await resp.json();
        // Return the first non-terminated session
        cloudSession = sessions.find(s => !['terminated', 'failed'].includes(s.state)) || null;
        updateTerminalUI();
        
        // Check for expiry warning
        if (cloudSession && ['ready', 'active'].includes(cloudSession.state)) {
            checkSessionExpiry(cloudSession);
        }
        
        return cloudSession;
    } catch (e) {
        console.error('Failed to check cloud session:', e);
        cloudSession = null;
        updateTerminalUI();
        return null;
    }
}

function checkSessionExpiry(session) {
    // Local static VMs (Vagrant/libvirt) aren't billed cloud resources and
    // never expire, so there's no cost-control countdown or termination to
    // warn about. Skip the entire cloud-expiry flow for them.
    if (session.is_static) return;

    const timeRemaining = session.time_remaining_seconds;
    
    // Warning at 10 minutes
    if (timeRemaining <= 600 && timeRemaining > 0 && !expiryWarningShown) {
        expiryWarningShown = true;
        showExpiryWarning(Math.ceil(timeRemaining / 60));
    }
    
    // Session expired
    if (timeRemaining <= 0) {
        showToast('error', 'Session Expired', 'Your cloud session has been terminated.');
        expiryWarningShown = false;
        cloudSession = null;
        renderCloudSessionUI(null);
    }
}

function showExpiryWarning(minutesLeft) {
    const container = document.getElementById('toast-container');
    const toast = document.createElement('div');
    toast.id = 'expiry-warning-toast';
    toast.className = 'flex flex-col gap-3 p-4 rounded-lg border-l-4 border-amber-500 bg-amber-500/20 backdrop-blur-sm animate-fade-in';
    toast.innerHTML = `
        <div class="flex items-start gap-3">
            <span class="material-symbols-outlined text-amber-400">warning</span>
            <div>
                <p class="font-medium text-amber-200">Session Expiring Soon</p>
                <p class="text-sm text-amber-300/80">Your cloud session will terminate in ${minutesLeft} minutes.</p>
            </div>
        </div>
        <div class="flex gap-2 ml-9">
            <button onclick="extendCloudSession(); document.getElementById('expiry-warning-toast').remove();" 
                    class="px-3 py-1.5 rounded bg-amber-500 hover:bg-amber-400 text-black text-sm font-medium transition-all">
                Extend +30 min
            </button>
            <button onclick="document.getElementById('expiry-warning-toast').remove();"
                    class="px-3 py-1.5 rounded bg-white/10 hover:bg-white/20 text-white text-sm transition-all">
                Dismiss
            </button>
        </div>
    `;
    container.appendChild(toast);
}

function startSessionMonitor() {
    // Check session status every 30 seconds
    if (sessionMonitorTimer) clearInterval(sessionMonitorTimer);
    sessionMonitorTimer = setInterval(async () => {
        if (cloudSession && ['ready', 'active'].includes(cloudSession.state)) {
            await refreshCloudSessionUI();
        }
    }, 30000);  // Every 30 seconds
}

function stopSessionMonitor() {
    if (sessionMonitorTimer) {
        clearInterval(sessionMonitorTimer);
        sessionMonitorTimer = null;
    }
    expiryWarningShown = false;
}

// Provision (create + provision, in sequence) a session directly from the
// terminal panel, without navigating to Settings. Self-contained rather than
// reusing createCloudSession()/provisionCloudSession() from cloud.js, since
// those fire-and-forget their internal refreshCloudSessionUI() call and
// aren't safe to chain synchronously.
async function provisionInlineFromTerminal() {
    const btn = document.getElementById('inline-provision-btn');
    const label = document.getElementById('inline-provision-btn-label');
    if (btn) btn.disabled = true;

    try {
        // Reuse an existing pending/ready session if one's already there
        // instead of always creating a new one.
        await checkCloudSession();

        if (!cloudSession) {
            if (label) label.textContent = 'Creating session...';
            const createResp = await fetch('/api/sessions', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
            const created = await createResp.json();
            if (!createResp.ok) {
                showToast('error', 'Failed to create session', created.error || '');
                return;
            }
            cloudSession = created;
        }

        if (cloudSession.state === 'pending') {
            if (label) label.textContent = 'Provisioning...';
            showToast('info', 'Provisioning VM...', 'This is usually quick for local VMs');
            const provResp = await fetch(`/api/sessions/${cloudSession.session_id}/provision`, { method: 'POST' });
            const provisioned = await provResp.json();
            if (!provResp.ok || provisioned.error) {
                showToast('error', 'Provisioning failed', provisioned.error || '');
                return;
            }
            cloudSession = provisioned;
        }

        await checkCloudSession();

        if (cloudSession && ['ready', 'active'].includes(cloudSession.state)) {
            showToast('success', 'VM Ready', 'Connecting...');
            termConnectNode(termCurrentNode || 'node1');
        } else {
            showToast('warning', 'Not ready yet', `Session state: ${cloudSession?.state || 'unknown'}`);
        }
    } catch (e) {
        showToast('error', 'Error', e.message);
    } finally {
        if (btn) btn.disabled = false;
        if (label) label.textContent = 'Provision VM Now';
    }
}

function updateTerminalUI() {
    const container = document.getElementById('terminal-container');
    const unavailable = document.getElementById('terminal-unavailable');
    
    if (cloudSession && ['ready', 'active'].includes(cloudSession.state)) {
        container.classList.remove('hidden');
        unavailable.classList.add('hidden');
    } else {
        container.classList.add('hidden');
        unavailable.classList.remove('hidden');
    }
}
