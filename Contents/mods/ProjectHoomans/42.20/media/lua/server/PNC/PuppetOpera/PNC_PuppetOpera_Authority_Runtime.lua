-- Server-authoritative Puppet Opera runtime state machine.
--
-- This spoke owns phase progression and per-tick adapter coordination.  It
-- receives validation, ownership, and lifecycle operations from the authority
-- entry module through the bounded Internal handoff table.

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
local Blueprints = Internal.Blueprints or Opera.Blueprints
local Anchors = Internal.Anchors or Opera.Anchors
local NPCMovement = Internal.NPCMovement or Opera.NPCMovement
local NPCAnimation = Internal.NPCAnimation or Opera.NPCAnimation
local NPCOverride = Internal.NPCOverride or Opera.Override
local Registry = Internal.Registry or PNC.Registry

local function refreshLease(session, timestamp)
    for _, actor in pairs(session.actors or {}) do
        if actor.kind == "nearby_live_npc" then
            local record = actor.record
            local runtime = record and record.runtime or nil
            local lease = runtime and runtime.puppetOperaLease or nil
            if not lease or tostring(lease.sessionId or "")
                ~= tostring(session.sessionId or "")
            then
                return false
            end
            lease.expiresAt = timestamp + Opera.Config.leaseDurationMs
        end
    end
    return true
end

local function activeSafety(session, timestamp)
    local invalidPlayer = Internal.invalidPlayer
    local invalidNPC = Internal.invalidNPC
    local puppetMovementIsSafe = Internal.puppetMovementIsSafe
    local actorFailureReason = Internal.actorFailureReason
    local unsafeNPCActionState = Internal.unsafeNPCActionState
    local nonCombatBumpCanBeReleased = Internal.nonCombatBumpCanBeReleased
    local hasValue = Internal.hasValue
    local inRange = Internal.inRange
    local npcAnimation = NPCAnimation
    local npcOverride = NPCOverride

    local playerReason = invalidPlayer(session.playerBody)
    if playerReason then return false, playerReason end
    for actorID, actor in pairs(session.actors or {}) do
        if actor.kind == "nearby_live_npc" then
            local live = Registry and Registry.GetLiveZombie
                and Registry.GetLiveZombie(actor.npcID) or nil
            if live ~= actor.body then
                return false, "npc_body_changed:" .. tostring(actorID)
            end
            local reason = invalidNPC(actor.record, actor.body, session)
            if reason then
                return false, actorFailureReason(reason, actorID, actor.body)
            end
            if PNC.LiveBodyControl
                and PNC.LiveBodyControl.IsSeated
                and PNC.LiveBodyControl.IsSeated(actor.record)
            then
                return false, "npc_became_seated:" .. tostring(actorID)
            end
            local movementSafe
            movementSafe, reason = puppetMovementIsSafe(session, actor)
            if not movementSafe then return false, reason end
            if unsafeNPCActionState(actor.body)
                and not npcAnimation.IsOwned(actor.body, session.sessionId)
                and not nonCombatBumpCanBeReleased(actor.body)
            then
                return false, actorFailureReason(
                    "npc_action_state_interrupted",
                    actorID,
                    actor.body
                )
            end
            if PNC.PathService and PNC.PathService.IsTraversalActive
                and PNC.PathService.IsTraversalActive(actor.record, actor.body)
            then
                return false, "npc_traversal_started:" .. tostring(actorID)
            end
            if PNC.LiveBodyControl
                and PNC.LiveBodyControl.IsPresentationCombatActive
                and PNC.LiveBodyControl.IsPresentationCombatActive(
                    actor.record,
                    timestamp
                )
            then
                return false, "npc_entered_combat:" .. tostring(actorID)
            end
            local runtime = actor.record and actor.record.runtime or nil
            local overrideOwned = npcOverride.IsOwned(
                actor.record,
                session.sessionId
            )
            if runtime and (
                runtime.target ~= nil
                    or runtime.combatTarget ~= nil
                    or runtime.attackAction ~= nil
                    or hasValue(runtime.animationScene)
                    or hasValue(runtime.conversationLease)
                    or hasValue(runtime.taskLeaseId)
                    or hasValue(runtime.orderLeaseId)
                    or hasValue(runtime.facilityActivity)
                    or hasValue(runtime.workOrderId)
                    or hasValue(runtime.medicalCare)
                    or hasValue(runtime.treatment)
                    or hasValue(runtime.roamAmbient)
            ) then
                if runtime.target ~= nil
                    or runtime.combatTarget ~= nil
                    or runtime.attackAction ~= nil
                then
                    return false, "npc_entered_combat:" .. tostring(actorID)
                end
                if not overrideOwned then
                    return false, "npc_behavior_ownership_lost:"
                        .. tostring(actorID)
                end
            end
            if runtime and runtime.followState
                and runtime.followState.ownerMoving == true
            then
                if not overrideOwned then
                    return false, "npc_movement_ownership_lost:"
                        .. tostring(actorID)
                end
            end
            if not inRange(session.playerBody, actor.body, 20) then
                return false, "actors_out_of_range:" .. tostring(actorID)
            end
        end
    end
    if not refreshLease(session, timestamp) then
        return false, "npc_session_lease_lost"
    end
    return true
end

local function maintainOverrides(session, timestamp)
    local actorFailureReason = Internal.actorFailureReason
    local actorID
    local actor
    local maintained
    local reason
    if not NPCOverride or not NPCOverride.Maintain then return true end
    for actorID, actor in pairs(session.actors or {}) do
        if actor.record then
            maintained, reason = NPCOverride.Maintain(
                session, actor, timestamp)
            if maintained ~= true then
                return false, actorFailureReason(reason, actorID, actor.body)
            end
        end
    end
    return true
end

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
    for actorID, actor in pairs(session.actors or {}) do
        if actor.kind == "nearby_live_npc" then
            local ok, reason = NPCMovement.Observe(session, actor)
            if not ok then
                return false, tostring(reason or "npc_movement_failed")
                    .. ":" .. tostring(actorID)
            end
        end
    end
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
    local accepted
    local status
    local reason
    if not session.beatStartedAt then
        if timestamp < tonumber(session.beatStartAt or 0) then
            return true
        end
        session.beatStartedAt = timestamp
        for actorID, actor in pairs(session.actors or {}) do
            if actor.kind == "nearby_live_npc" then
                local track = Blueprints.GetTrack
                    and Blueprints.GetTrack(beat, actorID, actor.kind)
                    or beat.tracks and beat.tracks[actorID]
                    or beat.npc
                accepted, reason = NPCAnimation.Start(
                    session, actor, beat, track
                )
                if not accepted then
                    return false, reason or "npc_animation_start_failed"
                end
                actor.animationOwned = true
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
                + Opera.Config.acknowledgementTimeoutMs
        then
            return false, "player_animation_ack_timeout"
        end
    end
    for actorID, actor in pairs(session.actors or {}) do
        if actor.kind == "nearby_live_npc" and actor.animationOwned then
            local track = Blueprints.GetTrack
                and Blueprints.GetTrack(beat, actorID, actor.kind)
                or beat.tracks and beat.tracks[actorID]
                or beat.npc
            local ok
            ok, status = NPCAnimation.Observe(session, actor, beat, track)
            if not ok then return false, status end
            if status == "finished" then
                session.beatFinishedBy[actorID] = true
            elseif timestamp < session.phaseDeadline then
                local maintained, maintainReason = NPCAnimation.Maintain(
                    session,
                    actor,
                    beat,
                    session.phaseDeadline,
                    track
                )
                if maintained ~= true then
                    return false, maintainReason
                        or "npc_animation_maintain_failed"
                end
            end
        end
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

function Authority.PumpSession(session, timestamp)
    if not session or session.closed then return false end
    local safe
    local reason
    safe, reason = activeSafety(session, timestamp)
    if not safe then
        Internal.abortSession(session, reason)
        return false
    end
    safe, reason = maintainOverrides(session, timestamp)
    if not safe then
        Internal.abortSession(session, reason)
        return false
    end
    if session.phase == Opera.Phases.MOVING then
        safe, reason = pumpMoving(session, timestamp)
    elseif session.phase == Opera.Phases.FACING then
        safe, reason = pumpFacing(session, timestamp)
    elseif session.phase == Opera.Phases.READY then
        if session.previewOnly then
            session.phaseDeadline = timestamp + (
                tonumber(Opera.Config.placementPreviewLeaseMs) or 30000
            )
            safe = true
        else
            safe, reason = pumpReady(session, timestamp)
        end
    elseif session.phase == Opera.Phases.PLAYING then
        safe, reason = pumpPlaying(session, timestamp)
    else
        safe = true
    end
    if not safe then
        Internal.abortSession(session, reason or "puppet_opera_phase_failed")
        return false
    end
    if session.phaseDeadline and timestamp > session.phaseDeadline
        and session.phase ~= Opera.Phases.PLAYING
    then
        Internal.abortSession(
            session,
            "phase_timeout:" .. tostring(session.phase)
        )
        return false
    end
    return true
end

function Authority.Pump()
    local timestamp = Internal.now()
    local sessions = {}
    local sessionID
    local session
    for sessionID, session in pairs(Authority.Sessions) do
        sessions[#sessions + 1] = session
    end
    for _, session in ipairs(sessions) do
        Authority.PumpSession(session, timestamp)
    end
end

Internal.activeSafety = activeSafety
Internal.maintainOverrides = maintainOverrides

return Authority
