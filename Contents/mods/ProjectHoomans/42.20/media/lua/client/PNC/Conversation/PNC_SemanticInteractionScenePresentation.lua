-- Client presentation adapter for already-resolved semantic Scene speech.
-- It reuses the canonical semantic speech queue/presentation path and never
-- resolves meaning or generates player affordances for observer-only packets.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local ScenePresentation = PNC.Semantics.InteractionScenePresentation or {}
PNC.Semantics.InteractionScenePresentation = ScenePresentation

ScenePresentation.VERSION = 1

local function clean(value, maximum)
    value = tostring(value or "")
    if value == "" or string.find(value, "%c") then return nil end
    return string.sub(value, 1, maximum or 128)
end

function ScenePresentation.Receive(packet)
    packet = type(packet) == "table" and packet or {}
    if packet.kind ~= "semantic_scene_speech" then
        return false, "scene_speech_kind_invalid"
    end
    local sceneID = clean(packet.sceneID, 128)
    local eventID = clean(packet.eventID, 128)
    local speakerID = clean(packet.speakerID, 96)
    local text = clean(packet.text, 768)
    if not sceneID or not eventID or not speakerID or not text then
        return false, "scene_speech_identity_invalid"
    end

    local speech = PNC.SemanticSpeechPresentation
    if type(speech) ~= "table" or type(speech.Receive) ~= "function" then
        speech = require "PNC/Conversation/PNC_SemanticSpeechPresentation"
    end
    if type(speech) ~= "table" or type(speech.Receive) ~= "function" then
        return false, "semantic_speech_presentation_unavailable"
    end

    local observerOnly = packet.observerOnly == true
        or packet.audienceRole ~= "recipient"
    local context = {
        sceneID = sceneID,
        sceneSequence = tonumber(packet.sequence) or 0,
        sceneSpeakerID = speakerID,
        sceneRecipientID = clean(packet.recipientID, 96),
        sceneAudienceRole = observerOnly and "observer" or "recipient",
        observerOnly = observerOnly,
        recipientKind = observerOnly and "npc" or "player",
        sceneHandoff = not observerOnly
            and type(packet.sceneHandoff) == "table"
            and packet.sceneHandoff or nil,
        sceneResponsePlan = not observerOnly
            and type(packet.responsePlan) == "table"
            and packet.responsePlan or nil,
        interaction = not observerOnly
            and type(packet.interaction) == "table"
            and packet.interaction or nil,
        offerIDs = not observerOnly and packet.offerIDs or nil,
        factRefs = packet.factRefs,
        eventRefs = packet.eventRefs,
        contentOwner = "interaction_scene",
    }

    return speech.Receive({
        eventID = eventID,
        eventRef = eventID,
        eventType = "semantic_scene",
        family = "semantic_scene",
        npcID = speakerID,
        speechEventID = "semantic.scene.speech",
        semanticOwned = true,
        contentOwner = "interaction_scene",
        act = packet.act,
        topic = packet.topic,
        responsePlanID = packet.responsePlanID,
        realizationFamily = packet.realizationFamily,
        realizationID = packet.realizationID,
        factRefs = packet.factRefs,
        offerIDs = not observerOnly and packet.offerIDs or nil,
        interaction = context.interaction,
        text = text,
        resolvedText = text,
        llmEligible = false,
        memoryEligible = false,
        pumpImmediately = true,
        priority = 55,
        weight = 100,
        source = {
            kind = "semantic_speech",
            channel = "interaction_scene",
            contextEligible = false,
        },
        presentationState = {
            nameplate = true,
            conversationUI = observerOnly ~= true,
            tts = true,
            interrupt = false,
        },
        context = context,
    }, nil, {
        sceneID = sceneID,
        sceneSequence = tonumber(packet.sequence) or 0,
    })
end

return ScenePresentation
