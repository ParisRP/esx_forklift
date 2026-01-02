local ESX = exports['es_extended']:getSharedObject()

-- Événement pour terminer le job
RegisterNetEvent('esx_forklift:finishJob')
AddEventHandler('esx_forklift:finishJob', function(reward)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if not xPlayer then return end

    -- Vérification anti-triche (distance)
    local ped = GetPlayerPed(src)
    local pedCoords = GetEntityCoords(ped)
    local jobCoords = vector3(153.81, -3214.6, 4.93)
    local distance = #(pedCoords - jobCoords)

    if distance > Config.JobSettings.distanceCheck then
        print(('^3[Forklift] ^1Tentative de triche détectée: %s (trop loin: %sm)^7'):format(
            xPlayer.identifier, math.floor(distance)))
        return
    end

    -- Vérifier le montant
    local maxReward = Config.JobSettings.rewardPerPallet * Config.JobSettings.maxPallets
    if reward > maxReward then
        print(('^3[Forklift] ^1Tentative de triche détectée: %s (récompense trop élevée: $%s)^7'):format(
            xPlayer.identifier, reward))
        return
    end

    -- Donner l'argent
    xPlayer.addMoney(reward)

    -- Log
    print(('^3[Forklift] ^2%s a terminé une mission et reçu $%s^7'):format(
        xPlayer.identifier, reward))

    -- Notification
    TriggerClientEvent('esx:showNotification', src, 'You received $' .. reward .. ' for the job!')
end)

-- Callback pour vérifier si un joueur peut faire le job
ESX.RegisterServerCallback('esx_forklift:canWork', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    cb(xPlayer ~= nil)
end)

-- Commande de test (admin)
RegisterCommand('testforklift', function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer and xPlayer.getGroup() == 'admin' then
        TriggerClientEvent('esx:showNotification', source, 'Forklift system is working!')
        print('[Forklift] System test by admin: ' .. xPlayer.identifier)
    end
end, false)

-- Log de démarrage
AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        print('^2[Forklift] ^7Script serveur démarré avec succès')
        print('^2[Forklift] ^7Utilisation de oxmysql: OK')

        if Config.UseOxLib then
            print('^2[Forklift] ^7Utilisation de ox_lib: OK')
        end
        if Config.UseOxTarget then
            print('^2[Forklift] ^7Utilisation de ox_target: OK')
        end
        if Config.UseOxFuel then
            print('^2[Forklift] ^7Utilisation de ox_fuel: OK')
        end
    end
end)