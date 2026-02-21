/* ============================================================
   GUNWARD UI — Main NUI Script
   Event-driven, no polling timers.
   Receives data from Lua via SendNUIMessage.
   ============================================================ */
(function () {
    'use strict';

    /* ── HELPERS ── */
    function rgbToCss(c)       { return 'rgb(' + c.r + ',' + c.g + ',' + c.b + ')'; }
    function rgbToRgba(c, a)   { return 'rgba(' + c.r + ',' + c.g + ',' + c.b + ',' + a + ')'; }
    function fmtMoney(v)       { return '$' + Number(v || 0).toLocaleString('fr-FR'); }
    function fmtKD(k, d)       { return (k / Math.max(d, 1)).toFixed(2); }
    function initials(name)    { return (name || '?').substring(0, 2).toUpperCase(); }
    function padZero(n)        { return String(n).padStart(2, '0'); }

    /* ── DOM REFS ── */
    var ui         = document.getElementById('gunward-ui');
    var timerEl    = document.getElementById('gw-timer-value');
    var tMin       = document.getElementById('gw-t-min');
    var tSec       = document.getElementById('gw-t-sec');
    var zoneLabel  = document.getElementById('gw-zone-label');
    var zoneMLabel = document.getElementById('gw-zone-map-label');
    var playerCnt  = document.getElementById('gw-player-count');
    var teamsWrap  = document.getElementById('gw-teams-wrap');
    var lbBody     = document.getElementById('gw-lb-body');
    var podiumEl   = document.getElementById('gw-podium');
    var pAvatar    = document.getElementById('gw-p-avatar');
    var pName      = document.getElementById('gw-p-name');
    var pKills     = document.getElementById('gw-p-kills');
    var pDeaths    = document.getElementById('gw-p-deaths');
    var pKD        = document.getElementById('gw-p-kd');
    var pPos       = document.getElementById('gw-p-position');
    var pBank      = document.getElementById('gw-p-bank');

    /* ── STATE ── */
    var timerInterval = null;
    var timerSec      = 0;
    var myIdentifier  = null;
    var cachedLB      = [];      // sorted leaderboard rows cached for podium updates

    /* ── SCALE UI TO VIEWPORT ── */
    function scaleUI() {
        if (!ui) return;
        var s = Math.min(window.innerWidth / 1920, window.innerHeight / 1080);
        ui.style.transform = 'scale(' + s + ')';
    }
    window.addEventListener('resize', scaleUI);
    scaleUI();

    /* ── TIMER ── */
    function startTimer(seconds) {
        timerSec = Math.max(0, Math.floor(seconds));
        if (timerInterval) clearInterval(timerInterval);
        renderTimer();
        timerInterval = setInterval(function () {
            if (timerSec > 0) timerSec--;
            renderTimer();
        }, 1000);
    }

    function renderTimer() {
        var m = padZero(Math.floor(timerSec / 60));
        var s = padZero(timerSec % 60);
        if (tMin) tMin.textContent = m;
        if (tSec) tSec.textContent = s;
        if (timerEl) {
            timerEl.className = 'gw-timer-value' + (timerSec <= 60 ? ' warning' : '');
        }
    }

    /* ── ZONE LABEL ── */
    function setZoneLabel(label) {
        var txt = label ? '[ ' + label + ' ]' : '[ — ]';
        if (zoneLabel)  zoneLabel.textContent  = txt;
        if (zoneMLabel) zoneMLabel.textContent = txt;
    }

    /* ── TEAM CARDS ── */
    function renderTeams(teams) {
        if (!teamsWrap || !teams || !teams.length) return;
        teamsWrap.innerHTML = '';
        teams.forEach(function (t) {
            var col  = rgbToCss(t.color);
            var glow = rgbToRgba(t.color, 0.12);
            var pct  = Math.min((t.current / t.max) * 100, 100).toFixed(0);
            var full = t.current >= t.max;

            var card = document.createElement('div');
            card.className = 'gw-team-card' + (full ? ' full' : '');
            card.style.setProperty('--tc', col);
            card.style.setProperty('--tg', glow);
            card.innerHTML =
                '<div>' +
                  '<div class="gw-team-name-lbl">' + escHtml(t.label) + '</div>' +
                  '<div class="gw-team-count">' + t.current + '</div>' +
                  '<div class="gw-team-max">/ ' + t.max + ' OPÉRATEURS</div>' +
                  '<div class="gw-cap-bar-label">' +
                    '<span>CAPACITÉ</span><span>' + pct + '%</span>' +
                  '</div>' +
                  '<div class="gw-cap-bar-track">' +
                    '<div class="gw-cap-bar-fill" style="width:' + pct + '%"></div>' +
                  '</div>' +
                '</div>' +
                '<button class="gw-join-btn"' + (full ? ' disabled' : '') + '>' +
                  (full ? 'COMPLET' : 'REJOINDRE') +
                '</button>';

            if (!full) {
                var btn = card.querySelector('.gw-join-btn');
                btn.addEventListener('click', function (e) {
                    e.stopPropagation();
                    sendJoinTeam(t.name);
                });
            }
            teamsWrap.appendChild(card);
        });
    }

    function sendJoinTeam(name) {
        fetch('https://gunward/selectTeam', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ team: name })
        });
    }

    /* ── LEADERBOARD ── */
    function renderLeaderboard(rows, myIdent) {
        if (!lbBody) return;
        cachedLB = rows || [];
        lbBody.innerHTML = '';

        if (!cachedLB.length) {
            lbBody.innerHTML = '<tr><td colspan="6"><div class="gw-empty-lb">AUCUNE STATISTIQUE DISPONIBLE</div></td></tr>';
            renderPodium([]);
            return;
        }

        cachedLB.forEach(function (row, i) {
            var kd      = row.kd !== undefined ? parseFloat(row.kd) : parseFloat(fmtKD(row.kills, row.deaths));
            var kdStr   = kd.toFixed(2);
            var isMe    = myIdent && row.identifier === myIdent;
            var rank    = i + 1;
            var rankCls = rank === 1 ? 'r1' : rank === 2 ? 'r2' : rank === 3 ? 'r3' : '';
            var kdCls   = kd >= 1.5 ? 'gw-accent-val' : 'gw-muted-val';

            var tr = document.createElement('tr');
            if (isMe) tr.className = 'gw-me';
            tr.setAttribute('data-ident', row.identifier);
            tr.innerHTML =
                '<td><span class="gw-rank-num ' + rankCls + '">' + rank + '</span></td>' +
                '<td><span class="gw-player-name">' + escHtml(row.name || row.identifier) + '</span></td>' +
                '<td class="gw-kills-val">' + (row.kills || 0) + '</td>' +
                '<td class="gw-muted-val">' + (row.deaths || 0) + '</td>' +
                '<td class="' + kdCls + '">' + kdStr + '</td>' +
                '<td class="gw-accent-val">' + fmtMoney(row.bank) + '</td>';
            lbBody.appendChild(tr);
        });

        renderPodium(cachedLB);
    }

    /* ── PODIUM TOP 3 (sorted by kills) ── */
    function renderPodium(rows) {
        if (!podiumEl) return;
        var sorted = (rows || []).slice().sort(function (a, b) {
            var killsDiff = (b.kills || 0) - (a.kills || 0);
            if (killsDiff !== 0) return killsDiff;
            var kdA = a.kd !== undefined ? parseFloat(a.kd) : parseFloat(fmtKD(a.kills, a.deaths));
            var kdB = b.kd !== undefined ? parseFloat(b.kd) : parseFloat(fmtKD(b.kills, b.deaths));
            return kdB - kdA;
        });
        var top3    = sorted.slice(0, 3);
        var classes = ['gw-gold', 'gw-silver', 'gw-bronze'];

        if (!top3.length) {
            podiumEl.innerHTML = '<div class="gw-empty-lb">AUCUN JOUEUR</div>';
            return;
        }

        podiumEl.innerHTML = '';
        top3.forEach(function (row, i) {
            var kd  = row.kd !== undefined ? parseFloat(row.kd).toFixed(2) : fmtKD(row.kills, row.deaths);
            var div = document.createElement('div');
            div.className = 'gw-podium-row ' + classes[i];
            div.innerHTML =
                '<div class="gw-podium-rank">0' + (i + 1) + '</div>' +
                '<div class="gw-podium-name">' + escHtml(row.name || row.identifier) + '</div>' +
                '<div class="gw-podium-kd">K/D ' + kd + '</div>';
            podiumEl.appendChild(div);
        });
    }

    /* ── PARTIAL STATS UPDATE (after a kill) ── */
    function applyStatsUpdate(updatedPlayers) {
        if (!updatedPlayers || !updatedPlayers.length) return;

        updatedPlayers.forEach(function (updated) {
            // Update cached leaderboard row
            var found = false;
            for (var i = 0; i < cachedLB.length; i++) {
                if (cachedLB[i].identifier === updated.identifier) {
                    cachedLB[i] = updated;
                    found = true;
                    break;
                }
            }
            if (!found) cachedLB.push(updated);

            // Update DOM row if visible
            if (!lbBody) return;
            var tr = lbBody.querySelector('tr[data-ident="' + updated.identifier + '"]');
            if (!tr) return;

            var kd    = updated.kd !== undefined ? parseFloat(updated.kd) : parseFloat(fmtKD(updated.kills, updated.deaths));
            var kdStr = kd.toFixed(2);
            var kdCls = kd >= 1.5 ? 'gw-accent-val' : 'gw-muted-val';
            var cells = tr.querySelectorAll('td');
            if (cells[2]) cells[2].textContent = updated.kills || 0;
            if (cells[3]) cells[3].textContent = updated.deaths || 0;
            if (cells[4]) { cells[4].textContent = kdStr; cells[4].className = kdCls; }
            if (cells[5]) cells[5].textContent = fmtMoney(updated.bank);
        });

        // Re-render podium from updated cache
        renderPodium(cachedLB);

        // Update my profile if I'm in the updated set
        if (myIdentifier) {
            var myRow = null;
            for (var i = 0; i < cachedLB.length; i++) {
                if (cachedLB[i].identifier === myIdentifier) { myRow = cachedLB[i]; break; }
            }
            if (myRow) {
                // Recalculate my position from sorted cache
                var sorted = cachedLB.slice().sort(function (a, b) {
                    var killsDiff = (b.kills || 0) - (a.kills || 0);
                    if (killsDiff !== 0) return killsDiff;
                    var kdA = a.kd !== undefined ? parseFloat(a.kd) : parseFloat(fmtKD(a.kills, a.deaths));
                    var kdB = b.kd !== undefined ? parseFloat(b.kd) : parseFloat(fmtKD(b.kills, b.deaths));
                    return kdB - kdA;
                });
                var pos = null;
                for (var j = 0; j < sorted.length; j++) {
                    if (sorted[j].identifier === myIdentifier) { pos = j + 1; break; }
                }
                updateProfile(myRow, pos);
            }
        }
    }

    /* ── PROFILE PANEL ── */
    function updateProfile(stats, position) {
        if (!stats) return;
        var name = stats.name || stats.identifier || '—';
        var kd   = stats.kd !== undefined
            ? parseFloat(stats.kd).toFixed(2)
            : fmtKD(stats.kills || 0, stats.deaths || 0);

        if (pAvatar) pAvatar.textContent = initials(name);
        if (pName)   pName.textContent   = name;
        if (pKills)  pKills.textContent  = stats.kills  || 0;
        if (pDeaths) pDeaths.textContent = stats.deaths || 0;
        if (pKD)     pKD.textContent     = kd;
        if (pPos)    pPos.textContent    = position !== null && position !== undefined ? '#' + position : '#—';
        if (pBank)   pBank.textContent   = fmtMoney(stats.bank);
    }

    /* ── ESCAPE ── */
    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape' && ui && ui.classList.contains('gw-visible')) {
            closeUI();
            fetch('https://gunward/closeUI', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
        }
    });

    /* ── OPEN / CLOSE ── */
    function openUI(data) {
        if (!ui) return;

        myIdentifier = data.myIdent || null;

        // Teams
        renderTeams(data.teams || []);

        // Leaderboard + profile
        renderLeaderboard(data.leaderboard || [], myIdentifier);
        updateProfile(data.myStats, data.myPosition);

        // Player count
        if (playerCnt) playerCnt.textContent = data.serverPlayers || 0;

        // Timer + zone label
        var ti = data.timerInfo || {};
        setZoneLabel(ti.zoneLabel || '');
        startTimer(ti.timeRemaining || 0);

        // Show + switch to selection tab
        ui.classList.add('gw-visible');
        gwSwitchTab('selection');
        scaleUI();
    }

    function closeUI() {
        if (!ui) return;
        ui.classList.remove('gw-visible');
        if (timerInterval) { clearInterval(timerInterval); timerInterval = null; }
    }

    /* ── TAB SWITCH (exposed globally for onclick) ── */
    function gwSwitchTab(id) {
        document.querySelectorAll('#gunward-ui .gw-nav-tab').forEach(function (t) {
            t.classList.remove('active');
        });
        document.querySelectorAll('#gunward-ui .gw-page').forEach(function (p) {
            p.classList.remove('active');
        });
        var tab  = document.getElementById('gw-tab-' + id);
        var page = document.getElementById('gw-page-' + id);
        if (tab)  tab.classList.add('active');
        if (page) page.classList.add('active');
    }
    window.gwSwitchTab = gwSwitchTab;

    /* ── XSS PROTECTION ── */
    function escHtml(str) {
        return String(str || '')
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    /* ── MESSAGE HANDLER ── */
    window.addEventListener('message', function (e) {
        var d = e.data;
        if (!d || !d.action) return;

        switch (d.action) {

            /* Main open — sends all data in one shot */
            case 'openGunwardUI':
                openUI(d);
                break;

            /* Close */
            case 'closeUI':
                closeUI();
                break;

            /* Update team counts while UI is open */
            case 'updateTeams':
                if (d.teams) renderTeams(d.teams);
                break;

            /* Timer tick (from KOTH score update every 3s) */
            case 'updateTimer':
                if (d.timeRemaining !== undefined) startTimer(d.timeRemaining);
                if (d.zoneLabel !== undefined) setZoneLabel(d.zoneLabel);
                break;

            /* Server player count update */
            case 'updatePlayerCount':
                if (playerCnt && d.count !== undefined) playerCnt.textContent = d.count;
                break;

            /* Partial stats update after a kill (only changed players) */
            case 'updateStats':
                applyStatsUpdate(d.updatedPlayers);
                break;

            default:
                break;
        }
    });

})();
