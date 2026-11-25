-- Unified actor-side body-pose watchdog probe for orphaned bumped states.

PNC = PNC or {}
PNC.Watchdog = PNC.Watchdog or {}

local Watchdog = PNC.Watchdog
local Core = PNC.Core
local POSE_RECOVERY_COOLDOWN_MS = 500

local function getActionState(zombie)
    if not zombie or not zombie.getActionStateName then return "" end
    return string.lower(tostring(zombie:getActionStateName() or ""))
end

local function getBumpType(zombie)
    if not zombie then return "" end
    if zombie.getBumpType then
        return tostring(zombie:getBumpType() or "")
    end
    if zombie.getVariableString then
        return tostring(zombie:getVariableString("BumpType") or "")
    end
    return ""
end

local function hasActivePoseOwner(record, zombie, now)
    local runtime = record and record.runtime or nil
    local modData = zombie and zombie.getModData and zombie:getModData() or nil
    if modData and modData.PNC_BumpReleasePending == true then
        return true
    end
    if PNC.Animation and PNC.Animation.IsBumpActionActive
        and PNC.Animation.IsBumpActionActive(zombie, now)
    then
        return true
    end
    if not runtime then return false end
    if runtime.attackAction ~= nil then return true end
    if runtime.animationScene ~= nil then return true end
    if runtime.selfTreatment and runtime.selfTreatment.phase == "bandaging" then
        return true
    end
    if runtime.medicalCare and runtime.medicalCare.phase == "treating" then
        return true
    end
    if runtime.pathing and (
        runtime.pathing.traversalAction ~= nil
        or runtime.pathing.vanillaFenceAction ~= nil
        or (tonumber(runtime.pathing.specialMoveUntil) or 0) > now
    ) then
        return true
    end
    return false
end

function Watchdog.RecoverBodyPose(record, zombie, now)
    if not zombie then return false end
    now = tonumber(now) or (Core and Core.Now and Core.Now()) or 0
    local actionState = getActionState(zombie)
    local bumpType = getBumpType(zombie)
    if actionState ~= "bumped" and bumpType == "" then
        return false
    end
    if hasActivePoseOwner(record, zombie, now) then
        return false
    end
    local modData = zombie.getModData and zombie:getModData() or nil
    if modData then
        local lastAt = tonumber(modData.PNC_WatchdogPoseRecoverAt) or 0
        if now - lastAt < POSE_RECOVERY_COOLDOWN_MS then
            return false
        end
        modData.PNC_WatchdogPoseRecoverAt = now
    end
    local exited = false
    if PNC.Animation and PNC.Animation.ForceRecoverBumped then
        exited = PNC.Animation.ForceRecoverBumped(zombie) == true
    else
        if zombie.setBumpType then zombie:setBumpType("") end
        if zombie.setBumpDone then zombie:setBumpDone(true) end
        if zombie.setVariable then
            zombie:setVariable("BumpDone", true)
            zombie:setVariable("BumpAnimFinished", true)
        end
    end
    if not exited and getActionState(zombie) == "bumped"
        and PNC.Animation and PNC.Animation.FinishBump
    then
        PNC.Animation.FinishBump(zombie, true)
    end
    Watchdog.Record(
        "body_pose",
        record and record.id or (modData and modData.PNC_UUID) or "unknown",
        actionState == "bumped" and "orphaned_bumped_state" or "orphaned_bump_type",
        exited and "recovered" or "release_armed"
    )
    return true
end

return Watchdog
