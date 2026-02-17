Config.Teams = {
    ['RED'] = {
        label = 'Red Team',
        color = {r = 224, g = 50, b = 50},
        blipColor = 1,
        blipSprite = 491,
        spawn = vector4(-5758.0, -880.0, 502.49, 180.0),
        maxPlayers = Config.MaxPlayersPerTeam,
    },
    ['BLUE'] = {
        label = 'Blue Team',
        color = {r = 50, g = 100, b = 224},
        blipColor = 3,
        blipSprite = 491,
        spawn = vector4(-5830.0, -880.0, 502.49, 0.0),
        maxPlayers = Config.MaxPlayersPerTeam,
    },
    ['GREEN'] = {
        label = 'Green Team',
        color = {r = 50, g = 200, b = 80},
        blipColor = 2,
        blipSprite = 491,
        spawn = vector4(-5758.0, -930.0, 502.49, 90.0),
        maxPlayers = Config.MaxPlayersPerTeam,
    },
    ['BLACK'] = {
        label = 'Black Team',
        color = {r = 40, g = 40, b = 40},
        blipColor = 0,
        blipSprite = 491,
        spawn = vector4(-5830.0, -930.0, 502.49, 270.0),
        maxPlayers = Config.MaxPlayersPerTeam,
    },
}

-- Ordre d'affichage dans l'UI
Config.TeamOrder = {'RED', 'BLUE', 'GREEN', 'BLACK'}
