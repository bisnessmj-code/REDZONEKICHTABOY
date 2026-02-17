Config.Roles = {
    ['admin'] = {ace = 'gunward.admin'},
    ['staff'] = {ace = 'gunward.staff'},
    ['organisateur'] = {ace = 'gunward.orga'},
    ['responsable'] = {ace = 'gunward.responsable'},
}

Config.Commands = {
    -- Joueur
    {command = 'gw_leave', label = 'Quitter Gunward', roles = {}, side = 'client'},
    {command = 'gw_team', label = 'Voir son équipe', roles = {}, side = 'client'},

    -- Staff
    {command = 'gw_kick', label = 'Kick un joueur', roles = {'admin', 'staff', 'responsable'}, side = 'server', args = {{name = 'id', help = 'ID du joueur', type = 'number'}}},
    {command = 'gw_kickall', label = 'Kick tous les joueurs', roles = {'admin', 'staff'}, side = 'server'},

    -- Organisateur
    {command = 'gw_start', label = 'Démarrer une partie', roles = {'admin', 'organisateur'}, side = 'server'},
    {command = 'gw_stop', label = 'Arrêter la partie', roles = {'admin', 'organisateur'}, side = 'server'},
    {command = 'gw_move', label = 'Déplacer un joueur', roles = {'admin', 'organisateur'}, side = 'server', args = {{name = 'id', help = 'ID du joueur', type = 'number'}, {name = 'team', help = 'Nom équipe (RED/BLUE/GREEN/BLACK)', type = 'string'}}},

    -- Admin
    {command = 'gw_reset', label = 'Reset complet', roles = {'admin'}, side = 'server'},
    {command = 'gw_debug', label = 'Toggle debug', roles = {'admin'}, side = 'server'},
    {command = 'gw_tp', label = 'TP au spawn équipe', roles = {'admin'}, side = 'server', args = {{name = 'team', help = 'Nom équipe (RED/BLUE/GREEN/BLACK)', type = 'string'}}},
    {command = 'gw_setteam', label = 'Forcer équipe joueur', roles = {'admin'}, side = 'server', args = {{name = 'id', help = 'ID du joueur', type = 'number'}, {name = 'team', help = 'Nom équipe', type = 'string'}}},
}
