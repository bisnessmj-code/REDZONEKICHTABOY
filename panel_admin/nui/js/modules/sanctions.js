/**
 * Sanctions Module - Panel Admin Fight League
 */

const SanctionsModule = {
    sanctions: [],
    currentPage: 1,
    perPage: 20,
    currentFilters: {},

    /**
     * Initialiser le module
     */
    init() {
        // Filter by type
        const typeFilter = document.getElementById('sanctionTypeFilter');
        if (typeFilter) {
            typeFilter.addEventListener('change', () => {
                this.currentFilters.type = typeFilter.value || '';
                this.currentPage = 1;
                this.load();
            });
        }

        // Filter by status
        const statusFilter = document.getElementById('sanctionStatusFilter');
        if (statusFilter) {
            statusFilter.addEventListener('change', () => {
                this.currentFilters.status = statusFilter.value || '';
                this.currentPage = 1;
                this.load();
            });
        }

        // Search field (debounced)
        const searchField = document.getElementById('sanctionSearch');
        if (searchField) {
            let searchTimeout;
            searchField.addEventListener('input', (e) => {
                clearTimeout(searchTimeout);
                searchTimeout = setTimeout(() => {
                    this.currentFilters.search = e.target.value.trim();
                    this.currentPage = 1;
                    this.load();
                }, 500); // Attendre 500ms après la dernière frappe
            });
        }

        // Clear search button
        const clearSearch = document.getElementById('clearSanctionSearch');
        if (clearSearch) {
            clearSearch.addEventListener('click', () => {
                if (searchField) searchField.value = '';
                this.currentFilters.search = '';
                this.currentPage = 1;
                this.load();
            });
        }

        // Ban by identifier form
        this.initBanByIdForm();

        // Initial load
        this.load();
    },

    /**
     * Initialiser le formulaire de ban par identifier
     */
    initBanByIdForm() {
        const durationSelect = document.getElementById('banByIdDuration');
        const customDurationGroup = document.getElementById('banByIdCustomDuration');
        const banBtn = document.getElementById('banByIdBtn');

        // Show/hide custom duration
        if (durationSelect && customDurationGroup) {
            durationSelect.addEventListener('change', () => {
                customDurationGroup.style.display = durationSelect.value === 'custom' ? 'block' : 'none';
            });
        }

        // Ban button
        if (banBtn) {
            banBtn.addEventListener('click', () => this.banByIdentifier());
        }
    },

    /**
     * Bannir par identifier
     */
    async banByIdentifier() {
        const identifier = document.getElementById('banByIdIdentifier')?.value?.trim();
        const reason = document.getElementById('banByIdReason')?.value?.trim();
        let duration = document.getElementById('banByIdDuration')?.value;

        // Validations
        if (!identifier) {
            Notifications.error('Erreur', 'Veuillez entrer un identifier');
            return;
        }

        if (!reason) {
            Notifications.error('Erreur', 'Veuillez entrer une raison');
            return;
        }

        // Calculer la duree
        if (duration === 'custom') {
            duration = parseInt(document.getElementById('banByIdCustomHours')?.value) || 1;
        } else {
            duration = parseInt(duration);
        }

        // Confirmation
        const isPermanent = duration === -1;
        const durationText = isPermanent ? 'permanent' : `${duration} heure${duration > 1 ? 's' : ''}`;

        const confirmed = await Modal.confirm({
            title: 'Confirmer le bannissement',
            message: `Voulez-vous vraiment bannir <strong>${Helpers.escapeHtml(identifier)}</strong> ?<br><br>
                      <strong>Duree:</strong> ${durationText}<br>
                      <strong>Raison:</strong> ${Helpers.escapeHtml(reason)}`,
            confirmText: 'Bannir',
            cancelText: 'Annuler',
            danger: true
        });

        if (!confirmed) return;

        // Envoyer la requete
        const result = await API.banByIdentifier(identifier, reason, duration);

        if (result && result.success) {
            const unbanIdMsg = result.unbanId ? ` (ID de deban: ${result.unbanId})` : '';
            Notifications.success('Succes', 'Joueur banni avec succes' + unbanIdMsg);
            // Reset form
            document.getElementById('banByIdIdentifier').value = '';
            document.getElementById('banByIdReason').value = '';
            document.getElementById('banByIdDuration').value = '1';
            document.getElementById('banByIdCustomDuration').style.display = 'none';
            // Reload sanctions
            this.load();
        } else {
            Notifications.error('Erreur', result?.error || 'Impossible de bannir le joueur');
        }
    },

    /**
     * Charger les sanctions
     */
    async load() {
        const result = await API.getSanctions(this.currentFilters, this.currentPage, this.perPage);

        if (result.success) {
            this.sanctions = result.sanctions || [];
            this.render();
            this.renderPagination(result.total || 0);
        } else {
            console.error('Erreur chargement sanctions:', result.error);
            Notifications.show('error', 'Erreur', 'Impossible de charger les sanctions');
        }
    },

    /**
     * Rendre la table des sanctions
     */
    render() {
        const tbody = document.querySelector('#sanctionsTable tbody');

        if (!tbody) return;

        if (this.sanctions.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="6">
                        <div class="table-empty">
                            <i class="fas fa-gavel"></i>
                            <p>Aucune sanction trouvée</p>
                        </div>
                    </td>
                </tr>
            `;
            return;
        }

        tbody.innerHTML = this.sanctions.map(sanction => {
            // Type de sanction
            const typeLabel = this.getTypeLabel(sanction.type);
            const typeBadgeClass = this.getTypeBadgeClass(sanction.type);

            // Statut
            const statusLabel = sanction.status || 'active';
            const statusBadgeClass = this.getStatusBadgeClass(statusLabel);

            // Durée si applicable
            let durationText = '';
            if (sanction.duration_hours && sanction.duration_hours > 0) {
                durationText = ` (${sanction.duration_hours}h)`;
            }

            // ID de deban (pour les bans uniquement)
            const isBan = sanction.type === 'ban_temp' || sanction.type === 'ban_perm';
            const unbanId = sanction.unban_id || null;

            return `
                <tr>
                    <td>
                        <span class="badge ${typeBadgeClass}">
                            ${typeLabel}${durationText}
                        </span>
                        ${isBan && unbanId ? `<div style="margin-top: 4px;"><span class="badge badge-info" style="font-size: 10px;"><i class="fas fa-key"></i> ${Helpers.escapeHtml(unbanId)}</span></div>` : ''}
                    </td>
                    <td class="sanction-player-cell">
                        <div class="sanction-player-name">${Helpers.escapeHtml(sanction.target_name || 'Inconnu')}</div>
                        <div class="sanction-player-identifier">${Helpers.escapeHtml(sanction.target_identifier || '')}</div>
                        ${sanction.target_discord ? `<div class="sanction-player-discord"><i class="fab fa-discord" style="color: #5865F2;"></i> ${Helpers.escapeHtml(sanction.target_discord.replace('discord:', ''))}</div>` : ''}
                    </td>
                    <td>${Helpers.truncate(sanction.reason || '-', 60)}</td>
                    <td>${Helpers.escapeHtml(sanction.staff_name || 'System')}</td>
                    <td>${Helpers.formatDate(sanction.created_at)}</td>
                    <td>
                        <span class="badge ${statusBadgeClass}">
                            ${this.getStatusLabel(statusLabel)}
                        </span>
                    </td>
                </tr>
            `;
        }).join('');
    },

    /**
     * Rendre la pagination
     */
    renderPagination(total) {
        const paginationContainer = document.getElementById('sanctionsPagination');
        if (!paginationContainer) return;

        const totalPages = Math.ceil(total / this.perPage);

        if (totalPages <= 1) {
            paginationContainer.innerHTML = '';
            return;
        }

        let html = '<div class="pagination">';

        // Bouton précédent
        if (this.currentPage > 1) {
            html += `<button class="btn-page" onclick="SanctionsModule.changePage(${this.currentPage - 1})">‹ Précédent</button>`;
        }

        // Info page
        html += `<span class="page-info">Page ${this.currentPage} / ${totalPages}</span>`;

        // Bouton suivant
        if (this.currentPage < totalPages) {
            html += `<button class="btn-page" onclick="SanctionsModule.changePage(${this.currentPage + 1})">Suivant ›</button>`;
        }

        html += '</div>';
        paginationContainer.innerHTML = html;
    },

    /**
     * Changer de page
     */
    changePage(page) {
        this.currentPage = page;
        this.load();
    },

    /**
     * Obtenir le label du type
     */
    getTypeLabel(type) {
        const labels = {
            'warn': 'Avertissement',
            'kick': 'Expulsion',
            'ban_temp': 'Ban Temporaire',
            'ban_perm': 'Ban Permanent'
        };
        return labels[type] || type;
    },

    /**
     * Obtenir la classe CSS du type
     */
    getTypeBadgeClass(type) {
        const classes = {
            'warn': 'badge-warning',
            'kick': 'badge-orange',
            'ban_temp': 'badge-danger',
            'ban_perm': 'badge-dark'
        };
        return classes[type] || 'badge-secondary';
    },

    /**
     * Obtenir le label du statut
     */
    getStatusLabel(status) {
        const labels = {
            'active': 'Actif',
            'expired': 'Expiré',
            'revoked': 'Révoqué'
        };
        return labels[status] || status;
    },

    /**
     * Obtenir la classe CSS du statut
     */
    getStatusBadgeClass(status) {
        const classes = {
            'active': 'badge-danger',
            'expired': 'badge-secondary',
            'revoked': 'badge-info'
        };
        return classes[status] || 'badge-secondary';
    }
};

// Export
window.SanctionsModule = SanctionsModule;
