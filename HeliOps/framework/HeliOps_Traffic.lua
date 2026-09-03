----------------------------------------------------------------
-- HELIOPS TRAFFIC
-- Generic AI flight routing, proximity tasks and abort handling
----------------------------------------------------------------

env.info("=== HELIOPS TRAFFIC START ===")

HeliOps = HeliOps or {}
HeliOps.Traffic = HeliOps.Traffic or {}

----------------------------------------------------------------
-- CONSTANTS
----------------------------------------------------------------

local METERS_TO_FEET = 3.28084

----------------------------------------------------------------
-- SHUFFLE
----------------------------------------------------------------

local function Shuffle(List)

    for i = #List, 2, -1 do

        local j = math.random(i)

        List[i], List[j] =
            List[j], List[i]
    end
end

----------------------------------------------------------------
-- VALIDATE CONFIG
----------------------------------------------------------------

function HeliOps.Traffic:ValidateConfig(Config)

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

function HeliOps.Traffic:CreateRoutePlan(Config)

    local plan = {}

    for i, navIndex in ipairs(Config.Route) do

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
    -- Shuffle WP + Task pairs together
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
        terrain_ft + clearance_ft

    if altitude_ft < minimumAltitude_ft then

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

    return {

        WP         = Nav.WP,
        PoolIndex  = PoolIndex,

        Coordinate = coord,

        Speed_kt   = speed_kt,
        Alt_ft_msl = altitude_ft,
        Terrain_ft = terrain_ft,
    }
end

----------------------------------------------------------------
-- START ORBIT TASK
----------------------------------------------------------------

function HeliOps.Traffic:StartOrbitTask(
    Flight,
    WPData,
    TaskConfig,
    Config
)

    local vec2 =
        WPData.Coordinate:GetVec2()

    local altitude_m =
        UTILS.FeetToMeters(
            WPData.Alt_ft_msl
        )

    local speed_mps =
        UTILS.KnotsToMps(
            WPData.Speed_kt
        )

    ------------------------------------------------------------
    -- DCS ORBIT TASK
    ------------------------------------------------------------

    local orbitTask = {

        id = "Orbit",

        params = {

            pattern = "Circle",

            point = {
                x = vec2.x,
                y = vec2.y,
            },

            speed =
                speed_mps,

            altitude =
                altitude_m,
        }
    }

    ------------------------------------------------------------
    -- REPLACE CURRENT DCS TASK WITH ORBIT
    ------------------------------------------------------------

    Flight.group:SetTask(
        orbitTask
    )

    local duration =
        TaskConfig.Duration_s
        or 120

    env.info(
        string.format(
            "HELIOPS TRAFFIC: %s ORBIT_CIRCLE started at %s for %d sec",
            Config.Group,
            WPData.WP,
            duration
        )
    )

    trigger.action.outText(
        Config.Group
        .. " ORBIT at "
        .. WPData.WP
        .. " for "
        .. tostring(duration)
        .. " sec",
        10
    )

    ------------------------------------------------------------
    -- RESUME ROUTE AFTER TASK
    ------------------------------------------------------------

    SCHEDULER:New(

        nil,

        function()

            if not Flight
            or not Flight.group
            or not Flight.group:IsAlive() then

                return
            end

            env.info(
                "HELIOPS TRAFFIC: "
                .. Config.Group
                .. " ORBIT complete -> resume route"
            )

            trigger.action.outText(
                Config.Group
                .. " ORBIT COMPLETE -> RESUME ROUTE",
                10
            )

            Flight:UpdateRoute()

        end,

        {},

        duration
    )
end

----------------------------------------------------------------
-- CREATE PROXIMITY TASK
--
-- A task is triggered when the GROUP enters a radius around
-- its associated NAV waypoint.
----------------------------------------------------------------

function HeliOps.Traffic:AddWaypointTask(
    Flight,
    Waypoint,
    WPData,
    TaskIndex,
    Config
)

    ------------------------------------------------------------
    -- 0 = no task
    ------------------------------------------------------------

    if not TaskIndex
    or TaskIndex == 0 then

        return true
    end

    ------------------------------------------------------------
    -- TASK CONFIG
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
    -- CURRENTLY SUPPORTED TASK
    ------------------------------------------------------------

    if taskConfig.Type ~= "ORBIT_CIRCLE" then

        env.error(
            "HELIOPS TRAFFIC: Unsupported task type: "
            .. tostring(taskConfig.Type)
        )

        return false
    end

    ------------------------------------------------------------
    -- TRIGGER RADIUS
    ------------------------------------------------------------

    local radius_m =
        taskConfig.TriggerRadius_m
        or 3000

    ------------------------------------------------------------
    -- TASK ZONE
    ------------------------------------------------------------

    local vec2 =
        WPData.Coordinate:GetVec2()

    local zoneName =
        string.format(
            "HELIOPS_%s_%s_TASK_%d",
            Config.Group,
            WPData.WP,
            TaskIndex
        )

    local taskZone =
        ZONE_RADIUS:New(
            zoneName,
            vec2,
            radius_m
        )

    ------------------------------------------------------------
    -- WATCH DCS GROUP
    ------------------------------------------------------------

    local watchedGroup =
        GROUP:FindByName(
            Config.Group
        )

    if not watchedGroup then

        env.error(
            "HELIOPS TRAFFIC: Group not found for task zone: "
            .. Config.Group
        )

        return false
    end

    ------------------------------------------------------------
    -- FASTER CHECK FOR FAST AIRCRAFT
    ------------------------------------------------------------

    taskZone:SetCheckTime(1)

    ------------------------------------------------------------
    -- ONE SHOT
    ------------------------------------------------------------

    local triggered = false

    ------------------------------------------------------------
    -- ENTER ZONE CALLBACK
    ------------------------------------------------------------

    function taskZone:OnAfterEnteredZone(
        From,
        Event,
        To,
        Controllable
    )

        if triggered then
            return
        end

        triggered = true

        env.info(
            string.format(
                "HELIOPS TRAFFIC: %s entered task radius at %s",
                Config.Group,
                WPData.WP
            )
        )

        trigger.action.outText(
            Config.Group
            .. " TASK TRIGGER: "
            .. WPData.WP,
            10
        )

        --------------------------------------------------------
        -- Stop further zone checks
        --------------------------------------------------------

        self:TriggerStop()

        --------------------------------------------------------
        -- EXECUTE TASK
        --------------------------------------------------------

        HeliOps.Traffic:StartOrbitTask(
            Flight,
            WPData,
            taskConfig,
            Config
        )
    end

    ------------------------------------------------------------
    -- START MONITORING
    ------------------------------------------------------------

    taskZone:Trigger(
        watchedGroup
    )

    ------------------------------------------------------------
    -- Keep reference alive
    ------------------------------------------------------------

    Flight._HeliOpsTaskZones =
        Flight._HeliOpsTaskZones
        or {}

    table.insert(
        Flight._HeliOpsTaskZones,
        taskZone
    )

    env.info(
        string.format(
            "HELIOPS TRAFFIC: %s proximity task created at %s radius=%d m task=%d",
            Config.Group,
            WPData.WP,
            radius_m,
            TaskIndex
        )
    )

    return true
end

----------------------------------------------------------------
-- BUILD ROUTE
--
-- Build MOOSE route immediately.
-- DO NOT UpdateRoute here.
----------------------------------------------------------------

function HeliOps.Traffic:BuildRoute(
    Flight,
    Config
)

    if not self:ValidateConfig(Config) then
        return false
    end

    ------------------------------------------------------------
    -- Prevent duplicate route creation
    ------------------------------------------------------------

    if Flight._HeliOpsRoutePrepared then

        return true
    end

    local plan =
        self:CreateRoutePlan(
            Config
        )

    ------------------------------------------------------------
    -- RTB
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

        return false
    end

    Flight:SetDestinationbase(
        destination
    )

    ------------------------------------------------------------
    -- SCREEN ROUTE
    ------------------------------------------------------------

    local routeText =
        Config.Group
        .. " route:\n"

    ------------------------------------------------------------
    -- ADD WAYPOINTS
    ------------------------------------------------------------

    for routePosition, item in ipairs(plan) do

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
        -- false = don't update DCS controller yet
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
        -- PROXIMITY TASK
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
        -- LOG
        --------------------------------------------------------

        env.info(
            string.format(
                "HELIOPS TRAFFIC: %s Route[%d] NavPool[%d] %s | %.0f kt | %.0f ft | Task=%d",
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
        -- SCREEN TEXT
        --------------------------------------------------------

        routeText =
            routeText
            .. tostring(routePosition)
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
        .. " route prepared"
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
-- START TRAFFIC
----------------------------------------------------------------

function HeliOps.Traffic:Start(
    Config
)

    if not self:ValidateConfig(Config) then
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
    -- VERBOSITY
    ------------------------------------------------------------

    if HeliOps.Config
    and HeliOps.Config.Verbosity then

        flight:SetVerbosity(
            HeliOps.Config.Verbosity
        )
    end

    ------------------------------------------------------------
    -- PREPARE ROUTE NOW
    --
    -- Prevent initial false ARRIVED state.
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
    -- TAKEOFF -> ACTIVATE ROUTE
    ------------------------------------------------------------

    function flight:onafterTakeoff(
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
