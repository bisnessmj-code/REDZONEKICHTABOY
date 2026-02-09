/**
 * Staff Chat Module - Panel Admin Fight League
 * Apple-style chat interface for staff communication
 */

const StaffChatModule = {
    messages: [],
    currentUser: null,
    isAdmin: false,
    refreshInterval: null,
    lastMessageId: 0,

    /**
     * Initialize the module
     */
    init() {
        // Send button click
        document.getElementById('staffChatSend').addEventListener('click', () => {
            this.sendMessage();
        });

        // Enter key to send
        document.getElementById('staffChatInput').addEventListener('keypress', (e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                this.sendMessage();
            }
        });

        // Refresh button
        document.getElementById('staffChatRefresh').addEventListener('click', () => {
            this.loadMessages();
        });

        // Clear all button (admin only)
        document.getElementById('staffChatClearAll').addEventListener('click', () => {
            this.confirmClearAll();
        });

        // Start auto-refresh
        this.startAutoRefresh();
    },

    /**
     * Set current user info
     */
    setCurrentUser(user) {
        this.currentUser = user;
        this.isAdmin = user && (user.group === 'admin' || user.group === 'owner');

        // Show/hide admin buttons
        const clearAllBtn = document.getElementById('staffChatClearAll');
        if (clearAllBtn) {
            if (this.isAdmin) {
                clearAllBtn.classList.remove('hidden');
            } else {
                clearAllBtn.classList.add('hidden');
            }
        }

    },

    /**
     * Load messages from server
     */
    async loadMessages() {
        try {
            const response = await API.getStaffChatMessages();

            if (response && response.success) {
                const newMessages = response.messages || [];

                // Update online count
                if (response.onlineStaff !== undefined) {
                    document.getElementById('staffChatOnline').textContent = response.onlineStaff + ' en ligne';
                }

                // Check if messages changed (compare IDs and count)
                const oldIds = this.messages.map(m => m.id).join(',');
                const newIds = newMessages.map(m => m.id).join(',');

                if (oldIds !== newIds) {
                    this.messages = newMessages;
                    this.renderMessages();

                    // Track last message ID for updates
                    if (this.messages.length > 0) {
                        this.lastMessageId = Math.max(...this.messages.map(m => m.id));
                    }
                }
            }
        } catch (error) {
            console.error('[STAFF CHAT] Error loading messages:', error);
        }
    },

    /**
     * Render messages in the chat
     */
    renderMessages() {
        const container = document.getElementById('staffChatMessages');

        if (!this.messages || this.messages.length === 0) {
            container.innerHTML = `
                <div class="staff-chat-empty">
                    <i class="fas fa-comment-dots"></i>
                    <p>Aucun message pour le moment</p>
                    <span>Soyez le premier a ecrire !</span>
                </div>
            `;
            return;
        }

        let html = '';
        let lastDate = null;

        this.messages.forEach(msg => {
            // Date separator
            const msgDate = new Date(msg.created_at).toLocaleDateString('fr-FR');
            if (msgDate !== lastDate) {
                html += this.renderDateSeparator(msgDate);
                lastDate = msgDate;
            }

            html += this.renderMessage(msg);
        });

        container.innerHTML = html;

        // Scroll to bottom
        container.scrollTop = container.scrollHeight;

        // Attach delete event listeners
        this.attachDeleteListeners();
    },

    /**
     * Render a single message
     */
    renderMessage(msg) {
        const isOwn = this.currentUser && msg.staff_identifier === this.currentUser.identifier;
        const time = new Date(msg.created_at).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });

        // Can delete: own message OR admin/owner
        const canDelete = isOwn || this.isAdmin;

        return `
            <div class="staff-chat-message ${isOwn ? 'own' : 'other'}" data-id="${msg.id}">
                <div class="staff-chat-message-header">
                    <span class="staff-chat-message-name">${this.escapeHtml(msg.staff_name)}</span>
                    <span class="staff-chat-message-group ${msg.staff_group}">${msg.staff_group}</span>
                </div>
                <div class="staff-chat-message-bubble">
                    ${this.escapeHtml(msg.message)}
                    ${canDelete ? `
                        <button class="staff-chat-message-delete" data-id="${msg.id}" title="Supprimer">
                            <i class="fas fa-times"></i>
                        </button>
                    ` : ''}
                </div>
                <div class="staff-chat-message-time">${time}</div>
            </div>
        `;
    },

    /**
     * Render date separator
     */
    renderDateSeparator(date) {
        const today = new Date().toLocaleDateString('fr-FR');
        const yesterday = new Date(Date.now() - 86400000).toLocaleDateString('fr-FR');

        let label = date;
        if (date === today) label = "Aujourd'hui";
        else if (date === yesterday) label = 'Hier';

        return `
            <div class="staff-chat-date-separator">
                <span>${label}</span>
            </div>
        `;
    },

    /**
     * Attach delete button listeners
     */
    attachDeleteListeners() {
        document.querySelectorAll('.staff-chat-message-delete').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                const messageId = parseInt(btn.dataset.id);
                this.deleteMessage(messageId);
            });
        });
    },

    /**
     * Send a new message
     */
    async sendMessage() {
        const input = document.getElementById('staffChatInput');
        const message = input.value.trim();

        if (!message) return;

        // Disable send button temporarily
        const sendBtn = document.getElementById('staffChatSend');
        sendBtn.disabled = true;

        try {
            const response = await API.sendStaffChatMessage(message);

            if (response && response.success) {
                input.value = '';
                // Reload messages to get the new one
                await this.loadMessages();
            } else {
                Notifications.error('Erreur', response?.error || 'Impossible d\'envoyer le message');
            }
        } catch (error) {
            console.error('[STAFF CHAT] Error sending message:', error);
            Notifications.error('Erreur', 'Impossible d\'envoyer le message');
        } finally {
            sendBtn.disabled = false;
            input.focus();
        }
    },

    /**
     * Delete a message
     */
    async deleteMessage(messageId) {
        try {
            const response = await API.deleteStaffChatMessage(messageId);

            if (response && response.success) {
                // Remove from local array
                this.messages = this.messages.filter(m => m.id !== messageId);
                this.renderMessages();
                Notifications.success('Succes', 'Message supprime');
            } else {
                Notifications.error('Erreur', response?.error || 'Impossible de supprimer le message');
            }
        } catch (error) {
            console.error('[STAFF CHAT] Error deleting message:', error);
        }
    },

    /**
     * Confirm and clear all messages (admin only)
     */
    async confirmClearAll() {
        if (!this.isAdmin) return;

        const confirmed = await Modal.confirm({
            title: 'Supprimer tous les messages',
            message: 'Voulez-vous vraiment supprimer TOUS les messages du chat staff ? Cette action est irreversible.',
            confirmText: 'Supprimer tout',
            cancelText: 'Annuler',
            danger: true
        });

        if (confirmed) {
            this.clearAllMessages();
        }
    },

    /**
     * Clear all messages
     */
    async clearAllMessages() {
        try {
            const response = await API.clearStaffChat();

            if (response && response.success) {
                this.messages = [];
                this.renderMessages();
                Notifications.success('Succes', 'Tous les messages ont ete supprimes');
            } else {
                Notifications.error('Erreur', response?.error || 'Impossible de supprimer les messages');
            }
        } catch (error) {
            console.error('[STAFF CHAT] Error clearing messages:', error);
        }
    },

    /**
     * Start auto-refresh interval
     */
    startAutoRefresh() {
        // Refresh every 5 seconds
        this.refreshInterval = setInterval(() => {
            // Only refresh if dashboard is visible
            const dashboardView = document.getElementById('view-dashboard');
            if (dashboardView && dashboardView.classList.contains('active')) {
                this.loadMessages();
            }
        }, 5000);
    },

    /**
     * Stop auto-refresh
     */
    stopAutoRefresh() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
            this.refreshInterval = null;
        }
    },

    /**
     * Escape HTML to prevent XSS
     */
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
};

// Export
window.StaffChatModule = StaffChatModule;
