
// Initialization
(async function init() {
    try {
        loadConfig();
        await loadTasks();

        // Check for saved session and auto-resume if found
        const hasSession = checkForSavedSession();
        if (hasSession) {
            // Auto-resume logic is handled by user action (clicking banner)
            // But if we wanted to auto-start: resumeSession(); 
            // Current UX is: show banner on welcome screen.

            // If the user was in the middle of standard practice flow, maybe we *should* auto-resume?
            // The original code did:
            // if (hasSession) { await resumeSession(); } else { showView('welcome'); }
            // But the welcome screen has a banner now.
            // Let's stick to the original logic: if session exists, resume it?
            // Wait, the new welcome screen logic in index.html (lines ~1825) implies manual resume.
            // "Resume Session Banner (hidden by default)"
            // "checkForSavedSession" unhides it.
            // But "init" calls "checkForSavedSession".

            // The original code lines 3995+:
            // const hasSession = checkForSavedSession();
            // if (hasSession) { await resumeSession(); } else { showView('welcome'); }

            // I will match the original behavior for continuity, OR since I saw a banner in the HTML, maybe the original intention was to show banner.
            // Let's look at `index.html` again.
            // It had `id="resume-session-banner"` hidden.
            // `checkForSavedSession` unhides it.
            // The original `init` called `resumeSession()` automatically!
            // That might be annoying if I want to start over.
            // But since I'm refactoring, I should probably stick to original behavior unless "Refine Session UX" conversation changed it.
            // The summary said "ensuring the session resume functionality works as intended (including the resume banner)".
            // This suggests the banner IS the way to resume.
            // So I should NOT auto-resume, but show welcome screen with banner.

            showView('welcome');

            // Note: The previous code *did* auto-resume in line 3999, which might have been a bug or a feature.
            // "Refine Session UX" summary says "ensuring the session resume functionality works as intended".
            // If I auto-resume, I skip the welcome screen.
            // I'll show Welcome screen.
        } else {
            showView('welcome');
        }

    } catch (e) {
        console.error("Initialization failed", e);
        showView('welcome');
    }

    // Attach event listeners for search/sort in Practice Setup (if not inline)
    // Inline onchange/oninput attributes are used in HTML, so no need here unless I removed them.
    // I added IDs `task-filter-text` and `task-sort-mode`.
    // I should add listeners because I didn't add oninput/onchange to the HTML elements yet (they will be new).

    const filterInput = document.getElementById('task-filter-text');
    if (filterInput) filterInput.addEventListener('input', updatePracticeSetupList);

    const sortSelect = document.getElementById('task-sort-mode');
    if (sortSelect) sortSelect.addEventListener('change', updatePracticeSetupList);

})();
