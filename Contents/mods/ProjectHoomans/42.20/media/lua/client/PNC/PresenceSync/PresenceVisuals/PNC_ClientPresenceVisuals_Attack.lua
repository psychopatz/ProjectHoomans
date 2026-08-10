--[[
    PNC Client Presence Visuals: attack bump lifecycle
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
local Animation = PNC.Animation
local AnimationTrace = PNC.AnimationTrace
local logClientMotionDebug = Internal.LogClientMotionDebug
local ATTACK_BUMP_REARM_MS = 100
local ATTACK_BUMP_MAX_REARMS = 1

local function getActionStateName(zombie)
    if zombie and zombie.getActionStateName then
        return string.lower(tostring(
            zombie:getActionStateName() or ""
        ))
    end
    return ""
end

local function getBumpType(zombie)
    if zombie and zombie.getBumpType then
        return tostring(zombie:getBumpType() or "")
    end
    return ""
end

local function beginClientAttackBump(
    snapshot,
    zombie,
    recordView,
    modData,
    attackKey,
    anim,
    now
)
    if Animation and Animation.PlayBump then
        Animation.PlayBump(zombie, recordView, anim)
    end
    if modData then
        modData.PNC_ClientAttackKey = attackKey
        modData.PNC_ClientAttackLocalStartedAt = now
        modData.PNC_ClientAttackRetries = 0
        modData.PNC_ClientAttackRequestedAnim =
            tostring(anim or "")
        modData.PNC_ClientAttackResolvedAnim =
            Animation and Animation.ResolveBumpType
                and Animation.ResolveBumpType(anim)
                or tostring(anim or "")
        modData.PNC_ClientAttackActionState =
            getActionStateName(zombie)
        modData.PNC_ClientAttackBumpType =
            getBumpType(zombie)
    end
    logClientMotionDebug(
        snapshot,
        snapshot and snapshot.id or nil,
        "attack_anim_start",
        "anim=" .. tostring(anim)
            .. " bump=" .. getBumpType(zombie)
            .. " action=" .. getActionStateName(zombie)
    )
end

local function observeClientAttackBump(zombie, modData)
    if not modData then return end
    modData.PNC_ClientAttackActionState =
        getActionStateName(zombie)
    modData.PNC_ClientAttackBumpType =
        getBumpType(zombie)
end

local function rearmDroppedClientAttackBump(
    snapshot,
    zombie,
    recordView,
    modData,
    attackKey,
    anim,
    now
)
    local startedAt
    local retries
    local actionState
    if not zombie or not modData or not attackKey then return false end
    startedAt = tonumber(modData.PNC_ClientAttackLocalStartedAt) or now
    retries = tonumber(modData.PNC_ClientAttackRetries) or 0
    actionState = getActionStateName(zombie)
    if actionState == "bumped"
        or now - startedAt < ATTACK_BUMP_REARM_MS
        or retries >= ATTACK_BUMP_MAX_REARMS
    then
        return false
    end
    -- PathFindState can consume the first BumpType change while it exits,
    -- leaving the requested selector installed but the ActionContext idle.
    -- Toggle the selector once to create a fresh edge after path ownership has
    -- been released. Never do this after BumpedState has actually started.
    if zombie.setBumpType then zombie:setBumpType("") end
    if Animation and Animation.PlayBump then
        Animation.PlayBump(zombie, recordView, anim, {
            leaseUntil = snapshot
                and snapshot.visualState
                and snapshot.visualState.attackFinishAt
                or nil,
        })
    end
    modData.PNC_ClientAttackRetries = retries + 1
    observeClientAttackBump(zombie, modData)
    logClientMotionDebug(
        snapshot,
        snapshot and snapshot.id or nil,
        "attack_anim_rearm",
        "anim=" .. tostring(anim)
            .. " bump=" .. getBumpType(zombie)
            .. " action=" .. getActionStateName(zombie)
    )
    if AnimationTrace and AnimationTrace.Sample then
        AnimationTrace.Sample(zombie, "client_attack_rearm", now, true)
    end
    return true
end


Internal.BeginClientAttackBump = beginClientAttackBump
Internal.ObserveClientAttackBump = observeClientAttackBump
Internal.RearmDroppedClientAttackBump = rearmDroppedClientAttackBump

