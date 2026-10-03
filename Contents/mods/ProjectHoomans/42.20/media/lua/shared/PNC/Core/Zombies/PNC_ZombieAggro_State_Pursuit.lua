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
