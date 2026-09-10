----------------------------------------------------------------
-- HELIOPS RADIO ROUTER
--
-- Mission-state bridge between DCS-gRPC user flags and
-- native MOOSE FLIGHTCONTROL player callbacks.
--
-- Design:
--   * No parallel/custom ATC state machine.
--   * Player FLIGHTGROUP is created only on the first ACTIVE
--     HeliOps radio command (for example RADIO_CHECK or TAXI).
--   * Registration uses HeliOps:RegisterFlight().
--   * Native ATC commands call the exact MOOSE FLIGHTCONTROL
--     callbacks used by the native F10 menu.
--   * RADIO_CHECK is the only small HeliOps-specific radio action;
--     its tower reply is transmitted through MOOSE TransmissionTower().
----------------------------------------------------------------

env.info("=== HELIOPS RADIO ROUTER START ===")

HeliOps = HeliOps or {}
HeliOps.RadioRouter = HeliOps.RadioRouter or {}

local R = HeliOps.RadioRouter

R.FrequencyToleranceHz = 500
R.PollInterval = 0.10

-- When a player FLIGHTGROUP is created by the first radio command,
-- give MOOSE time to initialize/synchronize the group before the
-- requested action is invoked.
R.RegistrationSyncDelay = 1.0

----------------------------------------------------------------
-- COMMANDS
----------------------------------------------------------------

R.NativeCommands = {
    TAXI            = "_PlayerRequestTaxi",
    TAKEOFF         = "_PlayerRequestTakeoff",
    INBOUND         = "_PlayerRequestInbound",
    DIRECT          = "_PlayerRequestDirectLanding",
    HOLDING         = "_PlayerHolding",
    CONFIRM_LANDING = "_PlayerConfirmLanding",
}

R.CommandNames = {
    "RADIO_CHECK",
    "TAXI",
    "TAKEOFF",
    "INBOUND",
    "DIRECT",
    "HOLDING",
    "CONFIRM_LANDING",
}

R.RadioFrequencyFlag  = "HELIOPS_RADIO_FREQ_HZ"
R.RadioModulationFlag = "HELIOPS_RADIO_MOD"

----------------------------------------------------------------
-- USER FLAG HELPERS
----------------------------------------------------------------

local function getFlag(Name)
    return USERFLAG:New(Name):Get() or 0
end

local function setFlag(Name, Value)
    USERFLAG:New(Name):Set(Value)
end

----------------------------------------------------------------
-- GET ACTIVE HUMAN PLAYER GROUP
----------------------------------------------------------------

function R:GetPlayerGroupName()

    if not _DATABASE
    or not _DATABASE.GetPlayerUnits then

        env.error(
            "HELIOPS RADIO: _DATABASE:GetPlayerUnits unavailable"
        )

        return nil
    end

    local players =
        _DATABASE:GetPlayerUnits()

    if not players then
        return nil
    end

    for _, unit in pairs(players) do

        if unit
        and unit.IsAlive
        and unit:IsAlive() then

            local group =
                unit:GetGroup()

            if group then
                return group:GetName()
            end
        end
    end

    return nil
end

----------------------------------------------------------------
-- REGISTER / RESOLVE HUMAN PLAYER AS NATIVE MOOSE FLIGHTGROUP
--
-- IMPORTANT:
-- No background registration is performed.
--
-- The first actual HeliOps radio command performs registration.
-- This allows a normal sequence such as:
--
--   "Akrotiri, radio check"
--   "Akrotiri, request taxi"
--   "Akrotiri, request takeoff"
--   ...
--   "Akrotiri inbound"
--
-- Registration deliberately uses the framework's existing
-- HeliOps:RegisterFlight() helper instead of constructing a
-- parallel player-flight implementation here.
----------------------------------------------------------------

function R:RegisterPlayerFlight()

    local groupName =
        self:GetPlayerGroupName()

    if not groupName then

        env.error(
            "HELIOPS RADIO: No active human player group found"
        )

        return nil, nil, false
    end

    local flight =
        _DATABASE:GetOpsGroup(
            groupName
        )

    if flight then
        return flight, groupName, false
    end

    if not HeliOps.RegisterFlight then

        env.error(
            "HELIOPS RADIO: HeliOps:RegisterFlight unavailable"
        )

        return nil, groupName, false
    end

    flight =
        HeliOps:RegisterFlight(
            groupName
        )

    if not flight then

        env.error(
            "HELIOPS RADIO: Could not register player FLIGHTGROUP "
            .. tostring(groupName)
        )

        return nil, groupName, false
    end

    env.info(
        "HELIOPS RADIO: Registered player FLIGHTGROUP "
        .. tostring(groupName)
        .. " on first active radio command"
    )

    return flight, groupName, true
end

----------------------------------------------------------------
-- AIRPORT / CONTROLLER
----------------------------------------------------------------

function R:GetAirport(AirportKey)

    if not HeliOps.Airports
    or not HeliOps.Airports.Get then

        env.error(
            "HELIOPS RADIO: HeliOps.Airports:Get unavailable"
        )

        return nil
    end

    return HeliOps.Airports:Get(
        AirportKey
    )
end

function R:GetController(AirportKey)

    if not HeliOps.FlightControl
    or not HeliOps.FlightControl.Get then

        env.error(
            "HELIOPS RADIO: HeliOps.FlightControl:Get unavailable"
        )

        return nil
    end

    return HeliOps.FlightControl:Get(
        AirportKey
    )
end

----------------------------------------------------------------
-- FREQUENCY VALIDATION
----------------------------------------------------------------

function R:FrequencyMatches(
    Airport,
    ActualFrequencyHz,
    ActualModulation
)

    if not Airport
    or not Airport.FlightControl then
        return false
    end

    local Config =
        Airport.FlightControl

    local expectedMHz =
        tonumber(
            Config.Frequency
        )

    if not expectedMHz then
        return false
    end

    local expectedHz =
        math.floor(
            expectedMHz * 1000000
            + 0.5
        )

    local actualHz =
        tonumber(
            ActualFrequencyHz
        )

    if not actualHz then
        return false
    end

    if math.abs(
        actualHz - expectedHz
    ) > self.FrequencyToleranceHz then

        env.info(
            string.format(
                "HELIOPS RADIO: Frequency mismatch | expected %.3f MHz | actual %.3f MHz",
                expectedHz / 1000000,
                actualHz / 1000000
            )
        )

        return false
    end

    if Config.Modulation ~= nil
    and ActualModulation ~= nil then

        if tonumber(Config.Modulation)
        ~= tonumber(ActualModulation) then

            env.info(
                string.format(
                    "HELIOPS RADIO: Modulation mismatch | expected %s | actual %s",
                    tostring(Config.Modulation),
                    tostring(ActualModulation)
                )
            )

            return false
        end
    end

    return true
end

----------------------------------------------------------------
-- RADIO CHECK
--
-- RADIO_CHECK is intentionally small: no custom ATC state.
-- The response is sent through the existing MOOSE FLIGHTCONTROL
-- TransmissionTower() path, using the airport's configured MSRS/gRPC
-- tower radio.
----------------------------------------------------------------

function R:RadioCheck(
    AirportKey,
    FC,
    Flight,
    GroupName
)

    if not FC
    or not Flight
    or not GroupName then
        return false
    end

    if type(FC.TransmissionTower) ~= "function" then

        env.error(
            "HELIOPS RADIO: FLIGHTCONTROL TransmissionTower unavailable"
        )

        return false
    end

    local callsign =
        tostring(GroupName)

    if type(FC._GetCallsignName) == "function" then

        local ok, result =
            pcall(
                FC._GetCallsignName,
                FC,
                Flight
            )

        if ok
        and result
        and tostring(result) ~= "" then
            callsign = tostring(result)
        end
    end

    local station =
        tostring(
            FC.alias
            or AirportKey
        )

    local text =
        string.format(
            "%s, %s Tower, readability five",
            callsign,
            station
        )

    env.info(
        "HELIOPS RADIO: "
        .. tostring(AirportKey)
        .. " RADIO_CHECK -> "
        .. tostring(GroupName)
        .. " | response=\""
        .. text
        .. "\""
    )

    local ok, err =
        pcall(
            FC.TransmissionTower,
            FC,
            text,
            Flight,
            0
        )

    if not ok then

        env.error(
            "HELIOPS RADIO: RADIO_CHECK transmission failed: "
            .. tostring(err)
        )

        return false
    end

    return true
end

----------------------------------------------------------------
-- EXECUTE COMMAND AFTER PLAYER FLIGHT EXISTS
----------------------------------------------------------------

function R:ExecuteCommand(
    AirportKey,
    Command,
    GroupName,
    ActualFrequencyHz
)

    local fc =
        self:GetController(
            AirportKey
        )

    if not fc then

        env.error(
            "HELIOPS RADIO: No FLIGHTCONTROL for "
            .. tostring(AirportKey)
        )

        return false
    end

    local flight =
        _DATABASE:GetOpsGroup(
            GroupName
        )

    if not flight then

        env.error(
            "HELIOPS RADIO: Player FLIGHTGROUP not found after registration: "
            .. tostring(GroupName)
        )

        return false
    end

    local airborne = false

    if flight.IsAirborne then
        airborne = flight:IsAirborne()
    end

    env.info(
        string.format(
            "HELIOPS RADIO: %s %s -> %s | %.3f MHz | airborne=%s",
            tostring(AirportKey),
            tostring(Command),
            tostring(GroupName),
            tonumber(ActualFrequencyHz) / 1000000,
            tostring(airborne)
        )
    )

    ------------------------------------------------------------
    -- HELIOPS-SPECIFIC RADIO CHECK
    ------------------------------------------------------------

    if Command == "RADIO_CHECK" then

        return self:RadioCheck(
            AirportKey,
            fc,
            flight,
            GroupName
        )
    end

    ------------------------------------------------------------
    -- EXACT NATIVE MOOSE CALLBACK
    ------------------------------------------------------------

    local callbackName =
        self.NativeCommands[
            Command
        ]

    if not callbackName then

        env.error(
            "HELIOPS RADIO: Unsupported command "
            .. tostring(Command)
        )

        return false
    end

    local callback =
        fc[
            callbackName
        ]

    if type(callback) ~= "function" then

        env.error(
            "HELIOPS RADIO: FLIGHTCONTROL callback missing: "
            .. tostring(callbackName)
        )

        return false
    end

    local ok, err =
        pcall(
            callback,
            fc,
            GroupName
        )

    if not ok then

        env.error(
            "HELIOPS RADIO: MOOSE callback failed: "
            .. tostring(err)
        )

        return false
    end

    return true
end

----------------------------------------------------------------
-- DISPATCH
----------------------------------------------------------------

function R:Dispatch(
    AirportKey,
    Command,
    ActualFrequencyHz,
    ActualModulation
)

    local airport =
        self:GetAirport(
            AirportKey
        )

    if not airport then

        env.error(
            "HELIOPS RADIO: Unknown airport "
            .. tostring(AirportKey)
        )

        return false
    end

    if not self:FrequencyMatches(
        airport,
        ActualFrequencyHz,
        ActualModulation
    ) then
        return false
    end

    if Command ~= "RADIO_CHECK"
    and not self.NativeCommands[Command] then

        env.error(
            "HELIOPS RADIO: Unsupported command "
            .. tostring(Command)
        )

        return false
    end

    local fc =
        self:GetController(
            AirportKey
        )

    if not fc then

        env.error(
            "HELIOPS RADIO: No FLIGHTCONTROL for "
            .. tostring(AirportKey)
        )

        return false
    end

    local flight, groupName, wasCreated =
        self:RegisterPlayerFlight()

    if not flight
    or not groupName then
        return false
    end

    ------------------------------------------------------------
    -- Newly created player FLIGHTGROUP:
    -- wait briefly before invoking the requested MOOSE function.
    ------------------------------------------------------------

    if wasCreated then

        env.info(
            string.format(
                "HELIOPS RADIO: %s created; delaying %s by %.1f s for MOOSE sync",
                tostring(groupName),
                tostring(Command),
                self.RegistrationSyncDelay
            )
        )

        SCHEDULER:New(
            nil,
            function()

                R:ExecuteCommand(
                    AirportKey,
                    Command,
                    groupName,
                    ActualFrequencyHz
                )
            end,
            {},
            self.RegistrationSyncDelay
        )

        return true
    end

    ------------------------------------------------------------
    -- Existing FLIGHTGROUP:
    -- invoke immediately.
    ------------------------------------------------------------

    return self:ExecuteCommand(
        AirportKey,
        Command,
        groupName,
        ActualFrequencyHz
    )
end

----------------------------------------------------------------
-- POLL gRPC USER FLAGS
----------------------------------------------------------------

function R:Poll()

    if not HeliOps.Airports then
        return
    end

    local frequencyHz =
        getFlag(
            self.RadioFrequencyFlag
        )

    local modulation =
        getFlag(
            self.RadioModulationFlag
        )

    for airportKey, airport in pairs(
        HeliOps.Airports
    ) do

        if type(airport) == "table"
        and airport.Airbase then

            for _, command in ipairs(
                self.CommandNames
            ) do

                local flagName =
                    "HELIOPS_CALL_"
                    .. tostring(airportKey)
                    .. "_"
                    .. tostring(command)

                if getFlag(flagName) == 1 then

                    -- Clear FIRST so each voice command is handled once.
                    setFlag(
                        flagName,
                        0
                    )

                    self:Dispatch(
                        airportKey,
                        command,
                        frequencyHz,
                        modulation
                    )
                end
            end
        end
    end
end

----------------------------------------------------------------
-- RADIO COMMAND POLLER
--
-- Deliberately NO player-registration scheduler here.
----------------------------------------------------------------

R.CommandScheduler =
    SCHEDULER:New(
        nil,
        function()
            R:Poll()
        end,
        {},
        1,
        R.PollInterval
    )

env.info("=== HELIOPS RADIO ROUTER READY ===")
