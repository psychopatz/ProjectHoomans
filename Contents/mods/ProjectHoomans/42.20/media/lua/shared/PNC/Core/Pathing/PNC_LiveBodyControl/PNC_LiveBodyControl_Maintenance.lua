-- Throttled body maintenance and engine-ownership policy.

local LiveBodyControl = PNC.LiveBodyControl
local Internal = LiveBodyControl.Internal
local Core = PNC.Core
local BODY_MAINTENANCE_INTERVAL_MS = 500
local NEXT_AUDIO_SUPPRESSION_AT = setmetatable({}, { __mode = "k" })
local NEXT_BODY_MAINTENANCE_AT = setmetatable({}, { __mode = "k" })
local LAST_KEEP_ENGINE_ACTIVE = setmetatable({}, { __mode = "k" })

function LiveBodyControl.MaintainHumanizedBody(
    zombie,
    now,
    keepEngineMovementActive,
    force
)
    local modData
    local nextAudioAt
    local nextMaintenanceAt
    local actionLeaseActive
    local actionState
    if not zombie then return false end
    now = tonumber(now) or (Core and Core.Now and Core.Now() or 0)
    modData = zombie.getModData and zombie:getModData() or nil
    actionState = LiveBodyControl.GetActionStateName(zombie)
    actionLeaseActive = Internal.hasBumpActionLease(zombie, now)
        or Internal.hasNativeGetUpLease(zombie, now)
        or keepEngineMovementActive == true
            and (Internal.GROUNDED_STATES[actionState] == true
                or Internal.GETUP_STATES[actionState] == true)
    if LAST_KEEP_ENGINE_ACTIVE[zombie]
        ~= (keepEngineMovementActive == true)
    then
        force = true
    end
    nextMaintenanceAt = tonumber(NEXT_BODY_MAINTENANCE_AT[zombie]) or 0
    if force == true or now >= nextMaintenanceAt then
        if actionLeaseActive then
            Internal.applyActionLeaseSafeguards(zombie, modData)
        else
            LiveBodyControl.ApplyHumanizedBodyFlags(
                zombie,
                keepEngineMovementActive
            )
        end
        NEXT_BODY_MAINTENANCE_AT[zombie] =
            now + BODY_MAINTENANCE_INTERVAL_MS
        LAST_KEEP_ENGINE_ACTIVE[zombie] = keepEngineMovementActive == true
    end
    nextAudioAt = tonumber(NEXT_AUDIO_SUPPRESSION_AT[zombie]) or 0
    if now >= nextAudioAt then
        LiveBodyControl.SuppressZombieSounds(zombie)
        NEXT_AUDIO_SUPPRESSION_AT[zombie] =
            now + Internal.SUPPRESSION_AUDIO_COOLDOWN_MS
    end
    return true
end

function LiveBodyControl.ShouldKeepEngineMovementActive(record, zombie)
    local runtime = record and record.runtime or nil
    local navigation = runtime and runtime.localNavigation or nil
    local attackAction = runtime and runtime.attackAction or nil
    local treatment = runtime and runtime.selfTreatment or nil
    local modData = zombie and zombie.getModData and zombie:getModData() or nil
    local now = Core and Core.Now and Core.Now() or 0
    if Internal.hasNativeGetUpLease(zombie, now) then return true end
    if Core and Core.IsAuthority and not Core.IsAuthority() then
        local actionState = LiveBodyControl.GetActionStateName(zombie)
        if not Internal.intentionallyGrounded(record)
            and (Internal.GROUNDED_STATES[actionState] == true
                or Internal.GETUP_STATES[actionState] == true)
        then
            return true
        end
    end
    if LiveBodyControl.HasNativeMovementLease(zombie, now) then return true end
    if modData and modData.PNC_BumpActionLease == true then
        if now <= (tonumber(modData.PNC_BumpActionLeaseUntil) or now) then
            return modData.PNC_BumpKeepUseless ~= true
        end
        modData.PNC_BumpActionLease = nil
        modData.PNC_BumpActionLeaseUntil = nil
        modData.PNC_BumpActionLeaseStartedAt = nil
        modData.PNC_BumpRequestedType = nil
        modData.PNC_BumpKeepUseless = nil
    end
    if Core and Core.IsAuthority and not Core.IsAuthority() then return false end
    if attackAction and now < (tonumber(attackAction.finishAt) or 0) then
        return true
    end
    if treatment and treatment.phase == "bandaging" then return true end
    if not navigation
        or navigation.provider ~= "engine_path"
        or navigation.nativeActive ~= true
    then
        return false
    end
    return navigation.controllerMode ~= "behavior2_move"
end
