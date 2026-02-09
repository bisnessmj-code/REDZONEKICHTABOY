--[[
    Module Staff Chat - Panel Admin Fight League
    Chat interne pour le staff
]]

local StaffChat = {}

-- ══════════════════════════════════════════════════════════════
-- FONCTIONS PRINCIPALES
-- ══════════════════════════════════════════════════════════════

-- Obtenir tous les messages
function StaffChat.GetMessages()
    local messages = Database.QueryAsync([[
        SELECT id, staff_identifier, staff_name, staff_group, message, created_at
        FROM panel_staff_chat
        ORDER BY created_at ASC
        LIMIT 100
    ]], {})

    return messages or {}
end

-- Envoyer un message
function StaffChat.SendMessage(staffIdentifier, staffName, staffGroup, message)
    if not message or message == '' then
        return false, 'MESSAGE_EMPTY'
    end

    -- Limiter la taille du message
    if #message > 500 then
        message = string.sub(message, 1, 500)
    end

    local id = Database.InsertAsync([[
        INSERT INTO panel_staff_chat (staff_identifier, staff_name, staff_group, message)
        VALUES (?, ?, ?, ?)
    ]], {staffIdentifier, staffName, staffGroup, message})

    if id and id > 0 then
        return true, id
    end

    return false, 'INSERT_FAILED'
end

-- Supprimer un message
function StaffChat.DeleteMessage(staffIdentifier, staffGroup, messageId)
    if Config.Debug then print('[STAFF CHAT] DeleteMessage called - identifier: ' .. tostring(staffIdentifier) .. ', group: ' .. tostring(staffGroup) .. ', messageId: ' .. tostring(messageId)) end

    -- Verifier si c'est le proprietaire du message ou un admin/owner
    local group = string.lower(staffGroup or '')
    local isAdmin = group == 'admin' or group == 'owner'

    if Config.Debug then print('[STAFF CHAT] isAdmin: ' .. tostring(isAdmin)) end

    -- Verifier d'abord si le message existe
    local existingMsg = Database.SingleAsync([[
        SELECT id, staff_identifier FROM panel_staff_chat WHERE id = ?
    ]], {messageId})

    if not existingMsg then
        if Config.Debug then print('[STAFF CHAT] Message not found in database') end
        return false, 'MESSAGE_NOT_FOUND'
    end

    if Config.Debug then print('[STAFF CHAT] Message found - owner: ' .. tostring(existingMsg.staff_identifier)) end

    -- Si pas admin, verifier que c'est son propre message
    if not isAdmin then
        if existingMsg.staff_identifier ~= staffIdentifier then
            if Config.Debug then print('[STAFF CHAT] Not owner and not admin - denied') end
            return false, 'NOT_YOUR_MESSAGE'
        end
    end

    -- Supprimer le message
    if Config.Debug then print('[STAFF CHAT] Deleting message...') end
    Database.ExecuteAsync('DELETE FROM panel_staff_chat WHERE id = ?', {messageId})
    return true
end

-- Supprimer tous les messages (admin/owner uniquement)
function StaffChat.ClearAll(staffGroup)
    local group = string.lower(staffGroup or '')
    if group ~= 'admin' and group ~= 'owner' then
        return false, 'NO_PERMISSION'
    end

    Database.ExecuteAsync('DELETE FROM panel_staff_chat', {})
    return true
end

-- Compter le staff en ligne
function StaffChat.GetOnlineStaffCount()
    local count = 0
    local xPlayers = ESX.GetExtendedPlayers()

    for _, xPlayer in pairs(xPlayers) do
        local session = Auth.GetSession(xPlayer.source)
        if session then
            count = count + 1
        end
    end

    return count
end

-- ══════════════════════════════════════════════════════════════
-- CALLBACKS SERVEUR
-- ══════════════════════════════════════════════════════════════

-- Obtenir les messages du chat staff
ESX.RegisterServerCallback('panel:getStaffChatMessages', function(source, cb)
    local session = Auth.GetSession(source)
    if not session then
        cb({success = false, error = 'NOT_AUTHENTICATED'})
        return
    end

    local messages = StaffChat.GetMessages()
    local onlineStaff = StaffChat.GetOnlineStaffCount()

    cb({
        success = true,
        messages = messages,
        onlineStaff = onlineStaff
    })
end)

-- Envoyer un message
ESX.RegisterServerCallback('panel:sendStaffChatMessage', function(source, cb, message)
    local session = Auth.GetSession(source)
    if not session then
        cb({success = false, error = 'NOT_AUTHENTICATED'})
        return
    end

    local success, result = StaffChat.SendMessage(
        session.identifier,
        session.name,
        session.group,
        message
    )

    if success then
        cb({success = true, messageId = result})
    else
        cb({success = false, error = result})
    end
end)

-- Supprimer un message
ESX.RegisterServerCallback('panel:deleteStaffChatMessage', function(source, cb, messageId)
    local session = Auth.GetSession(source)
    if not session then
        if Config.Debug then print('[STAFF CHAT] deleteStaffChatMessage - No session') end
        cb({success = false, error = 'NOT_AUTHENTICATED'})
        return
    end

    if Config.Debug then print('[STAFF CHAT] deleteStaffChatMessage - Session: ' .. tostring(session.identifier) .. ', group: ' .. tostring(session.group) .. ', messageId: ' .. tostring(messageId)) end

    local success, err = StaffChat.DeleteMessage(
        session.identifier,
        session.group,
        messageId
    )

    if Config.Debug then print('[STAFF CHAT] deleteStaffChatMessage result - success: ' .. tostring(success) .. ', error: ' .. tostring(err)) end
    cb({success = success, error = err})
end)

-- Supprimer tous les messages (admin/owner)
ESX.RegisterServerCallback('panel:clearStaffChat', function(source, cb)
    local session = Auth.GetSession(source)
    if not session then
        cb({success = false, error = 'NOT_AUTHENTICATED'})
        return
    end

    local success, err = StaffChat.ClearAll(session.group)

    if success then
        -- Log l'action
        Database.AddLog(
            Enums.LogCategory.SYSTEM,
            'staff_chat_clear',
            session.identifier,
            session.name,
            nil, nil,
            {action = 'clear_all_messages'}
        )
        cb({success = true})
    else
        cb({success = false, error = err})
    end
end)

-- Export global
_G.StaffChat = StaffChat
