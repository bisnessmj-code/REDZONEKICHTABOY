/**
 * Helpers - Panel Admin Fight League
 * Fonctions utilitaires JavaScript
 */

const Helpers = {
    /**
     * Formater un nombre avec séparateurs
     */
    formatNumber(n) {
        return n.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
    },

    /**
     * Formater une durée en heures vers texte
     */
    formatDuration(hours) {
        if (!hours || hours < 0) return 'Permanent';

        if (hours < 1) {
            return Math.floor(hours * 60) + ' minutes';
        } else if (hours < 24) {
            return hours + ' heure' + (hours > 1 ? 's' : '');
        } else if (hours < 168) {
            const days = Math.floor(hours / 24);
            return days + ' jour' + (days > 1 ? 's' : '');
        } else {
            const weeks = Math.floor(hours / 168);
            return weeks + ' semaine' + (weeks > 1 ? 's' : '');
        }
    },

    /**
     * Formater une date relative
     */
    formatRelativeTime(dateStr) {
        const date = new Date(dateStr);
        const now = new Date();
        const diff = Math.floor((now - date) / 1000);

        if (diff < 60) {
            return 'Il y a quelques secondes';
        } else if (diff < 3600) {
            const minutes = Math.floor(diff / 60);
            return 'Il y a ' + minutes + ' minute' + (minutes > 1 ? 's' : '');
        } else if (diff < 86400) {
            const hours = Math.floor(diff / 3600);
            return 'Il y a ' + hours + ' heure' + (hours > 1 ? 's' : '');
        } else if (diff < 604800) {
            const days = Math.floor(diff / 86400);
            return 'Il y a ' + days + ' jour' + (days > 1 ? 's' : '');
        } else {
            return date.toLocaleDateString('fr-FR');
        }
    },

    /**
     * Formater une date complète
     */
    formatDate(dateStr) {
        if (!dateStr) return '-';
        const date = new Date(dateStr);
        return date.toLocaleDateString('fr-FR', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    },

    /**
     * Échapper le HTML
     */
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    },

    /**
     * Tronquer un texte
     */
    truncate(str, maxLen) {
        if (!str) return '';
        if (str.length <= maxLen) return str;
        return str.substring(0, maxLen - 3) + '...';
    },

    /**
     * Debounce une fonction
     */
    debounce(func, wait) {
        let timeout;
        return function(...args) {
            clearTimeout(timeout);
            timeout = setTimeout(() => func.apply(this, args), wait);
        };
    },

    /**
     * Obtenir la couleur du ping
     */
    getPingClass(ping) {
        if (ping < 50) return 'ping-good';
        if (ping < 100) return 'ping-medium';
        return 'ping-bad';
    },

    /**
     * Obtenir la classe du badge de grade
     */
    getGradeBadgeClass(grade) {
        const gradeClasses = {
            'owner': 'badge-owner',
            'admin': 'badge-admin',
            'responsable': 'badge-responsable',
            'organisateur': 'badge-organisateur',
            'staff': 'badge-staff'
        };
        return gradeClasses[grade] || 'badge-neutral';
    },

    /**
     * Obtenir l'icône selon le type de log
     */
    getLogIcon(category) {
        const icons = {
            'auth': 'fa-key',
            'player': 'fa-user',
            'sanction': 'fa-gavel',
            'economy': 'fa-dollar-sign',
            'teleport': 'fa-map-marker-alt',
            'vehicle': 'fa-car',
            'event': 'fa-trophy',
            'announce': 'fa-bullhorn',
            'config': 'fa-cog',
            'system': 'fa-server'
        };
        return icons[category] || 'fa-circle';
    },

    /**
     * Obtenir le label français d'un type de sanction
     */
    getSanctionLabel(type) {
        const labels = {
            'warn': 'Avertissement',
            'kick': 'Expulsion',
            'ban_temp': 'Ban temporaire',
            'ban_perm': 'Ban permanent'
        };
        return labels[type] || type;
    },

    /**
     * Obtenir la classe du badge de sanction
     */
    getSanctionBadgeClass(type) {
        const classes = {
            'warn': 'badge-warning',
            'kick': 'badge-info',
            'ban_temp': 'badge-danger',
            'ban_perm': 'badge-danger'
        };
        return classes[type] || 'badge-neutral';
    },

    /**
     * Obtenir la classe du badge de statut
     */
    getStatusBadgeClass(status) {
        const classes = {
            'active': 'badge-success',
            'expired': 'badge-neutral',
            'revoked': 'badge-warning'
        };
        return classes[status] || 'badge-neutral';
    }
};

// Export pour utilisation globale
window.Helpers = Helpers;
