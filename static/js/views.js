/**
 * RHCSA Practice Labs - View Management
 * Handles view switching, session persistence, and navigation
 */

function showView(viewId) {
    const currentView = document.querySelector('.view.active');
    if (currentView) previousView = currentView.id.replace('view-', '');
    
    document.querySelectorAll('.view').forEach(v => v.classList.remove('active'));
    const newView = document.getElementById(`view-${viewId}`);
    if (newView) newView.classList.add('active');
    
    // Show/hide exam sidebar and timer
    const sidebar = document.getElementById('exam-sidebar');
    const timer = document.getElementById('timer');
    const practiceBar = document.getElementById('practice-bottom-bar');
    
    if (viewId === 'exam-running') {
        sidebar?.classList.remove('hidden');
        if (currentMode === 'exam' || currentMode === 'challenge') timer?.classList.remove('hidden');
    } else {
        sidebar?.classList.add('hidden');
        timer?.classList.add('hidden');
    }

    // Show/hide practice setup bottom bar
    if (viewId === 'practice-setup') {
        practiceBar?.classList.remove('hidden');
    } else {
        practiceBar?.classList.add('hidden');
    }
    
    // Load data for specific views
    if (viewId === 'practice-setup') loadTasks();
    if (viewId === 'practice-category') populateCategoryGrid();
    if (viewId === 'challenge-setup') populateChallengeCategoryFilter();
    if (viewId === 'stats') loadStats();
    if (viewId === 'welcome') checkForSavedSession();
    if (viewId === 'setup') {
        loadConfig();
        refreshCloudSessionUI();
    }
    if (viewId === 'flashcards') loadFlashcards();
}

// Session Persistence
function saveSession() {
    if (selectedTasks.length === 0) return;
    const session = {
        // Store only task IDs - descriptions will be re-fetched on resume
        selectedTaskIds: selectedTasks.map(t => t.id),
        currentMode, currentTaskIndex,
        taskResults: Array.from(taskResults.entries()),
        timestamp: Date.now()
    };
    localStorage.setItem(SESSION_KEY, JSON.stringify(session));
}

function loadSavedSession() {
    try {
        const saved = localStorage.getItem(SESSION_KEY);
        return saved ? JSON.parse(saved) : null;
    } catch { return null; }
}

function clearSavedSession() {
    localStorage.removeItem(SESSION_KEY);
    document.getElementById('resume-session-banner')?.classList.add('hidden');
    showToast('info', 'Session Cleared');
}

function checkForSavedSession() {
    const session = loadSavedSession();
    const banner = document.getElementById('resume-session-banner');
    const info = document.getElementById('resume-session-info');
    
    // Support both old format (selectedTasks) and new format (selectedTaskIds)
    const taskCount = session?.selectedTaskIds?.length || session?.selectedTasks?.length || 0;
    if (taskCount > 0) {
        const graded = session.taskResults?.filter(([k, v]) => v?.graded).length || 0;
        const modeLabel = session.currentMode === 'exam' ? 'Exam' : 'Practice';
        info.textContent = `${modeLabel} mode - ${graded}/${taskCount} tasks graded`;
        banner?.classList.remove('hidden');
    } else {
        banner?.classList.add('hidden');
    }
}

async function resumeSession() {
    const session = loadSavedSession();
    if (!session) return;
    
    // Fetch fresh task data from API to get current descriptions
    if (allTasks.length === 0) {
        try {
            const res = await fetch('/api/v2/tasks');
            allTasks = await res.json();
        } catch (e) {
            showToast('error', 'Failed to load tasks', e.message);
            return;
        }
    }
    
    // Support both old format (selectedTasks) and new format (selectedTaskIds)
    const taskIds = session.selectedTaskIds || session.selectedTasks?.map(t => t.id) || [];
    selectedTasks = allTasks.filter(t => taskIds.includes(t.id));
    
    if (selectedTasks.length === 0) {
        showToast('error', 'Session Invalid', 'Tasks no longer available');
        clearSavedSession();
        return;
    }
    
    currentMode = session.currentMode;
    currentTaskIndex = Math.min(session.currentTaskIndex || 0, selectedTasks.length - 1);
    taskResults = new Map(session.taskResults || []);
    
    document.getElementById('breadcrumb-mode').textContent = currentMode === 'exam' ? 'Exam' : 'Practice';
    populateSidebarCategoryFilter();
    renderTaskList();
    showTaskDetail(selectedTasks[currentTaskIndex]?.id);
    updateTaskNavigation();
    showView('exam-running');
    showToast('success', 'Session Restored');
}

