----------------------------------------------------------------
-- HELIOPS HELICOPTER TRAFFIC
----------------------------------------------------------------

env.info("=== HELICOPTER TRAFFIC START ===")

local Groups =
    HeliOps.ME.Assets.Groups

local Zones =
    HeliOps.ME.Assets.Zones

local HelicopterTaskPool = {

    { Type = "ORBIT_CIRCLE", Duration_s = 120 },
    { Type = "ORBIT_CIRCLE", Duration_s = 300 },
    { Type = "ORBIT_CIRCLE", Duration_s = 600 },
}

local HelicopterProfiles = {

    MI8 = {

        Limits = {
            MinTerrainClearance_ft = 100,
            MinSpeed_kt = 30,
            MaxSpeed_kt = 140,
        },

        CruiseAlt_ft = 1000,

        NavPool = {
            { WP = Zones.NavCyp01.Name, Speed_kt = 100, Alt_ft_msl = 1500 },
            { WP = Zones.NavCyp02.Name, Speed_kt = 110, Alt_ft_msl = 1000 },
            { WP = Zones.NavCyp03.Name, Speed_kt = 90,  Alt_ft_msl = 1000 },
            { WP = Zones.NavCyp04.Name, Speed_kt = 105, Alt_ft_msl = 1000 },
            { WP = Zones.NavCyp05.Name, Speed_kt = 110, Alt_ft_msl = 1000 },
        },
    },

    AH64D = {

        Limits = {
            MinTerrainClearance_ft = 100,
            MinSpeed_kt = 30,
            MaxSpeed_kt = 160,
        },

        CruiseAlt_ft = 1000,

        NavPool = {
            { WP = Zones.NavCyp01.Name, Speed_kt = 110, Alt_ft_msl = 1200 },
            { WP = Zones.NavCyp02.Name, Speed_kt = 120, Alt_ft_msl = 1000 },
            { WP = Zones.NavCyp03.Name, Speed_kt = 110, Alt_ft_msl = 1000 },
            { WP = Zones.NavCyp04.Name, Speed_kt = 120, Alt_ft_msl = 1000 },
            { WP = Zones.NavCyp05.Name, Speed_kt = 110, Alt_ft_msl = 1000 },
        },
    },

    CH47F = {

        Limits = {
            MinTerrainClearance_ft = 100,
            MinSpeed_kt = 30,
            MaxSpeed_kt = 170,
        },

        CruiseAlt_ft = 1200,

        NavPool = {
            { WP = Zones.NavCyp01.Name, Speed_kt = 120, Alt_ft_msl = 1500 },
            { WP = Zones.NavCyp02.Name, Speed_kt = 130, Alt_ft_msl = 1200 },
            { WP = Zones.NavCyp03.Name, Speed_kt = 120, Alt_ft_msl = 1200 },
            { WP = Zones.NavCyp04.Name, Speed_kt = 130, Alt_ft_msl = 1200 },
            { WP = Zones.NavCyp05.Name, Speed_kt = 120, Alt_ft_msl = 1200 },
        },
    },
}

local function StartHelicopter(
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
            HelicopterTaskPool,

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

local Hip21 =
    StartHelicopter(
        Groups.Hip21.Name,
        HelicopterProfiles.MI8,
        AIRBASE.Syria.Akrotiri,
        { 5 },
        { 0 }
    )

local Hip22 =
    StartHelicopter(
        Groups.Hip22.Name,
        HelicopterProfiles.MI8,
        AIRBASE.Syria.Akrotiri,
        { 5 },
        { 0 }
    )

local Apache21 =
    StartHelicopter(
        Groups.Apache21.Name,
        HelicopterProfiles.AH64D,
        AIRBASE.Syria.Akrotiri,
        { 4, 5 },
        { 0, 0 }
    )

local Chinook21 =
    StartHelicopter(
        Groups.Chinook21.Name,
        HelicopterProfiles.CH47F,
        AIRBASE.Syria.Akrotiri,
        { 4, 5 },
        { 0, 0 }
    )

env.info("=== HELICOPTER TRAFFIC READY ===")
