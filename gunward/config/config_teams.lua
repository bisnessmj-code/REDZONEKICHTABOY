Config.Teams = {
    ['RED'] = {
        label = 'Red Team',
        color = {r = 224, g = 50, b = 50},
        blipColor = 1,
        blipSprite = 491,
        spawn = vector4(96.909890, -1933.569214, 20.787598, 45.354328),
        maxPlayers = Config.MaxPlayersPerTeam,
    },
    ['BLUE'] = {
        label = 'Blue Team',
        color = {r = 50, g = 100, b = 224},
        blipColor = 3,
        blipSprite = 491,
        spawn = vector4(305.380218, -2015.406616, 20.180908, 45.354328),
        maxPlayers = Config.MaxPlayersPerTeam,
    },
    ['GREEN'] = {
        label = 'Green Team',
        color = {r = 50, g = 200, b = 80},
        blipColor = 2,
        blipSprite = 491,
        spawn = vector4(-99.481316, -1587.362670, 31.436646, 308.976380),
        maxPlayers = Config.MaxPlayersPerTeam,
    },
    ['BLACK'] = {
        label = 'Black Team',
        color = {r = 40, g = 40, b = 40},
        blipColor = 0,
        blipSprite = 491,
        spawn = vector4(462.514282, -1521.665894, 29.246094, 113.385826),
        maxPlayers = Config.MaxPlayersPerTeam,
    },
}

-- Ordre d'affichage dans l'UI
Config.TeamOrder = {'RED', 'BLUE', 'GREEN', 'BLACK'}
