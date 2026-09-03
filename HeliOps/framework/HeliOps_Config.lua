----------------------------------------------------------------
-- HELIOPS CONFIG
-- Cyprus
----------------------------------------------------------------

env.info("=== HELIOPS CONFIG START ===")

HeliOps = HeliOps or {}

HeliOps.Config = {

    ------------------------------------------------------------
    -- GENERAL
    ------------------------------------------------------------

    Debug = true,

    Verbosity = 3,


    ------------------------------------------------------------
    -- CYPRUS
    ------------------------------------------------------------

    Cyprus = {

        HomeBase = AIRBASE.Syria.Akrotiri,

        --------------------------------------------------------
        -- NAV defaults
        --------------------------------------------------------

        NavPrefix = "NAV_CYP_",

        --------------------------------------------------------
        -- FLIGHTCONTROL
        --------------------------------------------------------

        FlightControl = {

            Enabled = true,

            Frequency = 251.700,

            Modulation =
                radio.modulation.AM,

            TaxiLimit = 1,

            ShowHoldingPatterns = false,

            RadioOnlyIfPlayers = true,
        },

    },

}

env.info("=== HELIOPS CONFIG READY ===")
