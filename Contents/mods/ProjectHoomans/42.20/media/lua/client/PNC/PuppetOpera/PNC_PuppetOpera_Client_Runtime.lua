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
        local track = Blueprints.GetTrack
            and Blueprints.GetTrack(
                beat,
                localActorID,
                localActorState.kind
            )
            or beat.tracks and beat.tracks[localActorID]
            or beat.player
        if not track then
            setError("player_track_missing")
            request("player_cancelled", {
                sessionId = sessionID,
                reason = State.error,
            })
            return
        end
        if not State.beatStartedAck
            and timestamp() >= tonumber(snapshot.beatStartAt or 0)
        then
            local accepted, reason = Animation.Start(sessionID, beat, track)
            if not accepted then
                setError(reason)
                request("player_cancelled", {
                    sessionId = sessionID,
                    reason = reason,
                })
                return
            end
            State.beatStartedAck = true
            request("player_beat_started", {
                sessionId = sessionID,
                beatIndex = snapshot.beatIndex,
                revision = snapshot.revision,
            })
        end
        if State.beatStartedAck and not State.beatFinishedAck then
            local ok, status = Animation.Observe(sessionID)
            if not ok then
                setError(status)
                request("player_cancelled", {
                    sessionId = sessionID,
                    reason = status,
                })
            elseif status == "finished" then
                State.beatFinishedAck = true
                Animation.Clear(sessionID)
                request("player_beat_finished", {
                    sessionId = sessionID,
                    beatIndex = snapshot.beatIndex,
                    revision = snapshot.revision,
                })
            end
        end
    end
end

return Client
