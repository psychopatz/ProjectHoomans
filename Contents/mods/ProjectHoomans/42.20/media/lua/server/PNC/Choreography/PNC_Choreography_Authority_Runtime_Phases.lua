-- Server-authoritative Puppet Opera phase handlers.
--
-- This provider owns movement, facing, beat preparation, and playback phase
-- coordination.  The runtime entry keeps safety checks and session dispatch.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Choreography = PNC.Choreography or {}

local Opera = PNC.Choreography
local Authority = Opera.Authority or {}
Opera.Authority = Authority
local Internal = Authority.Internal or {}
Authority.Internal = Internal
local Anchors = Internal.Anchors or Opera.Anchors
local Blueprints = Internal.Blueprints or Opera.Blueprints
local Tether = Opera.Tether
    or require "PNC/Core/Choreography/PNC_Choreography_Tether"
local Telemetry = Opera.Telemetry
    or require "PNC/Core/Choreography/PNC_Choreography_Telemetry"
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
    local totalBeats = #(session.blueprint.beats or {})
    if session.beatIndex < totalBeats then
        session.beatIndex = session.beatIndex + 1
    elseif session.loopEnabled then
        session.beatIndex = 1
        session.iteration = session.iteration + 1
    else
        return Internal.closeSession(
            session,
            Opera.Phases.COMPLETED,
            "playback_complete"
        )
    end
    for _, actor in pairs(session.actors or {}) do
        actor.facing = false
    end
    scheduleBeat(session, timestamp)
    return true
end

local function pumpMoving(session, timestamp)
    local stateChanged = false
    local arrivalTol = session.plan
        and (session.plan.arrivalTolerance or session.plan.tolerance)
        or 0.75
    for actorID, actor in pairs(session.actors or {}) do
        if actor.kind == "nearby_live_npc"
            and actor.stationary ~= true
            and actor.arrived ~= true
        then
            local previousState = actor.state
            local ok, reason = NPCMovement.Observe(session, actor)
            if not ok then
                return false, tostring(reason or "npc_movement_failed")
                    .. ":" .. tostring(actorID)
            end
            if actor.state ~= previousState then stateChanged = true end
        elseif actor.kind == "local_player"
            and actor.arrived ~= true
            and actor.body
            and actor.target
            and Anchors.IsAt(actor.body, actor.target, arrivalTol)
        then
            actor.arrived = true
            actor.state = "arrived"
            actor.lastReason = "player_arrived_server_verified"
            stateChanged = true
        end
    end
    if Telemetry and Telemetry.LogActorSnapshot then
        Telemetry.LogActorSnapshot(session, "MOVE_PROGRESS", timestamp, false)
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
            if actor.stationary == true then
                actor.facing = true
            else
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
    end
    local allFacing = true
    for _, actor in pairs(session.actors or {}) do
        if not actor.facing then allFacing = false break end
    end
    if not allFacing and Telemetry and Telemetry.LogActorSnapshot then
        Telemetry.LogActorSnapshot(session, "FACE_PROGRESS", timestamp, false)
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
    local beat = session.blueprint and session.blueprint.beats
        and session.blueprint.beats[session.beatIndex] or nil
    if beat and (beat.tetherActive == true or beat.mode == "locomotive") then
        local bpActors = session.blueprint and session.blueprint.actors or {}
        for actorID, actor in pairs(session.actors or {}) do
            local def = bpActors[actorID]
            local coupling = def and def.coupling or nil
            if coupling and coupling.attachTo then
                local leader = session.actors[coupling.attachTo]
                if leader and leader.body and actor.body then
                    Tether.ApplyBody(actor.body, leader.body, coupling)
                end
            end
        end
    end
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
        session.beatSampled = false
        for actorID, actor in pairs(session.actors or {}) do
            if actor.kind == "nearby_live_npc" then
                actor.timelineStartedAt = timestamp
                session.beatStartedBy[actorID] = true
            elseif actor.kind == "local_player" then
                session.beatStartedBy[actorID] = session.beatStartedBy[actorID] == true
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
    if beat.tetherActive == true or beat.mode == "locomotive" then
        local bpActors = session.blueprint and session.blueprint.actors or {}
        for actorID, actor in pairs(session.actors or {}) do
            local def = bpActors[actorID]
            local coupling = def and def.coupling or nil
            local lease = actor.record and actor.record.runtime
                and actor.record.runtime.choreographyLease or nil
            if coupling and coupling.attachTo then
                local leader = session.actors[coupling.attachTo]
                if leader and leader.body and actor.body then
                    local okTether, tetherReason = Tether.ApplyBody(
                        actor.body,
                        leader.body,
                        coupling
                    )
                    if not okTether then
                        return false, tostring(tetherReason or "tether_failed")
                            .. ":" .. tostring(actorID)
                    end
                    actor.tethered = true
                    actor.tetherLeaderID = coupling.attachTo
                    if lease then
                        lease.tethered = true
                        lease.carrying = false
                    end
                    if not actor._tetherNavCleared and actor.record then
                        actor._tetherNavCleared = true
                        local rt = actor.record.runtime
                        if rt then
                            rt.moveIntent = nil
                            rt.localNavigation = nil
                        end
                        if PNC.EnginePathPlanner
                            and PNC.EnginePathPlanner.Invalidate
                        then
                            PNC.EnginePathPlanner.Invalidate(
                                actor.record,
                                "choreography_tether",
                                actor.body
                            )
                        end
                        if PNC.PathService and PNC.PathService.Commands
                            and PNC.PathService.Commands.Reset
                        then
                            PNC.PathService.Commands.Reset(
                                actor.record,
                                actor.body,
                                "choreography_tether"
                            )
                        end
                    end
                elseif leader and leader.record and actor.record
                    and coupling.abstractCoMove ~= false
                then
                    Tether.SyncAbstractPair(leader.record, actor.record)
                end
            elseif beat.mode == "locomotive" and actor.kind == "nearby_live_npc" then
                -- Mark untethered locomotive initiator as carrying so its own
                -- AI/behavior (colonist follow, neutral/hostile flee, squad
                -- rescue, etc.) drives locomotion agnostically while tethered
                -- passengers remain suspended and follow in lockstep.
                if lease then
                    lease.carrying = true
                    lease.tethered = false
                end
            end
        end
    end
    if beat.disableCollision == true then
        for _, actor in pairs(session.actors or {}) do
            if actor.body and actor.body.setCollidable then
                actor.body:setCollidable(false)
                actor.collisionDisabled = true
            end
        end
    end
    if not session.beatSampled
        and session.beatStartedAt
        and timestamp >= session.beatStartedAt + 250
    then
        session.beatSampled = true
        if Telemetry and Telemetry.LogBeatSample then
            Telemetry.LogBeatSample(session, beat)
        end
    end
    if stateChanged then
        Internal.sendState(session, false)
    end
    if Internal.VisualSync and Internal.VisualSync.SyncBeat then
        Internal.VisualSync.SyncBeat(session, beat, false)
    end
    if beat.mode == "sustained" or beat.mode == "locomotive" then
        session.phaseDeadline = timestamp + tonumber(beat.durationMs or 900)
            + Opera.Config.beatGraceMs
        return true
    end
    local beatDuration = tonumber(beat.durationMs) or 900
    if session.beatStartedAt and timestamp >= session.beatStartedAt + beatDuration then
        for actorID, actor in pairs(session.actors or {}) do
            if actor.kind == "local_player"
                and session.beatStartedBy[actorID] == true
                and not session.beatFinishedBy[actorID]
            then
                local track = Blueprints and Blueprints.GetTrack
                    and Blueprints.GetTrack(beat, actorID, actor.kind) or nil
                if type(track) == "table" and track.route == "anim_vars" then
                    session.beatFinishedBy[actorID] = true
                    actor.animationOwned = false
                    actor.state = "animation_finished"
                    actor.lastReason = "player_anim_vars_duration_complete"
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
        if Telemetry and Telemetry.LogActorSnapshot then
            Telemetry.LogActorSnapshot(session, "BEAT_TIMEOUT", timestamp, true)
        end
        return false, "beat_timeout"
    end
    return true
end

Internal.pumpMoving = pumpMoving
Internal.pumpFacing = pumpFacing
Internal.pumpReady = pumpReady
Internal.pumpPlaying = pumpPlaying

return Authority
