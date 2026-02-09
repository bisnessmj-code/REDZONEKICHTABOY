/**
 * Activity Module - Panel Admin Fight League
 * Timeline des activités récentes
 */

const ActivityModule = {
    activities: [],
    refreshInterval: null,

    /**
     * Initialize the module
     */
    init() {
        // Refresh button
        const refreshBtn = document.getElementById('refreshActivity');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', () => {
                this.load(true);
            });
        }

        // Auto-refresh every 30 seconds
        this.startAutoRefresh();
    },

    /**
     * Load activities from server
     */
    async load(showLoading = false) {
        const container = document.getElementById('recentActivity');
        const refreshBtn = document.getElementById('refreshActivity');

        if (showLoading && refreshBtn) {
            refreshBtn.classList.add('loading');
        }

        try {
            const response = await API.getRecentActivity();

            if (response && response.success) {
                this.activities = response.activities || [];
                this.render();
            }
        } catch (error) {
            console.error('[ACTIVITY] Error loading activities:', error);
        } finally {
            if (refreshBtn) {
                refreshBtn.classList.remove('loading');
            }
        }
    },

    /**
     * Render activities
     */
    render() {
        const container = document.getElementById('recentActivity');

        if (!this.activities || this.activities.length === 0) {
            container.innerHTML = `
                <div class="activity-empty">
                    <i class="fas fa-inbox"></i>
                    <p>Aucune activité récente</p>
                </div>
            `;
            return;
        }

        let html = '';
        this.activities.forEach(activity => {
            html += this.renderActivity(activity);
        });

        container.innerHTML = html;
    },

    /**
     * Render a single activity
     */
    renderActivity(activity) {
        const config = this.getActivityConfig(activity.type, activity.action);
        const time = this.formatTime(activity.created_at);

        return `
            <div class="activity-item">
                <div class="activity-icon ${config.iconClass}">
                    <i class="${config.icon}"></i>
                </div>
                <div class="activity-content">
                    <div class="activity-title">${this.formatMessage(activity, config)}</div>
                    <div class="activity-meta">
                        <span class="activity-staff">
                            <i class="fas fa-user-shield"></i>
                            ${this.escapeHtml(activity.staff_name)}
                            ${activity.staff_group ? `<span class="activity-badge ${activity.staff_group}">${activity.staff_group}</span>` : ''}
                        </span>
                        <span class="activity-time">
                            <i class="fas fa-clock"></i>
                            ${time}
                        </span>
                    </div>
                </div>
            </div>
        `;
    },

    /**
     * Get activity configuration (icon, class, label)
     */
    getActivityConfig(type, action) {
        const configs = {
            // Sanctions
            'sanction_ban_add': { icon: 'fas fa-gavel', iconClass: 'ban', label: 'Ban' },
            'sanction_kick_player': { icon: 'fas fa-door-open', iconClass: 'kick', label: 'Kick' },
            'sanction_warn_add': { icon: 'fas fa-exclamation-triangle', iconClass: 'warn', label: 'Warn' },
            'sanction_unban': { icon: 'fas fa-unlock', iconClass: 'unban', label: 'Unban' },

            // Player
            'player_player_heal': { icon: 'fas fa-heart', iconClass: 'economy', label: 'Heal' },
            'player_player_revive': { icon: 'fas fa-heartbeat', iconClass: 'economy', label: 'Revive' },
            'player_player_freeze': { icon: 'fas fa-snowflake', iconClass: 'teleport', label: 'Freeze' },
            'player_player_unfreeze': { icon: 'fas fa-sun', iconClass: 'teleport', label: 'Unfreeze' },
            'player_spectate_start': { icon: 'fas fa-eye', iconClass: 'teleport', label: 'Spectate' },

            // Teleport
            'teleport_tp_goto': { icon: 'fas fa-location-arrow', iconClass: 'teleport', label: 'Goto' },
            'teleport_tp_bring': { icon: 'fas fa-user-plus', iconClass: 'teleport', label: 'Bring' },
            'teleport_tp_coords': { icon: 'fas fa-map-marker-alt', iconClass: 'teleport', label: 'TP Coords' },
            'teleport_tp_player': { icon: 'fas fa-exchange-alt', iconClass: 'teleport', label: 'TP Player' },
            'teleport_tp_return': { icon: 'fas fa-undo', iconClass: 'teleport', label: 'Return' },
            'teleport_tp_return_player': { icon: 'fas fa-undo-alt', iconClass: 'teleport', label: 'Return joueur' },

            // Vehicle
            'vehicle_vehicle_spawn': { icon: 'fas fa-car', iconClass: 'vehicle', label: 'Spawn véhicule' },
            'vehicle_vehicle_delete': { icon: 'fas fa-car-crash', iconClass: 'vehicle', label: 'Delete véhicule' },
            'vehicle_vehicle_repair': { icon: 'fas fa-wrench', iconClass: 'vehicle', label: 'Repair véhicule' },

            // Events
            'event_event_start': { icon: 'fas fa-flag-checkered', iconClass: 'event', label: 'Event lancé' },
            'event_event_create': { icon: 'fas fa-plus-circle', iconClass: 'event', label: 'Event créé' },
            'event_event_announce': { icon: 'fas fa-bullhorn', iconClass: 'event', label: 'Event annoncé' },

            // Auth
            'auth_panel_open': { icon: 'fas fa-sign-in-alt', iconClass: 'connect', label: 'Connexion panel' },
            'auth_panel_close': { icon: 'fas fa-sign-out-alt', iconClass: 'disconnect', label: 'Déconnexion panel' },

            // Economy
            'economy_money_add': { icon: 'fas fa-coins', iconClass: 'economy', label: 'Give money' },
            'economy_money_remove': { icon: 'fas fa-minus-circle', iconClass: 'economy', label: 'Remove money' },
            'economy_money_set': { icon: 'fas fa-edit', iconClass: 'economy', label: 'Set money' },

            // Default
            'default': { icon: 'fas fa-circle', iconClass: 'connect', label: 'Action' }
        };

        const key = `${type}_${action}`;
        return configs[key] || configs['default'];
    },

    /**
     * Format activity message
     */
    formatMessage(activity, config) {
        const targetName = activity.target_name ? `<strong>${this.escapeHtml(activity.target_name)}</strong>` : '';
        const details = activity.details || {};

        switch (activity.type) {
            case 'sanction':
                if (activity.action === 'ban_add') {
                    return `Ban de ${targetName}`;
                } else if (activity.action === 'kick_player') {
                    return `Kick de ${targetName}`;
                } else if (activity.action === 'warn_add') {
                    return `Warn de ${targetName}`;
                } else if (activity.action === 'unban') {
                    return `Unban de ${targetName}`;
                }
                break;

            case 'player':
                if (activity.action === 'player_heal') {
                    return `Heal de ${targetName}`;
                } else if (activity.action === 'player_revive') {
                    return `Revive de ${targetName}`;
                } else if (activity.action === 'player_freeze') {
                    return `Freeze de ${targetName}`;
                } else if (activity.action === 'player_unfreeze') {
                    return `Unfreeze de ${targetName}`;
                } else if (activity.action === 'spectate_start') {
                    return `Spectate de ${targetName}`;
                }
                break;

            case 'teleport':
                if (activity.action === 'tp_goto') {
                    return `Teleportation vers ${targetName}`;
                } else if (activity.action === 'tp_bring') {
                    return `Bring de ${targetName}`;
                } else if (activity.action === 'tp_coords') {
                    return `Teleportation aux coordonnees`;
                } else if (activity.action === 'tp_return' || activity.action === 'tp_return_player') {
                    return `Return de ${targetName || 'soi-meme'}`;
                }
                break;

            case 'vehicle':
                if (activity.action === 'vehicle_spawn') {
                    const model = details.model || 'vehicule';
                    return `Spawn <strong>${model}</strong>${targetName ? ` pour ${targetName}` : ''}`;
                } else if (activity.action === 'vehicle_delete') {
                    return `Suppression vehicule${targetName ? ` de ${targetName}` : ''}`;
                } else if (activity.action === 'vehicle_repair') {
                    return `Reparation vehicule${targetName ? ` de ${targetName}` : ''}`;
                }
                break;

            case 'event':
                const eventType = details.type || details.eventType || 'Event';
                if (activity.action === 'event_start' || activity.action === 'event_create') {
                    return `Lancement event <strong>${eventType}</strong>`;
                } else if (activity.action === 'event_announce') {
                    return `Annonce event <strong>${eventType}</strong>`;
                }
                break;

            case 'auth':
                if (activity.action === 'panel_open') {
                    return `Connexion au panel`;
                } else if (activity.action === 'panel_close') {
                    return `Deconnexion du panel`;
                }
                break;

            case 'economy':
                const amount = details.amount ? `<strong>$${Number(details.amount).toLocaleString()}</strong>` : '';
                const accountType = details.account || details.type || '';
                if (activity.action === 'money_add') {
                    return `Give ${amount} ${accountType} a ${targetName}`;
                } else if (activity.action === 'money_remove') {
                    return `Remove ${amount} ${accountType} de ${targetName}`;
                } else if (activity.action === 'money_set') {
                    return `Set ${amount} ${accountType} pour ${targetName}`;
                }
                break;
        }

        return config.label;
    },

    /**
     * Format time (relative)
     */
    formatTime(dateStr) {
        const date = new Date(dateStr);
        const now = new Date();
        const diff = Math.floor((now - date) / 1000);

        if (diff < 60) {
            return 'À l\'instant';
        } else if (diff < 3600) {
            const mins = Math.floor(diff / 60);
            return `Il y a ${mins}m`;
        } else if (diff < 86400) {
            const hours = Math.floor(diff / 3600);
            return `Il y a ${hours}h`;
        } else {
            const days = Math.floor(diff / 86400);
            return `Il y a ${days}j`;
        }
    },

    /**
     * Start auto-refresh
     */
    startAutoRefresh() {
        this.refreshInterval = setInterval(() => {
            const dashboardView = document.getElementById('view-dashboard');
            if (dashboardView && dashboardView.classList.contains('active')) {
                this.load();
            }
        }, 30000);
    },

    /**
     * Stop auto-refresh
     */
    stopAutoRefresh() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
            this.refreshInterval = null;
        }
    },

    /**
     * Escape HTML
     */
    escapeHtml(text) {
        if (!text) return '';
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
};

// Export
window.ActivityModule = ActivityModule;
