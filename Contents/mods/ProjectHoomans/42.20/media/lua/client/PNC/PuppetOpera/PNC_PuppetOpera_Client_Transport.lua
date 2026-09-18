-- Client Puppet Opera transport and server snapshot ingress.
--
-- This spoke owns request routing, server-command registration, preflight
-- ingestion, and the server-to-client movement/facing/beat handoff. Local
-- preview leases remain in PNC_PuppetOpera_Client_Preview.lua; per-tick local
-- execution remains in PNC_PuppetOpera_Client_Runtime.lua.

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}

local Opera = PNC.PuppetOpera
local Client = Opera.Client or {}
Opera.Client = Client
local Internal = Client.Internal or {}
Client.Internal = Internal

local State = Internal.State
local Const = Internal.Const
local Movement = Internal.Movement
local timestamp = Internal.timestamp
local localPlayer = Internal.localPlayer
local isClientOnly = Internal.isClientOnly
local setError = Internal.setError
local resetTransient = Internal.resetTransient
local stopOwnedLocals = Internal.stopOwnedLocals
local finalPhase = Internal.finalPhase
local localActor = Internal.localActor
local actorTarget = Internal.actorTarget

local function request(action, payload)
    payload = type(payload) == "table" and payload or {}
    payload.action = tostring(action or "")
    local player = localPlayer()
    if isClientOnly() then
        if not player or not sendClientCommand then
            setError("puppet_opera_network_unavailable")
            return false, State.error
        end
        sendClientCommand(player, Const.MODULE, Const.CMD_PUPPET_OPERA_REQUEST, payload)
        return true, "sent"
    end
    local authority = Opera.Authority
    if authority and authority.HandleRequest then
        local accepted, result = authority.HandleRequest(player, payload)
        if type(result) == "table" and result.preflight then
            Client.ReceivePreflight(result.preflight)
        elseif type(result) == "table" and result.sessionId then
            Client.ReceiveState(Opera.BuildSnapshot(result, false))
        end
        if accepted ~= true then setError(result) end
        return accepted == true, result
    end
    setError("puppet_opera_authority_unavailable")
    return false, State.error
end

function Client.Request(action, payload)
    return request(action, payload)
end

function Client.ReceivePreflight(preflight)
    if type(preflight) ~= "table" then return false end
    State.preflight = preflight
    State.preflightKey = tostring(
        preflight.requestKey or State.preflightKey or ""
    )
    State.preflightRequestedAt = timestamp()
    if not State.snapshot or not State.snapshot.sessionId then
        State.status = preflight.ready == true and "ready" or "blocked"
        State.error = nil
    end
    return true
end

function Client.ReceiveState(snapshot)
    if type(snapshot) ~= "table" then return false end
    local previous = State.snapshot
    if previous
        and previous.sessionId == snapshot.sessionId
        and tonumber(snapshot.revision or 0) < tonumber(previous.revision or 0)
    then
        return false
    end
    State.snapshot = snapshot
    if snapshot.trace then State.trace = snapshot.trace end
    if snapshot.preflight then Client.ReceivePreflight(snapshot.preflight) end
    if snapshot.preflight and not snapshot.sessionId then
        State.status = snapshot.preflight.ready == true
            and "ready" or "blocked"
    else
        State.status = tostring(snapshot.phase or "idle")
    end
    State.error = snapshot.lastError
    if finalPhase(snapshot.phase) then
        stopOwnedLocals(snapshot.sessionId)
        if snapshot.trace then State.trace = snapshot.trace end
        State.placementPreviewKey = nil
        State.placementPreviewRefreshAt = 0
        return true
    end
    if previous and previous.sessionId ~= snapshot.sessionId then
        resetTransient()
    end
    local localActorID, localActorState = localActor(snapshot)
    if snapshot.phase == Opera.Phases.MOVING then
        if localActorState
            and (State.movementSessionId ~= snapshot.sessionId
                or State.movementRevision ~= snapshot.revision)
        then
            local playerTarget = localActorState.target
            if playerTarget then
                local accepted, reason = Movement.Start(
                    snapshot.sessionId,
                    playerTarget,
                    {}
                )
                if not accepted then
                    setError(reason)
                    request("player_cancelled", {
                        sessionId = snapshot.sessionId,
                        reason = reason,
                    })
                    return false
                end
            end
            State.movementSessionId = snapshot.sessionId
            State.movementRevision = snapshot.revision
            State.movementAckRevision = nil
            request("player_moving", {
                sessionId = snapshot.sessionId,
                revision = snapshot.revision,
            })
        end
    elseif snapshot.phase == Opera.Phases.FACING then
        if localActorState
            and State.movementSessionId == snapshot.sessionId
        then
            local stopped, stopReason = Movement.Stop(snapshot.sessionId)
            if stopped ~= true and Movement.IsOwned(snapshot.sessionId) then
                local observed, movementStatus = Movement.Observe(
                    snapshot.sessionId
                )
                if not (observed and movementStatus == "arrived") then
                    setError(stopReason or movementStatus)
                    request("player_cancelled", {
                        sessionId = snapshot.sessionId,
                        reason = State.error,
                    })
                    return false
                end
            end
            Movement.Clear(snapshot.sessionId)
            State.movementSessionId = nil
            State.movementRevision = nil
        end
        if localActorState
            and (State.facingSessionId ~= snapshot.sessionId
                or State.facingRevision ~= snapshot.revision)
        then
            local npcTarget = actorTarget(snapshot, localActorState)
            local accepted, reason = Movement.Face(npcTarget)
            if not accepted then
                setError(reason)
                request("player_cancelled", {
                    sessionId = snapshot.sessionId,
                    reason = reason,
                })
                return false
            end
            State.facingSessionId = snapshot.sessionId
            State.facingRevision = snapshot.revision
        end
    elseif snapshot.phase == Opera.Phases.PLAYING then
        if State.beatSessionId ~= snapshot.sessionId
            or State.beatRevision ~= snapshot.revision
            or State.beatIndex ~= snapshot.beatIndex
        then
            State.beatSessionId = snapshot.sessionId
            State.beatRevision = snapshot.revision
            State.beatIndex = snapshot.beatIndex
            State.beatStartedAck = false
            State.beatFinishedAck = false
        end
    end
    return true
end

local function receiveTrace(snapshot)
    if type(snapshot) == "table" then
        State.trace = snapshot.trace or {}
        State.snapshot = snapshot
    end
end

if PNC.Client and PNC.Client.Internal
    and PNC.Client.Internal.RegisterServerCommand
then
    PNC.Client.Internal.RegisterServerCommand(
        Const.CMD_PUPPET_OPERA_STATE,
        Client.ReceiveState
    )
    PNC.Client.Internal.RegisterServerCommand(
        Const.CMD_PUPPET_OPERA_TRACE,
        receiveTrace
    )
end

return Client
