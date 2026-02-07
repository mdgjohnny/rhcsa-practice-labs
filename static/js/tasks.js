/**
 * RHCSA Practice Labs - Task Management
 * Task loading, filtering, and category management
 */

async function loadTasks() {
    try {
        // Use v2 API with Python grader (more reliable)
        const res = await fetch('/api/v2/tasks');
        allTasks = await res.json();
        renderTaskCheckboxes(allTasks);
        populateCategoryFilter();
    } catch (e) {
        showToast('error', 'Failed to load tasks', e.message);
    }
}

function renderTaskCheckboxes(tasks) {
    const container = document.getElementById('task-checkbox-list');
    if (!tasks.length) {
        container.innerHTML = '<p class="text-gray-400 text-center py-4">No tasks available</p>';
        return;
    }
    
    // Group by category
    const byCategory = {};
    tasks.forEach(t => {
        const cat = t.category || 'Other';
        if (!byCategory[cat]) byCategory[cat] = [];
        byCategory[cat].push(t);
    });

    const categoryIcons = {
        'networking': { icon: 'lan', color: 'blue' },
        'storage': { icon: 'hard_drive', color: 'orange' },
        'local-storage': { icon: 'hard_drive', color: 'orange' },
        'users': { icon: 'group', color: 'blue' },
        'security': { icon: 'security', color: 'red' },
        'selinux': { icon: 'shield', color: 'red' },
        'services': { icon: 'settings_applications', color: 'purple' },
        'containers': { icon: 'deployed_code', color: 'cyan' },
        'file-systems': { icon: 'folder_open', color: 'green' },
        'essential-tools': { icon: 'construction', color: 'yellow' },
        'deploy-maintain': { icon: 'cloud_sync', color: 'indigo' },
        'default': { icon: 'folder', color: 'gray' }
    };
    
    container.innerHTML = Object.entries(byCategory).map(([cat, catTasks]) => {
        const key = Object.keys(categoryIcons).find(k => cat.toLowerCase().includes(k)) || 'default';
        const { icon, color } = categoryIcons[key];
        return `
        <details open class="group bg-surface-dark border border-white/10 rounded-xl overflow-hidden">
            <summary class="flex items-center justify-between p-4 cursor-pointer hover:bg-white/5 transition-colors select-none">
                <div class="flex items-center gap-3">
                    <div class="p-2 bg-${color}-500/10 rounded-lg text-${color}-400">
                        <span class="material-symbols-outlined">${icon}</span>
                    </div>
                    <div>
                        <h3 class="text-lg font-bold capitalize">${cat.replace(/-/g, ' ')}</h3>
                    </div>
                </div>
                <div class="flex items-center gap-4">
                    <span class="px-2 py-1 rounded bg-black/40 text-xs font-mono text-gray-400 border border-white/5">${catTasks.length} Tasks</span>
                    <span class="material-symbols-outlined text-gray-500 transform group-open:rotate-180 transition-transform">expand_more</span>
                </div>
            </summary>
            <div class="border-t border-white/10">
                ${catTasks.map((t, idx) => `
                    <label class="flex items-start gap-4 p-4 hover:bg-white/5 cursor-pointer border-b border-white/5 last:border-0 transition-colors group/item">
                        <input type="checkbox" value="${t.id}" onchange="updateSelectedCount()" class="task-checkbox mt-1 w-5 h-5 rounded border-gray-600 bg-background-dark text-primary focus:ring-primary focus:ring-offset-0 transition-all"/>
                        <div class="flex-1">
                            <div class="flex items-center gap-2 mb-1">
                                <span class="text-xs font-mono text-gray-400 bg-gray-700/50 px-1.5 py-0.5 rounded">${t.id}</span>
                                <span class="text-xs px-1.5 py-0.5 rounded bg-gray-700/30 text-gray-400 border border-white/5">${t.target || 'node1'}</span>
                                ${t.cloud_compatible === false ? '<span class="text-xs px-1.5 py-0.5 rounded text-orange-400 border border-orange-500/20 bg-orange-500/10" title="This task requires changing network settings that may break cloud VM connectivity">Local Only</span>' : ''}
                                <span class="ml-auto text-xs text-gray-500">${t.points || 1}pt</span>
                            </div>
                            <h4 class="text-white font-medium mb-1 group-hover/item:text-primary transition-colors">${t.title || t.id}</h4>
                            <p class="text-gray-400 text-sm leading-relaxed">${t.description || ''}</p>
                        </div>
                    </label>
                `).join('')}
            </div>
        </details>
    `}).join('');

    updateSelectedCount();
}

function updateSelectedCount() {
    const selected = document.querySelectorAll('.task-checkbox:checked').length;
    const total = document.querySelectorAll('.task-checkbox').length;
    const countEl = document.getElementById('selected-count');
    const totalEl = document.getElementById('total-count');
    const durationEl = document.getElementById('estimated-duration');
    
    if (countEl) countEl.childNodes[0].textContent = String(selected).padStart(2, '0');
    if (totalEl) totalEl.textContent = `/${total}`;
    if (durationEl) durationEl.textContent = `~${selected * 3} Minutes`;
}

function filterTasks() {
    const search = document.getElementById('task-search')?.value.toLowerCase() || '';
    const cat = document.getElementById('category-filter')?.value || '';
    let filtered = allTasks;
    if (cat) filtered = filtered.filter(t => t.category === cat);
    if (search) filtered = filtered.filter(t => 
        (t.title || '').toLowerCase().includes(search) ||
        (t.description || '').toLowerCase().includes(search) || 
        (t.id || '').toLowerCase().includes(search)
    );
    renderTaskCheckboxes(filtered);
}

function populateCategoryFilter() {
    const container = document.getElementById('category-checkboxes');
    const categories = [...new Set(allTasks.map(t => t.category).filter(Boolean))].sort();
    container.innerHTML = categories.map(c => `
        <label class="flex items-center gap-3 px-4 py-2 hover:bg-white/5 cursor-pointer">
            <input type="checkbox" value="${c}" onchange="filterByCategory()" checked class="category-cb w-4 h-4 rounded border-gray-600 bg-background-dark text-primary focus:ring-primary">
            <span class="text-gray-300 text-sm capitalize">${c.replace(/-/g, ' ')}</span>
        </label>
    `).join('');
}

function toggleCategoryDropdown() {
    const dropdown = document.getElementById('category-dropdown');
    dropdown.classList.toggle('hidden');
}

// Close dropdown when clicking outside
document.addEventListener('click', (e) => {
    const dropdown = document.getElementById('category-dropdown');
    const btn = document.getElementById('category-filter-btn');
    if (dropdown && btn && !dropdown.contains(e.target) && !btn.contains(e.target)) {
        dropdown.classList.add('hidden');
    }
});

function toggleAllCategories() {
    const allChecked = document.getElementById('cat-all').checked;
    document.querySelectorAll('.category-cb').forEach(cb => cb.checked = allChecked);
    filterByCategory();
}

function filterByCategory() {
    const checkboxes = document.querySelectorAll('.category-cb');
    const selectedCats = [...checkboxes].filter(cb => cb.checked).map(cb => cb.value);
    const allCheckbox = document.getElementById('cat-all');
    
    // Update "All" checkbox state
    if (allCheckbox) {
        allCheckbox.checked = selectedCats.length === checkboxes.length;
    }
    
    // Update label
    const label = document.getElementById('category-filter-label');
    if (label) {
        if (selectedCats.length === 0) {
            label.textContent = 'No categories';
        } else if (selectedCats.length === checkboxes.length) {
            label.textContent = 'All Categories';
        } else if (selectedCats.length <= 2) {
            label.textContent = selectedCats.map(c => c.replace(/-/g, ' ')).join(', ');
        } else {
            label.textContent = `${selectedCats.length} categories`;
        }
    }
    
    // Filter tasks
    const filtered = selectedCats.length === 0 ? [] : 
        selectedCats.length === checkboxes.length ? allTasks :
        allTasks.filter(t => selectedCats.includes(t.category));
    renderTaskCheckboxes(filtered);
}

function selectAllTasks() {
    document.querySelectorAll('.task-checkbox').forEach(cb => cb.checked = true);
    updateSelectedCount();
}

function deselectAllTasks() {
    document.querySelectorAll('.task-checkbox').forEach(cb => cb.checked = false);
    updateSelectedCount();
}

function getSelectedTaskIds() {
    return Array.from(document.querySelectorAll('.task-checkbox:checked')).map(cb => cb.value);
}

// Category Grid
function populateCategoryGrid() {
    if (!allTasks.length) {
        loadTasks().then(renderCategoryGrid);
    } else {
        renderCategoryGrid();
    }
}

function renderCategoryGrid() {
    const grid = document.getElementById('category-grid');
    const categories = [...new Set(allTasks.map(t => t.category).filter(Boolean))].sort();
    
    if (!categories.length) {
        grid.innerHTML = '<p class="text-gray-400 text-center py-8 col-span-full">No categories found</p>';
        return;
    }
    
    const categoryMeta = {
        'essential-tools': { icon: 'construction', desc: 'File handling, grep, regex, pipelines, and IO redirection.' },
        'operate-systems': { icon: 'settings_power', desc: 'Boot, reboot, interrupt boot process, and manage system processes.' },
        'local-storage': { icon: 'hard_drive', desc: 'Partitions, LVM logical volumes, extending volumes, swap space.' },
        'file-systems': { icon: 'folder_open', desc: 'Create vfat, ext4, xfs systems. Mount and unmount, configure autofs.' },
        'deploy-maintain': { icon: 'cloud_sync', desc: 'Networking, time synchronization, logging, package management.' },
        'networking': { icon: 'lan', desc: 'Network configuration, hostnames, DNS, and routing.' },
        'users': { icon: 'group', desc: 'User creation, group management, password aging, LDAP auth.' },
        'security': { icon: 'security', desc: 'Firewalls, SELinux contexts, booleans, SSH configuration.' },
        'selinux': { icon: 'shield', desc: 'SELinux modes, contexts, booleans, and troubleshooting.' },
        'services': { icon: 'dns', desc: 'Systemd services, targets, and process management.' },
        'containers': { icon: 'deployed_code', desc: 'Podman containers, images, and rootless containers.' },
        'default': { icon: 'folder', desc: 'Practice tasks for this category.' }
    };
    
    grid.innerHTML = categories.map((cat, idx) => {
        const count = allTasks.filter(t => t.category === cat).length;
        const key = Object.keys(categoryMeta).find(k => cat.toLowerCase().includes(k)) || 'default';
        const meta = categoryMeta[key] || categoryMeta.default;
        return `
            <div onclick="toggleCategorySelection('${cat}', this)" 
                 data-category="${cat}"
                 class="category-card group flex flex-col text-left h-full rounded-lg border-2 border-white/10 bg-[#1b1b1b] p-6 hover:border-primary/50 transition-all duration-300 relative overflow-hidden cursor-pointer">
                <div class="absolute top-3 right-3">
                    <div class="category-check w-6 h-6 rounded-full border-2 border-gray-600 flex items-center justify-center transition-all">
                        <span class="material-symbols-outlined text-white text-sm opacity-0">check</span>
                    </div>
                </div>
                <div class="mb-5 flex justify-between items-start">
                    <div class="inline-flex h-12 w-12 items-center justify-center rounded bg-white/5 text-primary group-hover:bg-primary/20 transition-colors duration-300">
                        <span class="material-symbols-outlined">${meta.icon}</span>
                    </div>
                </div>
                <div class="flex flex-col gap-2 flex-1">
                    <h3 class="text-lg font-bold group-hover:text-primary transition-colors capitalize">${cat.replace(/-/g, ' ')}</h3>
                    <p class="text-gray-500 text-sm leading-relaxed mb-4">${meta.desc}</p>
                    <div class="mt-auto pt-4 border-t border-white/5 flex items-center justify-between text-xs font-bold uppercase tracking-wider text-gray-500">
                        <span class="text-primary">Obj ${idx + 1}</span>
                        <span>${count} Tasks</span>
                    </div>
                </div>
            </div>
        `;
    }).join('');
}

const selectedCategories = new Set();

function toggleCategorySelection(category, element) {
    if (selectedCategories.has(category)) {
        selectedCategories.delete(category);
        element.classList.remove('border-primary', 'bg-primary/5');
        element.classList.add('border-white/10');
        element.querySelector('.category-check').classList.remove('bg-primary', 'border-primary');
        element.querySelector('.category-check').classList.add('border-gray-600');
        element.querySelector('.category-check span').classList.add('opacity-0');
    } else {
        selectedCategories.add(category);
        element.classList.add('border-primary', 'bg-primary/5');
        element.classList.remove('border-white/10');
        element.querySelector('.category-check').classList.add('bg-primary', 'border-primary');
        element.querySelector('.category-check').classList.remove('border-gray-600');
        element.querySelector('.category-check span').classList.remove('opacity-0');
    }
    updateCategorySelectionUI();
}

function updateCategorySelectionUI() {
    const count = selectedCategories.size;
    const countEl = document.getElementById('category-selection-count');
    const btn = document.getElementById('start-categories-btn');
    if (countEl) countEl.textContent = `${count} selected`;
    if (btn) btn.disabled = count === 0;
}

function startSelectedCategoriesPractice() {
    if (selectedCategories.size === 0) {
        showToast('warning', 'Select at least one category');
        return;
    }
    selectedTasks = allTasks.filter(t => selectedCategories.has(t.category));
    if (!selectedTasks.length) {
        showToast('warning', 'No tasks in selected categories');
        return;
    }
    const catNames = [...selectedCategories].map(c => c.replace(/-/g, ' ')).join(', ');
    currentMode = 'practice';
    taskResults.clear();
    currentTaskIndex = 0;
    document.getElementById('breadcrumb-mode').textContent = `Practice: ${selectedCategories.size > 2 ? selectedCategories.size + ' categories' : catNames}`;
    populateSidebarCategoryFilter();
    renderTaskList();
    showTaskDetail(selectedTasks[0].id);
    updateTaskNavigation();
    showView('exam-running');
    saveSession();
    selectedCategories.clear(); // Reset for next time
}

function startCategoryPractice(category) {
    selectedTasks = allTasks.filter(t => t.category === category);
    if (!selectedTasks.length) {
        showToast('warning', 'No tasks in this category');
        return;
    }
    currentMode = 'practice';
    taskResults.clear();
    currentTaskIndex = 0;
    document.getElementById('breadcrumb-mode').textContent = `Practice: ${category}`;
    populateSidebarCategoryFilter();
    renderTaskList();
    showTaskDetail(selectedTasks[0].id);
    updateTaskNavigation();
    showView('exam-running');
    saveSession();
}

