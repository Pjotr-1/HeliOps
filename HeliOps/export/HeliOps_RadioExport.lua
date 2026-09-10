----------------------------------------------------------------
-- HELIOPS RADIO EXPORT
----------------------------------------------------------------

local lfs = require("lfs")
local socket = require("socket")

local radioDevicesPath =
    lfs.writedir()
    .. [[Missions\HeliOps\framework\HeliOps_RadioDevices.lua]]

local okDevices, devicesErr = pcall(dofile, radioDevicesPath)
if not okDevices then
    log.write(
        "HeliOps-Radio",
        log.ERROR,
        "Cannot load HeliOps_RadioDevices.lua: " .. tostring(devicesErr)
    )
    return
end

local HRO = {
    HOST = "127.0.0.1",
    PORT = 9088,
    INTERVAL = 0.20,
}

HRO.socket = socket.udp()

local previousAfterNextFrame = LuaExportAfterNextFrame
local nextUpdate = 0

local function round(number, step)
    if not number then return nil end
    step = step or 1
    return math.floor((number + step / 2) / step) * step
end

local function getExportTime()
    local ok, value = pcall(LoGetModelTime)
    if ok and type(value) == "number" then
        return value
    end
    return nil
end

local function getRadioSelected(Config)
    if not Config
    or not Config.SelectorArgument
    or Config.SelectorPosition == nil then
        return true
    end

    local device0 = GetDevice(0)
    if not device0 then return false end

    local value =
        tonumber(
            device0:get_argument_value(Config.SelectorArgument)
        )

    if value == nil then return false end

    local step = Config.SelectorStep or 0.1
    local position =
        math.floor(math.abs(value / step) + 0.5)

    return position == Config.SelectorPosition
end

local function readRadio(AircraftType, RadioKey)
    if not HeliOps
    or not HeliOps.RadioDevices
    or not HeliOps.RadioDevices.Get then
        return nil
    end

    local config =
        HeliOps.RadioDevices:Get(AircraftType, RadioKey)

    if not config then return nil end

    local radio = GetDevice(config.DeviceID)
    if not radio then return nil end

    local frequency = nil
    local modulation = 0

    local okFreq, freq =
        pcall(function()
            return radio:get_frequency()
        end)

    if okFreq and freq then
        frequency = round(freq, 5000)
    end

    local okMod, mod =
        pcall(function()
            return radio:get_modulation()
        end)

    if okMod and mod ~= nil then
        modulation = mod
    end

    if not frequency or frequency <= 1 then
        return nil
    end

    return {
        frequency = frequency,
        modulation = modulation,
        selected = getRadioSelected(config),
    }
end

local function getCurrentRadioState()
    local selfData = LoGetSelfData()

    if not selfData or not selfData.Name then
        return nil
    end

    if selfData.Name == "OH58D" then
        local radio = readRadio("OH58D", "UHF")
        if not radio then return nil end

        return {
            aircraft = "OH58D",
            radio = "UHF",
            frequency = radio.frequency,
            modulation = radio.modulation,
            selected = radio.selected,
        }
    end

    return nil
end

local function sendRadioState()
    local state = getCurrentRadioState()
    if not state then return end

    local message =
        string.format(
            "%s|%s|%d|%d|%d",
            state.aircraft,
            state.radio,
            state.frequency,
            state.modulation,
            state.selected and 1 or 0
        )

    HRO.socket:sendto(message, HRO.HOST, HRO.PORT)
end

----------------------------------------------------------------
-- IMPORTANT:
-- HeliOps does NOT use LuaExportActivityNextEvent.
-- That callback is left completely untouched.
----------------------------------------------------------------

LuaExportAfterNextFrame =
function()

    if previousAfterNextFrame then
        local ok, err = pcall(previousAfterNextFrame)

        if not ok then
            log.write(
                "HeliOps-Radio",
                log.ERROR,
                "Previous LuaExportAfterNextFrame failed: "
                .. tostring(err)
            )
        end
    end

    local now = getExportTime()
    if not now then return end

    if now < nextUpdate then
        return
    end

    nextUpdate = now + HRO.INTERVAL

    local ok, err = pcall(sendRadioState)

    if not ok then
        log.write(
            "HeliOps-Radio",
            log.ERROR,
            "sendRadioState failed: " .. tostring(err)
        )
    end
end

log.write(
    "HeliOps-Radio",
    log.INFO,
    "HeliOps radio export loaded via LuaExportAfterNextFrame"
)
