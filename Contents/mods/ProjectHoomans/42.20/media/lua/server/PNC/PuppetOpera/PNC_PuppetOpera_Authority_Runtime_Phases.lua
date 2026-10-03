-- Server-authoritative Puppet Opera phase handlers.
--
-- This provider owns movement, facing, beat preparation, and playback phase
-- coordination.  The runtime entry keeps safety checks and session dispatch.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}

local Opera = PNC.PuppetOpera
local Authority = Opera.Authority or {}
Opera.Authority = Authority
local Internal = Authority.Internal or {}
Authority.Internal = Internal
local Anchors = Internal.Anchors or Opera.Anchors
local NPCMovement = Internal.NPCMovement or Opera.NPCMovement
local NPCAnimation = Internal.NPCAnimation or Opera.NPCAnimation
local timelineStartOffset = Internal.timelineStartOffset
local pumpNPCAnimationTimeline = Internal.pumpNPCAnimationTimeline

local function moveToFacing(session, timestamp)
    for _, actor in pairs(session.actors or {}) do
        if actor.kind == "nearby_live_npc" then
            if actor.movementOwned then NPCMovement.Release(session, actor) end
        end
        actor.state = "facing"
        actor.lastReason = "movement_barrier_complete"
    end
    Internal.setPhase(
        session,
        Opera.Phases.FACING,
        timestamp + Opera.Config.facingTimeoutMs,
        "movement_complete",
        true
    )
end

local function scheduleBeat(session, timestamp)
    local playback = session.blueprint.playback or {}
    session.beatStartAt = timestamp + (tonumber(playback.gapMs) or 250)
    session.beatStartedAt = nil
    session.beatStartedBy = {}
    session.beatFinishedBy = {}
    session.beatRevision = nil
    for _, actor in pairs(session.actors or {}) do
        actor.state = "animation_queued"
        actor.lastReason = "beat_scheduled"
    end
    Internal.setPhase(
        session,
        Opera.Phases.READY,
        session.beatStartAt + Opera.Config.acknowledgementTimeoutMs
            + tonumber(session.blueprint.beats[session.beatIndex].durationMs or 900)
            + Opera.Config.beatGraceMs,
        "beat_scheduled",
        true
    )
end

local function prepareBeat(session, timestamp)
    local beat = session.blueprint.beats[session.beatIndex]
    local playback = session.blueprint.playback or {}
    if not beat then return false, "beat_missing" end
    session.beatStartAt = timestamp + (tonumber(playback.gapMs) or 250)
    session.beatStartedAt = nil
    session.beatStartedBy = {}
    session.beatFinishedBy = {}
    for _, actor in pairs(session.actors or {}) do
        actor.animationStartedAt = nil
        actor.animationOwned = false
        actor.timelineStartedAt = nil
        actor.timelineNodeID = nil
        actor.timelineNodeType = nil
        actor.timelineNodeFinished = false
        actor.timelineElapsedMs = 0
        actor.state = "animation_ready"
        actor.lastReason = "beat_prepared"
    end
    Internal.setPhase(
        session,
        Opera.Phases.PLAYING,
        session.beatStartAt + tonumber(beat.durationMs or 900)
            + Opera.Config.beatGraceMs,
        "beat_prepared",
        false
    )
    session.beatRevision = session.revision
    Internal.sendState(session, false)
    return true
end

local function beatFinished(session, timestamp)
    for _, actor in pairs(session.actors or {}) do
        if actor.kind == "nearby_live_npc" then
            if actor.animationOwned then NPCAnimation.Release(session, actor) end
            actor.animationOwned = false
        end
    end
    Internal.trace(session, "beat_finished", {
        beat = session.blueprint.beats[session.beatIndex].id,
        iteration = session.iteration,
    }, timestamp)
    if not session.loopEnabled then
        return Internal.closeSession(
            session,
            Opera.Phases.COMPLETED,
            "playback_complete"
        )
    end
    session.beatIndex = session.beatIndex + 1
    if session.beatIndex > #session.blueprint.beats then
        session.beatIndex = 1
        session.iteration = session.iteration + 1
    end
    for _, actor in pairs(session.actors or {}) do
        actor.facing = false
    end
    scheduleBeat(session, timestamp)
    return true
end

local function pumpMoving(session, timestamp)
    local stateChanged = false
    for actorID, actor in pairs(session.actors or {}) do
        if actor.kind == "nearby_live_npc" then
            local previousState = actor.state
            local ok, reason = NPCMovement.Observe(session, actor)
            if not ok then
                return false, tostring(reason or "npc_movement_failed")
                    .. ":" .. tostring(actorID)
            end
            if actor.state ~= previousState then stateChanged = true end
        end
    end
    if stateChanged then Internal.sendState(session, false) end
    local allArrived = true
    for _, actor in pairs(session.actors or {}) do
        if not actor.arrived then allArrived = false break end
    end
    if allArrived then
        moveToFacing(session, timestamp)
    end
    return true
end

local function pumpFacing(session, timestamp)
    for actorID, actor in pairs(session.actors or {}) do
        if actor.kind == "nearby_live_npc" then
            if not actor.body.faceLocation then
                return false, "npc_facing_api_unavailable:" .. tostring(actorID)
            end
            local targetActor = actor.target and session.actors
                and session.actors[actor.target.faceTarget] or nil
            local target = targetActor and targetActor.target or nil
            if not target then
                return false, "npc_facing_target_unavailable:"
                    .. tostring(actorID)
            end
            local point = Anchors.WorldPoint(target)
            if not point then
                return false, "npc_facing_target_unavailable:"
                    .. tostring(actorID)
            end
            actor.body:faceLocation(point.x, point.y)
            actor.facing = Anchors.IsFacing(actor.body, target, 0.70)
        end
    end
    local allFacing = true
    for _, actor in pairs(session.actors or {}) do
        if not actor.facing then allFacing = false break end
    end
    if allFacing then
        if session.previewOnly then
            for _, actor in pairs(session.actors or {}) do
                actor.state = "preview_ready"
                actor.lastReason = "placement_preview_facing_complete"
            end
            Internal.setPhase(
                session,
                Opera.Phases.READY,
                timestamp + (tonumber(Opera.Config.placementPreviewLeaseMs)
                    or 30000),
                "placement_preview_ready",
                true
            )
        else
            scheduleBeat(session, timestamp)
        end
    end
    return true
end

local function pumpReady(session, timestamp)
    if timestamp < tonumber(session.beatStartAt or 0) then return true end
    local accepted, reason = prepareBeat(session, timestamp)
    if not accepted then return false, reason end
    return true
end

local function pumpPlaying(session, timestamp)
    local beat = session.blueprint.beats[session.beatIndex]
    local stateChanged = false
    if not session.beatStartedAt then
        if timestamp < tonumber(session.beatStartAt or 0) then
            return true
        end
        session.beatStartedAt = timestamp
        for actorID, actor in pairs(session.actors or {}) do
            if actor.kind == "nearby_live_npc" then
                actor.timelineStartedAt = timestamp
                session.beatStartedBy[actorID] = true
            elseif actor.kind == "local_player" then
                session.beatStartedBy[actorID] = false
            end
        end
        Internal.trace(session, "beat_started", {
            beat = beat.id,
            revision = session.revision,
        }, timestamp)
        Internal.sendState(session, false)
    end
    for actorID, actor in pairs(session.actors or {}) do
        if actor.kind == "local_player"
            and not session.beatStartedBy[actorID]
            and timestamp > session.beatStartedAt
                + timelineStartOffset(beat, actorID, actor.kind)
                + Opera.Config.acknowledgementTimeoutMs
        then
            return false, "player_animation_ack_timeout"
        end
    end
    for actorID, actor in pairs(session.actors or {}) do
        if actor.kind == "nearby_live_npc" then
            local ok, reason, changed = pumpNPCAnimationTimeline(
                session,
                actor,
                beat,
                timestamp
            )
            if not ok then return false, reason end
            stateChanged = stateChanged or changed == true
        end
    end
    if stateChanged then
        Internal.sendState(session, false)
    end
    local allFinished = true
    for actorID in pairs(session.actors or {}) do
        if not session.beatFinishedBy[actorID] then
            allFinished = false
            break
        end
    end
    if allFinished then
        return beatFinished(session, timestamp)
    end
    if timestamp >= session.phaseDeadline then
        return false, "beat_timeout"
    end
    return true
end

Internal.pumpMoving = pumpMoving
Internal.pumpFacing = pumpFacing
Internal.pumpReady = pumpReady
Internal.pumpPlaying = pumpPlaying

return Authority
