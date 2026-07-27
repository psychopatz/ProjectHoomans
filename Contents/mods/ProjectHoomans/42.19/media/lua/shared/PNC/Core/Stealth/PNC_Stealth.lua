PNC = PNC or {}
PNC.Stealth = PNC.Stealth or {}

local Stealth = PNC.Stealth
local Core = PNC.Core
local Const = PNC.Const
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

function Stealth.ShouldSuppressCompanionCombat(record)
    return Stealth.IsFollowStealthActive(record)
end

function Stealth.ShouldSuppressZombieAggro(record)
    return Stealth.IsFollowStealthActive(record)
end

function Stealth.ResolveFollowMoveMode(record, owner, ownerDist)
    if Stealth.IsFollowStealthActive(record) and isOwnerActuallySneaking(owner, ownerDist) then
        return "sneak"
    end
    if owner and owner.isRunning and owner:isRunning() then
        return "run"
    end
    if owner and owner.isSprinting and owner:isSprinting() then
        return "run"
    end
    if ownerDist >= Const.FOLLOW_RUN_DISTANCE then
        return "run"
    end
    return "walk"
end
