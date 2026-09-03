----------------------------------------------------------------
-- HELIOPS DEBUG
--
-- IMPORTANT:
-- User callbacks use OnAfter<Event>.
-- Do NOT override MOOSE internal onafter<Event> handlers.
----------------------------------------------------------------

env.info("=== HELIOPS DEBUG START ===")

HeliOps = HeliOps or {}
HeliOps.Debug = HeliOps.Debug or {}

trigger.action.outText(
    "DEBUG FILE VERSION B LOADED",
    15
)

----------------------------------------------------------------
-- DEBUG MESSAGE
----------------------------------------------------------------

function HeliOps.Debug:Message(
    GroupName,
    EventName
)

    local text =
        GroupName
        .. " DEBUG: "
        .. EventName

    env.info(text)

    if HeliOps.Config
    and HeliOps.Config.Debug then

        trigger.action.outText(
            text,
            10
        )
    end
end

----------------------------------------------------------------
-- ATTACH DEBUG CALLBACKS
----------------------------------------------------------------

function HeliOps.Debug:Attach(
    Flight,
    GroupName
)

    ------------------------------------------------------------
    -- PASSING WAYPOINT
    ------------------------------------------------------------
--[[
    function Flight:OnAfterPassingWaypoint(
        From,
        Event,
        To,
        Waypoint
    )

        HeliOps.Debug:Message(
            GroupName,
            "PassingWaypoint"
        )

        if Waypoint then

            env.info(
                string.format(
                    "HELIOPS DEBUG: %s waypoint UID=%s name=%s",
                    GroupName,
                    tostring(Waypoint.uid),
                    tostring(Waypoint.name)
                )
            )
        end
    end
--]]
    ------------------------------------------------------------
    -- FINAL WAYPOINT
    ------------------------------------------------------------

    function Flight:OnAfterPassedFinalWaypoint(
        From,
        Event,
        To
    )

        HeliOps.Debug:Message(
            GroupName,
            "PassedFinalWaypoint"
        )
    end

    ------------------------------------------------------------
    -- INBOUND
    ------------------------------------------------------------

    function Flight:OnAfterInbound(
        From,
        Event,
        To
    )

        HeliOps.Debug:Message(
            GroupName,
            "INBOUND"
        )
    end

    ------------------------------------------------------------
    -- LANDING
    ------------------------------------------------------------

    function Flight:OnAfterLanding(
        From,
        Event,
        To
    )

        HeliOps.Debug:Message(
            GroupName,
            "LANDING"
        )
    end

    ------------------------------------------------------------
    -- LANDED
    ------------------------------------------------------------

    function Flight:OnAfterLanded(
        From,
        Event,
        To
    )

        HeliOps.Debug:Message(
            GroupName,
            "LANDED"
        )
    end

    ------------------------------------------------------------
    -- ARRIVED
    ------------------------------------------------------------

    function Flight:OnAfterArrived(
        From,
        Event,
        To
    )

        HeliOps.Debug:Message(
            GroupName,
            "ARRIVED"
        )
    end

    ------------------------------------------------------------
    -- DEAD
    ------------------------------------------------------------

    function Flight:OnAfterDead(
        From,
        Event,
        To
    )

        HeliOps.Debug:Message(
            GroupName,
            "DEAD"
        )
    end

end

----------------------------------------------------------------
-- READY
----------------------------------------------------------------

env.info("=== HELIOPS DEBUG READY ===")
