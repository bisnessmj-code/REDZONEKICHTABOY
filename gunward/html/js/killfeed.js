/* ============================================================
   KILL FEED — Style Redzone (repris à l'identique)
   ============================================================ */

const KILLFEED_MAX_ENTRIES  = 6;
const KILLFEED_DISPLAY_TIME = 6000;

function addKillFeed(data) {
    const container = document.getElementById('killfeed-container');
    if (!container) return;

    const killerName = data.killerName || 'Inconnu';
    const killerId   = data.killerId   || '?';
    const victimName = data.victimName || 'Inconnu';
    const victimId   = data.victimId   || '?';

    const killRow = document.createElement('div');
    killRow.className = 'kill-row';
    killRow.innerHTML =
        '<div class="killfeed-player-box killfeed-killer-box">' +
            '<span class="killfeed-player-id">ID:' + killerId + '</span>' +
            '<span class="killfeed-killer-name">' + escapeHtml(killerName) + '</span>' +
        '</div>' +
        '<div class="killfeed-action-tag">\u00c0 TU\u00c9</div>' +
        '<div class="killfeed-player-box">' +
            '<span class="killfeed-victim-name">' + escapeHtml(victimName) + '</span>' +
            '<span class="killfeed-player-id">ID:' + victimId + '</span>' +
        '</div>';

    // Nouveau kill en haut
    container.prepend(killRow);

    // Supprimer les entrées en excès avec animation
    while (container.children.length > KILLFEED_MAX_ENTRIES) {
        const last = container.lastElementChild;
        if (last) {
            last.classList.add('killfeed-exit');
            setTimeout(function () {
                if (last.parentNode) last.remove();
            }, 400);
        }
    }

    // Auto-suppression après délai
    setTimeout(function () {
        if (killRow.parentNode) {
            killRow.classList.add('killfeed-exit');
            setTimeout(function () {
                if (killRow.parentNode) killRow.remove();
            }, 400);
        }
    }, KILLFEED_DISPLAY_TIME);
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = String(text);
    return div.innerHTML;
}

window.addEventListener('message', function (event) {
    if (event.data.action === 'addKillFeed') {
        addKillFeed(event.data);
    }
});
