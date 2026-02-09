/**
 * Vehicles Module - Panel Admin Fight League
 * Carousel de véhicules avec options de personnalisation
 */

const VehiclesModule = {
    currentCategoryIndex: 0,
    selectedColor: 0,
    useCustomColor: false,
    customColor: { r: 118, g: 47, b: 255 },
    currentHue: 270,
    tuning: {
        engine: 3,
        transmission: 2,
        brakes: 2,
        suspension: 3,
        armor: 4,
        turbo: true,
        neon: true,
        xenon: true,
        fullUpgrade: true
    },

    // Catégories de véhicules
    categories: [
        {
            name: 'Sports',
            icon: 'fa-flag-checkered',
            vehicles: [
                { model: 'adder', name: 'Adder', icon: 'fa-car-side' },
                { model: 't20', name: 'T20', icon: 'fa-car-side' },
                { model: 'zentorno', name: 'Zentorno', icon: 'fa-car-side' },
                { model: 'osiris', name: 'Osiris', icon: 'fa-car-side' },
                { model: 'entityxf', name: 'Entity XF', icon: 'fa-car-side' },
                { model: 'turismor', name: 'Turismo R', icon: 'fa-car-side' },
                { model: 'reaper', name: 'Reaper', icon: 'fa-car-side' },
                { model: 'banshee2', name: 'Banshee 900R', icon: 'fa-car-side' }
            ]
        },
        {
            name: 'Muscle',
            icon: 'fa-fire',
            vehicles: [
                { model: 'dominator', name: 'Dominator', icon: 'fa-car' },
                { model: 'gauntlet', name: 'Gauntlet', icon: 'fa-car' },
                { model: 'vigero', name: 'Vigero', icon: 'fa-car' },
                { model: 'sabregt', name: 'Sabre GT', icon: 'fa-car' },
                { model: 'buffalo', name: 'Buffalo', icon: 'fa-car' },
                { model: 'phoenix', name: 'Phoenix', icon: 'fa-car' },
                { model: 'ruiner', name: 'Ruiner', icon: 'fa-car' },
                { model: 'dukes', name: 'Dukes', icon: 'fa-car' }
            ]
        },
        {
            name: 'SUV',
            icon: 'fa-truck',
            vehicles: [
                { model: 'baller', name: 'Baller', icon: 'fa-truck-monster' },
                { model: 'cavalcade', name: 'Cavalcade', icon: 'fa-truck-monster' },
                { model: 'granger', name: 'Granger', icon: 'fa-truck-monster' },
                { model: 'dubsta', name: 'Dubsta', icon: 'fa-truck-monster' },
                { model: 'huntley', name: 'Huntley', icon: 'fa-truck-monster' },
                { model: 'landstalker', name: 'Landstalker', icon: 'fa-truck-monster' },
                { model: 'contender', name: 'Contender', icon: 'fa-truck-monster' },
                { model: 'xls', name: 'XLS', icon: 'fa-truck-monster' }
            ]
        },
        {
            name: 'Motos',
            icon: 'fa-motorcycle',
            vehicles: [
                { model: 'bati', name: 'Bati 801', icon: 'fa-motorcycle' },
                { model: 'akuma', name: 'Akuma', icon: 'fa-motorcycle' },
                { model: 'hakuchou', name: 'Hakuchou', icon: 'fa-motorcycle' },
                { model: 'double', name: 'Double T', icon: 'fa-motorcycle' },
                { model: 'nemesis', name: 'Nemesis', icon: 'fa-motorcycle' },
                { model: 'pcj', name: 'PCJ 600', icon: 'fa-motorcycle' },
                { model: 'ruffian', name: 'Ruffian', icon: 'fa-motorcycle' },
                { model: 'sanchez', name: 'Sanchez', icon: 'fa-motorcycle' }
            ]
        },
        {
            name: 'Hélicoptères',
            icon: 'fa-helicopter',
            vehicles: [
                { model: 'buzzard', name: 'Buzzard', icon: 'fa-helicopter' },
                { model: 'frogger', name: 'Frogger', icon: 'fa-helicopter' },
                { model: 'maverick', name: 'Maverick', icon: 'fa-helicopter' },
                { model: 'swift', name: 'Swift', icon: 'fa-helicopter' },
                { model: 'savage', name: 'Savage', icon: 'fa-helicopter' },
                { model: 'valkyrie', name: 'Valkyrie', icon: 'fa-helicopter' },
                { model: 'cargobob', name: 'Cargobob', icon: 'fa-helicopter' },
                { model: 'volatus', name: 'Volatus', icon: 'fa-helicopter' }
            ]
        },
        {
            name: 'Bateaux',
            icon: 'fa-ship',
            vehicles: [
                { model: 'speeder', name: 'Speeder', icon: 'fa-ship' },
                { model: 'jetmax', name: 'Jetmax', icon: 'fa-ship' },
                { model: 'squalo', name: 'Squalo', icon: 'fa-ship' },
                { model: 'tropic', name: 'Tropic', icon: 'fa-ship' },
                { model: 'dinghy', name: 'Dinghy', icon: 'fa-ship' },
                { model: 'toro', name: 'Toro', icon: 'fa-ship' },
                { model: 'seashark', name: 'Seashark', icon: 'fa-ship' },
                { model: 'marquis', name: 'Marquis', icon: 'fa-ship' }
            ]
        },
        {
            name: 'Utilitaires',
            icon: 'fa-truck-pickup',
            vehicles: [
                { model: 'flatbed', name: 'Flatbed', icon: 'fa-truck' },
                { model: 'mule', name: 'Mule', icon: 'fa-truck' },
                { model: 'benson', name: 'Benson', icon: 'fa-truck' },
                { model: 'hauler', name: 'Hauler', icon: 'fa-truck' },
                { model: 'phantom', name: 'Phantom', icon: 'fa-truck' },
                { model: 'tow', name: 'Tow Truck', icon: 'fa-truck' },
                { model: 'trash', name: 'Trash Truck', icon: 'fa-truck' },
                { model: 'ambulance', name: 'Ambulance', icon: 'fa-ambulance' }
            ]
        }
    ],

    /**
     * Initialiser le module
     */
    init() {
        // Spawn vehicle button
        document.getElementById('spawnVehicle').addEventListener('click', () => {
            this.spawnVehicle();
        });

        // Delete vehicle button
        document.getElementById('deleteVehicle').addEventListener('click', () => {
            this.deleteVehicle();
        });

        // Repair vehicle button
        document.getElementById('repairVehicle').addEventListener('click', () => {
            this.repairVehicle();
        });

        // Enter key on input
        document.getElementById('vehicleModel').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                this.spawnVehicle();
            }
        });

        // Carousel navigation
        document.getElementById('carouselPrev').addEventListener('click', () => {
            this.previousCategory();
        });

        document.getElementById('carouselNext').addEventListener('click', () => {
            this.nextCategory();
        });

        // Color palette
        document.querySelectorAll('#vehicleColorPalette .color-swatch').forEach(swatch => {
            swatch.addEventListener('click', () => {
                document.querySelectorAll('#vehicleColorPalette .color-swatch').forEach(s => s.classList.remove('selected'));
                swatch.classList.add('selected');
                this.selectedColor = parseInt(swatch.dataset.color);
            });
        });

        // Tuning selects
        const tuningSelects = {
            'vehicleEngine': 'engine',
            'vehicleTransmission': 'transmission',
            'vehicleBrakes': 'brakes',
            'vehicleSuspension': 'suspension',
            'vehicleArmor': 'armor',
            'vehicleTurbo': 'turbo'
        };

        Object.entries(tuningSelects).forEach(([elementId, tuningKey]) => {
            const select = document.getElementById(elementId);
            if (select) {
                select.addEventListener('change', (e) => {
                    const value = parseInt(e.target.value);
                    if (tuningKey === 'turbo') {
                        this.tuning[tuningKey] = value === 1;
                    } else {
                        this.tuning[tuningKey] = value;
                    }
                });
            }
        });

        // Checkboxes extras
        const checkboxes = {
            'vehicleNeon': 'neon',
            'vehicleXenon': 'xenon',
            'vehicleFullUpgrade': 'fullUpgrade'
        };

        Object.entries(checkboxes).forEach(([elementId, tuningKey]) => {
            const checkbox = document.getElementById(elementId);
            if (checkbox) {
                checkbox.addEventListener('change', (e) => {
                    this.tuning[tuningKey] = e.target.checked;
                });
            }
        });

        // Color mode toggle
        const colorModeToggle = document.getElementById('colorModeToggle');
        if (colorModeToggle) {
            colorModeToggle.addEventListener('click', () => {
                this.toggleColorMode();
            });
        }

        // Initialize color picker
        this.initColorPicker();

        // Render initial carousel
        this.renderCarousel();
    },

    /**
     * Toggle entre mode simple et avancé
     */
    toggleColorMode() {
        const palette = document.getElementById('vehicleColorPalette');
        const picker = document.getElementById('advancedColorPicker');
        const toggle = document.getElementById('colorModeToggle');

        if (picker.classList.contains('hidden')) {
            palette.classList.add('hidden');
            picker.classList.remove('hidden');
            toggle.classList.add('active');
            this.useCustomColor = true;
            this.drawHueSlider();
            this.drawSpectrum();
            this.updateColorFromRGB();
        } else {
            palette.classList.remove('hidden');
            picker.classList.add('hidden');
            toggle.classList.remove('active');
            this.useCustomColor = false;
        }
    },

    /**
     * Initialiser le color picker avancé
     */
    initColorPicker() {
        const spectrum = document.getElementById('colorSpectrum');
        const hueSlider = document.getElementById('hueSlider');

        if (!spectrum || !hueSlider) return;

        // Draw initial canvases
        this.drawHueSlider();
        this.drawSpectrum();

        // Spectrum mouse events
        const spectrumContainer = spectrum.parentElement;
        let isDraggingSpectrum = false;

        spectrumContainer.addEventListener('mousedown', (e) => {
            isDraggingSpectrum = true;
            this.handleSpectrumClick(e);
        });

        document.addEventListener('mousemove', (e) => {
            if (isDraggingSpectrum) {
                this.handleSpectrumClick(e);
            }
        });

        document.addEventListener('mouseup', () => {
            isDraggingSpectrum = false;
        });

        // Hue slider events
        const hueContainer = hueSlider.parentElement;
        let isDraggingHue = false;

        hueContainer.addEventListener('mousedown', (e) => {
            isDraggingHue = true;
            this.handleHueClick(e);
        });

        document.addEventListener('mousemove', (e) => {
            if (isDraggingHue) {
                this.handleHueClick(e);
            }
        });

        document.addEventListener('mouseup', () => {
            isDraggingHue = false;
        });

        // Input events
        document.getElementById('colorHex').addEventListener('input', (e) => {
            this.setColorFromHex(e.target.value);
        });

        document.getElementById('colorR').addEventListener('input', () => this.updateColorFromInputs());
        document.getElementById('colorG').addEventListener('input', () => this.updateColorFromInputs());
        document.getElementById('colorB').addEventListener('input', () => this.updateColorFromInputs());
    },

    /**
     * Dessiner le slider de teinte (hue)
     */
    drawHueSlider() {
        const canvas = document.getElementById('hueSlider');
        if (!canvas) return;

        const ctx = canvas.getContext('2d');
        const gradient = ctx.createLinearGradient(0, 0, 0, canvas.height);

        gradient.addColorStop(0, '#ff0000');
        gradient.addColorStop(0.17, '#ff00ff');
        gradient.addColorStop(0.33, '#0000ff');
        gradient.addColorStop(0.5, '#00ffff');
        gradient.addColorStop(0.67, '#00ff00');
        gradient.addColorStop(0.83, '#ffff00');
        gradient.addColorStop(1, '#ff0000');

        ctx.fillStyle = gradient;
        ctx.fillRect(0, 0, canvas.width, canvas.height);
    },

    /**
     * Dessiner le spectre de couleur
     */
    drawSpectrum() {
        const canvas = document.getElementById('colorSpectrum');
        if (!canvas) return;

        const ctx = canvas.getContext('2d');
        const width = canvas.width;
        const height = canvas.height;

        // Base color from hue
        const hueColor = this.hslToRgb(this.currentHue / 360, 1, 0.5);
        const baseColor = `rgb(${hueColor.r}, ${hueColor.g}, ${hueColor.b})`;

        // Horizontal gradient: white to base color
        const gradientH = ctx.createLinearGradient(0, 0, width, 0);
        gradientH.addColorStop(0, '#ffffff');
        gradientH.addColorStop(1, baseColor);
        ctx.fillStyle = gradientH;
        ctx.fillRect(0, 0, width, height);

        // Vertical gradient: transparent to black
        const gradientV = ctx.createLinearGradient(0, 0, 0, height);
        gradientV.addColorStop(0, 'rgba(0,0,0,0)');
        gradientV.addColorStop(1, '#000000');
        ctx.fillStyle = gradientV;
        ctx.fillRect(0, 0, width, height);
    },

    /**
     * Gérer le clic sur le spectre
     */
    handleSpectrumClick(e) {
        const canvas = document.getElementById('colorSpectrum');
        const rect = canvas.getBoundingClientRect();

        // Utiliser les dimensions réelles du rendu
        let x = e.clientX - rect.left;
        let y = e.clientY - rect.top;

        // Clamper aux dimensions réelles
        x = Math.max(0, Math.min(rect.width, x));
        y = Math.max(0, Math.min(rect.height, y));

        // Update cursor position (en pourcentage pour être responsive)
        const cursor = document.getElementById('spectrumCursor');
        cursor.style.left = x + 'px';
        cursor.style.top = y + 'px';

        // Calculate saturation and brightness basé sur les dimensions réelles
        const saturation = x / rect.width;
        const brightness = 1 - (y / rect.height);

        // Convert HSB to RGB
        const rgb = this.hsbToRgb(this.currentHue / 360, saturation, brightness);
        this.customColor = rgb;
        this.updateColorDisplay();
    },

    /**
     * Gérer le clic sur le slider de teinte
     */
    handleHueClick(e) {
        const canvas = document.getElementById('hueSlider');
        const rect = canvas.getBoundingClientRect();
        let y = e.clientY - rect.top;

        y = Math.max(0, Math.min(rect.height, y));

        // Update cursor position
        const cursor = document.getElementById('hueCursor');
        cursor.style.top = y + 'px';

        // Calculate hue (0-360)
        this.currentHue = (y / rect.height) * 360;

        // Redraw spectrum with new hue
        this.drawSpectrum();

        // Recalculate color based on current spectrum cursor position
        const spectrumCursor = document.getElementById('spectrumCursor');
        const spectrum = document.getElementById('colorSpectrum');
        const spectrumRect = spectrum.getBoundingClientRect();

        const sx = parseFloat(spectrumCursor.style.left) || spectrumRect.width / 2;
        const sy = parseFloat(spectrumCursor.style.top) || spectrumRect.height / 2;
        const saturation = sx / spectrumRect.width;
        const brightness = 1 - (sy / spectrumRect.height);

        const rgb = this.hsbToRgb(this.currentHue / 360, saturation, brightness);
        this.customColor = rgb;
        this.updateColorDisplay();
    },

    /**
     * Mettre à jour l'affichage de la couleur
     */
    updateColorDisplay() {
        const { r, g, b } = this.customColor;
        const hex = this.rgbToHex(r, g, b);

        document.getElementById('colorPreviewBox').style.background = hex;
        document.getElementById('colorHex').value = hex;
        document.getElementById('colorR').value = r;
        document.getElementById('colorG').value = g;
        document.getElementById('colorB').value = b;
    },

    /**
     * Définir la couleur depuis un code hex
     */
    setColorFromHex(hex) {
        if (!/^#[0-9A-Fa-f]{6}$/.test(hex)) return;

        const r = parseInt(hex.slice(1, 3), 16);
        const g = parseInt(hex.slice(3, 5), 16);
        const b = parseInt(hex.slice(5, 7), 16);

        this.customColor = { r, g, b };
        this.updateColorDisplay();
        this.updatePickerFromRGB();
    },

    /**
     * Mettre à jour la couleur depuis les inputs RGB
     */
    updateColorFromInputs() {
        const r = parseInt(document.getElementById('colorR').value) || 0;
        const g = parseInt(document.getElementById('colorG').value) || 0;
        const b = parseInt(document.getElementById('colorB').value) || 0;

        this.customColor = {
            r: Math.max(0, Math.min(255, r)),
            g: Math.max(0, Math.min(255, g)),
            b: Math.max(0, Math.min(255, b))
        };

        this.updateColorDisplay();
        this.updatePickerFromRGB();
    },

    /**
     * Mettre à jour la couleur initiale depuis RGB
     */
    updateColorFromRGB() {
        this.updateColorDisplay();
        this.updatePickerFromRGB();
    },

    /**
     * Mettre à jour les curseurs du picker depuis RGB
     */
    updatePickerFromRGB() {
        const { r, g, b } = this.customColor;
        const hsb = this.rgbToHsb(r, g, b);

        this.currentHue = hsb.h * 360;

        // Update hue cursor
        const hueCanvas = document.getElementById('hueSlider');
        const hueCursor = document.getElementById('hueCursor');
        if (hueCanvas && hueCursor) {
            hueCursor.style.top = (this.currentHue / 360) * hueCanvas.height + 'px';
        }

        // Update spectrum cursor
        const spectrum = document.getElementById('colorSpectrum');
        const spectrumCursor = document.getElementById('spectrumCursor');
        if (spectrum && spectrumCursor) {
            spectrumCursor.style.left = hsb.s * spectrum.width + 'px';
            spectrumCursor.style.top = (1 - hsb.b) * spectrum.height + 'px';
        }

        // Redraw spectrum
        this.drawSpectrum();
    },

    /**
     * Conversion HSL vers RGB
     */
    hslToRgb(h, s, l) {
        let r, g, b;

        if (s === 0) {
            r = g = b = l;
        } else {
            const hue2rgb = (p, q, t) => {
                if (t < 0) t += 1;
                if (t > 1) t -= 1;
                if (t < 1/6) return p + (q - p) * 6 * t;
                if (t < 1/2) return q;
                if (t < 2/3) return p + (q - p) * (2/3 - t) * 6;
                return p;
            };

            const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
            const p = 2 * l - q;
            r = hue2rgb(p, q, h + 1/3);
            g = hue2rgb(p, q, h);
            b = hue2rgb(p, q, h - 1/3);
        }

        return {
            r: Math.round(r * 255),
            g: Math.round(g * 255),
            b: Math.round(b * 255)
        };
    },

    /**
     * Conversion HSB vers RGB
     */
    hsbToRgb(h, s, b) {
        let r, g, bl;
        const i = Math.floor(h * 6);
        const f = h * 6 - i;
        const p = b * (1 - s);
        const q = b * (1 - f * s);
        const t = b * (1 - (1 - f) * s);

        switch (i % 6) {
            case 0: r = b; g = t; bl = p; break;
            case 1: r = q; g = b; bl = p; break;
            case 2: r = p; g = b; bl = t; break;
            case 3: r = p; g = q; bl = b; break;
            case 4: r = t; g = p; bl = b; break;
            case 5: r = b; g = p; bl = q; break;
        }

        return {
            r: Math.round(r * 255),
            g: Math.round(g * 255),
            b: Math.round(bl * 255)
        };
    },

    /**
     * Conversion RGB vers HSB
     */
    rgbToHsb(r, g, b) {
        r /= 255; g /= 255; b /= 255;
        const max = Math.max(r, g, b);
        const min = Math.min(r, g, b);
        const d = max - min;
        let h, s;
        const br = max;

        s = max === 0 ? 0 : d / max;

        if (max === min) {
            h = 0;
        } else {
            switch (max) {
                case r: h = (g - b) / d + (g < b ? 6 : 0); break;
                case g: h = (b - r) / d + 2; break;
                case b: h = (r - g) / d + 4; break;
            }
            h /= 6;
        }

        return { h, s, b: br };
    },

    /**
     * Conversion RGB vers Hex
     */
    rgbToHex(r, g, b) {
        return '#' + [r, g, b].map(x => {
            const hex = x.toString(16);
            return hex.length === 1 ? '0' + hex : hex;
        }).join('').toUpperCase();
    },

    /**
     * Aller à la catégorie précédente
     */
    previousCategory() {
        this.currentCategoryIndex--;
        if (this.currentCategoryIndex < 0) {
            this.currentCategoryIndex = this.categories.length - 1;
        }
        this.renderCarousel();
    },

    /**
     * Aller à la catégorie suivante
     */
    nextCategory() {
        this.currentCategoryIndex++;
        if (this.currentCategoryIndex >= this.categories.length) {
            this.currentCategoryIndex = 0;
        }
        this.renderCarousel();
    },

    /**
     * Rendre le carousel
     */
    renderCarousel() {
        const category = this.categories[this.currentCategoryIndex];
        document.getElementById('carouselCategory').textContent = category.name;

        const carousel = document.getElementById('vehicleCarousel');
        carousel.innerHTML = category.vehicles.map(vehicle => `
            <div class="vehicle-card" onclick="VehiclesModule.quickSpawn('${vehicle.model}')">
                <div class="vehicle-icon">
                    <i class="fas ${vehicle.icon}"></i>
                </div>
                <span class="vehicle-name">${vehicle.name}</span>
                <span class="vehicle-model">${vehicle.model}</span>
            </div>
        `).join('');
    },

    /**
     * Obtenir les options de tuning actuelles
     */
    getTuningOptions() {
        const options = {
            color: this.selectedColor,
            engine: this.tuning.engine,
            transmission: this.tuning.transmission,
            brakes: this.tuning.brakes,
            suspension: this.tuning.suspension,
            armor: this.tuning.armor,
            turbo: this.tuning.turbo,
            neon: this.tuning.neon,
            xenon: this.tuning.xenon,
            fullUpgrade: this.tuning.fullUpgrade
        };

        // Si mode couleur personnalisée, ajouter les RGB
        if (this.useCustomColor) {
            options.customColor = true;
            options.colorR = this.customColor.r;
            options.colorG = this.customColor.g;
            options.colorB = this.customColor.b;
        }

        return options;
    },

    /**
     * Spawn rapide depuis le carousel
     */
    async quickSpawn(model) {
        const tuningOptions = this.getTuningOptions();
        const options = {
            model: model,
            ...tuningOptions
        };

        await API.vehicleAction('spawn', null, options);
    },

    /**
     * Spawn un véhicule (manuel)
     */
    async spawnVehicle() {
        const model = document.getElementById('vehicleModel').value.trim();

        if (!model) {
            Notifications.error('Erreur', 'Entrez un nom de modèle');
            return;
        }

        const tuningOptions = this.getTuningOptions();
        const options = {
            model: model,
            ...tuningOptions
        };

        await API.vehicleAction('spawn', null, options);
        document.getElementById('vehicleModel').value = '';
    },

    /**
     * Supprimer le véhicule actuel
     */
    async deleteVehicle() {
        await API.vehicleAction('delete');
    },

    /**
     * Réparer le véhicule actuel
     */
    async repairVehicle() {
        await API.vehicleAction('repair');
    }
};

// Export
window.VehiclesModule = VehiclesModule;
