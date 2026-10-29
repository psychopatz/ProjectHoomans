-- Server-authoritative consequence bridge for autonomous semantic speech.
-- Shared SocialConversation selects meaning; this adapter only hands supported
-- NPC->NPC social acts to the existing SocialEventService.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Service = PNC.Semantics.SocialConsequenceService or {}
PNC.Semantics.SocialConsequenceService = Service

local EVENT_BY_ACT = {
    INSULT = "npc_dialogue_insult",
    HOSTILE_REMARK = "npc_dialogue_hostile_remark",
    THREATEN = "npc_dialogue_threat",
}

local function clean(value, maximum)
    value = tostring(value or "")
    if value == "" or string.find(value, "%c") then return nil end
    value = string.sub(value, 1, maximum or 128)
    if string.find(value, "[^%w_%.:%-]") then return nil end
    return value
end

local function worldAgeHours()
    local time = getGameTime and getGameTime() or nil
    if time and type(time.getWorldAgeHours) == "function" then
        return math.max(0, tonumber(time:getWorldAgeHours()) or 0)
    end
    return 0
end

function Service.EventTypeFor(act)
    act = string.upper(tostring(act or ""))
    return EVENT_BY_ACT[act]
end

function Service.Apply(spec)
    spec = type(spec) == "table" and spec or {}
    local request = type(spec.request) == "table" and spec.request or {}
    local act = string.upper(tostring(
        request.speechAct or request.intent
        or spec.speechAct or spec.intent or ""
    ))
    local eventType = Service.EventTypeFor(act)
    if not eventType then
        return {
            accepted = false,
            applied = false,
            reason = "social_consequence_not_applicable",
            speechAct = act ~= "" and act or nil,
        }
    end

    local sourceID = clean(request.sourceID or spec.sourceID, 128)
    local targetID = clean(request.responderID or spec.targetID, 128)
    if not sourceID or not targetID or sourceID == targetID then
        return {
            accepted = false,
            applied = false,
            reason = "social_consequence_actor_invalid",
            speechAct = act,
        }
    end

    local entityRef = PNC.EntityRef
    local socialEvents = PNC.SocialEvents
    if not entityRef or type(entityRef.ForNPC) ~= "function"
        or not socialEvents or type(socialEvents.Emit) ~= "function"
    then
        return {
            accepted = false,
            applied = false,
            reason = "social_consequence_authority_unavailable",
            speechAct = act,
        }
    end

    local actorKey = entityRef.ForNPC(sourceID)
    local targetKey = entityRef.ForNPC(targetID)
    if not actorKey or not targetKey then
        return {
            accepted = false,
            applied = false,
            reason = "social_consequence_entity_ref_unavailable",
            speechAct = act,
        }
    end

    local sceneID = clean(spec.sceneID, 128) or "scene"
    local sequence = math.max(0, math.floor(tonumber(spec.sequence) or 0))
    local eventID = table.concat({
        "social:semantic_scene",
        sceneID,
        tostring(sequence),
        sourceID,
        targetID,
        eventType,
    }, ":")

    local processed = socialEvents.Emit({
        id = eventID,
        type = eventType,
        actorKey = actorKey,
        targetKey = targetKey,
        occurredAt = math.max(
            0,
            tonumber(spec.occurredAt) or worldAgeHours()
        ),
        sourceSystem = "semantic_scene",
        context = {
            sceneID = sceneID,
            sequence = sequence,
            speechAct = act,
            semanticStrategy = clean(spec.strategy, 64),
            socialMotive = clean(spec.motive, 64),
        },
    })

    return {
        accepted = type(processed) == "table" and processed.ok == true,
        applied = type(processed) == "table" and processed.ok == true,
        reason = type(processed) == "table" and processed.reason
            or "social_consequence_event_failed",
        speechAct = act,
        eventType = eventType,
        eventID = eventID,
        result = processed,
    }
end

return Service
