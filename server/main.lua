local QBCore = exports['qb-core']:GetCoreObject()

TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)

RegisterServerEvent('hz-mission:getItem', function(itemReward, finishedMessage)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
	Player.Functions.AddItem(itemReward, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemReward], 'add')
    TriggerClientEvent('QBCore:Notify', src, finishedMessage)
end)

RegisterServerEvent('hz-mission:removeItem', function(item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.Functions.RemoveItem(item, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'remove')
end)

RegisterServerEvent('hz-mission:gta:getReward', function(type, finishedMessage, rewardAmount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.Functions.AddMoney(type, rewardAmount, "gtamoney")
    TriggerClientEvent('QBCore:Notify', src, finishedMessage)
end)

RegisterServerEvent('hz-mission:server:loadMissions', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local items = {}
	local result = MySQL.scalar.await('SELECT items FROM stashitems WHERE stash = ?', {Player})
	if not result then return items end

	local stashItems = json.decode(result)
	if not stashItems then return items end

	for _, item in pairs(stashItems) do
		local itemInfo = QBCore.Shared.Items[item.name:lower()]
		if itemInfo then
			items[item.slot] = {
				name = itemInfo["name"],
				amount = tonumber(item.amount),
				info = item.info or "",
				label = itemInfo["label"],
				description = itemInfo["description"] or "",
				weight = itemInfo["weight"],
				type = itemInfo["type"],
				unique = itemInfo["unique"],
				useable = itemInfo["useable"],
				image = itemInfo["image"],
				created = item.created,
				slot = item.slot,
			}
		end
	end
	return items
end)

RegisterNetEvent('hz-mission:server:saveLevels', function(karma, level)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    MySQL.insert.await('INSERT INTO `missions` (license, citizenid, karma, level) VALUES (?, ?, ?)', {
        Player['PlayerData']['license'],Player['PlayerData']['citizenid'], karma, level
    })



end)