/**
 * RHCSA Practice Labs - Flashcard System
 * Anki-style spaced repetition flashcards
 */

// State variables are defined in state.js:
// fcData, fcProgress, fcCards, fcCurrentIndex, fcKnown, fcUnknown,
// fcMissedCards, fcSelectedChapters, fcIsFlipped, fcCardStartTime, fcStats, fcStudyMode

async function loadFlashcards() {
    try {
        // Load card data and progress in parallel
        const [dataResp, progressResp, statsResp] = await Promise.all([
            fetch('/flashcards.json'),
            fetch('/api/flashcards/progress'),
            fetch('/api/flashcards/stats')
        ]);
        fcData = await dataResp.json();
        const progressList = await progressResp.json();
        fcStats = await statsResp.json();
        
        // Index progress by card_id
        fcProgress = {};
        progressList.forEach(p => fcProgress[p.card_id] = p);
        
        fcRenderChapters();
    } catch (e) {
        console.error('Failed to load flashcards:', e);
    }
}

function fcGetCardId(card) {
    return `ch${card.chapter}-${btoa(card.q).slice(0, 16)}`;
}

function fcRenderChapters() {
    const grid = document.getElementById('fc-chapter-grid');
    
    // Calculate per-chapter stats
    const chapterStats = {};
    fcData.chapters.forEach(ch => {
        const cards = ch.cards.map(c => ({...c, chapter: ch.chapter}));
        let mastered = 0, due = 0, newCards = 0;
        cards.forEach(card => {
            const cardId = fcGetCardId(card);
            const prog = fcProgress[cardId];
            if (!prog) newCards++;
            else if (prog.state === 'mastered') mastered++;
            else if (prog.due_date && prog.due_date <= new Date().toISOString().slice(0, 10)) due++;
        });
        chapterStats[ch.chapter] = { mastered, due, newCards, total: cards.length };
    });
    
    grid.innerHTML = fcData.chapters.map(ch => {
        const stats = chapterStats[ch.chapter];
        const pct = Math.round((stats.mastered / stats.total) * 100);
        return `
        <div class="fc-chapter-card p-4 bg-surface-dark rounded-xl border border-white/5 hover:border-white/20 cursor-pointer transition-all"
             data-chapter="${ch.chapter}" onclick="fcToggleChapter(${ch.chapter})">
            <div class="flex justify-between items-start mb-2">
                <span class="text-xs text-gray-500">Ch ${ch.chapter}</span>
                <span class="text-xs ${stats.due > 0 ? 'text-yellow-500' : 'text-gray-500'}">
                    ${stats.due > 0 ? stats.due + ' due' : stats.total + ' cards'}
                </span>
            </div>
            <div class="font-medium text-sm mb-2">${ch.title}</div>
            <div class="flex items-center gap-2">
                <div class="flex-1 h-1.5 bg-white/5 rounded-full overflow-hidden">
                    <div class="h-full bg-green-500 transition-all" style="width: ${pct}%"></div>
                </div>
                <span class="text-xs text-gray-500">${pct}%</span>
            </div>
        </div>
    `}).join('');
    
    // Show summary stats
    fcRenderSummary();
}

function fcRenderSummary() {
    const summary = document.getElementById('fc-summary');
    if (!summary || !fcStats) return;
    
    const p = fcStats.progress || {};
    const dueToday = p.due_today || 0;
    const totalCards = 247;
    const studied = p.total || 0;
    const mastered = p.mastered || 0;
    
    summary.innerHTML = `
        <div class="grid grid-cols-2 md:grid-cols-4 gap-3 mb-6">
            <div class="p-4 bg-surface-dark rounded-xl border border-white/5 text-center">
                <div class="text-2xl font-bold text-yellow-500">${dueToday}</div>
                <div class="text-xs text-gray-500">Due Today</div>
            </div>
            <div class="p-4 bg-surface-dark rounded-xl border border-white/5 text-center">
                <div class="text-2xl font-bold text-blue-500">${studied}</div>
                <div class="text-xs text-gray-500">Studied</div>
            </div>
            <div class="p-4 bg-surface-dark rounded-xl border border-white/5 text-center">
                <div class="text-2xl font-bold text-green-500">${mastered}</div>
                <div class="text-xs text-gray-500">Mastered</div>
            </div>
            <div class="p-4 bg-surface-dark rounded-xl border border-white/5 text-center">
                <div class="text-2xl font-bold">${fcStats.streak || 0}</div>
                <div class="text-xs text-gray-500">Day Streak</div>
            </div>
        </div>
    `;
}

function fcToggleChapter(chNum) {
    const card = document.querySelector(`[data-chapter="${chNum}"]`);
    if (fcSelectedChapters.has(chNum)) {
        fcSelectedChapters.delete(chNum);
        card.classList.remove('border-yellow-500', 'bg-yellow-500/5');
        card.classList.add('border-white/5');
    } else {
        fcSelectedChapters.add(chNum);
        card.classList.add('border-yellow-500', 'bg-yellow-500/5');
        card.classList.remove('border-white/5');
    }
    fcUpdateSelectedCount();
}

function fcUpdateSelectedCount() {
    const count = Array.from(fcSelectedChapters).reduce((sum, chNum) => {
        const ch = fcData.chapters.find(c => c.chapter === chNum);
        return sum + (ch ? ch.cards.length : 0);
    }, 0);
    document.getElementById('fc-selected-count').textContent = count;
    document.getElementById('fc-start-selected-btn').classList.toggle('hidden', count === 0);
}

function fcStartAll() {
    fcStudyMode = 'all';
    fcCards = fcData.chapters.flatMap(ch => 
        ch.cards.map(c => ({...c, chapter: ch.chapter, title: ch.title}))
    );
    fcShuffleAndStart();
}

function fcStartSelected() {
    fcStudyMode = 'selected';
    fcCards = fcData.chapters
        .filter(ch => fcSelectedChapters.has(ch.chapter))
        .flatMap(ch => ch.cards.map(c => ({...c, chapter: ch.chapter, title: ch.title})));
    fcShuffleAndStart();
}

async function fcStartDue() {
    fcStudyMode = 'due';
    try {
        const resp = await fetch('/api/flashcards/due');
        const dueCards = await resp.json();
        const dueIds = new Set(dueCards.map(d => d.card_id));
        
        fcCards = fcData.chapters.flatMap(ch => 
            ch.cards.map(c => ({...c, chapter: ch.chapter, title: ch.title}))
        ).filter(card => dueIds.has(fcGetCardId(card)));
        
        if (fcCards.length === 0) {
            showToast('No cards due for review!', 'info');
            return;
        }
        fcShuffleAndStart();
    } catch (e) {
        showToast('Failed to load due cards', 'error');
    }
}

function fcShuffleAndStart() {
    // Put due cards first, then new cards, then shuffle within groups
    const today = new Date().toISOString().slice(0, 10);
    const due = [], newCards = [], other = [];
    
    fcCards.forEach(card => {
        const cardId = fcGetCardId(card);
        const prog = fcProgress[cardId];
        if (!prog) newCards.push(card);
        else if (prog.due_date && prog.due_date <= today) due.push(card);
        else other.push(card);
    });
    
    // Shuffle each group
    [due, newCards, other].forEach(arr => {
        for (let i = arr.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [arr[i], arr[j]] = [arr[j], arr[i]];
        }
    });
    
    // Prioritize: due first, then new (limit 20 new per session), then others
    fcCards = [...due, ...newCards.slice(0, 20), ...other];
    
    fcCurrentIndex = 0;
    fcKnown = 0;
    fcUnknown = 0;
    fcMissedCards = [];
    fcIsFlipped = false;
    document.getElementById('fc-chapter-select').classList.add('hidden');
    document.getElementById('fc-study-area').classList.remove('hidden');
    document.getElementById('fc-results-area').classList.add('hidden');
    document.getElementById('fc-total-num').textContent = fcCards.length;
    fcShowCard();
}

function fcShowCard() {
    if (fcCurrentIndex >= fcCards.length) {
        fcShowResults();
        return;
    }
    const card = fcCards[fcCurrentIndex];
    const cardId = fcGetCardId(card);
    const prog = fcProgress[cardId];
    
    document.getElementById('fc-question').textContent = card.q;
    document.getElementById('fc-answer').textContent = card.a;
    document.getElementById('fc-current-num').textContent = fcCurrentIndex + 1;
    document.getElementById('fc-known-count').textContent = fcKnown;
    document.getElementById('fc-unknown-count').textContent = fcUnknown;
    document.getElementById('fc-progress-bar').style.width = 
        `${((fcCurrentIndex) / fcCards.length) * 100}%`;
    
    // Show card state indicator
    const stateEl = document.getElementById('fc-card-state');
    if (stateEl) {
        if (!prog) stateEl.innerHTML = '<span class="text-blue-500">NEW</span>';
        else if (prog.state === 'mastered') stateEl.innerHTML = '<span class="text-green-500">MASTERED</span>';
        else if (prog.state === 'learning') stateEl.innerHTML = '<span class="text-yellow-500">LEARNING</span>';
        else stateEl.innerHTML = '<span class="text-gray-500">REVIEW</span>';
    }
    
    // Reset flip and start timer
    fcIsFlipped = false;
    fcCardStartTime = Date.now();
    document.querySelector('.fc-card-inner').style.transform = 'rotateY(0deg)';
}

function fcFlipCard() {
    fcIsFlipped = !fcIsFlipped;
    document.querySelector('.fc-card-inner').style.transform = 
        fcIsFlipped ? 'rotateY(180deg)' : 'rotateY(0deg)';
}

async function fcMarkCard(isKnown) {
    const card = fcCards[fcCurrentIndex];
    const cardId = fcGetCardId(card);
    const timeTaken = Date.now() - (fcCardStartTime || Date.now());
    
    // Record to backend (rating: 1=Again, 3=Good)
    const rating = isKnown ? 3 : 1;
    try {
        const resp = await fetch('/api/flashcards/review', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({
                card_id: cardId,
                chapter: card.chapter,
                rating: rating,
                time_taken_ms: timeTaken
            })
        });
        const result = await resp.json();
        // Update local progress cache
        fcProgress[cardId] = result;
    } catch (e) {
        console.error('Failed to record review:', e);
    }
    
    if (isKnown) {
        fcKnown++;
    } else {
        fcUnknown++;
        fcMissedCards.push(card);
    }
    fcCurrentIndex++;
    fcShowCard();
}

async function fcShowResults() {
    document.getElementById('fc-study-area').classList.add('hidden');
    document.getElementById('fc-results-area').classList.remove('hidden');
    document.getElementById('fc-final-known').textContent = fcKnown;
    document.getElementById('fc-final-total').textContent = fcKnown + fcUnknown;
    document.getElementById('fc-missed-count').textContent = fcMissedCards.length;
    document.getElementById('fc-restart-missed-btn').classList.toggle('hidden', fcMissedCards.length === 0);
    
    // Refresh stats
    try {
        const resp = await fetch('/api/flashcards/stats');
        fcStats = await resp.json();
    } catch (e) {}
}

function fcRestartMissed() {
    fcCards = [...fcMissedCards];
    fcShuffleAndStart();
}

async function fcBackToChapters() {
    document.getElementById('fc-chapter-select').classList.remove('hidden');
    document.getElementById('fc-study-area').classList.add('hidden');
    document.getElementById('fc-results-area').classList.add('hidden');
    // Refresh stats and chapter display
    try {
        const [progressResp, statsResp] = await Promise.all([
            fetch('/api/flashcards/progress'),
            fetch('/api/flashcards/stats')
        ]);
        const progressList = await progressResp.json();
        fcStats = await statsResp.json();
        fcProgress = {};
        progressList.forEach(p => fcProgress[p.card_id] = p);
        if (fcData) {
            fcRenderChapters();
            fcRenderSummary();
        }
    } catch (e) {
        console.error('Failed to refresh stats:', e);
    }
}

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
