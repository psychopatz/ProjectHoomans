local Core = PNC.Core
local Internal = PNC.ZombieAggro.Internal

local function isForeignOwnedBody(body)
    local ownership = PNC.Compatibility
        and PNC.Compatibility.ActorOwnership or nil
    return ownership
        and ownership.IsForeignOwned
        and ownership.IsForeignOwned(body) == true
        or false
end
Internal.isForeignOwnedBody = isForeignOwnedBody

function Internal.ensureZombieID(zombie)
    local modData
    if not zombie or not zombie.getModData then
        return nil
    end
    modData = zombie:getModData()
    if not modData then
        return nil
    end
    if not modData.PNC_ZombieID or tostring(modData.PNC_ZombieID) == "" then
        modData.PNC_ZombieID = Core.GenerateID("pz")
    end
    return modData.PNC_ZombieID
end

function Internal.getZombieModData(zombie)
    return zombie and zombie.getModData and zombie:getModData() or nil
end

function Internal.rememberZombieAttacker(
    record,
    zombie,
    phase,
    now,
    distSq
)
    local runtime
    local existing
    local zombieId
    local onlineID
    local path2
    if not record or not zombie then return nil end
    now = tonumber(now) or Core.Now()
    distSq = tonumber(distSq) or Core.DistanceSq(
        zombie:getX(),
        zombie:getY(),
        record.x or zombie:getX(),
        record.y or zombie:getY()
    )
    runtime = record.runtime or {}
    record.runtime = runtime
    zombieId = Internal.ensureZombieID(zombie)
    existing = runtime.zombieAttacker
    if existing
        and tostring(existing.zombieId or "")
            ~= tostring(zombieId or "")
        and (now - (tonumber(existing.observedAt) or 0)) < 750
        and (tonumber(existing.distSq) or math.huge) <= distSq
    then
        return existing
    end
    onlineID = zombie.getOnlineID
        and tonumber(zombie:getOnlineID()) or nil
    if onlineID and onlineID < 0 then onlineID = nil end
    path2 = zombie.getPath2 and zombie:getPath2() or nil
    runtime.zombieAttacker = {
        zombieId = zombieId,
        onlineID = onlineID,
        phase = tostring(phase or "pursuit"),
        observedAt = now,
        x = zombie:getX(),
        y = zombie:getY(),
        z = zombie:getZ(),
        distSq = distSq,
        actionState = zombie.getActionStateName
            and tostring(zombie:getActionStateName() or "")
            or "",
        bumpType = zombie.getBumpType
            and tostring(zombie:getBumpType() or "")
            or "",
        path2Active = path2 ~= nil,
    }
    return runtime.zombieAttacker
end
