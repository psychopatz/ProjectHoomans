-- Per-turn semantic context, view construction, and turn execution.

local Conversation = {}

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
    return {
        identityState = npc.identityState or "unknown",
        npcName = npcName,
        npcFullName = npcName,
        npcFirstName = npc.forename,
        npcState = {
            traits = copy(npc.traits or {}),
            identityState = npc.identityState or "unknown",
            needs = {
                hunger = number(world.hunger, 0),
                thirst = number(world.thirst, 0),
                fatigue = number(world.fatigue, 0),
            },
        },
        relationshipState = relationship.relationshipState
            or npc.relationshipState or "unknown",
        identityTrust = relationship.identityTrust,
        relationship = copy(relationship),
        npcTraits = copy(npc.traits or {}),
        npcPersonality = copy(npc.personality or {}),
        player = nil,
        playerNameKnown = true,
        playerName = context.SemanticAdapters.playerName(context, player),
        characterUUID = player.characterUUID,
        conversationTopic = conversation.topic or "greeting",
        conversationLifecycleState = { token = conversation.token or "harness-lease" },
        entry = {
            snapshot = {
                activeBehavior = "idle",
                healthState = "healthy",
                needs = {
                    hunger = number(world.hunger, 0),
                    thirst = number(world.thirst, 0),
                    fatigue = number(world.fatigue, 0),
                    stress = number(world.stress, 0),
                    boredom = number(world.boredom, 0),
                    panic = number(world.panic, 0),
                },
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

function Conversation.contextSnapshot(_, view)
    local session = view and view.session
    local context = session and session.semanticDialogueContext
    local semanticState = session and session.semanticDialogueState
    return {
        dialogue = context and context.ToContext and context:ToContext() or nil,
        state = semanticState and semanticState.Snapshot
            and semanticState:Snapshot() or nil,
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
    return {
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
            actionResult = Values.copy(actionResult),
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
        llmCalls = Runtime.llmCalls,
        loadedModules = Runtime.loadedModules,
    }
end

return Conversation
