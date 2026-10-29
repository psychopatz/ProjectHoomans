PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Language = PNC.Semantics.TacticalSpatialLanguage or {}
PNC.Semantics.TacticalSpatialLanguage = Language

Language.VERSION = 1

local Registry = require "PNC/Semantics/Generated/Conversation/Registry"

local function spatialRelation()
    if PsychopatzCore and PsychopatzCore.SpatialRelation then
        return PsychopatzCore.SpatialRelation
    end
    local ok, loaded = pcall(
        require, "PsychopatzCore/Spatial/PsychopatzSpatialRelation"
    )
    if ok and type(loaded) == "table" then return loaded end
    return nil
end

local TACTICAL_ROLES = {
    guard = true,
    raider = true,
    soldier = true,
    military = true,
    enforcer = true,
}

local TACTICAL_TRAITS = {
    pnc_veteran = true,
    pnc_disciplined_fighter = true,
}

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function traitSet(value)
    local output = {}
    if type(value) ~= "table" then return output end
    for key, item in pairs(value) do
        if type(key) == "string" and item == true then
            output[lower(key)] = true
        elseif type(item) == "string" then
            output[lower(item)] = true
        end
    end
    return output
end

local function roleFor(record)
    local affiliation = type(record) == "table"
        and type(record.affiliation) == "table"
        and record.affiliation or {}
    return lower(affiliation.role or affiliation.communityRole)
end

function Language.SelectMode(record, profile, spatial, options)
    spatial = type(spatial) == "table" and spatial or {}
    if not spatial.clockToken then return "omitted", "clock_unavailable" end
    options = type(options) == "table" and options or {}
    if options.forceMode == "clock" or options.forceMode == "coarse" then
        return options.forceMode, "explicit_policy"
    end

    local traits = traitSet(
        type(profile) == "table" and profile.traits
            or type(record) == "table" and (
                record.npcTraits or record.dynamicTraits
            ) or nil
    )
    for trait in pairs(TACTICAL_TRAITS) do
        if traits[trait] then return "clock", "tactical_trait:" .. trait end
    end

    local role = roleFor(record)
    if TACTICAL_ROLES[role] then
        return "clock", "tactical_role:" .. role
    end

    return "coarse", "civilian_fallback"
end

local function localizedPhrase(templateID)
    local family, phrases = Registry.FamilyFor(templateID, "neutral")
    local phrase = type(family) == "table"
        and type(phrases) == "table" and phrases[1] or nil
    if type(phrase) ~= "table" then
        return nil, "phrase_unavailable"
    end
    local key = tostring(phrase.key or "")
    local fallback = tostring(phrase.fallback or "")
    local translation = PNC.Translation
    if key ~= "" and translation
        and type(translation.GetKey) == "function"
    then
        return translation.GetKey(key, fallback), nil, key
    end
    return fallback, nil, key ~= "" and key or nil
end

local function replaceToken(text, token, value)
    return string.gsub(tostring(text or ""), token, function()
        return tostring(value or "")
    end)
end

local function familyFor(threatKind, mode)
    threatKind = lower(threatKind)
    local hostile = threatKind == "hostile"
        or threatKind == "human_hostile"
        or threatKind == "human_npc"
    local subject = hostile and "hostile" or "zombie"
    return "semantic.combat.tactical_spatial." .. subject .. "." .. mode
end

function Language.ComposePrefix(threatKind, spatial, mode)
    spatial = type(spatial) == "table" and spatial or {}
    mode = tostring(mode or spatial.presentationMode or "coarse")
    if mode ~= "clock" and mode ~= "coarse" then
        return nil, "presentation_omitted"
    end

    local templateID = familyFor(threatKind, mode)
    local text, reason, translationKey = localizedPhrase(templateID)
    if not text or text == "" then return nil, reason end

    local Relation = spatialRelation()
    if not Relation then return nil, "spatial_relation_unavailable" end

    if mode == "clock" then
        if not spatial.clockToken then return nil, "clock_unavailable" end
        local label = Relation.GetClockLabel(spatial.clockToken)
        if not label or label == "" then return nil, "clock_label_unavailable" end
        text = replaceToken(text, "{clock}", label)
    else
        if not spatial.relativeSector8 then
            return nil, "relative_sector_unavailable"
        end
        local label = Relation.GetRelativeSectorLabel(spatial.relativeSector8)
        if not label or label == "" then
            return nil, "relative_label_unavailable"
        end
        text = replaceToken(text, "{relative}", label)
    end

    return text, nil, {
        mode = mode,
        templateID = templateID,
        translationKey = translationKey,
        clockToken = spatial.clockToken,
        relativeSector8 = spatial.relativeSector8,
    }
end

function Language.Decorate(baseText, threatKind, spatial, mode)
    local prefix, reason, metadata = Language.ComposePrefix(
        threatKind, spatial, mode
    )
    if not prefix then return tostring(baseText or ""), reason end
    local base = tostring(baseText or "")
    if base == "" then return prefix, nil, metadata end
    return prefix .. " " .. base, nil, metadata
end

return Language
