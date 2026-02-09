/**
 * Staff Roles Module - Panel Admin Fight League
 * Gestion des rôles du staff
 */

const StaffRolesModule = {
    staffMembers: [],
    connectedPlayers: [],
    currentUserGroup: null,
    currentUserLevel: 0,

    // Hiérarchie des grades (niveau plus élevé = plus de pouvoir)
    gradeLevels: {
        'user': 0,
        'staff': 1,
        'organisateur': 2,
        'responsable': 3,
        'admin': 4,
        'owner': 5
    },

    // Grades disponibles pour la modification
    availableGrades: ['user', 'staff', 'organisateur', 'responsable', 'admin', 'owner'],

    // Grades staff uniquement (pour la promotion)
    staffGrades: ['staff', 'organisateur', 'responsable', 'admin', 'owner'],

    /**
     * Initialize the module
     */
    init() {
        // Refresh button
        const refreshBtn = document.getElementById('refreshStaffRoles');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', () => this.load());
        }

        // Search filter
        const searchInput = document.getElementById('staffRolesSearch');
        if (searchInput) {
            searchInput.addEventListener('input', () => this.filterAndRender());
        }

        // Grade filter
        const gradeFilter = document.getElementById('staffRolesFilter');
        if (gradeFilter) {
            gradeFilter.addEventListener('change', () => this.filterAndRender());
        }

        // Status filter
        const statusFilter = document.getElementById('staffRolesStatus');
        if (statusFilter) {
            statusFilter.addEventListener('change', () => this.filterAndRender());
        }

        // Promote player form
        this.initPromoteForm();
    },

    /**
     * Initialize the promote player form
     */
    initPromoteForm() {
        const playerSelect = document.getElementById('promotePlayerSelect');
        const gradeSelect = document.getElementById('promoteGradeSelect');
        const promoteBtn = document.getElementById('promotePlayerBtn');

        if (playerSelect) {
            playerSelect.addEventListener('change', () => this.updatePromoteButton());
        }

        if (gradeSelect) {
            gradeSelect.addEventListener('change', () => this.updatePromoteButton());
        }

        if (promoteBtn) {
            promoteBtn.addEventListener('click', () => this.promotePlayer());
        }
    },

    /**
     * Update the promote button state
     */
    updatePromoteButton() {
        const playerSelect = document.getElementById('promotePlayerSelect');
        const gradeSelect = document.getElementById('promoteGradeSelect');
        const promoteBtn = document.getElementById('promotePlayerBtn');
        const promoteInfo = document.getElementById('promoteInfo');

        if (!playerSelect || !gradeSelect || !promoteBtn) return;

        const playerId = playerSelect.value;
        const grade = gradeSelect.value;

        // Enable button only if both are selected
        promoteBtn.disabled = !playerId || !grade;

        // Update info message
        if (promoteInfo) {
            if (playerId && grade) {
                const playerName = playerSelect.options[playerSelect.selectedIndex].text;
                promoteInfo.className = 'promote-info';
                promoteInfo.innerHTML = `
                    <i class="fas fa-check-circle"></i>
                    <span><strong>${this.escapeHtml(playerName)}</strong> sera promu au grade <strong>${this.capitalizeFirst(grade)}</strong></span>
                `;
            } else {
                promoteInfo.className = 'promote-info';
                promoteInfo.innerHTML = `
                    <i class="fas fa-info-circle"></i>
                    <span>Sélectionnez un joueur connecté et un grade pour le promouvoir au staff.</span>
                `;
            }
        }
    },

    /**
     * Load the promote grades based on current user level
     */
    loadPromoteGrades() {
        const gradeSelect = document.getElementById('promoteGradeSelect');
        if (!gradeSelect) return;

        // Get grades that current user can assign (staff grades only, lower than their level)
        const assignableGrades = this.staffGrades.filter(grade => {
            const gradeLevel = this.gradeLevels[grade] || 0;
            return gradeLevel < this.currentUserLevel;
        });

        let html = '<option value="">-- Sélectionner un grade --</option>';
        assignableGrades.forEach(grade => {
            html += `<option value="${grade}">${this.capitalizeFirst(grade)}</option>`;
        });

        gradeSelect.innerHTML = html;
    },

    /**
     * Load connected players (non-staff only)
     */
    async loadConnectedPlayers() {
        const playerSelect = document.getElementById('promotePlayerSelect');
        if (!playerSelect) return;

        try {
            const response = await API.getConnectedUsers();

            if (response && response.success) {
                this.connectedPlayers = response.players || [];

                let html = '<option value="">-- Sélectionner un joueur --</option>';
                this.connectedPlayers.forEach(player => {
                    html += `<option value="${this.escapeHtml(player.identifier)}">[${player.serverId}] ${this.escapeHtml(player.name)} (${player.group})</option>`;
                });

                playerSelect.innerHTML = html;
            } else {
                playerSelect.innerHTML = '<option value="">Erreur de chargement</option>';
            }
        } catch (error) {
            console.error('[STAFF ROLES] Error loading connected players:', error);
            playerSelect.innerHTML = '<option value="">Erreur de chargement</option>';
        }
    },

    /**
     * Promote a player to staff
     */
    async promotePlayer() {
        const playerSelect = document.getElementById('promotePlayerSelect');
        const gradeSelect = document.getElementById('promoteGradeSelect');
        const promoteBtn = document.getElementById('promotePlayerBtn');

        if (!playerSelect || !gradeSelect) return;

        const identifier = playerSelect.value;
        const newGrade = gradeSelect.value;
        const playerName = playerSelect.options[playerSelect.selectedIndex].text;

        if (!identifier || !newGrade) return;

        // Disable button
        if (promoteBtn) {
            promoteBtn.disabled = true;
            promoteBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Promotion...';
        }

        try {
            const confirmed = await Modal.confirm({
                title: 'Promouvoir un joueur',
                message: `Voulez-vous vraiment promouvoir <strong>${this.escapeHtml(playerName)}</strong> au grade <strong>${this.capitalizeFirst(newGrade)}</strong> ?`,
                confirmText: 'Promouvoir',
                cancelText: 'Annuler',
                danger: false
            });

            if (!confirmed) {
                if (promoteBtn) {
                    promoteBtn.innerHTML = '<i class="fas fa-arrow-up"></i> Promouvoir';
                    promoteBtn.disabled = false;
                }
                return;
            }

            const response = await API.updateStaffGrade(identifier, newGrade);

            if (response && response.success) {
                Notifications.success('Succes', `${playerName} a ete promu ${newGrade}`);

                // Reset form
                playerSelect.value = '';
                gradeSelect.value = '';
                this.updatePromoteButton();

                // Reload both lists
                this.loadConnectedPlayers();
                this.load();
            } else {
                Notifications.error('Erreur', response?.error || 'Impossible de promouvoir le joueur');
            }
        } catch (error) {
            console.error('[STAFF ROLES] Error promoting player:', error);
            Notifications.error('Erreur', 'Erreur lors de la promotion');
        } finally {
            if (promoteBtn) {
                promoteBtn.innerHTML = '<i class="fas fa-arrow-up"></i> Promouvoir';
            }
        }
    },

    /**
     * Set current user info
     */
    setCurrentUser(session) {
        if (session) {
            this.currentUserGroup = session.group ? session.group.toLowerCase() : 'user';
            this.currentUserLevel = this.gradeLevels[this.currentUserGroup] || 0;
        }
    },

    /**
     * Load staff members from server
     */
    async load() {
        const container = document.getElementById('staffRolesList');
        container.innerHTML = `
            <div class="loading-placeholder">
                <i class="fas fa-spinner fa-spin"></i>
                <span>Chargement...</span>
            </div>
        `;

        // Set current user info from session
        if (App.session) {
            this.setCurrentUser(App.session);
        }

        // Load promote grades based on current user level
        this.loadPromoteGrades();

        // Load connected players for promotion
        this.loadConnectedPlayers();

        try {
            const response = await API.getStaffMembers();

            if (response && response.success) {
                this.staffMembers = response.members || [];
                this.filterAndRender();
            } else {
                container.innerHTML = `
                    <div class="staff-roles-empty">
                        <i class="fas fa-exclamation-triangle"></i>
                        <p>Erreur lors du chargement</p>
                        <span>${response?.error || 'Erreur inconnue'}</span>
                    </div>
                `;
            }
        } catch (error) {
            console.error('[STAFF ROLES] Error loading:', error);
            container.innerHTML = `
                <div class="staff-roles-empty">
                    <i class="fas fa-exclamation-triangle"></i>
                    <p>Erreur de connexion</p>
                </div>
            `;
        }
    },

    /**
     * Filter and render staff members
     */
    filterAndRender() {
        const searchValue = document.getElementById('staffRolesSearch')?.value.toLowerCase() || '';
        const gradeValue = document.getElementById('staffRolesFilter')?.value || 'all';
        const statusValue = document.getElementById('staffRolesStatus')?.value || 'all';

        let filtered = this.staffMembers.filter(member => {
            // Search filter
            if (searchValue) {
                const nameMatch = member.name?.toLowerCase().includes(searchValue);
                const identifierMatch = member.identifier?.toLowerCase().includes(searchValue);
                if (!nameMatch && !identifierMatch) return false;
            }

            // Grade filter
            if (gradeValue !== 'all') {
                if (member.group?.toLowerCase() !== gradeValue) return false;
            }

            // Status filter
            if (statusValue !== 'all') {
                if (statusValue === 'online' && !member.isOnline) return false;
                if (statusValue === 'offline' && member.isOnline) return false;
            }

            return true;
        });

        // Sort by grade level (highest first), then by name
        filtered.sort((a, b) => {
            const levelA = this.gradeLevels[a.group?.toLowerCase()] || 0;
            const levelB = this.gradeLevels[b.group?.toLowerCase()] || 0;
            if (levelB !== levelA) return levelB - levelA;
            return (a.name || '').localeCompare(b.name || '');
        });

        this.render(filtered);
    },

    /**
     * Render staff members list
     */
    render(members) {
        const container = document.getElementById('staffRolesList');

        if (!members || members.length === 0) {
            container.innerHTML = `
                <div class="staff-roles-empty">
                    <i class="fas fa-users-slash"></i>
                    <p>Aucun membre du staff trouvé</p>
                    <span>Modifiez vos filtres pour voir plus de résultats</span>
                </div>
            `;
            return;
        }

        let html = '';
        members.forEach(member => {
            html += this.renderMember(member);
        });

        container.innerHTML = html;

        // Attach event listeners
        this.attachEventListeners();
    },

    /**
     * Render a single staff member
     */
    renderMember(member) {
        const group = member.group?.toLowerCase() || 'user';
        const memberLevel = this.gradeLevels[group] || 0;

        // Check if current user can edit this member
        // Can only edit members with lower level
        const canEdit = this.currentUserLevel > memberLevel;

        // Get available grades for this member (only grades lower than current user's level)
        const editableGrades = this.getEditableGrades();

        return `
            <div class="staff-role-item ${canEdit ? '' : 'cannot-edit'}" data-identifier="${this.escapeHtml(member.identifier)}">
                <div class="staff-role-avatar ${group}">
                    <i class="fas fa-user"></i>
                </div>
                <div class="staff-role-info">
                    <div class="staff-role-name">
                        ${this.escapeHtml(member.name || 'Inconnu')}
                        <span class="staff-role-status ${member.isOnline ? 'online' : 'offline'}">
                            <i class="fas fa-circle"></i>
                            ${member.isOnline ? 'En ligne' : 'Hors ligne'}
                        </span>
                    </div>
                    <div class="staff-role-identifier">${this.escapeHtml(member.identifier)}</div>
                </div>
                <div class="staff-role-grade">
                    <span class="staff-role-grade-label">Grade actuel</span>
                    <span class="staff-role-badge ${group}">${group}</span>
                </div>
                ${canEdit ? `
                    <div class="staff-role-actions">
                        <select class="grade-select" data-identifier="${this.escapeHtml(member.identifier)}" data-current="${group}">
                            ${editableGrades.map(g => `
                                <option value="${g}" ${g === group ? 'selected' : ''}>${this.capitalizeFirst(g)}</option>
                            `).join('')}
                        </select>
                        <button class="btn-save" data-identifier="${this.escapeHtml(member.identifier)}" disabled>
                            <i class="fas fa-save"></i> Sauvegarder
                        </button>
                    </div>
                ` : ''}
            </div>
        `;
    },

    /**
     * Get grades that current user can assign
     */
    getEditableGrades() {
        // User can only assign grades lower than their own level
        return this.availableGrades.filter(grade => {
            const gradeLevel = this.gradeLevels[grade] || 0;
            return gradeLevel < this.currentUserLevel;
        });
    },

    /**
     * Attach event listeners to rendered elements
     */
    attachEventListeners() {
        // Grade select change
        document.querySelectorAll('.staff-role-actions .grade-select').forEach(select => {
            select.addEventListener('change', (e) => {
                const identifier = e.target.dataset.identifier;
                const currentGrade = e.target.dataset.current;
                const newGrade = e.target.value;

                // Enable/disable save button
                const saveBtn = document.querySelector(`.btn-save[data-identifier="${identifier}"]`);
                if (saveBtn) {
                    saveBtn.disabled = (newGrade === currentGrade);
                }
            });
        });

        // Save button click
        document.querySelectorAll('.staff-role-actions .btn-save').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const identifier = e.target.closest('.btn-save').dataset.identifier;
                const select = document.querySelector(`.grade-select[data-identifier="${identifier}"]`);
                if (select) {
                    this.updateGrade(identifier, select.value);
                }
            });
        });
    },

    /**
     * Update a member's grade
     */
    async updateGrade(identifier, newGrade) {
        const saveBtn = document.querySelector(`.btn-save[data-identifier="${identifier}"]`);
        const select = document.querySelector(`.grade-select[data-identifier="${identifier}"]`);

        if (saveBtn) {
            saveBtn.disabled = true;
            saveBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Sauvegarde...';
        }

        try {
            const confirmed = await Modal.confirm({
                title: 'Modifier le grade',
                message: `Voulez-vous vraiment modifier le grade de ce membre en "${this.capitalizeFirst(newGrade)}" ?`,
                confirmText: 'Confirmer',
                cancelText: 'Annuler',
                danger: newGrade === 'user'
            });

            if (!confirmed) {
                if (saveBtn) {
                    saveBtn.innerHTML = '<i class="fas fa-save"></i> Sauvegarder';
                    saveBtn.disabled = false;
                }
                // Reset select to current value
                if (select) {
                    select.value = select.dataset.current;
                }
                return;
            }

            const response = await API.updateStaffGrade(identifier, newGrade);

            if (response && response.success) {
                Notifications.success('Succes', 'Grade modifie avec succes');
                // Reload the list
                this.load();
            } else {
                Notifications.error('Erreur', response?.error || 'Impossible de modifier le grade');
                if (saveBtn) {
                    saveBtn.innerHTML = '<i class="fas fa-save"></i> Sauvegarder';
                    saveBtn.disabled = false;
                }
                // Reset select
                if (select) {
                    select.value = select.dataset.current;
                }
            }
        } catch (error) {
            console.error('[STAFF ROLES] Error updating grade:', error);
            Notifications.error('Erreur', 'Erreur lors de la modification');
            if (saveBtn) {
                saveBtn.innerHTML = '<i class="fas fa-save"></i> Sauvegarder';
                saveBtn.disabled = false;
            }
        }
    },

    /**
     * Capitalize first letter
     */
    capitalizeFirst(str) {
        if (!str) return '';
        return str.charAt(0).toUpperCase() + str.slice(1);
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
window.StaffRolesModule = StaffRolesModule;
