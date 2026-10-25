-- Harness implementations of the production semantic/network boundaries.
-- Keep this path stable: SemanticAdapters requires it directly.

local Provider = {}

local configureContext = require "worker/SemanticAdapters_Core_Context"
local configureRelationships = require "worker/SemanticAdapters_Core_Relationships"
local configureKnowledge = require "worker/SemanticAdapters_Core_Knowledge"

function Provider.configure(context, SemanticAdapters)
    local Values = context.Values
    local conversationData = context.scenario.conversation or {}
    local Runtime = context.Runtime
    local state = {
        context = context,
        SemanticAdapters = SemanticAdapters,
        Runtime = Runtime,
        Values = Values,
        number = Values.number,
        playerData = context.playerData,
        npcData = context.npcData,
        runtime = context.runtime,
        player = context.player,
        conversationToken = tostring(conversationData.token or ""),
        sourceKind = Runtime.sourceMetadata
            and Runtime.sourceMetadata.sourceKind or "FIXTURE",
    }

    configureContext(state)
    configureRelationships(state)
    configureKnowledge(state)

    return {
        context = context,
        Runtime = Runtime,
        Values = Values,
        number = state.number,
        playerData = state.playerData,
        npcData = state.npcData,
        runtime = state.runtime,
        player = state.player,
        leaseDuration = state.leaseDuration,
        conversationToken = state.conversationToken,
        identityName = state.identityName,
        relationshipFor = state.relationshipFor,
        relationshipSnapshotFor = state.relationshipSnapshotFor,
    }
end

return Provider
