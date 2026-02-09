/**
 * Bans Module - Panel Admin Fight League
 * Gestion des bannissements
 */

const BansModule = {
    bans: [],
    currentPage: 1,
    perPage: 20,
    searchQuery: '',

    /**
     * Initialiser le module
     */
    init() {
        const searchInput = document.getElementById('banSearchInput');
        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                this.searchQuery = e.target.value;
                this.currentPage = 1;
                this.renderFiltered();
            });
        }
    },

    /**
     * Charger les bans
     */
    async load() {
        const result = await API.getBans();

        if (result.success) {
            this.bans = result.bans || [];
            this.renderFiltered();
        } else {
            this.renderError(result.error);
        }
    },

    /**
     * Filtrer et rendre
     */
    renderFiltered() {
        let filtered = this.bans;

        if (this.searchQuery) {
            const query = this.searchQuery.toLowerCase();
            // Nettoyer le query pour la recherche Discord (enlever le préfixe discord: si présent)
            const discordQuery = query.replace('discord:', '');

            filtered = this.bans.filter(ban => {
                // Recherche par ID de deban (prioritaire)
                if (ban.unban_id && ban.unban_id.toLowerCase().includes(query)) return true;
                // Recherche dans le nom du joueur
                if (ban.player_name && ban.player_name.toLowerCase().includes(query)) return true;
                // Recherche dans l'identifier
                if (ban.identifier && ban.identifier.toLowerCase().includes(query)) return true;
                // Recherche dans la license
                if (ban.license && ban.license.toLowerCase().includes(query)) return true;
                // Recherche dans la raison
                if (ban.reason && ban.reason.toLowerCase().includes(query)) return true;
                // Recherche dans le nom du staff
                if (ban.banned_by_name && ban.banned_by_name.toLowerCase().includes(query)) return true;
                // Recherche dans le Discord ID
                if (ban.discord_id) {
                    const discordId = ban.discord_id.replace('discord:', '');
                    if (discordId.includes(discordQuery)) return true;
                }
                return false;
            });
        }

        this.render(filtered);
    },

    /**
     * Rendre la table des bans
     */
    render(bans) {
        const tbody = document.querySelector('#bansTable tbody');
        if (!tbody) return;

        if (bans.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="6">
                        <div class="table-empty">
                            <i class="fas fa-ban"></i>
                            <p>Aucun bannissement trouve</p>
                        </div>
                    </td>
                </tr>
            `;
            return;
        }

        tbody.innerHTML = bans.map(ban => {
            const isExpired = ban.expires_at && new Date(ban.expires_at) < new Date();
            const isPermanent = !ban.expires_at;
            const canUnban = ban.can_unban;
            const unbanId = ban.unban_id || 'N/A';

            return `
                <tr class="${isExpired ? 'ban-expired' : ''}">
                    <td>
                        <div class="ban-player-cell">
                            <div class="ban-player-name">${Helpers.escapeHtml(ban.player_name || 'Inconnu')}</div>
                            <div class="ban-player-identifier">${Helpers.escapeHtml(ban.license || ban.identifier || '')}</div>
                            ${ban.discord_id ? `<div class="ban-player-discord"><i class="fab fa-discord" style="color: #5865F2;"></i> ${Helpers.escapeHtml(ban.discord_id.replace('discord:', ''))}</div>` : ''}
                            <div class="ban-unban-id" style="margin-top: 4px;"><span class="badge badge-info" style="font-size: 11px;"><i class="fas fa-key"></i> ID: ${Helpers.escapeHtml(unbanId)}</span></div>
                        </div>
                    </td>
                    <td>${Helpers.escapeHtml(ban.reason || 'Non specifie')}</td>
                    <td>
                        <div class="player-info">
                            <span class="player-name">${Helpers.escapeHtml(ban.banned_by_name || 'Systeme')}</span>
                        </div>
                    </td>
                    <td>
                        <span class="text-muted">${this.formatDate(ban.created_at)}</span>
                    </td>
                    <td>
                        ${isPermanent
                            ? '<span class="badge badge-danger">Permanent</span>'
                            : isExpired
                                ? '<span class="badge badge-secondary">Expire</span>'
                                : `<span class="badge badge-warning">${this.formatDate(ban.expires_at)}</span>`
                        }
                    </td>
                    <td>
                        ${canUnban && !isExpired
                            ? `<button class="btn btn-sm btn-success" onclick="BansModule.unban('${Helpers.escapeHtml(ban.identifier)}', '${Helpers.escapeHtml(ban.player_name || 'Inconnu')}')">
                                <i class="fas fa-unlock"></i> Debannir
                               </button>`
                            : isExpired
                                ? '<span class="text-muted">Expire</span>'
                                : '<span class="text-muted">Non autorise</span>'
                        }
                    </td>
                </tr>
            `;
        }).join('');
    },

    /**
     * Afficher une erreur
     */
    renderError(error) {
        const tbody = document.querySelector('#bansTable tbody');
        if (!tbody) return;

        tbody.innerHTML = `
            <tr>
                <td colspan="6">
                    <div class="table-empty">
                        <i class="fas fa-exclamation-triangle"></i>
                        <p>Erreur: ${error || 'Impossible de charger les bans'}</p>
                    </div>
                </td>
            </tr>
        `;
    },

    /**
     * Debannir un joueur
     */
    async unban(identifier, playerName) {
        const confirmed = await Modal.confirm({
            title: 'Debannissement',
            message: `Voulez-vous vraiment debannir ${playerName} ?`,
            confirmText: 'Debannir',
            cancelText: 'Annuler',
            danger: false
        });

        if (!confirmed) {
            return;
        }

        const result = await API.unbanPlayer(identifier);

        if (result.success) {
            Notifications.success('Joueur debanni', `${playerName} a ete debanni avec succes`);
            this.load();
        } else {
            Notifications.error('Erreur', result.error || 'Impossible de debannir le joueur');
        }
    },

    /**
     * Formater la date
     */
    formatDate(dateStr) {
        if (!dateStr) return '-';
        const date = new Date(dateStr);
        return date.toLocaleString('fr-FR', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }
};

// Export
window.BansModule = BansModule;
