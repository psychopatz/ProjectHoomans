-- Native engine movement ownership and body-usefulness leases.

PNC = PNC or {}
PNC.LiveBodyControl = PNC.LiveBodyControl or {}

local LiveBodyControl = PNC.LiveBodyControl
local Core = PNC.Core
local LEASE_KEY = "PNC_NativeMovementLease"
local LEASE_UNTIL_KEY = "PNC_NativeMovementLeaseUntil"

-- Compatibility hook retained for callers from the earlier remote-carrier
-- experiment. IsoZombie.lastRemoteUpdate is a Java field, but assigning it
-- from Kahlua is not a supported bridge and raises an MP runtime error. The
-- carrier lifecycle must be maintained through supported body leases instead.
function LiveBodyControl.RefreshNativeRemoteHeartbeat(zombie)
    return false
end

function LiveBodyControl.IsMultiplayer()
    local world = getWorld and getWorld() or nil
    local gameMode = world and world.getGameMode
        and tostring(world:getGameMode() or "") or ""
    if gameMode == "Multiplayer" then return true end
    return (isClient and isClient() == true)
        or (isServer and isServer() == true)
        or false
end

function LiveBodyControl.SetManagedBodyUseless(
    zombie,
    requestedUseless,
    keepEngineMovementActive
)
    local desiredUseless
    if not zombie or not zombie.setUseless then return false end
    desiredUseless = keepEngineMovementActive ~= true
        and requestedUseless == true
        or false
    if zombie.isUseless and zombie:isUseless() == desiredUseless then
        return desiredUseless
    end
    zombie:setUseless(desiredUseless)
    return desiredUseless
end

function LiveBodyControl.BeginNativeMovementLease(
    zombie,
    leaseKey,
    now,
    durationMs
)
    local modData
    if not zombie or not zombie.getModData then return false end
    now = tonumber(now) or (Core and Core.Now and Core.Now() or 0)
    durationMs = math.max(
        250,
        tonumber(durationMs)
            or tonumber(PNC.Const and PNC.Const.CLIENT_NATIVE_MOVEMENT_LEASE_MS)
            or 750
    )
    modData = zombie:getModData()
    if not modData then return false end
    modData[LEASE_KEY] = tostring(leaseKey or "native_path")
    modData[LEASE_UNTIL_KEY] = now + durationMs
    LiveBodyControl.SetManagedBodyUseless(zombie, false, true)
    return true
end

function LiveBodyControl.EndNativeMovementLease(zombie, leaseKey)
    local modData
    if not zombie or not zombie.getModData then return false end
    modData = zombie:getModData()
    if not modData then return false end
    if leaseKey ~= nil
        and modData[LEASE_KEY] ~= nil
        and tostring(modData[LEASE_KEY]) ~= tostring(leaseKey)
    then
        return false
    end
    modData[LEASE_KEY] = nil
    modData[LEASE_UNTIL_KEY] = nil
    return true
end

function LiveBodyControl.HasNativeMovementLease(zombie, now)
    local modData
    local leaseKey
    local leaseUntil
    if not zombie or not zombie.getModData then return false end
    modData = zombie:getModData()
    leaseKey = modData and modData[LEASE_KEY] or nil
    if leaseKey == nil then return false end
    now = tonumber(now) or (Core and Core.Now and Core.Now() or 0)
    leaseUntil = tonumber(modData[LEASE_UNTIL_KEY]) or 0
    if now <= leaseUntil then return true end
    modData[LEASE_KEY] = nil
    modData[LEASE_UNTIL_KEY] = nil
    return false
end
