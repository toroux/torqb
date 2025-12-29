let container, closeBtn;
let staffChatMessages = [];
let currentUserId = null;
let showTimestamps = true;
let showFormatting = true;
let typingTimeout = null;
let editingMessageId = null;
let welcomeScreen = null;
let welcomeData = {}; // Store data from welcome screen
let currentReactionPicker = null; // Track the currently open reaction picker

function getResourceName() {
    if (typeof GetParentResourceName === 'function') {
        return GetParentResourceName();
    }
    if (typeof window.GetParentResourceName === 'function') {
        return window.GetParentResourceName();
    }
    return 'staffchat-standalone';
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
    container = document.getElementById('staffChatContainer');
    closeBtn = document.getElementById('close-btn');
    welcomeScreen = document.getElementById('welcomeScreen');
    
    if (!container) {
        console.error('Staff chat container not found!');
        return;
    }
    
    container.classList.add('hidden');
    if (welcomeScreen) {
        welcomeScreen.classList.add('hidden');
    }
    document.body.classList.remove('show');
    
    // Proceed button
    const proceedBtn = document.getElementById('proceedBtn');
    if (proceedBtn) {
        proceedBtn.addEventListener('click', () => {
            proceedToChat();
        });
    }
    
    // Cursor glow effect for welcome screen
    const cursorGlow = document.getElementById('cursorGlow');
    let isWelcomeScreenActive = false;
    
    function updateCursorGlow(e) {
        if (!isWelcomeScreenActive || !cursorGlow) return;
        cursorGlow.style.left = e.clientX + 'px';
        cursorGlow.style.top = e.clientY + 'px';
    }
    
    // Show cursor glow when welcome screen is active
    function showCursorGlow() {
        isWelcomeScreenActive = true;
        if (cursorGlow) {
            cursorGlow.classList.add('active');
        }
        welcomeScreen.addEventListener('mousemove', updateCursorGlow);
    }
    
    // Hide cursor glow when welcome screen is hidden
    function hideCursorGlow() {
        isWelcomeScreenActive = false;
        if (cursorGlow) {
            cursorGlow.classList.remove('active');
        }
        welcomeScreen.removeEventListener('mousemove', updateCursorGlow);
    }
    
    // Store functions for use in showWelcomeScreen
    window.showCursorGlow = showCursorGlow;
    window.hideCursorGlow = hideCursorGlow;
    
    // Options dropdown
    const optionsBtn = document.getElementById('optionsBtn');
    const optionsDropdown = document.getElementById('optionsDropdown');
    if (optionsBtn && optionsDropdown) {
        optionsBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            optionsDropdown.classList.toggle('show');
        });
        
        document.addEventListener('click', (e) => {
            if (!optionsDropdown.contains(e.target) && !optionsBtn.contains(e.target)) {
                optionsDropdown.classList.remove('show');
            }
        });
        
        document.getElementById('toggleTimestamps').addEventListener('click', () => {
            showTimestamps = !showTimestamps;
            updateAllMessageTimestamps();
            optionsDropdown.classList.remove('show');
        });
        
        document.getElementById('toggleFormatting').addEventListener('click', () => {
            showFormatting = !showFormatting;
            updateAllMessageFormatting();
            optionsDropdown.classList.remove('show');
        });
    }
    
    // Formatting toolbar
    const formatBtns = document.querySelectorAll('.format-btn');
    formatBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            const format = btn.dataset.format;
            applyFormatting(format);
            btn.classList.toggle('active');
        });
    });
    
    // Send button
    const sendBtn = document.getElementById('sendBtn');
    if (sendBtn) {
        sendBtn.addEventListener('click', () => {
            sendMessage();
        });
    }
    
    // Enter key to send, typing indicator
    const messageInput = document.getElementById('messageInput');
    if (messageInput) {
        messageInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                sendMessage();
            } else {
                handleTyping();
            }
        });
        
        messageInput.addEventListener('input', () => {
            handleTyping();
        });
    }
    
    // Close button
    if (closeBtn) {
        closeBtn.addEventListener('click', () => {
            postNUI('closeStaffChat', {});
        });
    }
    
    // Profile preview modal close button
    const profileModalClose = document.getElementById('profileModalClose');
    if (profileModalClose) {
        profileModalClose.addEventListener('click', () => {
            closeProfilePreview();
        });
    }
    
    // Profile preview modal overlay click to close
    const profileModalOverlay = document.querySelector('.profile-modal-overlay');
    if (profileModalOverlay) {
        profileModalOverlay.addEventListener('click', () => {
            closeProfilePreview();
        });
    }
    
    // Initialize profile settings
    initializeProfileSettings();
});

function handleTyping() {
    postNUI('typingStatus', { typing: true });
    
    clearTimeout(typingTimeout);
    typingTimeout = setTimeout(() => {
        postNUI('typingStatus', { typing: false });
    }, 3000);
}

function applyFormatting(format) {
    const input = document.getElementById('messageInput');
    const start = input.selectionStart;
    const end = input.selectionEnd;
    const selectedText = input.value.substring(start, end);
    
    let formattedText = '';
    switch(format) {
        case 'bold':
            formattedText = `**${selectedText || 'text'}**`;
            break;
        case 'italic':
            formattedText = `*${selectedText || 'text'}*`;
            break;
        case 'code':
            formattedText = `\`${selectedText || 'code'}\``;
            break;
    }
    
    input.value = input.value.substring(0, start) + formattedText + input.value.substring(end);
    input.focus();
    input.setSelectionRange(start + formattedText.length, start + formattedText.length);
}

function formatMessage(text) {
    if (!showFormatting) {
        return escapeHtml(text);
    }
    
    if (!text || text === '') {
        return '';
    }
    
    // First escape HTML to prevent XSS
    text = escapeHtml(text);
    
    // Process in order to avoid conflicts:
    // 1. Code blocks first (backticks) - preserve these temporarily
    const codePlaceholders = [];
    let codeIndex = 0;
    text = text.replace(/`([^`\n]+)`/g, function(match, content) {
        const placeholder = '___CODEBLOCK_' + codeIndex + '___';
        codePlaceholders.push(content);
        codeIndex++;
        return placeholder;
    });
    
    // 2. Bold: **text** (double asterisks) - must come before italic
    text = text.replace(/\*\*([^*\n]+?)\*\*/g, '<strong>$1</strong>');
    
    // 3. Italic: *text* (single asterisk, but not part of **)
    // Match *text* where * is not part of **
    text = text.replace(/\*([^*\n]+?)\*/g, function(match, content) {
        // Check if this is part of a ** pattern (already processed)
        // If the match doesn't contain <strong> tags, it's safe to make italic
        return '<em>' + content + '</em>';
    });
    
    // 4. Restore code blocks
    codePlaceholders.forEach(function(content, index) {
        text = text.replace('___CODEBLOCK_' + index + '___', '<code>' + content + '</code>');
    });
    
    // 5. Mentions: @fullname (must come before links to avoid conflicts)
    // Match @ followed by full name (letters, spaces, hyphens, apostrophes)
    // Matches names like "John Doe", "Mary-Jane", "O'Brien", "John Michael Smith", etc.
    // Pattern: @ followed by letters, spaces, hyphens, apostrophes - stops at punctuation or end
    text = text.replace(/@([a-zA-Z][a-zA-Z\s\-']*[a-zA-Z]|[a-zA-Z])(?=\s|$|[.,!?;:<>"'])/g, '<span class="message-mention">@$1</span>');
    
    // 6. Links: http:// or https:// URLs (must be last to avoid breaking HTML)
    text = text.replace(/(https?:\/\/[^\s<>"']+)/gi, '<a href="$1" target="_blank" rel="noopener noreferrer">$1</a>');
    
    return text;
}

function sendMessage() {
    // Close any open reaction picker when sending a message
    closeReactionPicker();
    const input = document.getElementById('messageInput');
    const message = input.value.trim();
    
    if (message.length > 0) {
        postNUI('sendStaffMessage', {
            message: message
        });
        
        input.value = '';
        postNUI('typingStatus', { typing: false });
    }
}

function addMessage(sender, message, time, avatar, messageId, isPinned, reactions, edited, fullTimestamp, senderId) {
    const messagesContainer = isPinned ? document.getElementById('pinnedMessages') : document.getElementById('messagesContainer');
    if (!messagesContainer) return;
    
    const messageDiv = document.createElement('div');
    messageDiv.className = 'message';
    messageDiv.dataset.messageId = messageId;
    if (isPinned) messageDiv.classList.add('pinned');
    if (edited) messageDiv.classList.add('edited');
    
    // Create avatar image or use default (make it clickable)
    let avatarHTML = '';
    const safeSender = escapeHtml(sender);
    const safeAvatar = avatar ? escapeHtml(avatar) : '';
    if (avatar) {
        avatarHTML = `<img src="${safeAvatar}" alt="${safeSender}" class="messageAvatar clickable-avatar" data-sender="${safeSender}" data-avatar="${safeAvatar}" onclick="showProfilePreview('${safeSender}', '${safeAvatar}')" onerror="this.style.display='none'">`;
    } else {
        avatarHTML = `<div class="messageAvatar clickable-avatar" data-sender="${safeSender}" data-avatar="" onclick="showProfilePreview('${safeSender}', '')" style="display: flex; align-items: center; justify-content: center; color: #FFD700; font-weight: bold; font-size: 18px; cursor: pointer;">${safeSender.charAt(0).toUpperCase()}</div>`;
    }
    
    const formattedMessage = formatMessage(message);
    const timeDisplay = showTimestamps ? (time || getCurrentTime()) : '';
    const fullTimeDisplay = fullTimestamp ? `<div class="message-time-full">${fullTimestamp}</div>` : '';
    
    const isOwnMessage = senderId && currentUserId && senderId === currentUserId;
    // Escape messageId for use in onclick
    const safeMessageId = escapeHtml(messageId);
    const actionsHTML = `
        <div class="message-actions">
            ${isOwnMessage ? `<button class="message-action-btn" onclick="editMessage('${safeMessageId}')">Edit</button>` : ''}
            <button class="message-action-btn" onclick="deleteMessage('${safeMessageId}')">Delete</button>
            <button class="message-action-btn" onclick="pinMessage('${safeMessageId}')">${isPinned ? 'Unpin' : 'Pin'}</button>
        </div>
    `;
    
    let reactionsHTML = '';
    if (reactions && Object.keys(reactions).length > 0) {
        reactionsHTML = '<div class="message-reactions">';
        for (const [emoji, users] of Object.entries(reactions)) {
            reactionsHTML += `<div class="reaction" onclick="toggleReaction('${messageId}', '${emoji}')">
                <span class="reaction-emoji">${emoji}</span>
                <span class="reaction-count">${users.length}</span>
            </div>`;
        }
        reactionsHTML += `<button class="add-reaction-btn" onclick="showReactionPicker('${messageId}')">+</button>`;
        reactionsHTML += '</div>';
    } else {
        reactionsHTML = `<div class="message-reactions"><button class="add-reaction-btn" onclick="showReactionPicker('${messageId}')">+</button></div>`;
    }
    
    messageDiv.innerHTML = `
        ${avatarHTML}
        <div class="messageContentWrapper">
            <div class="messageHeader">
                <span class="messageSender">${escapeHtml(sender)}</span>
            </div>
            <div class="messageContent message-content-formatted">${formattedMessage}</div>
            ${fullTimeDisplay}
            ${reactionsHTML}
            <span class="messageTime">${timeDisplay}</span>
        </div>
        ${actionsHTML}
    `;
    
    // Use requestAnimationFrame for smoother rendering
    requestAnimationFrame(() => {
        messagesContainer.appendChild(messageDiv);
        
        // Scroll after a brief delay to ensure message is rendered
        requestAnimationFrame(() => {
            if (!isPinned) {
                messagesContainer.scrollTop = messagesContainer.scrollHeight;
            }
        });
    });
}

function editMessage(messageId) {
    const messageDiv = document.querySelector(`[data-message-id="${messageId}"]`);
    if (!messageDiv || editingMessageId) return;
    
    editingMessageId = messageId;
    const messageContent = messageDiv.querySelector('.messageContent');
    const originalText = messageContent.textContent;
    
    const editHTML = `
        <div class="message-editing">
            <input type="text" class="edit-input" value="${escapeHtml(originalText)}" id="editInput-${messageId}">
            <div class="edit-actions">
                <button class="edit-btn" onclick="saveEdit('${messageId}')">Save</button>
                <button class="cancel-edit-btn" onclick="cancelEdit('${messageId}')">Cancel</button>
            </div>
        </div>
    `;
    
    messageContent.style.display = 'none';
    messageContent.insertAdjacentHTML('afterend', editHTML);
    
    const editInput = document.getElementById(`editInput-${messageId}`);
    if (editInput) {
        editInput.focus();
        editInput.select();
    }
}

function saveEdit(messageId) {
    const editInput = document.getElementById(`editInput-${messageId}`);
    if (!editInput) return;
    
    const newText = editInput.value.trim();
    if (newText) {
        postNUI('editMessage', {
            messageId: messageId,
            newMessage: newText
        });
    }
    
    cancelEdit(messageId);
}

function cancelEdit(messageId) {
    const messageDiv = document.querySelector(`[data-message-id="${messageId}"]`);
    if (!messageDiv) return;
    
    const messageContent = messageDiv.querySelector('.messageContent');
    const editingDiv = messageDiv.querySelector('.message-editing');
    
    if (editingDiv) editingDiv.remove();
    if (messageContent) messageContent.style.display = 'block';
    
    editingMessageId = null;
}

function deleteMessage(messageId) {
    // Remove confirm dialog to prevent freezing - delete directly
    // You can add a custom confirmation UI later if needed
    if (messageId) {
        postNUI('deleteMessage', { messageId: messageId });
    }
}

function pinMessage(messageId) {
    postNUI('pinMessage', { messageId: messageId });
}

function toggleReaction(messageId, emoji) {
    postNUI('toggleReaction', { messageId: messageId, emoji: emoji });
}

function closeReactionPicker() {
    if (currentReactionPicker) {
        currentReactionPicker.remove();
        currentReactionPicker = null;
        // Remove the click-outside listener
        document.removeEventListener('click', handleClickOutsidePicker);
    }
}

function handleClickOutsidePicker(event) {
    if (currentReactionPicker && !currentReactionPicker.contains(event.target)) {
        // Check if the click was not on the add-reaction-btn
        const addReactionBtn = event.target.closest('.add-reaction-btn');
        if (!addReactionBtn) {
            closeReactionPicker();
        }
    }
}

function showReactionPicker(messageId) {
    // Close any existing picker first
    closeReactionPicker();
    
    // If clicking the same button, just close it (toggle behavior)
    const messageDiv = document.querySelector(`[data-message-id="${messageId}"]`);
    if (!messageDiv) return;
    
    const existingPicker = messageDiv.querySelector('.reaction-picker');
    if (existingPicker) {
        closeReactionPicker();
        return;
    }
    
    const emojis = ['👍', '❤️', '😂', '😮', '😢', '✅', '❌', '🔥', '⭐'];
    const picker = document.createElement('div');
    picker.className = 'reaction-picker';
    picker.dataset.messageId = messageId;
    picker.style.cssText = 'position: absolute; background: rgba(0,0,0,0.9); border: 1px solid rgba(255,255,255,0.3); border-radius: 8px; padding: 8px; display: flex; gap: 4px; z-index: 1000; bottom: 100%; margin-bottom: 5px;';
    
    emojis.forEach(emoji => {
        const btn = document.createElement('button');
        btn.textContent = emoji;
        btn.style.cssText = 'background: transparent; border: none; font-size: 20px; cursor: pointer; padding: 4px 8px; transition: transform 0.2s ease;';
        btn.onmouseenter = () => {
            btn.style.transform = 'scale(1.2)';
        };
        btn.onmouseleave = () => {
            btn.style.transform = 'scale(1)';
        };
        btn.onclick = (e) => {
            e.stopPropagation(); // Prevent event bubbling
            toggleReaction(messageId, emoji);
            closeReactionPicker();
        };
        picker.appendChild(btn);
    });
    
    // Position the picker relative to the reactions container
    const reactionsContainer = messageDiv.querySelector('.message-reactions');
    if (reactionsContainer) {
        reactionsContainer.style.position = 'relative';
        reactionsContainer.appendChild(picker);
    } else {
        messageDiv.appendChild(picker);
    }
    
    currentReactionPicker = picker;
    
    // Add click-outside listener
    setTimeout(() => {
        document.addEventListener('click', handleClickOutsidePicker);
    }, 0);
    
    // Auto-close after 5 seconds
    setTimeout(() => {
        if (currentReactionPicker === picker) {
            closeReactionPicker();
        }
    }, 5000);
}

function updateAllMessageTimestamps() {
    const messages = document.querySelectorAll('.message');
    messages.forEach(msg => {
        const timeEl = msg.querySelector('.messageTime');
        if (timeEl) {
            timeEl.style.display = showTimestamps ? 'block' : 'none';
        }
    });
}

function updateAllMessageFormatting() {
    const messages = document.querySelectorAll('.message');
    messages.forEach(msg => {
        const contentEl = msg.querySelector('.messageContent');
        if (contentEl) {
            const originalText = contentEl.textContent;
            contentEl.innerHTML = showFormatting ? formatMessage(originalText) : escapeHtml(originalText);
        }
    });
}

// Profile Settings in Staff Chat
function initializeProfileSettings() {
    const profileSettingsAvatar = document.getElementById('profileSettingsAvatar');
    const profileSettingsAvatarPlaceholder = document.getElementById('profileSettingsAvatarPlaceholder');
    const profileSettingsUrlInput = document.getElementById('profileSettingsUrlInput');
    const profileSettingsSaveBtn = document.getElementById('profileSettingsSaveBtn');
    const profileSettingsRemoveBtn = document.getElementById('profileSettingsRemoveBtn');
    
    if (!profileSettingsUrlInput || !profileSettingsSaveBtn || !profileSettingsRemoveBtn) {
        console.error('Profile settings elements not found');
        return;
    }
    
    // Initialize: hide image, show placeholder
    if (profileSettingsAvatar) {
        profileSettingsAvatar.style.display = 'none';
    }
    if (profileSettingsAvatarPlaceholder) {
        profileSettingsAvatarPlaceholder.style.display = 'flex';
        profileSettingsAvatarPlaceholder.textContent = '?';
    }
    
    // Update avatar preview on input
    profileSettingsUrlInput.addEventListener('input', () => {
        const url = profileSettingsUrlInput.value.trim();
        updateProfileSettingsPreview(url);
    });
    
    // Save avatar
    profileSettingsSaveBtn.addEventListener('click', () => {
        const url = profileSettingsUrlInput.value.trim();
        if (!url) {
            return;
        }
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
            return;
        }
        postNUI('saveAvatar', { url: url });
    });
    
    // Remove avatar
    profileSettingsRemoveBtn.addEventListener('click', () => {
        if (profileSettingsUrlInput) {
            profileSettingsUrlInput.value = '';
        }
        updateProfileSettingsPreview('');
        postNUI('removeAvatar', {});
    });
}

function updateProfileSettingsPreview(url) {
    const profileSettingsAvatar = document.getElementById('profileSettingsAvatar');
    const profileSettingsAvatarPlaceholder = document.getElementById('profileSettingsAvatarPlaceholder');
    
    if (!profileSettingsAvatar || !profileSettingsAvatarPlaceholder) return;
    
    if (url && url.trim() !== '' && (url.startsWith('http://') || url.startsWith('https://'))) {
        // Set image source
        profileSettingsAvatar.src = url;
        
        // Show image, hide placeholder
        profileSettingsAvatar.style.display = 'block';
        profileSettingsAvatarPlaceholder.style.display = 'none';
        
        // Handle image load error
        profileSettingsAvatar.onerror = () => {
            profileSettingsAvatar.style.display = 'none';
            profileSettingsAvatarPlaceholder.style.display = 'flex';
            profileSettingsAvatarPlaceholder.textContent = '?';
        };
        
        // Handle successful image load
        profileSettingsAvatar.onload = () => {
            profileSettingsAvatar.style.display = 'block';
            profileSettingsAvatarPlaceholder.style.display = 'none';
        };
    } else {
        // No URL or invalid URL - show placeholder
        profileSettingsAvatar.style.display = 'none';
        profileSettingsAvatarPlaceholder.style.display = 'flex';
        profileSettingsAvatarPlaceholder.textContent = '?';
    }
}

function showProfilePreview(sender, avatar) {
    const modal = document.getElementById('profilePreviewModal');
    const modalAvatar = document.getElementById('profileModalAvatar');
    const modalAvatarPlaceholder = document.getElementById('profileModalAvatarPlaceholder');
    const modalName = document.getElementById('profileModalName');
    
    if (!modal) return;
    
    // Set name
    modalName.textContent = sender;
    
    // Set avatar
    if (avatar && avatar.trim() !== '') {
        modalAvatar.src = avatar;
        modalAvatar.style.display = 'block';
        modalAvatarPlaceholder.style.display = 'none';
        modalAvatarPlaceholder.textContent = '';
    } else {
        modalAvatar.style.display = 'none';
        modalAvatarPlaceholder.style.display = 'flex';
        modalAvatarPlaceholder.textContent = sender.charAt(0).toUpperCase();
    }
    
    // Show modal
    modal.classList.remove('hidden');
    setTimeout(() => {
        modal.classList.add('fade-in');
    }, 10);
}

function closeProfilePreview() {
    const modal = document.getElementById('profilePreviewModal');
    if (!modal) return;
    
    modal.classList.remove('fade-in');
    modal.classList.add('fade-out');
    setTimeout(() => {
        modal.classList.add('hidden');
        modal.classList.remove('fade-out');
    }, 300);
}


function loadMessages(messages) {
    const messagesContainer = document.getElementById('messagesContainer');
    const pinnedContainer = document.getElementById('pinnedMessages');
    if (!messagesContainer || !pinnedContainer) return;
    
    messagesContainer.innerHTML = '';
    pinnedContainer.innerHTML = '';
    
    if (messages && messages.length > 0) {
        messages.forEach(msg => {
            addMessage(
                msg.sender, 
                msg.message, 
                msg.time, 
                msg.avatar, 
                msg.id, 
                msg.pinned || false,
                msg.reactions || {},
                msg.edited || false,
                msg.fullTimestamp || '',
                msg.senderId
            );
        });
    }
}

function updateStaffList(staffList) {
    const staffListEl = document.getElementById('staffList');
    if (!staffListEl) return;
    
    staffListEl.innerHTML = '';
    
    if (staffList && staffList.length > 0) {
        staffList.forEach(staff => {
            const staffEl = document.createElement('div');
            staffEl.className = 'staff-member';
            staffEl.onclick = () => {
                const input = document.getElementById('messageInput');
                if (input) {
                    input.value = `@${staff.name} ` + input.value;
                    input.focus();
                }
            };
            
            staffEl.innerHTML = `
                <img src="${escapeHtml(staff.avatar || '')}" class="staff-avatar" onerror="this.style.display='none'">
                <span class="staff-name">${escapeHtml(staff.name)}</span>
                <div class="staff-status"></div>
            `;
            
            staffListEl.appendChild(staffEl);
        });
    }
}

function updateTypingIndicator(typingUsers) {
    const indicator = document.getElementById('typingIndicator');
    const typingText = document.getElementById('typingText');
    if (!indicator || !typingText) return;
    
    if (typingUsers && typingUsers.length > 0) {
        // Format names with better styling
        let formattedText = '';
        
        if (typingUsers.length === 1) {
            formattedText = `<span class="typing-name">${escapeHtml(typingUsers[0])}</span><span class="typing-action"> is typing</span>`;
        } else if (typingUsers.length === 2) {
            formattedText = `<span class="typing-name">${escapeHtml(typingUsers[0])}</span> and <span class="typing-name">${escapeHtml(typingUsers[1])}</span><span class="typing-action"> are typing</span>`;
        } else if (typingUsers.length === 3) {
            formattedText = `<span class="typing-name">${escapeHtml(typingUsers[0])}</span>, <span class="typing-name">${escapeHtml(typingUsers[1])}</span>, and <span class="typing-name">${escapeHtml(typingUsers[2])}</span><span class="typing-action"> are typing</span>`;
        } else {
            const firstTwo = typingUsers.slice(0, 2).map(name => `<span class="typing-name">${escapeHtml(name)}</span>`).join(', ');
            const remaining = typingUsers.length - 2;
            formattedText = `${firstTwo}, and <span class="typing-name">${remaining} other${remaining > 1 ? 's' : ''}</span><span class="typing-action"> are typing</span>`;
        }
        
        typingText.innerHTML = formattedText;
        indicator.classList.remove('hidden');
    } else {
        indicator.classList.add('hidden');
    }
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function getCurrentTime() {
    const now = new Date();
    return now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
}

function showWelcomeScreen(logoURL, rgbEnabled, rgbBordersEnabled, userId) {
    if (!welcomeScreen) {
        welcomeScreen = document.getElementById('welcomeScreen');
    }
    if (!welcomeScreen) {
        console.error('Welcome screen element not found!');
        return;
    }
    
    console.log('Showing welcome screen...');
    
    // Store data for later use
    welcomeData = {
        logoURL: logoURL,
        rgbEnabled: rgbEnabled,
        rgbBordersEnabled: rgbBordersEnabled,
        currentUserId: userId
    };
    
    // Set logo
    const welcomeLogo = document.getElementById('welcome-logo');
    if (welcomeLogo && logoURL) {
        welcomeLogo.src = logoURL;
        welcomeLogo.style.display = 'block';
    } else if (welcomeLogo) {
        welcomeLogo.style.display = 'none';
    }
    
    // Apply RGB effects if enabled
    const welcomeContainer = document.querySelector('.welcome-container');
    if (welcomeContainer && rgbEnabled) {
        welcomeContainer.style.border = '2px solid transparent';
        welcomeContainer.style.backgroundImage = 
            'linear-gradient(rgba(0, 0, 0, 0.7), rgba(0, 0, 0, 0.7)), ' +
            'linear-gradient(90deg, ' +
            'rgba(255, 215, 0, 0.4) 0%, ' +
            'rgba(255, 223, 0, 0.4) 25%, ' +
            'rgba(255, 215, 0, 0.4) 50%, ' +
            'rgba(255, 223, 0, 0.4) 75%, ' +
            'rgba(255, 215, 0, 0.4) 100%)';
        welcomeContainer.style.backgroundSize = '100% 100%, 200% 200%';
        welcomeContainer.style.animation = 'holographic 3s ease infinite';
    }
    
    // Ensure body has show class first
    document.body.classList.add('show');
    document.body.style.display = 'flex';
    
    // Remove hidden class FIRST
    welcomeScreen.classList.remove('hidden');
    
    // Set all styles directly to ensure visibility
    welcomeScreen.style.cssText = `
        display: flex !important;
        position: fixed !important;
        top: 0 !important;
        left: 0 !important;
        right: 0 !important;
        bottom: 0 !important;
        width: 100vw !important;
        height: 100vh !important;
        background: rgba(0, 0, 0, 0.8) !important;
        align-items: center !important;
        justify-content: center !important;
        z-index: 2000 !important;
        backdrop-filter: blur(10px) !important;
        opacity: 0 !important;
        pointer-events: auto !important;
        visibility: visible !important;
    `;
    
    // Force a reflow
    void welcomeScreen.offsetWidth;
    
    // Trigger fade-in after a brief delay
    setTimeout(() => {
        welcomeScreen.classList.add('fade-in');
        welcomeScreen.style.opacity = '1';
        console.log('Welcome screen should be visible now. Element:', welcomeScreen);
        console.log('Computed display:', window.getComputedStyle(welcomeScreen).display);
        console.log('Computed visibility:', window.getComputedStyle(welcomeScreen).visibility);
        
        // Activate cursor glow effect
        if (window.showCursorGlow) {
            window.showCursorGlow();
        }
    }, 50);
}

function proceedToChat() {
    if (!welcomeScreen) {
        welcomeScreen = document.getElementById('welcomeScreen');
    }
    if (!welcomeScreen) return;
    
    // Hide cursor glow
    if (window.hideCursorGlow) {
        window.hideCursorGlow();
    }
    
    // Fade out welcome screen
    welcomeScreen.classList.remove('fade-in');
    welcomeScreen.classList.add('fade-out');
    
    setTimeout(() => {
        welcomeScreen.classList.add('hidden');
        welcomeScreen.classList.remove('fade-out');
        
        // Request chat room data from client
        postNUI('proceedToChat', {});
    }, 300);
}

// Make functions global for onclick handlers
window.editMessage = editMessage;
window.saveEdit = saveEdit;
window.cancelEdit = cancelEdit;
window.deleteMessage = deleteMessage;
window.pinMessage = pinMessage;
window.toggleReaction = toggleReaction;
window.showReactionPicker = showReactionPicker;
window.showProfilePreview = showProfilePreview;

window.addEventListener('message', (event) => {
    const data = event.data;
    
    if (!container) {
        container = document.getElementById('staffChatContainer');
    }
    
    if (!welcomeScreen) {
        welcomeScreen = document.getElementById('welcomeScreen');
    }
    
    if (!container) return;

    if (data.action === 'openSettings' && data.target === 'settings') {
        // Handle profile settings opening from staff chat
        const settingsContainer = document.getElementById('settingsContainer');
        if (!settingsContainer) return;
        
        // Hide staff chat if open
        if (container && !container.classList.contains('hidden')) {
            container.classList.add('fade-out');
            setTimeout(() => {
                container.classList.add('hidden');
                container.classList.remove('fade-out');
            }, 300);
        }
        
        // Show settings
        settingsContainer.classList.remove('hidden');
        document.body.classList.add('show');
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
        const tabletContainer = settingsContainer.querySelector('.tablet-container');
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
        
    } else if (data.action === 'openStaffChat') {
        console.log('openStaffChat action received', data);
        
        // Hide settings if open
        const settingsContainer = document.getElementById('settingsContainer');
        if (settingsContainer && !settingsContainer.classList.contains('hidden')) {
            settingsContainer.classList.add('fade-out');
            setTimeout(() => {
                settingsContainer.classList.add('hidden');
                settingsContainer.classList.remove('fade-out');
            }, 300);
        }
        
        // Ensure welcome screen element is found
        if (!welcomeScreen) {
            welcomeScreen = document.getElementById('welcomeScreen');
            console.log('Welcome screen element lookup:', welcomeScreen);
        }
        
        // Show welcome screen first
        if (welcomeScreen) {
            console.log('Calling showWelcomeScreen');
            showWelcomeScreen(data.logoURL, data.rgbEnabled, data.rgbBordersEnabled, data.currentUserId);
        } else {
            // Fallback: if welcome screen doesn't exist, go straight to chat
            console.warn('Welcome screen not found, opening chat directly');
            container.classList.remove('hidden');
            document.body.classList.add('show');
            setTimeout(() => {
                container.classList.add('fade-in');
            }, 10);
        }
        
    } else if (data.action === 'openChatRoom') {
        // This is called after proceeding from welcome screen
        // Use stored welcome data
        const chatData = data.logoURL ? data : welcomeData;
        
        // Ensure welcome screen is fully hidden and not blocking
        if (welcomeScreen) {
            welcomeScreen.style.display = 'none';
            welcomeScreen.style.pointerEvents = 'none';
            welcomeScreen.style.zIndex = '-1';
        }
        
        container.classList.remove('hidden');
        document.body.classList.add('show');
        setTimeout(() => {
            container.classList.add('fade-in');
        }, 10);
        
        const headerLogo = document.getElementById('header-logo');
        if (headerLogo && chatData.logoURL) {
            headerLogo.src = chatData.logoURL;
            headerLogo.style.display = 'block';
        } else if (headerLogo) {
            headerLogo.style.display = 'none';
        }
        
        const tabletContainer = document.querySelector('.tablet-container');
        if (tabletContainer && chatData.rgbEnabled) {
            tabletContainer.classList.add('rgb-enabled');
        } else if (tabletContainer) {
            tabletContainer.classList.remove('rgb-enabled');
        }
        
        if (chatData.rgbBordersEnabled) {
            document.body.classList.add('rgb-borders');
        } else {
            document.body.classList.remove('rgb-borders');
        }
        
        if (chatData.currentUserId) {
            currentUserId = chatData.currentUserId;
        }
        
        // Request avatar settings when chat opens
        postNUI('requestAvatarSettings', {});
        
        // Focus input after a longer delay to ensure everything is rendered
        setTimeout(() => {
            const input = document.getElementById('messageInput');
            if (input) {
                // Ensure input is not disabled
                input.disabled = false;
                input.readOnly = false;
                input.style.pointerEvents = 'auto';
                input.style.opacity = '1';
                
                // Focus and click to ensure it's active
                input.focus();
                input.click();
                
                // Force focus again after a brief moment
                setTimeout(() => {
                    input.focus();
                    // Request focus from the browser
                    if (document.activeElement !== input) {
                        input.focus();
                    }
                }, 100);
            }
        }, 300);
    } else if (data.action === 'closeStaffChat') {
        // Close any open reaction picker when closing chat
        closeReactionPicker();
        container.classList.remove('fade-in');
        container.classList.add('fade-out');
        setTimeout(() => {
        container.classList.add('hidden');
            container.classList.remove('fade-out');
        document.body.classList.remove('show');
        }, 300);
    } else if (data.action === 'addMessage') {
        addMessage(
            data.sender, 
            data.message, 
            data.time, 
            data.avatar, 
            data.messageId,
            data.pinned || false,
            data.reactions || {},
            data.edited || false,
            data.fullTimestamp || '',
            data.senderId
        );
    } else if (data.action === 'loadMessages') {
        loadMessages(data.messages);
    } else if (data.action === 'updateMessage') {
        // Close any open reaction picker when message is updated
        closeReactionPicker();
        const messageDiv = document.querySelector(`[data-message-id="${data.messageId}"]`);
        if (messageDiv) {
            const contentEl = messageDiv.querySelector('.messageContent');
            if (contentEl) {
                contentEl.innerHTML = formatMessage(data.newMessage);
                messageDiv.classList.add('edited');
            }
        }
    } else if (data.action === 'removeMessage') {
        // Close any open reaction picker when message is removed
        closeReactionPicker();
        const messageDiv = document.querySelector(`[data-message-id="${data.messageId}"]`);
        if (messageDiv) {
            messageDiv.remove();
        }
    } else if (data.action === 'updateReactions') {
        const messageDiv = document.querySelector(`[data-message-id="${data.messageId}"]`);
        if (messageDiv) {
            const reactionsEl = messageDiv.querySelector('.message-reactions');
            if (reactionsEl) {
                let reactionsHTML = '';
                if (data.reactions && Object.keys(data.reactions).length > 0) {
                    for (const [emoji, users] of Object.entries(data.reactions)) {
                        reactionsHTML += `<div class="reaction" onclick="toggleReaction('${data.messageId}', '${emoji}')">
                            <span class="reaction-emoji">${emoji}</span>
                            <span class="reaction-count">${users.length}</span>
                        </div>`;
                    }
                }
                reactionsHTML += `<button class="add-reaction-btn" onclick="showReactionPicker('${data.messageId}')">+</button>`;
                reactionsEl.innerHTML = reactionsHTML;
            }
        }
    } else if (data.action === 'updateStaffList') {
        updateStaffList(data.staffList);
    } else if (data.action === 'updateTyping') {
        updateTypingIndicator(data.typingUsers);
    } else if (data.action === 'loadAvatarSettings') {
        // Load current avatar in profile settings
        const profileSettingsUrlInput = document.getElementById('profileSettingsUrlInput');
        if (profileSettingsUrlInput) {
            if (data.currentAvatar && data.currentAvatar.trim() !== '') {
                profileSettingsUrlInput.value = data.currentAvatar;
                updateProfileSettingsPreview(data.currentAvatar);
            } else {
                profileSettingsUrlInput.value = '';
                updateProfileSettingsPreview('');
            }
        }
    } else if (data.action === 'avatarSaved') {
        // Update profile settings preview after saving
        const profileSettingsUrlInput = document.getElementById('profileSettingsUrlInput');
        if (profileSettingsUrlInput && data.avatarUrl) {
            profileSettingsUrlInput.value = data.avatarUrl;
            updateProfileSettingsPreview(data.avatarUrl);
        }
    } else if (data.action === 'avatarRemoved') {
        // Clear profile settings after removing
        const profileSettingsUrlInput = document.getElementById('profileSettingsUrlInput');
        if (profileSettingsUrlInput) {
            profileSettingsUrlInput.value = '';
        }
        updateProfileSettingsPreview('');
    }
});

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        // Close profile preview modal if open
        const profileModal = document.getElementById('profilePreviewModal');
        if (profileModal && !profileModal.classList.contains('hidden')) {
            closeProfilePreview();
            return;
        }
        
        // Close any open reaction picker first
        if (currentReactionPicker) {
            closeReactionPicker();
            return; // Don't close chat if picker was open
        }
        
        // Check if welcome screen is open
        if (welcomeScreen && !welcomeScreen.classList.contains('hidden')) {
            // Hide cursor glow
            if (window.hideCursorGlow) {
                window.hideCursorGlow();
            }
            
            // Close welcome screen and unfreeze
            welcomeScreen.classList.remove('fade-in');
            welcomeScreen.classList.add('fade-out');
            setTimeout(() => {
                welcomeScreen.classList.add('hidden');
                welcomeScreen.classList.remove('fade-out');
                welcomeScreen.style.display = 'none';
                document.body.classList.remove('show');
                postNUI('closeStaffChat', {});
            }, 300);
        } else if (container && !container.classList.contains('hidden')) {
            if (editingMessageId) {
                cancelEdit(editingMessageId);
            } else {
                postNUI('closeStaffChat', {});
            }
        } else {
            // Fallback: if nothing is visible but we're frozen, close everything
            if (document.body.classList.contains('show')) {
                if (welcomeScreen) {
                    welcomeScreen.classList.add('hidden');
                    welcomeScreen.style.display = 'none';
                }
                if (container) {
                    container.classList.add('hidden');
                }
                document.body.classList.remove('show');
        postNUI('closeStaffChat', {});
            }
        }
    }
});
