
// Session Persistence Functions

function saveSession() {
    if (window.selectedTasks.length === 0) return;

    const session = {
        selectedTasks: window.selectedTasks,
        currentMode: window.currentMode,
        currentTaskIndex: window.currentTaskIndex,
        taskResults: Array.from(window.taskResults.entries()),
        timestamp: Date.now()
    };
    localStorage.setItem(window.SESSION_KEY, JSON.stringify(session));
}

function loadSavedSession() {
    try {
        const saved = localStorage.getItem(window.SESSION_KEY);
        if (!saved) return null;
        return JSON.parse(saved);
    } catch (e) {
        console.error('Failed to load session:', e);
        return null;
    }
}

function clearSavedSession() {
    localStorage.removeItem(window.SESSION_KEY);
    const banner = document.getElementById('resume-session-banner');
    if (banner) banner.classList.add('hidden');
    showToast('info', 'Session Cleared', 'Previous session has been cleared.');
}

function checkForSavedSession() {
    const session = loadSavedSession();
    const banner = document.getElementById('resume-session-banner');
    const info = document.getElementById('resume-session-info');

    if (session && session.selectedTasks && session.selectedTasks.length > 0) {
        // Calculate progress
        const graded = session.taskResults ? session.taskResults.filter(([k, v]) => v && v.graded).length : 0;
        const total = session.selectedTasks.length;
        const modeLabel = session.currentMode === 'exam' ? 'Exam' : 'Practice';
        const timeAgo = getTimeAgo(session.timestamp);

        info.textContent = `${modeLabel} mode - ${graded}/${total} tasks graded - ${timeAgo}`;
        banner.classList.remove('hidden');
        return true;
    } else {
        banner.classList.add('hidden');
        return false;
    }
}

async function resumeSession() {
    // Ensure tasks are loaded
    if (window.allTasks.length === 0) {
        await loadTasks();
    }

    const session = loadSavedSession();
    if (!session || !session.selectedTasks) {
        showToast('error', 'No Session', 'Could not find a saved session to resume.');
        return;
    }

    // Restore state
    window.selectedTasks = session.selectedTasks;
    window.currentMode = session.currentMode || 'practice';
    window.currentTaskIndex = session.currentTaskIndex || 0;
    window.taskResults = new Map(session.taskResults || []);

    // Sanity check
    if (!window.selectedTasks || window.selectedTasks.length === 0) {
        showToast('error', 'Session Error', 'Saved session is empty. Starting fresh.');
        clearSavedSession();
        showView('mode-select');
        return;
    }
    // Ensure index is valid
    if (window.currentTaskIndex >= window.selectedTasks.length) window.currentTaskIndex = 0;

    // Collapse all categories by default for cleaner view
    window.collapsedCategories.clear();
    const allCategories = [...new Set(window.selectedTasks.map(t => t.category))];
    allCategories.forEach(c => window.collapsedCategories.add(c));

    document.getElementById('toggle-collapse').textContent = 'Expand All';

    // Show exam UI
    showView('exam-running');
    document.getElementById('exam-sidebar').classList.remove('hidden');

    if (window.currentMode === 'exam') {
        document.getElementById('timer').classList.remove('hidden');
        // Restart timer (simplified - mostly just for tracking duration of *this* session part)
        // Ideally we'd persist remaining time but for now just start fresh or continue
        startTimer();
    } else {
        document.getElementById('timer').classList.add('hidden');
    }

    document.getElementById('breadcrumb-mode').textContent = window.currentMode === 'exam' ? 'Exam' : 'Practice';

    // Populate sidebar
    renderTaskSidebar();

    // Show current task
    if (window.selectedTasks.length > 0) {
        showTaskDetail(window.selectedTasks[window.currentTaskIndex].id);
        updateTaskNavigation();
    }

    // Save session for resume capability
    saveSession();

    // BACKGROUND CHECK: Warn if VMs are offline
    // We don't block resume because user might just want to review old state
    checkVmReady().then(status => {
        if (!status.ready) {
            const msg = status.reason === 'config'
                ? 'VMs are not configured. Grading will not work.'
                : 'VMs appear to be offline. Grading will not work.';
            showToast('warning', 'Connectivity Issue', msg, 7000);
        } else {
            console.log('Session resumed with VMs online');
        }
    });

}
