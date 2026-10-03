if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Puppet Opera authority admission and movement guards.
-- The provider keeps shared ownership checks cohesive while preserving the
-- Authority.Internal names consumed by admission and runtime spokes.

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}

local Opera = PNC.PuppetOpera
local Authority = Opera.Authority or {}
Opera.Authority = Authority
local Internal = Authority.Internal or {}
Authority.Internal = Internal

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

local function managedBumpCanBeReleased(body)
    local modData = body and body.getModData and body:getModData() or nil
    if npcActionState(body) ~= "bumped"
        or not modData
        or modData.PNC_BumpActionLease ~= true
    then
        return false
    end
    return true
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


Internal.distanceSquared = distanceSquared
Internal.inRange = inRange
Internal.hasValue = hasValue
Internal.npcActionState = npcActionState
Internal.npcActionContextState = npcActionContextState
Internal.unsafeNPCActionState = unsafeNPCActionState
Internal.nonCombatBumpCanBeReleased = managedBumpCanBeReleased
Internal.managedBumpCanBeReleased = managedBumpCanBeReleased
Internal.actorFailureReason = actorFailureReason
Internal.invalidPlayer = invalidPlayer
Internal.invalidNPC = invalidNPC
Internal.puppetMovementIsSafe = puppetMovementIsSafe

return true

