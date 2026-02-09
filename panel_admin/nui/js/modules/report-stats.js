/**
 * Report Stats Module - Panel Admin Fight League
 * Statistiques des tickets resolus par staff
 */

const ReportStatsModule = {
    stats: [],
    currentFilter: 'all',

    /**
     * Initialiser le module
     */
    init() {
        // Filtre de temps
        const timeFilter = document.getElementById('statsTimeFilter');
        if (timeFilter) {
            timeFilter.addEventListener('change', (e) => {
                this.currentFilter = e.target.value;
                this.load();
            });
        }

        // Bouton refresh
        const refreshBtn = document.getElementById('refreshStats');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', () => {
                this.load();
            });
        }
    },

    /**
     * Charger les statistiques
     */
    async load() {
        const result = await API.getReportStats(this.currentFilter);

        if (result.success) {
            this.stats = result.stats || [];
            this.updateSummary(result.summary || {});
            this.updatePodium();
            this.render();
        } else {
            Notifications.error('Erreur', result.error || 'Impossible de charger les statistiques');
        }
    },

    /**
     * Mettre a jour le resume
     */
    updateSummary(summary) {
        const totalEl = document.getElementById('totalTicketsResolved');
        const weekEl = document.getElementById('ticketsThisWeek');
        const todayEl = document.getElementById('ticketsToday');

        if (totalEl) totalEl.textContent = summary.total || 0;
        if (weekEl) weekEl.textContent = summary.week || 0;
        if (todayEl) todayEl.textContent = summary.today || 0;
    },

    /**
     * Mettre a jour le podium
     */
    updatePodium() {
        const positions = ['first', 'second', 'third'];
        const top3 = this.stats.slice(0, 3);

        positions.forEach((pos, index) => {
            const podium = document.getElementById(`podium${pos.charAt(0).toUpperCase() + pos.slice(1)}`);
            if (!podium) return;

            const staff = top3[index];
            const nameEl = podium.querySelector('.podium-name');
            const countEl = podium.querySelector('.podium-count');

            if (staff) {
                nameEl.textContent = staff.staff_name || 'Inconnu';
                countEl.textContent = `${staff.resolved_count} tickets`;
            } else {
                nameEl.textContent = '-';
                countEl.textContent = '0 tickets';
            }
        });
    },

    /**
     * Rendre le tableau
     */
    render() {
        const tbody = document.getElementById('statsTableBody');
        if (!tbody) return;

        if (this.stats.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="5" style="text-align: center; padding: 40px; color: var(--text-muted);">
                        <i class="fas fa-chart-bar" style="font-size: 48px; margin-bottom: 10px; display: block; opacity: 0.5;"></i>
                        Aucune statistique disponible
                    </td>
                </tr>
            `;
            return;
        }

        tbody.innerHTML = this.stats.map((staff, index) => {
            const rank = index + 1;
            const rankClass = rank <= 3 ? `rank-${rank}` : '';
            const rankIcon = this.getRankIcon(rank);

            return `
                <tr class="${rankClass}">
                    <td>
                        <span class="rank-badge ${rankClass}">${rankIcon} ${rank}</span>
                    </td>
                    <td>
                        <div class="staff-cell">
                            <div class="staff-avatar-small">
                                <i class="fas fa-user"></i>
                            </div>
                            <span class="staff-name">${this.escapeHtml(staff.staff_name || 'Inconnu')}</span>
                        </div>
                    </td>
                    <td>
                        <span class="group-badge" style="background: ${this.getGroupColor(staff.staff_group)};">
                            ${this.escapeHtml(staff.staff_group || 'N/A')}
                        </span>
                    </td>
                    <td>
                        <span class="ticket-count">${staff.resolved_count}</span>
                    </td>
                    <td>
                        <span class="last-ticket-date">${this.formatDate(staff.last_resolved)}</span>
                    </td>
                </tr>
            `;
        }).join('');
    },

    /**
     * Obtenir l'icone du rang
     */
    getRankIcon(rank) {
        switch (rank) {
            case 1: return '<i class="fas fa-trophy" style="color: #ffd700;"></i>';
            case 2: return '<i class="fas fa-medal" style="color: #c0c0c0;"></i>';
            case 3: return '<i class="fas fa-medal" style="color: #cd7f32;"></i>';
            default: return '';
        }
    },

    /**
     * Obtenir la couleur du groupe
     */
    getGroupColor(group) {
        const colors = {
            owner: '#e74c3c',
            admin: '#9b59b6',
            responsable: '#3498db',
            organisateur: '#2ecc71',
            staff: '#f39c12'
        };
        return colors[group?.toLowerCase()] || '#6b7280';
    },

    /**
     * Formater la date
     */
    formatDate(dateStr) {
        if (!dateStr) return 'Jamais';

        const date = new Date(dateStr);
        const now = new Date();
        const diff = Math.floor((now - date) / 1000);

        if (diff < 60) return 'A l\'instant';
        if (diff < 3600) return `Il y a ${Math.floor(diff / 60)} min`;
        if (diff < 86400) return `Il y a ${Math.floor(diff / 3600)}h`;
        if (diff < 604800) return `Il y a ${Math.floor(diff / 86400)}j`;

        return date.toLocaleDateString('fr-FR', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric'
        });
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
window.ReportStatsModule = ReportStatsModule;
