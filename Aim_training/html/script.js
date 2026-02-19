// Éléments du DOM
const mainMenu = document.getElementById('mainMenu');
const leaderboardMenu = document.getElementById('leaderboardMenu');
const gameHUD = document.getElementById('gameHUD');
const killNotif = document.getElementById('killNotif');

// État actuel
let currentMenu = null;

// Nom de la ressource (fixe)
const RESOURCE_NAME = 'aim_training';

// Écouteur de messages depuis FiveM
window.addEventListener('message', (event) => {
    const data = event.data;

    switch (data.action) {
        case 'openMainMenu':
            openMainMenu();
            break;

        case 'openLeaderboard':
            openLeaderboard(data.leaderboard);
            break;

        case 'closeMenu':
            closeAllMenus();
            break;

        case 'showHUD':
            showHUD();
            break;

        case 'hideHUD':
            hideHUD();
            break;

        case 'updateHUD':
            updateHUD(data.time, data.kills);
            break;

        case 'showKillNotif':
            showKillNotification(data.kills);
            break;
    }
});

// Ouvrir le menu principal
function openMainMenu() {
    closeAllMenus();
    mainMenu.classList.remove('hidden');
    currentMenu = 'main';
}

// Ouvrir le classement
function openLeaderboard(leaderboard) {
    closeAllMenus();
    const content = document.getElementById('leaderboardContent');
    content.innerHTML = '';

    if (leaderboard.length === 0) {
        content.innerHTML = '<div class="no-scores">Aucun score enregistré</div>';
    } else {
        leaderboard.forEach((entry, index) => {
            const rank = index + 1;
            const rankClass = rank <= 3 ? `rank-${rank}` : '';
            const medal = rank === 1 ? '🥇' : rank === 2 ? '🥈' : rank === 3 ? '🥉' : rank + '.';

            const item = document.createElement('div');
            item.className = `leaderboard-item ${rankClass}`;
            item.innerHTML = `
                <div class="leaderboard-rank">${medal}</div>
                <div class="leaderboard-name">${entry.name}</div>
                <div class="leaderboard-kills">${entry.kills} kills</div>
            `;
            content.appendChild(item);
        });
    }

    leaderboardMenu.classList.remove('hidden');
    currentMenu = 'leaderboard';
}

// Fermer tous les menus
function closeAllMenus() {
    mainMenu.classList.add('hidden');
    leaderboardMenu.classList.add('hidden');
    currentMenu = null;
}

// Afficher le HUD
function showHUD() {
    gameHUD.classList.remove('hidden');
}

// Cacher le HUD
function hideHUD() {
    gameHUD.classList.add('hidden');
}

// Mettre à jour le HUD
function updateHUD(time, kills) {
    document.getElementById('timeLeft').textContent = time + 's';
    document.getElementById('killCount').textContent = kills;
}

// Afficher notification de kill
function showKillNotification(kills) {
    killNotif.classList.remove('hidden');

    setTimeout(() => {
        killNotif.classList.add('hidden');
    }, 1000);
}

// Envoyer un callback à FiveM
function sendCallback(action, data = {}) {
    fetch(`https://${RESOURCE_NAME}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    }).catch(err => {
        console.error('Callback error:', action, err);
    });
}

// Événements de clic sur les items du menu principal
document.querySelectorAll('#mainMenu .menu-item').forEach(item => {
    item.addEventListener('click', () => {
        const action = item.getAttribute('data-action');

        if (action === 'start') {
            sendCallback('startGame');
        } else if (action === 'leaderboard') {
            sendCallback('getLeaderboard');
        } else if (action === 'close') {
            sendCallback('closeMenu');
        }
    });
});

// Événement de clic sur le bouton retour
document.querySelector('.back-button').addEventListener('click', () => {
    sendCallback('backToMain');
});

// Échappement avec ESC
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && currentMenu) {
        sendCallback('closeMenu');
    }
});
