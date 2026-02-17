(function () {
    const container = document.getElementById('team-select');
    const titleEl = document.getElementById('title');
    const grid = document.getElementById('teams-grid');

    function rgbToStr(c) {
        return `rgb(${c.r}, ${c.g}, ${c.b})`;
    }

    function rgbaToStr(c, a) {
        return `rgba(${c.r}, ${c.g}, ${c.b}, ${a})`;
    }

    function show(teams, title) {
        if (title) titleEl.textContent = title;

        grid.innerHTML = '';

        teams.forEach(function (team) {
            const isFull = team.current >= team.max;
            const pct = Math.min((team.current / team.max) * 100, 100);

            const card = document.createElement('div');
            card.className = 'team-card' + (isFull ? ' full' : '');
            card.style.setProperty('--team-color', rgbToStr(team.color));
            card.style.setProperty('--team-glow', rgbaToStr(team.color, 0.3));

            card.innerHTML =
                '<div class="team-name">' + team.label + '</div>' +
                '<div class="team-count"><span>' + team.current + '</span> / ' + team.max + ' joueurs</div>' +
                '<div class="team-bar"><div class="team-bar-fill" style="width:' + pct + '%"></div></div>' +
                '<button class="team-btn">' + (isFull ? 'COMPLET' : 'REJOINDRE') + '</button>';

            if (!isFull) {
                card.addEventListener('click', function () {
                    fetch('https://gunward/selectTeam', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ team: team.name })
                    });
                });
            }

            grid.appendChild(card);
        });

        container.classList.remove('hidden');
    }

    function hide() {
        container.classList.add('hidden');
    }

    window.addEventListener('message', function (event) {
        var data = event.data;

        if (data.action === 'openTeamSelect') {
            show(data.teams, data.title);
        } else if (data.action === 'closeUI') {
            hide();
        }
    });

    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') {
            hide();
            fetch('https://gunward/closeUI', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
        }
    });
})();
