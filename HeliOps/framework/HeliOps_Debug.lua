----------------------------------------------------------------
-- HELIOPS DEBUG
--
-- MOOSE user callbacks use OnAfter<Event>.
-- Never override internal onafter<Event>.
----------------------------------------------------------------

env.info("=== HELIOPS DEBUG START ===")

HeliOps = HeliOps or {}
HeliOps.Debug = HeliOps.Debug or {}

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

    function Flight:OnAfterPassingWaypoint(
        From,
        Event,
        To,
        Waypoint
    )

        local uid = -1
        local npassed = -1
        local index = -1
        local name = "UNKNOWN"
        local temp = "UNKNOWN"

        if Waypoint then

            uid =
                Waypoint.uid
                or -1

            npassed =
                Waypoint.npassed
                or -1

            name =
                Waypoint.name
                or "UNNAMED"

            temp =
                tostring(
                    Waypoint.temp
                )

            if Flight.waypoints then

                for i, wp in ipairs(
                    Flight.waypoints
                ) do

                    if wp.uid == uid then

                        index = i
                        break
                    end
                end
            end
        end

        local text =
            string.format(
                "%s DEBUG: PassingWaypoint index=%s uid=%s npassed=%s temp=%s name=%s",
                GroupName,
                tostring(index),
                tostring(uid),
                tostring(npassed),
                tostring(temp),
                tostring(name)
            )

        env.info(text)

        if HeliOps.Config
        and HeliOps.Config.Debug then

            trigger.action.outText(
                text,
                12
            )
        end
    end

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
    -- RTB
    ------------------------------------------------------------

    function Flight:OnAfterRTB(
        From,
        Event,
        To,
        Airbase,
        SpeedTo,
        SpeedHold,
        SpeedLand
    )

        local text =
            string.format(
                "RTB | cruise=%.0f ft",
                Flight:GetCruiseAltitude()
                or -1
            )

        HeliOps.Debug:Message(
            GroupName,
            text
        )
    end

    ------------------------------------------------------------
    -- HOLDING
    ------------------------------------------------------------

    function Flight:OnAfterHolding(
        From,
        Event,
        To
    )

        HeliOps.Debug:Message(
            GroupName,
            "HOLDING"
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
        To,
        Airbase
    )

        HeliOps.Debug:Message(
            GroupName,
            "LANDED"
        )
    end

    ------------------------------------------------------------
    -- PARKING
    ------------------------------------------------------------

    function Flight:OnAfterParking(
        From,
        Event,
        To
    )

        HeliOps.Debug:Message(
            GroupName,
            "PARKING"
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
