----------------------------------------------------------------
-- HELIOPS NAVIGATION
-- Cyprus navigation zone database
----------------------------------------------------------------

env.info("=== HELIOPS NAV START ===")

HeliOps = HeliOps or {}
HeliOps.Nav = HeliOps.Nav or {}

local Zones =
    HeliOps.ME.Assets.Zones

----------------------------------------------------------------
-- CYPRUS NAVIGATION ZONES
----------------------------------------------------------------

HeliOps.Nav.Cyprus = {

    Zones.NavCyp01.Name,
    Zones.NavCyp02.Name,
    Zones.NavCyp03.Name,
    Zones.NavCyp04.Name,
    Zones.NavCyp05.Name,
    Zones.NavCyp06.Name,
    Zones.NavCyp07.Name,
    Zones.NavCyp08.Name,
    Zones.NavCyp09.Name,
    Zones.NavCyp10.Name,
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

    if Mode == "RANDOM" then
        self:Shuffle(zones)
    end

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
