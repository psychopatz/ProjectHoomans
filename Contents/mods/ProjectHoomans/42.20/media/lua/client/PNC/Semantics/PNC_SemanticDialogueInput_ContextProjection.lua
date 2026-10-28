-- Build a bounded, read-only context snapshot for semantic routing.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Projection = {}
local EntityCandidates = require
    "PNC/Semantics/PNC_SemanticDialogueInput_EntityCandidates"
local ActorConversationContext = PNC.Semantics.ActorConversationContext
    or require "PNC/Semantics/PNC_ActorConversationContext"
local LocationObservation = PNC.Semantics.LocationObservation
    or require "PNC/Semantics/PNC_SemanticLocationObservation"

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

local function boundedPlayerTraits(player)
    local output = {}
    local seen = {}
    local function add(value)
        value = tostring(value or "")
        if value == "" or seen[value] or #output >= 32 then return end
        seen[value] = true
        output[#output + 1] = value
    end

    if type(player) == "table" then
        local values = player.traits or player.socialTraits
        if type(values) == "table" then
            for key, value in pairs(values) do
                if type(key) == "string" and value == true then
                    add(key)
                elseif type(value) == "string" then
                    add(value)
                elseif type(value) == "table" then
                    add(value.id or value.type or value.name)
                end
            end
        end
    end

    if player and type(player.getTraits) == "function" then
        local ok, values = pcall(player.getTraits, player)
        if ok and values then
            if type(values.size) == "function"
                and type(values.get) == "function"
            then
                local sizeOK, size = pcall(values.size, values)
                size = sizeOK and math.min(tonumber(size) or 0, 32) or 0
                for index = 0, size - 1 do
                    local getOK, value = pcall(values.get, values, index)
                    if getOK then add(value) end
                end
            elseif type(values) == "table" then
                for _, value in pairs(values) do add(value) end
            end
        end
    end

    table.sort(output)
    return output
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
    -- Older/native definition callers keep the semantic authority snapshot
    -- inside the authored composer context.  Promote the bounded projection
    -- at this boundary so capability eligibility does not depend on the
    -- authored menu's private nesting shape.
    local composerContext = type(source.conversationBlockContext) == "table"
        and source.conversationBlockContext or nil
    if output.actorAuthority == nil and composerContext then
        output.actorAuthority = composerContext.actorAuthority
    end
    if output.npcState == nil and composerContext then
        output.npcState = composerContext.npcState
    end
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
    local speechPresentation = PNC.SemanticSpeechPresentation
    if speechPresentation
        and type(speechPresentation.GetActiveMedicalSupplyRequest) == "function"
    then
        output.activeMedicalSupplyRequest =
            speechPresentation.GetActiveMedicalSupplyRequest(output.npcID)
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
        output.playerEntityKey = relationship.identityKey or output.playerEntityKey
        output.playerIdentitySeed = relationship.identityDiagnostics
            and relationship.identityDiagnostics.characterUUID or output.playerIdentitySeed
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
    local interactionLifecycle = session
        and session.semanticInteractionLifecycle
        or source.interactionLifecycle
    if type(interactionLifecycle) == "table" then
        -- This is the bounded semantic capsule delivered for this player.
        -- It intentionally contains no rendered NPC/player transcript text.
        output.interactionLifecycle = interactionLifecycle
        local thread = interactionLifecycle
        local beat = thread.activeBeat
        if beat and beat.topic then
            output.currentTopic = beat.topic
        elseif thread.topic and not output.currentTopic then
            output.currentTopic = thread.topic
        end
    end
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
    if type(interactionLifecycle) == "table" then
        local thread = interactionLifecycle
        local beat = thread.activeBeat
        if beat and beat.topic then
            output.currentTopic = beat.topic
        elseif thread.topic and not output.currentTopic then
            output.currentTopic = thread.topic
        end
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
    local enginePlayer = localPlayer(view, source)
    output.playerTraits = boundedPlayerTraits(enginePlayer)
    if WorldContext and type(WorldContext.Get) == "function" then
        output.worldContext = WorldContext.Get({
            player = enginePlayer,
        })
    end
    if LocationObservation
        and type(LocationObservation.Observe) == "function"
    then
        local locationObservation = LocationObservation.Observe({
            locationObservation = output.locationObservation,
            player = enginePlayer,
            origin = output.selectionOrigin or enginePlayer,
            selectionOrigin = output.selectionOrigin or enginePlayer,
            cell = output.cell,
            campSiteCandidates = output.campSiteCandidates,
            campfireCandidates = output.campfireCandidates,
        })
        if type(locationObservation) == "table" then
            output.locationObservation = locationObservation
            local candidates = locationObservation.campSiteCandidates
            if type(candidates) == "table" and #candidates > 0 then
                output.campSiteCandidates = candidates
            end
        end
    end
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
