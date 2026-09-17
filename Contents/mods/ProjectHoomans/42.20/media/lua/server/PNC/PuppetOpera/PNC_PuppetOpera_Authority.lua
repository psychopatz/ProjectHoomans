-- Server-authoritative Puppet Opera session coordinator.
--
-- This module deliberately does not reuse the ordinary AnimationScenes
-- lifecycle. Puppet Opera owns a separate lease and only releases state that
-- carries the current session id.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}

local Opera = PNC.PuppetOpera
local Blueprints = Opera.Blueprints
    or require "PNC/Core/PuppetOpera/PNC_PuppetOpera_Blueprints"
local Anchors = Opera.Anchors
    or require "PNC/Core/PuppetOpera/PNC_PuppetOpera_Anchors"
local Trace = Opera.Trace
    or require "PNC/Core/PuppetOpera/PNC_PuppetOpera_Trace"
local NPCMovement = Opera.NPCMovement
    or require "PNC/PuppetOpera/PNC_PuppetOpera_NPCMovementAdapter"
local NPCAnimation = Opera.NPCAnimation
    or require "PNC/PuppetOpera/PNC_PuppetOpera_NPCAnimationAdapter"

local Authority = Opera.Authority or {}
Opera.Authority = Authority

Authority.Sessions = Authority.Sessions or {}
Authority.ByOwner = Authority.ByOwner or {}
Authority.ByActor = Authority.ByActor or {}
Authority.LastSnapshots = Authority.LastSnapshots or {}
Authority.Serial = tonumber(Authority.Serial) or 0

local Const = PNC.Const or {}
local Registry = PNC.Registry
local Core = PNC.Core

local function now()
    return Core and Core.Now and Core.Now() or 0
end

local function trace(session, eventName, fields, at)
    Trace.Add(session.trace, at or now(), eventName, fields)
end

local function ownerID(player)
    local onlineID
    local username
    if player and player.getOnlineID then
        onlineID = tonumber(player:getOnlineID())
        if onlineID and onlineID >= 0 then
            return "online:" .. tostring(onlineID)
        end
    end
    if player and player.getUsername then
        username = tostring(player:getUsername() or "")
        if username ~= "" then return "user:" .. username end
    end
    return "player:" .. tostring(player or "unknown")
end

local function distanceSquared(left, right)
    if not left or not right or not left.getX or not left.getY
        or not right.getX or not right.getY
    then return nil end
    local dx = tonumber(left:getX()) - tonumber(right:getX())
    local dy = tonumber(left:getY()) - tonumber(right:getY())
    if not dx or not dy then return nil end
    return dx * dx + dy * dy
end

local function inRange(left, right, maximum)
    local distance = distanceSquared(left, right)
    return distance ~= nil and distance <= maximum * maximum
end

local function hasValue(value)
    return value ~= nil
        and (type(value) ~= "string" or value ~= "")
end

local UNSAFE_NPC_ACTION_STATES = {
    attack = true,
    ["attack-network"] = true,
    lunge = true,
    lungenetwork = true,
    bumped = true,
    climbfence = true,
    climbwindow = true,
    climbwall = true,
    falldown = true,
    getup = true,
    ["getup-fromonback"] = true,
    ["getup-fromonfront"] = true,
    ["getup-fromsitting"] = true,
    onground = true,
    ["onground-ragdoll"] = true,
    staggerback = true,
    ["staggerback-knockeddown"] = true,
    thump = true,
}

local function npcActionState(body)
    if PNC.LiveBodyControl
        and PNC.LiveBodyControl.GetActionStateName
    then
        return string.lower(tostring(
            PNC.LiveBodyControl.GetActionStateName(body) or ""
        ))
    end
    if body and body.getActionStateName then
        return string.lower(tostring(body:getActionStateName() or ""))
    end
    return ""
end

local function unsafeNPCActionState(body)
    return UNSAFE_NPC_ACTION_STATES[npcActionState(body)] == true
end

local function invalidPlayer(player)
    if not player then return "player_missing" end
    if player.isDead and player:isDead() then return "player_dead" end
    if player.getVehicle and player:getVehicle() then
        return "player_in_vehicle"
    end
    if player.isSeatedInVehicle and player:isSeatedInVehicle() then
        return "player_seated"
    end
    if player.isAttacking and player:isAttacking() then
        return "player_in_combat"
    end
    if player.isPerformingAttackAnimation
        and player:isPerformingAttackAnimation()
    then
        return "player_in_combat"
    end
    return nil
end

local function invalidNPC(record, body, activeSession)
    if not record then return "npc_record_missing" end
    if not body then return "npc_body_unavailable" end
    if body.isDead and body:isDead() then return "npc_dead" end
    if body.getVehicle and body:getVehicle() then return "npc_in_vehicle" end
    if body.isSeatedInVehicle and body:isSeatedInVehicle() then
        return "npc_seated"
    end
    if not activeSession and unsafeNPCActionState(body) then
        return "npc_action_state_busy"
    end

    local runtime = record.runtime or {}
    local lease = runtime.puppetOperaLease
    if lease and (not activeSession
        or tostring(lease.sessionId or "")
            ~= tostring(activeSession.sessionId or ""))
    then
        return "npc_owned_by_other_puppet_session"
    end
    if not activeSession then
        if PNC.Compatibility and PNC.Compatibility.ActorOwnership
            and PNC.Compatibility.ActorOwnership.IsForeignOwned
            and PNC.Compatibility.ActorOwnership.IsForeignOwned(body)
        then
            return "npc_owned_by_foreign_mod"
        end
        if PNC.LiveBodyControl
            and PNC.LiveBodyControl.IsPresentationCombatActive
            and PNC.LiveBodyControl.IsPresentationCombatActive(record, now())
        then
            return "npc_in_combat"
        end
        if runtime.target ~= nil or runtime.combatTarget ~= nil then
            return "npc_in_combat"
        end
        if PNC.PathService and PNC.PathService.IsTraversalActive
            and PNC.PathService.IsTraversalActive(record, body)
        then
            return "npc_traversal_active"
        end
        if hasValue(runtime.animationScene)
            or hasValue(runtime.conversationLease)
            or hasValue(runtime.taskLeaseId)
            or hasValue(runtime.orderLeaseId)
        then
            return "npc_behavior_owned"
        end
        if runtime.moveIntent and runtime.moveIntent.kind == "move" then
            return "npc_movement_active"
        end
        if hasValue(runtime.facilityActivity)
            or hasValue(runtime.workOrderId)
            or hasValue(runtime.medicalCare)
            or hasValue(runtime.treatment)
            or hasValue(runtime.roamAmbient)
        then
            return "npc_behavior_owned"
        end
        local roamingSeat = runtime.roamingSeat
        if roamingSeat and (
            tostring(roamingSeat.phase or "idle") ~= "idle"
                or roamingSeat.seating == true
                or roamingSeat.seatEntered == true
        ) then
            return "npc_behavior_owned"
        end
        local path = runtime.pathing
        local navigation = runtime.localNavigation
        if path and (
            path.phase == "requested"
                or path.phase == "active"
                or path.traversalAction ~= nil
        ) then
            return "npc_movement_active"
        end
        if navigation and (
            navigation.nativeActive == true
                or navigation.nativeTraversalState ~= nil
        ) then
            return "npc_movement_active"
        end
        if runtime.followState and runtime.followState.ownerMoving == true then
            return "npc_movement_active"
        end
        if runtime.facilityActivity
            and runtime.facilityActivity.seating == true
        then
            return "npc_facility_seated"
        end
    end
    return nil
end

local function sameNumber(left, right)
    if left == nil or right == nil then return left == right end
    return tonumber(left) == tonumber(right)
end

local function puppetMovementIsSafe(session)
    local actor = session and session.actors
        and session.actors.npc or nil
    local record = actor and actor.record or nil
    local runtime = record and record.runtime or nil
    local intent = runtime and runtime.moveIntent or nil
    if session.phase == Opera.Phases.MOVING then
        local claim = runtime and runtime.puppetOperaMovement or nil
        local expectedReason = "puppet_opera:"
            .. tostring(session.sessionId or "")
        if not claim
            or tostring(claim.sessionId or "")
                ~= tostring(session.sessionId or "")
            or not intent
            or intent.kind ~= "move"
            or tostring(intent.puppetOperaSessionId or "")
                ~= tostring(session.sessionId or "")
            or tostring(intent.reason or "") ~= expectedReason
            or not sameNumber(intent.x, claim.requestedX)
            or not sameNumber(intent.y, claim.requestedY)
            or not sameNumber(intent.z, claim.requestedZ)
        then
            return false, "npc_movement_ownership_lost"
        end
        return true
    end
    if intent and intent.kind == "move" then
        return false, "npc_movement_started_during_scene"
    end
    return true
end

local function debugAllowed(player)
    local router = PNC.ServerCommandRouter
    if not router or type(router.CanUseDebug) ~= "function" then
        return false
    end
    return router.CanUseDebug(player) == true
end

local function sendToClient(player, command, payload)
    if not player then return false end
    local serverRuntime = not isServer or isServer()
    if serverRuntime and sendServerCommand then
        sendServerCommand(player, Const.MODULE, command, payload)
        return true
    end
    if not serverRuntime and triggerEvent then
        triggerEvent("OnServerCommand", Const.MODULE, command, payload)
        return true
    end
    return false
end

local function sendState(session, includeTrace)
    if not session or not session.ownerPlayer then return false end
    return sendToClient(
        session.ownerPlayer,
        Const.CMD_PUPPET_OPERA_STATE,
        Opera.BuildSnapshot(session, includeTrace == true)
    )
end

local function sendError(player, reason, existingSession)
    if not player then return false end
    if existingSession and not existingSession.closed then
        local snapshot = Opera.BuildSnapshot(existingSession, false)
        snapshot.lastError = tostring(reason or "puppet_opera_request_rejected")
        return sendToClient(
            player,
            Const.CMD_PUPPET_OPERA_STATE,
            snapshot
        )
    end
    return sendToClient(player, Const.CMD_PUPPET_OPERA_STATE, {
        phase = Opera.Phases.ABORTED,
        lastError = tostring(reason or "puppet_opera_request_rejected"),
        restored = true,
    })
end

local function setPhase(session, phase, deadline, reason, notify)
    session.phase = phase
    session.phaseDeadline = deadline
    session.updatedAt = now()
    session.revision = (tonumber(session.revision) or 0) + 1
    if reason then session.lastReason = tostring(reason) end
    trace(session, "phase", {
        phase = phase,
        reason = reason,
        revision = session.revision,
    })
    if notify ~= false then sendState(session, false) end
end

local function rememberSnapshot(session, includeTrace)
    Authority.LastSnapshots[session.ownerId] = Opera.BuildSnapshot(
        session,
        includeTrace == true
    )
end

local function indexSession(session)
    Authority.Sessions[session.sessionId] = session
    Authority.ByOwner[session.ownerId] = session
    Authority.ByActor["player:" .. session.ownerId] = session
    Authority.ByActor[session.npcID] = session
end

local function unindexSession(session)
    if Authority.Sessions[session.sessionId] == session then
        Authority.Sessions[session.sessionId] = nil
    end
    if Authority.ByOwner[session.ownerId] == session then
        Authority.ByOwner[session.ownerId] = nil
    end
    if Authority.ByActor["player:" .. session.ownerId] == session then
        Authority.ByActor["player:" .. session.ownerId] = nil
    end
    if Authority.ByActor[session.npcID] == session then
        Authority.ByActor[session.npcID] = nil
    end
end

local function clearNPCLease(session)
    local actor = session.actors.npc
    local record = actor and actor.record or nil
    local runtime = record and record.runtime or nil
    local lease = runtime and runtime.puppetOperaLease or nil
    if lease and tostring(lease.sessionId or "")
        == tostring(session.sessionId or "")
    then
        runtime.puppetOperaLease = nil
    end
end

local function releaseActors(session)
    local actor = session.actors.npc
    if actor then
        if actor.animationOwned
            or NPCAnimation.IsOwned(actor.body, session.sessionId)
        then
            NPCAnimation.Release(session, actor)
        end
        if actor.movementOwned
            or NPCMovement.IsOwned(actor.record, session.sessionId)
        then
            NPCMovement.Release(session, actor)
        end
        clearNPCLease(session)
    end
end

local function closeSession(session, finalPhase, reason, errorText)
    if not session or session.closed then return false end
    session.closed = true
    session.stopReason = reason and tostring(reason) or nil
    session.lastError = errorText and tostring(errorText) or session.lastError
    setPhase(session, Opera.Phases.STOPPING, now() + 1000, reason, true)
    trace(session, "release_begin", { reason = reason, error = errorText })
    releaseActors(session)
    session.restored = true
    session.updatedAt = now()
    session.phase = finalPhase
    session.phaseDeadline = nil
    session.revision = (tonumber(session.revision) or 0) + 1
    trace(session, "session_closed", {
        phase = finalPhase,
        reason = reason,
        error = errorText,
    })
    rememberSnapshot(session, true)
    unindexSession(session)
    sendState(session, true)
    return true
end

local function abortSession(session, reason)
    trace(session, "abort", { reason = reason })
    return closeSession(session, Opera.Phases.ABORTED, reason, reason)
end

local function resolveNPC(npcID)
    local id = tostring(npcID or "")
    if id == "" or not Registry then return nil, nil, "npc_id_missing" end
    local record = Registry.Get and Registry.Get(id) or nil
    local body = Registry.GetLiveZombie and Registry.GetLiveZombie(id) or nil
    if not record then return nil, nil, "npc_not_registered" end
    if not body then return record, nil, "npc_not_live" end
    return record, body, nil
end

local function validatePlan(plan)
    if type(plan) ~= "table" or type(plan.actors) ~= "table" then
        return false, "anchor_plan_missing"
    end
    if type(getCell) ~= "function" then return true end
    local cell = getCell()
    if not cell or not cell.getGridSquare then return true end
    local actorID
    local target
    for actorID, target in pairs(plan.actors) do
        if not cell:getGridSquare(target.x, target.y, target.z) then
            return false, "anchor_square_unloaded:" .. tostring(actorID)
        end
    end
    return true
end

local function supportedActors(blueprint)
    local actorID
    local definition
    for actorID, definition in pairs(blueprint.actors or {}) do
        if definition.kind ~= "local_player"
            and definition.kind ~= "nearby_live_npc"
        then
            return false, "actor_kind_not_supported:" .. tostring(actorID)
        end
    end
    return true
end

local function makeSession(player, blueprint, record, body, plan, loopEnabled)
    Authority.Serial = Authority.Serial + 1
    local timestamp = now()
    local sessionID = "puppet:" .. tostring(timestamp) .. ":"
        .. tostring(Authority.Serial)
    local id = ownerID(player)
    local session = Opera.NewSession(
        sessionID,
        id,
        blueprint,
        timestamp,
        loopEnabled == true and blueprint.playback.allowLoop == true
    )
    session.ownerPlayer = player
    session.npcID = tostring(record.id)
    session.playerBody = player
    session.plan = plan
    session.actors.player = {
        id = "player",
        kind = "local_player",
        label = blueprint.actors.player.label,
        anchor = blueprint.actors.player.anchor,
        target = plan.actors.player,
        body = player,
        state = "pending",
        arrived = false,
        facing = false,
        movementOwned = false,
        animationOwned = false,
    }
    session.actors.npc = {
        id = "npc",
        kind = "nearby_live_npc",
        label = blueprint.actors.npc.label,
        anchor = blueprint.actors.npc.anchor,
        target = plan.actors.npc,
        record = record,
        body = body,
        state = "pending",
        arrived = false,
        facing = false,
        movementOwned = false,
        animationOwned = false,
    }
    record.runtime = record.runtime or {}
    record.runtime.puppetOperaLease = {
        sessionId = session.sessionId,
        ownerId = session.ownerId,
        expiresAt = timestamp + Opera.Config.leaseDurationMs,
    }
    trace(session, "session_created", {
        blueprint = blueprint.id,
        npc = session.npcID,
        loop = session.loopEnabled,
    }, timestamp)
    return session
end

local function startSession(player, args)
    local blueprintID = tostring(args.blueprintId or "social.kiss_test")
    local blueprint = Blueprints.Get(blueprintID)
    local candidate
    local candidateReason
    local current = Authority.ByOwner[ownerID(player)]
    local record
    local body
    local reason
    local plan
    local planOK
    local actorOK
    if current then return false, "owner_session_already_active" end
    if not blueprint then return false, "blueprint_not_found" end
    -- A builder draft contains only declarative data.  Normalize it again on
    -- the server and never trust client coordinates or executable values.
    if type(args.definition) == "table" then
        candidate, candidateReason = Blueprints.Normalize(
            blueprintID,
            args.definition
        )
        if not candidate then
            return false, "blueprint_definition_invalid:" .. tostring(candidateReason)
        end
        blueprint = candidate
    end
    local runtimeOK
    runtimeOK, reason = Blueprints.ValidateRuntime(blueprint)
    if not runtimeOK then return false, reason end
    actorOK, reason = supportedActors(blueprint)
    if not actorOK then return false, reason end
    reason = invalidPlayer(player)
    if reason then return false, reason end
    record, body, reason = resolveNPC(args.npcID)
    if not body then return false, reason end
    reason = invalidNPC(record, body, nil)
    if reason then return false, reason end
    if not inRange(player, body, 12) then return false, "npc_out_of_range" end
    if Authority.ByActor[tostring(record.id)] then
        return false, "npc_session_already_active"
    end
    plan, reason = Anchors.BuildPlan(blueprint, player)
    if not plan then return false, reason end
    planOK, reason = validatePlan(plan)
    if not planOK then return false, reason end

    local session = makeSession(
        player,
        blueprint,
        record,
        body,
        plan,
        args.loop == true
    )
    indexSession(session)
    setPhase(session, Opera.Phases.ACQUIRING, now() + 1500, "acquiring", false)
    local accepted
    accepted, reason = NPCMovement.Start(session, session.actors.npc)
    if not accepted then
        clearNPCLease(session)
        unindexSession(session)
        return false, reason or "npc_movement_start_failed"
    end
    session.actors.npc.state = "moving"
    session.actors.npc.movementOwned = true
    setPhase(
        session,
        Opera.Phases.MOVING,
        now() + Opera.Config.movementTimeoutMs,
        "movement_started",
        true
    )
    return true, session
end

local function refreshLease(session, timestamp)
    local record = session.actors.npc.record
    local runtime = record and record.runtime or nil
    local lease = runtime and runtime.puppetOperaLease or nil
    if not lease or tostring(lease.sessionId or "")
        ~= tostring(session.sessionId or "")
    then
        return false
    end
    lease.expiresAt = timestamp + Opera.Config.leaseDurationMs
    return true
end

local function activeSafety(session, timestamp)
    local playerReason = invalidPlayer(session.playerBody)
    if playerReason then return false, playerReason end
    local actor = session.actors.npc
    local live = Registry and Registry.GetLiveZombie
        and Registry.GetLiveZombie(session.npcID) or nil
    if live ~= actor.body then return false, "npc_body_changed" end
    local reason = invalidNPC(actor.record, actor.body, session)
    if reason then return false, reason end
    if PNC.LiveBodyControl
        and PNC.LiveBodyControl.IsSeated
        and PNC.LiveBodyControl.IsSeated(actor.record)
    then
        return false, "npc_became_seated"
    end
    local movementSafe
    movementSafe, reason = puppetMovementIsSafe(session)
    if not movementSafe then return false, reason end
    if unsafeNPCActionState(actor.body)
        and not NPCAnimation.IsOwned(actor.body, session.sessionId)
    then
        return false, "npc_action_state_interrupted"
    end
    if PNC.PathService and PNC.PathService.IsTraversalActive
        and PNC.PathService.IsTraversalActive(actor.record, actor.body)
    then
        return false, "npc_traversal_started"
    end
    if PNC.LiveBodyControl
        and PNC.LiveBodyControl.IsPresentationCombatActive
        and PNC.LiveBodyControl.IsPresentationCombatActive(
            actor.record,
            timestamp
        )
    then
        return false, "npc_entered_combat"
    end
    local runtime = actor.record and actor.record.runtime or nil
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
            return false, "npc_entered_combat"
        end
        return false, "npc_behavior_ownership_lost"
    end
    if runtime and runtime.followState
        and runtime.followState.ownerMoving == true
    then
        return false, "npc_movement_ownership_lost"
    end
    if not inRange(session.playerBody, actor.body, 20) then
        return false, "actors_out_of_range"
    end
    if not refreshLease(session, timestamp) then
        return false, "npc_session_lease_lost"
    end
    return true
end

local function moveToFacing(session, timestamp)
    local actor = session.actors.npc
    if actor.movementOwned then NPCMovement.Release(session, actor) end
    actor.state = "facing"
    actor.lastReason = "movement_barrier_complete"
    setPhase(
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
    session.playerBeatStarted = false
    session.playerBeatFinished = false
    session.npcBeatFinished = false
    session.beatRevision = nil
    setPhase(
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
    session.playerBeatStarted = false
    session.playerBeatFinished = false
    session.npcBeatFinished = false
    setPhase(
        session,
        Opera.Phases.PLAYING,
        session.beatStartAt + tonumber(beat.durationMs or 900)
            + Opera.Config.beatGraceMs,
        "beat_prepared",
        false
    )
    session.beatRevision = session.revision
    sendState(session, false)
    return true
end

local function beatFinished(session, timestamp)
    local actor = session.actors.npc
    if actor.animationOwned then NPCAnimation.Release(session, actor) end
    actor.animationOwned = false
    session.npcBeatFinished = true
    trace(session, "beat_finished", {
        beat = session.blueprint.beats[session.beatIndex].id,
        iteration = session.iteration,
    }, timestamp)
    if not session.loopEnabled then
        return closeSession(session, Opera.Phases.COMPLETED, "playback_complete")
    end
    session.beatIndex = session.beatIndex + 1
    if session.beatIndex > #session.blueprint.beats then
        session.beatIndex = 1
        session.iteration = session.iteration + 1
    end
    session.actors.player.facing = false
    session.actors.npc.facing = false
    scheduleBeat(session, timestamp)
    return true
end

local function pumpMoving(session, timestamp)
    local actor = session.actors.npc
    local ok
    local reason
    ok, reason = NPCMovement.Observe(session, actor)
    if not ok then return false, reason end
    if actor.arrived and session.actors.player.arrived then
        moveToFacing(session, timestamp)
    end
    return true
end

local function pumpFacing(session, timestamp)
    local playerActor = session.actors.player
    local npcActor = session.actors.npc
    local target
    if not npcActor.body.faceLocation then
        return false, "npc_facing_api_unavailable"
    end
    target = Anchors.WorldPoint(playerActor.target)
    if not target then return false, "npc_facing_target_unavailable" end
    npcActor.body:faceLocation(target.x, target.y)
    npcActor.facing = Anchors.IsFacing(npcActor.body, playerActor.target, 0.70)
    if npcActor.facing and playerActor.facing then
        scheduleBeat(session, timestamp)
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
    local actor = session.actors.npc
    local accepted
    local status
    local ok
    local reason
    if not session.beatStartedAt then
        if timestamp < tonumber(session.beatStartAt or 0) then
            return true
        end
        session.beatStartedAt = timestamp
        accepted, reason = NPCAnimation.Start(session, actor, beat)
        if not accepted then
            return false, reason or "npc_animation_start_failed"
        end
        actor.animationOwned = true
        trace(session, "beat_started", {
            beat = beat.id,
            revision = session.revision,
        }, timestamp)
        sendState(session, false)
    end
    if not session.playerBeatStarted
        and timestamp > session.beatStartedAt + Opera.Config.acknowledgementTimeoutMs
    then
        return false, "player_animation_ack_timeout"
    end
    if actor.animationOwned then
        ok, status = NPCAnimation.Observe(session, actor, beat)
        if not ok then return false, status end
        if status == "finished" then
            session.npcBeatFinished = true
        elseif timestamp < session.phaseDeadline then
            local maintained, maintainReason = NPCAnimation.Maintain(
                session,
                actor,
                beat,
                session.phaseDeadline
            )
            if maintained ~= true then
                return false, maintainReason or "npc_animation_maintain_failed"
            end
        end
    end
    if session.playerBeatFinished and session.npcBeatFinished then
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
        abortSession(session, reason)
        return false
    end
    if session.phase == Opera.Phases.MOVING then
        safe, reason = pumpMoving(session, timestamp)
    elseif session.phase == Opera.Phases.FACING then
        safe, reason = pumpFacing(session, timestamp)
    elseif session.phase == Opera.Phases.READY then
        safe, reason = pumpReady(session, timestamp)
    elseif session.phase == Opera.Phases.PLAYING then
        safe, reason = pumpPlaying(session, timestamp)
    else
        safe = true
    end
    if not safe then
        abortSession(session, reason or "puppet_opera_phase_failed")
        return false
    end
    if session.phaseDeadline and timestamp > session.phaseDeadline
        and session.phase ~= Opera.Phases.PLAYING
    then
        abortSession(session, "phase_timeout:" .. tostring(session.phase))
        return false
    end
    return true
end

function Authority.Pump()
    local timestamp = now()
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

local function ownsRequest(session, player, args)
    if not session or session.ownerPlayer ~= player then
        return false, "session_owner_mismatch"
    end
    if args.sessionId and tostring(args.sessionId) ~= session.sessionId then
        return false, "session_id_mismatch"
    end
    return true
end

function Authority.HandleRequest(player, args)
    args = type(args) == "table" and args or {}
    local id = ownerID(player)
    local session = Authority.ByOwner[id]
    if not debugAllowed(player) then
        sendError(player, "debug_not_authorized", session)
        return false, "debug_not_authorized"
    end
    local action = tostring(args.action or "")
    local accepted
    local reason
    if action == "start" then
        accepted, reason = startSession(player, args)
        if not accepted then
            sendError(player, reason, session)
            return false, reason
        end
        return true, reason
    end
    if action == "replay" then
        if session then
            local npcID = session.npcID
            local loop = session.loopEnabled
            closeSession(session, Opera.Phases.RESTORED, "replay")
            args.npcID = args.npcID or npcID
            args.loop = args.loop == true or loop
        end
        accepted, reason = startSession(player, args)
        if not accepted then
            sendError(player, reason, session)
            return false, reason
        end
        return true, reason
    end
    if action == "stop" then
        accepted, reason = ownsRequest(session, player, args)
        if not accepted then
            sendError(player, reason, session)
            return false, reason
        end
        closeSession(session, Opera.Phases.RESTORED, "user_stop")
        return true, "stopped"
    end
    if action == "snapshot" then
        if session then
            sendState(session, false)
        else
            sendToClient(player, Const.CMD_PUPPET_OPERA_STATE, {
                phase = "idle",
                blueprints = Opera.ListBlueprints(),
                lastSnapshot = Authority.LastSnapshots[id],
            })
        end
        return true, "snapshot_sent"
    end
    if action == "dump_trace" then
        if not session then
            local last = Authority.LastSnapshots[id]
            if last then
                sendToClient(player, Const.CMD_PUPPET_OPERA_TRACE, last)
            else
                sendToClient(player, Const.CMD_PUPPET_OPERA_TRACE, { trace = {} })
            end
            return true, "trace_sent"
        end
        accepted, reason = ownsRequest(session, player, args)
        if not accepted then return false, reason end
        sendToClient(
            player,
            Const.CMD_PUPPET_OPERA_TRACE,
            Opera.BuildSnapshot(session, true)
        )
        return true, "trace_sent"
    end

    if not session then
        sendError(player, "session_missing")
        return false, "session_missing"
    end
    accepted, reason = ownsRequest(session, player, args)
    if not accepted then
        sendError(player, reason)
        return false, reason
    end
    if action == "player_moving" then
        if session.phase ~= Opera.Phases.MOVING
            or tonumber(args.revision) ~= session.revision
        then
            return false, "player_movement_out_of_phase"
        end
        trace(session, "player_moving", { revision = args.revision })
        return true, "player_moving_acknowledged"
    end
    if action == "player_arrived" then
        if session.phase ~= Opera.Phases.MOVING
            or tonumber(args.revision) ~= session.revision
        then
            return false, "player_arrival_out_of_phase"
        end
        local actor = session.actors.player
        if not Anchors.IsAt(
            session.playerBody,
            actor.target,
            session.plan.tolerance
        ) then
            return false, "player_arrival_not_verified"
        end
        actor.arrived = true
        actor.state = "arrived"
        actor.lastReason = "player_arrived_verified"
        trace(session, "player_arrived", { actor = "player" })
        return true, "player_arrival_verified"
    end
    if action == "player_facing" then
        if session.phase ~= Opera.Phases.FACING
            or tonumber(args.revision) ~= session.revision
        then
            return false, "player_facing_out_of_phase"
        end
        local actor = session.actors.player
        if not Anchors.IsFacing(
            session.playerBody,
            session.actors.npc.target,
            0.70
        ) then
            return false, "player_facing_not_verified"
        end
        actor.facing = true
        actor.lastReason = "player_facing_verified"
        trace(session, "player_facing", { actor = "player" })
        return true, "player_facing_verified"
    end
    if action == "player_beat_started" then
        if session.phase ~= Opera.Phases.PLAYING
            or tonumber(args.beatIndex) ~= session.beatIndex
            or tonumber(args.revision) ~= session.beatRevision
        then
            return false, "player_beat_start_out_of_phase"
        end
        session.playerBeatStarted = true
        session.actors.player.animationOwned = true
        trace(session, "player_beat_started", {
            actor = "player",
            beat = session.beatIndex,
        })
        return true, "player_beat_start_verified"
    end
    if action == "player_beat_finished" then
        if session.phase ~= Opera.Phases.PLAYING
            or tonumber(args.beatIndex) ~= session.beatIndex
            or tonumber(args.revision) ~= session.beatRevision
        then
            return false, "player_beat_finish_out_of_phase"
        end
        session.playerBeatFinished = true
        session.actors.player.animationOwned = false
        trace(session, "player_beat_finished", {
            actor = "player",
            beat = session.beatIndex,
        })
        return true, "player_beat_finish_verified"
    end
    if action == "player_cancelled" then
        abortSession(session, tostring(args.reason or "player_cancelled"))
        return true, "session_aborted"
    end
    return false, "puppet_opera_action_unknown"
end

function Authority.GetSessionForOwner(player)
    return Authority.ByOwner[ownerID(player)]
end

if Events and Events.OnTick then
    Events.OnTick.Add(Authority.Pump)
end

if PNC.ServerCommandRouter and PNC.ServerCommandRouter.Register then
    PNC.ServerCommandRouter.Register(
        Const.CMD_PUPPET_OPERA_REQUEST,
        function(player, args)
            return Authority.HandleRequest(player, args)
        end
    )
end

return Authority
