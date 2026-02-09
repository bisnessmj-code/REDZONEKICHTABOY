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
                UNIQUE KEY `uk_identifier` (`identifier`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        ]], {}, function()
            print("^2[GDT System] ^7Table gdt_kills initialisee.")
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
-- INIT AU DEMARRAGE
-- ==========================================

Database.Init()

return Database
