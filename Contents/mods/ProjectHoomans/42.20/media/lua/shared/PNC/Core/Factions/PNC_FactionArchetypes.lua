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
            leader = true, trader = true, guard = true, medic = true,
            farmer = true, builder = true, scavenger = true, cook = true,
            mechanic = true, civilian = true,
        },
        defaultRole = "civilian",
        behavior = {
            hostileToOutsiders = false,
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
        mobile = {
            enabled = false,
            roleOrder = {
                "leader", "trader", "guard", "medic", "farmer",
                "builder", "scavenger", "cook", "mechanic",
            },
            npcArchetype = "General",
            hostile = false,
        },
    },
    looter = {
        id = "looter",
        label = "Looter Settlement",
        description = "A territorial survivor settlement that commonly relies on coercion, theft, tribute, or raids for resources.",
        allowedRoles = {
            leader = true, lieutenant = true, enforcer = true,
            raider = true, guard = true, scavenger = true,
            medic = true, civilian = true,
        },
        defaultRole = "civilian",
        behavior = {
            hostileToOutsiders = false,
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
        mobile = {
            enabled = true,
            roleOrder = {
                "leader", "raider", "enforcer", "scavenger",
                "guard", "medic",
            },
            npcArchetype = "Scavenger",
            hostile = true,
        },
    },
    trader = {
        id = "trader",
        label = "Trading Caravan",
        description = "A mobile survivor caravan focused on exchange, transport, and commercial relationships while travelling between settlements.",
        allowedRoles = {
            leader = true, trader = true, guard = true, medic = true,
            mechanic = true, scavenger = true, laborer = true,
            civilian = true,
        },
        defaultRole = "civilian",
        behavior = {
            hostileToOutsiders = false,
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
        mobile = {
            enabled = true,
            roleOrder = {
                "leader", "trader", "guard", "medic",
                "mechanic", "scavenger", "laborer",
            },
            npcArchetype = "General",
            hostile = false,
        },
    },
    refugee = {
        id = "refugee",
        label = "Refugee Group",
        description = "A displaced survivor organization seeking safety, shelter, or a permanent home.",
        allowedRoles = {
            leader = true, trader = true, guard = true, medic = true,
            scavenger = true, caregiver = true, civilian = true,
        },
        defaultRole = "civilian",
        behavior = {
            hostileToOutsiders = false,
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
        mobile = {
            enabled = true,
            roleOrder = {
                "leader", "trader", "guard", "medic",
                "caregiver", "scavenger",
            },
            npcArchetype = "General",
            hostile = false,
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

local CUSTOM = {}
local MAX_CUSTOM = 32

local function validID(value)
    return type(value) == "string"
        and #value > 0 and #value <= 128
        and string.match(value, "^[%w_%-%.:]+$") ~= nil
end

local function normalizeMobile(value, allowedRoles, defaultRole)
    value = type(value) == "table" and value or {}
    local roleOrder = {}
    for index = 1, math.min(#(value.roleOrder or {}), 32) do
        local role = value.roleOrder[index]
        if type(role) == "string"
            and allowedRoles[role] == true
        then
            roleOrder[#roleOrder + 1] = role
        end
    end
    if #roleOrder == 0 and defaultRole then
        roleOrder[1] = defaultRole
    end
    return {
        enabled = value.enabled == true,
        roleOrder = roleOrder,
        npcArchetype = type(value.npcArchetype) == "string"
            and value.npcArchetype ~= "" and value.npcArchetype
            or "General",
        hostile = value.hostile == true,
    }
end

local function customCount()
    local count = 0
    for _ in pairs(CUSTOM) do count = count + 1 end
    return count
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

function Archetypes.SupportsMobile(archetypeID)
    local definition = DEFINITIONS[archetypeID]
    return definition ~= nil
        and definition.mobile ~= nil
        and definition.mobile.enabled == true
end

function Archetypes.GetMobileRoleOrder(archetypeID)
    local definition = DEFINITIONS[archetypeID]
    local mobile = definition and definition.mobile or nil
    return mobile and copy(mobile.roleOrder) or nil
end

function Archetypes.GetMobileNPCArchetype(archetypeID)
    local definition = DEFINITIONS[archetypeID]
    local mobile = definition and definition.mobile or nil
    return mobile and mobile.npcArchetype or nil
end

function Archetypes.IsMobileHostile(archetypeID)
    local definition = DEFINITIONS[archetypeID]
    local mobile = definition and definition.mobile or nil
    return mobile and mobile.hostile == true or false
end

function Archetypes.Register(archetypeID, definition)
    if not validID(archetypeID) then
        return false, "faction_archetype_id_invalid"
    end
    if DEFINITIONS[archetypeID] then
        return false, "faction_archetype_exists"
    end
    if customCount() >= MAX_CUSTOM then
        return false, "faction_archetype_capacity"
    end
    if type(definition) ~= "table"
        or type(definition.allowedRoles) ~= "table"
    then
        return false, "faction_archetype_definition_required"
    end

    local allowedRoles = {}
    for role, enabled in pairs(definition.allowedRoles) do
        if type(role) == "string" and enabled == true then
            allowedRoles[role] = true
        end
    end
    local defaultRole = definition.defaultRole
    if type(defaultRole) ~= "string"
        or not allowedRoles[defaultRole]
    then
        return false, "faction_archetype_default_role_invalid"
    end

    local policyDefaults = type(definition.policyDefaults) == "table"
        and copy(definition.policyDefaults) or {
            aggression = 0.5,
            retaliation = 0.5,
            caution = 0.5,
            hospitality = 0.5,
            opportunism = 0.5,
            outsiderPolicy = "neutral",
            warThreshold = 70,
            peaceThreshold = 25,
        }
    DEFINITIONS[archetypeID] = {
        id = archetypeID,
        label = tostring(definition.label or archetypeID),
        description = tostring(definition.description or ""),
        allowedRoles = allowedRoles,
        defaultRole = defaultRole,
        behavior = copy(definition.behavior or {
            hostileToOutsiders = false,
        }),
        policyDefaults = policyDefaults,
        mobile = normalizeMobile(
            definition.mobile,
            allowedRoles,
            defaultRole
        ),
    }
    CUSTOM[archetypeID] = true
    return true
end

function Archetypes.IsCustom(archetypeID)
    return CUSTOM[archetypeID] == true
end

function Archetypes.ResetCustomForTests()
    for archetypeID in pairs(CUSTOM) do
        DEFINITIONS[archetypeID] = nil
        CUSTOM[archetypeID] = nil
    end
end

function Archetypes.IsHostileToOutsiders(archetypeID)
    local definition = DEFINITIONS[archetypeID]
    return definition ~= nil
        and definition.behavior ~= nil
        and definition.behavior.hostileToOutsiders == true
end

return Archetypes
