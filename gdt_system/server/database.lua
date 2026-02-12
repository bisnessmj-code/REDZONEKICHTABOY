-- ==========================================
-- SERVER DATABASE - GESTION KILLS GDT
-- ==========================================

Database = {}

-- ==========================================
-- INITIALISATION DE LA TABLE
-- ==========================================

function Database.Init()
    MySQL.ready(function()
        MySQL.Async.execute([[
            CREATE TABLE IF NOT EXISTS `gdt_kills` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `identifier` VARCHAR(60) NOT NULL,
                `name` VARCHAR(50) NOT NULL,
                `kills` INT NOT NULL DEFAULT 0,
                `deaths` INT NOT NULL DEFAULT 0,
                `wins` INT NOT NULL DEFAULT 0,
                `losses` INT NOT NULL DEFAULT 0,
                UNIQUE KEY `uk_identifier` (`identifier`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        ]], {}, function()
            -- Migration : ajouter les colonnes si elles n'existent pas (safe)
            MySQL.Async.execute([[
                ALTER TABLE `gdt_kills`
                ADD COLUMN IF NOT EXISTS `deaths` INT NOT NULL DEFAULT 0,
                ADD COLUMN IF NOT EXISTS `wins` INT NOT NULL DEFAULT 0,
                ADD COLUMN IF NOT EXISTS `losses` INT NOT NULL DEFAULT 0
            ]], {}, function()
                print("^2[GDT System] ^7Table gdt_kills initialisee (avec deaths/wins/losses).")
            end)
        end)
    end)
end

-- ==========================================
-- ENREGISTRER UN KILL (ASYNC - UPSERT)
-- ==========================================

function Database.AddKill(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    local name = xPlayer.getName() or 'Inconnu'

    MySQL.Async.execute([[
        INSERT INTO `gdt_kills` (`identifier`, `name`, `kills`)
        VALUES (@identifier, @name, 1)
        ON DUPLICATE KEY UPDATE `kills` = `kills` + 1, `name` = @name
    ]], {
        ['@identifier'] = identifier,
        ['@name'] = name
    })
end

-- ==========================================
-- TOP 3 KILLERS (POUR AFFICHAGE EXTERNE)
-- ==========================================

function Database.GetTopKillers(cb)
    MySQL.Async.fetchAll([[
        SELECT `name`, `kills` FROM `gdt_kills`
        ORDER BY `kills` DESC
        LIMIT 3
    ]], {}, function(results)
        cb(results or {})
    end)
end

-- ==========================================
-- TOP 20 KILLERS (CLASSEMENT)
-- ==========================================

function Database.GetTop20Killers(cb)
    MySQL.Async.fetchAll([[
        SELECT `name`, `kills` FROM `gdt_kills`
        ORDER BY `kills` DESC
        LIMIT 20
    ]], {}, function(results)
        cb(results or {})
    end)
end

-- ==========================================
-- ENREGISTRER UNE MORT (ASYNC - UPSERT)
-- ==========================================

function Database.AddDeath(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    local name = xPlayer.getName() or 'Inconnu'

    MySQL.Async.execute([[
        INSERT INTO `gdt_kills` (`identifier`, `name`, `deaths`)
        VALUES (@identifier, @name, 1)
        ON DUPLICATE KEY UPDATE `deaths` = `deaths` + 1, `name` = @name
    ]], {
        ['@identifier'] = identifier,
        ['@name'] = name
    })
end

-- ==========================================
-- ENREGISTRER UNE VICTOIRE (ASYNC - UPSERT)
-- ==========================================

function Database.AddWin(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    local name = xPlayer.getName() or 'Inconnu'

    MySQL.Async.execute([[
        INSERT INTO `gdt_kills` (`identifier`, `name`, `wins`)
        VALUES (@identifier, @name, 1)
        ON DUPLICATE KEY UPDATE `wins` = `wins` + 1, `name` = @name
    ]], {
        ['@identifier'] = identifier,
        ['@name'] = name
    })
end

-- ==========================================
-- ENREGISTRER UNE DEFAITE (ASYNC - UPSERT)
-- ==========================================

function Database.AddLoss(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    local name = xPlayer.getName() or 'Inconnu'

    MySQL.Async.execute([[
        INSERT INTO `gdt_kills` (`identifier`, `name`, `losses`)
        VALUES (@identifier, @name, 1)
        ON DUPLICATE KEY UPDATE `losses` = `losses` + 1, `name` = @name
    ]], {
        ['@identifier'] = identifier,
        ['@name'] = name
    })
end

-- ==========================================
-- STATS PERSONNELLES D'UN JOUEUR
-- ==========================================

function Database.GetPlayerStats(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(nil) end

    local identifier = xPlayer.identifier

    MySQL.Async.fetchAll([[
        SELECT `kills`, `deaths`, `wins`, `losses` FROM `gdt_kills`
        WHERE `identifier` = @identifier
        LIMIT 1
    ]], {
        ['@identifier'] = identifier
    }, function(results)
        if results and results[1] then
            cb(results[1])
        else
            cb({ kills = 0, deaths = 0, wins = 0, losses = 0 })
        end
    end)
end

-- ==========================================
-- INIT AU DEMARRAGE
-- ==========================================

Database.Init()

return Database
