--[[
    Module Economy - Panel Admin Fight League
    Gestion de l'économie joueurs
]]

local Economy = {}

-- ══════════════════════════════════════════════════════════════
-- FONCTIONS PRINCIPALES
-- ══════════════════════════════════════════════════════════════

-- Ajouter de l'argent
function Economy.AddMoney(staffSource, targetSource, amount, moneyType, reason)
    print('^3[ECONOMY DEBUG]^0 AddMoney appelé')
    print('^3[ECONOMY DEBUG]^0 staffSource: ' .. tostring(staffSource))
    print('^3[ECONOMY DEBUG]^0 targetSource: ' .. tostring(targetSource))
    print('^3[ECONOMY DEBUG]^0 amount: ' .. tostring(amount))
    print('^3[ECONOMY DEBUG]^0 moneyType: ' .. tostring(moneyType))
    print('^3[ECONOMY DEBUG]^0 reason: ' .. tostring(reason))

    if not Auth.HasPermission(staffSource, 'economy.modify') then
        print('^1[ECONOMY DEBUG]^0 Pas de permission economy.modify')
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    local valid, data = Validators.EconomyData({
        targetId = targetSource,
        amount = amount,
        moneyType = moneyType,
        reason = reason
    })
    if not valid then
        print('^1[ECONOMY DEBUG]^0 Validation echouee: ' .. json.encode(data))
        return false, data
    end

    print('^2[ECONOMY DEBUG]^0 Validation OK, data: ' .. json.encode(data))

    local xTarget = ESX.GetPlayerFromId(data.targetId)
    if not xTarget then
        print('^1[ECONOMY DEBUG]^0 Joueur non trouve')
        return false, Enums.ErrorCode.PLAYER_NOT_FOUND
    end

    local session = Auth.GetSession(staffSource)

    -- Afficher le solde avant
    local bankBefore = xTarget.getAccount('bank').money
    print('^3[ECONOMY DEBUG]^0 Banque AVANT: $' .. tostring(bankBefore))

    -- Ajouter l'argent
    if data.moneyType == Enums.MoneyType.CASH then
        print('^3[ECONOMY DEBUG]^0 Ajout en CASH')
        xTarget.addMoney(data.amount)
    else
        print('^3[ECONOMY DEBUG]^0 Ajout en compte: ' .. tostring(data.moneyType))
        xTarget.addAccountMoney(data.moneyType, data.amount)
    end

    -- Afficher le solde apres
    local bankAfter = xTarget.getAccount('bank').money
    print('^2[ECONOMY DEBUG]^0 Banque APRES: $' .. tostring(bankAfter))

    -- Log dans panel_economy_logs
    Database.Execute([[
        INSERT INTO panel_economy_logs
        (target_identifier, target_name, staff_identifier, staff_name, action, money_type, amount, reason)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        xTarget.getIdentifier(),
        GetPlayerName(data.targetId),
        session.identifier,
        session.name,
        Enums.EconomyAction.ADD,
        data.moneyType,
        data.amount,
        data.reason
    })

    -- Log général
    Database.AddLog(
        Enums.LogCategory.ECONOMY,
        Enums.LogAction.MONEY_ADD,
        session.identifier,
        session.name,
        xTarget.getIdentifier(),
        GetPlayerName(data.targetId),
        {amount = data.amount, type = data.moneyType, reason = data.reason}
    )

    -- Stats
    Database.UpdateDailyStat('money_added', data.amount)

    -- Discord webhook
    if Discord and Discord.LogEconomy then
        Discord.LogEconomy('add', session.name, GetPlayerName(data.targetId), data.amount, data.moneyType, data.reason)
    end

    -- Notifier le joueur
    TriggerClientEvent('panel:notification', targetSource, {
        type = 'success',
        title = 'Argent reçu',
        message = 'Vous avez reçu $' .. Helpers.FormatNumber(data.amount)
    })

    return true
end

-- Retirer de l'argent
function Economy.RemoveMoney(staffSource, targetSource, amount, moneyType, reason)
    if not Auth.HasPermission(staffSource, 'economy.modify') then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    local valid, data = Validators.EconomyData({
        targetId = targetSource,
        amount = amount,
        moneyType = moneyType,
        reason = reason
    })
    if not valid then return false, data end

    local xTarget = ESX.GetPlayerFromId(data.targetId)
    if not xTarget then return false, Enums.ErrorCode.PLAYER_NOT_FOUND end

    local session = Auth.GetSession(staffSource)

    -- Retirer l'argent
    if data.moneyType == Enums.MoneyType.CASH then
        xTarget.removeMoney(data.amount)
    else
        xTarget.removeAccountMoney(data.moneyType, data.amount)
    end

    -- Log
    Database.Execute([[
        INSERT INTO panel_economy_logs
        (target_identifier, target_name, staff_identifier, staff_name, action, money_type, amount, reason)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        xTarget.getIdentifier(),
        GetPlayerName(data.targetId),
        session.identifier,
        session.name,
        Enums.EconomyAction.REMOVE,
        data.moneyType,
        data.amount,
        data.reason
    })

    Database.AddLog(
        Enums.LogCategory.ECONOMY,
        Enums.LogAction.MONEY_REMOVE,
        session.identifier,
        session.name,
        xTarget.getIdentifier(),
        GetPlayerName(data.targetId),
        {amount = data.amount, type = data.moneyType, reason = data.reason}
    )

    Database.UpdateDailyStat('money_removed', data.amount)

    -- Discord webhook
    if Discord and Discord.LogEconomy then
        Discord.LogEconomy('remove', session.name, GetPlayerName(data.targetId), data.amount, data.moneyType, data.reason)
    end

    TriggerClientEvent('panel:notification', targetSource, {
        type = 'warning',
        title = 'Argent retiré',
        message = 'On vous a retiré $' .. Helpers.FormatNumber(data.amount)
    })

    return true
end

-- Définir un montant précis
function Economy.SetMoney(staffSource, targetSource, amount, moneyType, reason)
    if not Auth.HasPermission(staffSource, 'economy.modify') then
        return false, Enums.ErrorCode.NO_PERMISSION
    end

    local valid, data = Validators.EconomyData({
        targetId = targetSource,
        amount = amount,
        moneyType = moneyType,
        reason = reason
    })
    if not valid then return false, data end

    local xTarget = ESX.GetPlayerFromId(data.targetId)
    if not xTarget then return false, Enums.ErrorCode.PLAYER_NOT_FOUND end

    local session = Auth.GetSession(staffSource)

    -- Récupérer le montant actuel
    local currentAmount
    if data.moneyType == Enums.MoneyType.CASH then
        currentAmount = xTarget.getMoney()
    else
        currentAmount = xTarget.getAccount(data.moneyType).money
    end

    -- Calculer la différence et appliquer
    local diff = data.amount - currentAmount
    if diff > 0 then
        if data.moneyType == Enums.MoneyType.CASH then
            xTarget.addMoney(diff)
        else
            xTarget.addAccountMoney(data.moneyType, diff)
        end
    elseif diff < 0 then
        if data.moneyType == Enums.MoneyType.CASH then
            xTarget.removeMoney(math.abs(diff))
        else
            xTarget.removeAccountMoney(data.moneyType, math.abs(diff))
        end
    end

    -- Log
    Database.Execute([[
        INSERT INTO panel_economy_logs
        (target_identifier, target_name, staff_identifier, staff_name, action, money_type, amount, previous_amount, reason)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        xTarget.getIdentifier(),
        GetPlayerName(data.targetId),
        session.identifier,
        session.name,
        Enums.EconomyAction.SET,
        data.moneyType,
        data.amount,
        currentAmount,
        data.reason
    })

    Database.AddLog(
        Enums.LogCategory.ECONOMY,
        Enums.LogAction.MONEY_SET,
        session.identifier,
        session.name,
        xTarget.getIdentifier(),
        GetPlayerName(data.targetId),
        {amount = data.amount, previous = currentAmount, type = data.moneyType, reason = data.reason}
    )

    -- Discord webhook
    if Discord and Discord.LogEconomy then
        Discord.LogEconomy('set', session.name, GetPlayerName(data.targetId), data.amount, data.moneyType, data.reason)
    end

    return true
end

-- ══════════════════════════════════════════════════════════════
-- RÉCUPÉRATION
-- ══════════════════════════════════════════════════════════════

-- Obtenir l'économie d'un joueur
function Economy.GetPlayerMoney(targetSource)
    local xTarget = ESX.GetPlayerFromId(targetSource)
    if not xTarget then return nil end

    return {
        cash = xTarget.getMoney(),
        bank = xTarget.getAccount('bank').money,
        black = xTarget.getAccount('black_money').money
    }
end

-- Obtenir l'historique économique d'un joueur
function Economy.GetPlayerHistory(identifier, limit)
    limit = limit or 50
    return Database.QueryAsync([[
        SELECT * FROM panel_economy_logs
        WHERE target_identifier COLLATE utf8mb4_general_ci = ? COLLATE utf8mb4_general_ci
        ORDER BY created_at DESC
        LIMIT ?
    ]], {identifier, limit})
end

-- Obtenir les comptes de tous les joueurs en ligne (Owner/Admin uniquement)
function Economy.GetAllPlayersAccounts(staffSource)
    -- Vérifier permission (owner ou admin seulement)
    local session = Auth.GetSession(staffSource)
    if not session then return nil, Enums.ErrorCode.NO_PERMISSION end

    local staffGroup = session.group
    if staffGroup ~= 'owner' and staffGroup ~= 'admin' then
        return nil, Enums.ErrorCode.NO_PERMISSION
    end

    local accounts = {}
    local players = Helpers.GetAllPlayers()

    -- Utiliser les données ESX en mémoire (temps réel)
    for _, playerId in ipairs(players) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer then
            local bank = xPlayer.getAccount('bank').money or 0

            table.insert(accounts, {
                id = playerId,
                name = xPlayer.getName(),
                fivemName = GetPlayerName(playerId), -- Nom FiveM/Steam
                license = xPlayer.getIdentifier(),
                bank = bank
            })
        end
    end

    -- Trier par ID
    table.sort(accounts, function(a, b)
        return a.id < b.id
    end)

    return accounts
end

-- Export global
_G.Economy = Economy
