/**
 * RHCSA Practice Labs - Statistics View
 * Stats display, flashcard stats, and data management
 */

function showStatsTab(tab) {
    currentStatsTab = tab;
    // Update tab buttons
    document.getElementById('stats-tab-practice').classList.toggle('bg-primary', tab === 'practice');
    document.getElementById('stats-tab-practice').classList.toggle('text-white', tab === 'practice');
    document.getElementById('stats-tab-practice').classList.toggle('text-gray-400', tab !== 'practice');
    document.getElementById('stats-tab-flashcards').classList.toggle('bg-primary', tab === 'flashcards');
    document.getElementById('stats-tab-flashcards').classList.toggle('text-white', tab === 'flashcards');
    document.getElementById('stats-tab-flashcards').classList.toggle('text-gray-400', tab !== 'flashcards');
    // Show/hide content
    document.getElementById('stats-practice-content').classList.toggle('hidden', tab !== 'practice');
    document.getElementById('stats-flashcards-content').classList.toggle('hidden', tab !== 'flashcards');
    // Load flashcard stats if needed
    if (tab === 'flashcards') loadFlashcardStats();
}

async function loadStats() {
    try {
        const res = await fetch('/api/stats');
        const stats = await res.json();
        
        // Summary
        document.getElementById('stats-summary').innerHTML = `
            <div class="bg-surface-dark rounded-xl border border-white/5 p-6 text-center">
                <div class="text-4xl font-bold mb-1">${stats.total_attempts || 0}</div>
                <div class="text-sm text-gray-400">Total Attempts</div>
            </div>
            <div class="bg-surface-dark rounded-xl border border-white/5 p-6 text-center">
                <div class="text-4xl font-bold text-emerald-500 mb-1">${stats.passed || 0}</div>
                <div class="text-sm text-gray-400">Passed</div>
            </div>
            <div class="bg-surface-dark rounded-xl border border-white/5 p-6 text-center">
                <div class="text-4xl font-bold mb-1">${stats.pass_rate || 0}%</div>
                <div class="text-sm text-gray-400">Pass Rate</div>
            </div>
        `;
        
        // Category stats
        const catContainer = document.getElementById('category-stats');
        const cats = Object.entries(stats.categories || {});
        if (cats.length) {
            catContainer.innerHTML = cats.map(([cat, data]) => `
                <div class="space-y-2">
                    <div class="flex justify-between text-sm">
                        <span>${cat}</span>
                        <span class="text-gray-400">${data.percentage || 0}%</span>
                    </div>
                    <div class="w-full bg-white/5 rounded-full h-2">
                        <div class="h-2 rounded-full ${data.percentage >= 70 ? 'bg-emerald-500' : data.percentage >= 50 ? 'bg-amber-500' : 'bg-red-500'}" 
                             style="width: ${data.percentage || 0}%"></div>
                    </div>
                </div>
            `).join('');
        } else {
            catContainer.innerHTML = '<p class="text-gray-400 text-center py-4">No data yet</p>';
        }
        
        // Weak areas
        const weakContainer = document.getElementById('weak-areas');
        if (stats.weak_areas?.length) {
            weakContainer.innerHTML = `
                <h3 class="font-bold mb-3 flex items-center gap-2">
                    <span class="material-symbols-outlined text-amber-500">warning</span> Areas to Improve
                </h3>
                <div class="space-y-2">
                    ${stats.weak_areas.map(w => `
                        <div class="flex items-center justify-between p-2 rounded bg-amber-500/5 border border-amber-500/10">
                            <span class="text-sm">${w.category}</span>
                            <span class="text-sm text-amber-400">${w.percentage}%</span>
                        </div>
                    `).join('')}
                </div>
            `;
        } else {
            weakContainer.innerHTML = '';
        }
    } catch (e) {
        document.getElementById('stats-summary').innerHTML = '<p class="text-red-400 text-center py-4 col-span-full">Failed to load statistics</p>';
    }
}

async function loadFlashcardStats() {
    try {
        const [statsRes, dataRes] = await Promise.all([
            fetch('/api/flashcards/stats'),
            fcData ? Promise.resolve({json: () => fcData}) : fetch('/flashcards.json')
        ]);
        const stats = await statsRes.json();
        if (!fcData) fcData = await dataRes.json();
        
        const p = stats.progress || {};
        const totalCards = 247;
        
        // Summary stats
        document.getElementById('fc-stats-summary').innerHTML = `
            <div class="bg-surface-dark rounded-xl border border-white/5 p-6 text-center">
                <div class="text-4xl font-bold text-yellow-500 mb-1">${p.due_today || 0}</div>
                <div class="text-sm text-gray-400">Due Today</div>
            </div>
            <div class="bg-surface-dark rounded-xl border border-white/5 p-6 text-center">
                <div class="text-4xl font-bold mb-1">${stats.streak || 0}</div>
                <div class="text-sm text-gray-400">Day Streak</div>
            </div>
            <div class="bg-surface-dark rounded-xl border border-white/5 p-6 text-center">
                <div class="text-4xl font-bold text-green-500 mb-1">${p.mastered || 0}</div>
                <div class="text-sm text-gray-400">Mastered</div>
            </div>
            <div class="bg-surface-dark rounded-xl border border-white/5 p-6 text-center">
                <div class="text-4xl font-bold mb-1">${stats.accuracy || 0}%</div>
                <div class="text-sm text-gray-400">Accuracy</div>
            </div>
        `;
        
        // Chapter progress
        const chapterContainer = document.getElementById('fc-chapter-stats');
        const chapterMap = {};
        (stats.by_chapter || []).forEach(c => chapterMap[c.chapter] = c);
        
        chapterContainer.innerHTML = fcData.chapters.map(ch => {
            const chStats = chapterMap[ch.chapter] || { total: 0, mastered: 0 };
            const pct = ch.cards.length > 0 ? Math.round((chStats.mastered / ch.cards.length) * 100) : 0;
            return `
                <div class="flex items-center gap-4">
                    <div class="w-20 text-xs text-gray-500">Ch ${ch.chapter}</div>
                    <div class="flex-1">
                        <div class="flex justify-between text-sm mb-1">
                            <span>${ch.title}</span>
                            <span class="text-gray-400">${chStats.mastered}/${ch.cards.length}</span>
                        </div>
                        <div class="w-full bg-white/5 rounded-full h-2">
                            <div class="h-2 rounded-full bg-green-500 transition-all" style="width: ${pct}%"></div>
                        </div>
                    </div>
                </div>
            `;
        }).join('');
        
        // Daily stats
        const dailyContainer = document.getElementById('fc-daily-stats');
        const daily = stats.daily_stats || [];
        if (daily.length) {
            dailyContainer.innerHTML = daily.slice(0, 7).map(d => {
                const date = new Date(d.date).toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
                const acc = d.cards_studied > 0 ? Math.round((d.correct / d.cards_studied) * 100) : 0;
                return `
                    <div class="flex items-center justify-between py-2 border-b border-white/5">
                        <span class="text-sm text-gray-400">${date}</span>
                        <div class="flex items-center gap-4">
                            <span class="text-sm">${d.cards_studied} cards</span>
                            <span class="text-sm ${acc >= 70 ? 'text-green-500' : acc >= 50 ? 'text-yellow-500' : 'text-red-500'}">${acc}%</span>
                        </div>
                    </div>
                `;
            }).join('');
        } else {
            dailyContainer.innerHTML = '<p class="text-gray-400 text-center py-4">No activity yet</p>';
        }
    } catch (e) {
        console.error('Failed to load flashcard stats:', e);
        document.getElementById('fc-stats-summary').innerHTML = '<p class="text-red-400 text-center py-4 col-span-full">Failed to load flashcard statistics</p>';
    }
}

async function resetFlashcardProgress() {
    if (!confirm('Are you sure you want to reset all flashcard progress? This cannot be undone.')) return;
    try {
        await fetch('/api/flashcards/reset', { method: 'POST' });
        fcProgress = {};
        showToast('Flashcard progress reset', 'success');
        loadFlashcardStats();
    } catch (e) {
        showToast('Failed to reset progress', 'error');
    }
}

async function clearAllResults() {
    if (!confirm('Clear all history? This cannot be undone.')) return;
    try {
        await fetch('/api/results', { method: 'DELETE' });
        showToast('success', 'History Cleared');
        loadStats();
    } catch (e) {
        showToast('error', 'Failed to clear history', e.message);
    }
}
