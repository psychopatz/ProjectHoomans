-- Deterministic zero-LLM 5-stage Micro-Beat Dialogue Director atop ConvoEngine & JointSceneLease.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.DialogueMicroBeatDirector = PNC.DialogueMicroBeatDirector or {}

local Director = PNC.DialogueMicroBeatDirector

Director.VERSION = 1
Director.STAGES = {
    "transition_in",
    "body",
    "local_or_global_mixin",
    "wait_with_timeout",
    "transition_out",
}
Director.DEFAULT_WAIT_TIMEOUT_MS = 6000
Director.MAX_TURNS = 6
Director.MAX_MIXINS_PER_BEAT = 2
Director.ABORT_TENSION_THRESHOLD = 90
Director.MAX_RECENT_TELEMETRY = 32

Director.ACT_TENSION_DELTAS = {
    GREET = -8,
    AGREE = -10,
    PRAISE = -12,
    PACIFY = -15,
    DEFUSE = -18,
    APOLOGIZE = -18,
    CRITICIZE = 12,
    DISAGREE = 10,
    ANTAGONIZE = 24,
    INSULT = 26,
    THREATEN = 30,
    HOSTILE_REMARK = 24,
}

local FATAL_MIXIN_TYPES = {
    combat_alert = true,
    combat = true,
    death = true,
}

local FATAL_EVENT_TYPES = {
    ["shock.explosion"] = true,
    ["shock.gunshot"] = true,
    ["shock.ally_assaulted"] = true,
}

Director.ActiveScenes = Director.ActiveScenes or {}
Director.SceneByNPC = Director.SceneByNPC or {}
Director.RecentByNPC = Director.RecentByNPC or {}
Director.RecentOrder = Director.RecentOrder or {}
Director.Sequence = Director.Sequence or 0

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    return PNC.Core and type(PNC.Core.Now) == "function" and PNC.Core.Now() or 0
end

local function clamp(value, low, high)
    value = tonumber(value) or low
    if value < low then return low end
    if value > high then return high end
    return value
end

local function resolveConvoRegistry()
    if PNC.ConvoEngine and PNC.ConvoEngine.Registry then
        return PNC.ConvoEngine.Registry
    end
    if type(require) == "function" then
        return require "PNC/ConvoEngine/Registry"
    end
    return nil
end

local function resolveDirectorIndex()
    local reg = resolveConvoRegistry()
    return reg and type(reg.DIRECTOR_INDEX) == "table" and reg.DIRECTOR_INDEX or nil
end

local function resolveCatalog()
    return PNC.ConvoEngine and PNC.ConvoEngine.InteractionCatalog or nil
end

local function resolveInteractionDirector()
    return PNC.ConvoEngine and PNC.ConvoEngine.InteractionDirector or nil
end

local function resolveShockingBus()
    if PsychopatzCore and PsychopatzCore.ShockingEventBus then
        return PsychopatzCore.ShockingEventBus
    end
    if PsychopatzCore and type(PsychopatzCore.Require) == "function" then
        local ok, bus = PsychopatzCore.Require("core.shocking_events", "PNC_DialogueMicroBeatDirector")
        if ok and type(bus) == "table" then
            return bus
        end
    end
    return nil
end

local function pushStage(scene, stage)
    scene.stage = stage
    scene.stageHistory[#scene.stageHistory + 1] = stage
end

local function recordTelemetry(npcId, payload)
    local key = tostring(npcId or "")
    if key == "" then return end
    Director.RecentByNPC[key] = payload
    Director.RecentOrder[#Director.RecentOrder + 1] = key
    while #Director.RecentOrder > Director.MAX_RECENT_TELEMETRY do
        local oldest = table.remove(Director.RecentOrder, 1)
        if oldest and oldest ~= key then
            Director.RecentByNPC[oldest] = nil
        end
    end
end

local function getRecord(participant)
    if type(participant) == "table" and participant.id ~= nil then
        return participant
    end
    if type(participant) == "table" and type(participant.actor) == "table" then
        return participant.actor
    end
    if participant ~= nil and PNC.Registry and type(PNC.Registry.Get) == "function" then
        return PNC.Registry.Get(tostring(participant))
    end
    return nil
end

local function containsValue(list, target)
    if type(list) ~= "table" then return false end
    for i = 1, #list do
        if list[i] == target then return true end
    end
    return false
end

local function normalizeActMapping(rawAct)
    local act = string.upper(tostring(rawAct or "GREET"))
    if act == "ANTAGONIZE" or act == "INSULT" or act == "THREATEN" or act == "HOSTILE_REMARK" then
        return act, "HOSTILE_REMARK", act == "THREATEN" and "THREATEN" or "INSULT", "conflict"
    end
    if act == "DEFUSE" or act == "PACIFY" or act == "APOLOGIZE" then
        return act, "APOLOGIZE", "APOLOGIZE", "repair"
    end
    if act == "PRAISE" or act == "AGREE" then
        return act, "GREET", "GREET", "first_contact"
    end
    if act == "CRITICIZE" or act == "DISAGREE" then
        return act, "CRITICIZE", "HOSTILE_REMARK", "conflict"
    end
    return act, "GREET", "GREET", "first_contact"
end

local function selectBeatAndBehavior(scene, actInput, opts)
    opts = type(opts) == "table" and opts or {}
    local rawAct = actInput.act or scene.lastAct or "GREET"
    local act, intent, speechAct, hint = normalizeActMapping(rawAct)
    local stimulusType = tostring(actInput.stimulusType or "HUMAN_UTTERANCE")
    local idx = resolveDirectorIndex()
    local catalog = resolveCatalog()
    local entries = idx and idx.entries or {}
    local stimIds = (idx and idx.byStimulus and idx.byStimulus[stimulusType]) or {}

    local preferredBeatId = nil
    local preferredBehaviorId = nil
    if act == "ANTAGONIZE" or act == "INSULT" or act == "THREATEN" or act == "HOSTILE_REMARK" then
        preferredBeatId = "beat.argument_escalation"
        preferredBehaviorId = scene.tension >= 55 and "behavior.retaliate_verbally" or "behavior.warn"
    elseif act == "DEFUSE" or act == "PACIFY" or act == "APOLOGIZE" then
        preferredBeatId = "beat.reconciliation"
        preferredBehaviorId = act == "DEFUSE" and "behavior.deescalate" or "behavior.reconcile"
    elseif act == "GREET" or act == "PRAISE" or act == "AGREE" then
        if scene.firstContact == true then
            preferredBeatId = "beat.suspicious_first_contact"
            preferredBehaviorId = "behavior.challenge"
        else
            preferredBehaviorId = "behavior.acknowledge_reply"
        end
    end

    local interactionDirector = resolveInteractionDirector()
    if interactionDirector and type(interactionDirector.PreviewStimulus) == "function" then
        local stim = {
            type = stimulusType,
            source = { kind = actInput.sourceIsPlayer == false and "npc" or "human", actorID = scene.speakerId },
            targets = { scene.responderId },
            semantic = {
                intent = actInput.intent or intent,
                speechAct = actInput.speechAct or speechAct,
                topic = scene.topic,
                confidence = 0.9,
            },
        }
        local preview = interactionDirector.PreviewStimulus(stim, { sequence = scene.turnCount }, {
            interactionProjection = {
                actor = {
                    capabilities = { speech = true },
                    disposition = { confidence = 0.7, aggression = scene.tension / 100, forgiveness = 0.7 },
                    condition = { panic = 0 },
                },
                relationship = {
                    approval = 0,
                    familiarity = scene.firstContact == true and 0 or 30,
                },
                world = { immediateDanger = false },
            },
            semanticDialogueContext = {
                director = scene.directorSnapshot,
            },
        })
        if type(preview) == "table" and type(preview.interactionPlan) == "table" then
            if preview.selectedBeat and preview.selectedBeat.id then
                preferredBeatId = preferredBeatId or preview.selectedBeat.id
            end
            if preview.selectedBehavior and preview.selectedBehavior.id then
                preferredBehaviorId = preferredBehaviorId or preview.selectedBehavior.id
            end
        end
    end

    -- Verify/resolve against canonical compiled DIRECTOR_INDEX + InteractionCatalog
    local selectedBeat = preferredBeatId and entries[preferredBeatId] or nil
    if selectedBeat and containsValue(stimIds, selectedBeat.id) == false and #stimIds > 0 then
        selectedBeat = nil
    end
    if not selectedBeat and #stimIds > 0 then
        local bestScore = -1
        for i = 1, #stimIds do
            local e = entries[stimIds[i]]
            if type(e) == "table" and e.kind == "beat" then
                local score = tonumber(e.baseRelevance) or 0
                if e.domainPath == ("social/" .. tostring(hint)) then
                    score = score + 1.0
                end
                if score > bestScore or (score == bestScore and tostring(e.id) < tostring(selectedBeat and selectedBeat.id or "~")) then
                    selectedBeat = e
                    bestScore = score
                end
            end
        end
    end

    local selectedBehavior = preferredBehaviorId and entries[preferredBehaviorId] or nil
    if not selectedBehavior and #stimIds > 0 then
        local bestScore = -1
        for i = 1, #stimIds do
            local e = entries[stimIds[i]]
            if type(e) == "table" and e.kind == "behavior" then
                local score = tonumber(e.baseRelevance) or 0
                if score > bestScore or (score == bestScore and tostring(e.id) < tostring(selectedBehavior and selectedBehavior.id or "~")) then
                    selectedBehavior = e
                    bestScore = score
                end
            end
        end
    end

    local beatId = (selectedBeat and selectedBeat.id) or preferredBeatId
    local behaviorId = (selectedBehavior and selectedBehavior.id) or preferredBehaviorId

    if catalog then
        if beatId and catalog.Beats and catalog.Beats.Get and not catalog.Beats.Get(beatId) and not entries[beatId] then
            beatId = nil
        end
        if behaviorId and catalog.Behaviors and catalog.Behaviors.Get and not catalog.Behaviors.Get(behaviorId) and not entries[behaviorId] then
            behaviorId = nil
        end
    end

    local canonicalText = tostring(act)
    if type(opts.surfaceRephraser) == "function" then
        -- Non-authoritative surface phrasing ONLY: never overrides beat/behavior selection.
        local rephrased = opts.surfaceRephraser({
            act = act,
            beatId = beatId,
            behaviorId = behaviorId,
            tension = scene.tension,
        })
        if type(rephrased) == "string" and rephrased ~= "" then
            canonicalText = rephrased
        end
    end

    return {
        act = act,
        intent = actInput.intent or intent,
        speechAct = actInput.speechAct or speechAct,
        beatId = beatId,
        behaviorId = behaviorId,
        utteranceText = canonicalText,
        directorIndexUsed = idx ~= nil,
        llmCalls = 0,
    }
end

local function isFatalMixin(mixin)
    if type(mixin) ~= "table" then return false end
    local severity = string.lower(tostring(mixin.severity or ""))
    local band = tostring(mixin.band or "")
    local mtype = string.lower(tostring(mixin.mixinType or mixin.type or ""))
    local etype = tostring(mixin.eventType or "")
    return severity == "high"
        or severity == "critical"
        or band == "HARD_EMERGENCY"
        or FATAL_MIXIN_TYPES[mtype] == true
        or FATAL_EVENT_TYPES[etype] == true
end

local function runBodyAndMixinStages(scene, actInput, opts, at)
    local delta = Director.ACT_TENSION_DELTAS[string.upper(tostring(actInput.act or scene.lastAct or "GREET"))] or 0
    scene.tension = clamp(scene.tension + delta, 0, 100)
    scene.lastAct = string.upper(tostring(actInput.act or scene.lastAct or "GREET"))

    local decision = selectBeatAndBehavior(scene, actInput, opts)
    scene.beatId = decision.beatId
    scene.behaviorId = decision.behaviorId
    scene.lastUtterance = decision.utteranceText
    scene.llmCalls = 0

    local jointLease = PNC.JointSceneLease
    if jointLease and type(jointLease.UpdateSpeaker) == "function" then
        jointLease.UpdateSpeaker(scene.leaseId, actInput.speakerId or scene.speakerId, actInput.responderId or scene.responderId, at)
    end

    pushStage(scene, "body")
    pushStage(scene, "local_or_global_mixin")

    -- Drain any queued mix-ins on this turn up to MAX_MIXINS_PER_BEAT
    while #scene.pendingMixins > 0 do
        local mixin = table.remove(scene.pendingMixins, 1)
        scene.mixinHistory[#scene.mixinHistory + 1] = mixin
        if isFatalMixin(mixin) then
            scene.aborted = true
            return false, "fatal_mixin:" .. tostring(mixin.eventType or mixin.mixinType or "emergency")
        end
        if #scene.mixinHistory <= Director.MAX_MIXINS_PER_BEAT then
            scene.tension = clamp(scene.tension + (tonumber(mixin.tensionDelta) or 5), 0, 100)
        end
    end

    if scene.tension >= Director.ABORT_TENSION_THRESHOLD then
        scene.aborted = true
        return false, "tension_threshold_exceeded"
    end

    return true, decision
end

local function finalizeScene(scene, reason, aborted, at)
    if not scene or scene.closed then return false end
    scene.closed = true
    scene.aborted = aborted == true or scene.aborted == true
    scene.closeReason = tostring(reason or (scene.aborted and "aborted" or "completed"))
    scene.closedAt = at

    if scene.stage ~= "transition_out" then
        pushStage(scene, "transition_out")
    end

    -- Bounded hearsay spread between speaker and eligible NPC listeners on non-aborted completion
    if not scene.aborted and PNC.SocialWitness and type(PNC.SocialWitness.PropagateHearsay) == "function" then
        local speakerRec = getRecord(scene.speakerId)
        if speakerRec and type(scene.participants) == "table" then
            for i = 1, #scene.participants do
                local p = scene.participants[i]
                local pid = type(p) == "table" and tostring(p.id or "") or tostring(p or "")
                if pid ~= "" and pid ~= scene.speakerId then
                    local listenerRec = getRecord(p)
                    if listenerRec and listenerRec.id ~= scene.speakerId then
                        local res = PNC.SocialWitness.PropagateHearsay(speakerRec, listenerRec, {
                            at = at,
                        })
                        if res and res.propagated == true then
                            scene.hearsayCount = (tonumber(scene.hearsayCount) or 0) + 1
                            break
                        end
                    end
                end
            end
        end
    end

    local jointLease = PNC.JointSceneLease
    if jointLease then
        if scene.aborted and type(jointLease.AbortLease) == "function" then
            jointLease.AbortLease(scene.leaseId, scene.closeReason, at)
        elseif type(jointLease.Release) == "function" then
            jointLease.Release(scene.leaseId, scene.closeReason, at)
        end
    end

    for i = 1, #(scene.participantIds or {}) do
        local pid = scene.participantIds[i]
        if Director.SceneByNPC[pid] == scene.sceneId then
            Director.SceneByNPC[pid] = nil
        end
        recordTelemetry(pid, {
            sceneId = scene.sceneId,
            leaseId = scene.leaseId,
            stage = "transition_out",
            beatId = scene.beatId,
            behaviorId = scene.behaviorId,
            tension = nil, -- ephemeral local tension discarded after closure
            lastAct = scene.lastAct,
            closed = true,
            aborted = scene.aborted,
            closeReason = scene.closeReason,
        })
    end

    -- Ephemeral tension & scene state removed on transition_out
    scene.tension = nil
    Director.ActiveScenes[scene.sceneId] = nil
    return true
end

function Director.StartScene(spec, at)
    spec = type(spec) == "table" and spec or {}
    local current = nowMs(at)
    local participants = type(spec.participants) == "table" and spec.participants or {}
    if #participants < 2 then
        return false, "DIALOGUE_PARTICIPANTS_REQUIRED"
    end

    Director.Sequence = Director.Sequence + 1
    local sceneId = tostring(spec.sceneId or ("dialogue_scene:" .. tostring(Director.Sequence)))

    local speakerId = tostring(spec.speakerId or (type(participants[1]) == "table" and participants[1].id or participants[1]) or "")
    local responderId = tostring(spec.responderId or (type(participants[2]) == "table" and participants[2].id or participants[2]) or "")
    local waitTimeoutMs = math.max(500, tonumber(spec.waitTimeoutMs) or Director.DEFAULT_WAIT_TIMEOUT_MS)

    local scene = {
        sceneId = sceneId,
        leaseId = nil,
        stage = "transition_in",
        stageHistory = { "transition_in" },
        beatId = nil,
        behaviorId = nil,
        tension = clamp(spec.initialTension or 15, 0, 100),
        turnCount = 1,
        maxTurns = math.min(Director.MAX_TURNS, math.max(1, tonumber(spec.maxTurns) or 4)),
        waitDeadlineAt = current + waitTimeoutMs,
        waitTimeoutMs = waitTimeoutMs,
        speakerId = speakerId,
        responderId = responderId,
        participants = participants,
        participantIds = {},
        topic = tostring(spec.topic or "social"),
        firstContact = spec.firstContact == true,
        lastAct = string.upper(tostring(spec.act or "GREET")),
        pendingMixins = {},
        mixinHistory = {},
        hearsayCount = 0,
        directorSnapshot = { active = nil, recent = {}, cooldowns = {}, revision = 0 },
        aborted = false,
        closed = false,
        closeReason = nil,
        llmCalls = 0,
    }

    local jointLease = PNC.JointSceneLease
    if jointLease and type(jointLease.Acquire) == "function" then
        local ok, leaseOrReason = jointLease.Acquire({
            sceneId = sceneId,
            participants = participants,
            speakerId = speakerId,
            responderId = responderId,
            ttlMs = spec.ttlMs or (waitTimeoutMs * 2),
            onAbort = function(_lease, abortReason)
                if not scene.closed then
                    finalizeScene(scene, abortReason or "joint_lease_aborted", true, nowMs())
                end
            end,
        }, current)
        if not ok then
            return false, leaseOrReason
        end
        scene.leaseId = leaseOrReason.leaseId
        scene.participantIds = leaseOrReason.participantIds
    else
        for i = 1, #participants do
            local p = participants[i]
            scene.participantIds[#scene.participantIds + 1] = tostring(type(p) == "table" and p.id or p)
        end
    end

    Director.ActiveScenes[sceneId] = scene
    for i = 1, #scene.participantIds do
        Director.SceneByNPC[scene.participantIds[i]] = sceneId
    end

    if spec.stopAtTransitionIn == true then
        for i = 1, #scene.participantIds do
            recordTelemetry(scene.participantIds[i], {
                sceneId = scene.sceneId,
                leaseId = scene.leaseId,
                stage = scene.stage,
                beatId = scene.beatId,
                tension = scene.tension,
                lastAct = scene.lastAct,
                closed = false,
            })
        end
        return true, scene
    end

    local bodyOk, bodyRes = runBodyAndMixinStages(scene, {
        act = spec.act,
        intent = spec.intent,
        speechAct = spec.speechAct,
        speakerId = speakerId,
        responderId = responderId,
        sourceIsPlayer = spec.sourceIsPlayer,
    }, spec, current)

    if not bodyOk then
        finalizeScene(scene, bodyRes, true, current)
        return true, scene
    end

    if scene.turnCount >= scene.maxTurns then
        finalizeScene(scene, "max_turns_reached", false, current)
    else
        pushStage(scene, "wait_with_timeout")
        scene.waitDeadlineAt = current + scene.waitTimeoutMs
        for i = 1, #scene.participantIds do
            recordTelemetry(scene.participantIds[i], {
                sceneId = scene.sceneId,
                leaseId = scene.leaseId,
                stage = scene.stage,
                beatId = scene.beatId,
                behaviorId = scene.behaviorId,
                tension = scene.tension,
                lastAct = scene.lastAct,
                closed = false,
            })
        end
    end

    return true, scene
end

function Director.Advance(sceneId, actInput, at)
    local scene = Director.ActiveScenes[tostring(sceneId or "")]
    if not scene or scene.closed then
        return false, "DIALOGUE_SCENE_NOT_FOUND"
    end
    local current = nowMs(at)
    actInput = type(actInput) == "table" and actInput or {}
    if actInput.actorId ~= nil then
        scene.speakerId = tostring(actInput.actorId)
    end
    if actInput.targetId ~= nil then
        scene.responderId = tostring(actInput.targetId)
    end
    scene.turnCount = scene.turnCount + 1

    local bodyOk, bodyRes = runBodyAndMixinStages(scene, actInput, actInput, current)
    if not bodyOk then
        finalizeScene(scene, bodyRes, true, current)
        return true, scene
    end

    if actInput.close == true or scene.turnCount >= scene.maxTurns then
        finalizeScene(scene, actInput.closeReason or "completed", false, current)
    else
        pushStage(scene, "wait_with_timeout")
        scene.waitDeadlineAt = current + scene.waitTimeoutMs
        for i = 1, #scene.participantIds do
            recordTelemetry(scene.participantIds[i], {
                sceneId = scene.sceneId,
                leaseId = scene.leaseId,
                stage = scene.stage,
                beatId = scene.beatId,
                behaviorId = scene.behaviorId,
                tension = scene.tension,
                lastAct = scene.lastAct,
                closed = false,
            })
        end
    end
    return true, scene
end

function Director.InjectGlobalMixin(sceneIdOrNpcId, mixinEvent, at)
    local key = tostring(sceneIdOrNpcId or "")
    local scene = Director.ActiveScenes[key]
        or (Director.SceneByNPC[key] and Director.ActiveScenes[Director.SceneByNPC[key]])
        or nil
    if not scene or scene.closed then
        return false, "DIALOGUE_SCENE_NOT_FOUND"
    end
    local current = nowMs(at)
    mixinEvent = type(mixinEvent) == "table" and mixinEvent or {}

    local entry = {
        mixinType = tostring(mixinEvent.mixinType or mixinEvent.type or "bystander_bark"),
        eventType = tostring(mixinEvent.eventType or ""),
        severity = tostring(mixinEvent.severity or "low"),
        band = tostring(mixinEvent.band or ""),
        sourceId = mixinEvent.sourceId and tostring(mixinEvent.sourceId) or nil,
        tensionDelta = tonumber(mixinEvent.tensionDelta) or 4,
        at = current,
    }
    scene.mixinHistory[#scene.mixinHistory + 1] = entry
    pushStage(scene, "local_or_global_mixin")

    if isFatalMixin(entry) then
        finalizeScene(scene, "global_mixin_abort:" .. (entry.eventType ~= "" and entry.eventType or entry.mixinType), true, current)
        return true, { action = "aborted", sceneId = scene.sceneId, reason = scene.closeReason }
    end

    if #scene.mixinHistory <= Director.MAX_MIXINS_PER_BEAT then
        scene.tension = clamp((tonumber(scene.tension) or 0) + entry.tensionDelta, 0, 100)
        local sc = PNC.SecondaryChannel
        if sc and type(scene.participants) == "table" then
            for i = 1, #scene.participants do
                local rec = getRecord(scene.participants[i])
                if rec and rec.alive ~= false then
                    if type(sc.SetAlertLevel) == "function" then
                        sc.SetAlertLevel(rec, "wary")
                    end
                    if mixinEvent.barkId and type(sc.RequestBark) == "function" then
                        sc.RequestBark(rec, mixinEvent.barkId, current)
                    end
                end
            end
        end
    end

    -- Resume scene without losing beat/turn state
    pushStage(scene, "wait_with_timeout")
    scene.waitDeadlineAt = current + scene.waitTimeoutMs
    for i = 1, #scene.participantIds do
        recordTelemetry(scene.participantIds[i], {
            sceneId = scene.sceneId,
            leaseId = scene.leaseId,
            stage = scene.stage,
            beatId = scene.beatId,
            behaviorId = scene.behaviorId,
            tension = scene.tension,
            lastAct = scene.lastAct,
            closed = false,
            lastMixin = entry.mixinType,
        })
    end
    return true, { action = "interleaved", sceneId = scene.sceneId, tension = scene.tension, stage = scene.stage }
end

function Director.TickTimeout(sceneId, at)
    local scene = Director.ActiveScenes[tostring(sceneId or "")]
    if not scene or scene.closed then return false, "DIALOGUE_SCENE_NOT_FOUND" end
    local current = nowMs(at)
    if scene.stage == "wait_with_timeout" and scene.waitDeadlineAt and current >= scene.waitDeadlineAt then
        finalizeScene(scene, "wait_timeout", false, current)
        return true, { closed = true, reason = "wait_timeout", sceneId = scene.sceneId }
    end
    return true, { closed = false, stage = scene.stage, sceneId = scene.sceneId }
end

function Director.SweepTimeouts(at)
    local current = nowMs(at)
    local ids = {}
    for id in pairs(Director.ActiveScenes) do
        ids[#ids + 1] = id
    end
    table.sort(ids)
    local closedCount = 0
    for i = 1, #ids do
        local scene = Director.ActiveScenes[ids[i]]
        if scene and scene.stage == "wait_with_timeout" and scene.waitDeadlineAt and current >= scene.waitDeadlineAt then
            finalizeScene(scene, "wait_timeout", false, current)
            closedCount = closedCount + 1
        end
    end
    return closedCount
end

function Director.CloseScene(sceneId, reason, at)
    local scene = Director.ActiveScenes[tostring(sceneId or "")]
    if not scene or scene.closed then return false, "DIALOGUE_SCENE_NOT_FOUND" end
    return finalizeScene(scene, reason or "closed", false, nowMs(at))
end

function Director.GetScene(sceneId)
    return Director.ActiveScenes[tostring(sceneId or "")]
end

function Director.GetActorTelemetry(npcId)
    local key = tostring(npcId or "")
    local activeId = Director.SceneByNPC[key]
    if activeId and Director.ActiveScenes[activeId] then
        local scene = Director.ActiveScenes[activeId]
        return {
            sceneId = scene.sceneId,
            leaseId = scene.leaseId,
            stage = scene.stage,
            beatId = scene.beatId,
            behaviorId = scene.behaviorId,
            tension = scene.tension,
            lastAct = scene.lastAct,
            closed = false,
        }
    end
    return Director.RecentByNPC[key]
end

local function onShockingEvent(ev)
    if type(ev) ~= "table" then return end
    local ids = {}
    for id in pairs(Director.ActiveScenes) do
        ids[#ids + 1] = id
    end
    table.sort(ids)
    local ex = tonumber(ev.x)
    local ey = tonumber(ev.y)
    local ez = tonumber(ev.z) or 0
    local r = math.max(12, tonumber(ev.radius) or 18)
    local r2 = r * r

    for i = 1, #ids do
        local scene = Director.ActiveScenes[ids[i]]
        if scene and not scene.closed then
            local affected = false
            for p = 1, #scene.participantIds do
                local pid = scene.participantIds[p]
                if ev.targetId ~= nil and tostring(ev.targetId) == pid then
                    affected = true
                    break
                end
                local rec = getRecord(pid)
                if rec and ex and ey and rec.x ~= nil and rec.y ~= nil
                    and math.abs((tonumber(rec.z) or 0) - ez) <= 1
                then
                    local dx = tonumber(rec.x) - ex
                    local dy = tonumber(rec.y) - ey
                    if dx * dx + dy * dy <= r2 then
                        affected = true
                        break
                    end
                end
            end
            if affected then
                Director.InjectGlobalMixin(scene.sceneId, {
                    mixinType = "shocking_event",
                    eventType = ev.eventType,
                    severity = ev.severity,
                    band = ev.band,
                    sourceId = ev.sourceId,
                }, ev.at)
            end
        end
    end
end

function Director.EnsureSubscribed()
    local bus = resolveShockingBus()
    if bus and type(bus.Subscribe) == "function" then
        bus.Subscribe("*", onShockingEvent, "PNC.DialogueMicroBeatDirector")
    end
end

function Director.Reset()
    local ids = {}
    for id in pairs(Director.ActiveScenes) do
        ids[#ids + 1] = id
    end
    table.sort(ids)
    for i = 1, #ids do
        local scene = Director.ActiveScenes[ids[i]]
        if scene then
            finalizeScene(scene, "reset", true, 0)
        end
    end
    Director.ActiveScenes = {}
    Director.SceneByNPC = {}
    Director.RecentByNPC = {}
    Director.RecentOrder = {}
    Director.Sequence = 0
    Director.EnsureSubscribed()
end

Director.EnsureSubscribed()

return Director
