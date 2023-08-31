local QBCore = exports['qb-core']:GetCoreObject()


local onMission = false

local function createMissionPed(model, startCoord, targetText, targetEvent, targetIcon)
	local hash = GetHashKey(model)
    local coords = startCoord

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
    exports['qb-target']:AddTargetEntity(ped, {
        options = {
            {
                type = "client",
                event = targetEvent,
                icon = targetIcon,
                label = targetText,
                canInteract = function()
                    if onMission == false then return true
                end
            end
            }
        },
        distance = 2.0
    })
end

local function createGotoPed(destinationModel, destination, destinationText, finishEvent, icon)
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

local function loadMissions()
    for k, v in pairs(Config.Missions) do
        print(v.model)
        Wait(100)
        local ped = createMissionPed(v.model, v.startCoord, v.targetText, v.targetEvent, v.targetIcon)

    end
end


local function loadNetEvents()
    for k, v in pairs(Config.Missions) do
        RegisterNetEvent(v.targetEvent, function()
            if v.type == "goto" then
                print(v.destination)
                destination = v.destination
                destinationPed = createGotoPed(v.destinationModel, v.destination, v.destinationText, v.finishEvent, v.targetIcon)
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
                                Wait(90000)
                                DeleteVehicle(delveh)
                                onMission = false
                                break
                            end
                        end
                end
                end)
            end
        RegisterNetEvent(v.finishEvent, function()
            if onMission == true then
            RemoveBlip(blip)
            print(v.itemReward)
            local reward = v.itemReward
            local finishedMessage = v.finishedMessage
            print("HELL")
            TriggerServerEvent("hz-mission:getItem", reward, finishedMessage)
            exports['qb-target']:RemoveTargetEntity(destinationPed, 'Test')
            DeletePed(destinationPed)
            onMission = false
            end
        end)
        Wait(100)
    end)
end
end





RegisterCommand('mStart', function()
    print(onMission)
    loadMissions()
    loadNetEvents()
end)

RegisterCommand('mDebug', function()
    print(Config.Missions['mission1'].name)
    print(Config.Missions['mission1'].targetEvent)
end)