-- Build a bounded, read-only context snapshot for semantic routing.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Projection = {}
local EntityCandidates = require
    "PNC/Semantics/PNC_SemanticDialogueInput_EntityCandidates"
local ActorConversationContext = PNC.Semantics.ActorConversationContext
    or require "PNC/Semantics/PNC_ActorConversationContext"

local WorldContext
local EntityResolver
local Situation

function Projection.Configure(worldContext, entityResolver, situation)
    WorldContext = worldContext
    EntityResolver = entityResolver
    Situation = situation
end

local function localPlayer(view, source)
    return source and source.player
        or view and view.spec and view.spec.context
        and view.spec.context.player
        or getSpecificPlayer and getSpecificPlayer(0)
end

function Projection.LLMEnabled()
    local integration = PNC.PBrainZ
    if integration
        and type(integration.IsProviderAvailable) == "function"
    then
        return integration.IsProviderAvailable() == true
    end
    return integration
        and type(integration.IsBridgeEnabled) == "function"
        and integration.IsBridgeEnabled() == true
end

function Projection.ProviderStatus(isEnabled)
    local integration = PNC.PBrainZ
    if integration and type(integration.GetProviderStatus) == "function" then
        local ok, status = pcall(integration.GetProviderStatus)
        if ok and type(status) == "table" then return status end
    end
    isEnabled = type(isEnabled) == "function"
        and isEnabled or Projection.LLMEnabled
    return {
        ready = isEnabled(),
        status = isEnabled() and "ready" or "unavailable",
    }
end

function Projection.Build(view, getProviderStatus)
    local source = view and view.spec and view.spec.context or {}
    local output = {}
    local key
    local value
    for key, value in pairs(source) do output[key] = value end
    local providerStatus = getProviderStatus()
    output.llmEnabled = providerStatus.ready == true
    output.llmAvailable = output.llmEnabled
    output.llmProviderStatus = providerStatus.status
    output.llmProviderReason = providerStatus.reason
    output.npcID = view and view.spec and view.spec.npcID or output.npcID
    local clientState = PNC.Network and PNC.Network.ClientState or nil
    local presentation = clientState and clientState.npcPresentations
        and clientState.npcPresentations[tostring(output.npcID or "")]
        or nil
    if type(presentation) == "table"
        and (presentation.state == "known"
            or presentation.canAskName == false)
    then
        -- The presentation gateway is the player-scoped identity authority.
        -- Keep the semantic context aligned with it even when the NPC entry
        -- itself has no local identityState field.
        output.identityState = "known"
        output.identityKnown = true
    end
    local socialFlavor = PNC.SocialFlavorPresentation
    if socialFlavor
        and type(socialFlavor.GetActiveMedicalSupplyRequest) == "function"
    then
        output.activeMedicalSupplyRequest =
            socialFlavor.GetActiveMedicalSupplyRequest(output.npcID)
    end
    local relationship = PNC.Network and PNC.Network.ClientState
        and PNC.Network.ClientState.conversationRelationships
        and PNC.Network.ClientState.conversationRelationships[
            tostring(output.npcID or "")
        ] or nil
    if relationship then
        -- Relationship updates arrive after the conversation view is built.
        -- Prefer the authoritative client projection on every turn so a
        -- deception/evasion result affects the very next response.
        output.relationship = relationship
        output.identityTrust = relationship.identityTrust
            or relationship.trustLabel or output.identityTrust
        output.relationshipState = relationship.relationshipState
            or output.relationshipState
    end
    local knowledge = PNC.Network and PNC.Network.ClientState
        and PNC.Network.ClientState.npcKnowledge
        and PNC.Network.ClientState.npcKnowledge[tostring(output.npcID or "")]
        or nil
    if type(knowledge) == "table" then
        -- This is the already-filtered, player-specific dossier projection.
        -- Never replace it with the local NPC record or a generated profile.
        output.npcKnowledge = knowledge
    end
    output.authoredTopic = source.conversationTopic
        or source.conversationBlockContext
        and source.conversationBlockContext.conversationTopic
    local session = view and view.session or nil
    local memoryTargetID = session and session.semanticMemoryTargetID
        or source.semanticMemoryTargetID
    local cognitionClient = PNC.Semantics
        and PNC.Semantics.CognitionClient or nil
    if cognitionClient and type(cognitionClient.GetGossipContext) == "function" then
        output.npcGossip = cognitionClient.GetGossipContext(
            output.npcID,
            memoryTargetID
        )
    end
    local state = session and session.semanticDialogueState or nil
    if state and type(state.ToContext) == "function" then
        output.semanticDialogueState = state:ToContext()
        output.currentTopic = state.currentTopic or output.authoredTopic
    else
        output.currentTopic = output.authoredTopic
    end
    if session and session.semanticDialogueContext
        and type(session.semanticDialogueContext.ToContext) == "function"
    then
        -- Keep the live object private to the local resolver. The serialized
        -- projection is safe for diagnostics and future LLM context payloads.
        output.semanticContextState = session.semanticDialogueContext
        output.semanticDialogueContext =
            session.semanticDialogueContext:ToContext()
        output.currentTopic = session.semanticDialogueContext.currentTopic
            or output.currentTopic
    end
    local composer = PNC.Conversation and PNC.Conversation.Composer
    if composer and type(composer.BuildSemanticBlockProjection) == "function" then
        local blockProjection = composer.BuildSemanticBlockProjection(view)
        if blockProjection ~= nil then
            output.conversationBlock = blockProjection
        end
    end
    if composer and type(composer.BuildSemanticRootProjection) == "function" then
        local rootProjection = composer.BuildSemanticRootProjection(view)
        if rootProjection ~= nil then
            output.conversationRoot = rootProjection
        end
    end
    if WorldContext and type(WorldContext.Get) == "function" then
        output.worldContext = WorldContext.Get({
            player = localPlayer(view, source),
        })
    end
    local enginePlayer = localPlayer(view, source)
    local nativeKills
    if enginePlayer and type(enginePlayer.getZombieKills) == "function" then
        local ok, value = pcall(enginePlayer.getZombieKills, enginePlayer)
        if ok then nativeKills = tonumber(value) end
    end
    if nativeKills ~= nil then
        output.engineFacts = type(output.engineFacts) == "table"
            and output.engineFacts or {}
        output.engineFacts["player.stats.zombie_kills"] = nativeKills
    end
    if Situation and type(Situation.Build) == "function" then
        output.dialogueSituation = Situation.Build(output)
    end
    if EntityResolver and type(EntityResolver.BuildIndex) == "function" then
        output.semanticEntityIndex = EntityResolver.BuildIndex(
            EntityCandidates.Build(view, source)
        )
    end
    output.actorConversationContext = ActorConversationContext.Build(output)
    return output
end

return Projection
