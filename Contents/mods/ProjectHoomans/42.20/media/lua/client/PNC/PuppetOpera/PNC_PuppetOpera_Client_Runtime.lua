-- Client Puppet Opera local session runtime.
--
-- This spoke owns per-tick release cleanup and local-player movement, facing,
-- and beat acknowledgements. Request transport and server snapshot admission
-- remain in PNC_PuppetOpera_Client_Transport.lua; preview replay remains in
-- PNC_PuppetOpera_Client_Preview.lua because it owns the debug-player lease.

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}

local Opera = PNC.PuppetOpera
local Client = Opera.Client or {}
Opera.Client = Client
local Internal = Client.Internal or {}
Client.Internal = Internal

local State = Internal.State
local Movement = Internal.Movement
local Animation = Internal.Animation
local Anchors = Internal.Anchors
local Blueprints = Internal.Blueprints
local timestamp = Internal.timestamp
local request = Internal.request
local setError = Internal.setError
local finalPhase = Internal.finalPhase
local blueprintBeat = Internal.blueprintBeat
local localActor = Internal.localActor
local actorTarget = Internal.actorTarget
local pumpPreviewLoop = Internal.pumpPreviewLoop

local function timelineFor(beat, actorID, actorKind)
    if Blueprints.GetTimeline then
        return Blueprints.GetTimeline(beat, actorID, actorKind) or {}
    end
    local track = Blueprints.GetTrack
        and Blueprints.GetTrack(beat, actorID, actorKind)
        or beat.tracks and beat.tracks[actorID]
        or beat.player
    return {
        {
            id = "legacy_" .. tostring(actorID),
            type = "animation",
            startMs = 0,
            durationMs = tonumber(beat.durationMs) or 900,
            track = track,
        },
    }
end

local function nodeIdentity(node, index)
    return tostring(node and node.id or ("node_" .. tostring(index)))
end

local function pendingTimelineNode(nodes, elapsed)
    for index, node in ipairs(nodes or {}) do
        local startMs = tonumber(node.startMs or node.offsetMs) or 0
        local durationMs = tonumber(node.durationMs) or 0
        local nodeID = nodeIdentity(node, index)
        if not (
            State.timelineNodeFinished == true
            and tostring(State.timelineNodeID or "") == nodeID
        ) and elapsed >= startMs
            and elapsed < startMs + durationMs
        then
            return node, index
        end
    end
    return nil
end

local function hasPendingTimelineNode(nodes, elapsed)
    for index, node in ipairs(nodes or {}) do
        local startMs = tonumber(node.startMs or node.offsetMs) or 0
        local durationMs = tonumber(node.durationMs) or 0
        local nodeID = nodeIdentity(node, index)
        if not (
            State.timelineNodeFinished == true
            and tostring(State.timelineNodeID or "") == nodeID
        ) and startMs + durationMs > elapsed
        then
            return true
        end
    end
    return false
end

local function releasePlayerAnimation(sessionID)
    if not Animation.IsOwned(sessionID) then return true end
    local stopped, reason = Animation.Stop(sessionID)
    if stopped ~= true and Animation.IsOwned(sessionID) then
        return false, reason or "player_animation_stop_failed"
    end
    Animation.Clear(sessionID)
    return true
end

local function cancelPlayerSession(sessionID, reason)
    setError(reason)
    request("player_cancelled", {
        sessionId = sessionID,
        reason = reason,
    })
end

local function pumpPendingReleases()
    local movementSessionID = State.pendingMovementRelease
    if movementSessionID then
        local ok, status = Movement.Observe(movementSessionID)
        if not ok or status == "arrived" then
            Movement.Clear(movementSessionID)
            State.pendingMovementRelease = nil
        end
    end
    local animationSessionID = State.pendingAnimationRelease
    if animationSessionID then
        local ok, status = Animation.Observe(animationSessionID)
        if not ok or status == "finished" then
            Animation.Clear(animationSessionID)
            State.pendingAnimationRelease = nil
        end
    end
end

function Client.Pump()
    pumpPendingReleases()
    pumpPreviewLoop()
    local snapshot = State.snapshot
    if not snapshot or finalPhase(snapshot.phase) then return end
    local sessionID = snapshot.sessionId
    if snapshot.phase == Opera.Phases.MOVING
        and State.movementSessionId == sessionID
    then
        local ok, status = Movement.Observe(sessionID)
        if not ok then
            setError(status)
            request("player_cancelled", {
                sessionId = sessionID,
                reason = status,
            })
        elseif status == "arrived"
            and State.movementAckRevision ~= snapshot.revision
        then
            State.movementAckRevision = snapshot.revision
            request("player_arrived", {
                sessionId = sessionID,
                revision = snapshot.revision,
            })
        end
    elseif snapshot.phase == Opera.Phases.FACING
        and State.facingSessionId == sessionID
    then
        local body = Movement.GetPlayer()
        local _, actor = localActor(snapshot)
        local target = actorTarget(snapshot, actor)
        if Anchors.IsFacing(body, target, 0.70) then
            if State.facingRevision ~= -snapshot.revision then
                State.facingRevision = -snapshot.revision
                request("player_facing", {
                    sessionId = sessionID,
                    revision = snapshot.revision,
                })
            end
        end
    elseif snapshot.phase == Opera.Phases.PLAYING then
        local localActorID, localActorState = localActor(snapshot)
        if not localActorID or not localActorState then return end
        local beat = blueprintBeat(snapshot)
        if not beat then
            setError("player_beat_missing")
            request("player_cancelled", {
                sessionId = sessionID,
                reason = State.error,
            })
            return
        end
        if timestamp() < tonumber(snapshot.beatStartAt or 0) then
            return
        end
        local nodes = timelineFor(beat, localActorID, localActorState.kind)
        local elapsed = math.max(
            0,
            timestamp() - tonumber(snapshot.beatStartAt or timestamp())
        )
        State.timelineElapsedMs = math.floor(elapsed)
        local node, nodeIndex = pendingTimelineNode(nodes, elapsed)
        if node and node.type == "animation" then
            local nodeID = nodeIdentity(node, nodeIndex)
            local track = node.track or node
            local durationMs = tonumber(node.durationMs)
                or tonumber(beat.durationMs) or 900
            local nodeBeat = {
                id = beat.id,
                durationMs = durationMs,
            }
            if tostring(State.timelineNodeID or "") ~= nodeID
                or State.timelineNodeType ~= "animation"
            then
                local released, releaseReason = releasePlayerAnimation(
                    sessionID
                )
                if not released then
                    cancelPlayerSession(sessionID, releaseReason)
                    return
                end
                local accepted, reason = Animation.Start(
                    sessionID,
                    nodeBeat,
                    track
                )
                if not accepted then
                    cancelPlayerSession(sessionID, reason)
                    return
                end
                State.timelineNodeID = nodeID
                State.timelineNodeType = "animation"
                State.timelineNodeFinished = false
                if not State.beatStartedAck then
                    State.beatStartedAck = true
                    request("player_beat_started", {
                        sessionId = sessionID,
                        beatIndex = snapshot.beatIndex,
                        revision = snapshot.revision,
                    })
                end
            end
            if State.beatStartedAck and not State.timelineNodeFinished then
                local ok, status = Animation.Observe(sessionID)
                if not ok then
                    cancelPlayerSession(sessionID, status)
                    return
                elseif status == "finished" then
                    State.timelineNodeFinished = true
                    Animation.Clear(sessionID)
                end
            end
        elseif node then
            local released, releaseReason = releasePlayerAnimation(sessionID)
            if not released then
                cancelPlayerSession(sessionID, releaseReason)
                return
            end
            State.timelineNodeID = nodeIdentity(node, nodeIndex)
            State.timelineNodeType = node.type or "delay"
            State.timelineNodeFinished = false
        elseif hasPendingTimelineNode(nodes, elapsed) then
            local released, releaseReason = releasePlayerAnimation(sessionID)
            if not released then
                cancelPlayerSession(sessionID, releaseReason)
                return
            end
            State.timelineNodeType = "delay"
            State.timelineNodeFinished = true
        elseif State.beatStartedAck and not State.beatFinishedAck then
            local released, releaseReason = releasePlayerAnimation(sessionID)
            if not released then
                cancelPlayerSession(sessionID, releaseReason)
                return
            end
            State.timelineNodeFinished = true
            State.beatFinishedAck = true
            request("player_beat_finished", {
                sessionId = sessionID,
                beatIndex = snapshot.beatIndex,
                revision = snapshot.revision,
            })
        end
        if State.timelineNodeFinished
            and State.beatStartedAck
            and not State.beatFinishedAck
            and not hasPendingTimelineNode(nodes, elapsed)
        then
            State.beatFinishedAck = true
            local released, releaseReason = releasePlayerAnimation(sessionID)
            if not released then
                cancelPlayerSession(sessionID, releaseReason)
                return
            end
            request("player_beat_finished", {
                sessionId = sessionID,
                beatIndex = snapshot.beatIndex,
                revision = snapshot.revision,
            })
        end
        if #nodes == 0 then
            cancelPlayerSession(sessionID, "player_timeline_missing")
            return
        end
        local hasAnimation = false
        for _, timelineNode in ipairs(nodes) do
            if timelineNode.type == "animation" then
                hasAnimation = true
                break
            end
        end
        if not hasAnimation then
            cancelPlayerSession(sessionID, "player_timeline_animation_missing")
            return
        end
        if not Blueprints.GetTimeline and not node then
            local track = Blueprints.GetTrack
                and Blueprints.GetTrack(
                    beat,
                    localActorID,
                    localActorState.kind
                )
                or beat.tracks and beat.tracks[localActorID]
                or beat.player
            if not track then
                cancelPlayerSession(sessionID, "player_track_missing")
                return
            end
        end
    end
end

return Client
