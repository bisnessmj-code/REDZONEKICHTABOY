local function getFirstItemInDrop(dropId)
	local drop = Drops[dropId]
	if drop and drop.items then
		for k, v in pairs(drop.items) do
			return v
		end
	end
	return nil
end

function TimeoutFunction(wait, fn)
	CreateThread(function()
		Wait(wait)
		fn()
	end)
end

function SaveOtherInventories()
	for inventoryName, inventory in pairs(UpdatedInventories) do
		for id, updated in pairs(inventory) do
			if updated then
				SaveOtherInventory(inventoryName, id)
				UpdatedInventories[inventoryName][id] = nil
			end
		end
	end
end

---@param inventoryName OtherInventoryTypes
---@param id string
function SaveOtherInventory(inventoryName, id)
	Debug('SaveOtherInventory', inventoryName, id)
	if inventoryName == 'stash' then
		SaveStashItems(id, Stashes[id].items)
	elseif inventoryName == 'trunk' then
		SaveOwnedVehicleItems(id, Trunks[id].items)
	elseif inventoryName == 'glovebox' then
		SaveOwnedGloveboxItems(id, Gloveboxes[id].items)
	elseif inventoryName == 'clothes' then
		local src = GetPlayerSourceFromIdentifier(id)
		if not src then
			Error('SaveOtherInventory', 'Player not found', id, 'inventoryName', inventoryName)
			return
		end
		SaveClotheItems(id, GetClotheItems(src))
	end
end

function HandleCloseSecondInventories(src, type, id)
	local IsVehicleOwned = IsVehicleOwned(id)
	Debug('HandleSaveSecondInventories', src, type, id, IsVehicleOwned)
	if type == 'trunk' then
		if not Trunks[id] then
			Debug('Trunk id not found', id)
			return
		end
		if IsVehicleOwned then
			SaveOwnedVehicleItems(id, Trunks[id].items)
		else
			Trunks[id].isOpen = false
		end
	elseif type == 'glovebox' then
		if not Gloveboxes[id] then return end
		if IsVehicleOwned then
			SaveOwnedGloveboxItems(id, Gloveboxes[id].items)
		else
			Gloveboxes[id].isOpen = false
		end
	elseif type == 'stash' then
		if not Stashes[id] then
			return
		end
		SaveStashItems(id, Stashes[id].items)
		Stashes[id].isOpen = false -- IMPORTANT: Libérer le stash pour pouvoir le rouvrir
	elseif type == 'drop' then
		if Drops[id] then
			Drops[id].isOpen = false
			if Drops[id].items == nil or next(Drops[id].items) == nil then
				Drops[id] = nil
				TimeoutFunction(500, function()
					TriggerClientEvent(Config.InventoryPrefix .. ':client:RemoveDropItem', -1, id)
				end)
			else
				local dropItemsCount = table.length(Drops[id].items)
				local firstItem = getFirstItemInDrop(id)
				local dropObject = Config.ItemDropObject
				if firstItem then
					dropObject = dropItemsCount == 1 and ItemList[firstItem.name:lower()].object or Config.ItemDropObject
				end
				TimeoutFunction(500, function()
					TriggerClientEvent(Config.InventoryPrefix .. ':updateDropItems', -1, id, dropObject, dropItemsCount == 1 and firstItem or nil)
				end)
			end
		end
	elseif type == 'clothing' and Config.Clothing then
		local identifier = GetPlayerIdentifier(src)
		local clotheItems = GetClotheItems(src)
		if not clotheItems then return end
		SaveClotheItems(identifier, clotheItems)
	end
end

-- Fonction pour sauvegarder et fermer le stash d'un joueur
-- (OpenStashByPlayer et RegisterOpenStash sont définis dans StashPersistence.lua)
local function SaveAndClosePlayerStash(src)
	local stashId = GetOpenStash(src)
	if stashId and Stashes and Stashes[stashId] then
		SaveStashItems(stashId, Stashes[stashId].items)
		Stashes[stashId].isOpen = false
		CloseOpenStash(src)
	elseif stashId then
		CloseOpenStash(src)
	end
end

RegisterNetEvent(Config.InventoryPrefix .. ':server:handleInventoryClosed', function(type, id)
	local src = source

	-- IMPORTANT: Si ce joueur avait un stash ouvert, le sauvegarder
	-- (car qs-inventory envoie parfois le mauvais type)
	if GetOpenStash and GetOpenStash(src) then
		SaveAndClosePlayerStash(src)
	end

	HandleCloseSecondInventories(src, type, id)
	UpdateFrameworkInventory(src, Inventories[src])
end)

-- Sauvegarder le stash si le joueur se déconnecte
AddEventHandler('playerDropped', function(reason)
	local src = source
	if GetOpenStash and GetOpenStash(src) then
		SaveAndClosePlayerStash(src)
	end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		-- Sauvegarder tous les stash ouverts par des joueurs
		if OpenStashByPlayer then
			for src, stashId in pairs(OpenStashByPlayer) do
				if Stashes and Stashes[stashId] and Stashes[stashId].items then
					SaveStashItems(stashId, Stashes[stashId].items)
				end
			end
		end
		SaveOtherInventories()
	end
end)

-- RegisterCommand('save-inventories', function(source, args)
-- 	if source ~= 0 then
-- 		return Error(source, 'This command can use only by console')
-- 	end
-- 	SaveOtherInventories()
-- end)

-- CreateThread(function()
-- 	while true do
-- 		Wait(Config.SaveInventoryInterval)
-- 		SaveOtherInventories()
-- 	end
-- end)
