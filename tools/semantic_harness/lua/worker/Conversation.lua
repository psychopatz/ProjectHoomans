-- Per-turn semantic context, view construction, and turn execution.

local Conversation = {}

local NEED_KEYS = { "hunger", "thirst", "fatigue" }
local CONDITION_KEYS = { "stress", "boredom", "panic" }

local function numbersFor(source, keys, number)
    local values = {}
    if type(source) ~= "table" then return values end
    for index = 1, #keys do
        local key = keys[index]
        local value = number(source[key], nil)
        if value ~= nil then values[key] = value end
    end
    return values
end

function Conversation.buildContext(context)
    local Runtime = context.Runtime
    local Values = context.Values
    local number = Values.number
    local copy = Values.copy
    local scenario = Runtime.scenario or {}
    local npc = scenario.npc or {}
    local world = scenario.world or {}
    local conversation = scenario.conversation or {}
    local player = scenario.player or {}
    local relationship = context.SemanticAdapters.relationshipFor(
        context, npc.npcID
    )
    local npcName = context.SemanticAdapters.identityName(context, npc)
    -- The world-level fields remain a legacy scenario fallback. An explicit
    -- npc.needs/conditionStats table is authoritative even when empty (unknown).
    local needSource = type(npc.needs) == "table" and npc.needs or world
    local conditionSource = type(npc.conditionStats) == "table"
        and npc.conditionStats or world
    local needs = numbersFor(needSource, NEED_KEYS, number)
    local conditions = numbersFor(conditionSource, CONDITION_KEYS, number)
    local bodyHealth = type(npc.bodyHealth) == "table"
        and copy(npc.bodyHealth) or nil
    local hpCurrent = number(npc.hpCurrent, nil)
    local hpMax = number(npc.hpMax, nil)
    local snapshotNeeds = copy(needs)
    -- Preserve the old snapshot.needs condition fields for worker consumers,
    -- while exposing conditionStats to the real production situation resolver.
    for index = 1, #CONDITION_KEYS do
        local key = CONDITION_KEYS[index]
        snapshotNeeds[key] = conditions[key]
    end
    return {
        identityState = npc.identityState or "unknown",
        npcName = npcName,
        npcFullName = npcName,
        npcFirstName = npc.forename,
        npcState = {
            traits = copy(npc.traits or {}),
            identityState = npc.identityState or "unknown",
            healthState = npc.healthState,
            activeBehavior = npc.activeBehavior,
            bodyHealth = bodyHealth,
            hpCurrent = hpCurrent,
            hpMax = hpMax,
            needs = copy(needs),
            conditionStats = copy(conditions),
        },
        relationshipState = relationship.relationshipState
            or npc.relationshipState or "unknown",
        identityTrust = relationship.identityTrust,
        relationship = copy(relationship),
        npcTraits = copy(npc.traits or {}),
        npcPersonality = copy(npc.personality or {}),
        semanticFactValues = copy(context.semanticFactValues or {}),
        player = nil,
        playerNameKnown = true,
        playerName = context.SemanticAdapters.playerName(context, player),
        characterUUID = player.characterUUID,
        conversationTopic = conversation.topic or "greeting",
        conversationLifecycleState = { token = conversation.token or "harness-lease" },
        semanticAuthorization = copy(
            conversation.semanticAuthorization
                or npc.semanticAuthorization
        ),
        entry = {
            snapshot = {
                activeBehavior = npc.activeBehavior,
                healthState = npc.healthState,
                bodyHealth = bodyHealth,
                hpCurrent = hpCurrent,
                hpMax = hpMax,
                needs = snapshotNeeds,
                conditionStats = copy(conditions),
            },
        },
    }
end

function Conversation.buildView(context)
    local Runtime = context.Runtime
    local Values = context.Values
    local scenario = Runtime.scenario or {}
    local npc = scenario.npc or {}
    local player = scenario.player or {}
    local session = {
        characterUUID = player.characterUUID,
        conversationID = "harness-conversation",
        append = function(self, speaker, value, metadata)
            local message = {
                speaker = speaker,
                value = value,
                metadata = Values.copy(metadata),
            }
            self.lastAppend = message
            Runtime.transcript[#Runtime.transcript + 1] = message
            if speaker == "npc" then
                Runtime.queued[#Runtime.queued + 1] = {
                    speaker = speaker,
                    payload = Values.copy(value),
                    metadata = Values.copy(metadata),
                }
            end
            return { messageID = "harness-message-" .. tostring(#Runtime.transcript) }
        end,
        queueMessage = function(self, speaker, payload, metadata)
            local message = {
                speaker = speaker,
                payload = Values.copy(payload),
                metadata = Values.copy(metadata),
            }
            self.lastQueued = message
            Runtime.queued[#Runtime.queued + 1] = message
            Runtime.transcript[#Runtime.transcript + 1] = message
        end,
    }
    return {
        headless = true,
        lifecycleFinished = false,
        spec = {
            npcID = npc.npcID,
            context = Conversation.buildContext(context),
        },
        session = session,
    }
end

function Conversation.relationshipSnapshot(context)
    local scenario = context.Runtime.scenario or {}
    local npc = scenario.npc or {}
    return context.SemanticAdapters.relationshipSnapshotFor(context, npc.npcID)
end

function Conversation.contextSnapshot(harnessContext, view)
    local Values = harnessContext.Values
    local session = view and view.session
    local dialogueContext = session and session.semanticDialogueContext
    local semanticState = session and session.semanticDialogueState
    local null = harnessContext.Protocol.NULL
    local worldContext = PNC.Semantics.WorldContext
        and PNC.Semantics.WorldContext.Get
        and PNC.Semantics.WorldContext.Get({ player = harnessContext.player })
        or nil
    local engineFacts = {}
    local factCatalog = harnessContext.EngineFacts
        and harnessContext.EngineFacts.List
        and harnessContext.EngineFacts.List() or {}
    local factIndex
    for factIndex = 1, #factCatalog do
        local factID = factCatalog[factIndex].id
        local record = harnessContext.EngineFacts.Resolve(factID, {
            worldContext = worldContext,
            semanticFactValues = harnessContext.semanticFactValues,
            engineFacts = harnessContext.engineFacts,
            player = harnessContext.player,
        })
        engineFacts[factID] = Values.copy(record)
    end
    return {
        dialogue = dialogueContext and dialogueContext.ToContext
            and dialogueContext:ToContext() or null,
        state = semanticState and semanticState.Snapshot
            and semanticState:Snapshot() or null,
        engineFacts = engineFacts,
        engineEvents = harnessContext.EngineEvents
            and harnessContext.EngineEvents.Recent
            and Values.copy(harnessContext.EngineEvents.Recent()) or {},
    }
end

function Conversation.turn(context, text)
    local Runtime = context.Runtime
    local Values = context.Values
    Runtime.turn = Runtime.turn + 1
    Runtime.now = Runtime.now + 1
    local view = Runtime.view
    local queuedBefore = #Runtime.queued
    local transcriptBefore = #Runtime.transcript
    local traceBefore = #Runtime.trace
    local transportBefore = #Runtime.transport
    local translationBefore = #Runtime.translationLookups
    local relationshipBefore = Conversation.relationshipSnapshot(context)
    local contextBefore = Conversation.contextSnapshot(context, view)
    local accepted, reason = PNC.Semantics.DialogueInput.Submit(view, text)
    local result = view.lastSemanticDialogueResult
    -- Inspect the exact situation built by the production input router, not
    -- a separately re-created approximation in the Python test harness.
    local router = view.session and view.session.semanticDialogueRouter
    local routedContext = router and router.context
    local routedSituation = routedContext and routedContext.dialogueSituation
    local newMessages = {}
    local newTrace = {}
    local newTransport = {}
    local newTranslations = {}
    local index
    for index = queuedBefore + 1, #Runtime.queued do
        newMessages[#newMessages + 1] = Values.copy(Runtime.queued[index])
    end
    for index = transcriptBefore + 1, #Runtime.transcript do
        -- Transcript includes player input and queued NPC lines; preserve both.
    end
    for index = traceBefore + 1, #Runtime.trace do
        newTrace[#newTrace + 1] = Values.copy(Runtime.trace[index])
    end
    for index = transportBefore + 1, #Runtime.transport do
        newTransport[#newTransport + 1] = Values.copy(Runtime.transport[index])
    end
    for index = translationBefore + 1, #Runtime.translationLookups do
        newTranslations[#newTranslations + 1] = Values.copy(Runtime.translationLookups[index])
    end
    local actionResult = view.lastSemanticActionResult
    local toolCalls = context.OutputProjection.normalizedToolCalls(
        context, newTrace, newTransport, result, actionResult
    )
    local response = {
        ok = true,
        type = "turn",
        input = text,
        accepted = accepted == true,
        reason = reason,
        result = result and {
            accepted = result.accepted == true,
            reason = result.reason,
            sequence = result.sequence,
            ir = Values.copy(result.ir),
            decision = Values.copy(result.decision),
            flow = Values.copy(result.flow),
            actionResult = Values.copy(actionResult),
            candidates = Values.copy(result.candidates),
            candidateDiagnostics = Values.copy(result.candidateDiagnostics),
        } or nil,
        messages = newMessages,
        trace = newTrace,
        transport = newTransport,
        toolCalls = toolCalls,
        translation = {
            language = context.Translations.currentLanguage(context),
            lookups = newTranslations,
        },
        relationshipBefore = relationshipBefore,
        relationshipAfter = Conversation.relationshipSnapshot(context),
        contextBefore = contextBefore,
        contextAfter = Conversation.contextSnapshot(context, view),
        routedSituation = Values.copy(routedSituation),
        llmCalls = Runtime.llmCalls,
        loadedModules = Runtime.loadedModules,
    }
    response.observation = context.OutputProjection.observation(context, response)
    return response
end

function Conversation.preview(context, text)
    local Runtime = context.Runtime
    local Values = context.Values
    local view = Runtime.view
    local Input = PNC.Semantics and PNC.Semantics.DialogueInput or nil
    local Internal = Input and Input.Internal or {}
    local router, routerReason
    if type(Internal.RouterFor) == "function" then
        router, routerReason = Internal.RouterFor(view)
    end
    if not router then
        return {
            ok = true,
            type = "preview",
            input = text,
            accepted = false,
            reason = routerReason or "conversation_unavailable",
            contextBefore = Conversation.contextSnapshot(context, view),
            contextAfter = Conversation.contextSnapshot(context, view),
            messages = {},
            trace = {},
            transport = {},
            toolCalls = {},
            llmCalls = Runtime.llmCalls,
        }
    end

    local value = tostring(text or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    value = string.sub(value, 1, Input.MAX_INPUT_LENGTH)
    local contextBefore = Conversation.contextSnapshot(context, view)
    local relationshipBefore = Conversation.relationshipSnapshot(context)
    local traceBefore = #Runtime.trace
    local transportBefore = #Runtime.transport
    local translationBefore = #Runtime.translationLookups
    local projection = type(Internal.ShallowContext) == "function"
        and Internal.ShallowContext(view) or {}
    local options = {
        timestamp = type(Internal.Now) == "function" and Internal.Now() or 0,
    }
    local result = router:Preview(value, projection, options)
    if result and result.accepted == true
        and result.ir and type(router.Decide) == "function"
    then
        -- Router:Preview intentionally does not commit a turn. Ask the same
        -- production policy for its pure flow preview so the lab can inspect
        -- generated gates/bindings without recording or dispatching anything.
        local decision = router:Decide(result.ir, projection, options)
        result.decision = decision
        result.flow = decision and decision.flow
    end
    local newTrace = {}
    local newTransport = {}
    local newTranslations = {}
    local index
    for index = traceBefore + 1, #Runtime.trace do
        newTrace[#newTrace + 1] = Values.copy(Runtime.trace[index])
    end
    for index = transportBefore + 1, #Runtime.transport do
        newTransport[#newTransport + 1] = Values.copy(Runtime.transport[index])
    end
    for index = translationBefore + 1, #Runtime.translationLookups do
        newTranslations[#newTranslations + 1] = Values.copy(Runtime.translationLookups[index])
    end
    local toolCalls = context.OutputProjection.normalizedToolCalls(
        context, newTrace, newTransport, result, nil
    )
    local response = {
        ok = true,
        type = "preview",
        input = value,
        accepted = result and result.accepted == true,
        reason = result and result.reason,
        result = result and {
            accepted = result.accepted == true,
            reason = result.reason,
            sequence = result.sequence,
            ir = Values.copy(result.ir),
            decision = Values.copy(result.decision),
            flow = Values.copy(result.flow),
            candidates = Values.copy(result.candidates),
            candidateDiagnostics = Values.copy(result.candidateDiagnostics),
        } or nil,
        messages = {},
        trace = newTrace,
        transport = newTransport,
        toolCalls = toolCalls,
        translation = {
            language = context.Translations.currentLanguage(context),
            lookups = newTranslations,
        },
        relationshipBefore = relationshipBefore,
        relationshipAfter = Conversation.relationshipSnapshot(context),
        contextBefore = contextBefore,
        contextAfter = Conversation.contextSnapshot(context, view),
        routedSituation = Values.copy(projection.dialogueSituation),
        llmCalls = Runtime.llmCalls,
        loadedModules = Runtime.loadedModules,
    }
    response.observation = context.OutputProjection.observation(context, response)
    return response
end

return Conversation
