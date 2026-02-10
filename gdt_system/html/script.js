// ==========================================
// SCRIPT NUI - GUERRE DE TERRITOIRE (SIMPLIFIÉ)
// ==========================================

const container = document.getElementById('container');
const joinLobbyBtn = document.getElementById('joinLobbyBtn');

let killfeedEntries = [];
const maxKillfeedEntries = 6;

// ==========================================
// GESTION DES MESSAGES LUA
// ==========================================

window.addEventListener('message', (event) => {
    const data = event.data;
    
    switch (data.action) {
        case 'openUI':
            openUI();
            break;
        case 'closeUI':
            closeUI();
            break;
        case 'showAnnounce':
            showAnnounce(data.message, data.duration);
            break;
        case 'showRoundWin':
            showRoundWin(data.winner, data.color, data.scores, data.topRed, data.topBlue);
            break;
        case 'showGameEnd':
            showGameEnd(data.winner, data.color, data.scores, data.topRed, data.topBlue);
            break;
        case 'showSpectatorHUD':
            showSpectatorHUD(data.targetName, data.targetId, data.currentIndex, data.totalTargets);
            break;
        case 'hideSpectatorHUD':
            hideSpectatorHUD();
            break;
        case 'addKill':
            addKillfeedEntry(data.killer, data.victim, data.duration);
            break;
        case 'showLeaderboard':
            renderLeaderboard(data.players);
            break;
        case 'showTeamList':
            showTeamList(data.red, data.blue, data.lobby, data.gameInfo);
            break;
        case 'hideTeamList':
            hideTeamList();
            break;
    }
});

// ==========================================
// OUVRIR L'INTERFACE
// ==========================================

function openUI() {
    container.classList.remove('hidden');
}

// ==========================================
// FERMER L'INTERFACE
// ==========================================

function closeUI() {
    container.classList.add('hidden');
    
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// ==========================================
// BOUTON REJOINDRE
// ==========================================

joinLobbyBtn.addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/joinLobby`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
    
    joinLobbyBtn.style.transform = 'scale(0.95)';
    setTimeout(() => {
        joinLobbyBtn.style.transform = 'scale(1)';
    }, 150);
});

// ==========================================
// TOUCHE ESC
// ==========================================

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !container.classList.contains('hidden')) {
        closeUI();
    }
});

// ==========================================
// NOM DE LA RESSOURCE
// ==========================================

function GetParentResourceName() {
    const match = window.location.pathname.match(/\/([^/]+)\/html\//);
    return match ? match[1] : 'gdt_system';
}

// ==========================================
// ANNONCES - MODERN STYLE
// ==========================================

function showAnnounce(message, duration) {
    const container = document.getElementById('announce-container');
    const text = document.getElementById('announce-text');
    const timerBar = document.getElementById('announce-timer-bar');

    if (!container || !text) return;

    text.textContent = message;
    container.classList.remove('hidden');

    // Reset et animation de la barre de timer
    if (timerBar) {
        timerBar.style.transition = 'none';
        timerBar.style.width = '0%';

        // Démarrer l'animation après un court délai
        setTimeout(() => {
            timerBar.style.transition = `width ${duration}ms linear`;
            timerBar.style.width = '60%';
        }, 50);
    }

    // Disparition
    setTimeout(() => {
        container.classList.add('hidden');
        // Reset la barre après la disparition
        setTimeout(() => {
            if (timerBar) {
                timerBar.style.transition = 'none';
                timerBar.style.width = '0%';
            }
        }, 500);
    }, duration);
}

// ==========================================
// VICTOIRE DU ROUND
// ==========================================

function renderPlayerList(containerId, players) {
    const el = document.getElementById(containerId);
    if (!el) return;
    el.innerHTML = (players || []).map(p => `
        <div class="player-row">
            <span class="p-name">${escapeHtml(p.name)}</span>
            <span class="p-kills">${p.kills}<span>KILLS</span></span>
        </div>
    `).join('');
}

function showRoundWin(winner, color, scores, topRed, topBlue) {
    const container = document.getElementById('round-win-container');
    const teamElement = document.getElementById('round-win-team');
    const scoreRed = document.getElementById('score-red');
    const scoreBlue = document.getElementById('score-blue');

    if (!container || !teamElement) return;

    const neonColor = color === 'red' ? 'var(--red-neon)' : 'var(--blue-neon)';
    const neonShadow = color === 'red' ? '0 0 20px rgba(255,62,62,0.4)' : '0 0 20px rgba(0,210,255,0.4)';
    teamElement.textContent = `EQUIPE ${winner} GAGNE !`;
    teamElement.style.color = neonColor;
    teamElement.style.textShadow = neonShadow;
    scoreRed.textContent = scores.red;
    scoreBlue.textContent = scores.blue;

    renderPlayerList('round-red-players', topRed);
    renderPlayerList('round-blue-players', topBlue);

    container.classList.remove('hidden');

    setTimeout(() => {
        container.classList.add('hidden');
    }, 5000);
}

// ==========================================
// FIN DE PARTIE
// ==========================================

function showGameEnd(winner, color, scores, topRed, topBlue) {
    const container = document.getElementById('game-end-container');
    const winnerElement = document.getElementById('game-end-winner');
    const finalScoreRed = document.getElementById('final-score-red');
    const finalScoreBlue = document.getElementById('final-score-blue');

    if (!container || !winnerElement) return;

    const neonColor = color === 'red' ? 'var(--red-neon)' : 'var(--blue-neon)';
    const neonShadow = color === 'red' ? '0 0 20px rgba(255,62,62,0.4)' : '0 0 20px rgba(0,210,255,0.4)';
    winnerElement.textContent = `EQUIPE ${winner} VICTOIRE !`;
    winnerElement.style.color = neonColor;
    winnerElement.style.textShadow = neonShadow;
    finalScoreRed.textContent = scores.red;
    finalScoreBlue.textContent = scores.blue;

    renderPlayerList('end-red-players', topRed);
    renderPlayerList('end-blue-players', topBlue);

    container.classList.remove('hidden');

    setTimeout(() => {
        container.classList.add('hidden');
    }, 10000);
}

// ==========================================
// KILLFEED
// ==========================================

function addKillfeedEntry(killer, victim, duration) {
    const container = document.getElementById('killfeed-container');
    if (!container) return;

    const entry = document.createElement('div');
    entry.className = 'killfeed-entry';

    entry.innerHTML = `
        <div class="killfeed-player killfeed-killer">
            <span class="killfeed-id">ID:${killer.id}</span>
            <span class="killfeed-name">${escapeHtml(killer.name)}</span>
        </div>
        <div class="killfeed-action">À TUÉ</div>
        <div class="killfeed-player killfeed-victim">
            <span class="killfeed-name">${escapeHtml(victim.name)}</span>
            <span class="killfeed-id">ID:${victim.id}</span>
        </div>
    `;

    container.prepend(entry);
    killfeedEntries.unshift(entry);

    if (killfeedEntries.length > maxKillfeedEntries) {
        const oldEntry = killfeedEntries.pop();
        oldEntry.classList.add('fade-out');
        setTimeout(() => {
            if (oldEntry.parentNode) oldEntry.parentNode.removeChild(oldEntry);
        }, 400);
    }

    setTimeout(() => {
        removeKillfeedEntry(entry);
    }, duration);
}

function removeKillfeedEntry(entry) {
    if (!entry || !entry.parentNode) return;
    
    entry.classList.add('fade-out');
    
    setTimeout(() => {
        if (entry.parentNode) entry.parentNode.removeChild(entry);
        const index = killfeedEntries.indexOf(entry);
        if (index > -1) killfeedEntries.splice(index, 1);
    }, 300);
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// ==========================================
// SPECTATOR HUD - PROFESSIONAL STYLE
// ==========================================

function showSpectatorHUD(targetName, targetId, currentIndex, totalTargets) {
    const container = document.getElementById('spectator-hud');
    const nameElement = document.getElementById('spectator-target-name');
    const idElement = document.getElementById('spectator-target-id');
    const currentIndexElement = document.getElementById('spectator-current-index');
    const totalElement = document.getElementById('spectator-total');

    if (!container || !nameElement) return;

    nameElement.textContent = targetName;
    idElement.textContent = targetId;
    currentIndexElement.textContent = currentIndex;
    totalElement.textContent = totalTargets;

    container.classList.remove('hidden');
}

function hideSpectatorHUD() {
    const container = document.getElementById('spectator-hud');
    if (container) container.classList.add('hidden');
}

// ==========================================
// CLASSEMENT TOP 20
// ==========================================

const leaderboardBtn = document.getElementById('leaderboardBtn');
const leaderboardBack = document.getElementById('leaderboardBack');
const leaderboardPanel = document.getElementById('leaderboard-panel');
const tabletContent = document.querySelector('.tablet-content');

leaderboardBtn.addEventListener('click', () => {
    tabletContent.classList.add('hidden');
    leaderboardPanel.classList.remove('hidden');

    fetch(`https://${GetParentResourceName()}/getLeaderboard`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
});

leaderboardBack.addEventListener('click', () => {
    leaderboardPanel.classList.add('hidden');
    tabletContent.classList.remove('hidden');
});

function renderLeaderboard(players) {
    const list = document.getElementById('leaderboard-list');
    if (!list) return;

    if (!players || players.length === 0) {
        // Reset podium
        updatePodiumSlot('lb-slot-1', '---', 0);
        updatePodiumSlot('lb-slot-2', '---', 0);
        updatePodiumSlot('lb-slot-3', '---', 0);
        list.innerHTML = '<div class="lb-empty">Aucun joueur classe pour le moment</div>';
        return;
    }

    // Podium Top 3
    updatePodiumSlot('lb-slot-1', players[0] ? players[0].name : '---', players[0] ? players[0].kills : 0);
    updatePodiumSlot('lb-slot-2', players[1] ? players[1].name : '---', players[1] ? players[1].kills : 0);
    updatePodiumSlot('lb-slot-3', players[2] ? players[2].name : '---', players[2] ? players[2].kills : 0);

    // Liste #4+
    const rest = players.slice(3);

    if (rest.length === 0) {
        list.innerHTML = '<div class="lb-empty">Pas assez de joueurs pour la liste</div>';
        return;
    }

    list.innerHTML = rest.map((p, i) => {
        const rank = i + 4;
        const delay = Math.min(i * 0.04, 0.8);
        return `
            <div class="lb-row" style="animation-delay:${delay}s">
                <div class="lb-row-rank">#${rank}</div>
                <div class="lb-row-avatar"><i class="fas fa-user"></i></div>
                <div class="lb-row-name">${escapeHtml(p.name)}</div>
                <div class="lb-row-kills">${p.kills}<span class="lb-row-kills-label">KILLS</span></div>
            </div>
        `;
    }).join('');
}

function updatePodiumSlot(slotId, name, kills) {
    const slot = document.getElementById(slotId);
    if (!slot) return;

    const nameEl = slot.querySelector('.lb-podium-name');
    const killsEl = slot.querySelector('.lb-podium-kills');

    if (nameEl) nameEl.textContent = name ? escapeHtml(name) : '---';
    if (killsEl) killsEl.textContent = kills || 0;
}

// ==========================================
// TEAM LIST PANEL (/gteqlist toggle)
// ==========================================

function getStateClass(state) {
    switch (state) {
        case 'EN JEU': return 'state-en-jeu';
        case 'MORT': return 'state-mort';
        case 'SPEC': return 'state-spec';
        case 'PRET': return 'state-pret';
        default: return '';
    }
}

function renderTeamPlayers(containerId, players) {
    const el = document.getElementById(containerId);
    if (!el) return;

    if (!players || players.length === 0) {
        el.innerHTML = '<div style="padding:4px 6px;font-size:0.65rem;color:rgba(255,255,255,0.2);text-align:center;">Aucun joueur</div>';
        return;
    }

    el.innerHTML = players.map(p => `
        <div class="teamlist-player-row">
            <div>
                <span class="teamlist-player-id">ID:${p.id}</span>
                <span class="teamlist-player-name">${escapeHtml(p.name)}</span>
            </div>
            <span class="teamlist-player-state ${getStateClass(p.state)}">${p.state}</span>
        </div>
    `).join('');
}

function showTeamList(red, blue, lobby, gameInfo) {
    const panel = document.getElementById('teamlist-panel');
    if (!panel) return;

    panel.classList.remove('hidden');

    // Counts
    const redCount = document.getElementById('teamlist-red-count');
    const blueCount = document.getElementById('teamlist-blue-count');
    const lobbyCount = document.getElementById('teamlist-lobby-count');

    if (redCount) redCount.textContent = (red || []).length;
    if (blueCount) blueCount.textContent = (blue || []).length;
    if (lobbyCount) lobbyCount.textContent = (lobby || []).length;

    // Players
    renderTeamPlayers('teamlist-red-players', red);
    renderTeamPlayers('teamlist-blue-players', blue);

    // Game info
    const gameInfoEl = document.getElementById('teamlist-game-info');
    if (gameInfoEl) {
        if (gameInfo) {
            gameInfoEl.textContent = `R${gameInfo.round}/${gameInfo.maxRounds} | ${gameInfo.scoreRed}-${gameInfo.scoreBlue} | ${gameInfo.mapName}`;
        } else {
            gameInfoEl.textContent = 'EN ATTENTE';
        }
    }

    // Lobby section visibility
    const lobbySection = document.getElementById('teamlist-lobby-section');
    if (lobbySection) {
        lobbySection.style.display = (lobby && lobby.length > 0) ? 'block' : 'none';
    }
}

function hideTeamList() {
    const panel = document.getElementById('teamlist-panel');
    if (panel) panel.classList.add('hidden');
}