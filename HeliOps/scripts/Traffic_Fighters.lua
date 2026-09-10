----------------------------------------------------------------
-- HELIOPS FIGHTER TRAFFIC
----------------------------------------------------------------

env.info("=== FIGHTER TRAFFIC START ===")

local Groups =
    HeliOps.ME.Assets.Groups

local Zones =
    HeliOps.ME.Assets.Zones

local FighterTaskPool = {

    { Type = "ORBIT_CIRCLE", Duration_s = 120 },
    { Type = "ORBIT_CIRCLE", Duration_s = 300 },
    { Type = "ORBIT_CIRCLE", Duration_s = 600 },
}

local FighterProfiles = {

    F16C = {

        Limits = {
            MinTerrainClearance_ft = 300,
            MinSpeed_kt = 180,
            MaxSpeed_kt = 500,
        },

        CruiseAlt_ft = 3000,

        TacticalLanding = true,

        ModeOpt =
            HeliOps.LandingMode.OVERHEAD_BREAK,

        NavPool = {
            { WP = Zones.NavCyp01.Name, Speed_kt = 250, Alt_ft_msl = 3000 },
            { WP = Zones.NavCyp02.Name, Speed_kt = 280, Alt_ft_msl = 3000 },
            { WP = Zones.NavCyp03.Name, Speed_kt = 500, Alt_ft_msl = 3000 },
            { WP = Zones.NavCyp04.Name, Speed_kt = 500, Alt_ft_msl = 3000 },
            { WP = Zones.NavCyp05.Name, Speed_kt = 250, Alt_ft_msl = 3000 },
        },
    },

    F18C = {

        Limits = {
            MinTerrainClearance_ft = 100,
            MinSpeed_kt = 180,
            MaxSpeed_kt = 550,
        },

        CruiseAlt_ft = 3000,

        TacticalLanding = true,

        ModeOpt =
            HeliOps.LandingMode.OVERHEAD_BREAK,

        NavPool = {
            { WP = Zones.NavCyp01.Name, Speed_kt = 250, Alt_ft_msl = 3000 },
            { WP = Zones.NavCyp02.Name, Speed_kt = 280, Alt_ft_msl = 3000 },
            { WP = Zones.NavCyp03.Name, Speed_kt = 550, Alt_ft_msl = 3000 },
            { WP = Zones.NavCyp04.Name, Speed_kt = 250, Alt_ft_msl = 3000 },
            { WP = Zones.NavCyp05.Name, Speed_kt = 200, Alt_ft_msl = 3000 },
        },
    },

    F14B = {

        Limits = {
            MinTerrainClearance_ft = 300,
            MinSpeed_kt = 180,
            MaxSpeed_kt = 550,
        },

        CruiseAlt_ft = 3000,

        TacticalLanding = true,

        ModeOpt =
            HeliOps.LandingMode.OVERHEAD_BREAK,

        NavPool = {
            { WP = Zones.NavCyp01.Name, Speed_kt = 250, Alt_ft_msl = 3000 },
            { WP = Zones.NavCyp02.Name, Speed_kt = 280, Alt_ft_msl = 3000 },
            { WP = Zones.NavCyp03.Name, Speed_kt = 500, Alt_ft_msl = 3000 },
            { WP = Zones.NavCyp04.Name, Speed_kt = 500, Alt_ft_msl = 3000 },
            { WP = Zones.NavCyp05.Name, Speed_kt = 250, Alt_ft_msl = 3000 },
        },
    },
}

local function StartFighter(
    GroupName,
    Profile,
    RTBBase,
    Route,
    Tasks
)

    local Config = {

        Group = GroupName,
        Limits = Profile.Limits,

        TacticalLanding =
            Profile.TacticalLanding,

        ModeOpt =
            Profile.ModeOpt,

        CruiseAlt_ft =
            Profile.CruiseAlt_ft,

        NavPool =
            Profile.NavPool,

        TaskPool =
            FighterTaskPool,

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

local Viper21 =
    StartFighter(
        Groups.Viper21.Name,
        FighterProfiles.F16C,
        AIRBASE.Syria.Akrotiri,
        { 3, 5 },
        { 0, 0 }
    )

local Viper22 =
    StartFighter(
        Groups.Viper22.Name,
        FighterProfiles.F16C,
        AIRBASE.Syria.Akrotiri,
        { 3, 5 },
        { 0, 0 }
    )

local Hornet21 =
    StartFighter(
        Groups.Hornet21.Name,
        FighterProfiles.F18C,
        AIRBASE.Syria.Akrotiri,
        { 3, 5 },
        { 0, 0 }
    )

local Hornet22 =
    StartFighter(
        Groups.Hornet22.Name,
        FighterProfiles.F18C,
        AIRBASE.Syria.Akrotiri,
        { 3, 5 },
        { 0, 0 }
    )

local Tomcat21 =
    StartFighter(
        Groups.Tomcat21.Name,
        FighterProfiles.F14B,
        AIRBASE.Syria.Akrotiri,
        { 3 },
        { 0 }
    )

local Tomcat22 =
    StartFighter(
        Groups.Tomcat22.Name,
        FighterProfiles.F14B,
        AIRBASE.Syria.Akrotiri,
        { 3 },
        { 0 }
    )

env.info("=== FIGHTER TRAFFIC READY ===")
