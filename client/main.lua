local QBCore = exports['qb-core']:GetCoreObject()


local onMission = false
local completedMissions = 5
local missionPedLoaded = false
local eventsLoaded = false
local finishedCounter = 0
local karma = 0

local function getCurrentLevel()
    return completedMissions
end


local function getMissionStatus()
    return onMission
end

RegisterNetEvent("checkLevelRequirement", function(levelRequirement)
    print(levelRequirement)
    print(getCurrentLevel())
    if levelRequirement <= getCurrentLevel() then return false end
end)

-- Template function for creating missionPeds based on the config.
local function createMissionPed(model, startCoord, targetText, targetEvent, targetIcon, levelRequirement)
	local hash = GetHashKey(model)
    local coords = startCoord
    local level = completedMissions
    if not levelRequirement then
        levelRequirement = 0
    end

    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end
    local ped = CreatePed(5, hash, coords.x, coords.y, coords.z-1, coords.w, true, false)
	while not DoesEntityExist(ped) do Wait(10) end
    SetEntityHeading(ped, 180.0)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetModelAsNoLongerNeeded(ped)
    Wait(500)
    print(levelRequirement)
    print(level)
    exports['qb-target']:AddTargetEntity(ped, {
        options = {
            {
                type = "client",
                event = targetEvent,
                icon = targetIcon,
                label = targetText,
                canInteract = function()
                    -- level req not working. Not updating after finishing mission. Qbtarget not detecting change
                    if onMission == false and levelRequirement <= getCurrentLevel() then return true end
            end
            }
        },
        distance = 2.0
    })
end

-- Creates the destinationPed for "goto" missions and links their qb-target from the config.
local function createGotoPed(destinationModel, destination, destinationText, finishEvent, icon, pickupItem)
    local hash = GetHashKey(destinationModel)
    local coords = destination

    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end
    local destinationPed = CreatePed(5, hash, coords.x, coords.y, coords.z-1, coords.w, true, false)
    while not DoesEntityExist(destinationPed) do Wait(10) end
    SetEntityHeading(destinationPed, 180.0)
    FreezeEntityPosition(destinationPed, true)
    SetEntityInvincible(destinationPed, true)
    SetBlockingOfNonTemporaryEvents(destinationPed, true)
    SetModelAsNoLongerNeeded(destinationPed)
    Wait(500)
    if pickupItem == "" then
    exports['qb-target']:AddTargetEntity(destinationPed, {
        options = {
            {
                type = "client",
                event = finishEvent,
                icon = icon,
                label = destinationText
            }
        },
        distance = 2.0
    })
    end
    if pickupItem ~= "" then
        exports['qb-target']:AddTargetEntity(destinationPed, {
            options = {
                {
                    type = "client",
                    event = finishEvent,
                    icon = icon,
                    label = "Gi " .. pickupItem,
                    item = pickupItem
                },
                {
                    type = "client",
                    icon = icon,
                    label = "Har du " .. pickupItem .. "?"
                },
            },
            distance = 2.0
        })
        end
    return destinationPed
end

-- Spawns a car at a set location, and sets a blip to the car.
local function createStealCar(model, destination)
    local car = GetHashKey(model)
    local coords = destination
    RequestModel(car)
    while not HasModelLoaded(car) do Wait(10) end
    local vehicle = CreateVehicle(car, coords.x, coords.y, coords.z, 0, true, false)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleEngineOn(vehicle, false, true)
    SetModelAsNoLongerNeeded(vehicle)
    SetVehicleDoorsLocked(vehicle, 2)
    return vehicle
end

-- Spawns the peds for starting missions and links their qb-target from the config.
local function loadMissions()
    print("Loading missionPeds")
    if missionPedLoaded == false then
        for k, v in pairs(Config.Missions) do
            print(v.model)
            Wait(100)
            local ped = createMissionPed(v.model, v.startCoord, v.targetText, v.targetEvent, v.targetIcon, v.levelRequirement)
        end
        missionPedLoaded = true
    else
        print("Mission ped already loaded")
    end
end

-- Function for handling animation for goto missions.
local function deliverAnimation(ped)
    -- Face each other
        local playerPed = PlayerPedId()
        FreezeEntityPosition(ped, false)
		TaskTurnPedToFaceEntity(ped, playerPed, 1.0)
		TaskTurnPedToFaceEntity(playerPed, ped, 1.0)
		Wait(1500)
		PlayAmbientSpeech1(ped, "Generic_Hi", "Speech_Params_Force")
		Wait(1000)

		-- Playerped animation
		RequestAnimDict("mp_safehouselost@")
    	while not HasAnimDictLoaded("mp_safehouselost@") do Wait(10) end
    	TaskPlayAnim(playerPed, "mp_safehouselost@", "package_dropoff", 8.0, 1.0, -1, 16, 0, 0, 0, 0)
		Wait(800)
		
		-- Oxyped animation
		PlayAmbientSpeech1(ped, "Chat_State", "Speech_Params_Force")
		Wait(500)
		RequestAnimDict("mp_safehouselost@")
		while not HasAnimDictLoaded("mp_safehouselost@") do Wait(10) end
		TaskPlayAnim(ped, "mp_safehouselost@", "package_dropoff", 8.0, 1.0, -1, 16, 0, 0, 0, 0 )
		Wait(3000)

end


local function loadPostProp(location)
    local modelHash = `prop_cardbordbox_03a` -- The ` return the jenkins hash of a string. see more at: https://cookbook.fivem.net/2019/06/23/lua-support-for-compile-time-jenkins-hashes/
    local spawnLocation = vector4(location.x, location.y-6, location.z, location.w)

    if not HasModelLoaded(modelHash) then
        -- If the model isnt loaded we request the loading of the model and wait that the model is loaded
        RequestModel(modelHash)

        while not HasModelLoaded(modelHash) do
            Citizen.Wait(1)
        end
    end

    -- At this moment the model its loaded, so now we can create the object
    local obj = CreateObject(modelHash, spawnLocation, true)
    PlaceObjectOnGroundProperly_2(obj)
    FreezeEntityPosition(obj, true)
    exports['qb-target']:AddTargetEntity(obj, {
        options = {
            {
                type = "client",
                action = function(obj)
                    TriggerEvent('hz-mission:post:pickup', obj)
                end,
                icon = "fa-solid fa-truck-fast",
                label = "Stjel"
            }
        },
        distance = 2.0
    })
    return obj
end
-- Load all needed RegisterNetEvents for all missions dynamically.
local function loadNetEvents()
    print("Loading events")
    if eventsLoaded == false then
        for k, v in pairs(Config.Missions) do
            RegisterNetEvent(v.targetEvent, function()
                lib.notify({
                    title = 'Du startet oppdraget ' .. v.name .. '.',
                    description = 'Lykke til',
                    type = 'success',
                    position = 'top'
                })
                if v.type == "goto" then
                    print(v.destination)
                    destination = v.destination
                    destinationPed = createGotoPed(v.destinationModel, v.destination, v.destinationText, v.finishEvent, v.targetIcon, v.pickupItem)
                    blip = AddBlipForCoord(destination.x, destination.y, destination.z)
                    SetBlipRoute(blip, true)
                    onMission = true
                end
                if v.type == 'gta' then
                    local carPickedUp = false
                    local car = createStealCar(v.carModel, v.destination)
                    --Create thread to check if player is inside car and if so, set gps for a destination and then break thread.
                    blip = AddBlipForEntity(car)
                    SetBlipSprite(blip, 225)
                    SetBlipColour(blip, 1)
                    SetBlipRoute(blip, true)
                    BeginTextCommandSetBlipName("STRING")
                    AddTextComponentString(v.carName)
                    EndTextCommandSetBlipName(blip)
                    onMission = true
                    CreateThread(function()
                        while onMission == true do
                            Wait(1000)
                            local playerPed = PlayerPedId()
                            local playerCoords = GetEntityCoords(playerPed)
                            local carCoords = v.destination
                            local distance = Vdist(playerCoords.x, playerCoords.y, playerCoords.z, carCoords.x, carCoords.y, carCoords.z)
                            print(distance)
                            if distance < 1.0 then
                                print("Player is in car")
                                SetBlipRoute(blip, false)
                                RemoveBlip(blip)
                                blip = AddBlipForCoord(v.carDeliverDestination.x, v.carDeliverDestination.y, v.carDeliverDestination.z)
                                SetBlipRoute(blip, true)
                                carPickedUp = true
                                break
                            end
                        end
                    end)
                    CreateThread(function()
                        while onMission == true do
                            Wait(1000)
                            print("this live")
                            if carPickedUp == true then
                                local playerPed = PlayerPedId()
                                local playerCoords = GetEntityCoords(playerPed)
                                local deliverCoords = v.carDeliverDestination
                                local distance = Vdist(playerCoords.x, playerCoords.y, playerCoords.z, deliverCoords.x, deliverCoords.y, deliverCoords.z)
                                print("Checking car to deliver dist")
                                print(distance)
                                if distance < 2.0 then
                                    print("Player is at deliver destination")
                                    RemoveBlip(blip)
                                    SetBlipRoute(blip, false)
                                    delveh = GetVehiclePedIsIn(playerPed, false)
                                    TaskLeaveAnyVehicle(playerPed, 0, 0)
                                    SetVehicleDoorsLocked(delveh, 2)
                                    Wait(10000)
                                    DeleteVehicle(delveh)
                                    onMission = false
                                    completedMissions = completedMissions + 1
                                    TriggerServerEvent("hz-mission:gta:getReward", v.paymentType, v.finishedMessage, v.rewardAmount)
                                    break
                                end
                            end
                    end
                end)
                end
            if v.type == "post" then
                local robbed = false
                local car = createStealCar(v.carModel, v.destination)
                --Create thread to check if player is inside car and if so, set gps for a destination and then break thread.
                SetVehicleDoorOpen(car, 3, false, false)
                SetVehicleDoorOpen(car, 2, false, false)
                Wait(100)
                obj = loadPostProp(v.destination)
                blip = AddBlipForEntity(car)
                SetBlipSprite(blip, 225)
                SetBlipColour(blip, 1)
                SetBlipRoute(blip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(v.carName)
                EndTextCommandSetBlipName(blip)
                onMission = true
                Wait(10000)
                DeleteObject(obj)
                DeleteVehicle(car)
            end
            Finisher = AddEventHandler(v.finishEvent, function()
                if onMission == true then
                    exports['qb-target']:RemoveTargetEntity(destinationPed)
                    RemoveBlip(blip)
                    print(v.itemReward)
                    local reward = v.itemReward
                    local finishedMessage = v.finishedMessage
                    deliverAnimation(destinationPed)
                    if v.pickupItem then
                        TriggerServerEvent("hz-mission:removeItem", v.pickupItem)
                    end
                    TriggerServerEvent("hz-mission:getItem", reward, finishedMessage)
                    -- Ped wander off/delete
                    TaskWanderStandard(destinationPed, 10.0, 10)
                    Wait(10000)
                    DeletePed(destinationPed)
                    onMission = false
                    completedMissions = completedMissions + 1
                    RemoveEventHandler(Finisher)
                end
            end)
            Wait(100)
        end)
        eventsLoaded = true
    end
end
end


RegisterNetEvent('hz-mission:post:pickup', function(prop)
    FreezeEntityPosition(prop, false)
    AttachEntityToEntity(prop, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 57005), 10, 0, 10, 10, 100, 0, false, false, false, false, 2, true)
end)



-- Start the script.
RegisterCommand('mStart', function()
    print(onMission)
    loadMissions()
    loadNetEvents()
end)

RegisterCommand('mInsert', function(karma)
    level = getCurrentLevel()
    TriggerServerEvent('hz-mission:server:saveLevels',level, karma)
end)