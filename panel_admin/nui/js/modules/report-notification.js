/**
 * Report Notification Module - Panel Admin Fight League
 * Affiche les notifications de nouveaux reports au-dessus de la minimap
 */

const ReportNotification = {
    notifications: [],
    maxNotifications: 3,
    autoHideDelay: 15000, // 15 secondes
    interactionMode: false,

    /**
     * Initialiser le module
     */
    init() {
        // Ecouter la touche Echap pour fermer le mode interaction
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && this.interactionMode) {
                this.disableInteraction();
            }
        });

        // Delegation d'evenements sur le container pour une meilleure fiabilite
        const container = document.getElementById('reportNotificationContainer');
        if (container) {
            // Handler pour traiter les clics sur les boutons
            const handleButtonAction = (e) => {
                const target = e.target.closest('button');
                if (!target) return;

                // Eviter le double traitement
                if (target.dataset.processing === 'true') return;

                e.preventDefault();
                e.stopPropagation();
                e.stopImmediatePropagation();

                const notification = target.closest('.report-notification');
                if (!notification) return;

                const reportId = parseInt(notification.dataset.reportId);

                if (target.classList.contains('btn-claim')) {
                    target.dataset.processing = 'true';
                    this.claim(reportId, target);
                } else if (target.classList.contains('btn-tp')) {
                    const playerId = parseInt(target.dataset.playerId);
                    target.dataset.processing = 'true';
                    this.teleportTo(playerId, target);
                } else if (target.classList.contains('btn-dismiss')) {
                    this.dismiss(reportId);
                }
            };

            // Utiliser mouseup pour une meilleure fiabilite dans NUI (evite les problemes de click)
            container.addEventListener('mouseup', handleButtonAction, true);
        }
    },

    /**
     * Activer le mode interaction (souris visible)
     */
    enableInteraction() {
        this.interactionMode = true;
        const container = document.getElementById('reportNotificationContainer');
        if (container) {
            container.classList.add('interaction-mode');
        }
    },

    /**
     * Desactiver le mode interaction
     */
    disableInteraction() {
        this.interactionMode = false;
        const container = document.getElementById('reportNotificationContainer');
        if (container) {
            container.classList.remove('interaction-mode');
        }
        // Informer le client Lua
        fetch('https://panel_admin/closeReportInteraction', {
            method: 'POST',
            body: JSON.stringify({})
        });
    },

    /**
     * Mettre a jour le statut des notifications vers le client Lua
     */
    updateNotificationStatus() {
        fetch('https://panel_admin/reportNotificationsStatus', {
            method: 'POST',
            body: JSON.stringify({
                hasNotifications: this.notifications.length > 0
            })
        });
    },

    /**
     * Afficher une nouvelle notification de report
     */
    show(report) {
        const container = document.getElementById('reportNotificationContainer');
        if (!container) return;

        // Creer l'element de notification
        const notification = document.createElement('div');
        notification.className = 'report-notification';
        notification.dataset.reportId = report.id;

        notification.innerHTML = `
            <div class="report-notification-header">
                <div class="report-logo">
                    <img src="img/logo.png" alt="Logo" />
                </div>
                <div class="report-player-info">
                    <span class="player-id">ID: ${report.player_id}</span>
                    <span class="player-name">${this.escapeHtml(report.player_name)}</span>
                </div>
                <div class="report-alt-hint">
                    <span class="alt-key">ALT</span>
                </div>
            </div>
            <div class="report-notification-body">
                <p class="report-notification-message">${this.escapeHtml(report.message)}</p>
            </div>
            <div class="report-notification-footer">
                <button class="btn-claim" type="button">
                    <i class="fas fa-hand-paper"></i> Prendre
                </button>
                <button class="btn-tp" type="button" data-player-id="${report.player_id}">
                    <i class="fas fa-map-marker-alt"></i> TP
                </button>
                <button class="btn-dismiss" type="button">
                    <i class="fas fa-times"></i>
                </button>
            </div>
        `;

        // Ajouter au conteneur (les events sont geres par delegation dans init())
        container.appendChild(notification);

        // Jouer un son
        this.playSound();

        // Ajouter a la liste
        this.notifications.push({
            id: report.id,
            element: notification,
            playerId: report.player_id
        });

        // Limiter le nombre de notifications
        while (this.notifications.length > this.maxNotifications) {
            const oldest = this.notifications.shift();
            this.removeElement(oldest.element);
        }

        // Informer le client Lua qu'il y a des notifications
        this.updateNotificationStatus();

        // Auto-hide apres un delai
        setTimeout(() => {
            this.dismiss(report.id);
        }, this.autoHideDelay);
    },

    /**
     * Prendre en charge le report
     */
    async claim(reportId, buttonEl) {
        try {
            if (buttonEl) {
                buttonEl.disabled = true;
                buttonEl.innerHTML = '<i class="fas fa-spinner fa-spin"></i>';
            }

            const result = await API.reportAction('claim', reportId);

            if (result.success) {
                // Remplacer les boutons par un message de succes
                const notification = this.notifications.find(n => n.id === reportId);
                if (notification && notification.element) {
                    const footer = notification.element.querySelector('.report-notification-footer');
                    if (footer) {
                        footer.innerHTML = '<span style="color: var(--success); text-align: center; width: 100%;"><i class="fas fa-check"></i> Pris en charge</span>';
                    }
                    // Fermer apres 2 secondes
                    setTimeout(() => {
                        this.dismiss(reportId);
                    }, 2000);
                }
            } else {
                if (buttonEl) {
                    buttonEl.disabled = false;
                    buttonEl.innerHTML = '<i class="fas fa-hand-paper"></i> Prendre';
                    buttonEl.dataset.processing = 'false';
                }
                // Utiliser Notifications seulement si disponible
                if (window.Notifications) {
                    Notifications.error('Erreur', result.error || 'Impossible de prendre en charge ce ticket');
                } else {
                    console.error('Report claim error:', result.error);
                }
            }
        } catch (error) {
            console.error('Report claim exception:', error);
            if (buttonEl) {
                buttonEl.disabled = false;
                buttonEl.innerHTML = '<i class="fas fa-hand-paper"></i> Prendre';
                buttonEl.dataset.processing = 'false';
            }
        }
    },

    /**
     * Se teleporter vers le joueur
     */
    async teleportTo(playerId, buttonEl) {
        try {
            if (buttonEl) {
                buttonEl.disabled = true;
                buttonEl.innerHTML = '<i class="fas fa-spinner fa-spin"></i>';
            }

            const result = await API.teleportAction('goto', playerId);

            if (result.success) {
                if (buttonEl) {
                    buttonEl.innerHTML = '<i class="fas fa-check"></i> OK';
                }
            } else {
                if (buttonEl) {
                    buttonEl.disabled = false;
                    buttonEl.innerHTML = '<i class="fas fa-map-marker-alt"></i> TP';
                    buttonEl.dataset.processing = 'false';
                }
                if (window.Notifications) {
                    Notifications.error('Erreur', result.error || 'Impossible de se teleporter');
                } else {
                    console.error('Teleport error:', result.error);
                }
            }
        } catch (error) {
            console.error('Teleport exception:', error);
            if (buttonEl) {
                buttonEl.disabled = false;
                buttonEl.innerHTML = '<i class="fas fa-map-marker-alt"></i> TP';
                buttonEl.dataset.processing = 'false';
            }
        }
    },

    /**
     * Fermer une notification
     */
    dismiss(reportId) {
        const index = this.notifications.findIndex(n => n.id === reportId);
        if (index === -1) return;

        const notification = this.notifications[index];
        this.removeElement(notification.element);
        this.notifications.splice(index, 1);

        // Informer le client Lua du nouveau statut
        this.updateNotificationStatus();

        // Si plus de notifications et en mode interaction, desactiver
        if (this.notifications.length === 0 && this.interactionMode) {
            this.disableInteraction();
        }
    },

    /**
     * Retirer un element avec animation
     */
    removeElement(element) {
        if (!element || !element.parentNode) return;

        element.classList.add('closing');
        setTimeout(() => {
            if (element.parentNode) {
                element.parentNode.removeChild(element);
            }
        }, 300);
    },

    /**
     * Jouer le son de notification
     */
    playSound() {
        const audio = document.getElementById('reportSound');
        if (audio) {
            audio.currentTime = 0;
            audio.play().catch(() => {});
        }
    },

    /**
     * Echapper le HTML
     */
    escapeHtml(text) {
        if (!text) return '';
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
};

// Export
window.ReportNotification = ReportNotification;
