/* ============================================================
   KOTH ANNOUNCE - Redzone Style
   ============================================================ */

let announceTimeout = null;
let announceHideTimeout = null;

function showAnnounce(message, duration) {
    duration = duration || 5000;

    const container = document.getElementById('announce-container');
    if (!container) return;

    // Clear previous timeouts
    if (announceTimeout) clearTimeout(announceTimeout);
    if (announceHideTimeout) clearTimeout(announceHideTimeout);

    // Build HTML
    container.innerHTML = `
        <div class="announce-box">
            <div class="announce-neon-top"></div>
            <div class="announce-neon-bottom"></div>
            <div class="announce-label">KING OF THE HILL</div>
            <div class="announce-message">${escapeHtmlAnnounce(message)}</div>
            <div class="announce-timer-bar"></div>
        </div>
    `;

    const box = container.querySelector('.announce-box');
    const timerBar = container.querySelector('.announce-timer-bar');

    // Show with animation
    requestAnimationFrame(() => {
        box.classList.add('visible');

        // Animate timer bar
        if (timerBar) {
            timerBar.style.transition = 'none';
            timerBar.style.width = '100%';
            requestAnimationFrame(() => {
                timerBar.style.transition = `width ${duration}ms linear`;
                timerBar.style.width = '0%';
            });
        }
    });

    // Hide after duration
    announceTimeout = setTimeout(() => {
        box.classList.remove('visible');

        announceHideTimeout = setTimeout(() => {
            container.innerHTML = '';
        }, 500);
    }, duration);
}

function escapeHtmlAnnounce(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// NUI message listener
window.addEventListener('message', function(event) {
    if (event.data.action === 'showAnnounce') {
        showAnnounce(event.data.message, event.data.duration);
    }
});
