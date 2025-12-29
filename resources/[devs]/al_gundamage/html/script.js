let container, closeBtn;
let currentPage = 'tuning';
let currentWeapon = null;
let currentDamage = 1.0;
let currentRecoil = 1.0;
let playerWeapons = [];
let allWeapons = [];
let allAvailableWeapons = []; // Store all available weapons for filtering

function getResourceName() {
    if (typeof GetParentResourceName === 'function') {
        return GetParentResourceName();
    }
    if (typeof window.GetParentResourceName === 'function') {
        return window.GetParentResourceName();
    }
    return 'derrick_gun_damage';
}

function postNUI(endpoint, data) {
    const resourceName = getResourceName();
    fetch(`https://${resourceName}/${endpoint}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(data || {})
    }).catch(err => {
        console.error('NUI fetch error:', err);
    });
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    container = document.getElementById('tuning-container');
    closeBtn = document.getElementById('close-btn');
    
    if (!container) {
        console.error('Tuning container not found!');
        return;
    }
    
    container.classList.add('hidden');
    document.body.classList.remove('show');
    
    // Navigation tabs
    document.querySelectorAll('.nav-tab').forEach(tab => {
        tab.addEventListener('click', () => {
            const page = tab.getAttribute('data-page');
            switchPage(page);
        });
    });
    
    // Weapon search input
    const weaponSearchInput = document.getElementById('weapon-search-input');
    const weaponResults = document.getElementById('weapon-results');
    
    if (weaponSearchInput && weaponResults) {
        // Filter and show results as user types
        weaponSearchInput.addEventListener('input', (e) => {
            const searchTerm = e.target.value.toLowerCase();
            showWeaponResults(searchTerm);
        });
        
        // When user clicks on search input, show all options
        weaponSearchInput.addEventListener('focus', () => {
            showWeaponResults(weaponSearchInput.value.toLowerCase());
        });
        
        // Hide results when clicking outside
        document.addEventListener('click', (e) => {
            const wrapper = weaponSearchInput.closest('.weapon-search-wrapper');
            if (wrapper && !wrapper.contains(e.target)) {
                weaponResults.classList.remove('show');
            }
        });
        
        // When user clicks outside, if there's a match, select it
        weaponSearchInput.addEventListener('blur', () => {
            setTimeout(() => {
                const searchTerm = weaponSearchInput.value.toLowerCase();
                if (searchTerm) {
                    // Find exact match
                    const exactMatch = allAvailableWeapons.find(w => w.toLowerCase() === searchTerm);
                    if (exactMatch) {
                        weaponSearchInput.value = exactMatch;
                        selectWeapon(exactMatch);
                    } else {
                        // Find first partial match
                        const partialMatch = allAvailableWeapons.find(w => w.toLowerCase().includes(searchTerm));
                        if (partialMatch) {
                            weaponSearchInput.value = partialMatch;
                            selectWeapon(partialMatch);
                        }
                    }
                }
                weaponResults.classList.remove('show');
            }, 200);
        });
    }
    
    // Damage slider
    const damageSlider = document.getElementById('damage-slider');
    if (damageSlider) {
        damageSlider.addEventListener('input', (e) => {
            currentDamage = parseFloat(e.target.value);
            updateDamageValue(currentDamage);
        });
    }
    
    // Recoil slider
    const recoilSlider = document.getElementById('recoil-slider');
    if (recoilSlider) {
        recoilSlider.addEventListener('input', (e) => {
            currentRecoil = parseFloat(e.target.value);
            updateRecoilValue(currentRecoil);
        });
    }
    
    // Arrow buttons for damage
    document.getElementById('damage-decrease')?.addEventListener('click', () => {
        const newValue = Math.max(0.1, currentDamage - 0.05);
        currentDamage = newValue;
        damageSlider.value = newValue;
        updateDamageValue(newValue);
    });
    
    document.getElementById('damage-increase')?.addEventListener('click', () => {
        const newValue = Math.min(2.0, currentDamage + 0.05);
        currentDamage = newValue;
        damageSlider.value = newValue;
        updateDamageValue(newValue);
    });
    
    // Arrow buttons for recoil
    document.getElementById('recoil-decrease')?.addEventListener('click', () => {
        const newValue = Math.max(0.0, currentRecoil - 0.05);
        currentRecoil = newValue;
        recoilSlider.value = newValue;
        updateRecoilValue(newValue);
    });
    
    document.getElementById('recoil-increase')?.addEventListener('click', () => {
        const newValue = Math.min(2.0, currentRecoil + 0.05);
        currentRecoil = newValue;
        recoilSlider.value = newValue;
        updateRecoilValue(newValue);
    });
    
    // Apply button
    document.getElementById('apply-tuning-btn')?.addEventListener('click', () => {
        if (currentWeapon) {
            applyTuning();
        }
    });
    
    // Weapon search
    const weaponSearch = document.getElementById('weapon-search');
    if (weaponSearch) {
        weaponSearch.addEventListener('input', (e) => {
            filterWeapons(e.target.value);
        });
    }
    
    // Close button
    if (closeBtn) {
        closeBtn.addEventListener('click', () => {
            postNUI('close', {});
        });
    }
});

function switchPage(page) {
    currentPage = page;
    
    // Update tab active state
    document.querySelectorAll('.nav-tab').forEach(tab => {
        if (tab.getAttribute('data-page') === page) {
            tab.classList.add('active');
        } else {
            tab.classList.remove('active');
        }
    });
    
    // Show/hide pages
    document.querySelectorAll('.page-content').forEach(p => {
        p.classList.add('hidden');
    });
    
    const pageElement = document.getElementById(page + '-page');
    if (pageElement) {
        pageElement.classList.remove('hidden');
    }
    
    // Load data for specific pages
    if (page === 'weapons') {
        postNUI('getWeapons', {});
    }
}

function selectWeapon(weapon) {
    currentWeapon = weapon;
    document.getElementById('tuning-controls').style.display = 'block';
    
    // Get current values for this weapon
    postNUI('getWeaponStats', { weapon: weapon });
}

function updateDamageValue(value) {
    document.getElementById('damage-value').textContent = value.toFixed(2);
}

function updateRecoilValue(value) {
    document.getElementById('recoil-value').textContent = value.toFixed(2);
}

function applyTuning() {
    if (!currentWeapon) return;
    
    postNUI('applyTuning', {
        weapon: currentWeapon,
        damage: currentDamage,
        recoil: currentRecoil
    });
}

function filterWeapons(searchTerm) {
    const weaponsList = document.getElementById('weapons-list');
    if (!weaponsList) return;
    
    const filtered = allWeapons.filter(weapon => {
        const name = weapon.name || weapon.weapon || '';
        return name.toLowerCase().includes(searchTerm.toLowerCase());
    });
    
    displayWeapons(filtered);
}

function showWeaponResults(searchTerm) {
    const weaponResults = document.getElementById('weapon-results');
    if (!weaponResults || !allAvailableWeapons || allAvailableWeapons.length === 0) return;
    
    // Filter weapons based on search term
    const filtered = allAvailableWeapons.filter(weapon => {
        return weapon.toLowerCase().includes(searchTerm);
    });
    
    // Clear results
    weaponResults.innerHTML = '';
    
    // Show results if there's a search term or if input is focused
    if (searchTerm || document.activeElement === document.getElementById('weapon-search-input')) {
        if (filtered.length > 0) {
            // Limit to 10 results for better performance
            const displayResults = filtered.slice(0, 10);
            displayResults.forEach(weapon => {
                const item = document.createElement('div');
                item.className = 'weapon-result-item';
                item.textContent = weapon;
                item.addEventListener('click', () => {
                    document.getElementById('weapon-search-input').value = weapon;
                    selectWeapon(weapon);
                    weaponResults.classList.remove('show');
                });
                weaponResults.appendChild(item);
            });
            weaponResults.classList.add('show');
        } else if (searchTerm) {
            const item = document.createElement('div');
            item.className = 'weapon-result-item';
            item.textContent = 'No weapons found';
            item.style.color = '#888888';
            item.style.cursor = 'default';
            weaponResults.appendChild(item);
            weaponResults.classList.add('show');
        }
    } else {
        weaponResults.classList.remove('show');
    }
}

function displayWeapons(weapons) {
    const weaponsList = document.getElementById('weapons-list');
    if (!weaponsList) return;
    
    weaponsList.innerHTML = '';
    
    if (weapons.length === 0) {
        weaponsList.innerHTML = '<p style="color: #a0a0a0; text-align: center; padding: 20px;">No weapons found</p>';
        return;
    }
    
    weapons.forEach(weapon => {
        const card = document.createElement('div');
        card.className = 'weapon-card';
        
        const name = weapon.name || weapon.weapon || 'Unknown';
        const damage = weapon.damage !== undefined ? weapon.damage.toFixed(2) : 'N/A';
        const recoil = weapon.recoil !== undefined ? weapon.recoil.toFixed(2) : 'N/A';
        
        card.innerHTML = `
            <h3>${name}</h3>
            <div class="weapon-stat">
                <span class="weapon-stat-label">Damage:</span>
                <span class="weapon-stat-value">${damage}</span>
            </div>
            <div class="weapon-stat">
                <span class="weapon-stat-label">Recoil:</span>
                <span class="weapon-stat-value">${recoil}</span>
            </div>
        `;
        
        weaponsList.appendChild(card);
    });
}

window.addEventListener('message', (event) => {
    const data = event.data;
    
    if (!container) {
        container = document.getElementById('tuning-container');
    }
    
    if (!container) return;

    if (data.action === 'open') {
        container.classList.remove('hidden');
        document.body.classList.add('show');
        
        const headerLogo = document.getElementById('header-logo');
        if (headerLogo && data.logoURL) {
            headerLogo.src = data.logoURL;
            headerLogo.style.display = 'block';
        }
        
        // Apply RGB effect if enabled
        const tabletContainer = document.querySelector('.tablet-container');
        if (tabletContainer && data.rgbEnabled) {
            tabletContainer.classList.add('rgb-enabled');
        }
        
        // Apply RGB borders if enabled
        if (data.rgbBordersEnabled) {
            document.body.classList.add('rgb-borders');
        }
        
        // Load weapons for selector
        postNUI('getPlayerWeapons', {});
        
    } else if (data.action === 'close') {
        container.classList.add('hidden');
        document.body.classList.remove('show');
        currentWeapon = null;
        document.getElementById('tuning-controls').style.display = 'none';
    } else if (data.action === 'updateWeaponList') {
        // Store all available weapons
        if (data.weapons) {
            allAvailableWeapons = data.weapons;
        }
    } else if (data.action === 'updateWeaponStats') {
        // Update current weapon stats
        if (data.damage !== undefined) {
            currentDamage = data.damage;
            document.getElementById('damage-slider').value = currentDamage;
            updateDamageValue(currentDamage);
        }
        if (data.recoil !== undefined) {
            currentRecoil = data.recoil;
            document.getElementById('recoil-slider').value = currentRecoil;
            updateRecoilValue(currentRecoil);
        }
    } else if (data.action === 'updateWeaponsList') {
        // Update weapons list for search page
        allWeapons = data.weapons || [];
        displayWeapons(allWeapons);
    } else if (data.action === 'tuningResult') {
        if (data.success) {
            // Show success message (you can add a notification system here)
            console.log('Tuning applied successfully');
        } else {
            console.error('Tuning failed:', data.error);
        }
    }
});

// Escape key to close
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && container && !container.classList.contains('hidden')) {
        postNUI('close', {});
    }
});

