----------------------------------------------------------------
-- HELIOPS NAVIGATION
-- Cyprus navigation zone database
----------------------------------------------------------------

env.info("=== HELIOPS NAV START ===")

HeliOps = HeliOps or {}
HeliOps.Nav = HeliOps.Nav or {}


----------------------------------------------------------------
-- CYPRUS NAVIGATION ZONES
----------------------------------------------------------------

HeliOps.Nav.Cyprus = {

    "NAV_CYP_01",
    "NAV_CYP_02",
    "NAV_CYP_03",
    "NAV_CYP_04",
    "NAV_CYP_05",
    "NAV_CYP_06",
    "NAV_CYP_07",
    "NAV_CYP_08",
    "NAV_CYP_09",
    "NAV_CYP_10",

}


----------------------------------------------------------------
-- GET ALL EXISTING NAV ZONES
----------------------------------------------------------------

function HeliOps.Nav:GetZones(Area)

    local names =
        HeliOps.Nav[Area]

    local zones = {}


    if not names then

        env.error(
            "HELIOPS NAV: Unknown area: "
            .. tostring(Area)
        )

        return zones
    end


    for _, zoneName in ipairs(names) do

        local zone =
            ZONE:FindByName(zoneName)

        if zone then

            table.insert(
                zones,
                zone
            )

            env.info(
                "HELIOPS NAV: Found "
                .. zoneName
            )

        else

            env.info(
                "HELIOPS NAV: Zone not present: "
                .. zoneName
            )

        end

    end


    return zones

end


----------------------------------------------------------------
-- SHUFFLE TABLE
----------------------------------------------------------------

function HeliOps.Nav:Shuffle(List)

    for i = #List, 2, -1 do

        local j =
            math.random(i)

        List[i], List[j] =
            List[j], List[i]

    end


    return List

end


----------------------------------------------------------------
-- GET ROUTE ZONES
--
-- Mode:
-- FIXED
-- RANDOM
--
-- Count:
-- nil = all available
----------------------------------------------------------------

function HeliOps.Nav:GetRoute(
    Area,
    Mode,
    Count
)

    local zones =
        self:GetZones(Area)


    if #zones == 0 then

        env.error(
            "HELIOPS NAV: No NAV zones available"
        )

        return {}
    end


    ------------------------------------------------------------
    -- Randomize
    ------------------------------------------------------------

    if Mode == "RANDOM" then

        self:Shuffle(zones)

    end


    ------------------------------------------------------------
    -- Determine number
    ------------------------------------------------------------

    local useCount

    if Count == nil then

        useCount = #zones

    else

        useCount =
            math.min(
                Count,
                #zones
            )

    end


    ------------------------------------------------------------
    -- Create output
    ------------------------------------------------------------

    local selected = {}

    for i = 1, useCount do

        table.insert(
            selected,
            zones[i]
        )

    end


    return selected

end


env.info("=== HELIOPS NAV READY ===")