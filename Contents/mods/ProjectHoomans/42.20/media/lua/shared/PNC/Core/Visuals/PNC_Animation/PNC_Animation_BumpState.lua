--[[
    PNC Animation
    Single writer for PNC animation variables, locomotion flags, downed state,
    and custom bump-trigger playback on live NPC bodies.
]]

PNC = PNC or {}
PNC.Animation = PNC.Animation or {}
PNC.Animation.Internal = PNC.Animation.Internal or {}

local Animation = PNC.Animation
local Internal = Animation.Internal
local Core = PNC.Core
local LiveBodyControl = PNC.LiveBodyControl
local LocomotionProfiles = PNC.LocomotionProfiles
local AnimationTrace = PNC.AnimationTrace

Internal.BUMP_RELEASE_SETTLE_MS = 50
Internal.BUMP_ACTION_LEASE_TIMEOUT_MS = 10000
Internal.BUMP_ACTION_ENTRY_GRACE_MS = 350
Internal.BUMP_RELEASE_HARD_TIMEOUT_MS = math.max(
    250,
    tonumber(PNC.Const and PNC.Const.BUMP_RELEASE_HARD_TIMEOUT_MS)
        or 750
)

-- PNC owns a namespaced copy of Bandits' complete combat bump graph. Never
-- translate these requests back to Bandits' global BumpType values: doing so
-- lets whichever mod node loads last win and made melee playback dependent on
-- load order. Legacy unprefixed values remain recognizable only for cleanup.
Internal.PNC_COMBAT_BUMP_TYPES = {
    PNC_Attack1H1 = true,
    PNC_Attack1H2 = true,
    PNC_Attack2H1 = true,
    PNC_Attack2H2 = true,
    PNC_AttackS1 = true,
    PNC_AttackKnife = true,
    PNC_AttackPistol = true,
    PNC_AttackRifle = true,
    PNC_Attack2HFloor = true,
    PNC_Attack2HStamp = true,
    PNC_Shove = true,
}

function Animation.ResolveBumpType(bumpType)
    local resolved = tostring(bumpType or "Bump")
    if string.sub(resolved, 1, 4) == "PNC_" then
        return resolved
    end
    return "PNC_" .. resolved
end

function Internal.isCombatBumpType(requested, resolved)
    local requestName = tostring(requested or "")
    local resolvedName = tostring(resolved or "")
    local function hasCombatPrefix(value)
        return string.sub(value, 1, 10) == "PNC_Attack"
            or string.sub(value, 1, 9) == "PNC_Shove"
            or string.sub(value, 1, 17) == "PNC_Legacy_Attack"
            or string.sub(value, 1, 16) == "PNC_Legacy_Shove"
            or string.sub(value, 1, 16) == "PNC_Legacy_Knife"
            or value == "PNC_FrontKick"
            or value == "PNC_HighKick"
            or value == "PNC_Legacy_FrontKick"
            or value == "PNC_Legacy_HighKick"
    end
    return Internal.PNC_COMBAT_BUMP_TYPES[requestName] == true
        or Internal.PNC_COMBAT_BUMP_TYPES[resolvedName] == true
        or Internal.PNC_COMBAT_BUMP_TYPES["PNC_" .. requestName] == true
        or Internal.PNC_COMBAT_BUMP_TYPES["PNC_" .. resolvedName] == true
        or hasCombatPrefix(requestName)
        or hasCombatPrefix(resolvedName)
        or hasCombatPrefix("PNC_" .. requestName)
        or hasCombatPrefix("PNC_" .. resolvedName)
end

function Animation.IsBumpActionActive(zombie, now)
    local actionState
    local bumpType
    local modData = zombie
        and zombie.getModData
        and zombie:getModData()
        or nil
    if not modData or modData.PNC_BumpActionLease ~= true then
        return false
    end
    now = tonumber(now) or Core and Core.Now and Core.Now() or 0
    actionState = zombie.getActionStateName
        and string.lower(tostring(zombie:getActionStateName() or ""))
        or ""
    if zombie.getBumpType then
        bumpType = tostring(zombie:getBumpType() or "")
    elseif zombie.getVariableString then
        bumpType = tostring(zombie:getVariableString("BumpType") or "")
    else
        bumpType = ""
    end
    -- A failed/externally-cancelled bump used to retain its ten-second lease.
    -- Fake locomotion correctly respected that lease, so the body translated
    -- while Bob_Idle remained selected. Recover as soon as the engine has
    -- demonstrably cleared both the selector and bumped action state.
    if modData.PNC_BumpReleasePending ~= true
        and now - (
            tonumber(modData.PNC_BumpActionLeaseStartedAt)
                or now
        ) >= Internal.BUMP_ACTION_ENTRY_GRACE_MS
        and bumpType == ""
        and actionState ~= "bumped"
    then
        modData.PNC_BumpActionLease = nil
        modData.PNC_BumpActionLeaseUntil = nil
        modData.PNC_BumpActionLeaseStartedAt = nil
        modData.PNC_BumpRequestedType = nil
        modData.PNC_BumpKeepUseless = nil
        return false
    end
    if now <= (
        tonumber(modData.PNC_BumpActionLeaseUntil)
            or now
    ) then
        return true
    end
    modData.PNC_BumpActionLease = nil
    modData.PNC_BumpActionLeaseUntil = nil
    modData.PNC_BumpActionLeaseStartedAt = nil
    modData.PNC_BumpRequestedType = nil
    modData.PNC_BumpKeepUseless = nil
    return false
end

function Internal.setManagedUseless(
    zombie,
    requestedUseless,
    keepEngineMovementActive
)
    if LiveBodyControl
        and LiveBodyControl.SetManagedBodyUseless
    then
        return LiveBodyControl.SetManagedBodyUseless(
            zombie,
            requestedUseless,
            keepEngineMovementActive
        )
    end
    if zombie and zombie.setUseless then
        zombie:setUseless(
            keepEngineMovementActive == true
                and false
                or requestedUseless == true
        )
    end
    return requestedUseless == true
end

function Internal.applyBumpLeaseBodyMode(zombie)
    local modData = zombie
        and zombie.getModData
        and zombie:getModData()
        or nil
    local keepUseless = modData
        and modData.PNC_BumpKeepUseless == true
        or false
    return Internal.setManagedUseless(
        zombie,
        keepUseless,
        not keepUseless
    )
end

function Internal.getActionStateName(zombie)
    if zombie and zombie.getActionStateName then
        return string.lower(tostring(zombie:getActionStateName() or ""))
    end
    return ""
end

function Internal.recordBumpTrigger(
    zombie,
    record,
    bumpType,
    entered,
    mode,
    before,
    after
)
    local now = Core and Core.Now and Core.Now() or 0
    local modData = zombie
        and zombie.getModData
        and zombie:getModData()
        or nil
    local trigger = {
        anim = tostring(bumpType or "Bump"),
        entered = entered == true,
        mode = tostring(mode or "unknown"),
        stateBefore = tostring(before or ""),
        stateAfter = tostring(after or ""),
        at = now,
    }
    if modData then
        modData.PNC_BumpTriggerMode = trigger.mode
        modData.PNC_BumpTriggerStateBefore = trigger.stateBefore
        modData.PNC_BumpTriggerStateAfter = trigger.stateAfter
        modData.PNC_BumpTriggerAt = now
    end
    if record then
        record.runtime = record.runtime or {}
        record.runtime.lastAnimationTrigger = trigger
    end
end

function Internal.setPNCStateVars(zombie, record, animState)
    if not zombie or not zombie.setVariable then
        return
    end
    zombie:setVariable("PNC", true)
    zombie:setVariable("PNCActor", true)
    zombie:setVariable("PNCState", tostring(record and (record.activeBehavior or record.activeJob) or "Idle"))
    zombie:setVariable("PNCOrder", tostring(record and record.orderSpec and record.orderSpec.kind or "none"))
    zombie:setVariable("PNCPresence", tostring(record and record.presenceState or "unknown"))
    zombie:setVariable("PNCAnim", tostring(animState or "Idle"))
    zombie:setVariable("PNCWeaponMode", tostring(record and record.weaponMode or "melee"))
end
