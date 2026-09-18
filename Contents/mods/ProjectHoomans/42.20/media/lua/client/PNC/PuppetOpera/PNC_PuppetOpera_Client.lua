-- Client coordinator and compatibility API for Puppet Opera.

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}

local Opera = PNC.PuppetOpera
require "PNC/Debug/PNC_AnimationDebugPlayer"
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
    preflight = nil,
    preflightKey = nil,
    preflightRequestedAt = 0,
    placementPreviewKey = nil,
    placementPreviewRefreshAt = 0,
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
    previewPlayerOwner = nil,
    previewNPCID = nil,
    previewNPCBody = nil,
    previewLoop = false,
    previewNPCEntry = nil,
    previewNPCRecord = nil,
    previewNPCNextAt = 0,
}

local State = Client.State
local Core = PNC.Core
local Const = PNC.Const or {}
local stopOwnedLocals

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

-- Keep the coordinator call sites stable while transport owns the request
-- implementation. The target is resolved when a public operation is called,
-- after the transport spoke has been composed below.
local function request(action, payload)
    return Client.Request(action, payload)
end

function Client.Start(blueprintID, npcID, loopEnabled, definition,
    actorBindings)
    State.error = nil
    State.status = "requesting"
    if State.snapshot and State.snapshot.preview
        and State.snapshot.sessionId
    then
        stopOwnedLocals(State.snapshot.sessionId)
    end
    -- A preview is owned by this builder, so it is safe to release before a
    -- server session claims the same actor.  This also prevents the Core
    -- player controller's preview lease from blocking the first beat.
    Client.StopPreview()
    return request("start", {
        blueprintId = tostring(blueprintID or "social.kiss_player_npc"),
        npcID = npcID and tostring(npcID) or nil,
        actors = type(actorBindings) == "table" and actorBindings or nil,
        loop = loopEnabled == true,
        definition = type(definition) == "table" and definition or nil,
    })
end

function Client.Replay(blueprintID, npcID, loopEnabled, definition,
    actorBindings)
    State.error = nil
    State.status = "requesting"
    if State.snapshot and State.snapshot.preview
        and State.snapshot.sessionId
    then
        stopOwnedLocals(State.snapshot.sessionId)
    end
    Client.StopPreview()
    return request("replay", {
        blueprintId = tostring(blueprintID or "social.kiss_player_npc"),
        npcID = npcID and tostring(npcID) or nil,
        actors = type(actorBindings) == "table" and actorBindings or nil,
        loop = loopEnabled == true,
        definition = type(definition) == "table" and definition or nil,
    })
end

function Client.Preflight(blueprintID, definition, actorBindings, requestKey,
    force)
    local current = timestamp()
    local key = tostring(requestKey or blueprintID or "")
    local refreshMs = Opera.Config and tonumber(
        Opera.Config.preflightRefreshMs
    ) or 1000
    if not force
        and State.preflightKey == key
        and current - (tonumber(State.preflightRequestedAt) or 0)
            < refreshMs
    then
        return true, "preflight_cached"
    end
    State.preflightKey = key
    State.preflightRequestedAt = current
    if not State.snapshot or not State.snapshot.sessionId then
        State.status = "preflight"
        State.error = nil
    end
    return request("preflight", {
        blueprintId = tostring(blueprintID or "social.kiss_player_npc"),
        actors = type(actorBindings) == "table" and actorBindings or {},
        definition = type(definition) == "table" and definition or nil,
    })
end

function Client.StartPlacementPreview(blueprintID, definition, actorBindings,
    requestKey, force)
    local key = tostring(requestKey or blueprintID or "")
    local snapshot = State.snapshot
    if not force
        and State.placementPreviewKey == key
        and snapshot and snapshot.preview == true
        and snapshot.sessionId
    then
        return true, "placement_preview_cached"
    end
    if snapshot and snapshot.preview == true and snapshot.sessionId then
        stopOwnedLocals(snapshot.sessionId)
    end
    -- The builder's individual player/NPC previews use the same native
    -- animation lanes as the placement preview. Release only those previews
    -- owned by this builder before the server evaluates the live actor; an
    -- old local Shove preview must not present itself as an NPC action-state
    -- conflict during placement.
    Client.StopPreview()
    State.placementPreviewKey = key
    State.placementPreviewRefreshAt = timestamp()
    State.error = nil
    State.status = "preview_requesting"
    return request("preview_start", {
        blueprintId = tostring(blueprintID or "social.kiss_player_npc"),
        actors = type(actorBindings) == "table" and actorBindings or {},
        definition = type(definition) == "table" and definition or nil,
    })
end

function Client.StopPlacementPreview()
    local snapshot = State.snapshot
    if not snapshot or snapshot.preview ~= true or not snapshot.sessionId then
        if State.placementPreviewKey then
            local accepted, result = request("preview_stop", {})
            State.placementPreviewKey = nil
            State.placementPreviewRefreshAt = 0
            if accepted then
                State.status = "idle"
                State.error = nil
            end
            return accepted, result
        end
        State.placementPreviewKey = nil
        return false, "placement_preview_missing"
    end
    stopOwnedLocals(snapshot.sessionId)
    local accepted, result = request("preview_stop", {
        sessionId = snapshot.sessionId,
    })
    if accepted and result == "preview_stopped" then
        State.snapshot = nil
        State.status = "idle"
        State.error = nil
        State.placementPreviewKey = nil
    end
    return accepted, result
end

function Client.RefreshPlacementPreview(force)
    local snapshot = State.snapshot
    if not snapshot or snapshot.preview ~= true or not snapshot.sessionId then
        return false, "placement_preview_missing"
    end
    local current = timestamp()
    if not force and current - (tonumber(State.placementPreviewRefreshAt)
        or 0) < 5000
    then
        return true, "placement_preview_cached"
    end
    State.placementPreviewRefreshAt = current
    return request("preview_refresh", { sessionId = snapshot.sessionId })
end

function Client.Stop()
    local snapshot = State.snapshot
    if not snapshot or not snapshot.sessionId then
        local pendingPreviewAccepted, pendingPreviewResult =
            Client.StopPlacementPreview()
        if pendingPreviewAccepted
            or pendingPreviewResult ~= "placement_preview_missing"
        then
            return pendingPreviewAccepted, pendingPreviewResult
        end
        local previewStopped = Client.StopPreview()
        return previewStopped, previewStopped
            and "preview_stopped" or "puppet_opera_session_missing"
    end
    if snapshot.preview == true then
        return Client.StopPlacementPreview()
    end
    local accepted, result = request("stop", { sessionId = snapshot.sessionId })
    Client.StopPreview()
    return accepted, result
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
    elseif State.preflight then
        State.status = State.preflight.ready == true and "ready" or "blocked"
    else
        State.status = "idle"
    end
end

stopOwnedLocals = function(sessionID)
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

local function localActor(snapshot)
    for actorID, actor in pairs(snapshot and snapshot.actors or {}) do
        if actor and actor.kind == "local_player" then
            return tostring(actorID), actor
        end
    end
    -- Older snapshots predate generic actor metadata.
    if snapshot and snapshot.actors and snapshot.actors.player then
        return "player", snapshot.actors.player
    end
    return nil, nil
end

local function actorTarget(snapshot, actor)
    local targetID = actor and actor.target and actor.target.faceTarget
        or nil
    if not targetID and snapshot and snapshot.actors
        and snapshot.actors.npc
    then
        return snapshot.actors.npc.target
    end
    local targetActor = targetID and snapshot and snapshot.actors
        and snapshot.actors[tostring(targetID)] or nil
    return targetActor and targetActor.target or nil
end

-- Explicit handoff keeps the transport spoke dependent on stable contracts,
-- not on the coordinator's lexical locals. It also makes authority and local
-- side effects visible at the composition boundary.
local Internal = Client.Internal or {}
Client.Internal = Internal
Internal.State = State
Internal.Opera = Opera
Internal.Const = Const
Internal.Movement = Movement
Internal.Animation = Animation
Internal.Anchors = Anchors
Internal.Blueprints = Blueprints
Internal.timestamp = timestamp
Internal.localPlayer = localPlayer
Internal.isClientOnly = isClientOnly
Internal.request = request
Internal.setError = setError
Internal.resetTransient = resetTransient
Internal.stopOwnedLocals = stopOwnedLocals
Internal.finalPhase = finalPhase
Internal.blueprintBeat = blueprintBeat
Internal.localActor = localActor
Internal.actorTarget = actorTarget

require "PNC/PuppetOpera/PNC_PuppetOpera_Client_Discovery"
require "PNC/PuppetOpera/PNC_PuppetOpera_Client_Preview"
require "PNC/PuppetOpera/PNC_PuppetOpera_Client_Runtime"
require "PNC/PuppetOpera/PNC_PuppetOpera_Client_Transport"

function Client.GetStatus()
    return State.status, State.error
end

function Client.GetPreflight()
    return State.preflight
end

function Client.GetLocalPlayer()
    return localPlayer()
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
        and Blueprints.Get(snapshot.blueprintId) or Blueprints.Get("social.kiss_player_npc")
    return Anchors.GetGridPreview(blueprint)
end

function Client.Reset()
    Client.StopPreview()
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
    State.preflight = nil
    State.preflightKey = nil
    State.preflightRequestedAt = 0
    State.placementPreviewKey = nil
    State.placementPreviewRefreshAt = 0
    State.previewLoop = false
end

if Events and Events.OnTick then
    Events.OnTick.Add(Client.Pump)
end
if Events and Events.OnResetLua then
    Events.OnResetLua.Add(Client.Reset)
end

return Client
