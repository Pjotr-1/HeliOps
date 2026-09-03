----------------------------------------------------------------
-- HELIOPS FLIGHT CONTROL
----------------------------------------------------------------

env.info(
    "=== HELIOPS FLIGHTCONTROL START ==="
)

HeliOps = HeliOps or {}
HeliOps.FlightControl =
    HeliOps.FlightControl or {}


----------------------------------------------------------------
-- CREATE FLIGHTCONTROL
----------------------------------------------------------------

function HeliOps.FlightControl:Create(
    AirbaseName,
    Config
)

    if not Config.Enabled then

        env.info(
            "HELIOPS FC: Disabled for "
            .. AirbaseName
        )

        return nil
    end


    env.info(
        "HELIOPS FC: Creating FLIGHTCONTROL for "
        .. AirbaseName
    )


    local fc =
        FLIGHTCONTROL:New(
            AirbaseName,
            Config.Frequency,
            Config.Modulation
        )


    if not fc then

        env.error(
            "HELIOPS FC: Could not create FLIGHTCONTROL"
        )

        return nil
    end


    ------------------------------------------------------------
    -- CONFIGURE
    ------------------------------------------------------------

    fc:SetVerbosity(
        HeliOps.Config.Verbosity or 0
    )


    fc:SetLimitTaxi(
        Config.TaxiLimit or 2,
        false,
        0
    )


    fc:SetMarkHoldingPattern(
        Config.ShowHoldingPatterns
    )


    fc:SetRadioOnlyIfPlayers(
        Config.RadioOnlyIfPlayers
    )


    ------------------------------------------------------------
    -- START
    ------------------------------------------------------------

    fc:Start()


    env.info(
        "HELIOPS FC: FLIGHTCONTROL started for "
        .. AirbaseName
    )


    return fc

end


----------------------------------------------------------------
-- AKROTIRI
----------------------------------------------------------------

HeliOps.FlightControl.Akrotiri =
    HeliOps.FlightControl:Create(
        HeliOps.Config.Cyprus.HomeBase,
        HeliOps.Config.Cyprus.FlightControl
    )


env.info(
    "=== HELIOPS FLIGHTCONTROL READY ==="
)