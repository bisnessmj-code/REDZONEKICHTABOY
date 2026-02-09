/**
 * Modal Module - Panel Admin Fight League
 */

const Modal = {
    element: null,
    titleEl: null,
    bodyEl: null,
    footerEl: null,
    overlayEl: null,

    /**
     * Initialiser le module
     */
    init() {
        this.element = document.getElementById('modal');
        this.titleEl = document.getElementById('modalTitle');
        this.bodyEl = document.getElementById('modalBody');
        this.footerEl = document.getElementById('modalFooter');
        this.overlayEl = this.element.querySelector('.modal-overlay');

        // Close button
        document.getElementById('closeModal').addEventListener('click', () => this.close());

        // Overlay click
        this.overlayEl.addEventListener('click', () => this.close());

        // Escape key
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && !this.element.classList.contains('hidden')) {
                this.close();
            }
        });
    },

    /**
     * Ouvrir une modal
     */
    open(options = {}) {
        const { title, body, footer, size, onClose } = options;

        // Set title
        this.titleEl.textContent = title || 'Modal';

        // Set body
        if (typeof body === 'string') {
            this.bodyEl.innerHTML = body;
        } else if (body instanceof HTMLElement) {
            this.bodyEl.innerHTML = '';
            this.bodyEl.appendChild(body);
        }

        // Set footer
        if (footer) {
            this.footerEl.innerHTML = '';
            if (typeof footer === 'string') {
                this.footerEl.innerHTML = footer;
            } else if (Array.isArray(footer)) {
                footer.forEach(btn => {
                    const button = document.createElement('button');
                    button.className = `btn ${btn.class || 'btn-secondary'}`;
                    button.textContent = btn.text;
                    if (btn.onClick) {
                        button.addEventListener('click', btn.onClick);
                    }
                    this.footerEl.appendChild(button);
                });
            }
            this.footerEl.classList.remove('hidden');
        } else {
            this.footerEl.classList.add('hidden');
        }

        // Set size
        this.element.className = 'modal';
        if (size) {
            this.element.classList.add(`modal-${size}`);
        }

        // Store onClose callback
        this.onCloseCallback = onClose;

        // Show
        this.element.classList.remove('hidden');
    },

    /**
     * Fermer la modal
     */
    close() {
        this.element.classList.add('hidden');

        if (this.onCloseCallback) {
            this.onCloseCallback();
            this.onCloseCallback = null;
        }
    },

    /**
     * Modal de confirmation
     */
    confirm(options = {}) {
        return new Promise((resolve) => {
            const { title, message, confirmText, cancelText, danger } = options;

            const body = `
                <div class="confirm-modal">
                    <div class="confirm-icon ${danger ? 'danger' : ''}">
                        <i class="fas ${danger ? 'fa-exclamation-triangle' : 'fa-question'}"></i>
                    </div>
                    <p>${Helpers.escapeHtml(message)}</p>
                </div>
            `;

            this.open({
                title: title || 'Confirmation',
                body,
                size: 'sm',
                footer: [
                    {
                        text: cancelText || 'Annuler',
                        class: 'btn-secondary',
                        onClick: () => {
                            this.close();
                            resolve(false);
                        }
                    },
                    {
                        text: confirmText || 'Confirmer',
                        class: danger ? 'btn-danger' : 'btn-primary',
                        onClick: () => {
                            this.close();
                            resolve(true);
                        }
                    }
                ]
            });
        });
    },

    /**
     * Modal de prompt
     */
    prompt(options = {}) {
        return new Promise((resolve) => {
            const { title, message, placeholder, defaultValue, inputType } = options;

            const inputId = 'promptInput_' + Date.now();

            const body = `
                <div class="form-group">
                    <label>${Helpers.escapeHtml(message || 'Entrez une valeur')}</label>
                    <input type="${inputType || 'text'}" id="${inputId}"
                           placeholder="${Helpers.escapeHtml(placeholder || '')}"
                           value="${Helpers.escapeHtml(defaultValue || '')}">
                </div>
            `;

            this.open({
                title: title || 'Entrée',
                body,
                size: 'sm',
                footer: [
                    {
                        text: 'Annuler',
                        class: 'btn-secondary',
                        onClick: () => {
                            this.close();
                            resolve(null);
                        }
                    },
                    {
                        text: 'Valider',
                        class: 'btn-primary',
                        onClick: () => {
                            const input = document.getElementById(inputId);
                            this.close();
                            resolve(input.value);
                        }
                    }
                ]
            });

            // Focus input
            setTimeout(() => {
                const input = document.getElementById(inputId);
                if (input) input.focus();
            }, 100);
        });
    }
};

// Export
window.Modal = Modal;
