----------------------------------------------------------------
-- HELIOPS FLIGHT CONTROL
--
-- Generic MOOSE FLIGHTCONTROL wrapper.
--
-- Airport-specific data is stored in:
--   HeliOps_Airports.lua
--
-- Custom holding behavior:
--   1. FLIGHTCONTROL:New() creates MOOSE's backup holding.
--   2. HeliOps reads heading / flight levels from that backup
--      when not explicitly configured.
--   3. HeliOps creates a NEW holding pattern whose pos0 is the
--      center of the configured Mission Editor trigger zone.
--   4. Only after successful creation is the original MOOSE
--      backup holding removed.
----------------------------------------------------------------

env.info("=== HELIOPS FLIGHTCONTROL START ===")

MSRS.SetDefaultBackendGRPC()

env.info("HELIOPS: MSRS backend = gRPC")

HeliOps = HeliOps or {}

HeliOps.FlightControl =
    HeliOps.FlightControl or {}

HeliOps.FlightControl.Controllers =
    HeliOps.FlightControl.Controllers or {}

----------------------------------------------------------------
-- VALIDATE AIRPORT CONFIG
----------------------------------------------------------------

function HeliOps.FlightControl:ValidateAirport(
    AirportKey,
    Airport
)

    if not Airport then

        env.error(
            "HELIOPS FC: Airport config missing for "
            .. tostring(AirportKey)
        )

        return false
    end

    if not Airport.Airbase then

        env.error(
            "HELIOPS FC: Airbase missing for "
            .. tostring(AirportKey)
        )

        return false
    end

    if not Airport.FlightControl then

        env.error(
            "HELIOPS FC: FlightControl config missing for "
            .. tostring(AirportKey)
        )

        return false
    end

    return true
end

----------------------------------------------------------------
-- CONFIGURE CUSTOM HOLDING
----------------------------------------------------------------

function HeliOps.FlightControl:ConfigureHolding(
    FC,
    AirportKey,
    HoldConfig
)

    if not HoldConfig
    or not HoldConfig.Zone then

        env.info(
            "HELIOPS FC: "
            .. tostring(AirportKey)
            .. " no custom holding configured; MOOSE backup retained"
        )

        return true
    end

    ------------------------------------------------------------
    -- FIND ME TRIGGER ZONE
    ------------------------------------------------------------

    local holdZone =
        ZONE:FindByName(
            HoldConfig.Zone
        )

    if not holdZone then

        env.error(
            "HELIOPS FC: Holding trigger zone not found: "
            .. tostring(HoldConfig.Zone)
            .. " | MOOSE backup retained"
        )

        trigger.action.outText(
            "ERROR: Holding zone not found: "
            .. tostring(HoldConfig.Zone),
            20
        )

        return false
    end

    ------------------------------------------------------------
    -- READ MOOSE BACKUP HOLDING
    ------------------------------------------------------------

    local backup = nil

    if FC.holdingpatterns
    and #FC.holdingpatterns > 0 then

        backup =
            FC.holdingpatterns[1]
    end

    ------------------------------------------------------------
    -- RESOLVE HEADING
    ------------------------------------------------------------

    local heading =
        HoldConfig.Heading_deg

    if heading == nil
    and backup
    and backup.stacks
    and backup.stacks[1] then

        heading =
            backup.stacks[1].heading
    end

    if heading == nil then

        env.error(
            "HELIOPS FC: Could not determine holding heading for "
            .. tostring(AirportKey)
            .. " | MOOSE backup retained"
        )

        return false
    end

    ------------------------------------------------------------
    -- RESOLVE FLIGHT LEVELS
    ------------------------------------------------------------

    local flightLevelMin =
        HoldConfig.FL_Min

    local flightLevelMax =
        HoldConfig.FL_Max

    if flightLevelMin == nil
    and backup then

        flightLevelMin =
            backup.angelsmin
    end

    if flightLevelMax == nil
    and backup then

        flightLevelMax =
            backup.angelsmax
    end

    flightLevelMin =
        flightLevelMin
        or 5

    flightLevelMax =
        flightLevelMax
        or 15

    ------------------------------------------------------------
    -- LENGTH / PRIORITY
    ------------------------------------------------------------

    local lengthNM =
        HoldConfig.Length_NM
        or 15

    local priority =
        HoldConfig.Priority
        or 10

    ------------------------------------------------------------
    -- CREATE CUSTOM HOLDING
    ------------------------------------------------------------

    local customHolding =
        FC:AddHoldingPattern(
            holdZone,
            heading,
            lengthNM,
            flightLevelMin,
            flightLevelMax,
            priority
        )

    if not customHolding then

        env.error(
            "HELIOPS FC: Could not create custom holding for "
            .. tostring(AirportKey)
            .. " | MOOSE backup retained"
        )

        return false
    end

    ------------------------------------------------------------
    -- REMOVE ORIGINAL MOOSE BACKUP
    ------------------------------------------------------------

    if backup then

        FC:RemoveHoldingPattern(
            backup
        )
    end

    env.info(
        string.format(
            "HELIOPS FC: %s custom holding ACTIVE | zone=%s | center=ME trigger center | heading=%.0f deg | length=%.1f NM | FL%d-FL%d | prio=%d",
            tostring(AirportKey),
            tostring(HoldConfig.Zone),
            heading,
            lengthNM,
            flightLevelMin,
            flightLevelMax,
            priority
        )
    )

    return true
end

----------------------------------------------------------------
-- CREATE ONE FLIGHTCONTROL
----------------------------------------------------------------

function HeliOps.FlightControl:Create(
    AirportKey,
    Airport
)

    if not self:ValidateAirport(
        AirportKey,
        Airport
    ) then

        return nil
    end

    if Airport.Enabled == false then

        env.info(
            "HELIOPS FC: Airport disabled: "
            .. tostring(AirportKey)
        )

        return nil
    end

    local Config =
        Airport.FlightControl

    if Config.Enabled == false then

        env.info(
            "HELIOPS FC: FLIGHTCONTROL disabled for "
            .. tostring(AirportKey)
        )

        return nil
    end

    env.info(
        "HELIOPS FC: Creating FLIGHTCONTROL for "
        .. tostring(AirportKey)
        .. " / "
        .. tostring(Airport.Airbase)
    )

    local fc =
        FLIGHTCONTROL:New(
            Airport.Airbase,
            Config.Frequency,
            Config.Modulation,
            Config.SRSPath,
            Config.SRSPort or 5002
        )

    if not fc then

        env.error(
            "HELIOPS FC: Could not create FLIGHTCONTROL for "
            .. tostring(AirportKey)
        )

        return nil
    end

    ------------------------------------------------------------
    -- FORCE gRPC BACKEND ON CREATED MSRS INSTANCES
    ------------------------------------------------------------

    if fc.msrsTower then
        fc.msrsTower:SetBackend(
            MSRS.Backend.GRPC
        )
    end

    if fc.msrsPilot then
        fc.msrsPilot:SetBackend(
            MSRS.Backend.GRPC
        )
    end

    ------------------------------------------------------------
    -- SRS / TTS VOICES
    ------------------------------------------------------------

    fc:SetSRSTower(
        "female",
        "en-GB",
        nil,
        1.0,
        tostring(AirportKey) .. " Tower"
    )

    fc:SetSRSPilot(
        "male",
        "en-US",
        nil,
        1.0,
        "Pilot"
    )

    ------------------------------------------------------------
    -- SRS DEBUG
    ------------------------------------------------------------

    env.info(
        string.format(
            "HELIOPS SRS DEBUG: %s | path=%s | port=%s | freq=%s | mod=%s | tower=%s | pilot=%s | towerBackend=%s | pilotBackend=%s",
            tostring(AirportKey),
            tostring(Config.SRSPath),
            tostring(Config.SRSPort or 5002),
            tostring(Config.Frequency),
            tostring(Config.Modulation),
            tostring(fc.msrsTower ~= nil),
            tostring(fc.msrsPilot ~= nil),
            tostring(
                fc.msrsTower
                and fc.msrsTower:GetBackend()
                or "nil"
            ),
            tostring(
                fc.msrsPilot
                and fc.msrsPilot:GetBackend()
                or "nil"
            )
        )
    )

    ------------------------------------------------------------
    -- VERBOSITY
    ------------------------------------------------------------

    local verbosity = 0

    if HeliOps.Config
    and HeliOps.Config.Verbosity then

        verbosity =
            HeliOps.Config.Verbosity
    end

    fc:SetVerbosity(
        verbosity
    )

    ------------------------------------------------------------
    -- TAXI
    ------------------------------------------------------------

    fc:SetLimitTaxi(
        Config.TaxiLimit or 2,
        false,
        0
    )

    ------------------------------------------------------------
    -- LANDING LIMIT
    ------------------------------------------------------------

    fc:SetLimitLanding(
        Config.LandingLimit or 2,
        Config.LandingTakeoffLimit or 0
    )

    ------------------------------------------------------------
    -- LANDING INTERVAL
    ------------------------------------------------------------

    fc:SetLandingInterval(
        Config.LandingInterval_s or 180
    )

    ------------------------------------------------------------
    -- RADIO
    ------------------------------------------------------------

    fc:SetRadioOnlyIfPlayers(
        false
    )

    fc:SetTransmitOnlyWithPlayers(
        false
    )

    ------------------------------------------------------------
    -- CUSTOM HOLDING
    ------------------------------------------------------------

    self:ConfigureHolding(
        fc,
        AirportKey,
        Airport.Hold
    )

    ------------------------------------------------------------
    -- F10 HOLDING GRAPHICS
    ------------------------------------------------------------

    fc:SetMarkHoldingPattern(
        Config.ShowHoldingPatterns
    )

    ------------------------------------------------------------
    -- START
    ------------------------------------------------------------

    fc:Start()

    env.info(
        "HELIOPS FC: FLIGHTCONTROL started for "
        .. tostring(AirportKey)
    )

    return fc
end

----------------------------------------------------------------
-- CREATE ALL ENABLED AIRPORT CONTROLLERS
----------------------------------------------------------------

function HeliOps.FlightControl:CreateAll()

    if not HeliOps.Airports then

        env.error(
            "HELIOPS FC: HeliOps.Airports missing. "
            .. "Load HeliOps_Airports.lua before HeliOps_FlightControl.lua"
        )

        return
    end

    for airportKey, airport in pairs(
        HeliOps.Airports
    ) do

        if type(airport) == "table"
        and airport.Airbase then

            local fc =
                self:Create(
                    airportKey,
                    airport
                )

            if fc then

                self.Controllers[
                    airportKey
                ] = fc

                if airportKey == "AKROTIRI" then

                    self.Akrotiri =
                        fc
                end
            end
        end
    end
end

----------------------------------------------------------------
-- GET CONTROLLER
----------------------------------------------------------------

function HeliOps.FlightControl:Get(
    AirportKey
)

    return self.Controllers[
        AirportKey
    ]
end

----------------------------------------------------------------
-- START ALL
----------------------------------------------------------------

HeliOps.FlightControl:CreateAll()

----------------------------------------------------------------
-- READY
----------------------------------------------------------------

env.info("=== HELIOPS FLIGHTCONTROL READY ===")
