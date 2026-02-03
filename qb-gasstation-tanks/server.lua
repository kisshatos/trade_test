local QBCore = exports['qb-core']:GetCoreObject()

local RESOURCE_NAME = GetCurrentResourceName()
local DATA_FILE = 'data/gasstations.json'

local Stations = {}

local function isAdmin(player)
    local group = player.PlayerData.group
    for _, allowed in ipairs(Config.AdminGroups) do
        if group == allowed then
            return true
        end
    end
    return false
end

local function getStation(stationId)
    return Stations[stationId]
end

local function getTankCapacity(tankType)
    local tank = Config.TankTypes[tankType]
    if not tank then
        return 0
    end
    return tank.capacity
end

local function saveStations()
    SaveResourceFile(RESOURCE_NAME, DATA_FILE, json.encode(Stations, { indent = true }), -1)
end

local function loadStations()
    local raw = LoadResourceFile(RESOURCE_NAME, DATA_FILE)
    if raw then
        local decoded = json.decode(raw)
        if decoded then
            Stations = decoded
            return
        end
    end

    for stationId in pairs(Config.Stations) do
        Stations[stationId] = {
            owner = nil,
            tankType = Config.DefaultTankType,
            fuel = 0,
            pendingOrder = nil,
            lastUpgradeAt = 0
        }
    end
    saveStations()
end

local function createOrder(station, amount)
    station.pendingOrder = {
        liters = amount,
        createdAt = os.time(),
        claimedBy = nil
    }
end

local function canUpgrade(station)
    local cooldownSeconds = Config.UpgradeCooldownHours * 3600
    return (os.time() - (station.lastUpgradeAt or 0)) >= cooldownSeconds
end

local function payPlayer(source, amount, account)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then
        return false
    end
    return player.Functions.RemoveMoney(account or 'bank', amount)
end

local function givePlayer(source, amount, account)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then
        return false
    end
    player.Functions.AddMoney(account or 'bank', amount)
    return true
end

local function isAllowedDeliveryJob(player)
    for _, job in ipairs(Config.DeliveryJob.allowedJobs) do
        if player.PlayerData.job.name == job then
            return true
        end
    end
    return false
end

local function ensureStationData(stationId)
    if not Stations[stationId] then
        Stations[stationId] = {
            owner = nil,
            tankType = Config.DefaultTankType,
            fuel = 0,
            pendingOrder = nil,
            lastUpgradeAt = 0
        }
    end
end

RegisterNetEvent('qb-gastanks:server:assignBusiness', function(targetId, stationId)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player or not isAdmin(player) then
        TriggerClientEvent('QBCore:Notify', src, 'No permission.', 'error')
        return
    end

    local target = QBCore.Functions.GetPlayer(tonumber(targetId))
    if not target then
        TriggerClientEvent('QBCore:Notify', src, 'Target not found.', 'error')
        return
    end

    stationId = tonumber(stationId)
    if not Config.Stations[stationId] then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid station.', 'error')
        return
    end

    ensureStationData(stationId)
    Stations[stationId].owner = target.PlayerData.citizenid
    saveStations()

    TriggerClientEvent('QBCore:Notify', src, 'Business assigned.', 'success')
    TriggerClientEvent('QBCore:Notify', target.PlayerData.source, 'You now own a gas station business.', 'success')
end)

RegisterNetEvent('qb-gastanks:server:upgradeTank', function(stationId, newType)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then
        return
    end

    stationId = tonumber(stationId)
    if not Config.Stations[stationId] then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid station.', 'error')
        return
    end

    ensureStationData(stationId)
    local station = getStation(stationId)
    if station.owner ~= player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, 'You are not the owner.', 'error')
        return
    end

    if not canUpgrade(station) then
        TriggerClientEvent('QBCore:Notify', src, 'Upgrade cooldown active.', 'error')
        return
    end

    local tank = Config.TankTypes[newType]
    if not tank then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid tank type.', 'error')
        return
    end

    if station.tankType == newType then
        TriggerClientEvent('QBCore:Notify', src, 'Tank already installed.', 'error')
        return
    end

    if not payPlayer(src, tank.price, 'bank') then
        TriggerClientEvent('QBCore:Notify', src, 'Not enough money.', 'error')
        return
    end

    station.tankType = newType
    station.lastUpgradeAt = os.time()
    local capacity = getTankCapacity(newType)
    if station.fuel > capacity then
        station.fuel = capacity
    end
    saveStations()

    TriggerClientEvent('QBCore:Notify', src, ('Tank upgraded to %s.'):format(tank.label), 'success')
end)

RegisterNetEvent('qb-gastanks:server:orderFuel', function(stationId, liters)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then
        return
    end

    stationId = tonumber(stationId)
    liters = tonumber(liters)
    if not Config.Stations[stationId] or not liters or liters <= 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid order.', 'error')
        return
    end

    ensureStationData(stationId)
    local station = getStation(stationId)
    if station.owner ~= player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, 'You are not the owner.', 'error')
        return
    end

    if station.pendingOrder then
        TriggerClientEvent('QBCore:Notify', src, 'Existing order pending.', 'error')
        return
    end

    local capacity = getTankCapacity(station.tankType)
    local availableSpace = capacity - station.fuel
    if liters > availableSpace then
        TriggerClientEvent('QBCore:Notify', src, 'Order exceeds capacity.', 'error')
        return
    end

    local total = liters * Config.FuelOrderPricePerLiter
    if not payPlayer(src, total, 'bank') then
        TriggerClientEvent('QBCore:Notify', src, 'Not enough money.', 'error')
        return
    end

    createOrder(station, liters)
    saveStations()

    TriggerClientEvent('QBCore:Notify', src, ('Fuel order placed: %s liters.'):format(liters), 'success')
end)

RegisterNetEvent('qb-gastanks:server:claimOrder', function(stationId)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then
        return
    end

    stationId = tonumber(stationId)
    if not Config.Stations[stationId] then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid station.', 'error')
        return
    end

    if not isAllowedDeliveryJob(player) then
        TriggerClientEvent('QBCore:Notify', src, 'Job not allowed.', 'error')
        return
    end

    ensureStationData(stationId)
    local station = getStation(stationId)
    if not station.pendingOrder then
        TriggerClientEvent('QBCore:Notify', src, 'No pending order.', 'error')
        return
    end

    if station.pendingOrder.claimedBy then
        TriggerClientEvent('QBCore:Notify', src, 'Order already claimed.', 'error')
        return
    end

    station.pendingOrder.claimedBy = player.PlayerData.citizenid
    saveStations()

    TriggerClientEvent('QBCore:Notify', src, 'Order claimed. Deliver fuel to station.', 'success')
end)

RegisterNetEvent('qb-gastanks:server:deliverFuel', function(stationId)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then
        return
    end

    stationId = tonumber(stationId)
    if not Config.Stations[stationId] then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid station.', 'error')
        return
    end

    ensureStationData(stationId)
    local station = getStation(stationId)
    if not station.pendingOrder then
        TriggerClientEvent('QBCore:Notify', src, 'No pending order.', 'error')
        return
    end

    if station.pendingOrder.claimedBy ~= player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, 'You did not claim this order.', 'error')
        return
    end

    local liters = station.pendingOrder.liters
    local capacity = getTankCapacity(station.tankType)
    if station.fuel + liters > capacity then
        TriggerClientEvent('QBCore:Notify', src, 'Tank is full.', 'error')
        return
    end

    station.fuel = station.fuel + liters
    station.pendingOrder = nil
    saveStations()

    local reward = math.floor(liters * Config.DeliveryJob.rewardPerLiter)
    givePlayer(src, reward, 'cash')

    TriggerClientEvent('QBCore:Notify', src, ('Delivery complete. Earned $%s.'):format(reward), 'success')
end)

QBCore.Functions.CreateCallback('qb-gastanks:server:getStationData', function(source, cb, stationId)
    stationId = tonumber(stationId)
    if not Config.Stations[stationId] then
        cb(nil)
        return
    end

    ensureStationData(stationId)
    cb(Stations[stationId])
end)

CreateThread(function()
    loadStations()
end)
