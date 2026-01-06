
// UI Functions

// How-To Toggle
// How-To Toggle
window.toggleHowTo = function () {
    const howToContent = document.getElementById('howto-content');
    const configContent = document.getElementById('config-content');

    // Close others
    if (configContent && configContent.classList.contains('active')) {
        configContent.classList.remove('active');
    }

    if (howToContent) {
        howToContent.classList.toggle('active');

        // Scroll to view if opened
        if (howToContent.classList.contains('active')) {
            setTimeout(() => howToContent.scrollIntoView({ behavior: 'smooth', block: 'center' }), 300);
        }
    }
}

// Config Toggle (Inline)
window.toggleConfig = function () {
    const configContent = document.getElementById('config-content');
    const howToContent = document.getElementById('howto-content');

    // Close others
    if (howToContent && howToContent.classList.contains('active')) {
        howToContent.classList.remove('active');
    }

    // Ensure we are on home view
    const currentView = document.querySelector('.content-body:not(.hidden)');
    if (currentView && currentView.id !== 'view-welcome') {
        goHome();
        // Small delay to allow view render before animating
        setTimeout(() => {
            if (configContent) configContent.classList.add('active');
        }, 50);
    } else {
        if (configContent) configContent.classList.toggle('active');
    }

    // Scroll to view if opened
    if (configContent && configContent.classList.contains('active')) {
        setTimeout(() => configContent.scrollIntoView({ behavior: 'smooth', block: 'center' }), 300);
    }
}

// View Management
function goHome() {
    // No confirmation needed as progress is preserved
    const examSidebar = document.getElementById('exam-sidebar');
    if (examSidebar && !examSidebar.classList.contains('hidden')) {
        stopTimer();
    }
    showView('welcome');
}

function showView(viewId) {
    // Track previous view for back navigation
    const currentView = document.querySelector('.content-body:not(.hidden)');
    if (currentView) {
        window.previousView = currentView.id.replace('view-', '');
    }

    document.querySelectorAll('.content-body').forEach(v => v.classList.add('hidden'));
    document.getElementById(`view-${viewId}`).classList.remove('hidden');

    // Hide exam UI elements when not in exam
    if (viewId !== 'exam-running') {
        const sidebar = document.getElementById('exam-sidebar');
        if (sidebar) sidebar.classList.add('hidden');
        const timer = document.getElementById('timer');
        if (timer) timer.classList.add('hidden');
    }

    // Load data for specific views
    if (viewId === 'practice-setup') loadTasks();
    if (viewId === 'practice-category') populateCategoryGrid();
    if (viewId === 'stats') loadStats();
    if (viewId === 'welcome') checkForSavedSession();
}

// Mode Selection
function selectMode(mode) {
    window.currentMode = mode;
    showView(mode === 'practice' ? 'practice-setup' : 'exam-setup');
}

// Category Grid
function populateCategoryGrid() {
    const grid = document.getElementById('category-grid');
    if (!window.allTasks.length) {
        fetch('/api/tasks')
            .then(res => res.json())
            .then(tasks => {
                window.allTasks = tasks;
                renderCategoryGrid();
            });
    } else {
        renderCategoryGrid();
    }
}

function renderCategoryGrid() {
    const grid = document.getElementById('category-grid');
    const categories = {};
    window.allTasks.forEach(t => {
        if (!categories[t.category]) categories[t.category] = 0;
        categories[t.category]++;
    });

    grid.innerHTML = Object.entries(categories)
        .sort((a, b) => a[0].localeCompare(b[0]))
        .map(([cat, count]) => `
            <div class="category-card" onclick="startCategoryPractice('${cat}')">
                <h4>${cat.replace(/-/g, ' ')}</h4>
                <span class="task-count">${count} task${count !== 1 ? 's' : ''}</span>
            </div>
        `).join('');
}

// Loading Tasks & Practice Setup
async function loadTasks() {
    try {
        const res = await fetch('/api/tasks');
        window.allTasks = await res.json();

        // Populate category filter
        const categories = [...new Set(window.allTasks.map(t => t.category))].sort();
        const filter = document.getElementById('category-filter');
        const currentVal = filter.value;

        filter.innerHTML = '<option value="">All Categories</option>' +
            categories.map(c => `<option value="${c}">${c}</option>`).join('');

        if (currentVal) filter.value = currentVal;

        // Initial render
        updatePracticeSetupList();

        return true;
    } catch (e) {
        console.error('Failed to load tasks:', e);
        return false;
    }
}

// Enhanced Practice Setup Logic (Filtering & Sorting)
function updatePracticeSetupList() {
    const cat = document.getElementById('category-filter')?.value || '';
    const searchText = document.getElementById('task-filter-text')?.value?.toLowerCase() || '';
    const sortMode = document.getElementById('task-sort-mode')?.value || 'id';

    let filtered = window.allTasks;

    // Filter by Category
    if (cat) {
        filtered = filtered.filter(t => t.category === cat);
    }

    // Filter by Search Text (ID or Description)
    if (searchText) {
        filtered = filtered.filter(t =>
            t.description.toLowerCase().includes(searchText) ||
            t.id.toLowerCase().includes(searchText)
        );
    }

    // Sort
    filtered.sort((a, b) => {
        if (sortMode === 'category') {
            const catCompare = a.category.localeCompare(b.category);
            if (catCompare !== 0) return catCompare;
            // secondary sort by id
            return a.id.localeCompare(b.id, undefined, { numeric: true });
        } else {
            // Sort by ID
            return a.id.localeCompare(b.id, undefined, { numeric: true });
        }
    });

    renderTaskCheckboxes(filtered);
}

function renderTaskCheckboxes(tasks) {
    const list = document.getElementById('task-checkbox-list');
    if (tasks.length === 0) {
        list.innerHTML = '<div class="loading">No matching tasks found</div>';
        return;
    }

    list.innerHTML = tasks.map(t => {
        const target = t.target || 'node1';
        return `
        <label class="task-checkbox-item">
            <input type="checkbox" value="${t.id}">
            <span class="desc"><strong>${t.id}:</strong> ${t.description}</span>
            <span class="task-target ${target}">${target}</span>
            <span class="cat">${t.category}</span>
        </label>
    `}).join('');
}

function selectAllTasks() {
    document.querySelectorAll('#task-checkbox-list input').forEach(cb => cb.checked = true);
}

function deselectAllTasks() {
    document.querySelectorAll('#task-checkbox-list input').forEach(cb => cb.checked = false);
}

function getSelectedTaskIds() {
    return [...document.querySelectorAll('#task-checkbox-list input:checked')].map(cb => cb.value);
}

function filterByCategory() {
    updatePracticeSetupList();
}


// Sidebar Toggles
function toggleCompactMode() {
    window.compactMode = !window.compactMode;
    document.getElementById('toggle-compact').classList.toggle('active', window.compactMode);
    renderTaskSidebar();
}

function toggleAllCategories() {
    const categories = [...new Set(window.selectedTasks.map(t => t.category))];
    const allCollapsed = categories.every(c => window.collapsedCategories.has(c));

    if (allCollapsed) {
        window.collapsedCategories.clear();
        document.getElementById('toggle-collapse').textContent = 'Collapse All';
    } else {
        categories.forEach(c => window.collapsedCategories.add(c));
        document.getElementById('toggle-collapse').textContent = 'Expand All';
    }
    renderTaskSidebar();
}

function filterSidebarTasks() {
    renderTaskSidebar();
}

function toggleCategory(cat) {
    if (window.collapsedCategories.has(cat)) {
        window.collapsedCategories.delete(cat);
    } else {
        window.collapsedCategories.add(cat);
    }
    renderTaskSidebar();
}


// VM Info Modal Functions
function showVmInfoModal() {
    const modal = document.getElementById('vm-info-modal');
    modal.classList.remove('hidden');
    updateVmInfoModal();
}

function hideVmInfoModal() {
    document.getElementById('vm-info-modal').classList.add('hidden');
}

function updateVmInfoModal() {
    const config = window.cachedConfig || {};
    const node1Name = config.node1 || 'node1';
    const node2Name = config.node2 || 'node2';
    const node1Ip = config.node1_ip || '-';
    const node2Ip = config.node2_ip || '-';

    document.getElementById('vm-info-name1').textContent = node1Name;
    document.getElementById('vm-info-name2').textContent = node2Name;
    document.getElementById('vm-info-ip1').textContent = node1Ip;
    document.getElementById('vm-info-ip2').textContent = node2Ip;

    // SSH commands
    const ssh1 = node1Ip !== '-' ? `ssh root@${node1Ip}` : '-';
    const ssh2 = node2Ip !== '-' ? `ssh root@${node2Ip}` : '-';
    document.getElementById('vm-info-ssh1').textContent = ssh1;
    document.getElementById('vm-info-ssh2').textContent = ssh2;

    // Copy status from header indicators
    const status1 = document.getElementById('vm1-status').className;
    const status2 = document.getElementById('vm2-status').className;
    document.getElementById('vm-info-status1').className = status1;
    document.getElementById('vm-info-status2').className = status2;
    document.getElementById('vm-info-status1').style.backgroundColor = document.getElementById('vm1-status').style.backgroundColor;
    document.getElementById('vm-info-status2').style.backgroundColor = document.getElementById('vm2-status').style.backgroundColor;
}

// Reboot Modal Functions
let pendingReboot = null;

function showRebootModal() {
    document.getElementById('reboot-modal').classList.remove('hidden');
    // Reset states
    ['node1', 'node2'].forEach(node => {
        resetCardState(node);
    });
    document.getElementById('status-both').textContent = '';
    pendingReboot = null;

    // Add ESC listener
    document.addEventListener('keydown', handleRebootEsc);
}

function hideRebootModal() {
    document.getElementById('reboot-modal').classList.add('hidden');
    document.removeEventListener('keydown', handleRebootEsc);
}

function handleRebootEsc(e) {
    if (e.key === 'Escape') hideRebootModal();
}

function resetCardState(node) {
    const card = document.getElementById(`card-${node}`);
    const status = document.getElementById(`status-${node}`);
    const progress = document.getElementById(`progress-${node}`);

    card.className = 'reboot-target-card';
    status.textContent = 'Ready';
    status.style.color = 'var(--rh-gray-light)';
    if (progress) progress.style.width = '0%';
}

async function rebootNode(target) {
    // Confirmation Logic
    if (pendingReboot !== target) {
        // Reset others
        if (pendingReboot && pendingReboot !== target) {
            if (pendingReboot === 'both') {
                // Reset global button state if needed, though simpler to just ignore
            } else {
                // Don't fully reset if it's currently rebooting
                const card = document.getElementById(`card-${pendingReboot}`);
                if (!card.classList.contains('rebooting')) {
                    resetCardState(pendingReboot);
                }
            }
        }

        pendingReboot = target;

        if (target === 'both') {
            const statusBoth = document.getElementById('status-both');
            statusBoth.innerHTML = '<span style="color: var(--rh-orange); font-weight: bold;">Click again to confirm rebooting BOTH nodes</span>';
        } else {
            const card = document.getElementById(`card-${target}`);
            if (card.classList.contains('rebooting')) return; // Already going

            const status = document.getElementById(`status-${target}`);
            card.classList.add('confirming');
            status.innerHTML = '<span style="color: var(--rh-orange); font-weight: bold;">Click to Confirm</span>';
        }
        return;
    }

    // Confirmed - Proceed
    pendingReboot = null;

    const nodes = target === 'both' ? ['node1', 'node2'] : [target];

    // Update UI to show rebooting state
    nodes.forEach(node => {
        const card = document.getElementById(`card-${node}`);
        const status = document.getElementById(`status-${node}`);

        card.classList.remove('confirming');
        card.classList.add('rebooting', 'active');
        status.textContent = 'Starting...';
    });

    if (target === 'both') {
        document.getElementById('status-both').textContent = 'Waiting for systems to come back online...';
    }

    // Progress Animation Loop
    const progressIntervals = {};
    nodes.forEach(node => {
        let p = 0;
        const progressEl = document.getElementById(`progress-${node}`);
        const statusEl = document.getElementById(`status-${node}`);

        progressIntervals[node] = setInterval(() => {
            p += 1;
            if (p > 95) p = 95; // Hold at 95% until done
            progressEl.style.width = p + '%';

            // Cycle messages
            if (p < 20) statusEl.textContent = 'Sending signal...';
            else if (p < 50) statusEl.textContent = 'System restarting...';
            else if (p < 80) statusEl.textContent = 'Waiting for SSH...';
            else statusEl.textContent = 'Finalizing...';
        }, 600); // ~60 seconds to reach 95%
    });

    try {
        // Execute reboots in parallel
        const promises = nodes.map(async (node) => {
            try {
                const res = await fetch('/api/reboot-vm', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ node })
                });
                const data = await res.json();
                return { node, ok: data.ok, message: data.message };
            } catch (e) {
                return { node, ok: false, message: 'Network error' };
            }
        });

        const results = await Promise.all(promises);

        // Update UI with results
        results.forEach(result => {
            clearInterval(progressIntervals[result.node]);

            const card = document.getElementById(`card-${result.node}`);
            const status = document.getElementById(`status-${result.node}`);
            const progress = document.getElementById(`progress-${result.node}`);

            card.classList.remove('rebooting', 'active');
            progress.style.width = '100%';

            if (result.ok) {
                card.classList.add('success');
                status.textContent = '✓ Online';
                status.style.color = 'var(--rh-green)';
            } else {
                card.classList.add('error');
                status.textContent = '✗ Failed';
                status.style.color = 'var(--rh-red)';
            }
        });

        // Final status message
        const allOk = results.every(r => r.ok);
        if (target === 'both') {
            const statusBoth = document.getElementById('status-both');
            if (allOk) {
                statusBoth.textContent = '✓ All systems online';
                statusBoth.style.color = 'var(--rh-green)';
                showToast('success', 'Reboot Complete', 'Both VMs are back online.');
            } else {
                statusBoth.textContent = '⚠ Some systems failed to return';
                statusBoth.style.color = 'var(--rh-orange)';
                showToast('warning', 'Reboot Partial', 'Some VMs did not come back online.');
            }
        } else {
            if (allOk) {
                showToast('success', 'Reboot Complete', `${target} is back online.`);
            } else {
                showToast('error', 'Reboot Failed', `${target} failed to come back online.`);
            }
        }

    } catch (e) {
        console.error('Reboot error:', e);
        showToast('error', 'System Error', 'An error occurred during the reboot process.');

        // Cleanup on error
        nodes.forEach(node => {
            clearInterval(progressIntervals[node]);
            const card = document.getElementById(`card-${node}`);
            const status = document.getElementById(`status-${node}`);
            card.className = 'reboot-target-card error';
            status.textContent = 'Error';
        });
    }
}


// Stats Functions
async function loadStats() {
    const summaryEl = document.getElementById('stats-summary');
    const weakAreasEl = document.getElementById('weak-areas');
    const categoryStatsEl = document.getElementById('category-stats');

    try {
        const endpoint = '/api/stats';
        const res = await fetch(endpoint);
        const stats = await res.json();

        // Check if database is empty
        if (!stats.total_attempts || stats.total_attempts === 0) {
            summaryEl.innerHTML = `
                <div class="alert alert-info" style="grid-column: 1 / -1; text-align: center;">
                    <p style="font-size: 1.1rem; margin-bottom: 0.5rem;">No practice sessions yet</p>
                    <p style="color: var(--rh-gray-light);">Complete a practice or exam session to start tracking your progress.</p>
                </div>
            `;
            weakAreasEl.innerHTML = '<p style="color: var(--rh-gray-light)">Complete some practice sessions to see weak areas.</p>';
            categoryStatsEl.innerHTML = '<p style="color: var(--rh-gray-light)">No data yet.</p>';
            return;
        }

        summaryEl.innerHTML = `
            <div class="result-box">
                <div class="value">${stats.total_attempts}</div>
                <div class="label">Attempts</div>
            </div>
            <div class="result-box">
                <div class="value">${stats.passed}</div>
                <div class="label">Passed</div>
            </div>
            <div class="result-box">
                <div class="value">${stats.pass_rate}%</div>
                <div class="label">Pass Rate</div>
            </div>
        `;

        // Show weak areas as a simple recommendation
        if (stats.weak_areas.length > 0) {
            const weakNames = stats.weak_areas.map(w => `<strong>${w.category.replace(/-/g, ' ')}</strong> (${w.percentage}%)`).join(', ');
            weakAreasEl.innerHTML = `
                <div style="display: flex; align-items: flex-start; gap: 0.75rem;">
                    <span style="color: var(--rh-orange); font-size: 1.2rem;">💡</span>
                    <div>
                        <div style="color: var(--rh-orange); font-weight: 600; margin-bottom: 0.25rem;">Focus Areas</div>
                        <div style="color: var(--rh-gray-light); font-size: 0.9rem;">
                            Practice these categories to improve: ${weakNames}
                        </div>
                    </div>
                </div>
            `;
        } else {
            weakAreasEl.innerHTML = '';
        }

        // Sort: tested categories first (by percentage desc), then untested
        const sortedCats = Object.entries(stats.categories).sort((a, b) => {
            if (a[1].tested && !b[1].tested) return -1;
            if (!a[1].tested && b[1].tested) return 1;
            return b[1].percentage - a[1].percentage;
        });
        categoryStatsEl.innerHTML = sortedCats.length ?
            sortedCats.map(([cat, s]) => {
                if (!s.tested) {
                    return `
                        <div class="category-bar" style="opacity: 0.5;">
                            <div class="header">
                                <span class="name">${cat.replace(/-/g, ' ')}</span>
                                <span class="pct" style="color: var(--rh-gray-light);">Not tested</span>
                            </div>
                            <div class="progress-track">
                                <div class="progress-fill" style="width: 0%"></div>
                            </div>
                        </div>
                    `;
                }
                const cls = s.percentage >= 70 ? 'good' : s.percentage >= 50 ? 'ok' : 'bad';
                return `
                    <div class="category-bar">
                        <div class="header">
                            <span class="name">${cat.replace(/-/g, ' ')}</span>
                            <span class="pct ${cls}">${s.percentage}%</span>
                        </div>
                        <div class="progress-track">
                            <div class="progress-fill ${cls}" style="width: ${s.percentage}%"></div>
                        </div>
                    </div>
                `;
            }).join('') : '<p style="color: var(--rh-gray-light)">No data yet.</p>';
    } catch (e) {
        console.error('Failed to load stats:', e);
        summaryEl.innerHTML = `
            <div class="alert alert-warning" style="grid-column: 1 / -1;">
                Failed to load statistics. Please try again later.
            </div>
        `;
        weakAreasEl.innerHTML = '';
        categoryStatsEl.innerHTML = '';
    }
}

async function clearAllResults() {
    if (!confirm('Are you sure you want to delete all practice history? This cannot be undone.')) {
        return;
    }

    try {
        const res = await fetch('/api/results', { method: 'DELETE' });
        const data = await res.json();

        if (data.status === 'cleared') {
            showToast('success', 'History Cleared', `Deleted ${data.deleted} result(s).`);
            loadStats(); // Refresh the stats view
        } else {
            showToast('error', 'Error', 'Failed to clear history.');
        }
    } catch (e) {
        showToast('error', 'Connection Error', 'Failed to reach server.');
    }
}
