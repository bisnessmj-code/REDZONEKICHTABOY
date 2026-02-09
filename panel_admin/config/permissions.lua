--[[
    Système de Permissions - Panel Admin Fight League
    Matrice hiérarchique avec héritage automatique
]]

Permissions = {}

-- ══════════════════════════════════════════════════════════════
-- DÉFINITION DES GRADES
-- ══════════════════════════════════════════════════════════════

Permissions.Grades = {
    owner = {
        level = 100,
        label = 'Owner',
        color = '#e74c3c',
        inherits = 'admin',
        abilities = {'*'} -- Wildcard = toutes les permissions
    },

    admin = {
        level = 80,
        label = 'Admin',
        color = '#9b59b6',
        inherits = 'responsable',
        abilities = {
            'sanction.ban.perm',
            'sanction.unban',
            'economy.modify',
            'player.setgroup',
            'config.modify',
            'logs.delete',
            'report.delete',
            'object.delete', -- Suppression d'objets en noclip
            'event.stats.reset' -- Reset du classement événements
        }
    },

    responsable = {
        level = 60,
        label = 'Responsable',
        color = '#3498db',
        inherits = 'organisateur',
        abilities = {
            'sanction.kick',
            'sanction.ban.temp',
            'sanction.warn',
            'sanction.remove',
            'economy.view',
            'logs.view.all',
            'player.freeze',
            'report.stats',
            'report.delete',        -- Supprimer les tickets
            'event.stats',
            'event.stats.reset',    -- Reset du classement événements
            'event.clear'           -- Clear les événements
        }
    },

    organisateur = {
        level = 40,
        label = 'Organisateur',
        color = '#2ecc71',
        inherits = 'staff',
        abilities = {
            'teleport.self',
            'teleport.player',
            'teleport.bring',
            'teleport.goto',
            'vehicle.spawn',
            'vehicle.delete',
            'vehicle.repair',
            'announce.send',
            'announce.schedule',
            'event.create',
            'event.manage',
            'event.participant',
            'event.announce',
            'player.godmode'
        }
    },

    staff = {
        level = 20,
        label = 'Staff',
        color = '#f39c12',
        inherits = nil, -- Pas d'héritage
        abilities = {
            'vehicle.repair',
            'panel.open',
            'player.view',
            'player.view.details',
            'player.spectate',
            'player.note.view',
            'player.note.add',
            'logs.view.own',
            'player.revive',
            'player.heal',
            'dashboard.view',
            'sanction.view',    -- Voir les sanctions/bans
            'report.claim',     -- Prendre en charge un ticket
            'report.respond',   -- Repondre a un ticket
            -- Permissions Quick Menu
            'teleport.self',    -- Noclip
            'teleport.goto',    -- Aller vers lui
            'teleport.bring',   -- Amener ici
            'teleport.player',  -- Return
            'sanction.warn',    -- Avertissement
            'sanction.kick',    -- Kick
            'sanction.ban.temp', -- Ban temporaire
            'sanction.ban.perm' -- Ban permanent
        }
    }
}

-- ══════════════════════════════════════════════════════════════
-- LISTE COMPLÈTE DES PERMISSIONS
-- ══════════════════════════════════════════════════════════════

Permissions.List = {
    -- Panel
    ['panel.open'] = {
        description = 'Ouvrir le panel d\'administration',
        minLevel = 20
    },

    -- Dashboard
    ['dashboard.view'] = {
        description = 'Voir le dashboard',
        minLevel = 20
    },

    -- Joueurs
    ['player.view'] = {
        description = 'Voir la liste des joueurs',
        minLevel = 20
    },
    ['player.view.details'] = {
        description = 'Voir les détails d\'un joueur',
        minLevel = 20
    },
    ['player.spectate'] = {
        description = 'Spectate un joueur',
        minLevel = 20
    },
    ['player.note.view'] = {
        description = 'Voir les notes sur les joueurs',
        minLevel = 20
    },
    ['player.note.add'] = {
        description = 'Ajouter une note sur un joueur',
        minLevel = 20
    },
    ['player.freeze'] = {
        description = 'Freeze/Unfreeze un joueur',
        minLevel = 60
    },
    ['player.revive'] = {
        description = 'Réanimer un joueur',
        minLevel = 40
    },
    ['player.heal'] = {
        description = 'Soigner un joueur',
        minLevel = 40
    },
    ['player.godmode'] = {
        description = 'Activer le godmode',
        minLevel = 40
    },
    ['player.setgroup'] = {
        description = 'Modifier le groupe d\'un joueur',
        minLevel = 80
    },

    -- Sanctions
    ['sanction.view'] = {
        description = 'Voir les sanctions et bannissements',
        minLevel = 20
    },
    ['sanction.warn'] = {
        description = 'Avertir un joueur',
        minLevel = 60
    },
    ['sanction.kick'] = {
        description = 'Expulser un joueur',
        minLevel = 60
    },
    ['sanction.ban.temp'] = {
        description = 'Bannir temporairement',
        minLevel = 60
    },
    ['sanction.ban.perm'] = {
        description = 'Bannir définitivement',
        minLevel = 80
    },
    ['sanction.unban'] = {
        description = 'Débannir un joueur',
        minLevel = 80
    },
    ['sanction.remove'] = {
        description = 'Supprimer une sanction',
        minLevel = 60
    },

    -- Économie
    ['economy.view'] = {
        description = 'Voir l\'économie des joueurs',
        minLevel = 60
    },
    ['economy.modify'] = {
        description = 'Modifier l\'argent des joueurs',
        minLevel = 80
    },

    -- Téléportation
    ['teleport.self'] = {
        description = 'Se téléporter',
        minLevel = 40
    },
    ['teleport.player'] = {
        description = 'Téléporter un joueur',
        minLevel = 40
    },
    ['teleport.bring'] = {
        description = 'Amener un joueur à soi',
        minLevel = 40
    },
    ['teleport.goto'] = {
        description = 'Aller vers un joueur',
        minLevel = 40
    },

    -- Véhicules
    ['vehicle.spawn'] = {
        description = 'Spawn un véhicule',
        minLevel = 40
    },
    ['vehicle.delete'] = {
        description = 'Supprimer un véhicule',
        minLevel = 40
    },
    ['vehicle.repair'] = {
        description = 'Réparer un véhicule',
        minLevel = 40
    },

    -- Objets
    ['object.delete'] = {
        description = 'Supprimer un objet (noclip)',
        minLevel = 80 -- Admin uniquement
    },

    -- Annonces
    ['announce.send'] = {
        description = 'Envoyer une annonce',
        minLevel = 40
    },
    ['announce.schedule'] = {
        description = 'Programmer une annonce',
        minLevel = 40
    },

    -- Événements
    ['event.create'] = {
        description = 'Créer un événement',
        minLevel = 40
    },
    ['event.manage'] = {
        description = 'Gérer les événements',
        minLevel = 40
    },
    ['event.participant'] = {
        description = 'Gérer les participants',
        minLevel = 40
    },
    ['event.announce'] = {
        description = 'Envoyer une annonce d\'événement (Discord + In-Game)',
        minLevel = 40
    },
    ['event.stats'] = {
        description = 'Voir les statistiques des événements',
        minLevel = 60
    },
    ['event.stats.reset'] = {
        description = 'Réinitialiser le classement des événements',
        minLevel = 60
    },
    ['event.clear'] = {
        description = 'Supprimer tous les événements',
        minLevel = 60
    },

    -- Logs
    ['logs.view.own'] = {
        description = 'Voir ses propres logs',
        minLevel = 20
    },
    ['logs.view.all'] = {
        description = 'Voir tous les logs',
        minLevel = 60
    },
    ['logs.delete'] = {
        description = 'Supprimer des logs',
        minLevel = 80
    },

    -- Configuration
    ['config.modify'] = {
        description = 'Modifier la configuration',
        minLevel = 80
    },

    -- Reports
    ['report.delete'] = {
        description = 'Supprimer un ticket de support',
        minLevel = 60
    },
    ['report.stats'] = {
        description = 'Voir les statistiques des tickets',
        minLevel = 60
    }
}

-- ══════════════════════════════════════════════════════════════
-- FONCTIONS UTILITAIRES
-- ══════════════════════════════════════════════════════════════

-- Obtenir le niveau d'un grade
function Permissions.GetLevel(grade)
    local gradeData = Permissions.Grades[grade]
    return gradeData and gradeData.level or 0
end

-- Obtenir les infos d'un grade
function Permissions.GetGradeInfo(grade)
    return Permissions.Grades[grade]
end

-- Obtenir toutes les permissions d'un grade (avec héritage)
function Permissions.GetAllAbilities(grade)
    local abilities = {}
    local currentGrade = grade

    while currentGrade do
        local gradeData = Permissions.Grades[currentGrade]
        if not gradeData then break end

        -- Ajouter les abilities du grade
        if gradeData.abilities then
            for _, ability in ipairs(gradeData.abilities) do
                abilities[ability] = true
            end
        end

        -- Passer au grade parent
        currentGrade = gradeData.inherits
    end

    return abilities
end

-- Vérifier si un grade a une permission
function Permissions.HasAbility(grade, ability)
    if not grade or not ability then return false end

    local abilities = Permissions.GetAllAbilities(grade)

    -- Wildcard = toutes les permissions
    if abilities['*'] then return true end

    return abilities[ability] == true
end

-- Vérifier si un grade peut agir sur un autre
function Permissions.CanActOn(actorGrade, targetGrade)
    local actorLevel = Permissions.GetLevel(actorGrade)
    local targetLevel = Permissions.GetLevel(targetGrade)
    return actorLevel > targetLevel
end

-- Obtenir la liste des grades inférieurs
function Permissions.GetLowerGrades(grade)
    local currentLevel = Permissions.GetLevel(grade)
    local lowerGrades = {}

    for gradeName, gradeData in pairs(Permissions.Grades) do
        if gradeData.level < currentLevel then
            table.insert(lowerGrades, {
                name = gradeName,
                level = gradeData.level,
                label = gradeData.label
            })
        end
    end

    -- Trier par niveau décroissant
    table.sort(lowerGrades, function(a, b)
        return a.level > b.level
    end)

    return lowerGrades
end
