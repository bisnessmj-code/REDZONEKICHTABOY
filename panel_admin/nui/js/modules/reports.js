/**
 * Reports Module - Panel Admin Fight League
 * Gestion des tickets de support
 */

const ReportsModule = {
    reports: [],
    currentFilter: 'pending',
    refreshInterval: null,

    /**
     * Initialiser le module
     */
    init() {
        // Filtre de statut
        const statusFilter = document.getElementById('reportStatusFilter');
        if (statusFilter) {
            statusFilter.addEventListener('change', (e) => {
                this.currentFilter = e.target.value;
                this.renderFiltered();
            });
        }

        // Bouton refresh
        const refreshBtn = document.getElementById('refreshReports');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', () => {
                this.load();
            });
        }

        // Bouton supprimer tout (admin/owner seulement)
        const deleteAllBtn = document.getElementById('deleteAllReports');
        if (deleteAllBtn) {
            deleteAllBtn.addEventListener('click', () => {
                this.confirmDeleteAll();
            });
        }

        // Auto-refresh toutes les 30 secondes
        this.startAutoRefresh();
    },

    /**
     * Mettre a jour les permissions du bouton supprimer tout
     */
    updateDeleteAllPermission() {
        const deleteAllBtn = document.getElementById('deleteAllReports');
        if (deleteAllBtn) {
            if (App.hasPermission('reportDelete')) {
                deleteAllBtn.style.display = '';
            } else {
                deleteAllBtn.style.display = 'none';
            }
        }
    },

    /**
     * Demarrer l'auto-refresh
     */
    startAutoRefresh() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
        }
        this.refreshInterval = setInterval(() => {
            if (document.getElementById('view-reports').classList.contains('active')) {
                this.load(true); // silent refresh
            }
        }, 30000);
    },

    /**
     * Charger les reports
     */
    async load(silent = false) {
        // Mettre a jour les permissions du bouton supprimer tout
        this.updateDeleteAllPermission();

        const result = await API.getReports();

        if (result.success) {
            this.reports = result.reports || [];
            this.updateStats();
            this.renderFiltered();
        } else if (!silent) {
            this.renderError(result.error);
        }
    },

    /**
     * Mettre a jour les stats
     */
    updateStats() {
        const pending = this.reports.filter(r => r.status === 'pending').length;
        const inProgress = this.reports.filter(r => r.status === 'in_progress').length;
        const resolvedToday = this.reports.filter(r => {
            if (r.status !== 'resolved') return false;
            const resolved = new Date(r.resolved_at);
            const today = new Date();
            return resolved.toDateString() === today.toDateString();
        }).length;

        const pendingEl = document.getElementById('reportsPending');
        const inProgressEl = document.getElementById('reportsInProgress');
        const resolvedEl = document.getElementById('reportsResolved');

        if (pendingEl) pendingEl.textContent = pending;
        if (inProgressEl) inProgressEl.textContent = inProgress;
        if (resolvedEl) resolvedEl.textContent = resolvedToday;

        // Mettre a jour le badge dans la sidebar
        this.updateBadge(pending);
    },

    /**
     * Mettre a jour le badge de la sidebar
     */
    updateBadge(count) {
        const badge = document.getElementById('reportsBadge');
        if (!badge) return;

        if (count > 0) {
            badge.textContent = count > 99 ? '99+' : count;
            badge.classList.remove('hidden');
        } else {
            badge.classList.add('hidden');
        }
    },

    /**
     * Filtrer et rendre
     */
    renderFiltered() {
        let filtered = this.reports;

        if (this.currentFilter) {
            filtered = this.reports.filter(r => r.status === this.currentFilter);
        }

        // Trier par date (plus recent en premier)
        filtered.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

        this.render(filtered);
    },

    /**
     * Rendre la liste des reports
     */
    render(reports) {
        const container = document.getElementById('reportsList');
        if (!container) return;

        if (reports.length === 0) {
            container.innerHTML = `
                <div class="reports-empty">
                    <i class="fas fa-inbox"></i>
                    <p>Aucun ticket ${this.getStatusLabel(this.currentFilter)}</p>
                </div>
            `;
            return;
        }

        container.innerHTML = reports.map(report => this.renderReportCard(report)).join('');
    },

    /**
     * Rendre une carte de report
     */
    renderReportCard(report) {
        const statusClass = this.getStatusClass(report.status);
        const statusLabel = this.getStatusLabel(report.status);
        const timeAgo = this.getTimeAgo(report.created_at);
        const isOnline = report.is_online;

        return `
            <div class="report-card ${statusClass}" data-report-id="${report.id}">
                <div class="report-header">
                    <div class="report-player">
                        <span class="report-player-id">ID: ${report.player_id}</span>
                        <span class="report-player-name">${Helpers.escapeHtml(report.player_name)}</span>
                        ${isOnline ? '<span class="online-badge"><i class="fas fa-circle"></i> En ligne</span>' : '<span class="offline-badge"><i class="fas fa-circle"></i> Hors ligne</span>'}
                    </div>
                    <div class="report-meta">
                        <span class="report-time"><i class="fas fa-clock"></i> ${timeAgo}</span>
                        <span class="report-status badge badge-${statusClass}">${statusLabel}</span>
                    </div>
                </div>
                <div class="report-body">
                    <p class="report-message">${Helpers.escapeHtml(report.message)}</p>
                </div>
                ${report.claimed_by_name ? `
                    <div class="report-claimed">
                        <i class="fas fa-user-check"></i>
                        Pris en charge par <strong>${Helpers.escapeHtml(report.claimed_by_name)}</strong>
                    </div>
                ` : ''}
                ${report.response ? `
                    <div class="report-response">
                        <i class="fas fa-reply"></i>
                        <span>${Helpers.escapeHtml(report.response)}</span>
                    </div>
                ` : ''}
                <div class="report-actions">
                    ${this.renderActions(report)}
                </div>
            </div>
        `;
    },

    /**
     * Rendre les actions selon le statut
     */
    renderActions(report) {
        const actions = [];

        if (report.status === 'pending') {
            actions.push(`
                <button class="btn btn-sm btn-primary" onclick="ReportsModule.claim(${report.id})">
                    <i class="fas fa-hand-paper"></i> Prendre en charge
                </button>
            `);
        }

        if (report.status === 'in_progress') {
            actions.push(`
                <button class="btn btn-sm btn-success" onclick="ReportsModule.showResponseModal(${report.id})">
                    <i class="fas fa-reply"></i> Repondre
                </button>
            `);
            actions.push(`
                <button class="btn btn-sm btn-secondary" onclick="ReportsModule.resolve(${report.id})">
                    <i class="fas fa-check"></i> Resolu
                </button>
            `);
        }

        // Actions disponibles si le joueur est en ligne
        if (report.is_online) {
            actions.push(`
                <button class="btn btn-sm btn-info" onclick="ReportsModule.teleportTo(${report.player_id})" title="Se teleporter vers le joueur">
                    <i class="fas fa-map-marker-alt"></i> TP
                </button>
            `);
            actions.push(`
                <button class="btn btn-sm btn-warning" onclick="ReportsModule.bringPlayer(${report.player_id})" title="Amener le joueur a vous">
                    <i class="fas fa-user-plus"></i> Bring
                </button>
            `);
            actions.push(`
                <button class="btn btn-sm btn-purple" onclick="ReportsModule.spectatePlayer(${report.player_id})" title="Observer le joueur">
                    <i class="fas fa-eye"></i> Spec
                </button>
            `);
            actions.push(`
                <button class="btn btn-sm btn-cyan" onclick="ReportsModule.returnPlayer(${report.player_id})" title="Renvoyer le joueur a sa position">
                    <i class="fas fa-undo"></i> Return
                </button>
            `);
        }

        // Bouton supprimer uniquement pour admin/owner
        if (App.hasPermission('reportDelete')) {
            actions.push(`
                <button class="btn btn-sm btn-danger" onclick="ReportsModule.deleteReport(${report.id})">
                    <i class="fas fa-trash"></i>
                </button>
            `);
        }

        return actions.join('');
    },

    /**
     * Prendre en charge un report
     */
    async claim(reportId) {
        const result = await API.reportAction('claim', reportId);

        if (result.success) {
            Notifications.success('Report pris en charge', 'Vous avez pris en charge ce ticket');

            // Changer le filtre vers "En cours" pour garder la main sur le ticket
            this.currentFilter = 'in_progress';
            const statusFilter = document.getElementById('reportStatusFilter');
            if (statusFilter) {
                statusFilter.value = 'in_progress';
            }

            this.load();
        } else {
            Notifications.error('Erreur', result.error || 'Impossible de prendre en charge ce ticket');
        }
    },

    /**
     * Afficher le modal de reponse
     */
    showResponseModal(reportId) {
        const modalBody = `
            <div class="form-group">
                <label><i class="fas fa-comment"></i> Message pour le joueur</label>
                <textarea id="reportResponseText" rows="4" placeholder="Votre message sera envoye au joueur en notification..."></textarea>
                <small style="color: var(--text-muted); margin-top: 5px; display: block;">
                    <i class="fas fa-info-circle"></i> Le joueur recevra ce message en haut de son ecran
                </small>
            </div>
            <div class="form-group">
                <label class="checkbox-label">
                    <input type="checkbox" id="reportCloseAfterResponse">
                    <span>Fermer le ticket apres envoi</span>
                </label>
            </div>
        `;

        const modalFooter = `
            <button class="btn btn-secondary" onclick="Modal.close()">Annuler</button>
            <button class="btn btn-primary" onclick="ReportsModule.sendResponse(${reportId})">
                <i class="fas fa-paper-plane"></i> Envoyer le message
            </button>
        `;

        Modal.open({
            title: 'Envoyer un message au joueur',
            body: modalBody,
            footer: modalFooter
        });
    },

    /**
     * Envoyer une reponse
     */
    async sendResponse(reportId) {
        const responseText = document.getElementById('reportResponseText').value.trim();
        const closeAfter = document.getElementById('reportCloseAfterResponse').checked;

        if (!responseText) {
            Notifications.error('Erreur', 'Veuillez entrer une reponse');
            return;
        }

        const result = await API.reportAction('respond', reportId, {
            response: responseText,
            closeAfter: closeAfter
        });

        if (result.success) {
            Modal.close();
            Notifications.success('Reponse envoyee', 'Le joueur a ete notifie');
            this.load();
        } else {
            Notifications.error('Erreur', result.error || 'Impossible d\'envoyer la reponse');
        }
    },

    /**
     * Marquer comme resolu
     */
    async resolve(reportId) {
        const result = await API.reportAction('resolve', reportId);

        if (result.success) {
            Notifications.success('Ticket resolu', 'Le ticket a ete marque comme resolu');
            this.load();
        } else {
            Notifications.error('Erreur', result.error || 'Impossible de resoudre ce ticket');
        }
    },

    /**
     * Supprimer un report
     */
    async deleteReport(reportId) {
        const confirmed = await Modal.confirm({
            title: 'Supprimer le ticket',
            message: 'Voulez-vous vraiment supprimer ce ticket ?',
            confirmText: 'Supprimer',
            cancelText: 'Annuler',
            danger: true
        });

        if (!confirmed) return;

        const result = await API.reportAction('delete', reportId);

        if (result.success) {
            Notifications.success('Ticket supprime', 'Le ticket a ete supprime');
            this.load();
        } else {
            Notifications.error('Erreur', result.error || 'Impossible de supprimer ce ticket');
        }
    },

    /**
     * Confirmer la suppression de tous les tickets
     */
    async confirmDeleteAll() {
        const ticketCount = this.reports.length;

        if (ticketCount === 0) {
            Notifications.warning('Aucun ticket', 'Il n\'y a aucun ticket a supprimer');
            return;
        }

        const confirmed = await Modal.confirm({
            title: 'Supprimer TOUS les tickets',
            message: `Voulez-vous vraiment supprimer les ${ticketCount} tickets ? Cette action est irreversible !`,
            confirmText: 'Tout supprimer',
            cancelText: 'Annuler',
            danger: true
        });

        if (!confirmed) return;

        this.deleteAllReports();
    },

    /**
     * Supprimer tous les reports
     */
    async deleteAllReports() {
        const result = await API.reportAction('deleteAll', null);

        if (result.success) {
            Notifications.success('Tickets supprimes', `${result.count || 'Tous les'} tickets ont ete supprimes`);
            this.load();
        } else {
            Notifications.error('Erreur', result.error || 'Impossible de supprimer les tickets');
        }
    },

    /**
     * Teleporter vers le joueur
     */
    async teleportTo(playerId) {
        const result = await API.teleportAction('goto', playerId);

        if (result.success) {
            Notifications.success('Teleportation', 'Vous avez ete teleporte vers le joueur');
        } else {
            Notifications.error('Erreur', result.error || 'Impossible de se teleporter');
        }
    },

    /**
     * Amener le joueur (Bring)
     */
    async bringPlayer(playerId) {
        const result = await API.teleportAction('bring', playerId);

        if (result.success) {
            Notifications.success('Bring', 'Le joueur a ete amene a votre position');
        } else {
            Notifications.error('Erreur', result.error || 'Impossible d\'amener le joueur');
        }
    },

    /**
     * Spectate le joueur
     */
    async spectatePlayer(playerId) {
        const result = await API.spectate(playerId);

        if (result.success) {
            Notifications.success('Spectate', 'Vous observez maintenant le joueur');
        } else {
            Notifications.error('Erreur', result.error || 'Impossible d\'observer le joueur');
        }
    },

    /**
     * Return le joueur a sa position d'origine
     */
    async returnPlayer(playerId) {
        const result = await API.teleportAction('returnPlayer', playerId);

        if (result.success) {
            Notifications.success('Return', 'Le joueur a ete renvoye a sa position d\'origine');
        } else {
            Notifications.error('Erreur', result.error || 'Impossible de renvoyer le joueur (pas de position sauvegardee?)');
        }
    },

    /**
     * Afficher une erreur
     */
    renderError(error) {
        const container = document.getElementById('reportsList');
        if (!container) return;

        container.innerHTML = `
            <div class="reports-empty error">
                <i class="fas fa-exclamation-triangle"></i>
                <p>Erreur: ${error || 'Impossible de charger les tickets'}</p>
            </div>
        `;
    },

    /**
     * Obtenir la classe CSS du statut
     */
    getStatusClass(status) {
        switch (status) {
            case 'pending': return 'warning';
            case 'in_progress': return 'info';
            case 'resolved': return 'success';
            default: return 'secondary';
        }
    },

    /**
     * Obtenir le label du statut
     */
    getStatusLabel(status) {
        switch (status) {
            case 'pending': return 'En attente';
            case 'in_progress': return 'En cours';
            case 'resolved': return 'Resolu';
            case '': return '';
            default: return status;
        }
    },

    /**
     * Calculer le temps ecoule
     */
    getTimeAgo(dateStr) {
        const date = new Date(dateStr);
        const now = new Date();
        const diff = Math.floor((now - date) / 1000);

        if (diff < 60) return 'A l\'instant';
        if (diff < 3600) return `Il y a ${Math.floor(diff / 60)} min`;
        if (diff < 86400) return `Il y a ${Math.floor(diff / 3600)}h`;
        return `Il y a ${Math.floor(diff / 86400)}j`;
    },

    /**
     * Recevoir une nouvelle notification de report
     */
    onNewReport(report) {
        // Ajouter a la liste
        this.reports.unshift(report);
        this.updateStats();
        this.renderFiltered();

        // Jouer un son
        this.playNotificationSound();

        // Afficher notification
        Notifications.info('Nouveau report', `${report.player_name} (ID: ${report.player_id}): ${report.message.substring(0, 50)}...`);
    },

    /**
     * Jouer le son de notification
     */
    playNotificationSound() {
        const audio = document.getElementById('reportSound');
        if (audio) {
            audio.currentTime = 0;
            audio.play().catch(() => {});
        }
    }
};

// Export
window.ReportsModule = ReportsModule;
