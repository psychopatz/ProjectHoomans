-- Native get-up lease and grounded-state preparation.

local LiveBodyControl = PNC.LiveBodyControl
local Internal = LiveBodyControl.Internal
local Core = PNC.Core
local LEASE_KEY = "PNC_NativeGetUpLease"
local LEASE_UNTIL_KEY = "PNC_NativeGetUpLeaseUntil"
local LEASE_MS = 4000

function Internal.clearBumpActionLease(zombie)
    local modData = zombie and zombie.getModData and zombie:getModData() or nil
    if modData then
        modData.PNC_BumpReleasePending = nil
        modData.PNC_BumpReleaseAt = nil
        modData.PNC_BumpActionLease = nil
        modData.PNC_BumpActionLeaseUntil = nil
        modData.PNC_BumpActionLeaseStartedAt = nil
        modData.PNC_BumpRequestedType = nil
        modData.PNC_BumpKeepUseless = nil
    end
end

function Internal.hasNativeGetUpLease(zombie, now)
    local modData = zombie and zombie.getModData
        and zombie:getModData() or nil
    local leaseUntil
    if not modData or modData[LEASE_KEY] ~= true then return false end
    now = tonumber(now) or (Core and Core.Now and Core.Now() or 0)
    leaseUntil = tonumber(modData[LEASE_UNTIL_KEY]) or 0
    if now <= leaseUntil then return true end
    modData[LEASE_KEY] = nil
    modData[LEASE_UNTIL_KEY] = nil
    return false
end

function Internal.clearNativeGetUpLease(zombie)
    local modData = zombie and zombie.getModData
        and zombie:getModData() or nil
    if not modData then return false end
    modData[LEASE_KEY] = nil
    modData[LEASE_UNTIL_KEY] = nil
    return true
end

function Internal.beginNativeGetUpLease(zombie, now)
    local modData = zombie and zombie.getModData
        and zombie:getModData() or nil
    if not modData then return false end
    now = tonumber(now) or (Core and Core.Now and Core.Now() or 0)
    modData[LEASE_KEY] = true
    modData[LEASE_UNTIL_KEY] = now + LEASE_MS
    if zombie.setReanimateTimer then zombie:setReanimateTimer(0) end
    LiveBodyControl.SetManagedBodyUseless(zombie, false, true)
    return true
end

function Internal.prepareNativeGetUp(zombie)
    if not zombie then return end
    Internal.clearBumpActionLease(zombie)
    LiveBodyControl.ReleaseDamageReaction(zombie)
    if zombie.setBumpFall then zombie:setBumpFall(false) end
    if zombie.setCrawler then zombie:setCrawler(false) end
    if zombie.setFakeDead then zombie:setFakeDead(false) end
    if zombie.setCanWalk then zombie:setCanWalk(true) end
    if zombie.setVariable then
        zombie:setVariable("bBecomeCrawler", false)
        zombie:setVariable("bCrawling", false)
        zombie:setVariable("BumpFall", false)
    end
end

function Internal.intentionallyGrounded(record)
    local runtime = record and record.runtime or nil
    local activity = runtime and runtime.facilityActivity or nil
    return record and record.health
            and record.health.state == "incapacitated"
        or runtime and runtime.activityOverride == "sleeping"
        or activity and activity.capability == "sleep"
            and tostring(activity.phase or "") == "SLEEPING"
        or false
end
