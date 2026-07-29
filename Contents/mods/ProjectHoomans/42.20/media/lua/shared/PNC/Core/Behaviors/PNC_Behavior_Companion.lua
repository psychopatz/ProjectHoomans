--[[
    PNC Behavior Colonist
    Owns colonist job handlers such as follow, guard, and patrol so those
    rules stay isolated from hostile roaming and combat internals.
]]

PNC = PNC or {}
PNC.BehaviorCompanion = PNC.BehaviorCompanion or {}

local Companion = PNC.BehaviorCompanion
local Core = PNC.Core
local Const = PNC.Const
local Stealth = PNC.Stealth
local Animation = PNC.Animation
local Common = PNC.BehaviorCommon
local Targeting = PNC.BehaviorTargeting
local BehaviorCombat = PNC.BehaviorCombat
local Perception = PNC.Perception
local CombatTactics = PNC.CombatTactics
local Registry = PNC.Registry
local CompanionVehicle = PNC.CompanionVehicle
local TraversalQuery = PNC.TraversalQuery
local Spatial = PNC.SpatialIndex
local Performance = PNC.Performance
local FollowFormationCache = {}

local function getFollowState(record)
    record.runtime = record.runtime or {}
    record.runtime.followState = record.runtime.followState or { mode = "moving" }
    return record.runtime.followState
end

local function setFollowMode(record, mode)
    local state = getFollowState(record)
    local changed = state.mode ~= mode
    state.mode = mode
    return state, changed
end

local function holdAndFaceOwner(record, zombie, owner, mode, reason)
    local _, changed = setFollowMode(record, mode)
    record.activeBehavior = mode == "idle_near_owner" and "FollowOwner:idle" or "FollowOwner:formation_hold"
    Common.ClearCombatTarget(record, reason)
    if not zombie then return true end

    if changed then
        Common.HaltMovement(record, zombie, "follow_hold")
        Animation.Apply(zombie, record, "Idle")
    end
    if PNC.PathService and PNC.PathService.RequestIdleFacing then
        PNC.PathService.RequestIdleFacing(record, zombie, owner:getX(), owner:getY(), "follow_owner")
    elseif zombie.faceThisObject then
        zombie:faceThisObject(owner)
    elseif zombie.faceLocationF then
        zombie:faceLocationF(owner:getX(), owner:getY())
    end
    return true
end

local function normalizeDirection(dx, dy)
    local len = math.sqrt((dx * dx) + (dy * dy))
    if len <= 0.0001 then
        return nil, nil
    end
    return dx / len, dy / len
end

local function resolveOwnerForward(owner)
    local forward
    local fx
    local fy
    if not owner or not owner.getForwardDirection then
        return 0, 1
    end
    forward = owner:getForwardDirection()
    fx = forward and tonumber(forward:getX()) or 0
    fy = forward and tonumber(forward:getY()) or 0
    fx, fy = normalizeDirection(fx, fy)
    if fx and fy then
        return fx, fy
    end
    return 0, 1
end

local function isSameFollowGroup(record, other)
    local otherOrder
    local otherOwnerID
    local recordOwnerID
    if not record or not other or other.alive == false then
        return false
    end
    otherOrder = other.orderSpec or {}
    if tostring(otherOrder.kind or "") ~= Const.ORDER_FOLLOW then
        return false
    end
    otherOwnerID = tonumber(other.ownerOnlineID)
    recordOwnerID = tonumber(record.ownerOnlineID)
    if otherOwnerID ~= nil and recordOwnerID ~= nil then
        return otherOwnerID == recordOwnerID
    end
    return tostring(other.ownerUsername or "") == tostring(record.ownerUsername or "")
end

local function sortFollowerRecords(a, b)
    return tostring(a and a.id or "") < tostring(b and b.id or "")
end

local function resolveFollowOwnerKey(record, owner)
    local onlineID = owner and owner.getOnlineID
        and tonumber(owner:getOnlineID()) or tonumber(record and record.ownerOnlineID)
    if onlineID ~= nil then
        return "id:" .. tostring(onlineID)
    end
    return "user:" .. tostring(
        owner and owner.getUsername and owner:getUsername()
            or record and record.ownerUsername
            or ""
    )
end

local function buildFollowFormation(
    record,
    owner,
    now,
    ownerMoving
)
    local followers = {}
    local slots = {}
    local fx
    local fy
    local i
    if Registry and Registry.ForEach then
        Registry.ForEach(function(other)
            if isSameFollowGroup(record, other) then
                followers[#followers + 1] = other
            end
        end)
    end
    table.sort(followers, sortFollowerRecords)
    for i = 1, #followers do
        slots[tostring(followers[i].id)] = i - 1
    end
    fx, fy = resolveOwnerForward(owner)
    return {
        expiresAt = now + (
            ownerMoving
                and (
                    tonumber(
                        Const.FOLLOW_FORMATION_MOVING_CACHE_MS
                    ) or 200
                )
                or (
                    tonumber(
                        Const.FOLLOW_FORMATION_IDLE_CACHE_MS
                    ) or 1000
                )
        ),
        count = #followers,
        slots = slots,
        forwardX = fx,
        forwardY = fy,
        ownerMoving = ownerMoving == true,
    }
end

local function resolveFollowSlot(
    record,
    owner,
    ownerMoving
)
    local ownerKey
    local cache
    local now
    local slotIndex
    local followerCount
    local fx
    local fy
    local rightX
    local rightY
    local backX
    local backY
    local pairIndex
    local side
    local lateral
    local trailing
    local target
    if not owner then
        return nil
    end
    now = Core.Now()
    ownerKey = resolveFollowOwnerKey(record, owner)
    cache = FollowFormationCache[ownerKey]
    if not cache
        or now >= (tonumber(cache.expiresAt) or 0)
        or cache.slots[tostring(record.id)] == nil
        or ownerMoving == true
            and cache.ownerMoving ~= true
    then
        cache = buildFollowFormation(
            record,
            owner,
            now,
            ownerMoving
        )
        FollowFormationCache[ownerKey] = cache
    end
    slotIndex = tonumber(cache.slots[tostring(record.id)]) or 0
    followerCount = tonumber(cache.count) or 1
    fx = tonumber(cache.forwardX) or 0
    fy = tonumber(cache.forwardY) or 1
    rightX = -fy
    rightY = fx
    backX = -fx
    backY = -fy
    if followerCount <= 1 then
        lateral = 0
        trailing = tonumber(Const.FOLLOW_SLOT_DISTANCE) or 2.25
    else
        pairIndex = math.floor(slotIndex / 2)
        side = (slotIndex % 2 == 0) and -1 or 1
        lateral = side * ((tonumber(Const.FOLLOW_SLOT_LATERAL) or 1.15) + (pairIndex * (tonumber(Const.FOLLOW_SLOT_ROW_LATERAL) or 0.25)))
        trailing = (tonumber(Const.FOLLOW_SLOT_DISTANCE) or 2.25) + (pairIndex * (tonumber(Const.FOLLOW_SLOT_ROW_DISTANCE) or 0.85))
    end
    record.runtime = record.runtime or {}
    target = record.runtime.followSlotTarget or {}
    record.runtime.followSlotTarget = target
    target.x = owner:getX() + (backX * trailing) + (rightX * lateral)
    target.y = owner:getY() + (backY * trailing) + (rightY * lateral)
    target.z = owner:getZ()
    target.stopDistance = tonumber(Const.FOLLOW_SLOT_STOP_DISTANCE) or 0.35
    target.personalSpaceCorrection = nil
    -- Formation offsets are useful outdoors but can place the synthetic goal
    -- through an exterior/interior wall in a small room. Keep the slot only
    -- when it resolves to the owner's loaded building and room; otherwise
    -- route to the owner square so the native path exposes the real doorway.
    local cell = getCell and getCell() or nil
    local ownerSquare = owner.getSquare and owner:getSquare() or nil
    local slotSquare = cell and cell.getGridSquare and cell:getGridSquare(
        math.floor(target.x),
        math.floor(target.y),
        math.floor(target.z)
    ) or nil
    if ownerSquare and slotSquare then
        local ownerBuilding = ownerSquare.getBuilding
            and ownerSquare:getBuilding() or nil
        local slotBuilding = slotSquare.getBuilding
            and slotSquare:getBuilding() or nil
        local ownerRoom = ownerSquare.getRoom and ownerSquare:getRoom() or nil
        local slotRoom = slotSquare.getRoom and slotSquare:getRoom() or nil
        if ownerBuilding ~= slotBuilding
            or (ownerBuilding ~= nil and ownerRoom ~= slotRoom)
        then
            target.x = owner:getX()
            target.y = owner:getY()
            target.stopDistance = tonumber(
                Const.FOLLOW_INDOOR_APPROACH_DISTANCE
            ) or 1.6
            target.indoorApproach = true
        else
            target.indoorApproach = nil
        end
    else
        target.indoorApproach = nil
    end
    return target
end

local function isOwnerSpaceCandidate(owner, x, y, z)
    local cell
    local ownerSquare
    local candidateSquare
    local ownerBuilding
    local candidateBuilding
    local ownerRoom
    local candidateRoom
    if TraversalQuery and TraversalQuery.CanOccupy
        and not TraversalQuery.CanOccupy(x, y, z)
    then
        return false
    end
    cell = getCell and getCell() or nil
    ownerSquare = owner and owner.getSquare
        and owner:getSquare() or nil
    candidateSquare = cell and cell.getGridSquare
        and cell:getGridSquare(
            math.floor(x),
            math.floor(y),
            math.floor(z)
        ) or nil
    if not ownerSquare or not candidateSquare then
        return true
    end
    ownerBuilding = ownerSquare.getBuilding
        and ownerSquare:getBuilding() or nil
    candidateBuilding = candidateSquare.getBuilding
        and candidateSquare:getBuilding() or nil
    ownerRoom = ownerSquare.getRoom
        and ownerSquare:getRoom() or nil
    candidateRoom = candidateSquare.getRoom
        and candidateSquare:getRoom() or nil
    return ownerBuilding == candidateBuilding
        and (
            ownerBuilding == nil
            or ownerRoom == candidateRoom
        )
end

local function enforceOwnerPersonalSpace(
    record,
    owner,
    target,
    ownerDist
)
    local minimum = tonumber(
        Const.FOLLOW_PERSONAL_SPACE_MIN
    ) or 1.25
    local radius = tonumber(Const.FOLLOW_SLOT_DISTANCE) or 2.25
    local dx
    local dy
    local fx
    local fy
    local directions
    local direction
    local x
    local y
    local i
    if not record or not owner or not target
        or ownerDist >= minimum
    then
        return target
    end
    dx, dy = normalizeDirection(
        (tonumber(record.x) or owner:getX()) - owner:getX(),
        (tonumber(record.y) or owner:getY()) - owner:getY()
    )
    fx, fy = resolveOwnerForward(owner)
    if not dx or not dy then
        dx = -fx
        dy = -fy
    end
    directions = {
        { x = dx, y = dy },
        { x = -fx, y = -fy },
        { x = -fy, y = fx },
        { x = fy, y = -fx },
        { x = fx, y = fy },
    }
    for i = 1, #directions do
        direction = directions[i]
        x = owner:getX() + direction.x * radius
        y = owner:getY() + direction.y * radius
        if isOwnerSpaceCandidate(owner, x, y, owner:getZ()) then
            target.x = x
            target.y = y
            target.z = owner:getZ()
            target.stopDistance =
                tonumber(Const.FOLLOW_SLOT_STOP_DISTANCE) or 0.35
            target.indoorApproach = nil
            target.personalSpaceCorrection = true
            return target
        end
    end
    return target
end

local function updateOwnerMotionState(record, owner, now)
    local state = getFollowState(record)
    local ownerX = owner:getX()
    local ownerY = owner:getY()
    local elapsed = now - (tonumber(state.ownerSampleAt) or now)
    local moved = false
    local dx
    local dy
    local epsilon = tonumber(Const.FOLLOW_OWNER_MOVE_EPSILON) or 0.08

    if owner.isPlayerMoving and owner:isPlayerMoving() then
        moved = true
    elseif owner.isRunning and owner:isRunning() then
        moved = true
    elseif owner.isSprinting and owner:isSprinting() then
        moved = true
    elseif state.ownerSampleX ~= nil and elapsed > 0 then
        dx = ownerX - state.ownerSampleX
        dy = ownerY - state.ownerSampleY
        moved = (dx * dx) + (dy * dy) >= epsilon * epsilon
    end

    state.ownerMoving = moved
    state.ownerSampleX = ownerX
    state.ownerSampleY = ownerY
    state.ownerSampleAt = now
    return state
end

local function assessFollowHazards(record, zombie, now)
    local runtime = record.runtime or {}
    local cached = runtime.followHazard
    local radius = tonumber(Const.FOLLOW_HORDE_AVOID_RADIUS) or 6.5
    local radiusSq = radius * radius
    local nearDistance = tonumber(Const.FOLLOW_HORDE_NEAR_DISTANCE) or 2.4
    local candidates
    local candidate
    local x = zombie and zombie.getX and zombie:getX()
        or tonumber(record.x) or 0
    local y = zombie and zombie.getY and zombie:getY()
        or tonumber(record.y) or 0
    local z = zombie and zombie.getZ and zombie:getZ()
        or tonumber(record.z) or 0
    local zx
    local zy
    local dx
    local dy
    local distSq
    local distance
    local weight
    local i
    local cacheDx
    local cacheDy

    record.runtime = runtime
    cacheDx = cached and x - (tonumber(cached.x) or x) or 0
    cacheDy = cached and y - (tonumber(cached.y) or y) or 0
    if cached
        and now < (tonumber(cached.expiresAt) or 0)
        and (cacheDx * cacheDx) + (cacheDy * cacheDy) <= 0.25
    then
        return cached
    end

    cached = cached or {}
    cached.x = x
    cached.y = y
    cached.z = z
    cached.count = 0
    cached.nearestDistance = math.huge
    cached.repelX = 0
    cached.repelY = 0
    cached.expiresAt = now
        + (tonumber(Const.FOLLOW_HORDE_SCAN_MS) or 150)
    candidates = Spatial and Spatial.QueryZombies
        and Spatial.QueryZombies(x, y, radius) or {}
    for i = 1, #candidates do
        candidate = candidates[i]
        if candidate
            and (not candidate.isDead or not candidate:isDead())
            and (
                not Core.IsManagedNPCBody
                or not Core.IsManagedNPCBody(candidate)
            )
            and candidate.getX
            and candidate.getY
            and candidate.getZ
            and math.abs(candidate:getZ() - z) < 1
        then
            zx = candidate:getX()
            zy = candidate:getY()
            dx = x - zx
            dy = y - zy
            distSq = (dx * dx) + (dy * dy)
            if distSq <= radiusSq then
                distance = math.sqrt(math.max(0.0025, distSq))
                weight = math.max(0, (radius - distance) / radius)
                cached.count = cached.count + 1
                cached.nearestDistance = math.min(
                    cached.nearestDistance,
                    distance
                )
                cached.repelX = cached.repelX
                    + ((dx / distance) * weight * weight)
                cached.repelY = cached.repelY
                    + ((dy / distance) * weight * weight)
            end
        end
    end
    cached.active = cached.count
            >= (tonumber(Const.FOLLOW_HORDE_AVOID_COUNT) or 3)
        or cached.nearestDistance <= nearDistance
    if cached.count <= 0 then
        cached.nearestDistance = nil
    end
    runtime.followHazard = cached
    return cached
end

local function canUseFollowSteer(record, x, y, z, dirX, dirY)
    if TraversalQuery and TraversalQuery.CanStep
        and not TraversalQuery.CanStep(
            record.x,
            record.y,
            record.z,
            record.x + (dirX * 0.75),
            record.y + (dirY * 0.75),
            z
        )
    then
        return false
    end
    return not TraversalQuery
        or not TraversalQuery.CanOccupy
        or TraversalQuery.CanOccupy(x, y, z)
end

local function resolveHordeAwareFollowTarget(
    record,
    slotTarget,
    slotDist,
    hazard,
    now
)
    local runtime = record.runtime or {}
    local target = runtime.followAvoidanceTarget or {}
    local baseX
    local baseY
    local repelX
    local repelY
    local tangentX
    local tangentY
    local dirX
    local dirY
    local dot
    local distance
    local candidateX
    local candidateY
    local candidateZ

    record.runtime = runtime
    runtime.followAvoidanceTarget = target
    if not slotTarget
        or not hazard
        or hazard.active ~= true
        or slotTarget.indoorApproach == true
        or math.abs((tonumber(slotTarget.z) or record.z) - record.z) >= 1
    then
        target.active = false
        return nil
    end
    if target.active == true
        and now < (tonumber(target.expiresAt) or 0)
        and Core.DistanceSq(
            record.x,
            record.y,
            tonumber(target.x) or record.x,
            tonumber(target.y) or record.y
        ) > 0.49
    then
        return target
    end

    baseX, baseY = normalizeDirection(
        slotTarget.x - record.x,
        slotTarget.y - record.y
    )
    repelX, repelY = normalizeDirection(
        tonumber(hazard.repelX) or 0,
        tonumber(hazard.repelY) or 0
    )
    if not baseX or not repelX then
        target.active = false
        return nil
    end

    dirX, dirY = normalizeDirection(
        baseX + (repelX * math.min(1.35, 0.45 + hazard.count * 0.2)),
        baseY + (repelY * math.min(1.35, 0.45 + hazard.count * 0.2))
    )
    dot = dirX and ((dirX * baseX) + (dirY * baseY)) or -1
    if dot < 0.25 then
        tangentX = -baseY
        tangentY = baseX
        if (tangentX * repelX) + (tangentY * repelY) < 0 then
            tangentX = -tangentX
            tangentY = -tangentY
        end
        dirX, dirY = normalizeDirection(
            (baseX * 0.38) + (tangentX * 0.92),
            (baseY * 0.38) + (tangentY * 0.92)
        )
    end
    if not dirX then
        target.active = false
        return nil
    end

    distance = math.min(
        tonumber(Const.FOLLOW_HORDE_STEER_DISTANCE) or 3.4,
        math.max(1.4, tonumber(slotDist) or 1.4)
    )
    candidateZ = tonumber(slotTarget.z) or record.z
    candidateX = record.x + (dirX * distance)
    candidateY = record.y + (dirY * distance)
    if not canUseFollowSteer(
        record,
        candidateX,
        candidateY,
        candidateZ,
        dirX,
        dirY
    ) then
        -- The opposite side still makes forward progress toward the owner.
        dirX, dirY = normalizeDirection(
            (baseX * 0.38) + (baseY * 0.92),
            (baseY * 0.38) - (baseX * 0.92)
        )
        candidateX = record.x + (dirX * distance)
        candidateY = record.y + (dirY * distance)
        if not canUseFollowSteer(
            record,
            candidateX,
            candidateY,
            candidateZ,
            dirX,
            dirY
        ) then
            target.active = false
            return nil
        end
    end

    target.x = candidateX
    target.y = candidateY
    target.z = candidateZ
    target.stopDistance = 0.55
    target.active = true
    target.avoidance = true
    target.hazardCount = hazard.count
    target.expiresAt = now
        + (tonumber(Const.FOLLOW_HORDE_STEER_MS) or 350)
    return target
end

local function tryEngageTarget(record, zombie)
    if tostring(record.attackType or Const.ATTACK_TYPE_AUTO or "auto")
        == tostring(Const.ATTACK_TYPE_NONE or "none")
    then
        return false
    end
    local target = Targeting.ResolveCompanionEngageTarget(record)
    if not target then
        return false
    end
    record.runtime.target = target
    if Stealth and Stealth.SuspendForCombat then
        Stealth.SuspendForCombat(record, "combat_target")
    else
        record.runtime.stealthActive = false
    end
    BehaviorCombat.TickEngage(record, zombie, target)
    return true
end

local function tryAvoidThreat(record, zombie)
    local threat
    local moved
    local reason
    if tostring(record.attackType or Const.ATTACK_TYPE_AUTO or "auto")
        ~= tostring(Const.ATTACK_TYPE_NONE or "none")
    then
        return false
    end
    Common.ClearCombatTarget(record, "attack_disabled", zombie)
    threat = Perception and Perception.ResolveCompanionTarget
        and Perception.ResolveCompanionTarget(record) or nil
    if not threat or not CombatTactics or not CombatTactics.AvoidThreat then
        return false
    end
    moved, reason = CombatTactics.AvoidThreat(record, zombie, threat)
    if moved then
        record.activeBehavior = "AvoidThreat:no_attack"
        Common.SetCombatDebug(
            record,
            nil,
            reason or "companion_avoiding_threat",
            "none",
            "holstered"
        )
        return true
    end
    return false
end

local function tryRespondToThreat(record, zombie)
    if tryAvoidThreat(record, zombie) then return true end
    return tryEngageTarget(record, zombie)
end

local function shouldScanFollowThreat(
    record,
    now,
    active
)
    local runtime = record.runtime or {}
    local state
    local interval = active
        and (
            tonumber(Const.FOLLOW_THREAT_ACTIVE_SCAN_MS)
                or 150
        )
        or (
            tonumber(Const.FOLLOW_THREAT_IDLE_SCAN_MS)
                or 500
        )
    record.runtime = runtime
    state = getFollowState(record)
    if runtime.target ~= nil then return true end
    if now < (tonumber(state.nextThreatScanAt) or 0) then
        return false
    end
    state.nextThreatScanAt = now + interval
    if Performance then
        Performance.Count("follow.threatScans", 1)
    end
    return true
end

local function tickFollowOwner(record, zombie)
    local owner = Common.GetOwner(record)
    local now = Core.Now and Core.Now() or 0
    local ownerVehicle
    local vehicleHandled
    local vehicleReason
    local ownerDist
    local slotTarget
    local slotDist
    local moveMode
    local followState
    local hazard
    local moveTarget
    local prioritizeOwner
    local hordeCount
    if Stealth and Stealth.UpdateFollowState then
        Stealth.UpdateFollowState(record, owner)
    end
    if not owner then
        if CompanionVehicle and CompanionVehicle.IsPassenger
            and CompanionVehicle.IsPassenger(record)
            and CompanionVehicle.Tick
        then
            CompanionVehicle.Tick(record, zombie, nil)
        end
        setFollowMode(record, "returning_to_anchor")
        if Stealth and Stealth.Clear then
            Stealth.Clear(record, "owner_missing")
        end
        Common.ClearCombatTarget(record, "owner_missing_return_anchor")
        Common.MoveRecord(record, zombie, record.anchorX, record.anchorY, record.anchorZ, "walk", 0.8, "owner_missing_return_anchor")
        return true
    end

    if record.ownerUsername ~= owner:getUsername() then
        record.ownerUsername = owner:getUsername()
        if PNC.Registry and PNC.Registry.MarkDirty then
            PNC.Registry.MarkDirty(record, "owner")
        end
    end
    record.ownerOnlineID = owner:getOnlineID()
    followState = updateOwnerMotionState(record, owner, now)
    -- A follower may still be inside its formation tolerance when the owner
    -- first moves. End ambient presentation immediately instead of waiting
    -- for MoveRecord to be requested several ticks later.
    if followState.ownerMoving == true
        and PNC.AnimationScenes
        and PNC.AnimationScenes.Interrupt
    then
        PNC.AnimationScenes.Interrupt(
            record,
            zombie,
            "movement"
        )
    end
    ownerVehicle = owner.getVehicle and owner:getVehicle() or nil
    if CompanionVehicle and CompanionVehicle.Tick then
        vehicleHandled, vehicleReason = CompanionVehicle.Tick(record, zombie, owner)
        if vehicleHandled then
            setFollowMode(
                record,
                CompanionVehicle.IsPassenger and CompanionVehicle.IsPassenger(record)
                    and "vehicle_passenger"
                    or "vehicle_disembark"
            )
            return true
        end
    end
    -- A companion trying to catch its owner's car should not abandon that
    -- task for opportunistic combat. When no seat exists, it waits instead of
    -- repeatedly pathing into the occupied vehicle.
    if ownerVehicle and vehicleReason == "vehicle_full" then
        setFollowMode(record, "vehicle_full")
        record.activeBehavior = "FollowOwner:vehicle_full"
        Common.ClearCombatTarget(record, "vehicle_full", zombie)
        Common.HaltMovement(record, zombie, "vehicle_full")
        return true
    end
    ownerDist = Core.Distance(record.x, record.y, owner:getX(), owner:getY())
    if followState.ownerMoving == true
        or ownerDist >= (
            tonumber(Const.FOLLOW_WALK_DISTANCE) or 4
        )
    then
        hazard = assessFollowHazards(record, zombie, now)
    else
        record.runtime.followHazard =
            record.runtime.followHazard or {}
        hazard = record.runtime.followHazard
        hazard.count = 0
        hazard.active = false
        hazard.nearestDistance = nil
        hazard.expiresAt = 0
    end
    hordeCount = tonumber(hazard and hazard.count) or 0
    prioritizeOwner = followState.ownerMoving == true
        and (
            ownerDist >= (
                tonumber(Const.FOLLOW_COMBAT_LEASH_DISTANCE) or 5.5
            )
            or hordeCount
                >= (tonumber(Const.FOLLOW_HORDE_AVOID_COUNT) or 3)
        )
    if not ownerVehicle
        and not prioritizeOwner
        and shouldScanFollowThreat(
            record,
            now,
            followState.ownerMoving == true
                or ownerDist >= (
                    tonumber(Const.FOLLOW_WALK_DISTANCE)
                        or 4
                )
        )
        and tryRespondToThreat(record, zombie)
    then
        setFollowMode(record, "combat")
        return true
    end
    slotTarget = resolveFollowSlot(
        record,
        owner,
        followState.ownerMoving == true
    )
    slotTarget = enforceOwnerPersonalSpace(
        record,
        owner,
        slotTarget,
        ownerDist
    )
    slotDist = slotTarget
        and Core.Distance(
            record.x,
            record.y,
            slotTarget.x,
            slotTarget.y
        )
        or ownerDist
    moveTarget = resolveHordeAwareFollowTarget(
        record,
        slotTarget,
        slotDist,
        hazard,
        now
    ) or slotTarget
    if moveTarget == slotTarget
        and slotDist <= (
            slotTarget and slotTarget.stopDistance
                or Const.FOLLOW_DISTANCE
        )
        and math.abs((slotTarget and slotTarget.z or owner:getZ()) - record.z) < 1
    then
        return holdAndFaceOwner(
            record,
            zombie,
            owner,
            "formation_hold",
            record.runtime.stealthActive and "holding_follow_stealth" or "holding_follow_position"
        )
    end
    setFollowMode(record, "moving")
    record.activeBehavior = "FollowOwner:moving"
    moveMode = Stealth
        and Stealth.ResolveFollowMoveMode
        and Stealth.ResolveFollowMoveMode(
            record,
            owner,
            ownerDist,
            slotDist,
            hazard.count
        )
        or (
            ownerDist >= (
                tonumber(Const.FOLLOW_WALK_DISTANCE)
                    or tonumber(Const.FOLLOW_RUN_DISTANCE)
                    or 4
            )
            and "run"
            or "walk"
        )
    Common.ClearCombatTarget(
        record,
        moveTarget and moveTarget.avoidance
            and "following_owner_horde_avoidance"
            or (
                moveMode == "sneak"
                and "following_owner_sneak"
                or ("following_owner_" .. tostring(moveMode))
            )
    )
    Common.MoveRecord(
        record,
        zombie,
        moveTarget and moveTarget.x or owner:getX(),
        moveTarget and moveTarget.y or owner:getY(),
        moveTarget and moveTarget.z or owner:getZ(),
        moveMode,
        moveTarget and moveTarget.stopDistance or Const.FOLLOW_DISTANCE,
        moveTarget and moveTarget.avoidance
            and "follow_owner_horde_avoidance"
            or (
                moveMode == "sneak"
                and "follow_owner_sneak"
                or ("follow_owner_" .. tostring(moveMode))
            )
    )
    return true
end

local function tickGuardAnchor(record, zombie)
    local order = record.orderSpec or {}
    if tryRespondToThreat(record, zombie) then
        return true
    end
    Common.ClearCombatTarget(record, "guarding_anchor")
    Common.MoveRecord(
        record,
        zombie,
        tonumber(order.x) or record.anchorX,
        tonumber(order.y) or record.anchorY,
        tonumber(order.z) or record.anchorZ,
        "walk",
        Const.GUARD_RADIUS,
        "guard_anchor"
    )
    return true
end

local function tickPatrolRoute(record, zombie)
    local order = record.orderSpec or {}
    local patrolPoints
    local point
    if tryRespondToThreat(record, zombie) then
        return true
    end
    patrolPoints = order.points or record.patrolPoints or {}
    if #patrolPoints <= 0 then
        Common.ClearCombatTarget(record, "patrol_missing_points")
        Common.MoveRecord(record, zombie, record.anchorX, record.anchorY, record.anchorZ, "walk", 0.8, "patrol_missing_points")
        return true
    end
    record.patrolIndex = record.patrolIndex or 1
    point = patrolPoints[record.patrolIndex]
    if point and Core.Distance(record.x, record.y, point.x, point.y) <= Const.PATROL_REACHED_DISTANCE then
        record.patrolIndex = record.patrolIndex + 1
        if record.patrolIndex > #patrolPoints then
            record.patrolIndex = 1
        end
        if PNC.Registry and PNC.Registry.MarkDirty then
            PNC.Registry.MarkDirty(record, "patrol")
        end
        point = patrolPoints[record.patrolIndex]
    end
    if point then
        Common.ClearCombatTarget(record, "patrolling")
        Common.MoveRecord(record, zombie, point.x, point.y, point.z, "walk", Const.PATROL_REACHED_DISTANCE, "patrol_route")
    end
    return true
end

function Companion.Tick(record, zombie, job)
    if job == "FollowOwner" then
        return tickFollowOwner(record, zombie)
    end
    if job == "GuardAnchor" then
        return tickGuardAnchor(record, zombie)
    end
    if job == "PatrolRoute" then
        return tickPatrolRoute(record, zombie)
    end
    return false
end
