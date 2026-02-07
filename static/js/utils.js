/**
 * RHCSA Practice Labs - Utility Functions
 */

/**
 * Show a toast notification
 * @param {string} type - Toast type: 'success', 'error', 'warning', 'info'
 * @param {string} title - Toast title
 * @param {string} message - Optional message
 * @param {number} duration - Duration in ms (0 = no auto-dismiss)
 */
function showToast(type, title, message, duration = 5000) {
    const container = document.getElementById('toast-container');
    const colors = {
        success: 'border-emerald-500 bg-emerald-500/10',
        error: 'border-red-500 bg-red-500/10',
        warning: 'border-amber-500 bg-amber-500/10',
        info: 'border-blue-500 bg-blue-500/10'
    };
    const icons = { success: 'check_circle', error: 'error', warning: 'warning', info: 'info' };
    
    const toast = document.createElement('div');
    toast.className = `flex items-start gap-3 p-4 rounded-lg border-l-4 ${colors[type] || colors.info} backdrop-blur-sm animate-fade-in`;
    toast.innerHTML = `
        <span class="material-symbols-outlined">${icons[type] || 'info'}</span>
        <div class="flex-1">
            <div class="font-bold text-sm">${title}</div>
            ${message ? `<div class="text-sm text-gray-400 mt-0.5">${message}</div>` : ''}
        </div>
        <button onclick="this.parentElement.remove()" class="text-gray-400 hover:text-white">
            <span class="material-symbols-outlined text-lg">close</span>
        </button>
    `;
    container.appendChild(toast);
    if (duration > 0) setTimeout(() => toast.remove(), duration);
}

/**
 * Generate a short title from a task description
 * @param {string} description - Full task description
 * @returns {string} - Short title (max ~60 chars)
 */
function generateShortTitle(description) {
    if (!description) return 'Task';
    
    // Common patterns to look for
    const patterns = [
        /^(Configure|Create|Set up|Install|Enable|Disable|Add|Remove|Modify|Change|Update|Delete|Start|Stop|Restart)/i,
        /^(Ensure|Verify|Check|Fix|Troubleshoot|Debug|Resolve|Implement|Deploy|Manage)/i
    ];
    
    // Try to find the first sentence or clause
    let title = description.split(/[.!?]/)[0].trim();
    
    // If it's too long, try to cut at a natural break
    if (title.length > 60) {
        const breaks = [' and ', ' with ', ' for ', ' on ', ' using ', ' to '];
        for (const br of breaks) {
            const idx = title.toLowerCase().indexOf(br);
            if (idx > 20 && idx < 60) {
                title = title.substring(0, idx);
                break;
            }
        }
    }
    
    // Still too long? Just truncate
    if (title.length > 60) {
        title = title.substring(0, 57) + '...';
    }
    
    return title || 'Task';
}

/**
 * Format time in HH:MM:SS
 * @param {number} ms - Time in milliseconds
 * @returns {string} - Formatted time string
 */
function formatTime(ms) {
    const totalSeconds = Math.floor(ms / 1000);
    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = totalSeconds % 60;
    return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
}
