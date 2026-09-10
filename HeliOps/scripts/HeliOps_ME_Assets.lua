----------------------------------------------------------------
-- HELIOPS ME ASSETS
--
-- Single source of truth for Mission Editor assets.
--
-- This file should mirror what is actually implemented in ME.
--
-- Groups:
--   Name = exact DCS group name in Mission Editor
--   Type = DCS aircraft/helicopter type selected in ME
--
-- Zones:
--   Name = exact trigger-zone name in Mission Editor
--   Type = expected Mission Editor zone type
--
-- Keep behaviour, routes, speeds, tasks and profiles OUT of
-- this file. Those belong in Traffic_*.lua / framework files.
----------------------------------------------------------------

env.info("=== HELIOPS ME ASSETS START ===")

HeliOps = HeliOps or {}
HeliOps.ME = HeliOps.ME or {}
HeliOps.ME.Assets = HeliOps.ME.Assets or {}

----------------------------------------------------------------
-- GROUPS
----------------------------------------------------------------

HeliOps.ME.Assets.Groups = {

    ------------------------------------------------------------
    -- FIGHTERS
    ------------------------------------------------------------

    Viper21 = {
        Name = "Viper21",
        Type = "F-16C bl.50",
    },

    Viper22 = {
        Name = "Viper22",
        Type = "F-16C bl.50",
    },

    Hornet21 = {
        Name = "Hornet21",
        Type = "F/A-18C",
    },

    Hornet22 = {
        Name = "Hornet22",
        Type = "F/A-18C",
    },

    Tomcat21 = {
        Name = "Tomcat21",
        Type = "F-14B(U)",
    },

    Tomcat22 = {
        Name = "Tomcat22",
        Type = "F-14B(U)",
    },

    ------------------------------------------------------------
    -- HELICOPTERS
    ------------------------------------------------------------

    Hip21 = {
        Name = "Hip21",
        Type = "Mi-8MTV2",
    },

    Hip22 = {
        Name = "Hip22",
        Type = "Mi-8MTV2",
    },

    Apache21 = {
        Name = "Apache21",
        Type = "AH-64D BLK.II",
    },

    Chinook21 = {
        Name = "Chinook21",
        Type = "CH-47F",
    },

    ------------------------------------------------------------
    -- HEAVY / SUPPORT
    ------------------------------------------------------------

    Texaco21 = {
        Name = "Texaco21",
        Type = "KC-135",
    },

    Texaco22 = {
        Name = "Texaco22",
        Type = "KC-135",
    },

    Magic21 = {
        Name = "Magic21",
        Type = "E-3A",
    },

    Herc21 = {
        Name = "Herc21",
        Type = "C-130J-30",
    },
}

----------------------------------------------------------------
-- ZONES
----------------------------------------------------------------

HeliOps.ME.Assets.Zones = {

    ------------------------------------------------------------
    -- HOLDING ZONES
    ------------------------------------------------------------

    HoldAkrotiri = {
        Name = "HOLD_AKROTIRI",
        Type = "TRIGGER_CIRCLE",
    },

    HoldPaphos = {
        Name = "HOLD_PAPHOS",
        Type = "TRIGGER_CIRCLE",
    },

    HoldLarnaca = {
        Name = "HOLD_LARNACA",
        Type = "TRIGGER_CIRCLE",
    },

    ------------------------------------------------------------
    -- CYPRUS NAVIGATION ZONES
    ------------------------------------------------------------

    NavCyp01 = {
        Name = "NAV_CYP_01",
        Type = "TRIGGER_CIRCLE",
    },

    NavCyp02 = {
        Name = "NAV_CYP_02",
        Type = "TRIGGER_CIRCLE",
    },

    NavCyp03 = {
        Name = "NAV_CYP_03",
        Type = "TRIGGER_CIRCLE",
    },

    NavCyp04 = {
        Name = "NAV_CYP_04",
        Type = "TRIGGER_CIRCLE",
    },

    NavCyp05 = {
        Name = "NAV_CYP_05",
        Type = "TRIGGER_CIRCLE",
    },

    NavCyp06 = {
        Name = "NAV_CYP_06",
        Type = "TRIGGER_CIRCLE",
    },

    NavCyp07 = {
        Name = "NAV_CYP_07",
        Type = "TRIGGER_CIRCLE",
    },

    NavCyp08 = {
        Name = "NAV_CYP_08",
        Type = "TRIGGER_CIRCLE",
    },

    NavCyp09 = {
        Name = "NAV_CYP_09",
        Type = "TRIGGER_CIRCLE",
    },

    NavCyp10 = {
        Name = "NAV_CYP_10",
        Type = "TRIGGER_CIRCLE",
    },
}

----------------------------------------------------------------
-- READY
----------------------------------------------------------------

env.info("=== HELIOPS ME ASSETS READY ===")
