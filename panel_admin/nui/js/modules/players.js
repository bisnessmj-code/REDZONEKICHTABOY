/**
 * Players Module - Panel Admin Fight League
 */

const PlayersModule = {
    players: [],
    selectedPlayer: null,
    searchTimeout: null,
    currentGroupFilter: '',

    /**
     * Initialiser le module
     */
    init() {
        // Search input
        const searchInput = document.getElementById('playerSearch');
        searchInput.addEventListener('input', (e) => {
            clearTimeout(this.searchTimeout);
            this.searchTimeout = setTimeout(() => {
                this.applyFilters();
            }, 300);
        });

        // Group filter
        const groupFilter = document.getElementById('playerGroupFilter');
        if (groupFilter) {
            groupFilter.addEventListener('change', (e) => {
                this.currentGroupFilter = e.target.value;
                this.applyFilters();
            });
        }

        // Staff only checkbox
        const staffOnlyCheckbox = document.getElementById('staffOnlyFilter');
        if (staffOnlyCheckbox) {
            staffOnlyCheckbox.addEventListener('change', () => {
                this.applyFilters();
            });
        }

        // Include offline checkbox
        const offlineCheckbox = document.getElementById('includeOffline');
        offlineCheckbox.addEventListener('change', () => {
            this.load();
        });
    },

    /**
     * Charger la liste des joueurs
     */
    async load() {
        const result = await API.getPlayers();

        if (result.success) {
            this.players = result.players;
            this.render();
        }
    },

    /**
     * Appliquer tous les filtres (recherche + groupe + staff)
     */
    applyFilters() {
        const searchInput = document.getElementById('playerSearch');
        const query = searchInput ? searchInput.value.toLowerCase().trim() : '';
        const groupFilter = this.currentGroupFilter;
        const staffOnlyCheckbox = document.getElementById('staffOnlyFilter');
        const staffOnly = staffOnlyCheckbox ? staffOnlyCheckbox.checked : false;

        // Liste des groupes staff
        const staffGroups = ['staff', 'organisateur', 'responsable', 'admin', 'owner'];

        let filtered = this.players;

        // Filtre par texte (nom, ID, identifier)
        if (query) {
            // Verifier si c'est une recherche par ID (nombre seul)
            const queryNum = parseInt(query);
            if (!isNaN(queryNum) && query === queryNum.toString()) {
                // Recherche exacte par ID
                filtered = filtered.filter(p => p.id === queryNum);
            } else {
                // Recherche par nom/identifier
                filtered = filtered.filter(p =>
                    p.name.toLowerCase().includes(query) ||
                    (p.fivemName && p.fivemName.toLowerCase().includes(query)) ||
                    p.identifier.toLowerCase().includes(query)
                );
            }
        }

        // Filtre par groupe
        if (groupFilter) {
            filtered = filtered.filter(p => p.group === groupFilter);
        }

        // Filtre staff uniquement
        if (staffOnly) {
            filtered = filtered.filter(p => staffGroups.includes(p.group.toLowerCase()));
        }

        this.render(filtered);
    },

    /**
     * Filtrer les joueurs (legacy - utilise applyFilters)
     */
    filterPlayers(query) {
        this.applyFilters();
    },

    /**
     * Rendre la table des joueurs
     */
    render(players = this.players) {
        const tbody = document.querySelector('#playersTable tbody');

        if (players.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="6">
                        <div class="table-empty">
                            <i class="fas fa-users"></i>
                            <p>Aucun joueur trouvé</p>
                        </div>
                    </td>
                </tr>
            `;
            return;
        }

        tbody.innerHTML = players.map(player => {
            const fivemName = player.fivemName || player.name;
            const displayName = player.fivemName ? `${Helpers.escapeHtml(player.fivemName)}` : Helpers.escapeHtml(player.name);
            const charName = player.fivemName && player.name !== player.fivemName ? `<span class="player-char-name">(${Helpers.escapeHtml(player.name)})</span>` : '';

            return `
            <tr data-id="${player.id}">
                <td>
                    <span class="badge badge-info">${player.id}</span>
                </td>
                <td>
                    <div class="player-info">
                        <div class="player-avatar">
                            <i class="fas fa-user"></i>
                        </div>
                        <div class="player-names">
                            <span class="player-name">${displayName}</span>
                            ${charName}
                        </div>
                    </div>
                </td>
                <td>
                    <span class="badge ${Helpers.getGradeBadgeClass(player.group)}">
                        ${Helpers.escapeHtml(player.group)}
                    </span>
                </td>
                <td>${Helpers.escapeHtml(player.jobLabel || player.job)}</td>
                <td>
                    <div class="ping">
                        <span class="ping-indicator ${Helpers.getPingClass(player.ping)}"></span>
                        ${player.ping}ms
                    </div>
                </td>
                <td>
                    <div class="table-actions">
                        <button class="btn btn-sm btn-secondary" onclick="PlayersModule.showDetails(${player.id})" title="Détails">
                            <i class="fas fa-eye"></i>
                        </button>
                        <button class="btn btn-sm btn-secondary" onclick="PlayersModule.spectate(${player.id})" title="Spectate">
                            <i class="fas fa-video"></i>
                        </button>
                        <button class="btn btn-sm btn-secondary" onclick="PlayersModule.goto(${player.id})" title="Aller vers">
                            <i class="fas fa-location-arrow"></i>
                        </button>
                        <button class="btn btn-sm btn-warning" onclick="PlayersModule.showSanctionModal(${player.id}, '${Helpers.escapeHtml(fivemName)}')" title="Sanctionner">
                            <i class="fas fa-gavel"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `}).join('');
    },

    /**
     * Afficher les détails d'un joueur
     */
    async showDetails(playerId) {
        const result = await API.getPlayerDetails(playerId);

        if (!result.success) {
            Notifications.error('Erreur', 'Impossible de charger les détails');
            return;
        }

        const player = result.player;
        this.selectedPlayer = player;

        const fivemName = player.fivemName || player.name;
        const charNameDisplay = player.fivemName && player.name !== player.fivemName ? `<span class="player-detail-char">(${Helpers.escapeHtml(player.name)})</span>` : '';

        const body = `
            <div class="player-detail-header">
                <div class="player-detail-avatar">
                    <i class="fas fa-user"></i>
                </div>
                <div class="player-detail-info">
                    <h4>${Helpers.escapeHtml(fivemName)} ${charNameDisplay}</h4>
                    <div class="player-detail-meta">
                        <span><i class="fas fa-id-badge"></i> ID: ${player.id}</span>
                        <span class="badge ${Helpers.getGradeBadgeClass(player.group)}">${player.group}</span>
                    </div>
                </div>
            </div>

            <div class="detail-grid">
                <div class="detail-item">
                    <label>Nom FiveM</label>
                    <span>${Helpers.escapeHtml(fivemName)}</span>
                </div>
                <div class="detail-item">
                    <label>Personnage</label>
                    <span>${Helpers.escapeHtml(player.name)}</span>
                </div>
                <div class="detail-item">
                    <label>Identifier</label>
                    <span>${Helpers.escapeHtml(player.identifier)}</span>
                </div>
                <div class="detail-item">
                    <label><i class="fab fa-discord" style="color: #5865F2;"></i> Discord</label>
                    <span>${player.identifiers && player.identifiers.discord ? Helpers.escapeHtml(player.identifiers.discord.replace('discord:', '')) : 'Non lié'}</span>
                </div>
                <div class="detail-item">
                    <label>Job</label>
                    <span>${Helpers.escapeHtml(player.job.label)} (${player.job.gradeLabel})</span>
                </div>
                <div class="detail-item">
                    <label>Espèces</label>
                    <span>$${Helpers.formatNumber(player.money.cash)}</span>
                </div>
                <div class="detail-item">
                    <label>Banque</label>
                    <span>$${Helpers.formatNumber(player.money.bank)}</span>
                </div>
                <div class="detail-item">
                    <label>Ping</label>
                    <span>${player.ping}ms</span>
                </div>
                <div class="detail-item">
                    <label>Sanctions</label>
                    <span>${player.stats.totalSanctions} (${player.stats.warns} warns)</span>
                </div>
            </div>
        `;

        Modal.open({
            title: 'Détails du joueur',
            body,
            size: 'lg',
            footer: [
                { text: 'Fermer', class: 'btn-secondary', onClick: () => Modal.close() },
                { text: 'Amener ici', class: 'btn-primary', onClick: () => this.bring(player.id) },
                { text: 'Retourner', class: 'btn-info', onClick: () => this.returnPlayer(player.id) },
                { text: 'Sanctionner', class: 'btn-warning', onClick: () => this.showSanctionModal(player.id, player.name) },
                { text: 'Message', class: 'btn-info', onClick: () => this.showMessageModal(player.id, player.name) }
            ]
        });
    },

    /**
     * Modal d'envoi de message
     */
    showMessageModal(playerId, playerName) {
        const body = `
            <div class="form-group">
                <label>Message</label>
                <textarea id="playerMessageText" rows="3" placeholder="Message a envoyer..."></textarea>
            </div>
        `;

        Modal.open({
            title: `Envoyer un message a ${playerName}`,
            body,
            footer: [
                { text: 'Annuler', class: 'btn-secondary', onClick: () => Modal.close() },
                { text: 'Envoyer', class: 'btn-primary', onClick: () => {
                    const message = document.getElementById('playerMessageText').value;
                    if (message && message.trim() !== '') {
                        fetch(`https://${GetParentResourceName()}/sendMessageToPlayer`, {
                            method: 'POST',
                            body: JSON.stringify({ playerId: playerId, message: message })
                        });
                        Modal.close();
                    }
                }}
            ]
        });
    },

    /**
     * Modal de sanction
     */
    showSanctionModal(playerId, playerName) {
        const body = `
            <div class="form-group">
                <label>Type de sanction</label>
                <select id="sanctionType">
                    <option value="warn">Avertissement</option>
                    <option value="kick">Expulsion</option>
                    <option value="ban">Bannissement</option>
                </select>
            </div>
            <div class="form-group" id="durationGroup" style="display: none;">
                <label>Duree</label>
                <select id="sanctionDuration">
                    <option value="1">1 heure</option>
                    <option value="6">6 heures</option>
                    <option value="12">12 heures</option>
                    <option value="24">24 heures</option>
                    <option value="48">2 jours</option>
                    <option value="72">3 jours</option>
                    <option value="168">7 jours</option>
                    <option value="336">14 jours</option>
                    <option value="720">30 jours</option>
                    <option value="-1">Permanent</option>
                    <option value="custom">Personnalise...</option>
                </select>
            </div>
            <div class="form-group" id="customDurationGroup" style="display: none;">
                <label>Duree personnalisee</label>
                <div style="display: flex; gap: 10px; align-items: center;">
                    <input type="number" id="customDurationHours" min="0" max="8760" placeholder="Heures" style="width: 80px;" value="0">
                    <span>h</span>
                    <input type="number" id="customDurationMinutes" min="0" max="59" placeholder="Min" style="width: 80px;" value="0">
                    <span>min</span>
                </div>
                <small style="color: rgba(255,255,255,0.5); margin-top: 5px; display: block;">Ex: 1h30 = 1 heure et 30 minutes</small>
            </div>
            <div class="form-group">
                <label>Raison</label>
                <textarea id="sanctionReason" rows="3" placeholder="Raison de la sanction..."></textarea>
            </div>
        `;

        Modal.open({
            title: `Sanctionner ${playerName}`,
            body,
            footer: [
                { text: 'Annuler', class: 'btn-secondary', onClick: () => Modal.close() },
                { text: 'Appliquer', class: 'btn-danger', onClick: () => this.applySanction(playerId) }
            ]
        });

        // Show/hide duration based on type
        const typeSelect = document.getElementById('sanctionType');
        const durationGroup = document.getElementById('durationGroup');
        const durationSelect = document.getElementById('sanctionDuration');
        const customDurationGroup = document.getElementById('customDurationGroup');

        typeSelect.addEventListener('change', () => {
            durationGroup.style.display = typeSelect.value === 'ban' ? 'block' : 'none';
            if (typeSelect.value !== 'ban') {
                customDurationGroup.style.display = 'none';
            }
        });

        durationSelect.addEventListener('change', () => {
            customDurationGroup.style.display = durationSelect.value === 'custom' ? 'block' : 'none';
        });
    },

    /**
     * Appliquer une sanction
     */
    async applySanction(playerId) {
        const type = document.getElementById('sanctionType').value;
        const reason = document.getElementById('sanctionReason').value;
        let duration = document.getElementById('sanctionDuration')?.value;

        if (!reason.trim()) {
            Notifications.error('Erreur', 'Veuillez entrer une raison');
            return;
        }

        // Calculer la duree personnalisee si selectionnee
        if (duration === 'custom') {
            const hours = parseInt(document.getElementById('customDurationHours')?.value) || 0;
            const minutes = parseInt(document.getElementById('customDurationMinutes')?.value) || 0;
            duration = hours + (minutes / 60); // Convertir en heures decimales
            if (duration <= 0) {
                Notifications.error('Erreur', 'Veuillez entrer une duree valide');
                return;
            }
        } else {
            duration = parseInt(duration);
        }

        await API.sanctionAction(type, playerId, { reason, duration: duration });
        Modal.close();
    },

    /**
     * Spectate un joueur
     */
    async spectate(playerId) {
        await API.spectate(playerId);
    },

    /**
     * Aller vers un joueur
     */
    async goto(playerId) {
        await API.teleportAction('goto', playerId);
    },

    /**
     * Amener un joueur
     */
    async bring(playerId) {
        await API.teleportAction('bring', playerId);
        Modal.close();
    },

    /**
     * Retourner un joueur a sa position precedente
     */
    async returnPlayer(playerId) {
        await API.teleportAction('returnPlayer', playerId);
        Modal.close();
    }
};

// Export
window.PlayersModule = PlayersModule;
