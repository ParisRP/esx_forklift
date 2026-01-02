-- Variables
local ESX = exports.es_extended:getSharedObject()
local PlayerData = {}
local missionActive = false
local forklift = nil
local truck = nil
local driver = nil
local pallets = {}
local palletsLoaded = 0
local totalPallets = 0
local jobPed = nil
local garagePed = nil
local truckBlip = nil
local loadingZone = nil
local jobStarted = false

-- Fonction pour charger un modèle
local function LoadModel(model)
    local modelHash = GetHashKey(model)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(10)
    end
end

-- Fonction de notification
local function ShowNotification(message, type)
    if Config.UseOxLib then
        lib.notify({
            title = 'Forklift Job',
            description = message,
            type = type or 'inform',
            position = 'top'
        })
    else
        ESX.ShowNotification(message)
    end
end

-- Initialisation
CreateThread(function()
    -- Attendre ESX
    while not ESX.IsPlayerLoaded() do
        Wait(500)
    end

    PlayerData = ESX.GetPlayerData()

    -- Créer les peds
    CreatePeds()

    -- Créer le blip principal
    CreateBlip()

    -- Configurer ox_target
    if Config.UseOxTarget then
        SetupTarget()
    end

    print('^2[Forklift] Script client initialisé^7')
end)

-- Créer les peds
function CreatePeds()
    -- Ped du job
    LoadModel(Config.JobLocation.ped.model)
    jobPed = CreatePed(4, Config.JobLocation.ped.model,
        Config.JobLocation.ped.coords.x, Config.JobLocation.ped.coords.y, Config.JobLocation.ped.coords.z,
        Config.JobLocation.ped.coords.w, false, true)

    SetEntityAsMissionEntity(jobPed, true, true)
    SetBlockingOfNonTemporaryEvents(jobPed, true)
    SetEntityInvincible(jobPed, true)
    FreezeEntityPosition(jobPed, true)

    if Config.JobLocation.ped.scenario then
        TaskStartScenarioInPlace(jobPed, Config.JobLocation.ped.scenario, 0, true)
    end

    -- Ped du garage
    LoadModel(Config.JobLocation.garage.ped.model)
    garagePed = CreatePed(4, Config.JobLocation.garage.ped.model,
        Config.JobLocation.garage.ped.coords.x, Config.JobLocation.garage.ped.coords.y, Config.JobLocation.garage.ped.coords.z,
        Config.JobLocation.garage.ped.coords.w, false, true)

    SetEntityAsMissionEntity(garagePed, true, true)
    SetBlockingOfNonTemporaryEvents(garagePed, true)
    SetEntityInvincible(garagePed, true)
    FreezeEntityPosition(garagePed, true)

    if Config.JobLocation.garage.ped.scenario then
        TaskStartScenarioInPlace(garagePed, Config.JobLocation.garage.ped.scenario, 0, true)
    end
end

-- Créer le blip
function CreateBlip()
    local blip = AddBlipForCoord(Config.JobLocation.ped.coords.x, Config.JobLocation.ped.coords.y, Config.JobLocation.ped.coords.z)
    SetBlipSprite(blip, Config.Blips.job.sprite)
    SetBlipColour(blip, Config.Blips.job.color)
    SetBlipScale(blip, Config.Blips.job.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Blips.job.label)
    EndTextCommandSetBlipName(blip)
end

-- Configurer ox_target
function SetupTarget()
    -- Ped du job
    exports.ox_target:addLocalEntity(jobPed, {
        {
            name = 'forklift_start',
            label = Config.Text.startJob,
            icon = Config.Target.icons.signup,
            distance = Config.Target.distance,
            onSelect = function()
                if not missionActive then
                    StartJob()
                end
            end
        },
        {
            name = 'forklift_cancel',
            label = Config.Text.cancelJob,
            icon = Config.Target.icons.signup,
            distance = Config.Target.distance,
            onSelect = function()
                if missionActive then
                    CancelJob()
                end
            end
        }
    })

    -- Ped du garage
    exports.ox_target:addLocalEntity(garagePed, {
        {
            name = 'forklift_take',
            label = Config.Text.takeForklift,
            icon = Config.Target.icons.garage,
            distance = Config.Target.distance,
            onSelect = function()
                if missionActive and not forklift then
                    TakeForklift()
                end
            end
        },
        {
            name = 'forklift_return',
            label = Config.Text.returnForklift,
            icon = Config.Target.icons.garage,
            distance = Config.Target.distance,
            onSelect = function()
                if forklift then
                    ReturnForklift()
                end
            end
        }
    })
end

-- Démarrer le job
function StartJob()
    if missionActive then
        ShowNotification('You already have an active mission!', 'error')
        return
    end

    missionActive = true
    jobStarted = false
    totalPallets = math.random(Config.JobSettings.minPallets, Config.JobSettings.maxPallets)
    palletsLoaded = 0

    -- Créer les palettes
    CreatePallets()

    -- Créer le camion
    CreateTruck()

    ShowNotification(string.format(Config.Text.missionStarted, totalPallets), 'success')
    ShowNotification(Config.Text.goToGarage, 'info')
end

-- Annuler le job
function CancelJob()
    if not missionActive then return end

    -- Supprimer les palettes
    for i = 1, #pallets do
        if pallets[i] and DoesEntityExist(pallets[i]) then
            DeleteEntity(pallets[i])
        end
    end
    pallets = {}

    -- Supprimer le camion
    if truck and DoesEntityExist(truck) then
        DeleteEntity(truck)
    end

    if driver and DoesEntityExist(driver) then
        DeleteEntity(driver)
    end

    -- Retourner le forklift
    if forklift and DoesEntityExist(forklift) then
        DeleteEntity(forklift)
        forklift = nil
    end

    -- Supprimer le blip du camion
    if truckBlip then
        RemoveBlip(truckBlip)
        truckBlip = nil
    end

    -- Réinitialiser
    missionActive = false
    truck = nil
    driver = nil
    palletsLoaded = 0
    totalPallets = 0
    loadingZone = nil
    jobStarted = false

    ShowNotification(Config.Text.missionCanceled, 'error')
end

-- Créer les palettes
function CreatePallets()
    for i = 1, totalPallets do
        local posIndex = ((i-1) % #Config.Pallets.positions) + 1
        local modelIndex = ((i-1) % #Config.Pallets.models) + 1

        local pos = Config.Pallets.positions[posIndex]
        local model = Config.Pallets.models[modelIndex]

        LoadModel(model)

        local palette = CreateObject(GetHashKey(model), pos.x, pos.y, pos.z, true, true, true)
        SetEntityHeading(palette, pos.w)
        FreezeEntityPosition(palette, false)

        pallets[i] = palette

        -- Ajouter ox_target à la palette
        if Config.UseOxTarget then
            exports.ox_target:addLocalEntity(palette, {
                {
                    name = 'palette_' .. i,
                    label = Config.Text.loadPalette,
                    icon = Config.Target.icons.palette,
                    distance = Config.Target.distance,
                    onSelect = function()
                        LoadPalette(palette, i)
                    end
                }
            })
        end
    end
end

-- Créer le camion
function CreateTruck()
    local spawn = Config.JobLocation.truck.spawnCoords

    LoadModel(Config.JobLocation.truck.model)
    LoadModel(Config.JobLocation.truck.driver)

    -- Créer le camion
    truck = CreateVehicle(GetHashKey(Config.JobLocation.truck.model),
        spawn.x, spawn.y, spawn.z, spawn.w, true, true)

    -- Créer le chauffeur
    driver = CreatePedInsideVehicle(truck, 4, GetHashKey(Config.JobLocation.truck.driver), -1, true, true)

    -- Ouvrir la porte arrière
    SetVehicleDoorOpen(truck, Config.JobSettings.truckDoor, false, true) -- true = instant open

    -- Faire attendre le chauffeur
    TaskVehiclePark(driver, truck, spawn.x, spawn.y, spawn.z, spawn.w, 1, 10.0, true)

    -- Créer un blip pour le camion
    truckBlip = AddBlipForEntity(truck)
    SetBlipSprite(truckBlip, Config.Blips.truck.sprite)
    SetBlipColour(truckBlip, Config.Blips.truck.color)
    SetBlipScale(truckBlip, Config.Blips.truck.scale)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Blips.truck.label)
    EndTextCommandSetBlipName(truckBlip)

    -- Calculer la zone de chargement PLUS SIMPLE
    local truckCoords = GetEntityCoords(truck)
    local offset = GetOffsetFromEntityInWorldCoords(truck, -4.0, 0.0, 0.0) -- 4m derrière le camion

    loadingZone = vector3(offset.x, offset.y, offset.z)

    -- DEBUG: Show loading zone (optional)
    if Config.DebugMode then
        CreateThread(function()
            while truck and DoesEntityExist(truck) do
                DrawMarker(1, loadingZone.x, loadingZone.y, loadingZone.z,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    2.0, 2.0, 2.0, 255, 255, 0, 100, false, true, 2, false, nil, nil, false)
                Wait(0)
            end
        end)
    end

    jobStarted = true
end

-- Prendre le forklift
function TakeForklift()
    if forklift then
        ShowNotification('You already have a forklift!', 'error')
        return
    end

    if not missionActive then
        ShowNotification('You need to start a job first!', 'error')
        return
    end

    local spawn = Config.JobLocation.garage.forklift.coords

    LoadModel(Config.JobLocation.garage.forklift.model)

    forklift = CreateVehicle(GetHashKey(Config.JobLocation.garage.forklift.model),
        spawn.x, spawn.y, spawn.z, spawn.w, true, true)

    SetVehicleNumberPlateText(forklift, 'FORK' .. math.random(1000, 9999))

    -- Donner les clés (si ESX vehiclelock existe)
    local plate = GetVehicleNumberPlateText(forklift)

    -- Configurer le carburant
    if Config.UseOxFuel then
        exports.ox_fuel:SetFuel(forklift, 100.0)
    end

    ShowNotification(Config.Text.forkliftTaken, 'success')
end

-- Retourner le forklift
function ReturnForklift()
    if not forklift then
        ShowNotification('You don\'t have a forklift!', 'error')
        return
    end

    DeleteEntity(forklift)
    forklift = nil

    ShowNotification(Config.Text.forkliftReturned, 'success')
end

-- Charger une palette
function LoadPalette(palette, index)
    if not missionActive then
        ShowNotification('No active mission!', 'error')
        return
    end

    if not forklift then
        ShowNotification(Config.Text.noForklift, 'error')
        return
    end

    local playerPed = PlayerPedId()
    if GetVehiclePedIsIn(playerPed, false) ~= forklift then
        ShowNotification(Config.Text.inForklift, 'error')
        return
    end

    if not truck or not DoesEntityExist(truck) then
        ShowNotification('Truck is not here!', 'error')
        return
    end

    -- Vérifier si la porte est ouverte
    if GetVehicleDoorAngleRatio(truck, Config.JobSettings.truckDoor) < 0.5 then
        ShowNotification(Config.Text.truckDoorClosed, 'error')
        return
    end

    -- Vérifier la distance
    local forkliftCoords = GetEntityCoords(forklift)
    local distance = #(forkliftCoords - loadingZone)

    if distance > Config.JobSettings.loadingDistance then
        ShowNotification('Get closer to the loading zone!', 'error')
        return
    end

    -- Supprimer la palette
    if DoesEntityExist(palette) then
        DeleteEntity(palette)
    end
    pallets[index] = nil

    -- Mettre à jour le compteur
    palletsLoaded = palletsLoaded + 1

    -- Effet sonore
    PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true)

    -- Notification
    ShowNotification(string.format(Config.Text.paletteLoaded, palletsLoaded, totalPallets), 'success')

    -- Vérifier si la mission est terminée
    if palletsLoaded >= totalPallets then
        FinishJob()
    end
end

-- Terminer le job
function FinishJob()
    if not missionActive then return end

    -- Calculer la récompense
    local reward = Config.JobSettings.rewardPerPallet * totalPallets

    -- Envoyer au serveur
    TriggerServerEvent('esx_forklift:finishJob', reward)


    -- Fermer la porte
    SetVehicleDoorShut(truck, Config.JobSettings.truckDoor, false)

    -- Faire partir le camion
    if driver and DoesEntityExist(driver) and truck and DoesEntityExist(truck) then
        local leaveCoords = Config.JobLocation.truck.leaveCoords
        TaskVehicleDriveToCoord(driver, truck,
            leaveCoords.x, leaveCoords.y, leaveCoords.z,
            20.0, 0, GetEntityModel(truck), 786603, 5.0)

        -- Supprimer après 30 secondes
        SetTimeout(30000, function()
            if DoesEntityExist(truck) then DeleteEntity(truck) end
            if DoesEntityExist(driver) then DeleteEntity(driver) end
        end)
    end

    -- Supprimer le blip
    if truckBlip then
        RemoveBlip(truckBlip)
        truckBlip = nil
    end

    -- Réinitialiser
    missionActive = false
    pallets = {}
    truck = nil
    driver = nil
    palletsLoaded = 0
    totalPallets = 0
    loadingZone = nil
    jobStarted = false

    -- Retourner le forklift
    if forklift and DoesEntityExist(forklift) then
        DeleteEntity(forklift)
        forklift = nil
    end

    ShowNotification(string.format(Config.Text.missionComplete, reward), 'success')
end

-- Vérifier le chargement automatique
CreateThread(function()
    while true do
        if missionActive and jobStarted and forklift and truck and loadingZone then
            local playerPed = PlayerPedId()
            if GetVehiclePedIsIn(playerPed, false) == forklift then
                local forkliftCoords = GetEntityCoords(forklift)
                local distance = #(forkliftCoords - loadingZone)

                if distance < Config.JobSettings.loadingDistance then
                    -- Vérifier si une palette est proche
                    for i, palette in pairs(pallets) do
                        if palette and DoesEntityExist(palette) then
                            local paletteCoords = GetEntityCoords(palette)
                            local paletteDistance = #(forkliftCoords - paletteCoords)

                            if paletteDistance < 2.0 then
                                -- Vérifier la hauteur (si la palette est soulevée)
                                local heightDiff = paletteCoords.z - forkliftCoords.z
                                if heightDiff > 0.3 and heightDiff < 1.5 then
                                    -- Afficher une aide à l'écran pour appuyer sur E
                                    ShowHelpNotification('Appuyez sur ~INPUT_CONTEXT~ pour charger la palette')

                                    -- Vérifier l'appui sur la touche E (INPUT_CONTEXT)
                                    if IsControlJustReleased(0, 38) then -- 38 est la touche E
                                        LoadPalette(palette, i)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        Wait(0)
    end
end)

-- Nettoyage
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        CancelJob()

        if jobPed and DoesEntityExist(jobPed) then
            DeleteEntity(jobPed)
        end

        if garagePed and DoesEntityExist(garagePed) then
            DeleteEntity(garagePed)
        end
    end
end)

-- Événements ESX
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)