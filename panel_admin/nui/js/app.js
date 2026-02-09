/**
 * App Principal - Panel Admin Fight League
 */

const App = {
    session: null,
    currentView: 'dashboard',
    quickMenuTarget: null,
    selectedVehicleColor: 5,

    // Permissions par grade
    // staff < organisateur < responsable < admin < owner
    permissions: {
        teleport: ['staff', 'organisateur', 'responsable', 'admin', 'owner'],
        spectate: ['staff', 'organisateur', 'responsable', 'admin', 'owner'],
        heal: ['staff', 'organisateur', 'responsable', 'admin', 'owner'],
        message: ['staff', 'organisateur', 'responsable', 'admin', 'owner'],
        freeze: ['organisateur', 'responsable', 'admin', 'owner'], // Pas staff
        kick: ['staff', 'organisateur', 'responsable', 'admin', 'owner'], // Staff peut kick
        vehicle: ['organisateur', 'responsable', 'admin', 'owner'], // A partir de organisateur
        ban: ['staff', 'organisateur', 'responsable', 'admin', 'owner'], // A partir de staff
        reportDelete: ['responsable', 'admin', 'owner'], // Supprimer les tickets pour responsable+
        reportStats: ['responsable', 'admin', 'owner'], // Stats des tickets pour responsable+
        eventStats: ['responsable', 'admin', 'owner'], // Stats des événements pour responsable+
        eventStatsReset: ['responsable', 'admin', 'owner'], // Reset du classement événements pour responsable+
        staffRoles: ['responsable', 'admin', 'owner'] // Gestion des rôles staff pour responsable+
    },

    /**
     * Initialiser l'application
     */
    init() {
        // Init modules
        Notifications.init();
        Modal.init();
        PlayersModule.init();
        SanctionsModule.init();
        TeleportModule.init();
        VehiclesModule.init();
        AnnouncementsModule.init();
        EconomyModule.init();
        LogsModule.init();
        BansModule.init();
        ReportsModule.init();
        ReportStatsModule.init();
        ReportNotification.init();
        EventsModule.init();
        EventStatsModule.init();
        StaffChatModule.init();
        ActivityModule.init();
        StaffRolesModule.init();

        // Event listeners
        this.setupEventListeners();

        // Message listener from Lua
        window.addEventListener('message', (event) => {
            this.handleMessage(event.data);
        });
    },

    /**
     * Setup event listeners
     */
    setupEventListeners() {
        // Navigation
        document.querySelectorAll('.nav-item').forEach(item => {
            item.addEventListener('click', () => {
                const view = item.dataset.view;
                this.switchView(view);
            });
        });

        // Close button
        document.getElementById('closePanel').addEventListener('click', () => {
            this.close();
        });

        // Refresh button
        document.getElementById('refreshData').addEventListener('click', () => {
            this.refreshCurrentView();
        });

        // Quick actions
        document.querySelectorAll('.quick-action-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const action = btn.dataset.action;
                this.handleQuickAction(action);
            });
        });

        // Global search
        const globalSearch = document.getElementById('globalSearch');
        globalSearch.addEventListener('input', Helpers.debounce((e) => {
            this.handleGlobalSearch(e.target.value);
        }, 300));

        // Escape key
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                // Fermer le quick menu en priorite
                const quickMenu = document.getElementById('quickMenu');
                if (!quickMenu.classList.contains('hidden')) {
                    this.handleQuickMenuAction('close');
                    return;
                }
                this.close();
            }
        });

        // Quick menu buttons
        document.querySelectorAll('.quick-menu-btn[data-action]').forEach(btn => {
            btn.addEventListener('click', () => {
                if (btn.classList.contains('disabled')) return;
                const action = btn.dataset.action;
                switch (action) {
                    case 'kick':
                        this.showKickInput();
                        break;
                    case 'message':
                        this.showMessageInput();
                        break;
                    case 'ban':
                        this.showBanInput();
                        break;
                    case 'vehicle':
                        this.showVehicleInput();
                        break;
                    default:
                        this.handleQuickMenuAction(action);
                }
            });
        });

        // Quick menu close button
        const quickMenuClose = document.getElementById('quickMenuClose');
        if (quickMenuClose) {
            quickMenuClose.addEventListener('click', () => {
                this.handleQuickMenuAction('close');
            });
        }

        // Kick confirm button
        const confirmKick = document.getElementById('quickMenuConfirmKick');
        if (confirmKick) {
            confirmKick.addEventListener('click', () => {
                const reason = document.getElementById('quickMenuKickReason').value || 'Aucune raison';
                this.handleQuickMenuAction('confirmKick', { reason: reason });
            });
        }

        // Kick cancel button
        const cancelKick = document.getElementById('quickMenuCancelKick');
        if (cancelKick) {
            cancelKick.addEventListener('click', () => {
                this.hideKickInput();
            });
        }

        // Message buttons
        const confirmMessage = document.getElementById('quickMenuConfirmMessage');
        if (confirmMessage) {
            confirmMessage.addEventListener('click', () => {
                const message = document.getElementById('quickMenuMessageText').value;
                if (message) {
                    this.handleQuickMenuAction('confirmMessage', { message: message });
                }
            });
        }

        const cancelMessage = document.getElementById('quickMenuCancelMessage');
        if (cancelMessage) {
            cancelMessage.addEventListener('click', () => {
                this.hideMessageInput();
            });
        }

        // Ban buttons
        const confirmBan = document.getElementById('quickMenuConfirmBan');
        if (confirmBan) {
            confirmBan.addEventListener('click', () => {
                const reason = document.getElementById('quickMenuBanReason').value || 'Aucune raison';
                const duration = document.getElementById('quickMenuBanDuration').value;
                this.handleQuickMenuAction('confirmBan', { reason: reason, duration: duration });
            });
        }

        const cancelBan = document.getElementById('quickMenuCancelBan');
        if (cancelBan) {
            cancelBan.addEventListener('click', () => {
                this.hideBanInput();
            });
        }

        // Vehicle buttons
        const confirmVehicle = document.getElementById('quickMenuConfirmVehicle');
        if (confirmVehicle) {
            confirmVehicle.addEventListener('click', () => {
                const model = document.getElementById('quickMenuVehicleModel').value;
                if (model) {
                    this.handleQuickMenuAction('confirmVehicle', {
                        model: model,
                        color: this.selectedVehicleColor
                    });
                }
            });
        }

        const cancelVehicle = document.getElementById('quickMenuCancelVehicle');
        if (cancelVehicle) {
            cancelVehicle.addEventListener('click', () => {
                this.hideVehicleInput();
            });
        }

        // Color swatches
        document.querySelectorAll('#quickMenuPrimaryColors .color-swatch').forEach(swatch => {
            swatch.addEventListener('click', () => {
                document.querySelectorAll('#quickMenuPrimaryColors .color-swatch').forEach(s => s.classList.remove('selected'));
                swatch.classList.add('selected');
                this.selectedVehicleColor = parseInt(swatch.dataset.color);
            });
        });
    },

    /**
     * Verifier si le grade a la permission
     */
    hasPermission(permission) {
        if (!this.session || !this.session.group) return false;
        const allowedGroups = this.permissions[permission] || [];
        return allowedGroups.includes(this.session.group.toLowerCase());
    },

    /**
     * Mettre a jour les boutons selon les permissions
     */
    updateQuickMenuPermissions() {
        document.querySelectorAll('.quick-menu-btn[data-perm]').forEach(btn => {
            const perm = btn.dataset.perm;
            if (!this.hasPermission(perm)) {
                btn.classList.add('disabled');
            } else {
                btn.classList.remove('disabled');
            }
        });
    },

    /**
     * Gérer les messages depuis Lua
     */
    handleMessage(data) {
        // Handle type-based messages (quick menu)
        if (data.type) {
            switch (data.type) {
                case 'openQuickMenu':
                    this.openQuickMenu(data.player);
                    return;
                case 'closeQuickMenu':
                    this.closeQuickMenu();
                    return;
                case 'showKickInput':
                    this.showKickInput();
                    return;
                case 'quickMenuFocusChanged':
                    this.updateQuickMenuFocusIndicator(data.focused);
                    return;
            }
        }

        // Handle action-based messages (main panel)
        switch (data.action) {
            case 'open':
                this.open(data.session);
                break;

            case 'close':
                this.close();
                break;

            case 'init':
                this.loadInitialData(data.data);
                break;

            case 'notification':
                Notifications.show(
                    data.data.type,
                    data.data.title,
                    data.data.message,
                    data.data.duration
                );
                break;

            case 'showAnnounceBanner':
                if (window.AnnouncementBanner) {
                    AnnouncementBanner.show(data.data);
                }
                break;

            case 'playAnnouncementSound':
                // Jouer uniquement le son d'annonce (pour les annonces normales dans le chat)
                const announcementAudio = document.getElementById('announcementSound');
                if (announcementAudio) {
                    announcementAudio.currentTime = 0;
                    announcementAudio.play().catch(() => {});
                }
                break;

            case 'newReport':
                // Nouveau report recu - afficher notification minimap
                if (window.ReportNotification) {
                    ReportNotification.show(data.data);
                }
                // Mettre a jour la liste si on est sur la vue reports
                if (this.currentView === 'reports') {
                    ReportsModule.onNewReport(data.data);
                }
                break;

            case 'enableReportInteraction':
                // Activer le mode interaction pour les notifications de report
                if (window.ReportNotification) {
                    ReportNotification.enableInteraction();
                }
                break;

            case 'disableReportInteraction':
                // Desactiver le mode interaction
                if (window.ReportNotification) {
                    ReportNotification.disableInteraction();
                }
                break;

            case 'switchToReports':
                // Ouvrir directement l'onglet Reports
                this.switchView('reports');
                break;

            case 'updateData':
                this.handleDataUpdate(data.dataType, data.data);
                break;

            case 'refreshReports':
                // Rafraichir la liste des reports (joueur deconnecte)
                if (this.currentView === 'reports') {
                    ReportsModule.load(true); // silent refresh
                }
                break;
        }
    },

    /**
     * Ouvrir le menu rapide (noclip)
     */
    openQuickMenu(player) {
        if (!player) return;

        this.quickMenuTarget = player.serverId;
        this.quickMenuFocused = false;

        // Stocker le groupe du joueur pour les permissions
        if (player.adminGroup) {
            this.session = this.session || {};
            this.session.group = player.adminGroup;
        }

        const menu = document.getElementById('quickMenu');
        document.getElementById('quickMenuName').textContent = player.name;
        document.getElementById('quickMenuId').textContent = `ID: ${player.serverId}`;

        // Health bar
        const healthPercent = Math.min(100, (player.health / player.maxHealth) * 100);
        document.getElementById('quickMenuHealth').style.width = `${healthPercent}%`;
        document.getElementById('quickMenuHealthText').textContent = Math.round(player.health);

        // Armor bar
        document.getElementById('quickMenuArmor').style.width = `${player.armor}%`;
        document.getElementById('quickMenuArmorText').textContent = player.armor;

        // Coords
        const coordsSpan = document.querySelector('#quickMenuCoords span');
        if (coordsSpan) {
            coordsSpan.textContent = `X: ${player.coords.x.toFixed(1)} | Y: ${player.coords.y.toFixed(1)} | Z: ${player.coords.z.toFixed(1)}`;
        }

        // Reset all input sections
        this.hideAllInputSections();

        // Update button permissions
        this.updateQuickMenuPermissions();

        // Afficher l'indicateur de focus
        this.updateQuickMenuFocusIndicator(false);

        menu.classList.remove('hidden');
    },

    /**
     * Mettre a jour l'indicateur de focus du quick menu
     */
    updateQuickMenuFocusIndicator(focused) {
        this.quickMenuFocused = focused;
        const indicator = document.getElementById('quickMenuFocusIndicator');
        if (indicator) {
            if (focused) {
                indicator.textContent = 'Mode: Interaction (ALT pour bouger)';
                indicator.style.color = '#fbbf24';
            } else {
                indicator.textContent = 'Mode: Libre (ALT pour interagir)';
                indicator.style.color = '#10b981';
            }
        }
    },

    /**
     * Demander le focus clavier au client Lua
     */
    requestKeyboardFocus() {
        fetch(`https://${GetParentResourceName()}/requestKeyboardFocus`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    },

    /**
     * Relacher le focus clavier
     */
    releaseKeyboardFocus() {
        fetch(`https://${GetParentResourceName()}/releaseKeyboardFocus`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    },

    /**
     * Cacher toutes les sections d'input
     */
    hideAllInputSections() {
        const sections = [
            'quickMenuKickInput',
            'quickMenuMessageInput',
            'quickMenuBanInput',
            'quickMenuVehicleInput'
        ];
        sections.forEach(id => {
            const el = document.getElementById(id);
            if (el) el.classList.add('hidden');
        });
        // Reset inputs
        ['quickMenuKickReason', 'quickMenuMessageText', 'quickMenuBanReason', 'quickMenuVehicleModel'].forEach(id => {
            const input = document.getElementById(id);
            if (input) input.value = '';
        });
        // Relacher le focus clavier si on etait en mode input
        if (this.quickMenuFocused) {
            this.releaseKeyboardFocus();
        }
    },

    /**
     * Afficher l'input de kick
     */
    showKickInput() {
        this.hideAllInputSections();
        const kickInput = document.getElementById('quickMenuKickInput');
        if (kickInput) {
            kickInput.classList.remove('hidden');
            // Demander le focus clavier pour pouvoir taper
            this.requestKeyboardFocus();
            const input = document.getElementById('quickMenuKickReason');
            if (input) {
                setTimeout(() => input.focus(), 50);
            }
        }
    },

    /**
     * Cacher l'input de kick
     */
    hideKickInput() {
        const kickInput = document.getElementById('quickMenuKickInput');
        if (kickInput) kickInput.classList.add('hidden');
        // Relacher le focus clavier
        this.releaseKeyboardFocus();
    },

    /**
     * Afficher l'input de message
     */
    showMessageInput() {
        this.hideAllInputSections();
        const msgInput = document.getElementById('quickMenuMessageInput');
        if (msgInput) {
            msgInput.classList.remove('hidden');
            // Demander le focus clavier pour pouvoir taper
            this.requestKeyboardFocus();
            const input = document.getElementById('quickMenuMessageText');
            if (input) {
                setTimeout(() => input.focus(), 50);
            }
        }
    },

    /**
     * Cacher l'input de message
     */
    hideMessageInput() {
        const msgInput = document.getElementById('quickMenuMessageInput');
        if (msgInput) msgInput.classList.add('hidden');
        // Relacher le focus clavier
        this.releaseKeyboardFocus();
    },

    /**
     * Afficher l'input de ban
     */
    showBanInput() {
        this.hideAllInputSections();
        const banInput = document.getElementById('quickMenuBanInput');
        if (banInput) {
            banInput.classList.remove('hidden');
            // Demander le focus clavier pour pouvoir taper
            this.requestKeyboardFocus();
            const input = document.getElementById('quickMenuBanReason');
            if (input) {
                setTimeout(() => input.focus(), 50);
            }
        }
    },

    /**
     * Cacher l'input de ban
     */
    hideBanInput() {
        const banInput = document.getElementById('quickMenuBanInput');
        if (banInput) banInput.classList.add('hidden');
        // Relacher le focus clavier
        this.releaseKeyboardFocus();
    },

    /**
     * Afficher le selecteur de vehicule
     */
    showVehicleInput() {
        this.hideAllInputSections();
        const vehInput = document.getElementById('quickMenuVehicleInput');
        if (vehInput) {
            vehInput.classList.remove('hidden');
            // Demander le focus clavier pour pouvoir taper
            this.requestKeyboardFocus();
            const input = document.getElementById('quickMenuVehicleModel');
            if (input) {
                setTimeout(() => input.focus(), 50);
            }
        }
    },

    /**
     * Cacher le selecteur de vehicule
     */
    hideVehicleInput() {
        const vehInput = document.getElementById('quickMenuVehicleInput');
        if (vehInput) vehInput.classList.add('hidden');
        // Relacher le focus clavier
        this.releaseKeyboardFocus();
    },

    /**
     * Fermer le menu rapide
     */
    closeQuickMenu() {
        document.getElementById('quickMenu').classList.add('hidden');
        this.hideAllInputSections();
        this.quickMenuTarget = null;
    },

    /**
     * Gérer action du menu rapide
     */
    handleQuickMenuAction(action, extraData = {}) {
        if (action === 'close') {
            fetch(`https://${GetParentResourceName()}/quickMenuAction`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ action: 'close' })
            });
            return;
        }

        if (!this.quickMenuTarget) return;

        const payload = {
            action: action,
            targetId: this.quickMenuTarget,
            ...extraData
        };

        fetch(`https://${GetParentResourceName()}/quickMenuAction`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });
    },

    /**
     * Ouvrir le panel
     */
    open(session) {
        this.session = session;
        document.getElementById('panel').classList.remove('hidden');

        // Update user info
        if (session) {
            document.getElementById('userName').textContent = session.name;
            document.getElementById('userGroup').textContent = session.group;
        }

        // Mettre a jour les onglets selon les permissions
        this.updateNavPermissions();
    },

    /**
     * Mettre a jour les onglets de navigation selon les permissions
     */
    updateNavPermissions() {
        document.querySelectorAll('.nav-item[data-perm]').forEach(item => {
            const perm = item.dataset.perm;
            if (perm && !this.hasPermission(perm)) {
                item.style.display = 'none';
            } else {
                item.style.display = '';
            }
        });

        // Mettre a jour les boutons avec data-perm
        document.querySelectorAll('button[data-perm]').forEach(btn => {
            const perm = btn.dataset.perm;
            if (perm && !this.hasPermission(perm)) {
                btn.style.display = 'none';
            } else {
                btn.style.display = '';
            }
        });
    },

    /**
     * Fermer le panel
     */
    close() {
        document.getElementById('panel').classList.add('hidden');
        API.close();
    },

    /**
     * Charger les données initiales
     */
    loadInitialData(data) {
        if (!data) return;

        // Session
        if (data.session) {
            this.session = data.session;
            document.getElementById('userName').textContent = data.session.name;
            document.getElementById('userGroup').textContent = data.session.group;

            // Set user for staff chat
            StaffChatModule.setCurrentUser(data.session);
        }

        // Dashboard stats
        if (data.dashboard) {
            document.getElementById('statPlayersOnline').textContent = data.dashboard.playersOnline || 0;
            document.getElementById('statStaffOnline').textContent = data.dashboard.staffOnline || 0;
            document.getElementById('statActiveEvents').textContent = data.dashboard.activeEvents || 0;
            document.getElementById('statSanctionsToday').textContent = data.dashboard.sanctionsToday || 0;
        }

        // Load view data
        this.switchView('dashboard');
    },

    /**
     * Changer de vue
     */
    switchView(view) {
        // Update navigation
        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.toggle('active', item.dataset.view === view);
        });

        // Update views
        document.querySelectorAll('.view').forEach(v => {
            v.classList.toggle('active', v.id === `view-${view}`);
        });

        // Update title
        const titles = {
            'dashboard': 'Dashboard',
            'players': 'Joueurs',
            'sanctions': 'Sanctions',
            'bans': 'Debannissements',
            'economy': 'Économie',
            'teleport': 'Téléportation',
            'vehicles': 'Véhicules',
            'events': 'Événements',
            'event-stats': 'Stats Événements',
            'announcements': 'Annonces',
            'reports': 'Reports',
            'report-stats': 'Stats Tickets',
            'staff-roles': 'Gestion Staff',
            'logs': 'Logs'
        };
        document.getElementById('viewTitle').textContent = titles[view] || view;

        this.currentView = view;

        // Load view data
        this.loadViewData(view);
    },

    /**
     * Charger les données d'une vue
     */
    loadViewData(view) {
        switch (view) {
            case 'dashboard':
                StaffChatModule.loadMessages();
                ActivityModule.load();
                break;
            case 'players':
                PlayersModule.load();
                break;
            case 'sanctions':
                SanctionsModule.load();
                break;
            case 'bans':
                BansModule.load();
                break;
            case 'teleport':
                TeleportModule.load();
                break;
            case 'economy':
                EconomyModule.load();
                break;
            case 'reports':
                ReportsModule.load();
                break;
            case 'report-stats':
                ReportStatsModule.load();
                break;
            case 'event-stats':
                EventStatsModule.load();
                break;
            case 'staff-roles':
                StaffRolesModule.load();
                break;
            case 'logs':
                LogsModule.load();
                break;
        }
    },

    /**
     * Rafraîchir la vue actuelle
     */
    refreshCurrentView() {
        this.loadViewData(this.currentView);
        Notifications.info('Rafraîchi', 'Données mises à jour');
    },

    /**
     * Gérer les actions rapides
     */
    handleQuickAction(action) {
        switch (action) {
            case 'announce':
                this.switchView('announcements');
                break;
            case 'tpmarker':
                TeleportModule.teleportToMarker();
                break;
            case 'spawncar':
                this.switchView('vehicles');
                break;
            case 'deletecar':
                VehiclesModule.deleteVehicle();
                break;
            case 'reports':
                this.switchView('reports');
                break;
            case 'events':
                this.switchView('events');
                break;
        }
    },

    /**
     * Gérer la recherche globale
     */
    handleGlobalSearch(query) {
        if (query.length < 2) return;

        // Switch to players and search
        this.switchView('players');
        document.getElementById('playerSearch').value = query;
        PlayersModule.filterPlayers(query);
    },

    /**
     * Gérer les mises à jour de données
     */
    handleDataUpdate(dataType, data) {
        switch (dataType) {
            case 'players':
                PlayersModule.players = data;
                PlayersModule.render();
                break;
        }
    }
};

// Initialize on DOM ready
document.addEventListener('DOMContentLoaded', () => {
    App.init();
});
