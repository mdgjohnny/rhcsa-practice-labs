/**
 * RHCSA Practice Labs - Practice/Exam/Challenge Mode
 * Mode selection, grading, results, and session management
 */

function selectMode(mode) {
    currentMode = mode;
    if (mode === 'exam') {
        showView('exam-setup');
    } else {
        showView('practice-setup');
    }
}

function startPractice() {
    const taskIds = getSelectedTaskIds();
    if (!taskIds.length) {
        showToast('warning', 'No tasks selected', 'Please select at least one task');
        return;
    }
    const catOrder = sortByExamOrder([...new Set(allTasks.map(t => t.category).filter(Boolean))]);
    selectedTasks = allTasks.filter(t => taskIds.includes(t.id)).sort((a, b) => {
        const ca = catOrder.indexOf(a.category);
        const cb = catOrder.indexOf(b.category);
        if (ca !== cb) return ca - cb;
        return (a.id || '').localeCompare(b.id || '', undefined, { numeric: true });
    });
    taskResults.clear();
    currentTaskIndex = 0;
    document.getElementById('breadcrumb-mode').textContent = 'Practice';
    populateSidebarCategoryFilter();
    renderTaskList();
    showTaskDetail(selectedTasks[0].id);
    updateTaskNavigation();
    showView('exam-running');
    saveSession();
}

async function startExam() {
    const count = parseInt(document.getElementById('exam-task-count').value) || 15;
    examDuration = 3 * 60 * 60 * 1000; // Reset to 3 hours for exam
    try {
        const res = await fetch(`/api/random-tasks?count=${count}`);
        selectedTasks = await res.json();
        taskResults.clear();
        currentTaskIndex = 0;
        examStartTime = Date.now();
        startTimer();
        document.getElementById('breadcrumb-mode').textContent = 'Exam';
        populateSidebarCategoryFilter();
        renderTaskList();
        showTaskDetail(selectedTasks[0].id);
        updateTaskNavigation();
        showView('exam-running');
        saveSession();
    } catch (e) {
        showToast('error', 'Failed to start exam', e.message);
    }
}

// Challenge Mode Functions
function setChallengePreset(tasks, minutes, el) {
    document.getElementById('challenge-task-count').value = tasks;
    document.getElementById('challenge-time-limit').value = minutes;
    // Visual feedback
    document.querySelectorAll('.preset-btn').forEach(btn => btn.classList.remove('border-amber-500', 'bg-amber-500/10'));
    if (el) el.closest('.preset-btn').classList.add('border-amber-500', 'bg-amber-500/10');
}

async function startChallenge() {
    const count = parseInt(document.getElementById('challenge-task-count').value) || 10;
    const minutes = parseInt(document.getElementById('challenge-time-limit').value) || 60;
    const category = document.getElementById('challenge-category').value;
    
    examDuration = minutes * 60 * 1000;
    
    try {
        let url = `/api/random-tasks?count=${count}`;
        if (category) url += `&category=${encodeURIComponent(category)}`;
        
        const res = await fetch(url);
        selectedTasks = await res.json();
        
        if (selectedTasks.length === 0) {
            showToast('warning', 'No tasks found', 'Try a different category or increase task count');
            return;
        }
        
        taskResults.clear();
        currentTaskIndex = 0;
        currentMode = 'challenge';
        examStartTime = Date.now();
        startTimer();
        document.getElementById('breadcrumb-mode').textContent = `Challenge (${minutes}min)`;
        populateSidebarCategoryFilter();
        renderTaskList();
        showTaskDetail(selectedTasks[0].id);
        updateTaskNavigation();
        showView('exam-running');
        saveSession();
    } catch (e) {
        showToast('error', 'Failed to start challenge', e.message);
    }
}

// Populate challenge category dropdown
function populateChallengeCategoryFilter() {
    const select = document.getElementById('challenge-category');
    if (!select) return;
    const categories = [...new Set(allTasks.map(t => t.category))].sort();
    select.innerHTML = '<option value="">All Categories (Random)</option>' +
        categories.map(c => `<option value="${c}">${c}</option>`).join('');
}

// Timer
function startTimer() {
    const timerEl = document.getElementById('timer');
    timerEl.classList.remove('hidden');
    
    timerInterval = setInterval(() => {
        const elapsed = Date.now() - examStartTime;
        const remaining = Math.max(0, examDuration - elapsed);
        
        if (remaining <= 0) {
            clearInterval(timerInterval);
            showToast('warning', 'Time\'s Up!', 'Submitting for grading...');
            submitForGrading();
            return;
        }
        
        const hrs = Math.floor(remaining / 3600000);
        const mins = Math.floor((remaining % 3600000) / 60000);
        const secs = Math.floor((remaining % 60000) / 1000);
        timerEl.textContent = `${hrs.toString().padStart(2, '0')}:${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
        
        if (remaining < 300000) timerEl.classList.add('text-red-500', 'animate-pulse');
    }, 1000);
}

function stopTimer() {
    if (timerInterval) clearInterval(timerInterval);
    document.getElementById('timer').classList.add('hidden');
}

// Task List & Detail

// Returns { task, index } entries from selectedTasks that pass the sidebar
// search box and category dropdown filters. `index` is the task's position
// in the raw, unfiltered selectedTasks array. Shared by renderTaskList() and
// the Next/Prev navigation functions so they agree on what's "visible".
function getVisibleTaskEntries() {
    const searchInput = document.getElementById('sidebar-task-search');
    const searchTerm = searchInput?.value?.toLowerCase() || '';
    const categorySelect = document.getElementById('sidebar-category-filter');
    const categoryFilter = categorySelect?.value || '';

    return selectedTasks.map((task, i) => ({ task, index: i })).filter(({ task, index }) => {
        // Category filter
        if (categoryFilter && task.category !== categoryFilter) return false;

        // Search filter
        if (searchTerm) {
            const desc = (task.description || task.id).toLowerCase();
            const cat = (task.category || '').toLowerCase();
            if (!desc.includes(searchTerm) && !cat.includes(searchTerm) && !task.id.toLowerCase().includes(searchTerm)) {
                return false;
            }
        }

        return true;
    });
}

function renderTaskList() {
    const container = document.getElementById('task-list');
    const gradedCount = Array.from(taskResults.values()).filter(r => r?.graded).length;

    // Update progress bar
    const progressBar = document.getElementById('task-progress-bar');
    const progressText = document.getElementById('task-progress-text');
    if (progressBar) progressBar.style.width = `${(gradedCount / selectedTasks.length) * 100}%`;
    if (progressText) progressText.textContent = `${gradedCount} of ${selectedTasks.length}`;

    // Filter tasks
    const filteredTasks = getVisibleTaskEntries();

    if (filteredTasks.length === 0) {
        container.innerHTML = '<p class="text-gray-500 text-sm text-center py-4">No matching tasks</p>';
        return;
    }
    
    container.innerHTML = filteredTasks.map(({ task, index: i }) => {
        const result = taskResults.get(task.id);
        const isActive = i === currentTaskIndex;
        
        // Determine status icon and styles
        let icon, iconClass, itemClass, statusText = '';
        if (result?.graded) {
            if (result.passed) {
                icon = 'check_circle';
                iconClass = 'text-green-500';
                itemClass = 'border-l-2 border-transparent hover:border-gray-500';
            } else {
                icon = 'cancel';
                iconClass = 'text-red-500';
                itemClass = 'border-l-2 border-transparent hover:border-gray-500';
            }
        } else if (isActive) {
            icon = 'play_circle';
            iconClass = 'fill text-primary';
            itemClass = 'bg-surface-dark border-l-4 border-primary shadow-lg shadow-black/20';
            statusText = '<span class="text-xs text-primary font-medium">In Progress</span>';
        } else {
            icon = 'radio_button_unchecked';
            iconClass = 'text-gray-500';
            itemClass = 'border-l-2 border-transparent hover:border-gray-500';
        }
        
        // Use title for sidebar, fallback to truncated description
        const sidebarTitle = task.title || ((task.description || task.id).length > 25 
            ? (task.description || task.id).substring(0, 22) + '...' 
            : (task.description || task.id));
        
        return `
            <button onclick="selectTask(${i})" 
                    class="w-full flex items-center gap-3 px-3 py-3 rounded-sm hover:bg-surface-dark group transition-all text-left ${itemClass}">
                <span class="material-symbols-outlined ${iconClass} text-[20px]">${icon}</span>
                <div class="flex flex-col gap-1 min-w-0">
                    <span class="${isActive ? 'text-white font-bold' : 'text-gray-400 group-hover:text-white font-medium'} text-sm leading-none truncate transition-colors">${i + 1}. ${sidebarTitle}</span>
                    ${statusText}
                </div>
            </button>
        `;
    }).join('');
    
    // Update navigation dots
    updateTaskDots();
}

function updateTaskDots() {
    const dotsContainer = document.getElementById('task-dots');
    if (!dotsContainer) return;

    // Reflect the filtered/visible set, same as Next/Prev navigation, so the
    // dots and position counter stay consistent with what the user can
    // actually navigate to while a sidebar filter is active.
    const visible = getVisibleTaskEntries();
    const maxDots = 7;
    const totalTasks = visible.length;
    const visiblePos = visible.findIndex(({ index }) => index === currentTaskIndex);

    if (totalTasks <= maxDots) {
        dotsContainer.innerHTML = visible.map(({ index }, i) => {
            const isActive = index === currentTaskIndex;
            return `<button onclick="selectTask(${index})" class="size-2 rounded-full ${isActive ? 'bg-primary' : 'bg-surface-dark border border-border-dark hover:bg-primary/50'} transition-colors"></button>`;
        }).join('');
    } else {
        // Show abbreviated dots with current position indicator
        dotsContainer.innerHTML = `<span class="text-xs text-gray-400 font-mono">${visiblePos + 1} / ${totalTasks}</span>`;
    }
}

// Sidebar filtering
function filterSidebarTasks() {
    renderTaskList();
}

function populateSidebarCategoryFilter() {
    const select = document.getElementById('sidebar-category-filter');
    if (!select) return;
    
    // Get unique categories from selected tasks
    const categories = [...new Set(selectedTasks.map(t => t.category).filter(Boolean))].sort();
    
    select.innerHTML = '<option value="">All Categories</option>' + 
        categories.map(c => `<option value="${c}">${c.replace(/-/g, ' ')}</option>`).join('');
}

function selectTask(index) {
    currentTaskIndex = index;
    showTaskDetail(selectedTasks[index].id);
    updateTaskNavigation();
    renderTaskList();
    saveSession();
}

// Generate a concise title from task description
function generateShortTitle(description) {
    if (!description) return 'Task';
    
    let title = description;
    
    // Remove common verbose patterns
    // "Configure network on node1 with IP..." -> "Configure Network"
    title = title.replace(/^(Configure|Create|Set|Install|Enable|Add|Mount|Find|Search|Write|Schedule|Launch|Grant|Extend|Resize)\s+/i, (m, verb) => verb + ' ');
    
    // Cut at first occurrence of "with", "on node", "using", "for user", etc.
    const cutPoints = [' with ', ' on node', ' using ', ' for user', ' to /', ' from /', ' in /', ', '];
    for (const cut of cutPoints) {
        const idx = title.toLowerCase().indexOf(cut.toLowerCase());
        if (idx > 10 && idx < 50) {
            title = title.substring(0, idx);
            break;
        }
    }
    
    // Capitalize first letter after the verb
    title = title.replace(/^(\w+)\s+(\w)/, (m, verb, first) => verb + ' ' + first.toUpperCase());
    
    // Truncate if still too long
    if (title.length > 50) {
        title = title.substring(0, 47) + '...';
    }
    
    return title;
}

function showTaskDetail(taskId) {
    const task = selectedTasks.find(t => t.id === taskId);
    if (!task) return;
    
    const result = taskResults.get(taskId);
    const container = document.getElementById('current-task-detail');
    const taskIndex = selectedTasks.findIndex(t => t.id === taskId);
    
    // Update breadcrumbs
    const breadcrumbCategory = document.getElementById('breadcrumb-category');
    const breadcrumbTask = document.getElementById('breadcrumb-task');
    if (breadcrumbCategory) breadcrumbCategory.textContent = task.category || 'Tasks';
    if (breadcrumbTask) breadcrumbTask.textContent = `Task ${taskIndex + 1}`;
    
    // Determine target host display
    const targetHost = task.target === 'node1' ? 'rhcsa1 (node1)' : 
                      task.target === 'node2' ? 'rhcsa2 (node2)' : 
                      task.target === 'both' ? 'Both nodes' : task.target || 'node1';
    
    // Build result status HTML
    let resultHtml = '';
    if (result?.graded) {
        const statusColor = result.passed ? 'green' : 'red';
        const statusIcon = result.passed ? 'check_circle' : 'cancel';
        const statusText = result.passed ? 'Task Completed Successfully' : 'Task Failed';
        
        // Build check details HTML
        let checksHtml = '';
        if (result.details && result.details.length > 0) {
            checksHtml = `
                <div class="mt-4 pt-3 border-t border-white/10">
                    <p class="text-xs text-gray-500 uppercase tracking-wider mb-2">Verification Details</p>
                    <ul class="space-y-1">
                        ${result.details.map(d => {
                            const isPassed = d.startsWith('✓');
                            return `<li class="text-sm ${isPassed ? 'text-green-400' : 'text-red-400'} font-mono">${d}</li>`;
                        }).join('')}
                    </ul>
                </div>
            `;
        }
        
        resultHtml = `
            <div class="mt-6 p-4 rounded-sm border-l-4 ${result.passed ? 'border-l-green-500 bg-green-500/5 border-y border-r border-green-500/20' : 'border-l-red-500 bg-red-500/5 border-y border-r border-red-500/20'}">
                <div class="flex items-center gap-3">
                    <span class="material-symbols-outlined ${result.passed ? 'text-green-500' : 'text-red-500'} text-2xl">${statusIcon}</span>
                    <div>
                        <p class="font-bold ${result.passed ? 'text-green-400' : 'text-red-400'}">${statusText}</p>
                        <p class="text-sm text-gray-400">${result.points || 0} of ${result.maxPoints || task.points || 1} points earned</p>
                    </div>
                </div>
                ${result.error ? `<p class="text-sm text-red-400 mt-3 pl-9">Error: ${result.error}</p>` : ''}
                ${checksHtml}
            </div>
        `;
    }
    
    // Use task title if available, otherwise generate one
    const taskTitle = task.title || generateShortTitle(task.description || task.id);
    
    container.innerHTML = `
        <!-- Task Header -->
        <div class="flex flex-col md:flex-row md:items-start md:justify-between gap-4 mb-6">
            <div>
                <div class="flex items-center gap-2 text-gray-400 text-sm font-mono mb-1">Task ${taskIndex + 1} of ${selectedTasks.length}</div>
                <h1 class="text-2xl md:text-3xl font-bold text-white tracking-tight leading-tight">${taskTitle}</h1>
            </div>
            <div class="flex items-center gap-2 shrink-0">
                <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-sm bg-surface-dark border border-border-dark text-xs font-medium text-white uppercase tracking-wider">
                    <span class="w-1.5 h-1.5 rounded-full bg-purple-500"></span>
                    ${(task.category || 'General').replace(/-/g, ' ')}
                </span>
                <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-sm bg-primary/10 border border-primary/20 text-xs font-bold text-primary uppercase tracking-wider">
                    ${task.points || 1} Points
                </span>
            </div>
        </div>
        
        <!-- Target Info Cards -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
            <div class="bg-surface-dark border-l-2 border-l-red-500 border-y border-r border-border-dark rounded-r-sm p-5 flex items-start gap-4 shadow-sm">
                <div class="p-2.5 bg-background-dark rounded-sm shrink-0 text-white border border-border-dark">
                    <span class="material-symbols-outlined">dns</span>
                </div>
                <div>
                    <h3 class="text-sm font-bold text-gray-400 uppercase tracking-wider mb-1">Target Host</h3>
                    <p class="text-white font-mono text-base">${targetHost}</p>
                </div>
            </div>
            <div class="bg-surface-dark border-l-2 border-l-red-500 border-y border-r border-border-dark rounded-r-sm p-5 flex items-start gap-4 shadow-sm">
                <div class="p-2.5 bg-background-dark rounded-sm shrink-0 text-white border border-border-dark">
                    <span class="material-symbols-outlined">verified_user</span>
                </div>
                <div>
                    <h3 class="text-sm font-bold text-gray-400 uppercase tracking-wider mb-1">Verification</h3>
                    <p class="text-white font-mono text-base">Automated Check</p>
                </div>
            </div>
        </div>
        
        <hr class="border-border-dark"/>
        
        <!-- Task Description -->
        <div class="prose prose-invert prose-lg max-w-none mt-6">
            <h3 class="text-white text-xl font-bold mb-4 flex items-center gap-2 border-l-4 border-primary pl-3 h-8">
                Description
            </h3>
            <p class="text-white text-base leading-relaxed mb-4 font-medium">
                ${task.description || 'Complete this task according to the requirements.'}
            </p>
            
            ${task.checks && task.checks.length > 0 ? `
            <div class="mt-4 p-4 bg-surface-dark rounded-lg border border-border-dark">
                <h4 class="text-sm font-bold text-gray-400 uppercase tracking-wider mb-3 flex items-center gap-2">
                    <span class="material-symbols-outlined text-lg">checklist</span>
                    Verification Criteria (${task.checks.length} checks, ${task.points || task.checks.length * 10} points)
                </h4>
                <ul class="space-y-2">
                    ${task.checks.map((c, i) => `
                        <li class="flex items-start gap-2 text-sm">
                            <span class="text-gray-500 font-mono">${i + 1}.</span>
                            <span class="text-gray-300">${c.pass}</span>
                        </li>
                    `).join('')}
                </ul>
            </div>
            ` : ''}
        </div>
        
        <!-- Action Buttons -->
        <div class="flex gap-3 mt-8">
            <button onclick="gradeTask('${taskId}')" class="flex items-center gap-2 px-6 py-3 rounded-sm bg-primary hover:bg-primary-hover text-white font-bold transition-all shadow-lg shadow-red-900/20">
                <span class="material-symbols-outlined">check_circle</span> Check Task
            </button>
            ${!result?.graded ? `
            <button onclick="navigateTask(1)" class="flex items-center gap-2 px-6 py-3 rounded-sm bg-surface-dark hover:bg-white/10 border border-border-dark text-white font-medium transition-all">
                Skip for now
                <span class="material-symbols-outlined">arrow_forward</span>
            </button>
            ` : ''}
        </div>
        
        ${resultHtml}
    `;
}

function navigateTask(direction) {
    const visible = getVisibleTaskEntries();
    const visiblePos = visible.findIndex(({ index }) => index === currentTaskIndex);

    if (visiblePos === -1) {
        // Active task isn't in the currently filtered set (e.g. user filtered
        // to a category the active task isn't in). Fall back to walking the
        // raw, unfiltered list so Next/Prev still does something sensible
        // instead of silently no-oping.
        const newIndex = currentTaskIndex + direction;
        if (newIndex >= 0 && newIndex < selectedTasks.length) {
            selectTask(newIndex);
        }
        return;
    }

    const newVisiblePos = visiblePos + direction;
    if (newVisiblePos >= 0 && newVisiblePos < visible.length) {
        selectTask(visible[newVisiblePos].index);
    }
}

function updateTaskNavigation() {
    const prevBtn = document.getElementById('prev-task-btn');
    const nextBtn = document.getElementById('next-task-btn');

    const visible = getVisibleTaskEntries();
    const visiblePos = visible.findIndex(({ index }) => index === currentTaskIndex);

    if (visiblePos === -1) {
        // Active task isn't in the filtered set; mirror navigateTask's
        // fallback bounds (raw selectedTasks) so the buttons aren't
        // incorrectly disabled/enabled relative to what Next/Prev will do.
        if (prevBtn) prevBtn.disabled = currentTaskIndex === 0;
        if (nextBtn) nextBtn.disabled = currentTaskIndex === selectedTasks.length - 1;
    } else {
        if (prevBtn) prevBtn.disabled = visiblePos === 0;
        if (nextBtn) nextBtn.disabled = visiblePos === visible.length - 1;
    }

    // Update dots
    updateTaskDots();
}

// Grading
async function gradeTask(taskId) {
    const task = selectedTasks.find(t => t.id === taskId);
    if (!task) return;
    
    showToast('info', 'Grading...', task.description);
    
    try {
        // Use v2 API with Python grader
        const res = await fetch(`/api/v2/grade/${taskId}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
        const result = await res.json();
        
        taskResults.set(taskId, {
            graded: true,
            passed: result.passed,
            points: result.points || (result.passed ? task.points : 0),
            maxPoints: result.max_points || task.points,
            message: result.message,
            details: result.details || [],
            checksPasssed: result.checks_passed || 0,
            checksTotal: result.checks_total || 0,
            error: result.error
        });
        
        showTaskDetail(taskId);
        renderTaskList();
        saveSession();
        
        if (result.passed) {
            showToast('success', 'Task Passed!', `${result.points || task.points} points earned`);
        } else {
            showToast('error', 'Task Failed', result.message);
        }
    } catch (e) {
        showToast('error', 'Grading Failed', e.message);
    }
}

async function submitForGrading() {
    gradingAborted = false;
    document.getElementById('grading-modal').classList.remove('hidden');
    
    let completed = 0;
    for (const task of selectedTasks) {
        if (gradingAborted) break;
        
        document.getElementById('grading-status').textContent = `Checking task ${completed + 1} of ${selectedTasks.length}...`;
        document.getElementById('grading-progress').style.width = `${(completed / selectedTasks.length) * 100}%`;
        
        if (!taskResults.get(task.id)?.graded) {
            await gradeTask(task.id);
        }
        completed++;
    }
    
    document.getElementById('grading-modal').classList.add('hidden');
    
    if (!gradingAborted) {
        stopTimer();
        showResults();
    }
}

function abortGrading() {
    gradingAborted = true;
    document.getElementById('grading-modal').classList.add('hidden');
}

function showResults() {
    let score = 0, total = 0;
    selectedTasks.forEach(task => {
        total += task.points || 1;
        const result = taskResults.get(task.id);
        if (result?.passed) score += result.points || task.points || 1;
    });
    
    const pct = total > 0 ? Math.round((score / total) * 100) : 0;
    const passed = pct >= 70;
    
    document.getElementById('result-score').textContent = score;
    document.getElementById('result-total').textContent = total;
    document.getElementById('result-pct').textContent = `${pct}%`;
    document.getElementById('result-status').textContent = passed ? 'PASS' : 'FAIL';
    
    const statusBox = document.getElementById('result-status-box');
    statusBox.className = `bg-surface-dark rounded-xl border p-6 text-center ${passed ? 'border-emerald-500' : 'border-red-500'}`;
    document.getElementById('result-status').className = `text-4xl font-bold mb-1 ${passed ? 'text-emerald-500' : 'text-red-500'}`;
    
    // Render check results
    const checksContainer = document.getElementById('check-results');
    checksContainer.innerHTML = selectedTasks.map(task => {
        const result = taskResults.get(task.id);
        const icon = result?.passed ? 'check_circle' : 'cancel';
        const color = result?.passed ? 'text-emerald-500' : 'text-red-500';
        return `
            <div class="flex items-center gap-3 p-3 rounded-lg bg-white/5">
                <span class="material-symbols-outlined ${color}">${icon}</span>
                <span class="flex-1 text-sm">${task.description || task.id}</span>
                <span class="text-xs text-gray-500">${result?.points || 0}/${task.points || 1} pts</span>
            </div>
        `;
    }).join('');
    
    clearSavedSession();
    showView('results');
    
    // Save to history
    saveResult({ score, total, passed: pct >= 70, mode: currentMode, checks: Array.from(taskResults.entries()) });
}

async function saveResult(data) {
    try {
        await fetch('/api/results', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ ...data, timestamp: new Date().toISOString() })
        });
    } catch (e) {
        console.error('Failed to save result:', e);
    }
}

// Abandon Session
function confirmAbandon() { document.getElementById('abandon-modal').classList.remove('hidden'); }
function hideAbandonModal() { document.getElementById('abandon-modal').classList.add('hidden'); }

function abandonSession() {
    hideAbandonModal();
    stopTimer();
    clearSavedSession();
    selectedTasks = [];
    taskResults.clear();
    showView('welcome');
}

// Statistics
