-- Context and router lifecycle for the hybrid semantic dialogue input.
-- This spoke owns conversation-local semantic state, not presentation or
-- gameplay effects.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input

local Internal = Input.Internal or {}
Input.Internal = Internal

local Semantic = PsychopatzCore.Semantics
local DialogueRouter = Semantic.DialogueRouter
local State = Semantic.DialogueState
local DialogueContextState = PNC.Semantics.DialogueContextState
if type(DialogueContextState) ~= "table" then
    local loaded = require
        "PNC/Semantics/PNC_SemanticDialogueContextState"
    DialogueContextState = type(loaded) == "table" and loaded or nil
end
local Policy = PNC.Semantics.DialoguePolicy
local Topics = PNC.Semantics.TopicCatalog
if type(Topics) ~= "table" then
    local loaded = require "PNC/Semantics/PNC_SemanticTopicCatalog"
    Topics = type(loaded) == "table" and loaded or nil
end
local WorldContext = PNC.Semantics.WorldContext
if type(WorldContext) ~= "table" then
    local loaded = require "PNC/Semantics/PNC_SemanticWorldContext"
    WorldContext = type(loaded) == "table" and loaded or nil
end
local ReferenceResolver = PNC.Semantics.DialogueReferenceResolver
if type(ReferenceResolver) ~= "table" then
    local loaded = require
        "PNC/Semantics/PNC_SemanticDialogueReferenceResolver"
    ReferenceResolver = type(loaded) == "table" and loaded or nil
end
local EntityResolver = PNC.Semantics.EntityResolver
if type(EntityResolver) ~= "table" then
    local loaded = require "PNC/Semantics/PNC_SemanticEntityResolver"
    EntityResolver = type(loaded) == "table" and loaded or nil
end
local FactResolver = PNC.Semantics.DialogueFacts
if type(FactResolver) ~= "table" then
    local loaded = require "PNC/Semantics/PNC_SemanticDialogueFacts"
    FactResolver = type(loaded) == "table" and loaded or nil
end
local Situation = PNC.Semantics.DialogueSituation
if type(Situation) ~= "table" then
    local loaded = require "PNC/Semantics/PNC_SemanticDialogueSituation"
    Situation = type(loaded) == "table" and loaded or nil
end
pcall(require, "PNC/Semantics/PNC_SemanticDialogueFactSources")

Internal.Policy = Policy

function Internal.Parse(value, options)
    local parser = Semantic.Parser and Semantic.Parser.Parse
    if type(parser) ~= "function" then return nil, "parser_unavailable" end
    local ir, reason = parser(value, options)
    if ir and Topics and type(Topics.Annotate) == "function" then
        Topics.Annotate(ir, value)
    end
    return ir, reason
end

function Internal.ResolveReferences(ir, state, context, options)
    local output = ir
    if ReferenceResolver
        and type(ReferenceResolver.Resolve) == "function"
    then
        output = ReferenceResolver.Resolve(ir, state, context, options)
    end
    if FactResolver and type(FactResolver.Annotate) == "function" then
        output = FactResolver.Annotate(output, state, context, options)
    end
    return output
end

local function addEntityCandidate(candidates, seen, candidate)
    if type(candidate) ~= "table" then return end
    local id = candidate.id or candidate.entityID or candidate.npcID
        or candidate.uuid
    id = tostring(id or "")
    if id == "" or seen[id] then return end
    seen[id] = true
    candidates[#candidates + 1] = candidate
end

local function semanticEntityCandidates(view, source)
    local candidates = {}
    local seen = {}
    local explicit = source and (
        source.semanticEntityCandidates or source.semanticEntities
    ) or nil
    if type(explicit) == "table" then
        for index = 1, #explicit do
            addEntityCandidate(candidates, seen, explicit[index])
        end
    end

    local npcID = view and view.spec and view.spec.npcID
        or source and source.npcID
    if source and source.identityState == "known" and npcID then
        addEntityCandidate(candidates, seen, {
            id = npcID,
            entityType = "npc",
            name = source.npcFullName or source.npcName,
            aliases = {
                source.npcName,
                source.npcFirstName,
                source.npcFullName,
            },
            source = "conversation_npc",
        })
    end

    local playerID = view and view.session and view.session.characterUUID
        or source and source.characterUUID
    if source and source.playerNameKnown == true and playerID
        and tostring(playerID) ~= ""
        and tostring(playerID) ~= "unbound"
    then
        addEntityCandidate(candidates, seen, {
            id = "player:" .. tostring(playerID),
            entityType = "player",
            name = source.playerFullName or source.playerName,
            aliases = {
                source.playerName,
                source.playerFirstName,
                source.playerFullName,
            },
            source = "conversation_player",
        })
    end

    -- Known snapshots are optional ambient candidates. The identity gateway
    -- is consulted before a snapshot name is exposed to semantic matching.
    local clientState = PNC.Network and PNC.Network.ClientState or nil
    local snapshots = clientState and clientState.snapshots or nil
    local presentations = clientState and clientState.npcPresentations or nil
    local identity = PNC.NPCIdentityPresentation
    local snapshotCount = 0
    if type(snapshots) == "table" then
        for id, snapshot in pairs(snapshots) do
            if snapshotCount < 64 and type(snapshot) == "table" then
                local presentation = presentations and presentations[id] or nil
                local known = presentation
                    and presentation.state == "known"
                local name = presentation and presentation.displayName
                    or snapshot.displayName or snapshot.name
                if not known and identity
                    and type(identity.IsNameKnown) == "function"
                then
                    local ok, result = pcall(identity.IsNameKnown, snapshot)
                    known = ok and result == true
                end
                if known and identity
                    and type(identity.GetName) == "function"
                then
                    local ok, result = pcall(identity.GetName, snapshot)
                    if ok and result then name = result end
                end
                if known and name and tostring(name) ~= "" then
                    addEntityCandidate(candidates, seen, {
                        id = id,
                        entityType = "npc",
                        name = name,
                        aliases = { name },
                        source = "known_snapshot",
                    })
                    snapshotCount = snapshotCount + 1
                end
            end
        end
    end
    return candidates
end

local function localPlayer(view, source)
    return source and source.player
        or view and view.spec and view.spec.context
        and view.spec.context.player
        or getSpecificPlayer and getSpecificPlayer(0)
end

function Internal.Now()
    return getTimeInMillis and getTimeInMillis()
        or getTimestampMs and getTimestampMs() or 0
end

function Internal.LLMEnabled()
    local integration = PNC.HoomansLLM
    if integration
        and type(integration.IsProviderAvailable) == "function"
    then
        return integration.IsProviderAvailable() == true
    end
    return integration
        and type(integration.IsBridgeEnabled) == "function"
        and integration.IsBridgeEnabled() == true
end

function Internal.ProviderStatus()
    local integration = PNC.HoomansLLM
    if integration and type(integration.GetProviderStatus) == "function" then
        local ok, status = pcall(integration.GetProviderStatus)
        if ok and type(status) == "table" then return status end
    end
    return {
        ready = Internal.LLMEnabled(),
        status = Internal.LLMEnabled() and "ready" or "unavailable",
    }
end

function Internal.ShallowContext(view)
    local source = view and view.spec and view.spec.context or {}
    local output = {}
    local key
    local value
    for key, value in pairs(source) do output[key] = value end
    local providerStatus = Internal.ProviderStatus()
    output.llmEnabled = providerStatus.ready == true
    output.llmAvailable = output.llmEnabled
    output.llmProviderStatus = providerStatus.status
    output.llmProviderReason = providerStatus.reason
    output.npcID = view and view.spec and view.spec.npcID or output.npcID
    output.authoredTopic = source.conversationTopic
        or source.conversationBlockContext
        and source.conversationBlockContext.conversationTopic
    local session = view and view.session or nil
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
            semanticEntityCandidates(view, source)
        )
    end
    return output
end

-- A missing NPC fact should not block the current local response.  Ask the
-- authoritative server for the narrow fact in the background so a later turn
-- can use it without sending the whole NPC mind to the client.
function Internal.RequestCognitionForIR(view, ir)
    local subject
    local fact
    local target
    local targetID
    local lifecycle
    local context
    local request
    if type(ir) ~= "table"
        or ir.intent ~= "QUESTION"
    then
        return false, "not_a_fact_question"
    end
    subject = tostring(ir.subject or "")
    if subject == ""
        or subject == "TIME"
        or subject == "DATE"
        or subject == "WEATHER"
        or subject == "IDENTITY"
    then
        return false, "local_world_fact"
    end
    fact = ir.extensions and ir.extensions.facts
        and ir.extensions.facts[subject] or nil
    if type(fact) == "table" and fact.status == "known" then
        return false, "fact_already_known"
    end
    target = ir.target
    if type(target) ~= "table" or target.unresolved == true then
        return false, "target_unresolved"
    end
    targetID = target.id or target.entityID or target.npcID
    if tostring(targetID or "") == "" then
        return false, "target_id_unavailable"
    end
    context = view and view.spec and view.spec.context or {}
    lifecycle = context and context.conversationLifecycleState or nil
    request = PNC.Client and PNC.Client.RequestSemanticCognition
    if type(request) ~= "function" then
        return false, "cognition_request_unavailable"
    end
    return request(
        view and view.spec and view.spec.npcID,
        {
            subject = subject,
            targetID = targetID,
            conversationToken = lifecycle and lifecycle.token,
        }
    )
end

function Internal.Interactive(view)
    local session = view and view.session
    if not view or not session then return false end
    if view.closed == true or view.closing == true
        or view.editMode == true
    then
        return false
    end

    -- The semantic input is a live conversation channel, not a choice
    -- button.  A queued NPC line makes Session.busy true while it is being
    -- typed/released, but it must not prevent the player from sending the
    -- next turn.  Keep the legacy host callback as a fallback for custom
    -- conversation hosts that do not expose the view animation state.
    if view.headless == true then
        return view.lifecycleFinished ~= true
    end
    if view.animationInteractive ~= nil then
        return view.animationInteractive == true
    end
    return type(view.isConversationInteractive) == "function"
        and view:isConversationInteractive() == true
end

function Internal.RecordContextTurn(view, ir, options)
    local session = view and view.session
    local context = session and session.semanticDialogueContext or nil
    if not context or type(context.RecordTurn) ~= "function" then
        return false, "context_state_unavailable"
    end
    options = type(options) == "table" and options or {}
    local recordOptions = {
        timestamp = options.timestamp,
        speaker = options.speaker or "player",
        source = options.source or "player_input",
        mentions = options.mentions,
    }
    return context:RecordTurn(ir, recordOptions)
end

function Internal.RouterFor(view)
    local session = view and view.session
    if not session then return nil, "conversation_unavailable" end
    if not session.semanticDialogueState then
        local participants = {}
        local source = view.spec and view.spec.context or {}
        local initialTopic = source.conversationTopic
            or source.conversationBlockContext
            and source.conversationBlockContext.conversationTopic
        local groupParticipants = source.semanticGroupParticipants
        if type(groupParticipants) == "table" then
            for index = 1, #groupParticipants do
                participants[#participants + 1] = groupParticipants[index]
            end
        elseif view.spec and view.spec.npcID then
            participants[#participants + 1] = view.spec.npcID
        end
        if session.characterUUID then
            participants[#participants + 1] = session.characterUUID
        end
        session.semanticDialogueState = State.New({
            participants = participants,
            currentTopic = initialTopic,
            maxEvents = 12,
            maxParticipants = math.max(8, #participants),
        })
    end
    if not session.semanticDialogueContext
        and DialogueContextState
        and type(DialogueContextState.New) == "function"
    then
        session.semanticDialogueContext = DialogueContextState.New({
            currentTopic = initialTopic,
            maxTurns = 12,
            maxMentions = 32,
            maxFocus = 8,
        })
    end
    if not session.semanticDialogueRouter then
        session.semanticDialogueRouter = DialogueRouter.New({
            state = session.semanticDialogueState,
            policy = Policy,
            parser = Internal.Parse,
            contextResolver = Internal.ResolveReferences,
            context = Internal.ShallowContext(view),
        })
    else
        if type(session.semanticDialogueRouter.SetParser) == "function" then
            session.semanticDialogueRouter:SetParser(Internal.Parse)
        else
            session.semanticDialogueRouter.parser = Internal.Parse
        end
        if type(session.semanticDialogueRouter.SetContextResolver) == "function" then
            session.semanticDialogueRouter:SetContextResolver(
                Internal.ResolveReferences
            )
        else
            session.semanticDialogueRouter.contextResolver =
                Internal.ResolveReferences
        end
        session.semanticDialogueRouter:SetContext(Internal.ShallowContext(view))
        session.semanticDialogueRouter:SetPolicy(Policy)
    end
    return session.semanticDialogueRouter
end

return Input
