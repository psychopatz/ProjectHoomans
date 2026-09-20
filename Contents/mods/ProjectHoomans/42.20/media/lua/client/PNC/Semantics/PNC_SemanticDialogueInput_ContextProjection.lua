-- Build a bounded, read-only context snapshot for semantic routing.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Projection = {}
local EntityCandidates = require
    "PNC/Semantics/PNC_SemanticDialogueInput_EntityCandidates"

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
    if WorldContext and type(WorldContext.Get) == "function" then
        output.worldContext = WorldContext.Get({
            player = localPlayer(view, source),
        })
    end
    if Situation and type(Situation.Build) == "function" then
        output.dialogueSituation = Situation.Build(output)
    end
    if EntityResolver and type(EntityResolver.BuildIndex) == "function" then
        output.semanticEntityIndex = EntityResolver.BuildIndex(
            EntityCandidates.Build(view, source)
        )
    end
    return output
end

return Projection
