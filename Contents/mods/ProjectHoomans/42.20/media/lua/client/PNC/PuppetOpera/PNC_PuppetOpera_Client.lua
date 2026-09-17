-- Client transport and local-player half of Puppet Opera.

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}

local Opera = PNC.PuppetOpera
local Anchors = Opera.Anchors
    or require "PNC/Core/PuppetOpera/PNC_PuppetOpera_Anchors"
local Movement = Opera.PlayerMovement
    or require "PNC/PuppetOpera/PNC_PuppetOpera_PlayerMovementAdapter"
local Animation = Opera.PlayerAnimation
    or require "PNC/PuppetOpera/PNC_PuppetOpera_PlayerAnimationAdapter"
local Blueprints = Opera.Blueprints
    or require "PNC/Core/PuppetOpera/PNC_PuppetOpera_Blueprints"

local Client = Opera.Client or {}
Opera.Client = Client
Client.State = Client.State or {
    snapshot = nil,
    trace = {},
    status = "idle",
    error = nil,
    movementSessionId = nil,
    movementRevision = nil,
    movementAckRevision = nil,
    facingSessionId = nil,
    facingRevision = nil,
    beatSessionId = nil,
    beatRevision = nil,
    beatIndex = nil,
    beatStartedAck = false,
    beatFinishedAck = false,
    pendingMovementRelease = nil,
    pendingAnimationRelease = nil,
}

local State = Client.State
local Core = PNC.Core
local Const = PNC.Const or {}

local function timestamp()
    return Core and Core.Now and Core.Now() or 0
end

local function localPlayer()
    return Movement.GetPlayer and Movement.GetPlayer() or nil
end

local function isClientOnly()
    return Core and Core.IsClientOnly and Core.IsClientOnly() == true
end

local function setError(reason)
    State.error = tostring(reason or "puppet_opera_error")
    State.status = "error"
end

local function resetTransient()
    State.movementSessionId = nil
    State.movementRevision = nil
    State.movementAckRevision = nil
    State.facingSessionId = nil
    State.facingRevision = nil
    State.beatSessionId = nil
    State.beatRevision = nil
    State.beatIndex = nil
    State.beatStartedAck = false
    State.beatFinishedAck = false
end

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
        if type(result) == "table" and result.sessionId then
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

function Client.Start(blueprintID, npcID, loopEnabled, definition)
    State.error = nil
    State.status = "requesting"
    return request("start", {
        blueprintId = tostring(blueprintID or "social.kiss_test"),
        npcID = tostring(npcID or ""),
        loop = loopEnabled == true,
        definition = type(definition) == "table" and definition or nil,
    })
end

function Client.Replay(blueprintID, npcID, loopEnabled, definition)
    State.error = nil
    State.status = "requesting"
    return request("replay", {
        blueprintId = tostring(blueprintID or "social.kiss_test"),
        npcID = tostring(npcID or ""),
        loop = loopEnabled == true,
        definition = type(definition) == "table" and definition or nil,
    })
end

function Client.Stop()
    local snapshot = State.snapshot
    if not snapshot or not snapshot.sessionId then
        return false, "puppet_opera_session_missing"
    end
    return request("stop", { sessionId = snapshot.sessionId })
end

function Client.DumpTrace()
    local snapshot = State.snapshot
    return request("dump_trace", {
        sessionId = snapshot and snapshot.sessionId or nil,
    })
end

function Client.Refresh()
    return request("snapshot")
end

function Client.ClearStatus()
    State.error = nil
    if State.snapshot and State.snapshot.phase then
        State.status = State.snapshot.phase
    else
        State.status = "idle"
    end
end

local function stopOwnedLocals(sessionID)
    if not sessionID then return end
    local movementStopped = Movement.Stop(sessionID)
    local animationStopped = Animation.Stop(sessionID)
    if movementStopped == true or not Movement.IsOwned(sessionID) then
        Movement.Clear(sessionID)
        State.pendingMovementRelease = nil
    else
        State.pendingMovementRelease = tostring(sessionID)
    end
    if animationStopped == true or not Animation.IsOwned(sessionID) then
        Animation.Clear(sessionID)
        State.pendingAnimationRelease = nil
    else
        State.pendingAnimationRelease = tostring(sessionID)
    end
    resetTransient()
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

local function finalPhase(phase)
    return phase == Opera.Phases.STOPPING
        or phase == Opera.Phases.RESTORED
        or phase == Opera.Phases.COMPLETED
        or phase == Opera.Phases.ABORTED
end

local function blueprintBeat(snapshot)
    local blueprint = snapshot
        and Blueprints.Get(snapshot.blueprintId) or nil
    local index = snapshot and tonumber(snapshot.beatIndex) or nil
    return blueprint and index and blueprint.beats[index] or nil
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
    State.status = tostring(snapshot.phase or "idle")
    State.error = snapshot.lastError
    if finalPhase(snapshot.phase) then
        stopOwnedLocals(snapshot.sessionId)
        if snapshot.trace then State.trace = snapshot.trace end
        return true
    end
    if previous and previous.sessionId ~= snapshot.sessionId then
        resetTransient()
    end
    if snapshot.phase == Opera.Phases.MOVING then
        if State.movementSessionId ~= snapshot.sessionId
            or State.movementRevision ~= snapshot.revision
        then
            local playerTarget = snapshot.actors
                and snapshot.actors.player
                and snapshot.actors.player.target
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
            State.movementSessionId = snapshot.sessionId
            State.movementRevision = snapshot.revision
            State.movementAckRevision = nil
            request("player_moving", {
                sessionId = snapshot.sessionId,
                revision = snapshot.revision,
            })
        end
    elseif snapshot.phase == Opera.Phases.FACING then
        if State.movementSessionId == snapshot.sessionId then
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
        if State.facingSessionId ~= snapshot.sessionId
            or State.facingRevision ~= snapshot.revision
        then
            local npcTarget = snapshot.actors
                and snapshot.actors.npc
                and snapshot.actors.npc.target
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

local function nearbyEntry(zombie, record, snapshot, playerBody)
    if not zombie and not snapshot then return nil end
    local x = zombie and zombie.getX and zombie:getX()
        or snapshot and tonumber(snapshot.x)
        or record and tonumber(record.x)
    local y = zombie and zombie.getY and zombie:getY()
        or snapshot and tonumber(snapshot.y)
        or record and tonumber(record.y)
    if not x or not y then return nil end
    local px = playerBody and playerBody.getX and playerBody:getX() or x
    local py = playerBody and playerBody.getY and playerBody:getY() or y
    local id = record and record.id
        or snapshot and snapshot.id
        or zombie and zombie.getModData
            and zombie:getModData().PNC_UUID or nil
    if not id then return nil end
    return {
        id = tostring(id),
        name = record and (record.displayName or record.name)
            or snapshot and (snapshot.displayName or snapshot.name)
            or tostring(id),
        record = record,
        zombie = zombie,
        snapshot = snapshot,
        x = x,
        y = y,
        distSq = (x - px) * (x - px) + (y - py) * (y - py),
    }
end

function Client.GetNearbyNPCs(radius)
    local entries = {}
    local seen = {}
    local playerBody = localPlayer()
    local maxDistance = tonumber(radius) or 8
    local function addEntry(zombie, record, snapshot)
        local entry = nearbyEntry(zombie, record, snapshot, playerBody)
        local id = entry and tostring(entry.id or "") or ""
        if id ~= "" and entry.distSq <= maxDistance * maxDistance
            and not seen[id]
        then
            seen[id] = true
            entries[#entries + 1] = entry
        end
    end
    local registry = PNC.Registry
    if registry and registry.ForEachLive then
        registry.ForEachLive(function(record, body)
            addEntry(body, record, nil)
        end)
    end
    local clientState = PNC.Network and PNC.Network.ClientState
    local sync = PNC.ClientPresenceSync
    for id, snapshot in pairs(clientState and clientState.snapshots or {}) do
        if snapshot
            and snapshot.presenceState == (PNC.Const and PNC.Const.PRESENCE_LIVE)
            and snapshot.alive ~= false
        then
            local body = sync and sync.BodyByID
                and sync.BodyByID[tostring(id)] or nil
            if body == false then body = nil end
            addEntry(body, nil, snapshot)
        end
    end
    table.sort(entries, function(left, right)
        if left.distSq ~= right.distSq then
            return left.distSq < right.distSq
        end
        return tostring(left.name) < tostring(right.name)
    end)
    return entries
end

function Client.GetStatus()
    return State.status, State.error
end

function Client.GetSnapshot()
    return State.snapshot
end

function Client.GetTrace()
    return State.trace or {}
end

function Client.GetGridPreview()
    local snapshot = State.snapshot
    local blueprint = snapshot
        and Blueprints.Get(snapshot.blueprintId) or Blueprints.Get("social.kiss_test")
    return Anchors.GetGridPreview(blueprint)
end

function Client.Pump()
    pumpPendingReleases()
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
        local target = snapshot.actors
            and snapshot.actors.npc
            and snapshot.actors.npc.target
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
        local beat = blueprintBeat(snapshot)
        if not beat then
            setError("player_beat_missing")
            request("player_cancelled", {
                sessionId = sessionID,
                reason = State.error,
            })
            return
        end
        if not State.beatStartedAck
            and timestamp() >= tonumber(snapshot.beatStartAt or 0)
        then
            local accepted, reason = Animation.Start(sessionID, beat)
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

function Client.Reset()
    local snapshot = State.snapshot
    if snapshot and snapshot.sessionId then
        stopOwnedLocals(snapshot.sessionId)
    else
        resetTransient()
    end
    State.snapshot = nil
    State.trace = {}
    State.status = "idle"
    State.error = nil
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
        function(snapshot)
            if type(snapshot) == "table" then
                State.trace = snapshot.trace or {}
                State.snapshot = snapshot
            end
        end
    )
end

if Events and Events.OnTick then
    Events.OnTick.Add(Client.Pump)
end
if Events and Events.OnResetLua then
    Events.OnResetLua.Add(Client.Reset)
end

return Client
