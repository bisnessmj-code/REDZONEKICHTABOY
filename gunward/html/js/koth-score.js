/* ============================================================
   KOTH SCOREBOARD - Bottom Right Panel
   ============================================================ */

let previousPoints = {};

function formatTime(seconds) {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return m + ':' + (s < 10 ? '0' : '') + s;
}

function rgbToString(color) {
    return 'rgb(' + color.r + ',' + color.g + ',' + color.b + ')';
}

function rgbToAlpha(color, a) {
    return 'rgba(' + color.r + ',' + color.g + ',' + color.b + ',' + a + ')';
}

function buildScoreboard(scores, timeRemaining, zoneLabel) {
    const board = document.getElementById('koth-scoreboard');
    if (!board) return;

    // Find max points for bar width
    let maxPoints = 1;
    for (const team of scores) {
        if (team.points > maxPoints) maxPoints = team.points;
    }

    // Sort by points descending for display
    const sorted = [...scores].sort((a, b) => b.points - a.points);

    let html = '';

    // Header
    html += '<div class="koth-header">';
    html += '  <span class="koth-title">KOTH</span>';
    html += '  <span class="koth-timer" id="koth-timer">' + formatTime(timeRemaining) + '</span>';
    html += '</div>';

    // Zone label
    if (zoneLabel) {
        html += '<div class="koth-zone-label">' + escapeHtmlScore(zoneLabel) + '</div>';
    }

    // Teams
    html += '<div class="koth-teams">';
    for (const team of sorted) {
        const holderClass = team.isHolder ? ' is-holder' : '';
        const barWidth = maxPoints > 0 ? Math.round((team.points / maxPoints) * 100) : 0;
        const colorStr = rgbToString(team.color);

        // Check if points changed for bump animation
        const prevPts = previousPoints[team.name] || 0;
        const bumpClass = (team.points > prevPts) ? ' bump' : '';

        html += '<div class="koth-team-row' + holderClass + '">';
        html += '  <div class="koth-team-left">';
        html += '    <div class="koth-team-dot" style="background:' + colorStr + ';color:' + colorStr + '"></div>';
        html += '    <span class="koth-team-name">' + escapeHtmlScore(team.label) + '</span>';
        html += '  </div>';
        html += '  <span class="koth-team-points' + bumpClass + '">' + team.points + '</span>';
        html += '  <div class="koth-team-bar" style="width:' + barWidth + '%;background:' + rgbToAlpha(team.color, 0.3) + '"></div>';
        html += '</div>';
    }
    html += '</div>';

    board.innerHTML = html;
    board.classList.add('visible');

    // Store points for next comparison
    for (const team of scores) {
        previousPoints[team.name] = team.points;
    }
}

function updateScores(scores, timeRemaining) {
    const board = document.getElementById('koth-scoreboard');
    if (!board || !board.classList.contains('visible')) return;

    // Update timer
    const timer = document.getElementById('koth-timer');
    if (timer) {
        timer.textContent = formatTime(timeRemaining);
    }

    // Find max points
    let maxPoints = 1;
    for (const team of scores) {
        if (team.points > maxPoints) maxPoints = team.points;
    }

    // Sort by points descending
    const sorted = [...scores].sort((a, b) => b.points - a.points);

    // Rebuild teams section
    const teamsContainer = board.querySelector('.koth-teams');
    if (!teamsContainer) {
        buildScoreboard(scores, timeRemaining, null);
        return;
    }

    let html = '';
    for (const team of sorted) {
        const holderClass = team.isHolder ? ' is-holder' : '';
        const barWidth = maxPoints > 0 ? Math.round((team.points / maxPoints) * 100) : 0;
        const colorStr = rgbToString(team.color);

        const prevPts = previousPoints[team.name] || 0;
        const bumpClass = (team.points > prevPts) ? ' bump' : '';

        html += '<div class="koth-team-row' + holderClass + '">';
        html += '  <div class="koth-team-left">';
        html += '    <div class="koth-team-dot" style="background:' + colorStr + ';color:' + colorStr + '"></div>';
        html += '    <span class="koth-team-name">' + escapeHtmlScore(team.label) + '</span>';
        html += '  </div>';
        html += '  <span class="koth-team-points' + bumpClass + '">' + team.points + '</span>';
        html += '  <div class="koth-team-bar" style="width:' + barWidth + '%;background:' + rgbToAlpha(team.color, 0.3) + '"></div>';
        html += '</div>';
    }
    teamsContainer.innerHTML = html;

    // Store points
    for (const team of scores) {
        previousPoints[team.name] = team.points;
    }
}

function hideScoreboard() {
    const board = document.getElementById('koth-scoreboard');
    if (board) {
        board.classList.remove('visible');
        setTimeout(() => { board.innerHTML = ''; }, 400);
    }
    previousPoints = {};
}

function escapeHtmlScore(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// NUI listener
window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.action === 'kothShowScoreboard') {
        buildScoreboard(data.scores || [], data.timeRemaining || 0, data.zoneLabel || '');
    }

    if (data.action === 'kothUpdateScores') {
        updateScores(data.scores || [], data.timeRemaining || 0);
    }

    if (data.action === 'kothHideScoreboard') {
        hideScoreboard();
    }
});
