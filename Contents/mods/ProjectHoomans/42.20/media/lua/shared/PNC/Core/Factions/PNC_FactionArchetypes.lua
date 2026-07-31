-- Immutable organizational classifications. Phase 5B gives archetypes a
-- narrow tactical policy; this does not simulate raids, trade, or settlements.

PNC = PNC or {}
PNC.FactionArchetypes = PNC.FactionArchetypes or {}

local Archetypes = PNC.FactionArchetypes

local DEFINITIONS = {
    settler = {
        id = "settler",
        label = "Settlement",
        description = "A permanent survivor organization attempting to maintain a defended home and stable population.",
        allowedRoles = {
            leader = true, guard = true, medic = true, farmer = true,
            builder = true, scavenger = true, cook = true,
            mechanic = true, civilian = true,
        },
        defaultRole = "civilian",
        behavior = {
            hostileToOutsiders = true,
            defaultLegacyFaction = "hostile",
        },
        policyDefaults = {
            aggression = 0.30,
            retaliation = 0.55,
            caution = 0.55,
            hospitality = 0.50,
            opportunism = 0.30,
            outsiderPolicy = "neutral",
            warThreshold = 70,
            peaceThreshold = 25,
        },
    },
    looter = {
        id = "looter",
        label = "Looter Gang",
        description = "A survivor organization that commonly relies on coercion, theft, tribute, or raids for resources.",
        allowedRoles = {
            leader = true, lieutenant = true, enforcer = true,
            raider = true, guard = true, scavenger = true,
            medic = true, civilian = true,
        },
        defaultRole = "civilian",
        behavior = {
            hostileToOutsiders = false,
            defaultLegacyFaction = "neutral",
        },
        policyDefaults = {
            aggression = 0.75,
            retaliation = 0.70,
            caution = 0.35,
            hospitality = 0.10,
            opportunism = 0.85,
            outsiderPolicy = "predatory",
            warThreshold = 58,
            peaceThreshold = 20,
        },
    },
    trader = {
        id = "trader",
        label = "Trading Company",
        description = "A survivor organization focused on exchange, transport, and commercial relationships.",
        allowedRoles = {
            leader = true, trader = true, guard = true, medic = true,
            mechanic = true, scavenger = true, laborer = true,
            civilian = true,
        },
        defaultRole = "civilian",
        behavior = {
            hostileToOutsiders = false,
            defaultLegacyFaction = "neutral",
        },
        policyDefaults = {
            aggression = 0.20,
            retaliation = 0.40,
            caution = 0.65,
            hospitality = 0.60,
            opportunism = 0.75,
            outsiderPolicy = "commercial",
            warThreshold = 76,
            peaceThreshold = 30,
        },
    },
    refugee = {
        id = "refugee",
        label = "Refugee Group",
        description = "A displaced survivor organization seeking safety, shelter, or a permanent home.",
        allowedRoles = {
            leader = true, guard = true, medic = true,
            scavenger = true, caregiver = true, civilian = true,
        },
        defaultRole = "civilian",
        behavior = {
            hostileToOutsiders = false,
            defaultLegacyFaction = "neutral",
        },
        policyDefaults = {
            aggression = 0.15,
            retaliation = 0.35,
            caution = 0.80,
            hospitality = 0.45,
            opportunism = 0.25,
            outsiderPolicy = "cautious",
            warThreshold = 80,
            peaceThreshold = 28,
        },
    },
}

local function copy(value)
    local output = {}
    if type(value) ~= "table" then return value end
    for key, item in pairs(value) do
        output[key] = type(item) == "table" and copy(item) or item
    end
    return output
end

function Archetypes.Get(archetypeID)
    local definition = type(archetypeID) == "string"
        and DEFINITIONS[archetypeID] or nil
    return definition and copy(definition) or nil
end

function Archetypes.Exists(archetypeID)
    return type(archetypeID) == "string"
        and DEFINITIONS[archetypeID] ~= nil
end

function Archetypes.List()
    local output = {}
    for id, definition in pairs(DEFINITIONS) do
        output[id] = copy(definition)
    end
    return output
end

function Archetypes.IsRoleAllowed(archetypeID, role)
    local definition = DEFINITIONS[archetypeID]
    return definition ~= nil
        and definition.allowedRoles[role] == true
end

function Archetypes.GetDefaultRole(archetypeID)
    local definition = DEFINITIONS[archetypeID]
    return definition and definition.defaultRole or "civilian"
end

function Archetypes.GetPolicyDefaults(archetypeID)
    local definition = DEFINITIONS[archetypeID]
    return definition and copy(definition.policyDefaults) or nil
end

function Archetypes.IsHostileToOutsiders(archetypeID)
    local definition = DEFINITIONS[archetypeID]
    return definition ~= nil
        and definition.behavior ~= nil
        and definition.behavior.hostileToOutsiders == true
end

return Archetypes
