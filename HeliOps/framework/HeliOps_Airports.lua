----------------------------------------------------------------
-- HELIOPS AIRPORTS
----------------------------------------------------------------

env.info("=== HELIOPS AIRPORTS START ===")

HeliOps = HeliOps or {}
HeliOps.Airports = HeliOps.Airports or {}

local Zones =
    HeliOps.ME.Assets.Zones

----------------------------------------------------------------
-- AKROTIRI
----------------------------------------------------------------

HeliOps.Airports.AKROTIRI = {

    Enabled = true,

    Airbase = AIRBASE.Syria.Akrotiri,
    RTB     = AIRBASE.Syria.Akrotiri,

    FlightControl = {
        Enabled = true,
        Frequency = 251.700,
        Modulation = radio.modulation.AM,
        SRSPath = "C:\\Program Files\\DCS-SimpleRadio-Standalone\\ExternalAudio",
        SRSPort = 5002,
        TaxiLimit = 2,
        LandingLimit = 5,
        LandingTakeoffLimit = 2,
        LandingInterval_s = 45,
        RadioOnlyIfPlayers = true,
        ShowHoldingPatterns = true,
    },

    Hold = {
        Zone = Zones.HoldAkrotiri.Name,
        Length_NM = 3,
        Heading_deg = nil,
        FL_Min = nil,
        FL_Max = nil,
        Priority = 10,
    },
}

----------------------------------------------------------------
-- PAPHOS
----------------------------------------------------------------

HeliOps.Airports.PAPHOS = {

    Enabled = true,

    Airbase = AIRBASE.Syria.Paphos,
    RTB     = AIRBASE.Syria.Paphos,

    FlightControl = {
        Enabled = true,
        Frequency = 251.800,
        Modulation = radio.modulation.AM,
        TaxiLimit = 1,
        RadioOnlyIfPlayers = true,
        ShowHoldingPatterns = true,
    },

    Hold = {
        Zone = Zones.HoldPaphos.Name,
        Length_NM = 5,
        Heading_deg = nil,
        FL_Min = nil,
        FL_Max = nil,
        Priority = 10,
    },
}

----------------------------------------------------------------
-- LARNACA
----------------------------------------------------------------

HeliOps.Airports.LARNACA = {

    Enabled = true,

    Airbase = AIRBASE.Syria.Larnaca,
    RTB     = AIRBASE.Syria.Larnaca,

    FlightControl = {
        Enabled = true,
        Frequency = 251.850,
        Modulation = radio.modulation.AM,
        TaxiLimit = 1,
        RadioOnlyIfPlayers = true,
        ShowHoldingPatterns = true,
    },

    Hold = {
        Zone = Zones.HoldLarnaca.Name,
        Length_NM = 5,
        Heading_deg = nil,
        FL_Min = nil,
        FL_Max = nil,
        Priority = 10,
    },
}

----------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------

function HeliOps.Airports:Get(AirportKey)
    return self[AirportKey]
end

function HeliOps.Airports:GetRTB(AirportKey)

    local airport =
        self:Get(AirportKey)

    if not airport then
        return nil
    end

    return airport.RTB
end

env.info("=== HELIOPS AIRPORTS READY ===")
