/**
 * Announcements Module - Panel Admin Fight League
 */

const AnnouncementsModule = {
    /**
     * Initialiser le module
     */
    init() {
        // Send button
        document.getElementById('sendAnnounce').addEventListener('click', () => {
            this.sendAnnouncement();
        });
    },

    /**
     * Envoyer une annonce
     */
    async sendAnnouncement() {
        const message = document.getElementById('announceMessage').value.trim();
        const type = document.getElementById('announceType').value;
        const priority = document.getElementById('announcePriority').value;

        if (!message) {
            Notifications.error('Erreur', 'Entrez un message');
            return;
        }

        await API.announceAction({ message, type, priority });

        // Clear form
        document.getElementById('announceMessage').value = '';
        document.getElementById('announceType').value = 'chat';
        document.getElementById('announcePriority').value = 'normal';
    }
};

// Export
window.AnnouncementsModule = AnnouncementsModule;
