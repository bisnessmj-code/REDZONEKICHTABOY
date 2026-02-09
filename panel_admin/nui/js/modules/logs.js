/**
 * Logs Module - Panel Admin Fight League
 * Affichage de l'historique des logs
 */

const LogsModule = {
    logs: [],
    currentPage: 1,
    perPage: 50,
    totalCount: 0,
    currentFilters: {},

    searchTimeout: null,

    /**
     * Initialiser le module
     */
    init() {
        const categoryFilter = document.getElementById('logCategoryFilter');
        if (categoryFilter) {
            categoryFilter.addEventListener('change', (e) => {
                this.currentFilters.category = e.target.value || null;
                this.currentPage = 1;
                this.load();
            });
        }

        // Recherche par nom FiveM avec debounce
        const searchInput = document.getElementById('logSearchInput');
        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                // Debounce pour eviter trop de requetes
                clearTimeout(this.searchTimeout);
                this.searchTimeout = setTimeout(() => {
                    this.currentFilters.search = e.target.value.trim() || null;
                    this.currentPage = 1;
                    this.load();
                }, 300);
            });

            // Recherche immediate sur Enter
            searchInput.addEventListener('keydown', (e) => {
                if (e.key === 'Enter') {
                    clearTimeout(this.searchTimeout);
                    this.currentFilters.search = e.target.value.trim() || null;
                    this.currentPage = 1;
                    this.load();
                }
            });
        }
    },

    /**
     * Charger les logs
     */
    async load() {
        const filters = {};

        if (this.currentFilters.category) {
            filters.category = this.currentFilters.category;
        }

        if (this.currentFilters.search) {
            filters.search = this.currentFilters.search;
        }

        const result = await API.getLogs(filters, this.currentPage, this.perPage);

        if (result.success) {
            this.logs = result.logs || [];
            this.render();
        } else {
            this.renderError(result.error);
        }
    },

    /**
     * Rendre la table des logs
     */
    render() {
        const tbody = document.querySelector('#logsTable tbody');
        if (!tbody) return;

        if (this.logs.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="5">
                        <div class="table-empty">
                            <i class="fas fa-history"></i>
                            <p>Aucun log trouve</p>
                        </div>
                    </td>
                </tr>
            `;
            return;
        }

        tbody.innerHTML = this.logs.map(log => {
            // Gestion speciale pour les morts
            let staffDisplay = log.staff_name || 'Systeme';
            let staffId = log.staff_server_id || 0;
            let targetId = log.target_server_id || 0;
            let actionDisplay = this.formatAction(log.action);
            let details = '';

            if (log.category === 'death') {
                try {
                    const detailsData = typeof log.details === 'string' ? JSON.parse(log.details) : log.details;
                    if (detailsData && detailsData.cause) {
                        details = ` (${detailsData.cause})`;
                    }
                } catch(e) {}

                if (log.action === 'death_pvp') {
                    staffDisplay = log.staff_name || 'Inconnu';
                    actionDisplay = 'a tue';
                } else if (log.action === 'death_suicide') {
                    staffDisplay = log.target_name;
                    staffId = targetId;
                    actionDisplay = 'Suicide';
                } else {
                    staffDisplay = '-';
                    staffId = 0;
                    actionDisplay = 'Mort';
                }
            }

            // Formater l'affichage avec ID
            const staffWithId = staffDisplay !== '-' && staffDisplay !== 'Systeme' && staffId > 0
                ? `${Helpers.escapeHtml(staffDisplay)} <span class="text-muted">[${staffId}]</span>`
                : Helpers.escapeHtml(staffDisplay);

            const targetWithId = log.target_name && targetId > 0
                ? `${Helpers.escapeHtml(log.target_name)} <span class="text-muted">[${targetId}]</span>`
                : (log.target_name ? Helpers.escapeHtml(log.target_name) : '<span class="text-muted">-</span>');

            return `
                <tr>
                    <td>
                        <span class="badge ${this.getCategoryBadgeClass(log.category)}">
                            ${this.formatCategory(log.category)}
                        </span>
                    </td>
                    <td>${Helpers.escapeHtml(actionDisplay)}${details}</td>
                    <td>
                        <div class="player-info">
                            <span class="player-name">${staffWithId}</span>
                        </div>
                    </td>
                    <td>
                        ${targetWithId}
                    </td>
                    <td>
                        <span class="text-muted">${this.formatDate(log.created_at)}</span>
                    </td>
                </tr>
            `;
        }).join('');
    },

    /**
     * Afficher une erreur
     */
    renderError(error) {
        const tbody = document.querySelector('#logsTable tbody');
        if (!tbody) return;

        tbody.innerHTML = `
            <tr>
                <td colspan="5">
                    <div class="table-empty">
                        <i class="fas fa-exclamation-triangle"></i>
                        <p>Erreur: ${error || 'Impossible de charger les logs'}</p>
                    </div>
                </td>
            </tr>
        `;
    },

    /**
     * Formater la categorie
     */
    formatCategory(category) {
        const categories = {
            'auth': 'Authentification',
            'player': 'Joueur',
            'sanction': 'Sanction',
            'economy': 'Economie',
            'teleport': 'Teleportation',
            'vehicle': 'Vehicule',
            'event': 'Evenement',
            'system': 'Systeme',
            'death': 'Mort'
        };
        return categories[category] || category;
    },

    /**
     * Formater l'action
     */
    formatAction(action) {
        const actions = {
            'panel_open': 'Ouverture panel',
            'panel_close': 'Fermeture panel',
            'view_player': 'Consultation joueur',
            'spectate_start': 'Debut spectate',
            'spectate_end': 'Fin spectate',
            'player_revive': 'Reanimation',
            'player_heal': 'Soin',
            'player_freeze': 'Freeze',
            'player_unfreeze': 'Unfreeze',
            'player_setgroup': 'Changement grade',
            'warn_add': 'Avertissement',
            'kick_player': 'Expulsion',
            'ban_add': 'Bannissement',
            'unban': 'Debannissement',
            'sanction_remove': 'Suppression sanction',
            'money_add': 'Ajout argent',
            'money_remove': 'Retrait argent',
            'money_set': 'Definition argent',
            'tp_coords': 'TP coordonnees',
            'tp_player': 'TP joueur',
            'tp_bring': 'Amener joueur',
            'tp_goto': 'Aller vers',
            'tp_return': 'Retour position',
            'tp_return_player': 'Retour joueur',
            'vehicle_spawn': 'Spawn vehicule',
            'vehicle_delete': 'Suppression vehicule',
            'vehicle_repair': 'Reparation vehicule',
            'event_create': 'Creation evenement',
            'event_start': 'Debut evenement',
            'event_end': 'Fin evenement',
            'event_cancel': 'Annulation evenement',
            'announce_send': 'Envoi annonce',
            'announce_schedule': 'Planification annonce',
            'death_pvp': 'Tue par joueur',
            'death_suicide': 'Suicide',
            'death_environment': 'Mort environnement'
        };
        return actions[action] || action;
    },

    /**
     * Obtenir la classe du badge par categorie
     */
    getCategoryBadgeClass(category) {
        const classes = {
            'auth': 'badge-info',
            'player': 'badge-primary',
            'sanction': 'badge-danger',
            'economy': 'badge-success',
            'teleport': 'badge-warning',
            'vehicle': 'badge-secondary',
            'event': 'badge-purple',
            'system': 'badge-dark',
            'death': 'badge-danger'
        };
        return classes[category] || 'badge-secondary';
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
window.LogsModule = LogsModule;
