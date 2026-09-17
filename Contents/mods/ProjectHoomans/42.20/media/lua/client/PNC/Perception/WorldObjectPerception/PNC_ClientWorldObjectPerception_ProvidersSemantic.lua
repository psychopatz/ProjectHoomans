-- Semantic-name provider for client world-object perception.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and PsychopatzCore.RuntimeRole.AllowsClientCode
    and not PsychopatzCore.RuntimeRole.AllowsClientCode()
then return end

local Perception = PNC.Perception.WorldObjects
local Internal = Perception.Internal
local Catalog = Internal.Catalog

local function addUnique(values, value, normalizer)
    return Internal.AddUnique(values, value, normalizer)
end

local function semanticProvider(object, square, record)
    local metadata = record and record.metadata or {}
    local kinds = {}
    local names = {}
    local labels = {}
    for _, profile in ipairs(Catalog.List()) do
        local ok, matched = pcall(Catalog.Matches, profile.kind, metadata)
        if ok and matched == true then
            addUnique(kinds, profile.kind)
            addUnique(labels, profile.label)
            addUnique(names, profile.commandName or profile.label)
        end
    end
    if #kinds == 0 then return nil end
    return {
        semanticKinds = kinds,
        semanticNames = names,
        semanticLabels = labels,
        semanticName = names[1],
        commandName = names[1],
    }
end

local function semanticCandidate(object, square, metadata)
    metadata = type(metadata) == "table" and metadata or {}
    for _, profile in ipairs(Catalog.List()) do
        local ok, matched = pcall(Catalog.Matches, profile.kind, metadata)
        if ok and matched == true then return true end
    end
    return false
end

Perception.RegisterProvider("semantic", {
    order = 10,
    labelKey = "UI_PNC_PerceptionDebug_ProviderSemantic",
    candidate = semanticCandidate,
    describe = semanticProvider,
})

return Perception
