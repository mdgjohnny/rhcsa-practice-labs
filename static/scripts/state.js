
// Application State
window.allTasks = [];
window.selectedTasks = [];
window.currentMode = null;
window.timerInterval = null;
window.examStartTime = null;
window.currentTaskIndex = 0;
window.compactMode = false;
window.collapsedCategories = new Set();
window.taskResults = new Map(); // Track graded tasks: taskId -> {passed, graded}
window.gradingAborted = false; // Flag to cancel grading
window.previousView = null; // Track previous view for back navigation
window.cachedConfig = null; // Cache config for quick access
window.EXAM_DURATION = 3 * 60 * 60 * 1000; // 3 hours
window.SESSION_KEY = 'rhcsa_session';

// Random Sort State
window.randomSortMode = false;
