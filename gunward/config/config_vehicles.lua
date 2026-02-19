Config.Vehicles = {
    -- Gratuits
    {model = 'primo2',    label = 'Primo Custom',    price = 0},
    {model = 'jubilee',   label = 'Jubilee',         price = 0},
    -- Payants
    {model = 'sultan',    label = 'Sultan',           price = 500},
    {model = 'buffalo',   label = 'Buffalo',          price = 600},
    {model = 'elegy2',    label = 'Elegy Retro',      price = 800},
    {model = 'baller3',   label = 'Baller LE',        price = 800},
    {model = 'banshee',   label = 'Banshee',          price = 1000},
    {model = 'schafter2', label = 'Schafter V12',     price = 1000},
    {model = 'comet2',    label = 'Comet SR',         price = 1200},
    {model = 'jester',    label = 'Jester',           price = 1500},
    {model = 'kuruma2',   label = 'Kuruma Blinde',    price = 1800},
    {model = 'insurgent', label = 'Insurgent',        price = 2000},
    {model = 'zentorno',  label = 'Zentorno',         price = 2000},
    {model = 'turismor',  label = 'Turismo R',        price = 2500},
    {model = 'entityxf',  label = 'Entity XF',        price = 3000},
    {model = 'osiris',    label = 'Osiris',           price = 3500},
    {model = 't20',       label = 'T20',              price = 4000},
}

-- Couleurs véhicule par équipe (GTA color index)
Config.TeamVehicleColors = {
    ['RED']   = {primary = 27,  secondary = 27},   -- Rouge
    ['BLUE']  = {primary = 64,  secondary = 64},   -- Bleu
    ['GREEN'] = {primary = 55,  secondary = 55},   -- Vert
    ['BLACK'] = {primary = 0,   secondary = 0},    -- Noir
}

-- Position de spawn des véhicules par équipe
Config.VehicleSpawnPoints = {
    ['RED']   = vector4(86.967034, -1926.778076, 20.770752, 39.685040),
    ['BLUE']  = vector4(301.727478, -2012.676880, 20.062988, 42.519684),
    ['GREEN'] = vector4(-91.279122, -1579.516480, 30.914306, 317.480316),
    ['BLACK'] = vector4(452.756042, -1516.114258, 28.521606, 48.188972),
}
