local ZombieAggro = PNC.ZombieAggro
local Core = PNC.Core
local Const = PNC.Const
local Internal = ZombieAggro.Internal

local PURSUIT_OWNER = "ProjectHoomans"
local PURSUIT_LEASE_KEY = "PNC_ZombiePursuit"
local DEFAULT_PURSUIT_PRIORITIES = {
    ProjectHoomans = 100,
    Bandits = 60,
    NecroaHordeMaker = 30,
}

-- A real player target belongs to the vanilla zombie combat lane only after
-- the engine has entered a player-combat transition. It is intentionally
-- separate from nativeTargetOwner(): foreign AI providers need to identify
-- their own character targets, while an idle player target may still yield to
-- the NPC coordinate-pursuit lane.
local NATIVE_PLAYER_HANDOFF_OWNER = "VanillaPlayer"
local NATIVE_PLAYER_HANDOFF_TTL_MS = 750
local NATIVE_PLAYER_ATTACK_STATES = {
    attack = true,
    ["attack-network"] = true,
    lunge = true,
    ["lunge-network"] = true,
    turnalerted = true,
}

local function pursuitPriority(owner, requested)
    local value = tonumber(requested)
    if value ~= nil then return value end
    return tonumber(DEFAULT_PURSUIT_PRIORITIES[tostring(owner or "")]) or 0
end

local function logPursuitLease(zombie, targetId, state, detail, now)
    if ZombieAggro.LogPursuitDiagnostic then
        ZombieAggro.LogPursuitDiagnostic(
            zombie, targetId, "lease", state, detail, now
        )
    end
end

local function pursuitModData(zombie)
    return zombie and zombie.getModData and zombie:getModData() or nil
end

local function nativeTargetOwner(zombie)
    local target = zombie and zombie.getTarget
        and zombie:getTarget() or nil
    local attackedBy = zombie and zombie.getAttackedBy
        and zombie:getAttackedBy() or nil
    local ownership
    local function ownerOf(body)
        if not body then return nil end
        -- Player targets are vanilla control and are common in this hot path.
        -- Avoid invoking every optional foreign predicate for them.
        if instanceof and instanceof(body, "IsoPlayer") then
            return nil
        end
        if Core and Core.IsManagedNPCBody
            and Core.IsManagedNPCBody(body) == true
        then
            return PURSUIT_OWNER
        end
        if ownership and type(ownership.GetForeignOwner) == "function" then
            return ownership.GetForeignOwner(body)
        end
        return nil
    end
    ownership = PNC.Compatibility
        and PNC.Compatibility.ActorOwnership or nil
    return ownerOf(target) or ownerOf(attackedBy)
end

local function isIsoPlayer(body)
    return body and instanceof
        and instanceof(body, "IsoPlayer") == true
end

local function nativePlayerTarget(zombie)
    local target = zombie and zombie.getTarget
        and zombie:getTarget() or nil
    local attackedBy = zombie and zombie.getAttackedBy
        and zombie:getAttackedBy() or nil
    if isIsoPlayer(target)
        and not (target.isDead and target:isDead())
    then
        return target, "target"
    end
    if isIsoPlayer(attackedBy)
        and not (attackedBy.isDead and attackedBy:isDead())
    then
        return attackedBy, "attackedBy"
    end
    return nil, nil
end

local function nativePlayerActionState(zombie)
    if zombie and zombie.getActionStateName then
        return string.lower(tostring(zombie:getActionStateName() or ""))
    end
    return ""
end

local function isNativePlayerCombatActive(zombie, target)
    if not target then
        return false
    end
    return NATIVE_PLAYER_ATTACK_STATES[nativePlayerActionState(zombie)] == true
end

local function clearNativePlayerHandoff(modData)
    if type(modData) ~= "table" then return end
    modData.PNC_NativeCombatOwner = nil
    modData.PNC_NativeCombatTarget = nil
    modData.PNC_NativeCombatUntil = nil
    modData.PNC_NativeCombatReason = nil
    modData.PNC_NativeCombatHandoffApplied = nil
end

function Internal.GetNativePlayerTarget(zombie)
    return nativePlayerTarget(zombie)
end

-- This is the single read-side ownership gate used by both SP authority and
-- the MP owning-client controller.  It is deliberately O(1): it only checks
-- the zombie's existing target/attackedBy pointers and action state, and never
-- scans players or NPCs.
function Internal.ShouldYieldToNativePlayerAttack(zombie, now)
    local modData
    local target
    local source
    local action
    local owner
    local untilAt
    if not zombie
        or (Core and Core.IsManagedNPCBody
            and Core.IsManagedNPCBody(zombie) == true)
    then
        return false, nil, nil, ""
    end
    now = tonumber(now) or Core.Now()
    modData = pursuitModData(zombie)
    target, source = nativePlayerTarget(zombie)
    action = nativePlayerActionState(zombie)
    if target and NATIVE_PLAYER_ATTACK_STATES[action] == true then
        if modData then
            modData.PNC_NativeCombatOwner = NATIVE_PLAYER_HANDOFF_OWNER
            modData.PNC_NativeCombatTarget = target.getOnlineID
                and tonumber(target:getOnlineID()) or nil
            modData.PNC_NativeCombatUntil = now + NATIVE_PLAYER_HANDOFF_TTL_MS
            modData.PNC_NativeCombatReason = "player_target_" .. source
        end
        return true, target, source, action
    end
    owner = modData and modData.PNC_NativeCombatOwner or nil
    untilAt = modData and tonumber(modData.PNC_NativeCombatUntil) or nil
    if owner == NATIVE_PLAYER_HANDOFF_OWNER
        and untilAt and now <= untilAt
        and NATIVE_PLAYER_ATTACK_STATES[action] == true
    then
        return true, nil, "handoff", action
    end
    if owner == NATIVE_PLAYER_HANDOFF_OWNER then
        clearNativePlayerHandoff(modData)
    end
    return false, nil, nil, action
end

Internal.IsNativePlayerCombatActive = isNativePlayerCombatActive

local function clearPursuitLeaseData(modData, owner)
    if type(modData) ~= "table" then return end
    if owner == nil or tostring(modData["PNC_ZombiePursuitOwner"] or "")
        == tostring(owner)
    then
        modData["PNC_ZombiePursuitOwner"] = nil
        modData["PNC_ZombiePursuitProvider"] = nil
        modData["PNC_ZombiePursuitTarget"] = nil
        modData["PNC_ZombiePursuitRevision"] = nil
        modData["PNC_ZombiePursuitUntil"] = nil
        modData["PNC_ZombiePursuitPriority"] = nil
        modData["PNC_ZombiePursuitReason"] = nil
    end
end

function Internal.GetPursuitLease(zombie, now)
    local modData = pursuitModData(zombie)
    local owner
    local expiresAt
    if not modData then return nil end
    owner = modData["PNC_ZombiePursuitOwner"]
    expiresAt = tonumber(modData["PNC_ZombiePursuitUntil"])
    now = tonumber(now) or Core.Now()
    if owner == nil or expiresAt == nil or expiresAt <= now then
        clearPursuitLeaseData(modData)
        return nil
    end
    return {
        owner = tostring(owner),
        provider = modData["PNC_ZombiePursuitProvider"],
        targetId = modData["PNC_ZombiePursuitTarget"],
        revision = tonumber(modData["PNC_ZombiePursuitRevision"]) or 0,
        expiresAt = expiresAt,
        priority = tonumber(modData["PNC_ZombiePursuitPriority"])
            or pursuitPriority(owner, nil),
        reason = modData["PNC_ZombiePursuitReason"],
        key = PURSUIT_LEASE_KEY,
    }
end

function Internal.AcquirePursuitLease(
    zombie, owner, provider, targetId, now, ttl, priority, reason
)
    local modData = pursuitModData(zombie)
    local current
    local revision
    local ownerValue
    local providerValue
    local targetValue
    local priorityValue
    local reasonValue
    local changed
    if not modData or owner == nil then return false end
    now = tonumber(now) or Core.Now()
    ttl = tonumber(ttl) or tonumber(Const.ZOMBIE_NPC_AGGRO_LEASE_MS) or 8000
    ownerValue = tostring(owner)
    providerValue = provider ~= nil and tostring(provider) or nil
    targetValue = targetId ~= nil and tostring(targetId) or nil
    priorityValue = pursuitPriority(ownerValue, priority)
    reasonValue = reason ~= nil and tostring(reason) or nil
    current = Internal.GetPursuitLease(zombie, now)
    if current and current.owner ~= ownerValue then
        if priorityValue <= (tonumber(current.priority) or 0) then
            logPursuitLease(
                zombie,
                targetValue,
                "pursuit_lease_denied",
                "requestOwner=" .. ownerValue
                    .. " requestPriority=" .. tostring(priorityValue)
                    .. " currentOwner=" .. tostring(current.owner)
                    .. " currentPriority=" .. tostring(current.priority),
                now
            )
            return false
        end
    end
    changed = not current
        or current.owner ~= ownerValue
        or tostring(current.provider or "") ~= tostring(providerValue or "")
        or tostring(current.targetId or "") ~= tostring(targetValue or "")
        or (tonumber(current.priority) or 0) ~= priorityValue
        or tostring(current.reason or "") ~= tostring(reasonValue or "")
    revision = tonumber(modData["PNC_ZombiePursuitRevision"]) or 0
    if changed then revision = revision + 1 end
    modData["PNC_ZombiePursuitOwner"] = ownerValue
    modData["PNC_ZombiePursuitProvider"] = providerValue
    modData["PNC_ZombiePursuitTarget"] = targetValue
    modData["PNC_ZombiePursuitRevision"] = revision
    modData["PNC_ZombiePursuitUntil"] = now + math.max(1, ttl)
    modData["PNC_ZombiePursuitPriority"] = priorityValue
    modData["PNC_ZombiePursuitReason"] = reasonValue
    if changed then
        logPursuitLease(
            zombie,
            targetValue,
            "pursuit_lease_acquired",
            "owner=" .. ownerValue
                .. " provider=" .. tostring(providerValue)
                .. " priority=" .. tostring(priorityValue)
                .. " reason=" .. tostring(reasonValue),
            now
        )
    end
    return true, revision
end

function Internal.ReleasePursuitLease(zombie, owner)
    local modData = pursuitModData(zombie)
    if not modData then return false end
    if owner ~= nil and tostring(modData["PNC_ZombiePursuitOwner"] or "")
        ~= tostring(owner)
    then
        return false
    end
    clearPursuitLeaseData(modData, owner)
    return true
end

function Internal.ShouldYieldToPursuitOwner(
    zombie, owner, now, requestedPriority
)
    local lease = Internal.GetPursuitLease(zombie, now)
    if not lease or lease.owner == tostring(owner or "") then
        return false
    end
    return (tonumber(lease.priority) or 0)
        >= pursuitPriority(owner, requestedPriority)
end

-- Native target/path/lunge writes are a separate compatibility boundary from
-- the abstract pursuit lease. A provider may hold no lease yet still have a
-- live native target (for example Bandits' ordinary-zombie callback runs
-- before Hoomans). In that case Hoomans must not clear or replace the target.
function Internal.GetNativeTargetOwner(zombie)
    return nativeTargetOwner(zombie)
end

function Internal.CanWriteNativeControl(
    zombie, owner, now, requestedPriority, requestedIntent
)
    local ownerValue = tostring(owner or "")
    local lease = Internal.GetPursuitLease(zombie, now)
    local targetOwner = nativeTargetOwner(zombie)
    local nativePlayer
    local modData = pursuitModData(zombie)
    local requested = pursuitPriority(ownerValue, requestedPriority)
    requestedIntent = tostring(requestedIntent or "pursuit")
    if lease and lease.owner ~= ownerValue
        and (tonumber(lease.priority) or 0) >= requested
    then
        return false, lease.owner, "pursuit_lease"
    end
    if targetOwner and targetOwner ~= ownerValue then
        return false, targetOwner, "native_target"
    end
    nativePlayer = nativePlayerTarget(zombie)
    if nativePlayer
        and ownerValue == PURSUIT_OWNER
        and requestedIntent ~= "native_player_handoff"
        and isNativePlayerCombatActive(zombie, nativePlayer)
        and not (modData and modData.PNCZombieBitingNPC == true)
    then
        return false, NATIVE_PLAYER_HANDOFF_OWNER, "native_player_attack"
    end
    return true, ownerValue, nil
end

-- Transfer only the native combat/movement lane to vanilla.  The player
-- target is deliberately preserved; this function never clears target,
-- attackedBy, or the vanilla aggro list.
function Internal.BeginNativePlayerHandoff(zombie, target, now, reason)
    local modData
    local currentTarget
    local lease
    local alreadyApplied
    local needsSuspend
    if not zombie then return false end
    now = tonumber(now) or Core.Now()
    target = target or nativePlayerTarget(zombie)
    modData = pursuitModData(zombie)
    lease = Internal.GetPursuitLease(zombie, now)
    alreadyApplied = modData
        and modData.PNC_NativeCombatHandoffApplied == true
    needsSuspend = not alreadyApplied
        or (modData and modData.PNC_AggroNPCId ~= nil)
        or (lease and lease.owner == PURSUIT_OWNER)
    if needsSuspend and Internal.SuspendNPCPursuit then
        Internal.SuspendNPCPursuit(
            zombie, now, reason or "native_player_attack"
        )
    elseif needsSuspend then
        Internal.ReleasePursuitLease(zombie, PURSUIT_OWNER)
    end
    currentTarget = zombie.getTarget and zombie:getTarget() or nil
    if target and currentTarget ~= target and zombie.setTarget then
        zombie:setTarget(target)
    end
    if not alreadyApplied and zombie.setVariable then
        zombie:setVariable("NoLungeAttack", false)
    end
    modData = modData or pursuitModData(zombie)
    if modData then
        modData.PNC_NativeCombatOwner = NATIVE_PLAYER_HANDOFF_OWNER
        modData.PNC_NativeCombatTarget = target
            and target.getOnlineID
            and tonumber(target:getOnlineID()) or nil
        modData.PNC_NativeCombatUntil = now + NATIVE_PLAYER_HANDOFF_TTL_MS
        modData.PNC_NativeCombatReason = reason
            or "native_player_attack"
        modData.PNC_NativeCombatHandoffApplied = true
    end
    return true
end

-- Public compatibility boundary. Foreign AI mods can cooperate without
-- depending on Hoomans' internal module layout or load order.
ZombieAggro.Pursuit = ZombieAggro.Pursuit or {}
ZombieAggro.Pursuit.GetLease = function(zombie, now)
    return Internal.GetPursuitLease(zombie, now)
end
ZombieAggro.Pursuit.TryAcquire = function(
    zombie, owner, provider, targetId, now, ttl, priority, reason
)
    return Internal.AcquirePursuitLease(
        zombie, owner, provider, targetId, now, ttl, priority, reason
    )
end
ZombieAggro.Pursuit.Release = function(zombie, owner)
    return Internal.ReleasePursuitLease(zombie, owner)
end
ZombieAggro.Pursuit.ShouldYield = function(
    zombie, owner, now, requestedPriority
)
    return Internal.ShouldYieldToPursuitOwner(
        zombie, owner, now, requestedPriority
    )
end
ZombieAggro.Pursuit.GetNativeTargetOwner = function(zombie)
    return Internal.GetNativeTargetOwner(zombie)
end
ZombieAggro.Pursuit.CanWriteNative = function(
    zombie, owner, now, requestedPriority, requestedIntent
)
    return Internal.CanWriteNativeControl(
        zombie, owner, now, requestedPriority, requestedIntent
    )
end
