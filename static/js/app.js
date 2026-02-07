/**
 * RHCSA Practice Labs - Application Initialization
 * Main entry point and event listeners
 */

// Flashcard keyboard shortcuts
document.addEventListener('keydown', (e) => {
    if (!document.getElementById('view-flashcards').classList.contains('active')) return;
    if (document.getElementById('fc-study-area').classList.contains('hidden')) return;
    
    if (e.code === 'Space') {
        e.preventDefault();
        fcFlipCard();
    } else if (e.code === 'Digit1' || e.code === 'ArrowLeft') {
        fcMarkCard(false);
    } else if (e.code === 'Digit2' || e.code === 'ArrowRight') {
        fcMarkCard(true);
    }
});

// Initialize application
document.addEventListener('DOMContentLoaded', () => {
    showView('welcome');
    loadConfig();
    checkCloudSession().then(() => {
        refreshCloudSessionUI();
        // Start monitor if session already exists
        if (cloudSession && ['ready', 'active'].includes(cloudSession.state)) {
            startSessionMonitor();
        }
    });
});
