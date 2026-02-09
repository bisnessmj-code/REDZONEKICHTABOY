--[[
    Validators Serveur - Panel Admin Fight League
    Validation des données entrantes
]]

Validators = {}

-- ══════════════════════════════════════════════════════════════
-- VALIDATIONS GÉNÉRALES
-- ══════════════════════════════════════════════════════════════

-- Valider un ID joueur (server ID)
function Validators.PlayerId(id)
    if type(id) == 'string' then
        id = tonumber(id)
    end

    if type(id) ~= 'number' then
        return false, 'L\'ID doit être un nombre'
    end

    if id < 1 or id > 256 then
        return false, 'ID joueur invalide'
    end

    return true, id
end

-- Valider un identifier (steam:xxx, license:xxx, etc.)
function Validators.Identifier(identifier)
    if type(identifier) ~= 'string' then
        return false, 'Identifiant invalide'
    end

    local validPrefixes = {'steam:', 'license:', 'discord:', 'live:', 'xbl:', 'ip:', 'fivem:'}
    local hasValidPrefix = false

    for _, prefix in ipairs(validPrefixes) do
        if string.sub(identifier, 1, #prefix) == prefix then
            hasValidPrefix = true
            break
        end
    end

    if not hasValidPrefix then
        return false, 'Préfixe d\'identifiant invalide'
    end

    return true, identifier
end

-- Valider une raison (texte)
function Validators.Reason(reason, minLen, maxLen)
    minLen = minLen or 3
    maxLen = maxLen or 500

    if type(reason) ~= 'string' then
        return false, 'La raison doit être du texte'
    end

    reason = reason:gsub('^%s*(.-)%s*$', '%1') -- trim

    if #reason < minLen then
        return false, 'La raison est trop courte (min ' .. minLen .. ' caractères)'
    end

    if #reason > maxLen then
        return false, 'La raison est trop longue (max ' .. maxLen .. ' caractères)'
    end

    return true, Helpers.SanitizeString(reason)
end

-- Valider une durée en heures
function Validators.Duration(duration, allowPermanent)
    if type(duration) == 'string' then
        duration = tonumber(duration)
    end

    if type(duration) ~= 'number' then
        return false, 'La durée doit être un nombre'
    end

    if allowPermanent and duration == -1 then
        return true, -1
    end

    if duration < 0 then
        return false, 'La durée doit être positive'
    end

    if duration > 8760 then -- Max 1 an
        return false, 'La durée ne peut pas dépasser 1 an'
    end

    return true, duration
end

-- Valider un montant d'argent
function Validators.Amount(amount, maxAmount)
    maxAmount = maxAmount or Config.Economy.MaxSingleTransaction

    if type(amount) == 'string' then
        amount = tonumber(amount)
    end

    if type(amount) ~= 'number' then
        return false, 'Le montant doit être un nombre'
    end

    if amount <= 0 then
        return false, 'Le montant doit être positif'
    end

    if amount > maxAmount then
        return false, 'Montant trop élevé (max ' .. Helpers.FormatNumber(maxAmount) .. ')'
    end

    return true, math.floor(amount)
end

-- Valider des coordonnées
function Validators.Coords(x, y, z)
    if type(x) == 'string' then x = tonumber(x) end
    if type(y) == 'string' then y = tonumber(y) end
    if type(z) == 'string' then z = tonumber(z) end

    if type(x) ~= 'number' or type(y) ~= 'number' or type(z) ~= 'number' then
        return false, 'Coordonnées invalides'
    end

    -- Limites de la carte GTA V (incluant Cayo Perico et zones etendues)
    if x < -10000 or x > 10000 or y < -15000 or y > 10000 or z < -500 or z > 5000 then
        return false, 'Coordonnées hors limites'
    end

    return true, vector3(x, y, z)
end

-- ══════════════════════════════════════════════════════════════
-- VALIDATIONS SPÉCIFIQUES
-- ══════════════════════════════════════════════════════════════

-- Valider un type de sanction
function Validators.SanctionType(sanctionType)
    local validTypes = {
        Enums.SanctionType.WARN,
        Enums.SanctionType.KICK,
        Enums.SanctionType.BAN_TEMP,
        Enums.SanctionType.BAN_PERM
    }

    if not Helpers.TableContains(validTypes, sanctionType) then
        return false, 'Type de sanction invalide'
    end

    return true, sanctionType
end

-- Valider un type d'argent
function Validators.MoneyType(moneyType)
    local validTypes = {
        Enums.MoneyType.CASH,
        Enums.MoneyType.BANK,
        Enums.MoneyType.BLACK
    }

    if not Helpers.TableContains(validTypes, moneyType) then
        return false, 'Type d\'argent invalide'
    end

    return true, moneyType
end

-- Valider un nom de véhicule
function Validators.VehicleModel(model)
    if type(model) ~= 'string' then
        return false, 'Modèle invalide'
    end

    model = model:lower():gsub('%s+', '')

    if #model < 2 or #model > 50 then
        return false, 'Nom de modèle invalide'
    end

    -- Vérifier les caractères autorisés
    if not model:match('^[a-z0-9_]+$') then
        return false, 'Le nom du modèle contient des caractères invalides'
    end

    return true, model
end

-- Valider un grade ESX
function Validators.Grade(grade)
    if type(grade) ~= 'string' then
        return false, 'Grade invalide'
    end

    if not Permissions.Grades[grade] then
        return false, 'Grade inconnu: ' .. grade
    end

    return true, grade
end

-- Valider un type d'événement
function Validators.EventType(eventType)
    local validTypes = {
        Enums.EventType.FIGHT,
        Enums.EventType.TOURNAMENT,
        Enums.EventType.TRAINING,
        Enums.EventType.MEETING,
        Enums.EventType.OTHER
    }

    if not Helpers.TableContains(validTypes, eventType) then
        return false, 'Type d\'événement invalide'
    end

    return true, eventType
end

-- Valider un type d'annonce
function Validators.AnnounceType(announceType)
    local validTypes = {
        Enums.AnnounceType.CHAT,
        Enums.AnnounceType.NOTIFICATION,
        Enums.AnnounceType.POPUP,
        Enums.AnnounceType.ALL
    }

    if not Helpers.TableContains(validTypes, announceType) then
        return false, 'Type d\'annonce invalide'
    end

    return true, announceType
end

-- ══════════════════════════════════════════════════════════════
-- VALIDATIONS COMPOSÉES
-- ══════════════════════════════════════════════════════════════

-- Valider les données d'une sanction complète
function Validators.SanctionData(data)
    local errors = {}

    -- Type
    local valid, result = Validators.SanctionType(data.type)
    if not valid then
        table.insert(errors, result)
    else
        data.type = result
    end

    -- Target
    valid, result = Validators.PlayerId(data.targetId)
    if not valid then
        table.insert(errors, 'Cible: ' .. result)
    else
        data.targetId = result
    end

    -- Reason
    valid, result = Validators.Reason(data.reason)
    if not valid then
        table.insert(errors, 'Raison: ' .. result)
    else
        data.reason = result
    end

    -- Duration (si ban)
    if data.type == Enums.SanctionType.BAN_TEMP then
        valid, result = Validators.Duration(data.duration, false)
        if not valid then
            table.insert(errors, 'Durée: ' .. result)
        else
            data.duration = result
        end
    elseif data.type == Enums.SanctionType.BAN_PERM then
        data.duration = -1
    end

    if #errors > 0 then
        return false, errors
    end

    return true, data
end

-- Valider les données d'une transaction économique
function Validators.EconomyData(data)
    local errors = {}

    -- Target
    local valid, result = Validators.PlayerId(data.targetId)
    if not valid then
        table.insert(errors, 'Cible: ' .. result)
    else
        data.targetId = result
    end

    -- Amount
    valid, result = Validators.Amount(data.amount)
    if not valid then
        table.insert(errors, 'Montant: ' .. result)
    else
        data.amount = result
    end

    -- Money type
    valid, result = Validators.MoneyType(data.moneyType)
    if not valid then
        table.insert(errors, 'Type: ' .. result)
    else
        data.moneyType = result
    end

    -- Reason (optionnel mais requis si config)
    if Config.Economy.RequireReason then
        valid, result = Validators.Reason(data.reason, 3, 200)
        if not valid then
            table.insert(errors, 'Raison: ' .. result)
        else
            data.reason = result
        end
    end

    if #errors > 0 then
        return false, errors
    end

    return true, data
end
