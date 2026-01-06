
// Exam & Practice Logic

// --- Starting Modes ---

function selectMode(mode) {
    window.currentMode = mode;
    showView(mode === 'practice' ? 'practice-setup' : 'exam-setup');
}

function startPractice() {
    const ids = getSelectedTaskIds();
    if (ids.length === 0) {
        showToast('warning', 'No Tasks Selected', 'Please select at least one task to practice.');
        return;
    }
    window.selectedTasks = window.allTasks.filter(t => ids.includes(t.id));
    document.getElementById('breadcrumb-mode').textContent = 'Practice';
    startExamView(window.selectedTasks, false);
}

async function startExam() {
    const count = parseInt(document.getElementById('exam-task-count').value) || 15;

    // Verify VMs first (User Request)
    showToast('info', 'Preparing Exam', 'Verifying VM connectivity...');
    const vmStatus = await checkVmReady();

    if (!vmStatus.ready) {
        if (vmStatus.reason === 'config') {
            showToast('warning', 'Setup Required', 'Please configure VMs before starting the exam.');
            showView('setup');
        } else {
            showToast('error', 'Connection Failed', 'Cannot reach VMs. Please ensure they are running.');
            // Optional: Allow override? For now, enforcing as requested.
        }
        return;
    }

    try {
        const res = await fetch(`/api/random-tasks?count=${count}`);
        const tasks = await res.json();
        window.selectedTasks = tasks;
        document.getElementById('breadcrumb-mode').textContent = 'Exam';
        startExamView(tasks, true);
    } catch (e) {
        showToast('error', 'Exam Generation Failed', 'Failed to generate questions for exam mode. Check server logs.');
    }
}

function startCategoryPractice(category) {
    window.selectedTasks = window.allTasks.filter(t => t.category === category);
    window.currentMode = 'practice';
    window.currentTaskIndex = 0;

    document.getElementById('breadcrumb-mode').textContent = `Practice: ${category.replace(/-/g, ' ')}`;

    window.taskResults.clear(); // Reset grading state
    renderTaskSidebar();
    showView('exam-running');
    document.getElementById('exam-sidebar').classList.remove('hidden');

    // Auto-select first task
    if (window.selectedTasks.length > 0) {
        showTaskDetail(window.selectedTasks[0].id);
        updateTaskNavigation();
    }
}

async function startQuickPractice() {
    // 1. Check Config SILENTLY first to avoid showing loading screen if unconfigured
    try {
        let config = window.cachedConfig;

        // Fetch if not cached
        if (!config) {
            const configRes = await fetch('/api/config');
            if (!configRes.ok) throw new Error('Config fetch failed');
            config = await configRes.json();
            window.cachedConfig = config;
        }

        // Simple validation check
        if (!config.node1_ip || !config.node2_ip) {
            showView('setup');
            showToast('info', 'Setup Required', 'Please configure your laboratory VMs first to start practicing.');
            return;
        }
    } catch (e) {
        console.error('Quick Practice init failed:', e);
        // If checking config fails, assume setup needed
        showView('setup');
        showToast('warning', 'Config Check Failed', 'Could not verify VM configuration. Please check settings.');
        return;
    }

    // 2. Config is present, proceed with connection flow
    showView('connecting');

    // Reset UI
    const spinner = document.getElementById('connecting-spinner');
    const title = document.getElementById('connecting-title');

    if (spinner) {
        spinner.className = 'spinner-large';
        spinner.innerHTML = '';
        spinner.style.color = '';
    }
    if (title) {
        title.textContent = 'Initializing Environment';
        title.style.color = '';
    }

    document.querySelectorAll('.step-item').forEach(el => {
        el.className = 'step-item pending';
        el.querySelector('.step-icon').textContent = '○';
    });
    document.getElementById('connect-error-actions').classList.add('hidden');

    const updateStep = (id, status) => {
        const el = document.getElementById(id);
        if (el) {
            el.className = `step-item ${status}`;
            const icon = el.querySelector('.step-icon');
            if (status === 'active') icon.innerHTML = '<span class="step-spinner"></span>';
            if (status === 'done') icon.textContent = '✓';
            if (status === 'fail') icon.textContent = '✗';
        }
    };

    updateStep('step-tasks', 'active');

    try {
        // 1. Load Tasks
        await new Promise(r => setTimeout(r, 400)); // Min wait for UX
        if (window.allTasks.length === 0) {
            const res = await fetch('/api/tasks');
            if (!res.ok) throw new Error('Failed to load tasks');
            window.allTasks = await res.json();
        }
        updateStep('step-tasks', 'done');

        // 2. Check Config
        updateStep('step-config', 'active');
        await new Promise(r => setTimeout(r, 400));

        // Use cached config if available, or fetch
        let config = window.cachedConfig;
        if (!config) {
            const configRes = await fetch('/api/config');
            config = await configRes.json();
            window.cachedConfig = config;
        }

        if (!config.node1_ip || !config.node2_ip || !config.has_password) {
            updateStep('step-config', 'fail');
            document.getElementById('connect-error-msg').textContent = 'VMs are not configured.';
            document.getElementById('connect-error-actions').classList.remove('hidden');
            return;
        }
        updateStep('step-config', 'done');

        // 3. Test Connection (Parallel)
        updateStep('step-node1', 'active');
        updateStep('step-node2', 'active');

        const p1 = fetch('/api/test-connection', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ target: 'node1' })
        }).then(r => r.json()).then(d => {
            if (d.node1) updateStep('step-node1', 'done');
            else updateStep('step-node1', 'fail');
            return d.node1;
        }).catch(() => {
            updateStep('step-node1', 'fail');
            return false;
        });

        const p2 = fetch('/api/test-connection', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ target: 'node2' })
        }).then(r => r.json()).then(d => {
            if (d.node2) updateStep('step-node2', 'done');
            else updateStep('step-node2', 'fail');
            return d.node2;
        }).catch(() => {
            updateStep('step-node2', 'fail');
            return false;
        });

        const [r1, r2] = await Promise.all([p1, p2]);

        // Result Logic
        if (r1 && r2) {
            // Success!
            window.vmsConfigured = true; // Not strictly needed globally but good for state
            window.selectedTasks = window.allTasks;
            window.currentMode = 'practice';
            document.getElementById('breadcrumb-mode').textContent = 'Quick Practice';

            // Tiny delay to see the checkmarks
            setTimeout(() => {
                startExamView(window.selectedTasks, false);
            }, 500);
        } else {
            // FAILURE STATE
            const spinner = document.getElementById('connecting-spinner');
            const title = document.getElementById('connecting-title');

            if (spinner) {
                spinner.className = ''; // Remove spinner class to stop spinning
                spinner.innerHTML = '✗'; // Large X
                spinner.style.fontSize = '4rem';
                spinner.style.color = 'var(--rh-red)';
                spinner.style.lineHeight = '1';
            }
            if (title) {
                title.textContent = 'Connection Failed';
                title.style.color = 'var(--rh-red)';
            }

            document.getElementById('connect-error-msg').textContent = 'Could not connect to one or more VMs.';
            document.getElementById('connect-error-actions').classList.remove('hidden');
        }

    } catch (e) {
        console.error(e);
        updateStep('step-tasks', 'fail');
        document.getElementById('connect-error-msg').textContent = 'System error occurred: ' + e.message;
        document.getElementById('connect-error-actions').classList.remove('hidden');
    }
}

function startExamView(tasks, timed) {
    // Reset task index and results
    window.currentTaskIndex = 0;
    window.taskResults.clear();
    // Collapse all categories by default for cleaner view
    window.collapsedCategories.clear();
    const allCategories = [...new Set(window.selectedTasks.map(t => t.category))];
    allCategories.forEach(c => window.collapsedCategories.add(c));
    document.getElementById('toggle-collapse').textContent = 'Expand All';

    // Reset Random Sort Mode
    window.randomSortMode = false;
    document.getElementById('toggle-sort-random').classList.remove('active');

    // Show exam UI
    showView('exam-running');
    document.getElementById('exam-sidebar').classList.remove('hidden');

    if (timed) {
        document.getElementById('timer').classList.remove('hidden');
        startTimer();
    } else {
        document.getElementById('timer').classList.add('hidden');
    }

    // Populate sidebar
    renderTaskSidebar();

    // Show first task and init navigation
    if (tasks.length > 0) {
        showTaskDetail(tasks[0].id);
        updateTaskNavigation();
    }

    // Save session for resume capability
    saveSession();
}


// --- Sidebar & Navigation ---

function renderTaskSidebar() {
    const sidebar = document.getElementById('sidebar-task-list');
    const jumpSelect = document.getElementById('task-jump');
    const searchTerm = document.getElementById('task-search')?.value?.toLowerCase() || '';

    // Handle Random/Flat Sort
    if (window.randomSortMode) {
        renderTaskSidebarFlat(sidebar, searchTerm);
    } else {
        renderTaskSidebarCategorized(sidebar, searchTerm);
    }

    // Update jump-to dropdown
    jumpSelect.innerHTML = '<option value="">Jump to task...</option>' +
        window.selectedTasks.map((t, i) => `<option value="${i}">${i + 1}. ${t.id}</option>`).join('');

    // Update counts
    updateGradedCount();
}

function renderTaskSidebarFlat(sidebar, searchTerm) {
    const compactClass = window.compactMode ? 'compact' : '';

    const filteredTasks = window.selectedTasks.map((t, i) => ({ ...t, index: i })).filter(t =>
        t.description.toLowerCase().includes(searchTerm) ||
        t.id.toLowerCase().includes(searchTerm) ||
        t.category.toLowerCase().includes(searchTerm)
    );

    if (filteredTasks.length === 0) {
        sidebar.innerHTML = '<div class="loading">No matching tasks</div>';
        return;
    }

    const html = filteredTasks.map(t => {
        const result = window.taskResults.get(t.id);
        const statusClass = result ? (result.passed ? 'task-passed' : 'task-failed') : '';
        return `
              <div class="task-item task-list-item ${compactClass} ${statusClass} ${t.index === window.currentTaskIndex ? 'active' : ''}" 
                   data-id="${t.id}" data-index="${t.index}" onclick="selectTaskFromSidebar(${t.index})">
                  <div class="task-number">${t.index + 1}</div>
                  <div class="task-info">
                      <div class="task-title">${t.description}</div>
                      ${!window.compactMode ? `<div class="task-category"><span style="margin-right:0.5rem; opacity:0.7;">${t.category}</span><span class="task-target ${t.target || 'node1'}">${t.target || 'node1'}</span></div>` : ''}
                  </div>
              </div>
          `;
    }).join('');

    sidebar.innerHTML = `<div class="task-category-items">${html}</div>`;
}

function renderTaskSidebarCategorized(sidebar, searchTerm) {
    // Group tasks by category
    const categories = {};
    window.selectedTasks.forEach((t, i) => {
        if (!categories[t.category]) categories[t.category] = [];
        categories[t.category].push({ ...t, index: i });
    });

    // Filter tasks based on search
    const filteredCategories = {};
    for (const [cat, tasks] of Object.entries(categories)) {
        const filtered = tasks.filter(t =>
            t.description.toLowerCase().includes(searchTerm) ||
            t.id.toLowerCase().includes(searchTerm) ||
            cat.toLowerCase().includes(searchTerm)
        );
        if (filtered.length > 0) {
            filteredCategories[cat] = filtered;
        }
    }

    // Render grouped tasks
    const compactClass = window.compactMode ? 'compact' : '';
    let html = '';
    for (const [cat, tasks] of Object.entries(filteredCategories).sort((a, b) => a[0].localeCompare(b[0]))) {
        const isCollapsed = window.collapsedCategories.has(cat);
        html += `
            <div class="task-category-group" data-category="${cat}">
                <div class="task-category-header ${isCollapsed ? 'collapsed' : ''}" onclick="toggleCategory('${cat}')">
                    <span class="arrow">▼</span>
                    <span>${cat.replace(/-/g, ' ')}</span>
                    <span class="cat-count">${tasks.length}</span>
                </div>
                <div class="task-category-items ${isCollapsed ? 'hidden' : ''}">
                    ${tasks.map(t => {
            const result = window.taskResults.get(t.id);
            const statusClass = result ? (result.passed ? 'task-passed' : 'task-failed') : '';
            return `
                        <div class="task-item task-list-item ${compactClass} ${statusClass} ${t.index === window.currentTaskIndex ? 'active' : ''}" 
                             data-id="${t.id}" data-index="${t.index}" onclick="selectTaskFromSidebar(${t.index})">
                            <div class="task-number">${t.index + 1}</div>
                            <div class="task-info">
                                <div class="task-title">${t.description}</div>
                                ${!window.compactMode ? `<div class="task-category"><span class="task-target ${t.target || 'node1'}">${t.target || 'node1'}</span></div>` : ''}
                            </div>
                        </div>
                    `}).join('')}
                </div>
            </div>
        `;
    }
    sidebar.innerHTML = html || '<div class="loading">No matching tasks</div>';
}

function toggleSortMode() {
    window.randomSortMode = !window.randomSortMode;
    const btn = document.getElementById('toggle-sort-random');
    if (btn) btn.classList.toggle('active', window.randomSortMode);

    // Store current Task ID to maintain selection
    const currentTaskId = window.selectedTasks[window.currentTaskIndex].id;

    if (window.randomSortMode) {
        // Shuffle selectedTasks
        // Fisher-Yates shuffle
        for (let i = window.selectedTasks.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [window.selectedTasks[i], window.selectedTasks[j]] = [window.selectedTasks[j], window.selectedTasks[i]];
        }
    } else {
        // Sort by Category + ID
        window.selectedTasks.sort((a, b) => {
            const catCompare = a.category.localeCompare(b.category);
            if (catCompare !== 0) return catCompare;
            return a.id.localeCompare(b.id, undefined, { numeric: true });
        });
    }

    // Find new index
    window.currentTaskIndex = window.selectedTasks.findIndex(t => t.id === currentTaskId);
    if (window.currentTaskIndex === -1) window.currentTaskIndex = 0;

    saveSession();
    renderTaskSidebar();
    updateTaskNavigation();

    // Don't need to reload details if ID is same, but nav buttons update
}

function selectTaskFromSidebar(index) {
    window.currentTaskIndex = index;
    showTaskDetail(window.selectedTasks[index].id);
    updateTaskNavigation();
    document.querySelectorAll('.task-list-item').forEach((el, i) => {
        el.classList.toggle('active', i === index);
    });
    // In flat mode, make sure we update correctly
}

function showTaskDetail(taskId) {
    const task = window.allTasks.find(t => t.id === taskId);
    if (!task) return;

    // Update sidebar selection visual (safeguard)
    document.querySelectorAll('.task-list-item').forEach(el => {
        el.classList.toggle('active', el.dataset.id === taskId);
    });

    const target = task.target || 'node1';
    const targetLabel = target === 'both' ? 'node1 & node2' : target;

    document.getElementById('current-task-detail').innerHTML = `
        <div class="card">
            <h2>${task.id}</h2>
            <p style="font-size: 1.1rem; line-height: 1.6;">${task.description}</p>
            <p class="mt-1" style="display: flex; align-items: center; gap: 1rem;">
                <span style="color: var(--rh-cyan);">Category: ${task.category}</span>
                <span style="color: var(--rh-gray-light);">|</span>
                <span>Default Target: <span class="task-target ${target}" style="font-size: 0.8rem;">${targetLabel}</span></span>
            </p>
            <div class="mt-2" style="display: flex; align-items: center; gap: 1rem; flex-wrap: wrap;">
                <label style="display: flex; align-items: center; gap: 0.5rem;">
                    <span style="color: var(--rh-gray-light); font-size: 0.9rem;">Grade on:</span>
                    <select id="grade-vm-select" style="padding: 0.5rem; background: var(--rh-black); border: 1px solid var(--rh-gray); color: white; border-radius: 4px;">
                        <option value="default" ${target === 'node1' ? 'selected' : ''}>Default (${targetLabel})</option>
                        <option value="node1">node1 only</option>
                        <option value="node2">node2 only</option>
                        <option value="both">both VMs</option>
                    </select>
                </label>
                <button class="btn btn-primary" onclick="gradeCurrentTask('${task.id}')" id="grade-task-btn">
                    ✓ Grade This Task
                </button>
                <span id="task-grade-result"></span>
            </div>
        </div>
    `;

    // Check if checks exist for this task? 
    // (We could check if taskResults has a result and show it immediately)
    const priorResult = window.taskResults.get(taskId);
    if (priorResult) {
        const resultEl = document.getElementById('task-grade-result');
        if (priorResult.passed) {
            resultEl.innerHTML = `<span style="color: var(--rh-green);">✓ Passed (${priorResult.points}/${priorResult.maxPoints} pts)</span>`;
        } else {
            resultEl.innerHTML = `<span style="color: var(--rh-red);">✗ Failed (${priorResult.points}/${priorResult.maxPoints} pts)</span>`;
        }
    }
}

function navigateTask(direction) {
    const newIndex = window.currentTaskIndex + direction;
    if (newIndex >= 0 && newIndex < window.selectedTasks.length) {
        window.currentTaskIndex = newIndex;
        showTaskDetail(window.selectedTasks[window.currentTaskIndex].id);
        updateTaskNavigation();
        saveSession(); // Persist current position

        // Update sidebar highlight
        document.querySelectorAll('.task-list-item').forEach((el, i) => {
            el.classList.toggle('active', i === window.currentTaskIndex);
        });

        // Scroll sidebar to item
        const activeItem = document.querySelector('.task-list-item.active');
        if (activeItem) {
            activeItem.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
        }
    }
}

function updateTaskNavigation() {
    const prevBtn = document.getElementById('prev-task-btn');
    const nextBtn = document.getElementById('next-task-btn');
    const indicator = document.getElementById('task-nav-indicator');

    if (prevBtn) prevBtn.disabled = window.currentTaskIndex === 0;
    if (nextBtn) nextBtn.disabled = window.currentTaskIndex === window.selectedTasks.length - 1;
    if (indicator) indicator.textContent = `Task ${window.currentTaskIndex + 1} of ${window.selectedTasks.length}`;
}

function jumpToTask() {
    const select = document.getElementById('task-jump');
    const index = parseInt(select.value);
    if (!isNaN(index)) {
        selectTaskFromSidebar(index);
        select.value = ''; // Reset dropdown
    }
}

// --- Grading ---

async function gradeCurrentTask(taskId) {
    const btn = document.getElementById('grade-task-btn');
    const resultEl = document.getElementById('task-grade-result');
    const vmSelect = document.getElementById('grade-vm-select');
    const selectedVm = vmSelect ? vmSelect.value : 'default';

    btn.disabled = true;
    btn.textContent = 'Grading...';
    resultEl.innerHTML = '<span style="color: var(--rh-gray-light);">Checking...</span>';

    // Verify VMs first
    const vmStatus = await checkVmReady();
    if (!vmStatus.ready) {
        const msg = vmStatus.reason === 'config'
            ? 'VMs not configured'
            : 'VMs unreachable';
        resultEl.innerHTML = `<span style="color: var(--rh-red);">✗ ${msg}</span>`;
        showToast('error', 'Grading Failed', msg);
        btn.disabled = false;
        btn.textContent = '✓ Grade This Task';
        return;
    }

    try {
        const url = selectedVm === 'default'
            ? `/api/grade-task/${taskId}`
            : `/api/grade-task/${taskId}?target=${selectedVm}`;
        const res = await fetch(url, { method: 'POST' });
        const result = await res.json();

        if (result.error) {
            resultEl.innerHTML = `<span style="color: var(--rh-red);">✗ Error: ${result.message}</span>`;
            showToast('error', 'Grading Failed', result.message);
        } else if (result.passed) {
            resultEl.innerHTML = `
                <span style="color: var(--rh-green);">✓ ALL PASSED (${result.points}/${result.max_points} pts)</span>
                <div style="font-size: 0.85rem; margin-top: 0.5rem; color: var(--rh-gray-light);">
                    ${result.details ? result.details.join('<br>') : ''}
                </div>
            `;
            showToast('success', 'Task Passed!', `${taskId}: ${result.checks_passed}/${result.checks_total} checks passed`);
            updateTaskStatus(taskId, true, result.points, result.max_points);
        } else {
            resultEl.innerHTML = `
                <span style="color: var(--rh-red);">✗ ${result.checks_passed}/${result.checks_total} checks passed (${result.points}/${result.max_points} pts)</span>
                <div style="font-size: 0.85rem; margin-top: 0.5rem; color: var(--rh-gray-light);">
                    ${result.details ? result.details.join('<br>') : ''}
                </div>
            `;
            showToast('warning', 'Task Not Complete', `${result.checks_passed}/${result.checks_total} checks passed`);
            updateTaskStatus(taskId, false, result.points, result.max_points);
        }
    } catch (e) {
        resultEl.innerHTML = `<span style="color: var(--rh-red);">✗ Connection error</span>`;
        showToast('error', 'Connection Error', 'Failed to reach grading server.');
    }

    btn.disabled = false;
    btn.textContent = '✓ Grade This Task';
}

function updateTaskStatus(taskId, passed, points = 0, maxPoints = 0) {
    // Track result
    window.taskResults.set(taskId, { passed, points, maxPoints, graded: true });

    // Update sidebar task item to show pass/fail status
    const taskItem = document.querySelector(`.task-item[data-id="${taskId}"]`);
    if (taskItem) {
        taskItem.classList.remove('task-passed', 'task-failed');
        taskItem.classList.add(passed ? 'task-passed' : 'task-failed');
    }

    // Update graded count and save session
    updateGradedCount();
    saveSession();
}

function updateGradedCount() {
    const gradedCount = window.taskResults.size;
    const totalCount = window.selectedTasks.length;
    const pct = totalCount > 0 ? (gradedCount / totalCount * 100) : 0;

    const gc = document.getElementById('graded-count');
    if (gc) gc.textContent = gradedCount;
    const tt = document.getElementById('total-task-count');
    if (tt) tt.textContent = totalCount;
    const gp = document.getElementById('graded-progress');
    if (gp) gp.style.width = pct + '%';
    const tc = document.getElementById('task-count');
    if (tc) tc.textContent = `${gradedCount}/${totalCount}`;
}

// --- Submit & Results ---

// ESC key handler for canceling grading
function handleGradingEsc(e) {
    if (e.key === 'Escape') {
        abortGrading();
    }
}

function abortGrading() {
    window.gradingAborted = true;
    document.getElementById('grading-status').textContent = 'Cancelling...';
    document.getElementById('cancel-grading-btn').disabled = true;
}

async function submitExam() {
    stopTimer();
    window.gradingAborted = false; // Reset abort flag
    const duration = window.examStartTime ? Math.floor((Date.now() - window.examStartTime) / 1000) : null;
    const modal = document.getElementById('grading-modal');
    const taskList = document.getElementById('grading-task-list');
    const progressFill = document.getElementById('grading-progress-fill');
    const statusEl = document.getElementById('grading-status');
    const cancelBtn = document.getElementById('cancel-grading-btn');
    const spinner = document.getElementById('grading-spinner');
    const titleEl = document.getElementById('grading-title');

    // Reset modal UI
    cancelBtn.disabled = false;
    cancelBtn.textContent = 'Cancel Grading';
    spinner.style.display = 'block';
    titleEl.textContent = 'Preparing to Grade';

    // Show modal
    taskList.innerHTML = '<div style="text-align: center; padding: 2rem; color: var(--rh-gray-light);">Preparing...</div>';
    modal.classList.remove('hidden');
    progressFill.style.width = '0%';
    statusEl.textContent = 'Verifying VM connectivity...';

    // Add ESC key listener
    document.addEventListener('keydown', handleGradingEsc);

    // FAIL-FAST: Check connectivity before attempting long reboots
    const preCheck = await checkVmReady();
    if (!preCheck.ready || window.gradingAborted) {
        if (window.gradingAborted) {
            showToast('warning', 'Cancelled', 'Grading cancelled.');
        } else {
            const msg = 'VMs are unreachable. Cannot proceed with grading.';
            statusEl.innerHTML = `<span style="color: var(--rh-red);">✗ ${msg}</span>`;
            showToast('error', 'Grading Failed', msg);
        }
        await new Promise(r => setTimeout(r, 2000));
        modal.classList.add('hidden');
        document.removeEventListener('keydown', handleGradingEsc);
        return;
    }

    statusEl.textContent = 'Rebooting VMs to ensure configs survive...';

    // Reboot both VMs in parallel before grading
    try {
        // Progress Animation for Reboot
        let p = 0;
        const rebootInterval = setInterval(() => {
            if (window.gradingAborted) return;
            p += 0.5; // Slow increment
            if (p > 95) p = 95;

            // Update bar
            progressFill.style.width = p + '%';

            // Update text based on progress
            if (p < 15) statusEl.textContent = 'Sending reboot signals to VMs...';
            else if (p < 40) statusEl.textContent = 'Systems are ensuring configurations persist...';
            else if (p < 70) statusEl.textContent = 'Waiting for SSH services to come back online...';
            else statusEl.textContent = 'Finalizing connection establishment...';
        }, 100); // Update every 100ms

        // Execute reboots
        const rebootPromises = Promise.all([
            fetch('/api/reboot-vm', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ node: 'node1' })
            }).then(r => r.json()).catch(() => ({ ok: false })),
            fetch('/api/reboot-vm', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ node: 'node2' })
            }).then(r => r.json()).catch(() => ({ ok: false }))
        ]);

        // Minimum wait time for realism and to ensure VMs actually go down/up (15s minimum)
        const waitPromise = new Promise(resolve => setTimeout(resolve, 15000));

        const [[r1, r2]] = await Promise.all([rebootPromises, waitPromise]);

        clearInterval(rebootInterval);

        if (window.gradingAborted) {
            document.removeEventListener('keydown', handleGradingEsc);
            modal.classList.add('hidden');
            showToast('warning', 'Cancelled', 'Grading cancelled during reboot.');
            return;
        }

        if (!r1.ok || !r2.ok) {
            // Build specific error message
            const failures = [];
            if (!r1.ok) failures.push(`Node1: ${r1.message || 'failed to come back online (timeout)'}`);
            if (!r2.ok) failures.push(`Node2: ${r2.message || 'failed to come back online (timeout)'}`);
            statusEl.innerHTML = `<span style="color: var(--rh-orange);">⚠ Reboot issues:</span><br>${failures.join('<br>')}`;
            progressFill.style.width = '100%';
            progressFill.style.backgroundColor = 'var(--rh-orange)';
            await new Promise(r => setTimeout(r, 4000));

            // Abort grading on reboot failure
            showToast('error', 'Grading Aborted', 'VMs failed to come back online.');
            modal.classList.add('hidden');
            document.removeEventListener('keydown', handleGradingEsc);
            return;
        } else {
            statusEl.textContent = 'VMs rebooted successfully. Starting grading...';
            progressFill.style.width = '100%';
            await new Promise(r => setTimeout(r, 1000));
        }

        // Reset for grading
        progressFill.style.backgroundColor = 'var(--primary-color)'; // Reset color
        progressFill.style.width = '0%';

    } catch (e) {
        statusEl.innerHTML = '<span style="color: var(--rh-red);">Could not reboot VMs. Aborting...</span>';
        await new Promise(r => setTimeout(r, 3000));
        modal.classList.add('hidden');
        document.removeEventListener('keydown', handleGradingEsc);
        showToast('error', 'Grading Error', 'Failed to reboot VMs.');
        return;
    }

    if (window.gradingAborted) {
        document.removeEventListener('keydown', handleGradingEsc);
        modal.classList.add('hidden');
        showToast('warning', 'Cancelled', 'Grading cancelled.');
        return;
    }

    // Now show task list and begin grading
    titleEl.textContent = 'Grading in Progress';
    taskList.innerHTML = window.selectedTasks.map((t, i) => `
        <div class="grading-task-item pending" data-task-id="${t.id}">
            <div class="icon">○</div>
            <span class="task-name">${i + 1}. ${t.description}</span>
        </div>
    `).join('');
    statusEl.textContent = `Grading ${window.selectedTasks.length} tasks in parallel...`;

    // Grade all tasks in parallel with real-time UI updates
    const results = [];
    let totalScore = 0;
    let totalPoints = 0;
    let completedCount = 0;
    let cancelled = false;

    // Mark all tasks as grading
    window.selectedTasks.forEach(task => {
        const taskEl = taskList.querySelector(`[data-task-id="${task.id}"]`);
        taskEl.className = 'grading-task-item grading';
        taskEl.querySelector('.icon').textContent = '◐';
    });

    // Create all grading promises
    const gradingPromises = window.selectedTasks.map(async (task, i) => {
        const taskEl = taskList.querySelector(`[data-task-id="${task.id}"]`);

        try {
            const res = await fetch(`/api/grade-task/${task.id}`, { method: 'POST' });
            const result = await res.json();

            const passed = result.passed || false;
            const points = result.points || 0;
            const maxPoints = result.max_points || 0;

            // Update totals atomically
            totalScore += points;
            totalPoints += maxPoints;

            // Update task status in modal immediately
            taskEl.className = `grading-task-item ${passed ? 'passed' : 'failed'}`;
            taskEl.querySelector('.icon').textContent = passed ? '✓' : '✗';

            // Track result
            window.taskResults.set(task.id, { passed, points, maxPoints, graded: true });
            results.push({
                task: task.id,
                check: task.description,
                category: task.category,
                passed,
                points: maxPoints
            });

            return { success: true, passed, points, maxPoints };

        } catch (e) {
            taskEl.className = 'grading-task-item failed';
            taskEl.querySelector('.icon').textContent = '!';
            results.push({
                task: task.id,
                check: task.description,
                category: task.category,
                passed: false,
                points: 0
            });
            return { success: false };
        } finally {
            // Update progress bar as each task completes
            completedCount++;
            const pct = (completedCount / window.selectedTasks.length) * 100;
            progressFill.style.width = pct + '%';
            statusEl.textContent = `Graded ${completedCount} of ${window.selectedTasks.length} tasks...`;
        }
    });

    // Wait for all grading to complete
    await Promise.all(gradingPromises);

    // Remove ESC key listener
    document.removeEventListener('keydown', handleGradingEsc);

    if (window.gradingAborted) {
        cancelled = true;
    }

    if (cancelled) {
        // Grading was cancelled (though parallel grading completes quickly)
        spinner.style.display = 'none';
        titleEl.textContent = 'Grading Cancelled';
        statusEl.textContent = `Graded ${completedCount} of ${window.selectedTasks.length} tasks.`;
        cancelBtn.textContent = 'Close';
        cancelBtn.disabled = false;
        cancelBtn.onclick = () => {
            modal.classList.add('hidden');
            renderTaskSidebar(); // Update sidebar with partial results
        };
        showToast('warning', 'Grading Cancelled', `Graded ${completedCount} of ${window.selectedTasks.length} tasks.`);
        return;
    }

    statusEl.textContent = 'Grading complete! Preparing results...';

    // Build final result object
    const finalResult = {
        score: totalScore,
        total: totalPoints,
        passed: totalScore >= (totalPoints * 0.7),
        checks: results,
        categories: {}
    };

    // Calculate category stats
    results.forEach(r => {
        if (!finalResult.categories[r.category]) {
            finalResult.categories[r.category] = { earned: 0, possible: 0 };
        }
        if (r.passed) finalResult.categories[r.category].earned += r.points;
        finalResult.categories[r.category].possible += r.points;
    });

    // Save result
    try {
        await fetch('/api/results', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ ...finalResult, mode: window.currentMode, duration_seconds: duration })
        });
    } catch (e) {
        console.error('Failed to save results:', e);
    }

    // Brief pause to show completion
    await new Promise(r => setTimeout(r, 500));
    modal.classList.add('hidden');

    sessionStorage.clear(); // Clear session on completion
    displayResults(finalResult);
}

function confirmAbandon() {
    if (confirm('Are you sure you want to abandon this exam? Your progress will be lost.')) {
        stopTimer();
        window.taskResults.clear();
        showView('mode-select');
    }
}

function displayResults(result) {
    document.getElementById('exam-sidebar').classList.add('hidden');
    document.getElementById('timer').classList.add('hidden');

    showView('results');

    const pct = Math.round((result.score / result.total) * 100);
    document.getElementById('result-score').textContent = result.score;
    document.getElementById('result-total').textContent = result.total;
    document.getElementById('result-pct').textContent = pct + '%';
    document.getElementById('result-status').textContent = result.passed ? 'PASSED' : 'FAILED';

    const scoreBox = document.getElementById('result-score-box');
    const statusBox = document.getElementById('result-status-box');
    scoreBox.className = 'result-box ' + (result.passed ? 'passed' : 'failed');
    statusBox.className = 'result-box ' + (result.passed ? 'passed' : 'failed');

    document.getElementById('check-results').innerHTML = result.checks.map(c => `
        <div class="check-item ${c.passed ? 'passed' : 'failed'}">
            <div class="icon">${c.passed ? '✓' : '✗'}</div>
            <div class="text">${c.check}</div>
            <div class="category">${c.category}</div>
        </div>
    `).join('');
}

// Timer
function startTimer() {
    window.examStartTime = Date.now();
    const timerEl = document.getElementById('timer');

    if (window.timerInterval) clearInterval(window.timerInterval);

    window.timerInterval = setInterval(() => {
        const elapsed = Date.now() - window.examStartTime;
        const remaining = Math.max(0, window.EXAM_DURATION - elapsed);

        if (remaining <= 0) {
            stopTimer();
            submitExam();
            return;
        }

        const hrs = Math.floor(remaining / 3600000);
        const mins = Math.floor((remaining % 3600000) / 60000);
        const secs = Math.floor((remaining % 60000) / 1000);

        timerEl.textContent = `${hrs.toString().padStart(2, '0')}:${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;

        timerEl.classList.remove('warning', 'critical');
        if (remaining < 300000) timerEl.classList.add('critical');
        else if (remaining < 900000) timerEl.classList.add('warning');
    }, 1000);
}

function stopTimer() {
    if (window.timerInterval) {
        clearInterval(window.timerInterval);
        window.timerInterval = null;
    }
}
