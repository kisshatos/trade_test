Config = {}

Config.AdminGroups = {
    'god',
    'admin'
}

Config.UpgradeCooldownHours = 24

Config.TankTypes = {
    small = {
        label = 'Small Tank',
        capacity = 15000,
        price = 50000
    },
    medium = {
        label = 'Medium Tank',
        capacity = 30000,
        price = 100000
    },
    large = {
        label = 'Large Tank',
        capacity = 60000,
        price = 200000
    }
}

Config.DefaultTankType = 'small'

Config.FuelOrderPricePerLiter = 3

Config.Stations = {
    [1] = {
        name = 'Strawberry Gas',
        coords = vector3(264.74, -1259.47, 29.14)
    },
    [2] = {
        name = 'Sandy Gas',
        coords = vector3(2004.11, 3774.31, 32.18)
    },
    [3] = {
        name = 'Paleto Gas',
        coords = vector3(174.81, 6603.63, 31.86)
    }
}

Config.DeliveryJob = {
    label = 'Fuel Delivery',
    rewardPerLiter = 1.5,
    allowedJobs = {
        'unemployed',
        'delivery'
    }
}
