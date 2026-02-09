/**
 * Event Stats Module - Panel Admin Fight League
 * Statistiques des événements (GDT/CVC)
 */

const EventStatsModule = {
    currentFilter: 'all',
    stats: null,

    /**
     * Initialiser le module
     */
    init() {
        this.bindEvents();
    },

    /**
     * Lier les événements
     */
    bindEvents() {
        // Filtre de temps
        const timeFilter = document.getElementById('eventStatsTimeFilter');
        if (timeFilter) {
            timeFilter.addEventListener('change', (e) => {
                this.currentFilter = e.target.value;
                this.load();
            });
        }

        // Bouton refresh
        const refreshBtn = document.getElementById('refreshEventStats');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', () => this.load());
        }

        // Bouton reset
        const resetBtn = document.getElementById('resetEventStats');
        if (resetBtn) {
            resetBtn.addEventListener('click', () => this.confirmReset());
        }
    },

    /**
     * Mettre a jour les permissions du bouton reset
     */
    updateResetPermission() {
        const resetBtn = document.getElementById('resetEventStats');
        if (resetBtn) {
            if (App.hasPermission('eventStatsReset')) {
                resetBtn.style.display = '';
            } else {
                resetBtn.style.display = 'none';
            }
        }
    },

    /**
     * Confirmer la réinitialisation du classement
     */
    async confirmReset() {
        const confirmed = await Modal.confirm({
            title: 'Réinitialiser le classement',
            message: 'Êtes-vous sûr de vouloir réinitialiser le classement des événements ? Cette action supprimera toutes les statistiques d\'annonces (GDT/CVC) et est irréversible.',
            confirmText: 'Réinitialiser',
            danger: true
        });

        if (confirmed) {
            this.resetStats();
        }
    },

    /**
     * Réinitialiser les statistiques
     */
    async resetStats() {
        try {
            const result = await API.resetEventStats();

            if (result.success) {
                Notifications.success('Classement réinitialisé avec succès');
                this.load(); // Recharger les stats
            } else {
                Notifications.error(result.error === 'NO_PERMISSION' ? 'Vous n\'avez pas la permission' : 'Erreur lors de la réinitialisation');
            }
        } catch (error) {
            console.error('Erreur reset stats events:', error);
            Notifications.error('Erreur lors de la réinitialisation');
        }
    },

    /**
     * Charger les statistiques
     */
    async load() {
        // Mettre a jour les permissions du bouton reset
        this.updateResetPermission();

        try {
            const result = await API.getEventStats(this.currentFilter);

            if (result.success) {
                this.stats = result.data;
                this.render();
            } else {
                console.error('Erreur chargement stats events:', result.error);
            }
        } catch (error) {
            console.error('Erreur API stats events:', error);
        }
    },

    /**
     * Afficher les statistiques
     */
    render() {
        if (!this.stats) return;

        // Stats globales
        this.renderGlobalStats();

        // Podium
        this.renderPodium();

        // Tableau
        this.renderTable();
    },

    /**
     * Afficher les stats globales
     */
    renderGlobalStats() {
        const global = this.stats.global;

        const totalEl = document.getElementById('eventStatsTotal');
        const gdtEl = document.getElementById('eventStatsGDT');
        const cvcEl = document.getElementById('eventStatsCVC');

        if (totalEl) totalEl.textContent = global.total || 0;
        if (gdtEl) gdtEl.textContent = global.gdt_total || 0;
        if (cvcEl) cvcEl.textContent = global.cvc_total || 0;
    },

    /**
     * Afficher le podium
     */
    renderPodium() {
        const staff = this.stats.staff || [];

        // Top 3
        const first = staff[0] || null;
        const second = staff[1] || null;
        const third = staff[2] || null;

        this.updatePodiumItem('eventPodiumFirst', first, 1);
        this.updatePodiumItem('eventPodiumSecond', second, 2);
        this.updatePodiumItem('eventPodiumThird', third, 3);
    },

    /**
     * Mettre à jour un élément du podium
     */
    updatePodiumItem(elementId, data, rank) {
        const element = document.getElementById(elementId);
        if (!element) return;

        const nameEl = element.querySelector('.podium-name');
        const countEl = element.querySelector('.podium-count');

        if (data) {
            if (nameEl) nameEl.textContent = data.name || 'Inconnu';
            if (countEl) countEl.textContent = data.total_announces || 0;
            element.classList.remove('empty');
        } else {
            if (nameEl) nameEl.textContent = '-';
            if (countEl) countEl.textContent = '0';
            element.classList.add('empty');
        }
    },

    /**
     * Afficher le tableau
     */
    renderTable() {
        const tbody = document.querySelector('#eventStatsTable tbody');
        if (!tbody) return;

        const staff = this.stats.staff || [];

        if (staff.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="6" class="text-center text-muted">
                        Aucune donnée disponible pour cette période
                    </td>
                </tr>
            `;
            return;
        }

        tbody.innerHTML = staff.map((item, index) => {
            const rank = index + 1;
            const rankClass = rank <= 3 ? `rank-${rank}` : '';
            const rankIcon = rank === 1 ? '<i class="fas fa-trophy" style="color: gold;"></i>' :
                            rank === 2 ? '<i class="fas fa-medal" style="color: silver;"></i>' :
                            rank === 3 ? '<i class="fas fa-medal" style="color: #cd7f32;"></i>' : rank;

            const lastAnnounce = item.last_announce ? Helpers.formatDate(item.last_announce) : '-';

            return `
                <tr class="${rankClass}">
                    <td>${rankIcon}</td>
                    <td>
                        <div class="player-info">
                            <div class="player-avatar">
                                <i class="fas fa-user"></i>
                            </div>
                            <span class="player-name">${Helpers.escapeHtml(item.name)}</span>
                        </div>
                    </td>
                    <td><span class="badge badge-primary">${item.total_announces || 0}</span></td>
                    <td><span class="badge badge-info">${item.gdt_count || 0}</span></td>
                    <td><span class="badge badge-danger">${item.cvc_count || 0}</span></td>
                    <td class="text-muted">${lastAnnounce}</td>
                </tr>
            `;
        }).join('');
    }
};

// Export
window.EventStatsModule = EventStatsModule;
