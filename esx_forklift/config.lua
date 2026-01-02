Config = {}

-- Activation des fonctionnalités
Config.UseOxLib = true
Config.UseOxTarget = true
Config.UseOxFuel = true

-- Position du job
Config.JobLocation = {
    ped = {
        model = 's_m_y_airworker',
        coords = vector4(153.81, -3214.6, 5.86, 87.71),
        scenario = 'WORLD_HUMAN_CLIPBOARD'
    },

    garage = {
        ped = {
            model = 's_m_y_dockwork_01',
            coords = vector4(120.89, -3184.05, 5.92, 271.27),
            scenario = 'WORLD_HUMAN_AA_COFFEE'
        },
        forklift = {
            model = 'forklift',
            coords = vector4(128.15, -3183.94, 5.87, 269.27)
        }
    },

    truck = {
        model = 'benson',
        driver = 's_m_m_security_01',
        spawnCoords = vector4(159.18, -3196.7, 6.01, 90.43),
        leaveCoords = vector3(305.12, -2831.82, 6.0)
    }
}

-- Positions des palettes
Config.Pallets = {
    positions = {
        vector4(160.38, -3141.0, 5.99, 270.0),
        vector4(160.65, -3153.77, 5.98, 270.0),
        vector4(160.43, -3165.1, 5.99, 270.0),
        vector4(162.71, -3211.25, 5.95, 270.0),
        vector4(142.92, -3210.27, 5.86, 270.0),
    },
    models = {
        'prop_boxpile_02b',
        'prop_boxpile_02c',
        'prop_boxpile_03a'
    }
}

-- Paramètres du job
Config.JobSettings = {
    minPallets = 2,
    maxPallets = 4,
    rewardPerPallet = 150,
    missionTimeout = 900000, -- 15 minutes
    distanceCheck = 100.0,
    loadingDistance = 20.0,
    truckDoor = 5
}

-- Blips
Config.Blips = {
    job = {
        sprite = 525,
        color = 28,
        scale = 0.8,
        label = 'Forklift Job'
    },
    truck = {
        sprite = 477,
        color = 2,
        scale = 0.8,
        label = 'Delivery Truck'
    }
}

-- Textes
Config.Text = {
    startJob = 'Take Job',
    cancelJob = 'Cancel Job',
    takeForklift = 'Take Forklift',
    returnForklift = 'Return Forklift',
    loadPalette = 'Load Palette',
    missionStarted = 'Mission started! Load %s pallets into the truck.',
    missionCanceled = 'Mission canceled!',
    missionComplete = 'Mission complete! You received $%s',
    noForklift = 'You need a forklift!',
    inForklift = 'You must be in the forklift!',
    truckDoorClosed = 'Truck door is not open!',
    paletteLoaded = 'Palette loaded! (%s/%s)',
    forkliftTaken = 'Forklift taken! Load the pallets.',
    forkliftReturned = 'Forklift returned!',
    goToGarage = 'Go to the garage to take a forklift'
}

-- Options ox_target
Config.Target = {
    distance = 2.0,
    icons = {
        signup = 'fas fa-clipboard-check',
        garage = 'fas fa-forklift',
        palette = 'fas fa-box'
    }
}