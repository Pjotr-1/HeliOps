----------------------------------------------------------------
-- HELIOPS TRAFFIC
--
-- MOOSE-native traffic framework.
--
-- MOOSE owns:
--   route
--   waypoint passage
--   waypoint tasks
--   task duration
--   RTB / holding / landing
----------------------------------------------------------------

env.info("=== HELIOPS TRAFFIC START ===")

HeliOps = HeliOps or {}
HeliOps.Traffic = HeliOps.Traffic or {}

----------------------------------------------------------------
-- LANDING MODE ENUM
--
-- Used only when Config.TacticalLanding is true.
-- If TacticalLanding is false/nil, native MOOSE/DCS landing
-- behavior is left completely untouched.
----------------------------------------------------------------

HeliOps.LandingMode = HeliOps.LandingMode or {
    OVERHEAD_BREAK = 1,
    STRAIGHT_IN    = 2,
}

----------------------------------------------------------------
-- CONSTANTS
----------------------------------------------------------------

local METERS_TO_FEET = 3.28084

----------------------------------------------------------------
-- SHUFFLE
----------------------------------------------------------------

local function Shuffle(List)

    for i = #List, 2, -1 do

        local j =
            math.random(i)

        List[i], List[j] =
            List[j], List[i]
    end
end

----------------------------------------------------------------
-- VALIDATE CONFIG
----------------------------------------------------------------

function HeliOps.Traffic:ValidateConfig(
    Config
)

    if not Config then

        env.error(
            "HELIOPS TRAFFIC: Config missing"
        )

        return false
    end

    if not Config.Group then

        env.error(
            "HELIOPS TRAFFIC: Group missing"
        )

        return false
    end

    if not Config.NavPool
    or #Config.NavPool == 0 then

        env.error(
            "HELIOPS TRAFFIC: NavPool missing/empty for "
            .. Config.Group
        )

        return false
    end

    if not Config.Route
    or #Config.Route == 0 then

        env.error(
            "HELIOPS TRAFFIC: Route missing/empty for "
            .. Config.Group
        )

        return false
    end

    if Config.Tasks
    and #Config.Tasks ~= #Config.Route then

        env.error(
            "HELIOPS TRAFFIC: Route and Tasks must have same length for "
            .. Config.Group
        )

        return false
    end

    if not Config.RTB then

        env.error(
            "HELIOPS TRAFFIC: RTB missing for "
            .. Config.Group
        )

        return false
    end

    return true
end

----------------------------------------------------------------
-- CREATE ROUTE PLAN
----------------------------------------------------------------

function HeliOps.Traffic:CreateRoutePlan(
    Config
)

    local plan = {}

    for i, navIndex in ipairs(
        Config.Route
    ) do

        local taskIndex = 0

        if Config.Tasks
        and Config.Tasks[i] then

            taskIndex =
                Config.Tasks[i]
        end

        table.insert(
            plan,
            {
                NavIndex  = navIndex,
                TaskIndex = taskIndex,
            }
        )
    end

    ------------------------------------------------------------
    -- Shuffle waypoint/task pairs together
    ------------------------------------------------------------

    if Config.RandomizeRoute == true then

        Shuffle(plan)

        env.info(
            "HELIOPS TRAFFIC: "
            .. Config.Group
            .. " route randomized"
        )
    end

    return plan
end

----------------------------------------------------------------
-- PREPARE WAYPOINT
----------------------------------------------------------------

function HeliOps.Traffic:PrepareWaypoint(
    Config,
    Nav,
    PoolIndex
)

    ------------------------------------------------------------
    -- VALIDATE NAV ENTRY
    ------------------------------------------------------------

    if not Nav then

        env.error(
            "HELIOPS TRAFFIC: Invalid NavPool index "
            .. tostring(PoolIndex)
        )

        return nil
    end

    if not Nav.WP then

        env.error(
            "HELIOPS TRAFFIC: WP missing at NavPool index "
            .. tostring(PoolIndex)
        )

        return nil
    end

    if not Nav.Speed_kt then

        env.error(
            "HELIOPS TRAFFIC: Speed_kt missing for "
            .. tostring(Nav.WP)
        )

        return nil
    end

    if not Nav.Alt_ft_msl then

        env.error(
            "HELIOPS TRAFFIC: Alt_ft_msl missing for "
            .. tostring(Nav.WP)
        )

        return nil
    end

    ------------------------------------------------------------
    -- NAV ZONE
    ------------------------------------------------------------

    local zone =
        ZONE:FindByName(
            Nav.WP
        )

    if not zone then

        env.error(
            "HELIOPS TRAFFIC: NAV zone not found: "
            .. tostring(Nav.WP)
        )

        trigger.action.outText(
            "ERROR: NAV zone not found: "
            .. tostring(Nav.WP),
            20
        )

        return nil
    end

    ------------------------------------------------------------
    -- COORDINATE
    ------------------------------------------------------------

    local coord =
        zone:GetCoordinate()

    ------------------------------------------------------------
    -- SPEED
    ------------------------------------------------------------

    local speed_kt =
        Nav.Speed_kt

    if Config.Limits then

        if Config.Limits.MinSpeed_kt
        and speed_kt <
            Config.Limits.MinSpeed_kt then

            env.warning(
                string.format(
                    "HELIOPS TRAFFIC: %s speed %.0f kt corrected to %.0f kt",
                    Nav.WP,
                    speed_kt,
                    Config.Limits.MinSpeed_kt
                )
            )

            speed_kt =
                Config.Limits.MinSpeed_kt
        end

        if Config.Limits.MaxSpeed_kt
        and speed_kt >
            Config.Limits.MaxSpeed_kt then

            env.warning(
                string.format(
                    "HELIOPS TRAFFIC: %s speed %.0f kt corrected to %.0f kt",
                    Nav.WP,
                    speed_kt,
                    Config.Limits.MaxSpeed_kt
                )
            )

            speed_kt =
                Config.Limits.MaxSpeed_kt
        end
    end

    ------------------------------------------------------------
    -- ALTITUDE / TERRAIN
    ------------------------------------------------------------

    local terrain_ft =
        coord:GetLandHeight()
        * METERS_TO_FEET

    local altitude_ft =
        Nav.Alt_ft_msl

    local clearance_ft = 0

    if Config.Limits
    and Config.Limits.MinTerrainClearance_ft then

        clearance_ft =
            Config.Limits.MinTerrainClearance_ft
    end

    local minimumAltitude_ft =
        terrain_ft
        + clearance_ft

    if altitude_ft <
        minimumAltitude_ft then

        env.warning(
            string.format(
                "HELIOPS TRAFFIC: %s altitude %.0f ft MSL corrected to %.0f ft MSL",
                Nav.WP,
                altitude_ft,
                minimumAltitude_ft
            )
        )

        altitude_ft =
            minimumAltitude_ft
    end

    ------------------------------------------------------------
    -- RETURN
    ------------------------------------------------------------

    return {

        WP =
            Nav.WP,

        PoolIndex =
            PoolIndex,

        Coordinate =
            coord,

        Speed_kt =
            speed_kt,

        Alt_ft_msl =
            altitude_ft,

        Terrain_ft =
            terrain_ft,
    }
end

----------------------------------------------------------------
-- ADD MOOSE WAYPOINT TASK
----------------------------------------------------------------

function HeliOps.Traffic:AddWaypointTask(
    Flight,
    Waypoint,
    WPData,
    TaskIndex,
    Config
)

    ------------------------------------------------------------
    -- 0 = NO TASK
    ------------------------------------------------------------

    if not TaskIndex
    or TaskIndex == 0 then

        return true
    end

    ------------------------------------------------------------
    -- TASK POOL
    ------------------------------------------------------------

    if not Config.TaskPool then

        env.error(
            "HELIOPS TRAFFIC: TaskPool missing for "
            .. Config.Group
        )

        return false
    end

    local taskConfig =
        Config.TaskPool[
            TaskIndex
        ]

    if not taskConfig then

        env.error(
            "HELIOPS TRAFFIC: Invalid TaskPool index "
            .. tostring(TaskIndex)
        )

        return false
    end

    ------------------------------------------------------------
    -- ORBIT CIRCLE
    ------------------------------------------------------------

    if taskConfig.Type ==
        "ORBIT_CIRCLE" then

        local altitude_m =
            UTILS.FeetToMeters(
                WPData.Alt_ft_msl
            )

        local speed_mps =
            UTILS.KnotsToMps(
                WPData.Speed_kt
            )

        --------------------------------------------------------
        -- MOOSE ORBIT TASK
        --------------------------------------------------------

        local orbitTask =
            Flight.group:TaskOrbit(
                WPData.Coordinate,
                altitude_m,
                speed_mps
            )

        if not orbitTask then

            env.error(
                "HELIOPS TRAFFIC: TaskOrbit failed at "
                .. WPData.WP
            )

            return false
        end

        --------------------------------------------------------
        -- MOOSE WAYPOINT TASK
        --------------------------------------------------------

        local mooseTask =
            Flight:AddTaskWaypoint(
                orbitTask,
                Waypoint,
                "Orbit Circle",
                50,
                taskConfig.Duration_s
            )

        if not mooseTask then

            env.error(
                "HELIOPS TRAFFIC: AddTaskWaypoint failed at "
                .. WPData.WP
            )

            return false
        end

        env.info(
            string.format(
                "HELIOPS TRAFFIC: %s ORBIT queued at %s | %.0f ft | %.0f kt | duration=%d sec",
                Config.Group,
                WPData.WP,
                WPData.Alt_ft_msl,
                WPData.Speed_kt,
                taskConfig.Duration_s or 0
            )
        )

        return true
    end

    ------------------------------------------------------------
    -- UNKNOWN TASK
    ------------------------------------------------------------

    env.error(
        "HELIOPS TRAFFIC: Unsupported task type: "
        .. tostring(taskConfig.Type)
    )

    return false
end

----------------------------------------------------------------
-- BUILD MOOSE ROUTE
--
-- Route is prepared immediately.
-- UpdateRoute is NOT called here.
--
-- This prevents false ARRIVED at mission start.
----------------------------------------------------------------

function HeliOps.Traffic:BuildRoute(
    Flight,
    Config
)

    if not self:ValidateConfig(
        Config
    ) then

        return false
    end

    ------------------------------------------------------------
    -- PREVENT DUPLICATE BUILD
    ------------------------------------------------------------

    if Flight._HeliOpsRoutePrepared then

        env.warning(
            "HELIOPS TRAFFIC: Route already prepared for "
            .. Config.Group
        )

        return true
    end

    ------------------------------------------------------------
    -- ROUTE PLAN
    ------------------------------------------------------------

    local plan =
        self:CreateRoutePlan(
            Config
        )

    ------------------------------------------------------------
    -- DESTINATION
    ------------------------------------------------------------

    local destination =
        AIRBASE:FindByName(
            Config.RTB
        )

    if not destination then

        env.error(
            "HELIOPS TRAFFIC: RTB base not found: "
            .. tostring(Config.RTB)
        )

        trigger.action.outText(
            "ERROR: RTB base not found: "
            .. tostring(Config.RTB),
            20
        )

        return false
    end

    Flight:SetDestinationbase(
        destination
    )

    ------------------------------------------------------------
    -- ROUTE DISPLAY
    ------------------------------------------------------------

    local routeText =
        Config.Group
        .. " route:\n"

    ------------------------------------------------------------
    -- CREATE MOOSE WAYPOINTS
    ------------------------------------------------------------

    for routePosition, item in ipairs(
        plan
    ) do

        local nav =
            Config.NavPool[
                item.NavIndex
            ]

        local wpData =
            self:PrepareWaypoint(
                Config,
                nav,
                item.NavIndex
            )

        if not wpData then

            return false
        end

        --------------------------------------------------------
        -- ADD MOOSE WAYPOINT
        --
        -- false = no UpdateRoute yet.
        --------------------------------------------------------

        local waypoint =
            Flight:AddWaypoint(
                wpData.Coordinate,
                wpData.Speed_kt,
                nil,
                wpData.Alt_ft_msl,
                false
            )

        if not waypoint then

            env.error(
                "HELIOPS TRAFFIC: AddWaypoint failed for "
                .. wpData.WP
            )

            return false
        end

        --------------------------------------------------------
        -- NAME WAYPOINT
        --------------------------------------------------------

        waypoint.name =
            wpData.WP

        --------------------------------------------------------
        -- DEBUG CREATION
        --------------------------------------------------------

        env.info(
            string.format(
                "HELIOPS TRAFFIC: CREATED WP route=%d pool=%d name=%s uid=%s temp=%s",
                routePosition,
                item.NavIndex,
                wpData.WP,
                tostring(
                    waypoint.uid
                ),
                tostring(
                    waypoint.temp
                )
            )
        )

        --------------------------------------------------------
        -- MOOSE WAYPOINT TASK
        --------------------------------------------------------

        local taskOK =
            self:AddWaypointTask(
                Flight,
                waypoint,
                wpData,
                item.TaskIndex,
                Config
            )

        if not taskOK then

            return false
        end

        --------------------------------------------------------
        -- ROUTE LOG
        --------------------------------------------------------

        env.info(
            string.format(
                "HELIOPS TRAFFIC: %s Route[%d] NavPool[%d] %s | %.0f kt | %.0f ft MSL | Task=%d",
                Config.Group,
                routePosition,
                item.NavIndex,
                wpData.WP,
                wpData.Speed_kt,
                wpData.Alt_ft_msl,
                item.TaskIndex
            )
        )

        --------------------------------------------------------
        -- SCREEN
        --------------------------------------------------------

        routeText =
            routeText
            .. tostring(
                routePosition
            )
            .. ": "
            .. wpData.WP
            .. "  "
            .. math.floor(
                wpData.Speed_kt + 0.5
            )
            .. " kt / "
            .. math.floor(
                wpData.Alt_ft_msl + 0.5
            )
            .. " ft"

        if item.TaskIndex ~= 0 then

            routeText =
                routeText
                .. " TASK "
                .. tostring(
                    item.TaskIndex
                )
        end

        routeText =
            routeText
            .. "\n"
    end

    ------------------------------------------------------------
    -- ROUTE PREPARED
    ------------------------------------------------------------

    Flight._HeliOpsRoutePrepared =
        true

    routeText =
        routeText
        .. "RTB: "
        .. tostring(
            Config.RTB
        )

    if HeliOps.Config
    and HeliOps.Config.Debug then

        trigger.action.outText(
            routeText,
            20
        )
    end

    env.info(
        "HELIOPS TRAFFIC: "
        .. Config.Group
        .. " MOOSE route prepared"
    )

    return true
end

----------------------------------------------------------------
-- ABORT AND RTB
----------------------------------------------------------------

function HeliOps.Traffic:AbortAndRTB(
    Flight,
    Config,
    Reason
)

    if Flight._HeliOpsAbort then
        return
    end

    Flight._HeliOpsAbort =
        true

    local destination =
        AIRBASE:FindByName(
            Config.RTB
        )

    if not destination then

        env.error(
            "HELIOPS TRAFFIC: ABORT failed - RTB base not found"
        )

        return
    end

    env.warning(
        "HELIOPS TRAFFIC: "
        .. Config.Group
        .. " ABORT -> RTB: "
        .. tostring(Reason)
    )

    trigger.action.outText(
        Config.Group
        .. " ABORT -> RTB\n"
        .. tostring(Reason),
        20
    )

    Flight:RTB(
        destination
    )
end

----------------------------------------------------------------
-- START TRAFFIC FLIGHT
----------------------------------------------------------------

function HeliOps.Traffic:Start(
    Config
)

    ------------------------------------------------------------
    -- VALIDATE
    ------------------------------------------------------------

    if not self:ValidateConfig(
        Config
    ) then

        return nil
    end

    ------------------------------------------------------------
    -- REGISTER FLIGHTGROUP
    ------------------------------------------------------------

    local flight =
        HeliOps:RegisterFlight(
            Config.Group
        )

    if not flight then

        return nil
    end

    ------------------------------------------------------------
    -- LANDING POLICY
    --
    -- TacticalLanding = true:
    --   ModeOpt = HeliOps.LandingMode.OVERHEAD_BREAK
    --   ModeOpt = HeliOps.LandingMode.STRAIGHT_IN
    --
    -- TacticalLanding = false/nil:
    --   Native MOOSE/DCS landing behavior is left untouched.
    ------------------------------------------------------------

    if Config.TacticalLanding then

        if Config.ModeOpt ==
            HeliOps.LandingMode.OVERHEAD_BREAK then

            flight:SetOptionLandingOverheadBreak()

            env.info(
                "HELIOPS TRAFFIC: "
                .. Config.Group
                .. " landing mode = TACTICAL / OVERHEAD BREAK"
            )

        elseif Config.ModeOpt ==
            HeliOps.LandingMode.STRAIGHT_IN then

            flight:SetOptionLandingStraightIn()

            env.info(
                "HELIOPS TRAFFIC: "
                .. Config.Group
                .. " landing mode = TACTICAL / STRAIGHT IN"
            )

        else

            env.error(
                "HELIOPS TRAFFIC: "
                .. Config.Group
                .. " TacticalLanding enabled but ModeOpt is invalid: "
                .. tostring(Config.ModeOpt)
            )

            return nil
        end
    end

    ------------------------------------------------------------
    -- VERBOSITY
    ------------------------------------------------------------

    if HeliOps.Config
    and HeliOps.Config.Verbosity then

        flight:SetVerbosity(
            HeliOps.Config.Verbosity
        )
    end

    ------------------------------------------------------------
    -- DEFAULT / RTB CRUISE ALTITUDE
    --
    -- MOOSE API uses FEET.
    ------------------------------------------------------------

    if Config.CruiseAlt_ft then

        flight:SetDefaultAltitude(
            Config.CruiseAlt_ft
        )

        env.info(
            string.format(
                "HELIOPS TRAFFIC: %s default cruise altitude = %.0f ft",
                Config.Group,
                Config.CruiseAlt_ft
            )
        )
    end

    ------------------------------------------------------------
    -- PREPARE ROUTE IMMEDIATELY
    --
    -- Prevent false ARRIVED at mission start.
    ------------------------------------------------------------

    local prepared =
        HeliOps.Traffic:BuildRoute(
            flight,
            Config
        )

    if not prepared then

        trigger.action.outText(
            "ERROR: Route preparation failed for "
            .. Config.Group,
            20
        )

        return nil
    end

    ------------------------------------------------------------
    -- TAKEOFF -> SEND MOOSE ROUTE TO DCS
    ------------------------------------------------------------

    function flight:OnAfterTakeoff(
        From,
        Event,
        To,
        Airbase
    )

        env.info(
            "HELIOPS TRAFFIC: "
            .. Config.Group
            .. " TAKEOFF -> UpdateRoute"
        )

        self:UpdateRoute()
    end

    ------------------------------------------------------------
    -- DAMAGE ABORT
    ------------------------------------------------------------

    if Config.AbortConditions
    and Config.AbortConditions.OnDamage == true then

        function flight:OnAfterDamaged(
            From,
            Event,
            To
        )

            HeliOps.Traffic:AbortAndRTB(
                self,
                Config,
                "Flight damaged"
            )
        end

        function flight:OnAfterElementDamaged(
            From,
            Event,
            To,
            Element
        )

            HeliOps.Traffic:AbortAndRTB(
                self,
                Config,
                "Flight element damaged"
            )
        end

        function flight:OnAfterElementDead(
            From,
            Event,
            To,
            Element
        )

            HeliOps.Traffic:AbortAndRTB(
                self,
                Config,
                "Flight element lost"
            )
        end
    end

    ------------------------------------------------------------
    -- DEBUG
    ------------------------------------------------------------

    if HeliOps.Debug
    and HeliOps.Debug.Attach then

        HeliOps.Debug:Attach(
            flight,
            Config.Group
        )
    end

    ------------------------------------------------------------
    -- READY
    ------------------------------------------------------------

    env.info(
        "HELIOPS TRAFFIC: "
        .. Config.Group
        .. " ready"
    )

    return flight
end

----------------------------------------------------------------
-- READY
----------------------------------------------------------------

env.info("=== HELIOPS TRAFFIC READY ===")
