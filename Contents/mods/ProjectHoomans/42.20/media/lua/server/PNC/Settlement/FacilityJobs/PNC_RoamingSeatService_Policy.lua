if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.RoamingSeat
local Internal = Service.Internal or {}
local Core = PNC.Core
local Const = PNC.Const or {}
local Common = PNC.BehaviorCommon
local Jobs = PNC.FacilityJobs
local Resources = PNC.FacilityResources
local Targets = PNC.FacilityInteractionTargets
local Reservations = PNC.FacilityReservations
local Diagnostics = PNC.PerformanceScalingDiagnostics
local ActorControl = PNC.ActorControl
    or require "PNC/Core/ActorControl/PNC_ActorControl"

local function facilityJobs()
    return PNC.FacilityJobs or Jobs
end

local function facilityResources()
    return PNC.FacilityResources or Resources
end

local function interactionTargets()
    return PNC.FacilityInteractionTargets or Targets
end

local function facilityReservations()
    return PNC.FacilityReservations or Reservations
end

local function currentTime(value)
    return tonumber(value) or Core.Now()
end

local function orderKind(record)
    return tostring(record and record.orderSpec
        and record.orderSpec.kind or "")
end

local function isRoamOrder(record)
    local kind = orderKind(record)
    return kind == tostring(Const.ORDER_ROAM or "roam")
end

local function isGuardOrder(record)
    local kind = orderKind(record)
    return kind == tostring(Const.ORDER_GUARD or "guard")
end

local function isSeatOrder(record, state)
    if isRoamOrder(record) then
        return state == nil
            or tostring(state.ownerKind or "") == ""
            or tostring(state.ownerKind or "") == "roam"
    end
    return isGuardOrder(record) and state
        and tostring(state.ownerKind or "") == "guard"
end

local function eachObject(square, visitor)
    local objects = square and square.getObjects
        and square:getObjects() or nil
    if not objects then return end
    if objects.size and objects.get then
        for index = 0, objects:size() - 1 do
            visitor(objects:get(index), index)
        end
        return
    end
    for index = 1, #objects do visitor(objects[index], index) end
end

local function isReserved(resource)
    local reservations = facilityReservations()
    local key = tostring(resource and resource.resourceKey or "")
    return key ~= "" and reservations and reservations.ByResource
        and reservations.ByResource[key] ~= nil
end

local function distanceTo(zombie, x, y)
    return Core.Distance(zombie:getX(), zombie:getY(), x, y)
end

local function hasActivePath(record)
    local runtime = record and record.runtime or nil
    local pathing = runtime and runtime.pathing or nil
    local navigation = runtime and runtime.localNavigation or nil
    if pathing and (
        pathing.traversalAction ~= nil
            or pathing.vanillaFenceAction ~= nil
            or pathing.blockedStepToX ~= nil
            or pathing.phase == "requested"
            or pathing.phase == "active"
            or pathing.phase == "blocked"
    ) then
        return true
    end
    return navigation and navigation.nativeActive == true or false
end

local function canAttempt(record, zombie, roaming, at)
    local runtime = record and record.runtime or nil
    local target = runtime and runtime.target or nil
    if not Core.IsAuthority() or not record or not zombie
        or record.alive == false or not isRoamOrder(record)
        or not roaming or roaming.phase ~= "idle"
    then
        return false
    end
    if ActorControl and ActorControl.IsPuppetOwned
        and ActorControl.IsPuppetOwned(record)
    then
        return false
    end
    if at < (tonumber(roaming.idleSince) or at) + Service.MIN_IDLE_MS then
        return false
    end
    if at < (tonumber(roaming.seatCooldownUntil) or 0) then
        return false
    end
    if runtime and (runtime.facilityActivity or runtime.workOrderId
        or runtime.attackAction or runtime.combatTarget
        or at < (tonumber(runtime.inCombatUntil) or 0))
    then
        return false
    end
    if ActorControl and ActorControl.IsPuppetOwned
        and ActorControl.IsPuppetOwned(record)
    then
        return false
    end
    if type(target) == "table" and target.kind ~= nil then return false end
    return runtime.animationScene == nil and not hasActivePath(record)
end

local function canAttemptGuard(record, zombie, order, at)
    local runtime = record and record.runtime or nil
    local target = runtime and runtime.target or nil
    local anchorX = tonumber(order and order.x)
        or tonumber(record and record.anchorX)
        or tonumber(record and record.x) or 0
    local anchorY = tonumber(order and order.y)
        or tonumber(record and record.anchorY)
        or tonumber(record and record.y) or 0
    local bodyX = zombie and zombie.getX and zombie:getX()
        or record and record.x or 0
    local bodyY = zombie and zombie.getY and zombie:getY()
        or record and record.y or 0
    local stopDistance = tonumber(Const.GUARD_STOP_DISTANCE)
        or tonumber(Const.GUARD_REACHED_DISTANCE) or 0.55
    if not Core.IsAuthority() or not record or not zombie
        or record.alive == false or not isGuardOrder(record)
    then
        return false
    end
    if runtime and (runtime.facilityActivity or runtime.workOrderId
        or runtime.attackAction or runtime.combatTarget
        or runtime.roamingSeat
        or at < (tonumber(runtime.inCombatUntil) or 0))
    then
        return false
    end
    if type(target) == "table" and target.kind ~= nil then return false end
    if runtime.animationScene ~= nil or hasActivePath(record) then
        return false
    end
    local distance = Core.Distance(bodyX, bodyY, anchorX, anchorY)
    return distance <= math.max(0.45, stopDistance)
end

local function idHash(value, modulus)
    local hash = 0
    local text = tostring(value or "npc")
    for index = 1, #text do
        hash = (hash + (string.byte(text, index) or 0) * index)
            % modulus
    end
    return hash
end


Internal.facilityJobs = facilityJobs
Internal.facilityResources = facilityResources
Internal.interactionTargets = interactionTargets
Internal.facilityReservations = facilityReservations
Internal.currentTime = currentTime
Internal.isRoamOrder = isRoamOrder
Internal.isGuardOrder = isGuardOrder
Internal.isSeatOrder = isSeatOrder
Internal.eachObject = eachObject
Internal.isReserved = isReserved
Internal.distanceTo = distanceTo
Internal.hasActivePath = hasActivePath
Internal.canAttempt = canAttempt
Internal.canAttemptGuard = canAttemptGuard
Internal.idHash = idHash
