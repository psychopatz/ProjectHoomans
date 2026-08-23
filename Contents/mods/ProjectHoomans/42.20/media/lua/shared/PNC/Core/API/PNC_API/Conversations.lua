PNC = PNC or {}
PNC.API = PNC.API or {}
PNC.API.Internal = PNC.API.Internal or {}

local API = PNC.API
local Internal = API.Internal
local Core = PNC.Core
local Types = PNC.Types
local Registry = PNC.Registry
local OrderSystem = PNC.OrderSystem
local Presence = PNC.Presence
local Equipment = PNC.Equipment
local Health = PNC.Health
local Inventory = PNC.Inventory
local Network = PNC.Network

-- Versioned cross-mod conversation registration API. Definitions are copied
-- and validated by the shared registry; callers never receive canonical data.
API.Conversations = API.Conversations or {}

function API.Conversations.GetVersion()
    return PNC.Conversation.Registry.API_VERSION
end

function API.Conversations.GetCapabilities()
    return {
        apiVersion = PNC.Conversation.Registry.API_VERSION,
        schemaVersion = PNC.Conversation.Registry.SCHEMA_VERSION,
        categories = true,
        weightedBlocks = true,
        weightedOutcomes = true,
        authoritativeEffects = true,
        modularJSONText = true,
        languageFallback = "EN",
        customConditions = true,
        customEffects = true,
        relationshipAxes = { "approval", "respect", "familiarity" },
        derivedAttitudes = { "ADMIRE", "PITY", "FEAR", "DESPISE" },
        repeatScopes = { "pair", "character", "npc", "world" },
        oncePerDayRepeat = true,
        giftFlow = true,
        recruitmentResolver = true,
        relationshipDeltaDebug = true,
        registryFingerprint = true,
        sandboxDebugger = true,
    }
end

function API.Conversations.RegisterCategory(id, definition)
    return PNC.Conversation.Registry.RegisterCategory(id, definition)
end

function API.Conversations.UnregisterCategory(id)
    return PNC.Conversation.Registry.UnregisterCategory(id)
end

function API.Conversations.GetCategory(id)
    return PNC.Conversation.Registry.GetCategory(id)
end

function API.Conversations.ListCategories(filters)
    return PNC.Conversation.Registry.ListCategories(filters)
end

function API.Conversations.RegisterBlock(id, definition)
    return PNC.Conversation.Registry.RegisterBlock(id, definition)
end

function API.Conversations.UnregisterBlock(id)
    return PNC.Conversation.Registry.UnregisterBlock(id)
end

function API.Conversations.GetBlock(id)
    return PNC.Conversation.Registry.GetBlock(id)
end

function API.Conversations.ListBlocks(filters)
    return PNC.Conversation.Registry.ListBlocks(filters)
end

function API.Conversations.ValidateBlock(idOrDefinition, definition)
    return PNC.Conversation.Registry.ValidateBlock(idOrDefinition, definition)
end

function API.Conversations.RegisterConditionHandler(id, handler)
    return PNC.Conversation.Registry.RegisterConditionHandler(id, handler)
end

function API.Conversations.UnregisterConditionHandler(id)
    return PNC.Conversation.Registry.UnregisterConditionHandler(id)
end

function API.Conversations.RegisterEffectHandler(id, handler)
    return PNC.Conversation.Registry.RegisterEffectHandler(id, handler)
end

function API.Conversations.UnregisterEffectHandler(id)
    return PNC.Conversation.Registry.UnregisterEffectHandler(id)
end

