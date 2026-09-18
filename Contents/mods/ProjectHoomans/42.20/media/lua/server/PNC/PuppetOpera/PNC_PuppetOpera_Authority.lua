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
local NPCOverride = Opera.Override
    or require "PNC/PuppetOpera/PNC_PuppetOpera_OverrideAdapter"

local Authority = Opera.Authority or {}
Opera.Authority = Authority
local Internal = Authority.Internal or {}
Authority.Internal = Internal

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

local function npcActionContextState(body)
    if PNC.LiveBodyControl
        and PNC.LiveBodyControl.GetActionContextStateName
    then
        return string.lower(tostring(
            PNC.LiveBodyControl.GetActionContextStateName(body) or ""
        ))
    end
    if body and body.getCurrentActionContextStateName then
        return string.lower(tostring(
            body:getCurrentActionContextStateName() or ""
        ))
    end
    return npcActionState(body)
end

local function unsafeNPCActionState(body)
    return UNSAFE_NPC_ACTION_STATES[npcActionState(body)] == true
end

local function nonCombatBumpCanBeReleased(body)
    local modData = body and body.getModData and body:getModData() or nil
    return npcActionState(body) == "bumped"
        and modData
        and modData.PNC_BumpActionLease == true
        and modData.PNC_BumpNonCombat == true
end

local function actorFailureReason(reason, actorID, body)
    if not reason then return nil end
    local value = tostring(reason)
    if actorID then value = value .. ":" .. tostring(actorID) end
    if reason == "npc_action_state_busy"
        or reason == "npc_action_state_interrupted"
    then
        value = value .. ":state=" .. tostring(npcActionState(body) or "")
            .. ":context=" .. tostring(npcActionContextState(body) or "")
    end
    return value
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

local function puppetMovementIsSafe(session, actor)
    if not actor or actor.kind ~= "nearby_live_npc" then return true end
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
    for actorID, actor in pairs(session.actors or {}) do
        if actor.kind == "nearby_live_npc" and actor.npcID then
            Authority.ByActor[tostring(actor.npcID)] = session
        elseif actor.kind == "local_player" then
            Authority.ByActor["player:" .. session.ownerId] = session
        end
    end
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
    for _, actor in pairs(session.actors or {}) do
        if actor.kind == "nearby_live_npc" and actor.npcID
            and Authority.ByActor[tostring(actor.npcID)] == session
        then
            Authority.ByActor[tostring(actor.npcID)] = nil
        end
    end
end

local function clearNPCLease(session, actor)
    actor = actor or session and session.actors and session.actors.npc
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
    for _, actor in pairs(session.actors or {}) do
        if actor.kind == "nearby_live_npc" then
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
            if actor.overrideOwned
                or NPCOverride.IsOwned(actor.record, session.sessionId)
            then
                NPCOverride.Release(session, actor)
            end
            clearNPCLease(session, actor)
        end
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

-- Composition handoff for the runtime and request spokes. These references
-- are intentionally internal; the public surface remains Authority.
Internal.Opera = Opera
Internal.Blueprints = Blueprints
Internal.Anchors = Anchors
Internal.Trace = Trace
Internal.NPCMovement = NPCMovement
Internal.NPCAnimation = NPCAnimation
Internal.NPCOverride = NPCOverride
Internal.Registry = Registry
Internal.Core = Core
Internal.Const = Const
Internal.now = now
Internal.trace = trace
Internal.ownerID = ownerID
Internal.distanceSquared = distanceSquared
Internal.inRange = inRange
Internal.hasValue = hasValue
Internal.npcActionState = npcActionState
Internal.npcActionContextState = npcActionContextState
Internal.unsafeNPCActionState = unsafeNPCActionState
Internal.nonCombatBumpCanBeReleased = nonCombatBumpCanBeReleased
Internal.actorFailureReason = actorFailureReason
Internal.invalidPlayer = invalidPlayer
Internal.invalidNPC = invalidNPC
Internal.puppetMovementIsSafe = puppetMovementIsSafe
Internal.debugAllowed = debugAllowed
Internal.sendToClient = sendToClient
Internal.sendState = sendState
Internal.sendError = sendError
Internal.setPhase = setPhase
Internal.indexSession = indexSession
Internal.releaseActors = releaseActors
Internal.unindexSession = unindexSession
Internal.closeSession = closeSession
Internal.abortSession = abortSession

require "PNC/PuppetOpera/PNC_PuppetOpera_Authority_Admission"
require "PNC/PuppetOpera/PNC_PuppetOpera_Authority_Runtime"
require "PNC/PuppetOpera/PNC_PuppetOpera_Authority_Requests"
require "PNC/PuppetOpera/PNC_PuppetOpera_Authority_Acknowledgements"



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
