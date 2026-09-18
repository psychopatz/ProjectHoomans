-- Client transport and local-player half of Puppet Opera.

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

local PREVIEW_PLAYER_OWNER = "ProjectHoomans.PuppetOperaPreview"
local PREVIEW_NPC_OWNER_KEY = "PNC_PuppetOperaPreviewOwner"
local PREVIEW_NPC_OWNER = "ProjectHoomans.PuppetOperaPreview"

local function previewNPCMarker(body)
    local modData = body and body.getModData and body:getModData() or nil
    return modData and tostring(modData[PREVIEW_NPC_OWNER_KEY] or "")
        or ""
end

local function markPreviewNPC(body)
    local modData = body and body.getModData and body:getModData() or nil
    if modData then modData[PREVIEW_NPC_OWNER_KEY] = PREVIEW_NPC_OWNER end
end

local function clearPreviewNPCMarker(body)
    local modData = body and body.getModData and body:getModData() or nil
    if modData and previewNPCMarker(body) == PREVIEW_NPC_OWNER then
        modData[PREVIEW_NPC_OWNER_KEY] = nil
    end
end

function Client.PreviewPlayer(entry)
    if type(entry) ~= "table" then return false, "player_preview_entry_missing" end
    local controller = PsychopatzCore
        and PsychopatzCore.Animation
        and PsychopatzCore.Animation.Player
        or nil
    if not controller or not controller.Play then
        return false, "player_animation_controller_unavailable"
    end
    local runtime = controller.Runtime and controller.Runtime() or nil
    if runtime and runtime.active == true then
        if tostring(runtime.owner or "") ~= PREVIEW_PLAYER_OWNER then
            return false, "player_animation_owned_by_other"
        end
        local handle = controller.GetActiveHandle
            and controller.GetActiveHandle() or nil
        if controller.Stop then controller.Stop(handle, "preview_replaced") end
    end
    local player = controller.ResolveLocalPlayer
        and controller.ResolveLocalPlayer() or localPlayer()
    local accepted, reason = controller.Play(player, entry, {
        owner = PREVIEW_PLAYER_OWNER,
        loop = State.previewLoop == true,
        actionEvents = {},
    })
    if accepted == true then State.previewPlayerOwner = PREVIEW_PLAYER_OWNER end
    return accepted == true, reason
end

function Client.PreviewNPC(entry, npcID, body, record)
    if type(entry) ~= "table" then return false, "npc_preview_entry_missing" end
    local debugPlayer = PNC.AnimationDebugPlayer
    if not debugPlayer or not debugPlayer.PlayXML then
        return false, "npc_animation_debug_player_unavailable"
    end
    local id = tostring(npcID or "")
    local active = debugPlayer.active
    if active then
        if tostring(active.npcId or "") ~= id
            or State.previewNPCID ~= id
            or previewNPCMarker(active.body) ~= PREVIEW_NPC_OWNER
        then
            return false, "npc_preview_owned_by_other"
        end
    end
    if active and debugPlayer.Stop then
        clearPreviewNPCMarker(active.body)
        debugPlayer.Stop("preview_replaced")
    end
    -- The Presentation Lab's default preview is intentionally a generic
    -- debugger lease. Puppet Opera previews are a non-combat presentation
    -- lease, otherwise PlayBump leaves the body in `bumped` and the server
    -- readiness gate correctly rejects the same actor as action-state busy.
    -- Keep this option at the shared Animation.PlayBump boundary so the
    -- builder uses the same XML/BumpType pipeline as the NPC lab without
    -- weakening the normal NPC action route.
    local accepted, reason = debugPlayer.PlayXML(
        entry,
        id,
        body,
        record,
        {
            sceneId = PREVIEW_NPC_OWNER .. ":" .. id,
            sceneRevision = 0,
            leaseUntil = timestamp() + 10000,
            keepManagedUseless = false,
            nonCombat = true,
            loop = State.previewLoop == true,
        }
    )
    if accepted == true then
        State.previewNPCID = id
        State.previewNPCBody = debugPlayer.active
            and debugPlayer.active.body or body
        State.previewNPCEntry = entry
        State.previewNPCRecord = record
        State.previewNPCNextAt = timestamp() + 900
        markPreviewNPC(State.previewNPCBody)
    end
    return accepted == true, reason
end

function Client.StopPreview()
    local stopped = false
    local controller = PsychopatzCore
        and PsychopatzCore.Animation
        and PsychopatzCore.Animation.Player
        or nil
    local runtime = controller and controller.Runtime and controller.Runtime()
        or nil
    if controller and runtime and runtime.active
        and tostring(runtime.owner or "") == PREVIEW_PLAYER_OWNER
    then
        local handle = controller.GetActiveHandle
            and controller.GetActiveHandle() or nil
        stopped = controller.Stop(handle, "preview_stopped") == true or stopped
    end
    local debugPlayer = PNC.AnimationDebugPlayer
    if debugPlayer and debugPlayer.active
        and tostring(debugPlayer.active.npcId or "")
            == tostring(State.previewNPCID or "")
        and previewNPCMarker(debugPlayer.active.body) == PREVIEW_NPC_OWNER
    then
        clearPreviewNPCMarker(debugPlayer.active.body)
        stopped = debugPlayer.Stop("preview_stopped") == true or stopped
    end
    State.previewPlayerOwner = nil
    State.previewNPCID = nil
    State.previewNPCBody = nil
    State.previewNPCEntry = nil
    State.previewNPCRecord = nil
    State.previewNPCNextAt = 0
    return stopped
end

function Client.SetPreviewLoopEnabled(enabled)
    State.previewLoop = enabled == true
    if not State.previewLoop then State.previewNPCNextAt = 0 end
    return State.previewLoop
end

function Client.GetPreviewLoopEnabled()
    return State.previewLoop == true
end

local function pumpPreviewLoop()
    if State.previewLoop ~= true then return end
    local debugPlayer = PNC.AnimationDebugPlayer
    local active = debugPlayer and debugPlayer.active or nil
    if not active
        or tostring(active.npcId or "") ~= tostring(State.previewNPCID or "")
        or previewNPCMarker(active.body) ~= PREVIEW_NPC_OWNER
    then
        return
    end
    local current = timestamp()
    if debugPlayer.Maintain then
        debugPlayer.Maintain(active.body, current)
    end
    if current < (tonumber(State.previewNPCNextAt) or 0) then return end
    if debugPlayer.Replay and State.previewNPCEntry then
        local accepted = debugPlayer.Replay()
        if accepted == true then
            local entry = State.previewNPCEntry
            local duration = tonumber(entry.durationMs) or 900
            local speed = tonumber(entry.speed) or 1
            duration = math.floor(duration / math.max(0.1, speed))
            duration = math.max(250, math.min(5000, duration))
            State.previewNPCNextAt = current + duration
            if debugPlayer.active and debugPlayer.active.body then
                markPreviewNPC(debugPlayer.active.body)
            end
        end
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
    State.preflight = nil
    State.preflightKey = nil
    State.preflightRequestedAt = 0
    State.placementPreviewKey = nil
    State.placementPreviewRefreshAt = 0
    State.previewLoop = false
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
