HeliOps = HeliOps or {}
HeliOps.RadioDevices = HeliOps.RadioDevices or {}

HeliOps.RadioDevices.OH58D = {
    UHF = {
        DeviceID = 30,
        Name = "AN/ARC-164 UHF",
        SelectorArgument = 188,
        SelectorPosition = 3,
        SelectorStep = 0.1,
    },
}

function HeliOps.RadioDevices:Get(AircraftType, RadioKey)
    local aircraft = self[AircraftType]
    if not aircraft then return nil end
    return aircraft[RadioKey]
end
