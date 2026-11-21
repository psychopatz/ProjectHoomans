-- Deterministic RDR2-style street interaction (GREET / ANTAGONIZE / DEFUSE) across Agitation, SecondaryChannel, DialogueDirector, and SocialWitness.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.StreetInteraction = PNC.StreetInteraction or {}

local Service = PNC.StreetInteraction

Service.VERSION = 1
Service.MAX_RANGE_TILES = 12
Service.DEFAULT_ACTS = {
    GREET = {
        trigger = "greet",
        intent = "GREET",
        speechAct = "GREET",
        barkId = "bark.whisper_check",
        socialType = "social.greeting",
        approvalDelta = 2,
        respectDelta = 1,
        familiarityDelta = 2,
    },
    AGREE = {
        trigger = "greet",
        intent = "GREET",
        speechAct = "AGREE",
        barkId = "bark.whisper_check",
        socialType = "social.gratitude",
        approvalDelta = 2,
        respectDelta = 1,
        familiarityDelta = 1,
    },
    PRAISE = {
        trigger = "greet",
        intent = "PRAISE",
        speechAct = "PRAISE",
        barkId = "bark.whisper_check",
        socialType = "social.gratitude",
        approvalDelta = 4,
        respectDelta = 2,
        familiarityDelta = 1,
    },
    ANTAGONIZE = {
        trigger = "antagonize",
        intent = "HOSTILE_REMARK",
        speechAct = "INSULT",
        barkId = "bark.defuse_warning",
        socialType = "social.grievance",
        approvalDelta = -6,
        respectDelta = -4,
        familiarityDelta = 1,
    },
    CRITICIZE = {
        trigger = "antagonize",
        intent = "CRITICIZE",
        speechAct = "HOSTILE_REMARK",
        barkId = "bark.defuse_warning",
        socialType = "social.grievance",
        approvalDelta = -4,
        respectDelta = -3,
        familiarityDelta = 1,
    },
    DISAGREE = {
        trigger = "antagonize",
        intent = "DISAGREE",
        speechAct = "HOSTILE_REMARK",
        barkId = "bark.whisper_check",
        socialType = "social.grievance",
        approvalDelta = -2,
        respectDelta = -1,
        familiarityDelta = 1,
    },
    DEFUSE = {
        trigger = "defuse",
        intent = "APOLOGIZE",
        speechAct = "APOLOGIZE",
        barkId = "bark.defuse_warning",
        socialType = "social.apology",
        approvalDelta = 4,
        respectDelta = 3,
        familiarityDelta = 1,
    },
    PACIFY = {
        trigger = "defuse",
        intent = "APOLOGIZE",
        speechAct = "APOLOGIZE",
        barkId = "bark.whisper_check",
        socialType = "social.apology",
        approvalDelta = 3,
        respectDelta = 2,
        familiarityDelta = 1,
    },
}

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    return PNC.Core and type(PNC.Core.Now) == "function" and PNC.Core.Now() or 0
end

local function resolveSource(sourceOrId, opts)
    opts = type(opts) == "table" and opts or {}
    if type(sourceOrId) == "table" then
        local sid = sourceOrId.id
        if not sid and type(sourceOrId.getUsername) == "function" then
            sid = sourceOrId:getUsername()
        end
        sid = tostring(sid or sourceOrId.name or "player")
        local sx = sourceOrId.x ~= nil and tonumber(sourceOrId.x)
            or (type(sourceOrId.getX) == "function" and tonumber(sourceOrId:getX())) or nil
        local sy = sourceOrId.y ~= nil and tonumber(sourceOrId.y)
            or (type(sourceOrId.getY) == "function" and tonumber(sourceOrId:getY())) or nil
        local sz = sourceOrId.z ~= nil and tonumber(sourceOrId.z)
            or (type(sourceOrId.getZ) == "function" and tonumber(sourceOrId:getZ())) or 0
        local isPlayer = sourceOrId.isPlayer == true or type(sourceOrId.getUsername) == "function" or opts.sourceIsPlayer ~= false
        return {
            id = sid,
            x = sx,
            y = sy,
            z = sz,
            isPlayer = isPlayer,
            kind = isPlayer and "player" or "npc",
            record = sourceOrId,
        }
    end
    local sid = tostring(sourceOrId or "player")
    local rec = PNC.Registry and type(PNC.Registry.Get) == "function" and PNC.Registry.Get(sid) or nil
    local isPlayer = (rec == nil and opts.sourceIsPlayer ~= false) or (opts.sourceIsPlayer == true)
    return {
        id = sid,
        x = rec and tonumber(rec.x) or nil,
        y = rec and tonumber(rec.y) or nil,
        z = rec and tonumber(rec.z) or 0,
        isPlayer = isPlayer,
        kind = isPlayer and "player" or "npc",
        record = rec or { id = sid, isPlayer = isPlayer, kind = isPlayer and "player" or "npc" },
    }
end

local function resolveTarget(targetNpcOrId)
    if type(targetNpcOrId) == "table" and targetNpcOrId.id ~= nil then
        return targetNpcOrId
    end
    if targetNpcOrId ~= nil and PNC.Registry and type(PNC.Registry.Get) == "function" then
        return PNC.Registry.Get(tostring(targetNpcOrId))
    end
    return nil
end

local function collectListeners(sourceInfo, targetRecord, maxParticipants)
    local participants = {
        { id = sourceInfo.id, isPlayer = sourceInfo.isPlayer, kind = sourceInfo.kind, actor = sourceInfo.record },
        targetRecord,
    }
    if not PNC.SpatialIndex or type(PNC.SpatialIndex.QueryNPCs) ~= "function"
        or targetRecord.x == nil or targetRecord.y == nil
    then
        return participants
    end
    local near = PNC.SpatialIndex.QueryNPCs(tonumber(targetRecord.x), tonumber(targetRecord.y), 6) or {}
    local cap = math.min(4, tonumber(maxParticipants) or 4)
    for i = 1, #near do
        if #participants >= cap then break end
        local rec = near[i]
        if type(rec) == "table" and rec.id and rec.alive ~= false
            and tostring(rec.id) ~= tostring(targetRecord.id)
            and tostring(rec.id) ~= tostring(sourceInfo.id)
        then
            participants[#participants + 1] = rec
        end
    end
    return participants
end

function Service.HandleStreetAct(sourceOrId, targetNpcOrId, rawAct, opts)
    opts = type(opts) == "table" and opts or {}
    local act = string.upper(tostring(rawAct or ""))
    local spec = Service.DEFAULT_ACTS[act]
    if not spec then
        return false, "STREET_ACT_UNSUPPORTED"
    end

    local target = resolveTarget(targetNpcOrId)
    if type(target) ~= "table" or target.alive == false or target.id == nil then
        return false, "TARGET_NPC_UNAVAILABLE"
    end

    local source = resolveSource(sourceOrId, opts)
    local current = nowMs(opts.at)

    if opts.ignoreRange ~= true and source.x ~= nil and source.y ~= nil and target.x ~= nil and target.y ~= nil then
        if math.abs((source.z or 0) - (tonumber(target.z) or 0)) >= 1 then
            return false, "OUT_OF_RANGE"
        end
        local dx = source.x - tonumber(target.x)
        local dy = source.y - tonumber(target.y)
        local maxR = tonumber(opts.maxRange) or Service.MAX_RANGE_TILES
        if dx * dx + dy * dy > maxR * maxR then
            return false, "OUT_OF_RANGE"
        end
    end

    -- 1. AgitationService trigger
    local agResult = nil
    if PNC.AgitationService and type(PNC.AgitationService.ApplyTrigger) == "function" then
        local agOk, agStageOrErr, agPayload = PNC.AgitationService.ApplyTrigger(target, spec.trigger, source.id, current)
        if type(agPayload) == "table" then
            agResult = agPayload
        elseif agOk and type(agStageOrErr) == "table" then
            agResult = agStageOrErr
        elseif type(PNC.AgitationService.GetState) == "function" then
            agResult = PNC.AgitationService.GetState(target.id, current)
        end
    end

    -- 2. Orthogonal SecondaryChannel (coincident-guarded gaze, alert level, bark)
    local barkResult = nil
    local sc = PNC.SecondaryChannel
    if sc then
        if source.x ~= nil and source.y ~= nil and type(sc.RequestGaze) == "function" then
            sc.RequestGaze(target, source.x, source.y, 4000, current)
        end
        local stage = agResult and agResult.stage or "calm"
        if type(sc.SetAlertLevel) == "function" then
            sc.SetAlertLevel(target, stage)
        end
        local chosenBark = stage == "hostile" and "bark.alert_hey" or spec.barkId
        if chosenBark and type(sc.RequestBark) == "function" then
            local bOk, bRes = sc.RequestBark(target, chosenBark, current)
            if bOk then
                barkResult = bRes
            else
                barkResult = { suppressed = bRes }
            end
        end
    end

    -- 3. Deterministic 5-stage Micro-Beat DialogueDirector
    local scene = nil
    local director = PNC.DialogueMicroBeatDirector
    if director then
        local existing = director.GetActorTelemetry and director.GetActorTelemetry(target.id) or nil
        if existing and not existing.closed and type(director.Advance) == "function" then
            local advOk, advScene = director.Advance(existing.sceneId, {
                act = act,
                intent = spec.intent,
                speechAct = spec.speechAct,
                actorId = source.id,
                targetId = tostring(target.id),
                sourceIsPlayer = source.isPlayer,
                surfaceRephraser = opts.surfaceRephraser,
            }, current)
            if advOk then scene = advScene end
        elseif type(director.StartScene) == "function" then
            local participants = opts.participants or collectListeners(source, target, opts.maxParticipants)
            local stOk, started = director.StartScene({
                act = act,
                intent = spec.intent,
                speechAct = spec.speechAct,
                speakerId = source.id,
                responderId = tostring(target.id),
                participants = participants,
                sourceIsPlayer = source.isPlayer,
                firstContact = opts.firstContact == true,
                initialTension = agResult and agResult.score or (act == "ANTAGONIZE" and 25 or 10),
                maxTurns = opts.maxTurns or 4,
                waitTimeoutMs = opts.waitTimeoutMs,
                surfaceRephraser = opts.surfaceRephraser,
            }, current)
            if stOk then scene = started end
        end
    end

    -- 4. Witness-only PsychopatzSocial memory recording (zero leaks to non-witnesses)
    local witnessRes = nil
    if PNC.SocialWitness and type(PNC.SocialWitness.RecordWitnessedEvent) == "function" then
        local evId = "street:" .. act .. ":" .. tostring(source.id) .. ":" .. tostring(target.id) .. ":" .. tostring(current)
        witnessRes = PNC.SocialWitness.RecordWitnessedEvent({
            eventId = evId,
            type = spec.socialType,
            aboutKey = source.id,
            aboutIsPlayer = source.isPlayer,
            act = act,
            sceneId = scene and scene.sceneId or nil,
            x = target.x or source.x or 0,
            y = target.y or source.y or 0,
            z = target.z or source.z or 0,
            approvalDelta = spec.approvalDelta,
            respectDelta = spec.respectDelta,
            familiarityDelta = spec.familiarityDelta,
            worldAgeHours = opts.worldAgeHours,
            createdAt = opts.worldAgeHours,
            shareable = true,
        }, opts.witnessCandidates or { target }, {
            directParticipants = { [tostring(target.id)] = true },
            visionRadius = opts.visionRadius,
            hearingRadius = opts.hearingRadius,
            audible = opts.audible,
            losCheck = opts.losCheck,
            targetRecord = target,
        })
    end

    return true, {
        ok = true,
        act = act,
        targetId = tostring(target.id),
        sourceId = source.id,
        agitation = agResult,
        sceneId = scene and scene.sceneId or nil,
        stage = scene and scene.stage or nil,
        beatId = scene and scene.beatId or nil,
        behaviorId = scene and scene.behaviorId or nil,
        tension = scene and scene.tension or nil,
        bark = barkResult,
        witnessCount = witnessRes and witnessRes.recordedCount or 0,
        excludedCount = witnessRes and #(witnessRes.excluded or {}) or 0,
        llmCalls = 0,
    }
end

return Service
