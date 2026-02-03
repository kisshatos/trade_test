local QBCore = exports['qb-core']:GetCoreObject()

local function promptInput(title, text)
    local dialog = exports['qb-input']:ShowInput({
        header = title,
        submitText = 'OK',
        inputs = {
            {
                text = text,
                name = 'value',
                type = 'number',
                isRequired = true
            }
        }
    })

    if dialog and dialog.value then
        return tonumber(dialog.value)
    end

    return nil
end

RegisterCommand('gs_assign', function(_, args)
    local targetId = tonumber(args[1])
    local stationId = tonumber(args[2])
    if not targetId or not stationId then
        QBCore.Functions.Notify('Usage: /gs_assign [playerId] [stationId]', 'error')
        return
    end
    TriggerServerEvent('qb-gastanks:server:assignBusiness', targetId, stationId)
end)

RegisterCommand('gs_upgrade', function(_, args)
    local stationId = tonumber(args[1])
    local tankType = args[2]
    if not stationId or not tankType then
        QBCore.Functions.Notify('Usage: /gs_upgrade [stationId] [small|medium|large]', 'error')
        return
    end
    TriggerServerEvent('qb-gastanks:server:upgradeTank', stationId, tankType)
end)

RegisterCommand('gs_order', function(_, args)
    local stationId = tonumber(args[1])
    local liters = tonumber(args[2])
    if not stationId then
        QBCore.Functions.Notify('Usage: /gs_order [stationId] [liters]', 'error')
        return
    end

    if not liters then
        liters = promptInput('Fuel Order', 'Liters to order')
    end

    if not liters or liters <= 0 then
        QBCore.Functions.Notify('Invalid liters.', 'error')
        return
    end

    TriggerServerEvent('qb-gastanks:server:orderFuel', stationId, liters)
end)

RegisterCommand('gs_claim', function(_, args)
    local stationId = tonumber(args[1])
    if not stationId then
        QBCore.Functions.Notify('Usage: /gs_claim [stationId]', 'error')
        return
    end
    TriggerServerEvent('qb-gastanks:server:claimOrder', stationId)
end)

RegisterCommand('gs_deliver', function(_, args)
    local stationId = tonumber(args[1])
    if not stationId then
        QBCore.Functions.Notify('Usage: /gs_deliver [stationId]', 'error')
        return
    end
    TriggerServerEvent('qb-gastanks:server:deliverFuel', stationId)
end)
