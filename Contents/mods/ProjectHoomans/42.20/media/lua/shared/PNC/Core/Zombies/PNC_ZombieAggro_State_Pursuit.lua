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
local PLAYER_PROVOKE_WINDOW_MS = 5000
-- Only genuine player-combat states claim the vanilla attack lane.
-- "turnalerted" is a sight/sound turning state (triggered whenever a zombie
-- hears pathToSound or glances at a distant player) and must not abort an
-- active NPC pursuit.
local NATIVE_PLAYER_ATTACK_STATES = {
    attack = true,
    ["attack-network"] = true,
    lunge = true,
    ["lunge-network"] = true,
}
local NATIVE_PLAYER_LUNGE_YIELD_DIST_SQ = 6.25 -- 2.5 tiles

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
    -- Check attackedBy first so an actual player hit/shove is always
    -- distinguished from passive vision targeting (target).
    if isIsoPlayer(attackedBy)
        and not (attackedBy.isDead and attackedBy:isDead())
    then
        return attackedBy, "attackedBy"
    end
    if isIsoPlayer(target)
        and not (target.isDead and target:isDead())
    then
        return target, "target"
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
    local npcProvoked = modData
        and (tonumber(modData.PNC_AggroProvokedUntil) or 0) > now
    local playerProvoked = modData
        and (tonumber(modData.PNC_PlayerProvokedUntil) or 0) > now
    local npcLeased = modData
        and modData.PNC_ZombiePursuitOwner == PURSUIT_OWNER
        and (tonumber(modData.PNC_ZombiePursuitUntil) or 0) > now

    -- Organic hit-to-distract: if the player actually hit or shoved the zombie
    -- (attackedBy == player), immediately yield to the player and clear any
    -- prior NPC retaliation lock so the zombie turns on the player.
    if target and source == "attackedBy" then
        if modData then
            modData.PNC_AggroProvokedUntil = nil
            modData.PNC_PlayerProvokedUntil = now + PLAYER_PROVOKE_WINDOW_MS
            modData.PNC_NativeCombatOwner = NATIVE_PLAYER_HANDOFF_OWNER
            modData.PNC_NativeCombatTarget = target.getOnlineID
                and tonumber(target:getOnlineID()) or nil
            modData.PNC_NativeCombatUntil = now + NATIVE_PLAYER_HANDOFF_TTL_MS
            modData.PNC_NativeCombatReason = "player_provoked_hit"
        end
        return true, target, source, action
    end

    -- While the player's recent hit provocation is active (and no NPC has hit
    -- the zombie back), keep the zombie committed to the player.
    if target and playerProvoked and not npcProvoked then
        return true, target, "player_provoked", action
    end

    if target and NATIVE_PLAYER_ATTACK_STATES[action] == true then
        local isLunge = action == "lunge" or action == "lunge-network"
        -- If an NPC just hit/provoked this zombie, let it retaliate against
        -- the NPC instead of being pulled back to the player by a lunge.
        if isLunge and npcProvoked then
            return false, nil, nil, action
        end
        -- When a zombie is already committed to attacking/chasing an NPC,
        -- merely walking near it must not steal it onto the player; the player
        -- must attack/shove it (attackedBy) to draw aggro organically.
        if isLunge and npcLeased
            and (action == "lunge"
                or (zombie.getX and zombie.getY and target.getX and target.getY))
        then
            return false, nil, nil, action
        end
        -- For unleased zombies, Build 42 enters LungeState from up to ~12 tiles
        -- away while chasing a player. Ignore distant lunges (> 2.5 tiles) so
        -- acquireNearestTarget can compare distances fairly with closer NPCs.
        if isLunge
            and zombie.getX and zombie.getY and target.getX and target.getY
        then
            local dx = (tonumber(target:getX()) or 0) - (tonumber(zombie:getX()) or 0)
            local dy = (tonumber(target:getY()) or 0) - (tonumber(zombie:getY()) or 0)
            if (dx * dx) + (dy * dy) > NATIVE_PLAYER_LUNGE_YIELD_DIST_SQ then
                return false, nil, nil, action
            end
        end
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

function Internal.GetPursuitLeaseFields(zombie, now, modData)
    modData = modData or pursuitModData(zombie)
    if not modData then return nil end
    local owner = modData["PNC_ZombiePursuitOwner"]
    local expiresAt = tonumber(modData["PNC_ZombiePursuitUntil"])
    if owner == nil or expiresAt == nil then
        clearPursuitLeaseData(modData)
        return nil
    end
    now = tonumber(now) or Core.Now()
    if expiresAt <= now then
        clearPursuitLeaseData(modData)
        return nil
    end
    local ownerValue = tostring(owner)
    local priority = tonumber(modData["PNC_ZombiePursuitPriority"])
        or pursuitPriority(ownerValue, nil)
    return ownerValue,
        priority,
        expiresAt,
        modData["PNC_ZombiePursuitTarget"],
        modData["PNC_ZombiePursuitProvider"],
        tonumber(modData["PNC_ZombiePursuitRevision"]) or 0,
        modData["PNC_ZombiePursuitReason"]
end

function Internal.GetPursuitLease(zombie, now, modData)
    local ownerValue, priority, expiresAt, targetId, provider, revision, reason =
        Internal.GetPursuitLeaseFields(zombie, now, modData)
    if ownerValue == nil then return nil end
    return {
        owner = ownerValue,
        provider = provider,
        targetId = targetId,
        revision = revision,
        expiresAt = expiresAt,
        priority = priority,
        reason = reason,
        key = PURSUIT_LEASE_KEY,
    }
end

function Internal.AcquirePursuitLease(
    zombie, owner, provider, targetId, now, ttl, priority, reason, modData
)
    modData = modData or pursuitModData(zombie)
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
    local curOwner, curPriority, _, curTargetId, curProvider, curRev, curReason =
        Internal.GetPursuitLeaseFields(zombie, now, modData)
    if curOwner ~= nil and curOwner ~= ownerValue then
        if priorityValue <= curPriority then
            logPursuitLease(
                zombie,
                targetValue,
                "pursuit_lease_denied",
                "requestOwner=" .. ownerValue
                    .. " requestPriority=" .. tostring(priorityValue)
                    .. " currentOwner=" .. tostring(curOwner)
                    .. " currentPriority=" .. tostring(curPriority),
                now
            )
            return false
        end
    end
    changed = curOwner == nil
        or curOwner ~= ownerValue
        or tostring(curProvider or "") ~= tostring(providerValue or "")
        or tostring(curTargetId or "") ~= tostring(targetValue or "")
        or curPriority ~= priorityValue
        or tostring(curReason or "") ~= tostring(reasonValue or "")
    revision = curRev or tonumber(modData["PNC_ZombiePursuitRevision"]) or 0
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
    zombie, owner, now, requestedPriority, modData
)
    local leaseOwner, leasePriority = Internal.GetPursuitLeaseFields(
        zombie, now, modData
    )
    if not leaseOwner or leaseOwner == tostring(owner or "") then
        return false
    end
    return leasePriority >= pursuitPriority(owner, requestedPriority)
end

-- Native target/path/lunge writes are a separate compatibility boundary from
-- the abstract pursuit lease. A provider may hold no lease yet still have a
-- live native target (for example Bandits' ordinary-zombie callback runs
-- before Hoomans). In that case Hoomans must not clear or replace the target.
function Internal.GetNativeTargetOwner(zombie)
    return nativeTargetOwner(zombie)
end

function Internal.CanWriteNativeControl(
    zombie, owner, now, requestedPriority, requestedIntent, modData
)
    local ownerValue = tostring(owner or "")
    modData = modData or pursuitModData(zombie)
    local leaseOwner, leasePriority = Internal.GetPursuitLeaseFields(
        zombie, now, modData
    )
    local targetOwner = nativeTargetOwner(zombie)
    local nativePlayer
    local requested = pursuitPriority(ownerValue, requestedPriority)
    requestedIntent = tostring(requestedIntent or "pursuit")
    if leaseOwner and leaseOwner ~= ownerValue and leasePriority >= requested then
        return false, leaseOwner, "pursuit_lease"
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
