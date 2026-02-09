/**
 * Notifications Module - Panel Admin Fight League
 */

const Notifications = {
    container: null,
    defaultDuration: 5000,

    /**
     * Initialiser le module
     */
    init() {
        this.container = document.getElementById('notifications');
    },

    /**
     * Afficher une notification
     */
    show(type, title, message, duration = this.defaultDuration) {
        const notification = document.createElement('div');
        notification.className = `notification ${type}`;

        const iconMap = {
            success: 'fa-check',
            error: 'fa-times',
            warning: 'fa-exclamation-triangle',
            info: 'fa-info'
        };

        notification.innerHTML = `
            <div class="notification-icon">
                <i class="fas ${iconMap[type] || 'fa-bell'}"></i>
            </div>
            <div class="notification-content">
                <div class="notification-title">${Helpers.escapeHtml(title)}</div>
                <div class="notification-message">${Helpers.escapeHtml(message)}</div>
            </div>
            <button class="notification-close">
                <i class="fas fa-times"></i>
            </button>
        `;

        // Close button
        const closeBtn = notification.querySelector('.notification-close');
        closeBtn.addEventListener('click', () => this.hide(notification));

        // Add to container
        this.container.appendChild(notification);

        // Auto hide
        if (duration > 0) {
            setTimeout(() => this.hide(notification), duration);
        }

        return notification;
    },

    /**
     * Masquer une notification
     */
    hide(notification) {
        if (!notification || notification.classList.contains('hiding')) return;

        notification.classList.add('hiding');
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 300);
    },

    /**
     * Raccourcis
     */
    success(title, message, duration) {
        return this.show('success', title, message, duration);
    },

    error(title, message, duration) {
        return this.show('error', title, message, duration);
    },

    warning(title, message, duration) {
        return this.show('warning', title, message, duration);
    },

    info(title, message, duration) {
        return this.show('info', title, message, duration);
    }
};

// Export
window.Notifications = Notifications;
