Config = {}

-- ==========================================
-- POSITIONS CLÉS
-- ==========================================

Config.PedLocation = {
    coords = vector4(-5821.411132, -904.114258, 502.489990, 223.937012),
    model = 's_m_y_blackops_01',
    frozen = true,
    invincible = true,
    blockevents = true
}

Config.LobbyLocation = vector3(-1433.235107, -2819.907715, 433.759766)

-- ==========================================
-- ✅ NOUVELLE COORDONNÉE DE SORTIE (POUR TOUS LES CAS)
-- ==========================================
-- Utilisée pour : fin de partie, kick, quit manuel, etc.
-- ==========================================

Config.ExitLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)

Config.TeamZones = {
    red = {
        coords = vector3(-1421.182373, -2821.081299, 431.114258),
        color = {r = 0, g = 0, b = 0, a = 200},
        radius = 2.0,
        label = "équipe Rouge"
    },
    blue = {
        coords = vector3(-1425.112061, -2829.811035, 431.114258),
        color = {r = 0, g = 100, b = 255, a = 200},
        radius = 2.0,
        label = "équipe Bleue"
    }
}

-- ==========================================
-- TENUES DES ÉQUIPES
-- ==========================================

Config.Outfits = {
    red = {
        male = {
            ['tshirt_1'] = 0,   ['tshirt_2'] = 2,
            ['torso_1'] = 3,   ['torso_2'] = 5,
            ['decals_1'] = 0,    ['decals_2'] = 0,
            ['arms'] = 14,
            ['pants_1'] = 3,    ['pants_2'] = 15,
            ['shoes_1'] = 26,    ['shoes_2'] = 1,
            ['helmet_1'] = 2,   ['helmet_2'] = 7,
            ['chain_1'] = 0,     ['chain_2'] = 0,
            ['ears_1'] = -1,     ['ears_2'] = 0,
            ['bags_1'] = 0,      ['bags_2'] = 0,
            ['mask_1'] = 4,      ['mask_2'] = 2,
            ['bproof_1'] = 0,    ['bproof_2'] = 0
        },
        female = {
            ['tshirt_1'] = 58,   ['tshirt_2'] = 1,
            ['torso_1'] = 165,   ['torso_2'] = 1,
            ['decals_1'] = 0,    ['decals_2'] = 0,
            ['arms'] = 0,
            ['pants_1'] = 3,     ['pants_2'] = 7,
            ['shoes_1'] = 132,   ['shoes_2'] = 0,
            ['helmet_1'] = 141,  ['helmet_2'] = 3,
            ['chain_1'] = 0,     ['chain_2'] = 0,
            ['glasses_1'] = 9,   ['glasses_2'] = 3,
            ['bags_1'] = 0,      ['bags_2'] = 0,
            ['mask_1'] = 54,     ['mask_2'] = 0,
            ['bproof_1'] = 0,    ['bproof_2'] = 0
        }
    },
    blue = {
        male = {
            ['tshirt_1'] = 0,   ['tshirt_2'] = 0,
            ['torso_1'] = 3,   ['torso_2'] = 3,
            ['decals_1'] = 0,    ['decals_2'] = 0,
            ['arms'] = 14,
            ['pants_1'] = 3,    ['pants_2'] = 3,
            ['shoes_1'] = 26,    ['shoes_2'] = 4,
            ['helmet_1'] = 142,   ['helmet_2'] = 4,
            ['chain_1'] = 0,     ['chain_2'] = 0,
            ['ears_1'] = -1,     ['ears_2'] = 0,
            ['bags_1'] = 0,      ['bags_2'] = 0,
            ['mask_1'] = 169,      ['mask_2'] = 8,
            ['bproof_1'] = 0,    ['bproof_2'] = 0
        },
        female = {
            ['tshirt_1'] = 58,   ['tshirt_2'] = 1,
            ['torso_1'] = 165,   ['torso_2'] = 1,
            ['decals_1'] = 0,    ['decals_2'] = 0,
            ['arms'] = 0,
            ['pants_1'] = 3,     ['pants_2'] = 3,
            ['shoes_1'] = 132,   ['shoes_2'] = 0,
            ['helmet_1'] = 141,  ['helmet_2'] = 4,
            ['chain_1'] = 0,     ['chain_2'] = 0,
            ['glasses_1'] = 9,   ['glasses_2'] = 4,
            ['bags_1'] = 0,      ['bags_2'] = 0,
            ['mask_1'] = 54,     ['mask_2'] = 0,
            ['bproof_1'] = 0,    ['bproof_2'] = 0
        }
    }
}

-- ==========================================
-- SYSTÈME DE MAPS MULTIPLES
-- ==========================================

Config.Maps = {
    [1] = {
        name = "Usine Abandonnée",
        description = "Combat tactique dans une zone industrielle",
        enabled = true,
        spawns = {
            red = vector4(1500.131836, -2058.105468, 80.032226, 0.0),
            blue = vector4(1566.329712, -2205.771484, 80.006176, 0.0)
        },
        combatZone = {
            center = vector3(1541.472534, -2133.863770, 77.150146),
            radius = 150.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [2] = {
        name = "Désert de Sandy Shores",
        description = "Combat en terrain découvert avec peu de couvertures",
        enabled = true,
        spawns = {
            red = vector4(2330.729736, 3013.701172, 47.405151, 180.0),
            blue = vector4(2428.602295, 3169.437256, 49.898926, 0.0)
        },
        combatZone = {
            center = vector3(2388.843994, 3096.158203, 48.134766),
            radius = 180.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [3] = {
        name = "Vagos",
        description = "VAGOS",
        enabled = true,
        spawns = {
            red = vector4(373.635162, -1975.265991, 26.174316, 164.409454),
            blue = vector4(313.569244, -2075.116455, 19.973633, 311.811035)
        },
        combatZone = {
            center = vector3(344.320892, -2040.857178, 21.646851),
            radius = 100.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [4] = {
        name = "Ville labo",
        description = "Ville laboratoire de methe",
        enabled = true,
        spawns = {
            red = vector4(83.406593, -1673.446167, 32.077637, 272.125977),
            blue = vector4(263.498901, -1671.309937, 32.279907, 127.559052)
        },
        combatZone = {
            center = vector3(183.112091, -1677.679077, 29.751709),
            radius = 120.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [5] = {
        name = "Ville traitement",
        description = "Ville traitement",
        enabled = true,
        spawns = {
            red = vector4(1228.140625, -1228.958252, 38.767090, 147.401581),
            blue = vector4(1178.004395, -1371.243896, 37.874023, 345.826782)
        },
        combatZone = {
            center = vector3(1174.813232, -1314.224121, 34.806641),
            radius = 120.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [6] = {
        name = "Ville BurgerShot",
        description = "Ville BurgerShot",
        enabled = true,
        spawns = {
            red = vector4(1108.971436, -327.810974, 70.073974, 45.354328),
            blue = vector4(1153.094482, -474.052734, 69.534790, 11.338582)
        },
        combatZone = {
            center = vector3(1152.369262, -392.914276, 67.326782),
            radius = 120.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [7] = {
        name = "CARTIER PRIME",
        description = "CARTIER PRIME",
        enabled = true,
        spawns = {
            red = vector4(490.773620, -1451.894532, 32.279908, 155.905518),
            blue = vector4(444.540649, -1563.573608, 32.279907, 357.165344)
        },
        combatZone = {
            center = vector3(462.909882, -1525.740600, 29.060792),
            radius = 110.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [8] = {
        name = "CAISSE ABANDONNER",
        description = "CAISSE ABANDONNER",
        enabled = true,
        spawns = {
            red = vector4(-521.287902, -1679.090088, 22.271118, 62.362206),
            blue = vector4(-433.542846, -1724.610962, 21.900390, 272.12597)
        },
        combatZone = {
            center = vector3(-489.652740, -1715.459350, 18.866700),
            radius = 90.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [9] = {
        name = "EGLISE",
        description = "EGLISE",
        enabled = true,
        spawns = {
            red = vector4(-1667.564819, -307.331879, 54.369995, 2.834646),
            blue = vector4(-1706.123047, -245.195602, 57.015381, 212.598419)
        },
        combatZone = {
            center = vector3(-1677.718628, -282.382416, 64.125244),
            radius = 75.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [10] = {
        name = "CASINO",
        description = "CASINO",
        enabled = true,
        spawns = {
            red = vector4(1310.518677, 294.804382, 83.975098, 51.023624),
            blue = vector4(1214.663696, 354.224182, 84.986084, 246.614166)
        },
        combatZone = {
            center = vector3(1262.307739, 326.413177, 92.112793),
            radius = 80.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [11] = {
        name = "KOTH SANDY",
        description = "KOTH SANDY",
        enabled = true,
        spawns = {
            red = vector4(2691.692383, 4158.751465, 45.186768, 240.944885),
            blue = vector4(2738.887939, 4122.210938, 47.967041, 48.188972)
        },
        combatZone = {
            center = vector3(2713.648438, 4142.373535, 43.854980),
            radius = 80.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [12] = {
        name = "FERME",
        description = "FERME",
        enabled = true,
        spawns = {
            red = vector4(2535.705566, 4640.755859, 37.098877, 308.976379),
            blue = vector4(2600.347168, 4693.529785, 36.239502, 130.393707)
        },
        combatZone = {
            center = vector3(2571.415283, 4660.140625, 34.065186),
            radius = 75.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [13] = {
        name = "LABO WEED",
        description = "LABO WEED",
        enabled = true,
        spawns = {
            red = vector4(2045.670288, 4985.288086, 43.569214, 85.039368),
            blue = vector4(1979.815430, 4976.821777, 45.085693, 272.125977)
        },
        combatZone = {
            center = vector3(2010.659302, 4980.421875, 42.237305),
            radius = 75.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [14] = {
        name = "RECOLTE WEED",
        description = "RECOLTE WEED",
        enabled = true,
        spawns = {
            red = vector4(2199.125244, 5615.525391, 55.83007, 320.314972),
            blue = vector4(2264.690186, 5541.481445, 53.965576, 45.354328)
        },
        combatZone = {
            center = vector3(2209.912109, 5596.074707, 53.846924),
            radius = 85.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [15] = {
        name = "RECOLTE OPIUM",
        description = "RECOLTE OPIUM",
        enabled = true,
        spawns = {
            red = vector4(295.292297, 6630.171387, 32.195557, 269.291351),
            blue = vector4(380.518677, 6626.070312, 31.605835, 87.874016)
        },
        combatZone = {
            center = vector3(340.443970, 6628.430664, 28.875488),
            radius = 85.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [16] = {
        name = "FERME OPIUM",
        description = "FERME OPIUM",
        enabled = true,
        spawns = {
            red = vector4(-139.832962, 1913.010986, 200.289429, 266.456696),
            blue = vector4(-73.529663, 1917.626343, 199.227783, 104.881889)
        },
        combatZone = {
            center = vector3(-93.191208, 1910.386841, 196.885010),
            radius = 85.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [17] = {
        name = "BOX OFFICE",
        description = "BOX OFFICE",
        enabled = true,
        spawns = {
            red = vector4(650.017578, 602.861511, 131.895996, 246.614166),
            blue = vector4(743.459351, 576.039551, 128.913574, 68.031494)
        },
        combatZone = {
            center = vector3(686.281311, 578.043945, 130.446167),
            radius = 85.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [18] = {
        name = "BOX OFFICE",
        description = "BOX OFFICE",
        enabled = true,
        spawns = {
            red = vector4(415.437378, -347.340668, 49.208008, 96.377945),
            blue = vector4(350.901093, -353.894501, 48.331909, 266.456696)
        },
        combatZone = {
            center = vector3(389.221985, -356.096710, 48.016846),
            radius = 75.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [19] = {
        name = "mapping",
        description = "mapping route",
        enabled = true,
        spawns = {
            red = vector4(-2024.360474, -2032.892334, 1774.208008, 269.291351),
            blue = vector4(-1934.096680, -2033.340698, 1774.208008, 85.039368)
        },
        combatZone = {
            center = vector3(-1979.934082, -2033.235107, 1772.224854),
            radius = 85.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [20] = {
        name = "mapping2",
        description = "mapping route",
        enabled = true,
        spawns = {
            red = vector4(-2741.287842, -2445.745117, 1435.706299, 136.062988),
            blue = vector4(-2810.545166, -2511.586914, 1435.706299, 317.480316)
        },
        combatZone = {
            center = vector3(-2776.694580, -2469.745117, 1434.689453),
            radius = 85.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [21] = {
        name = "mapping3",
        description = "mapping fête",
        enabled = true,
        spawns = {
            red = vector4(4655.195801, 4941.929688, 1812.524658, 127.559052),
            blue = vector4(4600.338379, 4890.856934, 1812.524658, 308.976379)
        },
        combatZone = {
            center = vector3(4626.936035, 4918.747070, 1814.147217),
            radius = 85.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [22] = {
        name = "mapping4",
        description = "mapping block",
        enabled = true,
        spawns = {
            red = vector4(4757.195801, 4856.980469, 1514.731934, 45.354328),
            blue = vector4(4706.755859, 4911.520996, 1514.731934, 221.102371)
        },
        combatZone = {
            center = vector3(4732.312012, 4884.474609, 1517.051270),
            radius = 85.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [23] = {
        name = "mapping5",
        description = "mapping rapide",
        enabled = true,
        spawns = {
            red = vector4(4585.266113, 6182.650391, 745.931152, 317.480316),
            blue = vector4(4635.125488, 6235.885742, 745.931152, 127.559052)
        },
        combatZone = {
            center = vector3(4609.173828, 6209.340820, 745.936279),
            radius = 85.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [24] = {
        name = "mapping6",
        description = "mapping rapide",
        enabled = true,
        spawns = {
            red = vector4(6372.382324, -1048.588989, 1829.391113, 223.937012),
            blue = vector4(6497.063965, -1169.380249, 1829.407959, 36.850395)
        },
        combatZone = {
            center = vector3(6435.375977, -1107.072510, 1827.407959),
            radius = 85.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [25] = {
        name = "mapping7",
        description = "mapping fullfps",
        enabled = true,
        spawns = {
            red = vector4(3712.641846, 764.676941, 1299.649902, 323.149597),
            blue = vector4(3739.556152, 791.327454, 1299.649902, 136.062988)
        },
        combatZone = {
            center = vector3(3726.329590, 778.786804, 1297.649902),
            radius = 85.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [26] = {
        name = "mapping7",
        description = "mapping fullfps",
        enabled = true,
        spawns = {
            red = vector4(5426.597656, -1173.270386, 357.205810, 45.354328),
            blue = vector4(5310.395508, -1043.815430, 357.205810, 215.433074)
        },
        combatZone = {
            center = vector3(5366.993164, -1106.624146, 357.581788),
            radius = 115.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [27] = {
        name = "mapping8",
        description = "mapping fullfps2",
        enabled = true,
        spawns = {
            red = vector4(-81.929672, -4348.101074, 193.493042, 85.039368),
            blue = vector4(-213.191208, -4348.430664, 193.493042, 269.291352)
        },
        combatZone = {
            center = vector3(-147.112092, -4347.705566, 191.796386),
            radius = 85.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [28] = {
        name = "Chantier",
        description = "chantier",
        enabled = true,
        spawns = {
            red = vector4(97.661545, -364.589020, 42.237305, 130.393707),
            blue = vector4(-3.863731, -447.006592, 39.760498, 289.133850)
        },
        combatZone = {
            center = vector3(58.206593, -419.195618, 39.912109),
            radius = 120.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [29] = {
        name = "Fête",
        description = "Fête",
        enabled = true,
        spawns = {
            red = vector4(-1655.103271, -1027.661499, 13.205078, 192.755920),
            blue = vector4(-1659.586792, -1110.421997, 13.053467, 17.007874)
        },
        combatZone = {
            center = vector3(-1659.771484, -1076.334106, 20.433716),
            radius = 130.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [30] = {
        name = "Base Militaire",
        description = "Base militaire",
        enabled = true,
        spawns = {
            red = vector4(-1902.817627, 3298.892334, 32.986816, 79.370079),
            blue = vector4(-2008.483521, 3327.639648, 32.953125, 266.456696)
        },
        combatZone = {
            center = vector3(-1955.841797, 3325.041748, 32.953125),
            radius = 140.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [31] = {
        name = "Camp Nudiste",
        description = "Camp nudiste",
        enabled = true,
        spawns = {
            red = vector4(-1068.909912, 4948.259277, 212.302612, 147.401581),
            blue = vector4(-1099.134033, 4867.938477, 216.110596, 357.165344)
        },
        combatZone = {
            center = vector3(-1116.804443, 4923.059570, 218.098877),
            radius = 130.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [32] = {
        name = "Camps",
        description = "Camps",
        enabled = true,
        spawns = {
            red = vector4(32.373631, 3694.615479, 39.642456, 306.141724),
            blue = vector4(85.173630, 3736.008789, 39.743530, 96.377945)
        },
        combatZone = {
            center = vector3(57.784615, 3714.263672, 39.743530),
            radius = 110.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [33] = {
        name = "Nord 1",
        description = "Zone Nord 1",
        enabled = true,
        spawns = {
            red = vector4(977.169250, 3607.714355, 32.902588, 48.188972),
            blue = vector4(896.241760, 3660.013184, 32.767822, 243.779526)
        },
        combatZone = {
            center = vector3(938.136292, 3633.270264, 32.498169),
            radius = 120.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [34] = {
        name = "Nord 2",
        description = "Zone Nord 2",
        enabled = true,
        spawns = {
            red = vector4(1370.650513, 4300.733887, 37.536255, 42.519684),
            blue = vector4(1329.415405, 4372.839355, 43.568481, 212.598419)
        },
        combatZone = {
            center = vector3(1327.872559, 4346.281250, 41.243164),
            radius = 125.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [35] = {
        name = "Hydro",
        description = "Hydro",
        enabled = true,
        spawns = {
            red = vector4(2766.883545, 1594.549438, 24.494507, 158.740158),
            blue = vector4(2746.720947, 1515.784668, 24.494507, 331.653534)
        },
        combatZone = {
            center = vector3(2756.268066, 1550.663696, 24.494507),
            radius = 115.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [36] = {
        name = "Madrazo",
        description = "Madrazo",
        enabled = true,
        spawns = {
            red = vector4(1434.962646, 1179.982422, 114.186035, 223.937012),
            blue = vector4(1477.384644, 1130.123047, 114.320923, 59.527554)
        },
        combatZone = {
            center = vector3(1455.797852, 1153.635132, 117.825684),
            radius = 110.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [37] = {
        name = "1",
        description = "Centre",
        enabled = true,
        spawns = {
            red = vector4(-327.956055, -1410.659302, 30.526733, 328.818909),
            blue = vector4(-291.468140, -1326.870361, 31.133301, 127.559052)
        },
        combatZone = {
            center = vector3(-312.989014, -1352.795654, 40.586060),
            radius = 125.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [38] = {
        name = "Nord 3",
        description = "Zone Nord 3",
        enabled = true,
        spawns = {
            red = vector4(285.586823, 2798.492188, 43.821289, 345.826782),
            blue = vector4(294.606598, 2889.296631, 43.602173, 161.574799)
        },
        combatZone = {
            center = vector3(288.501099, 2862.672607, 43.635864),
            radius = 120.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [39] = {
        name = "Nord",
        description = "Centre",
        enabled = true,
        spawns = {
            red = vector4(1257.745117, 2985.586914, 41.276978, 300.472443),
            blue = vector4(1314.659302, 3033.217529, 43.012451, 161.574799)
        },
        combatZone = {
            center = vector3(1306.971436, 3003.164795, 52.498901),
            radius = 130.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [40] = {
        name = "Mega",
        description = "Mega",
        enabled = true,
        spawns = {
            red = vector4(2742.883545, 3428.861572, 56.408081, 36.850395),
            blue = vector4(2682.883545, 3545.841797, 51.588989, 221.102371)
        },
        combatZone = {
            center = vector3(2704.114258, 3490.536377, 61.513550),
            radius = 140.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    },
    [41] = {
        name = "Nord 4",
        description = "Zone Nord 4",
        enabled = true,
        spawns = {
            red = vector4(908.980225, 2880.382324, 56.526001, 110.551186),
            blue = vector4(845.459351, 2847.718750, 58.531128, 317.480316)
        },
        combatZone = {
            center = vector3(872.452759, 2863.595703, 56.761963),
            radius = 115.0,
            damagePerSecond = 5,
            damageTickRate = 500,
            warningDistance = 4.0
        },
        endLocation = vector4(-5805.099121, -917.709900, 505.068115, 90.708656)
    }
}


Config.DefaultMapId = 1

Config.SpawnLocations = Config.Maps[Config.DefaultMapId].spawns
Config.CombatZone = Config.Maps[Config.DefaultMapId].combatZone
Config.EndGameLocation = Config.Maps[Config.DefaultMapId].endLocation

-- ==========================================
-- TEXTES DE L'INTERFACE
-- ==========================================

Config.Texts = {
    uiTitle = "Guerre de Territoire",
    joinButton = "Rejoindre la salle d'attente",
    selectTeam = "Sélectionne ton équipe",
    redTeam = "équipe Rouge",
    blueTeam = "équipe Bleue"
}

-- ==========================================
-- PARAMÈTRES SYSTÈME
-- ==========================================

Config.EnableDebug = false
Config.ActionCooldown = 1000
Config.MaxPlayersPerTeam = 30
Config.MaxTotalPlayers = 60

-- ==========================================
-- ✅ PERMISSIONS ADMIN (MODIFIÉ)
-- ==========================================

Config.AdminPermissions = {
    command = 'gdt.admin',
    allowedGroups = {'responsable', 'organisateur', 'admin', 'owner'}
}

-- ==========================================
-- ROUTING BUCKETS
-- ==========================================

Config.BucketSettings = {
    startBucket = 1000,
    maxBuckets = 100,
    lockdownMode = true
}

-- ==========================================
-- NOTIFICATIONS
-- ==========================================

Config.Notifications = {
    joinedLobby = "Tu as rejoint la salle d'attente !",
    teamSelected = "Tu as rejoint l'équipe %s !",
    leftGDT = "Tu as quitté la guerre de territoire.",
    noPermission = "Tu n'as pas la permission.",
    invalidTeam = "équipe invalide.",
    alreadyInGDT = "Tu es déjà dans une partie.",
    gdtFull = "La partie est compléte (%d/%d joueurs).",
    teamFull = "Cette équipe est compléte (%d/%d joueurs).",
    mapNotFound = "Map introuvable (ID invalide).",
    mapDisabled = "Cette map est désactivée."
}

-- ==========================================
-- CONFIGURATION DE JEU
-- ==========================================

Config.GameSettings = {
    maxRounds = 3,
    respawnDelay = 0,
    roundEndDelay = 5000,
    gameEndDelay = 10000,
    announceDuration = 5000
}

Config.StartWeapon = {
    weapon = 'WEAPON_PISTOL50',
    ammo = 300
}

Config.Killfeed = {
    enabled = true,
    maxEntries = 6,
    displayDuration = 5000,
    position = {
        top = '80px',
        right = '20px'
    }
}

-- ==========================================
-- GAMEPLAY
-- ==========================================

Config.Gameplay = {
    infiniteStamina = true
}

Config.Spectator = {
    enabled = true,
    autoSwitchOnTargetDeath = true,
    showHUD = true,
    allowSpectateEnemies = false
}

-- ==========================================
-- ANTI-FRIENDLY FIRE
-- ==========================================

Config.FriendlyFire = {
    enabled = true,
    showWarning = true,
    warningCooldown = 3000,
    disableMeleeDamage = true,
    disableVehicleDamage = true,
    warningMessage = "TIR ALLIE BLOQUE !",
    serverBackup = {
        enabled = true,
        reviveVictim = true,
        notifyKiller = true,
        logTeamkills = true
    }
}