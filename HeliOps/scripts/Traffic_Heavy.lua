----------------------------------------------------------------
-- HELIOPS HEAVY / SUPPORT TRAFFIC
----------------------------------------------------------------

env.info("=== HEAVY TRAFFIC START ===")

local Groups =
    HeliOps.ME.Assets.Groups

local Zones =
    HeliOps.ME.Assets.Zones

local HeavyTaskPool = {

    { Type = "ORBIT_CIRCLE", Duration_s = 120 },
    { Type = "ORBIT_CIRCLE", Duration_s = 300 },
    { Type = "ORBIT_CIRCLE", Duration_s = 600 },
}

local HeavyProfiles = {

    KC135 = {

        Limits = {
            MinTerrainClearance_ft = 500,
            MinSpeed_kt = 180,
            MaxSpeed_kt = 450,
        },

        CruiseAlt_ft = 12000,

        NavPool = {
            { WP = Zones.NavCyp01.Name, Speed_kt = 280, Alt_ft_msl = 10000 },
            { WP = Zones.NavCyp02.Name, Speed_kt = 300, Alt_ft_msl = 12000 },
            { WP = Zones.NavCyp03.Name, Speed_kt = 320, Alt_ft_msl = 12000 },
            { WP = Zones.NavCyp04.Name, Speed_kt = 320, Alt_ft_msl = 12000 },
            { WP = Zones.NavCyp05.Name, Speed_kt = 280, Alt_ft_msl = 10000 },
        },
    },

    E3A = {

        Limits = {
            MinTerrainClearance_ft = 1000,
            MinSpeed_kt = 180,
            MaxSpeed_kt = 430,
        },

        CruiseAlt_ft = 25000,

        NavPool = {
            { WP = Zones.NavCyp01.Name, Speed_kt = 300, Alt_ft_msl = 20000 },
            { WP = Zones.NavCyp02.Name, Speed_kt = 320, Alt_ft_msl = 25000 },
            { WP = Zones.NavCyp03.Name, Speed_kt = 330, Alt_ft_msl = 25000 },
            { WP = Zones.NavCyp04.Name, Speed_kt = 330, Alt_ft_msl = 25000 },
            { WP = Zones.NavCyp05.Name, Speed_kt = 300, Alt_ft_msl = 20000 },
        },
    },

    C130J = {

        Limits = {
            MinTerrainClearance_ft = 300,
            MinSpeed_kt = 120,
            MaxSpeed_kt = 320,
        },

        CruiseAlt_ft = 10000,

        NavPool = {
            { WP = Zones.NavCyp01.Name, Speed_kt = 220, Alt_ft_msl = 8000 },
            { WP = Zones.NavCyp02.Name, Speed_kt = 240, Alt_ft_msl = 10000 },
            { WP = Zones.NavCyp03.Name, Speed_kt = 250, Alt_ft_msl = 10000 },
            { WP = Zones.NavCyp04.Name, Speed_kt = 250, Alt_ft_msl = 10000 },
            { WP = Zones.NavCyp05.Name, Speed_kt = 220, Alt_ft_msl = 8000 },
        },
    },
}

local function StartHeavy(
    GroupName,
    Profile,
    RTBBase,
    Route,
    Tasks
)

    local Config = {

        Group = GroupName,
        Limits = Profile.Limits,

        CruiseAlt_ft =
            Profile.CruiseAlt_ft,

        NavPool =
            Profile.NavPool,

        TaskPool =
            HeavyTaskPool,

        Route =
            Route,

        Tasks =
            Tasks,

        RandomizeRoute = false,

        AbortConditions = {
            OnDamage = false,
        },

        RTB = RTBBase,
    }

    return HeliOps.Traffic:Start(Config)
end

local Texaco21 =
    StartHeavy(
        Groups.Texaco21.Name,
        HeavyProfiles.KC135,
        AIRBASE.Syria.Akrotiri,
        { 3 },
        { 0 }
    )

local Texaco22 =
    StartHeavy(
        Groups.Texaco22.Name,
        HeavyProfiles.KC135,
        AIRBASE.Syria.Akrotiri,
        { 3 },
        { 0 }
    )

local Magic21 =
    StartHeavy(
        Groups.Magic21.Name,
        HeavyProfiles.E3A,
        AIRBASE.Syria.Akrotiri,
        { 2, 4 },
        { 0, 0 }
    )

local Herc21 =
    StartHeavy(
        Groups.Herc21.Name,
        HeavyProfiles.C130J,
        AIRBASE.Syria.Akrotiri,
        { 3, 5 },
        { 0, 0 }
    )

env.info("=== HEAVY TRAFFIC READY ===")
