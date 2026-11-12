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
    return PsychopatzCore.Conversation.Registry.API_VERSION
end

function API.Conversations.GetCapabilities()
    return {
        apiVersion = PsychopatzCore.Conversation.Registry.API_VERSION,
        schemaVersion = PsychopatzCore.Conversation.Registry.SCHEMA_VERSION,
        categories = true,
        weightedBlocks = true,
        weightedOutcomes = true,
        authoritativeEffects = true,
        modularJSONText = true,
        languageFallback = "EN",
        customConditions = true,
        categoryEligibilityProviders = true,
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
    return PsychopatzCore.Conversation.Registry.RegisterCategory(id, definition)
end

function API.Conversations.UnregisterCategory(id)
    return PsychopatzCore.Conversation.Registry.UnregisterCategory(id)
end

function API.Conversations.GetCategory(id)
    return PsychopatzCore.Conversation.Registry.GetCategory(id)
end

function API.Conversations.ListCategories(filters)
    return PsychopatzCore.Conversation.Registry.ListCategories(filters)
end

function API.Conversations.RegisterBlock(id, definition)
    return PsychopatzCore.Conversation.Registry.RegisterBlock(id, definition)
end

function API.Conversations.UnregisterBlock(id)
    return PsychopatzCore.Conversation.Registry.UnregisterBlock(id)
end

function API.Conversations.GetBlock(id)
    return PsychopatzCore.Conversation.Registry.GetBlock(id)
end

function API.Conversations.ListBlocks(filters)
    return PsychopatzCore.Conversation.Registry.ListBlocks(filters)
end

function API.Conversations.ValidateBlock(idOrDefinition, definition)
    return PsychopatzCore.Conversation.Registry.ValidateBlock(idOrDefinition, definition)
end

function API.Conversations.RegisterConditionHandler(id, handler)
    return PsychopatzCore.Conversation.Registry.RegisterConditionHandler(id, handler)
end

function API.Conversations.UnregisterConditionHandler(id)
    return PsychopatzCore.Conversation.Registry.UnregisterConditionHandler(id)
end

function API.Conversations.RegisterCategoryEligibilityProvider(id, provider)
    return PsychopatzCore.Conversation.Registry
        .RegisterCategoryEligibilityProvider(id, provider)
end

function API.Conversations.UnregisterCategoryEligibilityProvider(id)
    return PsychopatzCore.Conversation.Registry
        .UnregisterCategoryEligibilityProvider(id)
end

function API.Conversations.RegisterEffectHandler(id, handler)
    return PsychopatzCore.Conversation.Registry.RegisterEffectHandler(id, handler)
end

function API.Conversations.UnregisterEffectHandler(id)
    return PsychopatzCore.Conversation.Registry.UnregisterEffectHandler(id)
end
