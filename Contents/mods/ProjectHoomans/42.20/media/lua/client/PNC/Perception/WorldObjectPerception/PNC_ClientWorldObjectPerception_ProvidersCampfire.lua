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

local function campfireCandidate(object, square, metadata)
    if Internal.Call(object, "isCampfire") == true then return true end
    metadata = type(metadata) == "table" and metadata or {}
    local catalog = Internal.Catalog
    if not catalog or type(catalog.Matches) ~= "function" then
        return false
    end
    local ok, matched = pcall(catalog.Matches, "campfire", metadata)
    return ok and matched == true
end

Perception.RegisterProvider("campfire", {
    order = 60,
    labelKey = "UI_PNC_PerceptionDebug_ProviderCampfire",
    candidate = campfireCandidate,
    describe = campfireProvider,
})

return Perception
