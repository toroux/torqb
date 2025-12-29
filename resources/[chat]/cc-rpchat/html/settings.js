let settingsContainer, settingsCloseBtn;

function getResourceName() {
    if (typeof GetParentResourceName === 'function') {
        return GetParentResourceName();
    }
    if (typeof window.GetParentResourceName === 'function') {
        return window.GetParentResourceName();
    }
    return 'cc-rpchat';
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
    settingsContainer = document.getElementById('settingsContainer');
    settingsCloseBtn = document.getElementById('settings-close-btn') || document.getElementById('close-btn');
    
    if (!settingsContainer) {
        console.error('Settings container not found!');
        return;
    }
    
    settingsContainer.classList.add('hidden');
    document.body.classList.remove('show');
    
    // Close button
    if (settingsCloseBtn) {
        settingsCloseBtn.addEventListener('click', () => {
            postNUI('closeSettings', {});
        });
    }
    
    // Avatar settings
    const avatarUrlInput = document.getElementById('avatarUrlInput');
    const avatarPreview = document.getElementById('avatarPreview');
    const avatarPreviewPlaceholder = document.getElementById('avatarPreviewPlaceholder');
    const saveAvatarBtn = document.getElementById('saveAvatarBtn');
    const removeAvatarBtn = document.getElementById('removeAvatarBtn');
    
    if (avatarUrlInput) {
        avatarUrlInput.addEventListener('input', () => {
            updateAvatarPreview(avatarUrlInput.value);
        });
    }
    
    if (saveAvatarBtn) {
        saveAvatarBtn.addEventListener('click', () => {
            saveAvatar();
        });
    }
    
    if (removeAvatarBtn) {
        removeAvatarBtn.addEventListener('click', () => {
            removeAvatar();
        });
    }
});

function updateAvatarPreview(url) {
    const avatarPreview = document.getElementById('avatarPreview');
    const avatarPreviewPlaceholder = document.getElementById('avatarPreviewPlaceholder');
    
    if (url && url.trim() !== '' && (url.startsWith('http://') || url.startsWith('https://'))) {
        avatarPreview.src = url;
        avatarPreview.style.display = 'block';
        avatarPreviewPlaceholder.style.display = 'none';
        
        // Handle image load error
        avatarPreview.onerror = () => {
            avatarPreview.style.display = 'none';
            avatarPreviewPlaceholder.style.display = 'flex';
            avatarPreviewPlaceholder.textContent = 'Invalid Image';
        };
    } else {
        avatarPreview.style.display = 'none';
        avatarPreviewPlaceholder.style.display = 'flex';
        avatarPreviewPlaceholder.textContent = 'No Avatar';
    }
}

function saveAvatar() {
    const avatarUrlInput = document.getElementById('avatarUrlInput');
    const url = avatarUrlInput.value.trim();
    
    if (!url) {
        alert('Please enter an avatar URL');
        return;
    }
    
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
        alert('URL must start with http:// or https://');
        return;
    }
    
    postNUI('saveAvatar', { url: url });
}

function removeAvatar() {
    postNUI('removeAvatar', {});
}

window.addEventListener('message', (event) => {
    const data = event.data;
    
    if (!settingsContainer) {
        settingsContainer = document.getElementById('settingsContainer');
    }
    
    if (!settingsContainer) return;

    if (data.action === 'openSettings' && data.target === 'settings') {
        // Hide staff chat if open
        const staffChatContainer = document.getElementById('staffChatContainer');
        if (staffChatContainer && !staffChatContainer.classList.contains('hidden')) {
            staffChatContainer.classList.add('fade-out');
            setTimeout(() => {
                staffChatContainer.classList.add('hidden');
                staffChatContainer.classList.remove('fade-out');
            }, 300);
        }
        
        settingsContainer.classList.remove('hidden');
        document.body.classList.add('show');
        // Trigger fade in
        setTimeout(() => {
            settingsContainer.classList.add('fade-in');
        }, 10);
        
        const headerLogo = document.getElementById('settings-header-logo');
        if (headerLogo && data.logoURL) {
            headerLogo.src = data.logoURL;
            headerLogo.style.display = 'block';
        } else if (headerLogo) {
            headerLogo.style.display = 'none';
        }
        
        // Apply RGB effect if enabled
        const tabletContainer = document.querySelector('.tablet-container');
        if (tabletContainer && data.rgbEnabled) {
            tabletContainer.classList.add('rgb-enabled');
        } else if (tabletContainer) {
            tabletContainer.classList.remove('rgb-enabled');
        }
        
        // Apply RGB borders if enabled
        if (data.rgbBordersEnabled) {
            document.body.classList.add('rgb-borders');
        } else {
            document.body.classList.remove('rgb-borders');
        }
        
        // Request current avatar settings
        postNUI('requestAvatarSettings', {});
        
        // Focus on input
        setTimeout(() => {
            const input = document.getElementById('avatarUrlInput');
            if (input) input.focus();
        }, 100);
        
    } else if (data.action === 'closeSettings') {
        settingsContainer.classList.remove('fade-in');
        settingsContainer.classList.add('fade-out');
        setTimeout(() => {
            settingsContainer.classList.add('hidden');
            settingsContainer.classList.remove('fade-out');
            document.body.classList.remove('show');
        }, 300);
    } else if (data.action === 'loadAvatarSettings') {
        // Load current avatar URL if exists
        const avatarUrlInput = document.getElementById('avatarUrlInput');
        if (avatarUrlInput && data.currentAvatar) {
            avatarUrlInput.value = data.currentAvatar;
            updateAvatarPreview(data.currentAvatar);
        }
    } else if (data.action === 'avatarSaved') {
        const avatarUrlInput = document.getElementById('avatarUrlInput');
        if (avatarUrlInput && data.avatarUrl) {
            updateAvatarPreview(data.avatarUrl);
        }
    } else if (data.action === 'avatarRemoved') {
        const avatarUrlInput = document.getElementById('avatarUrlInput');
        if (avatarUrlInput) {
            avatarUrlInput.value = '';
        }
        updateAvatarPreview('');
    }
});

// Escape key to close
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && settingsContainer && !settingsContainer.classList.contains('hidden')) {
        postNUI('closeSettings', {});
    }
});

