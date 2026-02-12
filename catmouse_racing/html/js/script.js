/**
 * ═══════════════════════════════════════════════════════════
 * 🎮 CATMOUSE RACING - SCRIPT NUI PRINCIPAL
 * ═══════════════════════════════════════════════════════════
 */

const RESOURCE_NAME = 'catmouse_racing';

// ═══════════════════════════════════════════════════════════
// 📡 API NUI
// ═══════════════════════════════════════════════════════════

async function SendCallback(callback, data = {}) {
    try {
        const response = await fetch(`https://${RESOURCE_NAME}/${callback}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });
        return await response.json();
    } catch (error) {
        return null;
    }
}

// ═══════════════════════════════════════════════════════════
// 🔔 GESTIONNAIRE DE NOTIFICATIONS
// ═══════════════════════════════════════════════════════════

class NotificationManager {
    constructor() {
        this.container = document.getElementById('notifications-container');
        this.active = new Map();
        this.maxVisible = 3;
        this.defaultDuration = 5000;
    }
    
    show(data) {
        const { type = 'info', message, duration = this.defaultDuration, id = this.generateId() } = data;
        
        if (this.active.size >= this.maxVisible) {
            this.removeOldest();
        }
        
        const notification = this.createElement(type, message, id, duration);
        this.container.appendChild(notification);
        
        this.active.set(id, {
            element: notification,
            timeout: setTimeout(() => this.remove(id), duration)
        });
        
        requestAnimationFrame(() => notification.classList.add('active'));
    }
    
    createElement(type, message, id, duration) {
        const iconMap = {
            info: 'fa-info-circle',
            success: 'fa-check-circle',
            warning: 'fa-exclamation-triangle',
            error: 'fa-times-circle',
            invite: 'fa-envelope'
        };
        
        const div = document.createElement('div');
        div.className = `notification ${type}`;
        div.dataset.id = id;
        
        div.innerHTML = `
            <div class="notification-icon">
                <i class="fas ${iconMap[type] || iconMap.info}"></i>
            </div>
            <div class="notification-content">
                <p class="notification-message">${this.escapeHtml(message)}</p>
            </div>
            <div class="notification-progress" style="animation-duration: ${duration}ms;"></div>
        `;
        
        div.addEventListener('click', () => this.remove(id));
        return div;
    }
    
    remove(id) {
        const data = this.active.get(id);
        if (!data) return;
        
        clearTimeout(data.timeout);
        data.element.classList.add('removing');
        
        setTimeout(() => {
            data.element.remove();
            this.active.delete(id);
        }, 300);
    }
    
    removeOldest() {
        const firstId = this.active.keys().next().value;
        if (firstId) this.remove(firstId);
    }
    
    generateId() {
        return `notif_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }
    
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

// ═══════════════════════════════════════════════════════════
// 🎬 GESTIONNAIRE D'ANIMATION DE TRANSITION ROUND
// ═══════════════════════════════════════════════════════════

class RoundTransitionManager {
    constructor() {
        this.overlay = document.getElementById('round-transition-overlay');
        this.iconEl = document.getElementById('round-transition-icon');
        this.titleEl = document.getElementById('round-transition-title');
        this.subtitleEl = document.getElementById('round-transition-subtitle');
        this.messageEl = document.getElementById('round-transition-message');
        this.progressEl = document.getElementById('round-transition-progress');
        this.particlesContainer = document.getElementById('round-transition-particles');
        
        this.isActive = false;
        this.progressInterval = null;
        this.hideTimeout = null;
        
        // Durée par défaut augmentée à 6 secondes
        this.defaultDuration = 6000;
    }
    
    /**
     * Afficher l'animation de transition
     * @param {Object} data - { isWinner, message, duration }
     */
    show(data) {
        const { isWinner, message, duration = this.defaultDuration } = data;
        
        
        // Nettoyer état précédent
        this.cleanup();
        
        this.isActive = true;
        
        // Configurer le type (victoire ou défaite)
        this.overlay.classList.remove('victory', 'defeat', 'hidden', 'closing');
        this.overlay.classList.add(isWinner ? 'victory' : 'defeat');
        
        // Icône
        if (this.iconEl) {
            this.iconEl.innerHTML = isWinner 
                ? '<i class="fas fa-trophy"></i>' 
                : '<i class="fas fa-skull-crossbones"></i>';
        }
        
        // Titre
        if (this.titleEl) {
            this.titleEl.textContent = isWinner ? 'VICTOIRE' : 'DÉFAITE';
        }
        
        // Sous-titre
        if (this.subtitleEl) {
            this.subtitleEl.textContent = isWinner ? 'ROUND GAGNÉ' : 'ROUND PERDU';
        }
        
        // Message
        if (this.messageEl) {
            this.messageEl.textContent = message || (isWinner ? 'Bien joué !' : 'Dommage...');
        }
        
        // Générer les particules (moins nombreuses pour être plus sobre)
        this.generateParticles(isWinner ? 12 : 10);
        
        // Afficher
        requestAnimationFrame(() => {
            this.overlay.classList.add('active');
        });
        
        // Animation de la barre de progression
        this.startProgressAnimation(duration);
        
        // Masquer automatiquement
        this.hideTimeout = setTimeout(() => {
            this.hide();
        }, duration);
    }
    
    /**
     * Masquer l'animation de transition
     */
    hide() {
        if (!this.isActive) return;
        
        this.overlay.classList.add('closing');
        this.overlay.classList.remove('active');
        
        setTimeout(() => {
            this.overlay.classList.add('hidden');
            this.overlay.classList.remove('closing', 'victory', 'defeat');
            this.cleanup();
        }, 500);
    }
    
    /**
     * Démarrer l'animation de la barre de progression
     */
    startProgressAnimation(duration) {
        if (!this.progressEl) return;
        
        const startTime = Date.now();
        const endTime = startTime + duration;
        
        this.progressEl.style.width = '100%';
        
        this.progressInterval = setInterval(() => {
            const now = Date.now();
            const remaining = Math.max(0, endTime - now);
            const percent = (remaining / duration) * 100;
            
            this.progressEl.style.width = `${percent}%`;
            
            if (percent <= 0) {
                clearInterval(this.progressInterval);
                this.progressInterval = null;
            }
        }, 50);
    }
    
    /**
     * Générer des particules animées (moins nombreuses)
     */
    generateParticles(count) {
        if (!this.particlesContainer) return;
        
        this.particlesContainer.innerHTML = '';
        
        for (let i = 0; i < count; i++) {
            const particle = document.createElement('div');
            particle.className = 'particle';
            
            // Position aléatoire horizontale
            particle.style.left = `${Math.random() * 100}%`;
            
            // Taille aléatoire (plus petites)
            const size = 4 + Math.random() * 6;
            particle.style.width = `${size}px`;
            particle.style.height = `${size}px`;
            
            // Délai d'animation aléatoire
            particle.style.animationDelay = `${Math.random() * 3}s`;
            particle.style.animationDuration = `${3 + Math.random() * 3}s`;
            
            this.particlesContainer.appendChild(particle);
        }
    }
    
    /**
     * Nettoyage
     */
    cleanup() {
        this.isActive = false;
        
        if (this.progressInterval) {
            clearInterval(this.progressInterval);
            this.progressInterval = null;
        }
        
        if (this.hideTimeout) {
            clearTimeout(this.hideTimeout);
            this.hideTimeout = null;
        }
        
        if (this.progressEl) {
            this.progressEl.style.width = '100%';
        }
    }
}

// ═══════════════════════════════════════════════════════════
// 🎮 APPLICATION PRINCIPALE
// ═══════════════════════════════════════════════════════════

class CatMouseApp {
    constructor() {
        // Éléments DOM - Menu
        this.mainUI = document.getElementById('main-ui');
        this.titleEl = document.getElementById('ui-title');
        this.subtitleEl = document.getElementById('ui-subtitle');
        this.rulesListEl = document.getElementById('rules-list');
        this.playerIdInput = document.getElementById('player-id-input');
        this.sendInviteBtn = document.getElementById('send-invite-btn');
        this.closeUIBtn = document.getElementById('close-ui-btn');
        this.joinQueueBtn = document.getElementById('join-queue-btn');
        this.leaveQueueBtn = document.getElementById('leave-queue-btn');
        this.queueStatus = document.getElementById('queue-status');
        this.queueSection = document.getElementById('queue-section');
        
        // Éléments DOM - HUD
        this.raceHud = document.getElementById('race-hud');
        this.hudRound = document.getElementById('hud-round');
        this.currentRoundEl = document.getElementById('current-round');
        this.maxRoundsEl = document.getElementById('max-rounds');
        this.roleNameEl = document.getElementById('role-name');
        this.timerValueEl = document.getElementById('timer-value');
        this.hudTimer = document.getElementById('hud-timer');
        this.hudDistance = document.getElementById('hud-distance');
        this.distanceValueEl = document.getElementById('distance-value');
        this.distanceFillEl = document.getElementById('distance-fill');
        this.hudCapture = document.getElementById('hud-capture');
        this.captureFillEl = document.getElementById('capture-fill');
        this.capturePercentEl = document.getElementById('capture-percent');
        this.opponentNameEl = document.getElementById('opponent-name');
        
        // Éléments DOM - Scores
        this.myScoreEl = document.getElementById('my-score');
        this.opponentScoreEl = document.getElementById('opponent-score');
        this.opponentLabelEl = document.getElementById('opponent-label');
        
        // Éléments DOM - Overlays
        this.countdownOverlay = document.getElementById('countdown-overlay');
        this.countdownNumber = document.getElementById('countdown-number');
        this.resultOverlay = document.getElementById('result-overlay');
        this.resultTitle = document.getElementById('result-title');
        this.resultWinner = document.getElementById('result-winner');
        this.resultScoreName1 = document.getElementById('result-score-name-1');
        this.resultScoreValue1 = document.getElementById('result-score-value-1');
        this.resultScoreName2 = document.getElementById('result-score-name-2');
        this.resultScoreValue2 = document.getElementById('result-score-value-2');
        
        // État
        this.isMenuOpen = false;
        this.isHudVisible = false;
        this.currentRole = 0;
        this.config = null;
        this.isInQueue = false;
        
        // Gestionnaire de transition round
        this.roundTransition = new RoundTransitionManager();
        
        this.init();
    }
    
    init() {
        // Événements menu
        this.closeUIBtn?.addEventListener('click', () => this.closeMenu());
        this.sendInviteBtn?.addEventListener('click', () => this.sendInvitation());
        this.playerIdInput?.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') this.sendInvitation();
        });
        this.joinQueueBtn?.addEventListener('click', () => this.joinQueue());
        this.leaveQueueBtn?.addEventListener('click', () => this.leaveQueue());
        
        // ESC global
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && this.isMenuOpen) {
                this.closeMenu();
            }
        });
        
        // Messages NUI
        window.addEventListener('message', (event) => this.handleMessage(event.data));
        
    }
    
    handleMessage(data) {
        
        switch (data.action) {
            // Menu
            case 'openUI':
                this.openMenu(data.data);
                break;
            case 'closeUI':
                this.closeMenu();
                break;
                
            // Notifications
            case 'showNotification':
                notificationManager.show(data.data);
                break;
            case 'removeNotification':
                notificationManager.remove(data.data.id);
                break;
                
            // Queue
            case 'updateQueue':
                this.updateQueueStatus(data.data);
                break;
                
            // HUD
            case 'showRaceHUD':
                this.showHud(data.data);
                break;
            case 'hideRaceHUD':
                this.hideHud();
                break;
            case 'updateTimer':
                this.updateTimer(data.data);
                break;
            case 'updateDistance':
                this.updateDistance(data.data);
                break;
            case 'showCaptureBar':
                this.showCaptureBar(data.data.show);
                break;
            case 'updateCaptureProgress':
                this.updateCaptureProgress(data.data.progress);
                break;
            case 'updateScores':
                this.updateScores(data.data);
                break;
                
            // Countdown
            case 'showCountdown':
                this.showCountdown(data.data);
                break;
            case 'hideCountdown':
                this.hideCountdown();
                break;
                
            // Animation de transition round
            case 'showRoundTransition':
                this.showRoundTransition(data.data);
                break;
            case 'hideRoundTransition':
                this.hideRoundTransition();
                break;
                
            // Résultat
            case 'showFinalResult':
                this.showFinalResult(data.data);
                break;
        }
    }
    
    // ═══════════════════════════════════════════════════════════
    // 📋 MENU
    // ═══════════════════════════════════════════════════════════
    
    openMenu(config) {
        if (this.isMenuOpen) return;
        
        this.config = config;
        this.isMenuOpen = true;
        
        this.resetQueueUI();
        
        this.updateMenuContent();
        this.mainUI.classList.remove('hidden');
        
        setTimeout(() => this.playerIdInput?.focus(), 100);
    }
    
    closeMenu() {
        if (!this.isMenuOpen) return;
        
        this.isMenuOpen = false;
        this.mainUI.classList.add('hidden');
        this.playerIdInput.value = '';
        
        SendCallback('catmouse:closeUI');
    }
    
    updateMenuContent() {
        if (!this.config) return;
        
        if (this.titleEl) this.titleEl.textContent = this.config.title || 'JEU DE COURSE';
        if (this.subtitleEl) this.subtitleEl.textContent = this.config.subtitle || 'CHASSEUR VS FUYARD';
        
        if (this.config.matchmakingEnabled === false && this.queueSection) {
            this.queueSection.style.display = 'none';
        }
        
        this.renderRules(this.config.rules || []);
    }
    
    renderRules(rules) {
        if (!this.rulesListEl) return;
        
        this.rulesListEl.innerHTML = '';
        
        rules.forEach(rule => {
            const div = document.createElement('div');
            div.className = 'rule-item';
            div.innerHTML = `
                <h3 class="rule-title">${this.escapeHtml(rule.title)}</h3>
                <p class="rule-description">${this.escapeHtml(rule.description)}</p>
            `;
            this.rulesListEl.appendChild(div);
        });
    }
    
    sendInvitation() {
        const targetId = parseInt(this.playerIdInput?.value);
        
        if (!targetId || targetId < 1) {
            notificationManager.show({ type: 'error', message: 'ID de joueur invalide' });
            return;
        }
        
        SendCallback('catmouse:sendInvite', { targetId });
    }
    
    joinQueue() {
        SendCallback('catmouse:joinQueue');
        
        this.isInQueue = true;
        
        if (this.joinQueueBtn) this.joinQueueBtn.classList.add('hidden');
        if (this.queueStatus) this.queueStatus.classList.remove('hidden');
    }
    
    leaveQueue() {
        SendCallback('catmouse:leaveQueue');
        this.resetQueueUI();
    }
    
    resetQueueUI() {
        
        this.isInQueue = false;
        
        if (this.joinQueueBtn) {
            this.joinQueueBtn.classList.remove('hidden');
        }
        
        if (this.queueStatus) {
            this.queueStatus.classList.add('hidden');
        }
    }
    
    updateQueueStatus(data) {
        
        if (data.status === 2 || data.status === 3 || data.status === 4) {
            this.resetQueueUI();
        }
    }
    
    // ═══════════════════════════════════════════════════════════
    // 🏁 HUD DE COURSE
    // ═══════════════════════════════════════════════════════════
    
    showHud(data) {
        this.isHudVisible = true;
        this.currentRole = data.role;
        
        this.resetQueueUI();
        
        // Mise à jour des infos
        if (this.currentRoundEl) this.currentRoundEl.textContent = data.round;
        if (this.maxRoundsEl) this.maxRoundsEl.textContent = data.maxRounds;
        if (this.roleNameEl) this.roleNameEl.textContent = data.roleName;
        if (this.opponentNameEl) this.opponentNameEl.textContent = data.opponentName;
        
        // Mise à jour des scores
        if (this.myScoreEl) this.myScoreEl.textContent = data.myScore || 0;
        if (this.opponentScoreEl) this.opponentScoreEl.textContent = data.opponentScore || 0;
        if (this.opponentLabelEl) this.opponentLabelEl.textContent = (data.opponentName || 'ADV').substring(0, 3).toUpperCase();
        
        // Afficher/masquer selon le rôle
        if (this.hudDistance) {
            this.hudDistance.classList.toggle('hidden', data.role !== 2);
        }
        
        this.raceHud.classList.remove('hidden');
    }
    
    hideHud() {
        this.isHudVisible = false;
        this.raceHud.classList.add('hidden');
        this.hudCapture?.classList.add('hidden');
        this.hudDistance?.classList.add('hidden');
        
        this.resetQueueUI();
    }
    
    updateTimer(data) {
        if (this.timerValueEl) {
            this.timerValueEl.textContent = data.formattedTime;
        }
        
        if (this.hudTimer) {
            this.hudTimer.classList.toggle('critical', data.remainingTime < 30000);
        }
    }
    
    updateDistance(data) {
        const distance = Math.round(data.distance);
        
        if (this.distanceValueEl) {
            this.distanceValueEl.textContent = distance;
        }
        
        if (this.distanceFillEl) {
            const percent = Math.min(100, (distance / 150) * 100);
            this.distanceFillEl.style.width = `${percent}%`;
        }
    }
    
    showCaptureBar(show) {
        if (this.hudCapture) {
            this.hudCapture.classList.toggle('hidden', !show);
        }
    }
    
    updateCaptureProgress(progress) {
        if (this.captureFillEl) {
            this.captureFillEl.style.width = `${progress}%`;
        }
        if (this.capturePercentEl) {
            this.capturePercentEl.textContent = Math.round(progress);
        }
    }
    
    updateScores(data) {
        
        if (this.myScoreEl) {
            this.myScoreEl.textContent = data.myScore || 0;
        }
        
        if (this.opponentScoreEl) {
            this.opponentScoreEl.textContent = data.opponentScore || 0;
        }
    }
    
    // ═══════════════════════════════════════════════════════════
    // 🔢 COUNTDOWN
    // ═══════════════════════════════════════════════════════════
    
    showCountdown(data) {
        this.countdownOverlay.classList.remove('hidden');
        
        if (data.number === 0 || data.text === 'GO!') {
            this.countdownNumber.textContent = 'GO!';
            this.countdownNumber.classList.add('go');
        } else {
            this.countdownNumber.textContent = data.number;
            this.countdownNumber.classList.remove('go');
        }
        
        // Reset animation
        this.countdownNumber.style.animation = 'none';
        this.countdownNumber.offsetHeight;
        this.countdownNumber.style.animation = '';
    }
    
    hideCountdown() {
        this.countdownOverlay.classList.add('hidden');
    }
    
    // ═══════════════════════════════════════════════════════════
    // 🎬 ANIMATION TRANSITION ROUND
    // ═══════════════════════════════════════════════════════════
    
    /**
     * Afficher l'animation de transition de round
     * @param {Object} data - { isWinner, message, duration }
     */
    showRoundTransition(data) {
        this.roundTransition.show(data);
    }
    
    /**
     * Masquer l'animation de transition
     */
    hideRoundTransition() {
        this.roundTransition.hide();
    }
    
    // ═══════════════════════════════════════════════════════════
    // 🏆 RÉSULTAT
    // ═══════════════════════════════════════════════════════════
    
    showFinalResult(data) {
        
        // Masquer la transition de round si elle est active
        this.roundTransition.hide();
        
        this.resultOverlay.classList.remove('hidden');
        
        // Titre
        if (this.resultTitle) {
            this.resultTitle.textContent = data.isWinner ? 'VICTOIRE' : 'DÉFAITE';
            this.resultTitle.className = `result-title ${data.isWinner ? 'victory' : 'defeat'}`;
        }
        
        // Gagnant
        if (this.resultWinner) {
            this.resultWinner.textContent = `${data.winnerName} remporte le match !`;
        }
        
        // Scores finaux
        if (this.resultScoreName1) {
            this.resultScoreName1.textContent = data.myName || 'Vous';
        }
        if (this.resultScoreValue1) {
            this.resultScoreValue1.textContent = data.myScore || 0;
        }
        if (this.resultScoreName2) {
            this.resultScoreName2.textContent = data.opponentName || 'Adversaire';
        }
        if (this.resultScoreValue2) {
            this.resultScoreValue2.textContent = data.opponentScore || 0;
        }
        
        // Masquer après 5 secondes
        setTimeout(() => {
            this.resultOverlay.classList.add('hidden');
        }, 5000);
    }
    
    // ═══════════════════════════════════════════════════════════
    // 🛠️ UTILITAIRES
    // ═══════════════════════════════════════════════════════════
    
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

// ═══════════════════════════════════════════════════════════
// 🚀 INITIALISATION
// ═══════════════════════════════════════════════════════════

const notificationManager = new NotificationManager();
const app = new CatMouseApp();

// Debug (dev only)
if (window.location.hostname === 'localhost' || window.location.hostname === '') {
    window.CatMouseApp = app;
    window.NotificationManager = notificationManager;
    
    window.testUI = () => {
        app.openMenu({
            title: 'JEU DE COURSE',
            subtitle: 'CHASSEUR VS FUYARD',
            matchmakingEnabled: true,
            rules: [
                { title: 'OBJECTIF FUYARD', description: 'Atteindre 150m de distance du chasseur OU survivre 3 minutes.' },
                { title: 'OBJECTIF CHASSEUR', description: 'Bloquer le fuyard et maintenir la capture pendant 6 secondes.' },
                { title: 'FORMAT', description: 'Best of 3 rounds. Les rôles s\'inversent à chaque round.' }
            ]
        });
    };
    
    window.testHud = (role = 2) => {
        app.showHud({
            round: 1,
            maxRounds: 3,
            role: role,
            roleName: role === 1 ? 'CHASSEUR' : 'FUYARD',
            opponentName: 'TestPlayer',
            myScore: 1,
            opponentScore: 0
        });
    };
    
    window.testCountdown = () => {
        let count = 3;
        const interval = setInterval(() => {
            app.showCountdown({ number: count });
            count--;
            if (count < 0) {
                clearInterval(interval);
                setTimeout(() => app.hideCountdown(), 1000);
            }
        }, 1000);
    };
    
    window.testCapture = () => {
        app.showCaptureBar(true);
        let progress = 0;
        const interval = setInterval(() => {
            progress += 2;
            app.updateCaptureProgress(progress);
            if (progress >= 100) {
                clearInterval(interval);
                setTimeout(() => app.showCaptureBar(false), 500);
            }
        }, 100);
    };
    
    window.testScores = () => {
        app.updateScores({ myScore: 2, opponentScore: 1 });
    };
    
    // Test de la transition de round (durée 6 secondes par défaut)
    window.testTransition = (isWinner = true) => {
        app.showRoundTransition({
            isWinner: isWinner,
            message: isWinner ? 'Le fuyard a été capturé !' : 'Le fuyard s\'est échappé !',
            duration: 6000
        });
    };
    
    window.testTransitionVictory = () => window.testTransition(true);
    window.testTransitionDefeat = () => window.testTransition(false);
    
    window.testResult = (isWinner = true) => {
        app.showFinalResult({
            isWinner: isWinner,
            winnerName: isWinner ? 'Vous' : 'Adversaire',
            myScore: isWinner ? 2 : 1,
            opponentScore: isWinner ? 1 : 2,
            myName: 'Vous',
            opponentName: 'TestPlayer'
        });
    };

}
