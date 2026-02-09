/**
 * Economy Module - Panel Admin Fight League
 * Affichage des comptes des joueurs en ligne (Owner/Admin uniquement)
 */

const EconomyModule = {
    accounts: [],
    searchTimeout: null,
    selectedPlayer: null,

    /**
     * Initialiser le module
     */
    init() {
        const searchInput = document.getElementById('economySearch');
        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                clearTimeout(this.searchTimeout);
                this.searchTimeout = setTimeout(() => {
                    this.filterAccounts(e.target.value);
                }, 300);
            });
        }
    },

    /**
     * Charger la liste des comptes
     */
    async load() {
        const result = await API.getAccounts();

        if (result.success) {
            this.accounts = result.accounts;
            this.render();
        } else if (result.error === 'NO_PERMISSION') {
            this.renderNoPermission();
        }
    },

    /**
     * Filtrer les comptes par ID, nom ou license
     */
    filterAccounts(query) {
        if (!query) {
            this.render();
            return;
        }

        query = query.toLowerCase();
        const filtered = this.accounts.filter(a =>
            a.id.toString().includes(query) ||
            a.name.toLowerCase().includes(query) ||
            (a.fivemName && a.fivemName.toLowerCase().includes(query)) ||
            a.license.toLowerCase().includes(query)
        );

        this.render(filtered);
    },

    /**
     * Rendre la table des comptes
     */
    render(accounts = this.accounts) {
        const tbody = document.querySelector('#economyTable tbody');
        if (!tbody) return;

        if (accounts.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="5">
                        <div class="table-empty">
                            <i class="fas fa-wallet"></i>
                            <p>Aucun joueur en ligne</p>
                        </div>
                    </td>
                </tr>
            `;
            return;
        }

        tbody.innerHTML = accounts.map(account => {
            const fivemName = account.fivemName || account.name;
            const displayName = account.fivemName ? Helpers.escapeHtml(account.fivemName) : Helpers.escapeHtml(account.name);
            const charName = account.fivemName && account.name !== account.fivemName ? `<span class="player-char-name">(${Helpers.escapeHtml(account.name)})</span>` : '';

            return `
            <tr data-id="${account.id}">
                <td>
                    <span class="badge badge-info">${account.id}</span>
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
                    <span class="license-text">${Helpers.escapeHtml(account.license)}</span>
                </td>
                <td>
                    <span class="money-amount">$${Helpers.formatNumber(account.bank)}</span>
                </td>
                <td>
                    <div class="table-actions">
                        <button class="btn btn-sm btn-success" onclick="EconomyModule.showMoneyModal(${account.id}, '${Helpers.escapeHtml(fivemName)}', 'add')" title="Ajouter argent">
                            <i class="fas fa-plus"></i>
                        </button>
                        <button class="btn btn-sm btn-danger" onclick="EconomyModule.showMoneyModal(${account.id}, '${Helpers.escapeHtml(fivemName)}', 'remove')" title="Retirer argent">
                            <i class="fas fa-minus"></i>
                        </button>
                        <button class="btn btn-sm btn-primary" onclick="EconomyModule.showMoneyModal(${account.id}, '${Helpers.escapeHtml(fivemName)}', 'set')" title="Definir montant">
                            <i class="fas fa-edit"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `}).join('');
    },

    /**
     * Afficher message pas de permission
     */
    renderNoPermission() {
        const tbody = document.querySelector('#economyTable tbody');
        if (!tbody) return;

        tbody.innerHTML = `
            <tr>
                <td colspan="5">
                    <div class="table-empty">
                        <i class="fas fa-lock"></i>
                        <p>Vous n'avez pas la permission de voir les comptes</p>
                    </div>
                </td>
            </tr>
        `;
    },

    /**
     * Afficher le modal pour gerer l'argent
     */
    showMoneyModal(playerId, playerName, action) {
        this.selectedPlayer = { id: playerId, name: playerName };

        const titles = {
            'add': 'Ajouter de l\'argent',
            'remove': 'Retirer de l\'argent',
            'set': 'Definir le montant'
        };

        const buttonLabels = {
            'add': 'Ajouter',
            'remove': 'Retirer',
            'set': 'Definir'
        };

        const buttonClasses = {
            'add': 'btn-success',
            'remove': 'btn-danger',
            'set': 'btn-primary'
        };

        const body = `
            <div class="form-group">
                <label>Joueur</label>
                <input type="text" value="${Helpers.escapeHtml(playerName)} (ID: ${playerId})" disabled>
            </div>
            <div class="form-group">
                <label>Montant ($)</label>
                <input type="number" id="economyAmount" min="1" placeholder="Entrez le montant..." autofocus>
            </div>
            <div class="form-group">
                <label>Raison</label>
                <textarea id="economyReason" rows="2" placeholder="Raison de la modification..."></textarea>
            </div>
        `;

        Modal.open({
            title: `${titles[action]} - ${playerName}`,
            body,
            footer: [
                { text: 'Annuler', class: 'btn-secondary', onClick: () => Modal.close() },
                { text: buttonLabels[action], class: buttonClasses[action], onClick: () => this.applyMoneyAction(action) }
            ]
        });

        // Focus sur le champ montant
        setTimeout(() => {
            const amountInput = document.getElementById('economyAmount');
            if (amountInput) amountInput.focus();
        }, 100);
    },

    /**
     * Appliquer l'action sur l'argent
     */
    async applyMoneyAction(action) {
        const amount = parseInt(document.getElementById('economyAmount').value);
        const reason = document.getElementById('economyReason').value.trim();

        if (!amount || amount <= 0) {
            Notifications.error('Erreur', 'Veuillez entrer un montant valide');
            return;
        }

        if (!reason) {
            Notifications.error('Erreur', 'Veuillez entrer une raison');
            return;
        }

        await API.economyAction(action, this.selectedPlayer.id, {
            amount: amount,
            type: 'bank',
            reason: reason
        });

        Modal.close();

        // Rafraichir la liste apres un court delai
        setTimeout(() => {
            this.load();
        }, 500);
    }
};

// Export
window.EconomyModule = EconomyModule;
