/**
 * Events Module - Panel Admin Fight League
 * Gestion des annonces d'événements GDT/CVC
 */

const EventsModule = {
    /**
     * Initialiser le module
     */
    init() {
        this.bindEvents();
        this.updatePreview();
    },

    /**
     * Lier les événements
     */
    bindEvents() {
        // Type d'événement change
        const eventType = document.getElementById('eventType');
        if (eventType) {
            eventType.addEventListener('change', () => this.updatePreview());
        }

        // Horaire change
        const eventTime = document.getElementById('eventTime');
        if (eventTime) {
            eventTime.addEventListener('input', () => this.updatePreview());
        }

        // Message change
        const eventMessage = document.getElementById('eventMessage');
        if (eventMessage) {
            eventMessage.addEventListener('input', () => this.updatePreview());
        }

        // Réactions minimum change
        const eventMinReactions = document.getElementById('eventMinReactions');
        if (eventMinReactions) {
            eventMinReactions.addEventListener('input', () => this.updatePreview());
        }

        // Bouton envoyer
        const sendBtn = document.getElementById('sendEventAnnounce');
        if (sendBtn) {
            sendBtn.addEventListener('click', () => this.sendAnnouncement());
        }
    },

    /**
     * Mettre à jour l'aperçu Discord
     */
    updatePreview() {
        const type = document.getElementById('eventType')?.value || 'gdt';
        const time = document.getElementById('eventTime')?.value || '';
        const message = document.getElementById('eventMessage')?.value || 'Votre message apparaîtra ici...';
        const minReactions = document.getElementById('eventMinReactions')?.value || 20;

        const previewEmbed = document.getElementById('eventPreviewEmbed');
        if (!previewEmbed) return;

        // Mettre à jour la barre de couleur
        const embedBar = previewEmbed.querySelector('.embed-bar');
        if (embedBar) {
            embedBar.className = 'embed-bar ' + type;
        }

        // Mettre à jour le titre
        const embedTitle = previewEmbed.querySelector('.embed-title');
        if (embedTitle) {
            const icon = type === 'gdt' ? '🎮' : '⚔️';
            const title = type === 'gdt' ? 'ANNONCE GDT' : 'ANNONCE CVC';
            embedTitle.textContent = `${icon} ${title}${time ? ' - ' + time : ''}`;
        }

        // Mettre à jour l'horaire
        const embedTime = previewEmbed.querySelector('.embed-time');
        if (embedTime) {
            embedTime.innerHTML = time ? `<strong>📅 Horaire:</strong> ${Helpers.escapeHtml(time)}<br><br>` : '';
        }

        // Mettre à jour le message
        const embedMessage = previewEmbed.querySelector('.embed-message');
        if (embedMessage) {
            embedMessage.textContent = message || 'Votre message apparaîtra ici...';
        }

        // Mettre à jour les réactions
        const embedReactions = previewEmbed.querySelector('.embed-reactions');
        if (embedReactions) {
            embedReactions.textContent = minReactions;
        }
    },

    /**
     * Envoyer l'annonce
     */
    async sendAnnouncement() {
        const type = document.getElementById('eventType')?.value;
        const time = document.getElementById('eventTime')?.value?.trim();
        const message = document.getElementById('eventMessage')?.value?.trim();
        const minReactions = parseInt(document.getElementById('eventMinReactions')?.value) || 20;
        const sendDiscord = document.getElementById('eventSendDiscord')?.checked;
        const sendIngame = document.getElementById('eventSendIngame')?.checked;

        // Validation
        if (!message) {
            Notifications.error('Erreur', 'Veuillez entrer un message pour l\'annonce');
            return;
        }

        if (!sendDiscord && !sendIngame) {
            Notifications.error('Erreur', 'Veuillez sélectionner au moins un canal d\'envoi');
            return;
        }

        // Confirmation
        const typeLabel = type === 'gdt' ? 'GDT' : 'CVC';
        const confirmed = await this.confirmSend(typeLabel, time, sendDiscord, sendIngame);
        if (!confirmed) return;

        // Envoyer au serveur
        const data = {
            eventType: type,
            time: time,
            message: message,
            minReactions: minReactions,
            sendDiscord: sendDiscord,
            sendIngame: sendIngame
        };

        try {
            const result = await API.sendEventAnnouncement(data);

            if (result.success) {
                Notifications.success('Succès', `Annonce ${typeLabel} envoyée avec succès!`);

                // Réinitialiser le formulaire
                document.getElementById('eventMessage').value = '';
                document.getElementById('eventTime').value = '';
                this.updatePreview();
            } else {
                const errorMessages = {
                    'WEBHOOK_NOT_CONFIGURED': 'Le webhook Discord n\'est pas configuré',
                    'NO_PERMISSION': 'Vous n\'avez pas la permission d\'envoyer des annonces'
                };
                Notifications.error('Erreur', errorMessages[result.error] || 'Erreur lors de l\'envoi');
            }
        } catch (error) {
            console.error('Erreur envoi annonce:', error);
            Notifications.error('Erreur', 'Erreur de communication avec le serveur');
        }
    },

    /**
     * Confirmation avant envoi
     */
    confirmSend(type, time, discord, ingame) {
        return new Promise((resolve) => {
            let channels = [];
            if (discord) channels.push('Discord');
            if (ingame) channels.push('En jeu');

            const body = `
                <div class="confirm-content">
                    <p>Vous allez envoyer une annonce <strong>${type}</strong>${time ? ' à <strong>' + time + '</strong>' : ''}.</p>
                    <p>Canaux: <strong>${channels.join(' + ')}</strong></p>
                    <p class="text-warning"><i class="fas fa-exclamation-triangle"></i> Cette action est irréversible.</p>
                </div>
            `;

            Modal.open({
                title: 'Confirmer l\'envoi',
                body: body,
                footer: [
                    { text: 'Annuler', class: 'btn-secondary', onClick: () => { Modal.close(); resolve(false); } },
                    { text: 'Envoyer', class: 'btn-primary', onClick: () => { Modal.close(); resolve(true); } }
                ]
            });
        });
    }
};

// Export
window.EventsModule = EventsModule;
