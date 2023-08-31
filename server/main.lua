local QBCore = exports['qb-core']:GetCoreObject()

TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)

RegisterServerEvent('hz-mission:getItem', function(itemReward, finishedMessage)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
	Player.Functions.AddItem(itemReward, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemReward], 'add')
    TriggerClientEvent('QBCore:Notify', src, finishedMessage)
end)