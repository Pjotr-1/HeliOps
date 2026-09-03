----------------------------------------------------------------
-- HELIOPS
-- Core framework
----------------------------------------------------------------

env.info("=== HELIOPS CORE START ===")

HeliOps = HeliOps or {}

HeliOps.Version = "0.1"

----------------------------------------------------------------
-- REGISTER EXISTING DCS GROUP AS FLIGHTGROUP
----------------------------------------------------------------

function HeliOps:RegisterFlight(GroupName)

    env.info(
        "HELIOPS: Registering flight " .. GroupName
    )

    local group = GROUP:FindByName(GroupName)

    if not group then

        env.error(
            "HELIOPS: Group not found: " .. GroupName
        )

        return nil
    end


    local flight = FLIGHTGROUP:New(group)

    if not flight then

        env.error(
            "HELIOPS: Could not create FLIGHTGROUP: "
            .. GroupName
        )

        return nil
    end


    env.info(
        "HELIOPS: FLIGHTGROUP created: "
        .. GroupName
    )

    return flight

end


----------------------------------------------------------------
-- UTILITY
----------------------------------------------------------------

function HeliOps:Message(Text, Time)

    trigger.action.outText(
        Text,
        Time or 10
    )

end


env.info(
    "=== HELIOPS CORE READY ==="
)