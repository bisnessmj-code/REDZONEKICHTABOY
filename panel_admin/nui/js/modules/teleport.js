/**
 * Teleport Module - Panel Admin Fight League
 */

const TeleportModule = {
    savedLocations: [],
    currentCoords: { x: 0, y: 0, z: 0, h: 0 },

    /**
     * Initialiser le module
     */
    init() {
        // TP to coords button
        document.getElementById('tpToCoords').addEventListener('click', () => {
            this.teleportToCoords();
        });

        // TP to marker button
        document.getElementById('tpToMarker').addEventListener('click', () => {
            this.teleportToMarker();
        });

        // Return button
        const returnBtn = document.getElementById('tpReturn');
        if (returnBtn) {
            returnBtn.addEventListener('click', () => {
                this.returnToPrevious();
            });
        }

        // Get coords button
        const getCoordsBtn = document.getElementById('getCoords');
        if (getCoordsBtn) {
            getCoordsBtn.addEventListener('click', () => {
                this.getCurrentCoords();
            });
        }

        // Copy coords button
        const copyCoordsBtn = document.getElementById('copyCoords');
        if (copyCoordsBtn) {
            copyCoordsBtn.addEventListener('click', () => {
                this.copyCoords();
            });
        }

        // Parse quick coords button
        const parseQuickCoordsBtn = document.getElementById('parseQuickCoords');
        if (parseQuickCoordsBtn) {
            parseQuickCoordsBtn.addEventListener('click', () => {
                this.parseQuickCoords();
            });
        }

        // Quick coords input - parse on Enter key
        const quickCoordsInput = document.getElementById('tpQuickCoords');
        if (quickCoordsInput) {
            quickCoordsInput.addEventListener('keypress', (e) => {
                if (e.key === 'Enter') {
                    this.parseQuickCoords();
                }
            });
        }
    },

    /**
     * Charger les emplacements sauvegardés depuis le serveur
     */
    async load() {
        // Charger les emplacements depuis le serveur (config.lua)
        const result = await API.fetch('getTeleportLocations');
        if (result.success && result.locations) {
            this.savedLocations = result.locations;
        } else {
            // Fallback si le serveur ne repond pas
            this.savedLocations = [];
        }
        this.render();
    },

    /**
     * Rendre la liste des emplacements
     */
    render() {
        const list = document.getElementById('savedLocations');

        list.innerHTML = this.savedLocations.map((loc, index) => `
            <li class="location-item" onclick="TeleportModule.teleportToLocation(${index})">
                <div class="location-info">
                    <i class="fas fa-map-marker-alt location-icon"></i>
                    <div>
                        <span class="location-name">${Helpers.escapeHtml(loc.name)}</span>
                        <span class="location-category">${loc.category}</span>
                    </div>
                </div>
                <i class="fas fa-chevron-right" style="color: var(--text-muted);"></i>
            </li>
        `).join('');
    },

    /**
     * Parser les coordonnées rapides et les appliquer aux champs X, Y, Z
     */
    parseQuickCoords() {
        const quickInput = document.getElementById('tpQuickCoords').value.trim();

        if (!quickInput) {
            Notifications.error('Erreur', 'Aucune coordonnée à parser');
            return null;
        }

        // Supporter plusieurs formats:
        // "X, Y, Z" ou "X Y Z" ou "X,Y,Z" ou "vector3(X, Y, Z)" ou "vector4(X, Y, Z, H)"
        let coords = null;

        // Format vector3/vector4
        const vectorMatch = quickInput.match(/vector[34]\s*\(\s*([-\d.]+)\s*,\s*([-\d.]+)\s*,\s*([-\d.]+)/i);
        if (vectorMatch) {
            coords = {
                x: parseFloat(vectorMatch[1]),
                y: parseFloat(vectorMatch[2]),
                z: parseFloat(vectorMatch[3])
            };
        } else {
            // Format standard: séparé par virgules, espaces ou les deux
            const parts = quickInput.split(/[\s,]+/).filter(p => p !== '');
            if (parts.length >= 3) {
                coords = {
                    x: parseFloat(parts[0]),
                    y: parseFloat(parts[1]),
                    z: parseFloat(parts[2])
                };
            }
        }

        if (!coords || isNaN(coords.x) || isNaN(coords.y) || isNaN(coords.z)) {
            Notifications.error('Erreur', 'Format invalide. Utilisez: X, Y, Z');
            return null;
        }

        // Appliquer aux champs
        document.getElementById('tpX').value = coords.x;
        document.getElementById('tpY').value = coords.y;
        document.getElementById('tpZ').value = coords.z;

        Notifications.success('Position', 'Coordonnées appliquées');
        return coords;
    },

    /**
     * Téléporter aux coordonnées entrées
     */
    async teleportToCoords() {
        let x = parseFloat(document.getElementById('tpX').value);
        let y = parseFloat(document.getElementById('tpY').value);
        let z = parseFloat(document.getElementById('tpZ').value);

        // Si les champs sont vides, essayer de parser le champ rapide
        if (isNaN(x) || isNaN(y) || isNaN(z)) {
            const quickInput = document.getElementById('tpQuickCoords').value.trim();
            if (quickInput) {
                const coords = this.parseQuickCoords();
                if (coords) {
                    x = coords.x;
                    y = coords.y;
                    z = coords.z;
                } else {
                    return;
                }
            } else {
                Notifications.error('Erreur', 'Coordonnées invalides');
                return;
            }
        }

        await API.teleportAction('self', null, { x, y, z });
    },

    /**
     * Téléporter au marqueur carte
     */
    async teleportToMarker() {
        const result = await API.teleportToMarker();
        if (!result.success) {
            Notifications.error('Erreur', result.error || 'Aucun marqueur placé');
        }
    },

    /**
     * Téléporter à un emplacement sauvegardé
     */
    async teleportToLocation(index) {
        const loc = this.savedLocations[index];
        if (!loc) return;

        await API.teleportAction('self', null, { x: loc.x, y: loc.y, z: loc.z });
    },

    /**
     * Retourner a la position precedente
     */
    async returnToPrevious() {
        await API.teleportAction('return', null, {});
    },

    /**
     * Obtenir les coordonnees actuelles
     */
    async getCurrentCoords() {
        const result = await API.fetch('getPlayerCoords');

        if (result.success) {
            this.currentCoords = {
                x: result.x,
                y: result.y,
                z: result.z,
                h: result.h
            };

            // Mettre a jour l'affichage
            document.getElementById('currentX').textContent = result.x.toFixed(2);
            document.getElementById('currentY').textContent = result.y.toFixed(2);
            document.getElementById('currentZ').textContent = result.z.toFixed(2);
            document.getElementById('currentH').textContent = result.h.toFixed(2);

            // Mettre a jour le preview
            const vec4String = `vector4(${result.x.toFixed(2)}, ${result.y.toFixed(2)}, ${result.z.toFixed(2)}, ${result.h.toFixed(2)})`;
            document.getElementById('coordsPreview').textContent = vec4String;

            Notifications.success('Position', 'Coordonnees obtenues');
        } else {
            Notifications.error('Erreur', 'Impossible d\'obtenir les coordonnees');
        }
    },

    /**
     * Copier les coordonnees dans le presse-papier
     */
    copyCoords() {
        const vec4String = `vector4(${this.currentCoords.x.toFixed(2)}, ${this.currentCoords.y.toFixed(2)}, ${this.currentCoords.z.toFixed(2)}, ${this.currentCoords.h.toFixed(2)})`;

        navigator.clipboard.writeText(vec4String).then(() => {
            Notifications.success('Copie', 'Coordonnees copiees dans le presse-papier');

            // Animation feedback
            const btn = document.getElementById('copyCoords');
            btn.classList.add('copied');
            setTimeout(() => btn.classList.remove('copied'), 1000);
        }).catch(() => {
            // Fallback pour les navigateurs qui ne supportent pas clipboard API
            const textarea = document.createElement('textarea');
            textarea.value = vec4String;
            document.body.appendChild(textarea);
            textarea.select();
            document.execCommand('copy');
            document.body.removeChild(textarea);
            Notifications.success('Copie', 'Coordonnees copiees dans le presse-papier');
        });
    }
};

// Export
window.TeleportModule = TeleportModule;
