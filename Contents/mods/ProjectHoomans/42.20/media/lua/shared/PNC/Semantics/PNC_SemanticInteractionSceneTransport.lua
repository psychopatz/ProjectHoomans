-- Bounded transport projection for already-resolved InteractionScene turns.
-- This module never selects behavior, reruns the Director, or reparses text.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Lifecycle = require "PNC/Semantics/PNC_SemanticInteractionLifecycle"
local ValueBounds = require "PNC/Semantics/PNC_SemanticValueBounds"

local Transport = PNC.Semantics.InteractionSceneTransport or {}
PNC.Semantics.InteractionSceneTransport = Transport

Transport.VERSION = 1
Transport.MAX_AUDIENCE = 8
Transport.MAX_OFFERS = 8
Transport.MAX_FACT_REFS = 16

local function copy(value)
    return ValueBounds.Copy(value)
end

local function clean(value, maximum)
    value = tostring(value or "")
    if value == "" then return nil end
    if string.find(value, "%c") then return nil end
    return string.sub(value, 1, maximum or 128)
end

local function boundedList(values, maximum)
    local output = {}
    local seen = {}
    for _, value in ipairs(type(values) == "table" and values or {}) do
        local item = clean(value, 128)
        if item and not seen[item] then
            output[#output + 1] = item
            seen[item] = true
            if #output >= (maximum or Transport.MAX_FACT_REFS) then break end
        end
    end
    return output
end

local function responseOfferIDs(plan)
    local output = {}
    local seen = {}
    for _, turn in ipairs(
        type(plan) == "table"
            and type(plan.turns) == "table"
            and plan.turns or {}
    ) do
        for _, offer in ipairs(type(turn.offers) == "table" and turn.offers or {}) do
            local id = clean(type(offer) == "table" and offer.id or nil, 128)
            if id and not seen[id] then
                output[#output + 1] = id
                seen[id] = true
                if #output >= Transport.MAX_OFFERS then return output end
            end
        end
    end
    return output
end

local function selectedRealizationID(speech, result)
    return clean(
        speech and (
            speech.phraseID
            or speech.semanticVariantID
            or speech.selectionID
            or speech.realizationVariant
        )
        or result and result.interactionPlan
            and result.interactionPlan.behaviorID,
        128
    )
end

local function turnIdentity(scene, result)
    local history = type(result) == "table"
        and type(result.semanticHistoryEvent) == "table"
        and result.semanticHistoryEvent or {}
    local speakerID = clean(
        history.targetActorID or history.targetID,
        96
    )
    local recipientID = clean(
        history.sourceActorID or history.sourceID,
        96
    )
    local sequence = tonumber(history.sequence) or 0
    if not speakerID or not recipientID or sequence <= 0 then
        return nil, "scene_turn_identity_invalid"
    end
    return {
        sceneID = clean(scene and scene.id, 128),
        speakerID = speakerID,
        recipientID = recipientID,
        sequence = sequence,
        eventID = table.concat({
            tostring(scene and scene.id or "scene"),
            "turn",
            tostring(sequence),
        }, ":"),
    }
end

local function basePacket(scene, result)
    if type(scene) ~= "table" or type(result) ~= "table" then
        return nil, "scene_result_required"
    end
    local identity, identityReason = turnIdentity(scene, result)
    if not identity then return nil, identityReason end
    local presentation = type(result.presentation) == "table"
        and result.presentation or {}
    local speech = type(presentation.speech) == "table"
        and presentation.speech or nil
    local text = clean(speech and speech.fallback, 768)
    if not text then return nil, "scene_speech_unavailable" end
    local plan = type(result.interactionPlan) == "table"
        and result.interactionPlan or {}
    local responsePlan = type(speech.plan) == "table"
        and copy(speech.plan) or nil
    local offerIDs = responseOfferIDs(responsePlan)
    return {
        schemaVersion = Transport.VERSION,
        kind = "semantic_scene_speech",
        sceneID = identity.sceneID,
        eventID = identity.eventID,
        sequence = identity.sequence,
        speakerID = identity.speakerID,
        recipientID = identity.recipientID,
        behaviorID = clean(plan.behaviorID, 128),
        act = clean(
            plan.dialogueAct or plan.behaviorAct or "REACT",
            64
        ),
        topic = clean(plan.topic, 96),
        text = text,
        responsePlanID = clean(plan.behaviorID, 128),
        realizationFamily = clean(
            speech.realizationFamily or speech.phraseFamilyID,
            128
        ),
        realizationID = selectedRealizationID(speech, result),
        factRefs = boundedList(
            plan.groundedFactRefs,
            Transport.MAX_FACT_REFS
        ),
        eventRefs = boundedList(
            plan.groundedEventRefs,
            Transport.MAX_FACT_REFS
        ),
        offerIDs = offerIDs,
        responsePlan = responsePlan,
        continuation = copy(result.continuation),
    }
end

local function playerInteraction(packet, playerID)
    if not playerID then return nil end
    local Envelope = Lifecycle and Lifecycle.Envelope or nil
    if not Envelope or type(Envelope.NPCSpeech) ~= "function" then return nil end
    return Envelope.NPCSpeech({
        actorID = packet.speakerID,
        targetID = playerID,
        playerUUID = playerID,
        act = packet.act,
        topic = packet.topic,
        beatID = packet.eventID,
        responsePlanID = packet.responsePlanID,
        poolID = packet.responsePlanID,
        realizationFamily = packet.realizationFamily,
        realizationID = packet.realizationID,
        eventType = "semantic_scene",
        eventRef = packet.eventID,
        factRefs = packet.factRefs,
    })
end

function Transport.BuildPacket(scene, result, audience)
    audience = type(audience) == "table" and audience or {}
    local packet, reason = basePacket(scene, result)
    if not packet then return nil, reason end

    local actorID = clean(audience.actorID or audience.playerID, 96)
    local role = tostring(audience.role or "observer")
    local participant = actorID and scene.participants
        and scene.participants[actorID] or nil
    local addressed = role == "recipient"
        and actorID == packet.recipientID
        and participant and participant.isPlayer == true

    packet.audienceRole = addressed and "recipient" or "observer"
    packet.observerOnly = addressed ~= true
    packet.recipientKind = addressed and "player" or "npc"
    packet.playerActorID = addressed and actorID or nil

    if addressed then
        packet.interaction = playerInteraction(packet, actorID)
        local continuation = type(result.continuation) == "table"
            and result.continuation or {}
        if continuation.mode == "wait"
            and continuation.targetID == actorID
        then
            packet.sceneHandoff = {
                sceneID = packet.sceneID,
                expectedSceneSequence = packet.sequence,
                playerID = actorID,
                npcID = packet.speakerID,
                expectedResponse = clean(
                    continuation.expectedResponse,
                    64
                ),
                waiting = true,
            }
        end
    else
        -- Observers can render the already-selected line, but receive no
        -- response plan, offers, lifecycle capsule, or scene-resume token.
        packet.offerIDs = {}
        packet.responsePlan = nil
        packet.interaction = nil
        packet.sceneHandoff = nil
    end
    return packet
end

function Transport.Deliver(scene, result, audience)
    audience = type(audience) == "table" and audience or {}
    local network = PNC.Network
    local send = network and network.Internal
        and network.Internal.SendToPlayer or nil
    local command = PNC.Const and PNC.Const.CMD_SEMANTIC_SCENE_SPEECH or nil
    if type(send) ~= "function" or not command then
        return 0, "scene_transport_unavailable"
    end

    local sent = 0
    local seen = {}
    for index = 1, math.min(#audience, Transport.MAX_AUDIENCE) do
        local row = audience[index]
        local player = type(row) == "table" and row.player or nil
        local key = clean(
            type(row) == "table"
                and (row.actorID or row.playerID or row.key)
                or nil,
            96
        )
        if player and key and not seen[key] then
            local packet = Transport.BuildPacket(scene, result, row)
            if packet and send(player, command, packet) == true then
                sent = sent + 1
                seen[key] = true
            end
        end
    end
    return sent, sent > 0 and "delivered" or "no_audience"
end

return Transport
