/**
 * Announcement Banner Module - Panel Admin Fight League
 * Gestion de la banniere d'annonce visuelle
 */

const AnnouncementBanner = {
    // Configuration
    config: {
        duration: 5000,           // Duree d'affichage par defaut (5 secondes)
        soundEnabled: true,       // Son active par defaut
        soundVolume: 0.5,         // Volume du son (0 a 1)
        backgroundImage: 'img/standard.png'  // Image de fond par defaut
    },

    // Etat
    isShowing: false,
    hideTimeout: null,
    queue: [],

    /**
     * Initialiser le module
     */
    init() {
        // Precharger le son
        const sound = document.getElementById('announcementSound');
        if (sound) {
            sound.volume = this.config.soundVolume;
        }

        // Appliquer l'image de fond par defaut sur le header
        if (this.config.backgroundImage) {
            const headerElement = document.querySelector('.announcement-banner-header');
            if (headerElement) {
                headerElement.style.backgroundImage = `url('${this.config.backgroundImage}')`;
            }
        }
    },

    /**
     * Configurer l'image de fond
     * @param {string} imageUrl - URL de l'image de fond
     */
    setBackgroundImage(imageUrl) {
        this.config.backgroundImage = imageUrl;
        const headerElement = document.querySelector('.announcement-banner-header');
        if (headerElement && imageUrl) {
            headerElement.style.backgroundImage = `url('${imageUrl}')`;
        }
    },

    /**
     * Afficher une annonce
     * @param {Object} data - Donnees de l'annonce
     * @param {string} data.message - Message de l'annonce
     * @param {string} data.title - Titre de l'annonce (optionnel)
     * @param {string} data.priority - Priorite (normal, high, urgent)
     * @param {number} data.duration - Duree d'affichage en ms (optionnel)
     * @param {string} data.backgroundImage - Image de fond (optionnel)
     */
    show(data) {
        // Si une annonce est deja affichee, mettre en file d'attente
        if (this.isShowing) {
            this.queue.push(data);
            return;
        }

        this.isShowing = true;

        const banner = document.getElementById('announcementBanner');
        const messageEl = document.getElementById('announcementBannerMessage');
        const progressEl = document.getElementById('announcementBannerProgress');
        const headerEl = banner.querySelector('.announcement-banner-header');
        const titleEl = banner.querySelector('.announcement-banner-title');

        // Definir le message
        messageEl.textContent = data.message || 'Annonce du serveur';

        // Definir le titre si fourni
        if (titleEl) {
            titleEl.textContent = data.title || 'ANNONCE';
        }

        // Appliquer l'image de fond sur le header
        if (data.backgroundImage || this.config.backgroundImage) {
            headerEl.style.backgroundImage = `url('${data.backgroundImage || this.config.backgroundImage}')`;
        }

        // Supprimer les classes de priorite existantes
        banner.classList.remove('priority-normal', 'priority-high', 'priority-urgent');

        // Ajouter la classe de priorite
        const priority = data.priority || 'normal';
        if (priority !== 'normal') {
            banner.classList.add(`priority-${priority}`);
        }

        // Calculer la duree
        const duration = data.duration || this.getDurationByPriority(priority);

        // Configurer l'animation de la barre de progression
        progressEl.style.animation = 'none';
        progressEl.offsetHeight; // Force reflow
        progressEl.style.animation = `announceProgress ${duration}ms linear forwards`;

        // Supprimer les classes d'animation existantes
        banner.classList.remove('show', 'hide');

        // Afficher avec animation
        requestAnimationFrame(() => {
            banner.classList.add('show');
        });

        // Jouer le son
        this.playSound();

        // Programmer la disparition
        if (this.hideTimeout) {
            clearTimeout(this.hideTimeout);
        }

        this.hideTimeout = setTimeout(() => {
            this.hide();
        }, duration);
    },

    /**
     * Cacher la banniere
     */
    hide() {
        const banner = document.getElementById('announcementBanner');

        banner.classList.remove('show');
        banner.classList.add('hide');

        // Attendre la fin de l'animation puis reset
        setTimeout(() => {
            banner.classList.remove('hide');
            this.isShowing = false;

            // Verifier s'il y a des annonces en attente
            if (this.queue.length > 0) {
                const nextAnnounce = this.queue.shift();
                setTimeout(() => this.show(nextAnnounce), 300);
            }
        }, 500);
    },

    /**
     * Obtenir la duree selon la priorite
     * @param {string} priority - Priorite de l'annonce
     * @returns {number} Duree en ms
     */
    getDurationByPriority(priority) {
        const durations = {
            low: 4000,
            normal: 5000,
            high: 7000,
            urgent: 10000
        };
        return durations[priority] || durations.normal;
    },

    /**
     * Jouer le son d'annonce
     */
    playSound() {
        if (!this.config.soundEnabled) return;

        const sound = document.getElementById('announcementSound');
        if (sound) {
            sound.currentTime = 0;
            sound.volume = this.config.soundVolume;
            sound.play().catch(() => {
                // Ignorer les erreurs de lecture audio (politique autoplay)
            });
        }
    },

    /**
     * Activer/desactiver le son
     * @param {boolean} enabled
     */
    setSoundEnabled(enabled) {
        this.config.soundEnabled = enabled;
    },

    /**
     * Definir le volume du son
     * @param {number} volume - Volume de 0 a 1
     */
    setSoundVolume(volume) {
        this.config.soundVolume = Math.max(0, Math.min(1, volume));
        const sound = document.getElementById('announcementSound');
        if (sound) {
            sound.volume = this.config.soundVolume;
        }
    }
};

// Export global
window.AnnouncementBanner = AnnouncementBanner;

// Initialiser au chargement
document.addEventListener('DOMContentLoaded', () => {
    AnnouncementBanner.init();
});
