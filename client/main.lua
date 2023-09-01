local QBCore = exports['qb-core']:GetCoreObject()


local onMission = false
local completedMissions = 0

local function getCurrentLevel()
    return completedMissions
end

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
                    label = destinationText,
                    item = pickupItem
                }
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
    local vehicle = CreateVehicle(car, coords.x, coords.y, coords.z, coords.w, true, false)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleEngineOn(vehicle, false, true)
    SetModelAsNoLongerNeeded(vehicle)
    SetVehicleDoorsLocked(vehicle, 2)
    return vehicle
end

-- Spawns the peds for starting missions and links their qb-target from the config.
local function loadMissions()
    for k, v in pairs(Config.Missions) do
        print(v.model)
        Wait(100)
        local ped = createMissionPed(v.model, v.startCoord, v.targetText, v.targetEvent, v.targetIcon, v.levelRequirement)

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

-- Load all needed RegisterNetEvents for all missions dynamically.
local function loadNetEvents()
    for k, v in pairs(Config.Missions) do
        RegisterNetEvent(v.targetEvent, function()
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
                                break
                            end
                        end
                end
            end)
            end
        RegisterNetEvent(v.finishEvent, function()
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
            end
        end)
        Wait(100)
    end)
end
end




-- Start the script.
RegisterCommand('mStart', function()
    print(onMission)
    loadMissions()
    loadNetEvents()
end)

RegisterCommand('mDebug', function()
    print(Config.Missions['mission1'].name)
    print(Config.Missions['mission1'].targetEvent)
end)