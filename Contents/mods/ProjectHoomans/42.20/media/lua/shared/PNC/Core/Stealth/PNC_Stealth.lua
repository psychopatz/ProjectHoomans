PNC = PNC or {}
PNC.Stealth = PNC.Stealth or {}

local Stealth = PNC.Stealth
local Core = PNC.Core
local Const = PNC.Const
local Settings = PNC.Sandbox
Stealth.OwnerDiscoveryCache = Stealth.OwnerDiscoveryCache or {}

local function ownerCacheKey(owner)
    local onlineID = owner and owner.getOnlineID and owner:getOnlineID() or nil
    local username = owner and owner.getUsername and owner:getUsername() or nil
    if onlineID ~= nil then return "id:" .. tostring(onlineID) end
    if username and tostring(username) ~= "" then
        return "user:" .. tostring(username)
    end
    return tostring(owner)
end

local function cacheDiscovery(owner, discovered, reason, now)
    Stealth.OwnerDiscoveryCache[ownerCacheKey(owner)] = {
        discovered = discovered == true,
        reason = reason,
        expiresAt = now + (tonumber(Const.STEALTH_DISCOVERY_CACHE_MS) or 200),
    }
    return discovered == true, reason
end

local function logStealthState(record, runtime, reason)
    local stateKey
    if not record or not runtime then
        return
    end
    stateKey = table.concat({
        tostring(runtime.ownerSneaking == true),
        tostring(runtime.stealthActive == true),
        tostring(runtime.stealthBroken == true),
        tostring(reason or runtime.stealthReason or ""),
    }, "|")
    if runtime.lastStealthLogKey == stateKey then
        return
    end
    runtime.lastStealthLogKey = stateKey
    Core.LogRecordDebug(
        record,
        "NPC "
            .. tostring(record.id)
            .. " stealth ownerSneaking="
            .. tostring(runtime.ownerSneaking == true)
            .. " active="
            .. tostring(runtime.stealthActive == true)
            .. " broken="
            .. tostring(runtime.stealthBroken == true)
            .. " reason="
            .. tostring(reason or runtime.stealthReason or "unknown")
    )
end

local function getZombieCandidates(owner)
    local cell
    local zombieList
    local values
    local i
    local radius = tonumber(Const.STEALTH_DISCOVERY_RADIUS) or 12
    if owner and PNC.SpatialIndex and PNC.SpatialIndex.QueryZombies then
        return PNC.SpatialIndex.QueryZombies(
            owner:getX(),
            owner:getY(),
            radius
        )
    end
    if not getCell then
        return {}
    end
    cell = getCell()
    zombieList = cell and cell.getZombieList and cell:getZombieList() or nil
    values = {}
    if zombieList then
        for i = 0, zombieList:size() - 1 do
            values[#values + 1] = zombieList:get(i)
        end
    end
    return values
end

local function resolveOwner(record)
    if not record then
        return nil
    end
    return Core.ResolvePlayerByOnlineID(record.ownerOnlineID) or Core.ResolvePlayerByUsername(record.ownerUsername)
end

function Stealth.ResolveOwner(record)
    return resolveOwner(record)
end

function Stealth.Clear(record, reason)
    local runtime
    if not record then
        return false
    end
    runtime = record.runtime or {}
    record.runtime = runtime
    runtime.ownerSneaking = false
    runtime.stealthActive = false
    runtime.stealthBroken = false
    runtime.stealthReason = reason or "inactive"
    logStealthState(record, runtime, runtime.stealthReason)
    return false
end

function Stealth.IsOwnerDiscovered(owner)
    local zombieList
    local i
    local zombie
    local target
    local distSq
    local canSee
    local canSeeFn
    local now = Core.Now()
    local cached = owner
        and Stealth.OwnerDiscoveryCache[ownerCacheKey(owner)] or nil

    if not owner or owner:isDead() then
        return false, "owner_missing"
    end
    if cached and now < (tonumber(cached.expiresAt) or 0) then
        return cached.discovered == true, cached.reason
    end

    zombieList = getZombieCandidates(owner)
    if #zombieList <= 0 then
        return cacheDiscovery(owner, false, "no_zombies", now)
    end

    for i = #zombieList, 1, -1 do
        zombie = zombieList[i]
        if zombie and (not zombie:isDead()) and (not Core.IsManagedNPCBody(zombie)) and math.abs(zombie:getZ() - owner:getZ()) < 1 then
            target = zombie.getTarget and zombie:getTarget() or nil
            if target == owner then
                return cacheDiscovery(owner, true, "owner_targeted", now)
            end

            distSq = Core.DistanceSq(zombie:getX(), zombie:getY(), owner:getX(), owner:getY())
            if distSq <= (Const.STEALTH_BREAK_CONTACT_DISTANCE * Const.STEALTH_BREAK_CONTACT_DISTANCE) then
                return cacheDiscovery(
                    owner,
                    true,
                    "owner_close_contact",
                    now
                )
            end

            if distSq <= (Const.STEALTH_DISCOVERY_RADIUS * Const.STEALTH_DISCOVERY_RADIUS) and zombie.CanSee then
                canSeeFn = zombie.CanSee
                canSee = canSeeFn and zombie:CanSee(owner) or false
                if canSee == true then
                    return cacheDiscovery(owner, true, "owner_seen", now)
                end
            end
        end
    end

    return cacheDiscovery(owner, false, "owner_hidden", now)
end

local function isOwnerActuallySneaking(owner, ownerDist)
    local sneaking
    if not owner or owner:isDead() then
        return false
    end
    sneaking = owner.isSneaking and owner:isSneaking() or false
    if sneaking ~= true then
        return false
    end
    if owner.isRunning and owner:isRunning() then
        return false
    end
    if owner.isSprinting and owner:isSprinting() then
        return false
    end
    if owner.getVehicle and owner:getVehicle() then
        return false
    end
    if tonumber(ownerDist) and tonumber(ownerDist) > 24 then
        return false
    end
    return true
end

function Stealth.UpdateFollowState(record, owner)
    local runtime
    local ownerSneaking
    local ownerDist
    local discovered
    local reason

    if not record then
        return false
    end

    runtime = record.runtime or {}
    record.runtime = runtime
    owner = owner or resolveOwner(record)
    ownerDist = owner and Core.Distance(record.x, record.y, owner:getX(), owner:getY()) or nil
    ownerSneaking = isOwnerActuallySneaking(owner, ownerDist)

    runtime.ownerSneaking = ownerSneaking
    runtime.ownerDistance = ownerDist
    if (record.orderSpec and record.orderSpec.kind or nil) ~= Const.ORDER_FOLLOW then
        return Stealth.Clear(record, "not_follow_order")
    end
    if not owner or owner:isDead() then
        return Stealth.Clear(record, "owner_missing")
    end
    if not ownerSneaking then
        return Stealth.Clear(record, "owner_not_sneaking")
    end

    discovered, reason = Stealth.IsOwnerDiscovered(owner)
    runtime.stealthBroken = discovered == true
    runtime.stealthActive = discovered ~= true
    runtime.stealthReason = discovered and reason or "follow_stealth"
    logStealthState(record, runtime, runtime.stealthReason)
    return runtime.stealthActive == true
end

function Stealth.IsFollowStealthActive(record)
    local runtime = record and record.runtime or nil
    return runtime and runtime.stealthActive == true and runtime.ownerSneaking == true
end

function Stealth.SuspendForCombat(record, reason)
    local runtime
    if not record then
        return false
    end
    runtime = record.runtime or {}
    record.runtime = runtime
    runtime.stealthActive = false
    runtime.stealthBroken = true
    runtime.stealthReason = reason or "combat_active"
    logStealthState(record, runtime, runtime.stealthReason)
    return true
end

local function applyTravelBodyProtection(record, zombie, active)
    local protectedBySettings = Settings
        and Settings.CanZombieTargetRecord
        and not Settings.CanZombieTargetRecord(record, Core.Now())
        or false
    if zombie and zombie.setZombiesDontAttack then
        zombie:setZombiesDontAttack(active == true or protectedBySettings)
    end
end

local function travelState(record)
    if not record then
        return nil
    end
    record.runtime = record.runtime or {}
    record.runtime.travelStealth = record.runtime.travelStealth or {
        active = false,
        combatActive = false,
        nextScanAt = 0,
        quietUntil = 0,
        reason = "inactive",
    }
    return record.runtime.travelStealth
end

function Stealth.IsTravelStealthActive(record)
    local state = record
        and record.runtime
        and record.runtime.travelStealth
        or nil
    return state ~= nil
        and state.active == true
        and state.combatActive ~= true
end

function Stealth.IsTravelCombatActive(record)
    local state = record
        and record.runtime
        and record.runtime.travelStealth
        or nil
    return state ~= nil and state.combatActive == true
end

function Stealth.ClearTravel(record, reason, zombie)
    local state = travelState(record)
    if not state then
        return false
    end
    state.active = false
    state.combatActive = false
    state.nextScanAt = 0
    state.quietUntil = 0
    state.reason = reason or "inactive"
    applyTravelBodyProtection(record, zombie, false)
    return false
end

function Stealth.SetTravelCombatActive(record, zombie, active)
    local state = travelState(record)
    if not state then
        return false
    end
    state.combatActive = active == true
    state.active = false
    state.nextScanAt = 0
    state.quietUntil = 0
    state.reason = active == true and "travel_combat" or "combat_clear"
    applyTravelBodyProtection(record, zombie, false)
    return state.combatActive
end

function Stealth.UpdateTravelState(record, zombie, now)
    local state = travelState(record)
    local perception
    local nearCount
    local hordeCount
    local danger
    local wasActive
    if not state or not zombie or state.combatActive == true then
        return false
    end
    now = tonumber(now) or Core.Now()
    if now < (tonumber(state.nextScanAt) or 0) then
        return state.active == true
    end
    state.nextScanAt = now
        + (tonumber(Const.LIVE_TRAVEL_STEALTH_SCAN_MS) or 350)
    perception = PNC.Perception
    nearCount = perception
        and perception.CountZombiesInFrame
        and perception.CountZombiesInFrame(
            record,
            tonumber(Const.LIVE_TRAVEL_STEALTH_NEAR_RADIUS) or 7
        )
        or 0
    hordeCount = nearCount > 0 and nearCount
        or (
            perception
            and perception.CountZombiesInFrame
            and perception.CountZombiesInFrame(
                record,
                tonumber(Const.LIVE_TRAVEL_STEALTH_HORDE_RADIUS) or 12
            )
            or 0
        )
    danger = nearCount > 0
        or hordeCount >= (
            tonumber(Const.LIVE_TRAVEL_STEALTH_HORDE_COUNT) or 3
        )
    wasActive = state.active == true
    if danger then
        state.active = true
        state.quietUntil = now
            + (
                tonumber(Const.LIVE_TRAVEL_STEALTH_CLEAR_DELAY_MS)
                or 2500
            )
        state.reason = nearCount > 0
            and "nearby_zombie"
            or "nearby_horde"
    elseif wasActive and now < (tonumber(state.quietUntil) or 0) then
        state.active = true
        state.reason = "quiet_hysteresis"
    else
        state.active = false
        state.quietUntil = 0
        state.reason = "area_clear"
    end
    if state.active then
        if not wasActive
            and PNC.ZombieAggro
            and PNC.ZombieAggro.ClearForNPCBody
        then
            PNC.ZombieAggro.ClearForNPCBody(zombie)
        end
        applyTravelBodyProtection(record, zombie, true)
        record.runtime.combatBlockReason = "travel_stealth_hidden"
    elseif wasActive then
        applyTravelBodyProtection(record, zombie, false)
    end
    return state.active == true
end

function Stealth.ShouldSuppressCompanionCombat(record)
    return Stealth.IsFollowStealthActive(record)
end

function Stealth.ShouldSuppressZombieAggro(record)
    return Stealth.IsFollowStealthActive(record)
        or Stealth.IsTravelStealthActive(record)
end

function Stealth.ResolveFollowMoveMode(
    record,
    owner,
    ownerDist,
    slotDist,
    hazardCount
)
    local runtime = record and record.runtime or {}
    local state = runtime.followState or {}
    local walkDistance = tonumber(Const.FOLLOW_WALK_DISTANCE) or 4
    local enterDistance = tonumber(Const.FOLLOW_RUN_DISTANCE) or 10
    local exitDistance = tonumber(
        Const.FOLLOW_CATCHUP_EXIT_DISTANCE
    ) or 3
    local ownerRunning = owner and (
        (owner.isRunning and owner:isRunning())
        or (owner.isSprinting and owner:isSprinting())
    ) or false
    if record then
        record.runtime = runtime
        runtime.followState = state
    end

    -- Posture follows the owner, while stealth discovery independently
    -- controls aggro/combat suppression. Coupling those two decisions made a
    -- discovered sneaking owner force followers into the wrong walk state.
    if isOwnerActuallySneaking(owner, ownerDist) then
        state.catchingUp = false
        return "sneak"
    end

    local separation = math.max(
        tonumber(ownerDist) or 0,
        tonumber(slotDist) or 0
    )
    if separation >= enterDistance
        or (ownerRunning and separation >= walkDistance)
    then
        state.catchingUp = true
    elseif state.catchingUp == true and separation > exitDistance
    then
        state.catchingUp = true
    else
        state.catchingUp = false
    end
    if state.catchingUp == true then
        return "run"
    end
    return "walk"
end
