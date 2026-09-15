-- Localized presentation helpers for player-scoped world discovery data.

PNC = PNC or {}
PNC.WorldDiscoveryPresentation = PNC.WorldDiscoveryPresentation or {}

local Presentation = PNC.WorldDiscoveryPresentation

local PHASE_KEYS = {
    UNKNOWN = { "UI_PNC_Discovery_PhaseUnknown", "Unknown" },
    RUMORED = { "UI_PNC_Discovery_PhaseRumored", "Rumored" },
    LOCATED = { "UI_PNC_Discovery_PhaseLocated", "Located" },
    CONTACTED = { "UI_PNC_Discovery_PhaseContacted", "Contacted" },
}

local KIND_KEYS = {
    settlement = { "UI_PNC_Discovery_KindSettlement", "Settlement" },
    mobile_group = { "UI_PNC_Discovery_KindMobileGroup", "Mobile group" },
}

local NAME_KEYS = {
    ["Unknown signal"] = "UI_PNC_UnknownSignal",
    ["Unknown settlement"] = "UI_PNC_Discovery_UnknownSettlement",
    ["Unknown mobile signal"] = "UI_PNC_UnknownSignal",
}

local function translate(key, fallback)
    local translation = PNC.Translation
    if translation and type(translation.GetKey) == "function" then
        return translation.GetKey(key, fallback)
    end
    return fallback or key or ""
end

local function format(key, fallback, ...)
    local translation = PNC.Translation
    if translation and type(translation.TrFormat) == "function" then
        return translation.TrFormat(key, fallback, ...)
    end
    local value = translate(key, fallback)
    local args = { ... }
    value = string.gsub(value, "%%(%d+)", function(index)
        local replacement = args[tonumber(index)]
        return replacement ~= nil and tostring(replacement)
            or "%%" .. index
    end)
    return value
end

local function mapped(value, mappings, fallbackKey, fallback)
    local entry = mappings[tostring(value or "")]
    if entry then return translate(entry[1], entry[2]) end
    return translate(fallbackKey, fallback)
end

function Presentation.Phase(value)
    return mapped(value, PHASE_KEYS,
        "UI_PNC_Discovery_PhaseUnknown", "Unknown")
end

function Presentation.Kind(value)
    return mapped(value, KIND_KEYS,
        "UI_PNC_Discovery_KindContact", "Contact")
end

function Presentation.SignalName(entity)
    entity = type(entity) == "table" and entity or {}
    local nameKey = entity.nameKey
    local name = entity.name
    if nameKey and tostring(nameKey) ~= "" then
        return translate(nameKey, name)
    end
    name = tostring(name or "")
    local fallbackKey = NAME_KEYS[name]
    if fallbackKey then return translate(fallbackKey, name) end
    if name ~= "" then return name end
    return translate("UI_PNC_UnknownSignal", "Unknown signal")
end

function Presentation.Faction(entity)
    entity = type(entity) == "table" and entity or {}
    if entity.factionKnown == true and entity.factionName
        and tostring(entity.factionName) ~= ""
    then
        return format("UI_PNC_Discovery_Faction", "Faction: %1",
            tostring(entity.factionName))
    end
    return translate("UI_PNC_Discovery_FactionNotDisclosed",
        "Faction not disclosed")
end

function Presentation.SignalKind(entity)
    entity = type(entity) == "table" and entity or {}
    if entity.kind == "settlement" then
        return translate("UI_PNC_Discovery_SettlementSignal",
            "Settlement signal")
    end
    return translate("UI_PNC_Discovery_MobileGroupSignal",
        "Mobile group signal")
end

function Presentation.Population(value)
    return format("UI_PNC_Discovery_Population", "Population: %1", value)
end

function Presentation.ApproximatePosition()
    return translate("UI_PNC_Discovery_ApproximatePosition",
        "Position is approximate; scan again to locate.")
end

return Presentation
