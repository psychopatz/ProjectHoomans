-- Campfire-zone provider for client world-object perception.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and PsychopatzCore.RuntimeRole.AllowsClientCode
    and not PsychopatzCore.RuntimeRole.AllowsClientCode()
then return end

local Perception = PNC.Perception.WorldObjects
local Internal = Perception.Internal

local function number(value)
    return Internal.Number(value)
end

local function campfireProvider(object, square, record)
    local metadata = record and record.metadata or {}
    if metadata.special ~= "campfire" then return nil end
    return {
        isCampfire = true,
        validCampZone = true,
        campZoneKind = "campfire",
        campfireRadius = Perception.CAMPFIRE_RADIUS,
        usage = { "Campfire" },
        capabilities = { "camp" },
        jobs = { "camp" },
    }
end

Perception.RegisterProvider("campfire", {
    order = 60,
    labelKey = "UI_PNC_PerceptionDebug_ProviderCampfire",
    describe = campfireProvider,
})

return Perception
