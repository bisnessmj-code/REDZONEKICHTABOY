/* ============================================================
   KILL FEED — Black Ops 2 Style
   Logo + Killer › Victim, discreet, top-right
   ============================================================ */

const KILLFEED_MAX      = 6;
const KILLFEED_DURATION = 6000;

function addKillFeed(data) {
    const container = document.getElementById('killfeed-container');
    if (!container) return;

    const row = document.createElement('div');
    row.className = 'kill-row';

    row.innerHTML =
        '<img class="kf-logo" src="assets/logo.png" alt="" onerror="this.style.display=\'none\'">' +
        '<span class="killfeed-killer-name">' + escapeHtml(data.killerName) + '</span>' +
        '<span class="killfeed-sep">&#8250;</span>' +
        '<span class="killfeed-victim-name">' + escapeHtml(data.victimName) + '</span>';

    container.appendChild(row);

    // Remove oldest entry if over limit
    while (container.children.length > KILLFEED_MAX) {
        container.removeChild(container.children[0]);
    }

    // Auto-remove after duration
    setTimeout(function () {
        row.classList.add('removing');
        setTimeout(function () {
            if (row.parentNode) row.parentNode.removeChild(row);
        }, 250);
    }, KILLFEED_DURATION);
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// NUI message listener
window.addEventListener('message', function (event) {
    if (event.data.action === 'addKillFeed') {
        addKillFeed(event.data);
    }
});
