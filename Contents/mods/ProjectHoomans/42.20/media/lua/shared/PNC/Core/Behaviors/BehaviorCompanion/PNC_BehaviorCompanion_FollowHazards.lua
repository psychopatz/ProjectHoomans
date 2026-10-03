-- Zombie-density sensing and short-lived steering targets for followers.

local Internal = PNC.BehaviorCompanion.Internal
local Core = PNC.Core
local Const = PNC.Const
local Spatial = PNC.SpatialIndex
local TraversalQuery = PNC.TraversalQuery
local Diagnostics = PNC.PerformanceScalingDiagnostics

-- Followers in one formation usually occupy the same few tiles. Reuse a
-- short-lived candidate pool for that owner instead of rebuilding the same
-- spatial query for every follower. The pool is deliberately wider than the
-- exact hazard radius; every follower still applies its own exact-distance
-- filter below, so sharing cannot make a follower react to a distant zombie.
local FollowCandidateCache = {}
local FollowCandidateCacheKeys = {}
local MAX_FOLLOW_OWNER_CACHES = 32
local FOLLOW_CANDIDATE_REUSE_DISTANCE = 3.0

local function observeZombieHorde(record, count, threshold, now)
    if (tonumber(count) or 0) < (tonumber(threshold) or 3) then
        return
    end
    local hooks = PNC and PNC.SocialEventHooks
    if hooks and type(hooks.ObserveZombieHorde) == "function" then
        pcall(
            hooks.ObserveZombieHorde,
            record,
            count,
            threshold,
            now,
            "follow"
        )
    end
end

local function getSharedCandidates(record, x, y, z, radius, now)
    local ownerKey = Internal.GetFollowOwnerKey(record)
    local ownerCache = FollowCandidateCache[ownerKey]
    local i
    local entry
    local dx
    local dy
    local reuseRadius = FOLLOW_CANDIDATE_REUSE_DISTANCE
    local queryRadius = radius + reuseRadius
    if not ownerCache then
        if #FollowCandidateCacheKeys >= MAX_FOLLOW_OWNER_CACHES then
            FollowCandidateCache[FollowCandidateCacheKeys[1]] = nil
            table.remove(FollowCandidateCacheKeys, 1)
        end
        ownerCache = {}
        FollowCandidateCache[ownerKey] = ownerCache
        FollowCandidateCacheKeys[#FollowCandidateCacheKeys + 1] = ownerKey
    end
    for i = 1, #ownerCache do
        entry = ownerCache[i]
        if entry
            and now < (tonumber(entry.expiresAt) or 0)
            and math.abs((tonumber(entry.z) or z) - z) < 1
        then
            dx = x - (tonumber(entry.x) or x)
            dy = y - (tonumber(entry.y) or y)
            if (dx * dx) + (dy * dy) <= reuseRadius * reuseRadius then
                if Diagnostics then
                    Diagnostics.Increment("Follow.HazardCandidateCacheHits")
                end
                return entry.candidates
            end
        end
    end
    entry = {
        x = x,
        y = y,
        z = z,
        expiresAt = now + (tonumber(Const.FOLLOW_HORDE_SCAN_MS) or 150),
        candidates = Spatial and Spatial.QueryZombies
            and Spatial.QueryZombies(x, y, queryRadius) or {},
    }
    if Diagnostics then
        Diagnostics.Increment("Follow.HazardCandidateQueries")
    end
    -- Keep a bounded per-owner pool. A formation normally needs one entry;
    -- the second entry covers a group split across nearby map cells without
    -- allowing movement through a long session to grow this cache forever.
    if #ownerCache < 2 then
        ownerCache[#ownerCache + 1] = entry
    else
        ownerCache[1] = ownerCache[2]
        ownerCache[2] = entry
    end
    return entry.candidates
end

function Internal.AssessFollowHazards(record, zombie, now)
    local runtime = record.runtime or {}
    local cached = runtime.followHazard
    local radius = tonumber(Const.FOLLOW_HORDE_AVOID_RADIUS) or 6.5
    local radiusSq = radius * radius
    local combatRadius = tonumber(Const.COMBAT_HORDE_RADIUS) or 5.5
    local combatRadiusSq = combatRadius * combatRadius
    local nearDistance = tonumber(Const.FOLLOW_HORDE_NEAR_DISTANCE) or 2.4
    local candidates
    local candidate
    local x = zombie and zombie.getX and zombie:getX()
        or tonumber(record.x) or 0
    local y = zombie and zombie.getY and zombie:getY()
        or tonumber(record.y) or 0
    local z = zombie and zombie.getZ and zombie:getZ()
        or tonumber(record.z) or 0
    local zx
    local zy
    local dx
    local dy
    local distSq
    local distance
    local weight
    local i
    local cacheDx
    local cacheDy
    local combatCount
    local hostileZombies
    local hordeThreshold

    record.runtime = runtime
    cacheDx = cached and x - (tonumber(cached.x) or x) or 0
    cacheDy = cached and y - (tonumber(cached.y) or y) or 0
    if cached
        and now < (tonumber(cached.expiresAt) or 0)
        and (cacheDx * cacheDx) + (cacheDy * cacheDy) <= 0.25
    then
        return cached
    end

    cached = cached or {}
    cached.x = x
    cached.y = y
    cached.z = z
    cached.count = 0
    cached.nearestDistance = math.huge
    cached.repelX = 0
    cached.repelY = 0
    cached.combatCount = 0
    cached.combatCountReady = true
    cached.expiresAt = now
        + (tonumber(Const.FOLLOW_HORDE_SCAN_MS) or 150)
    candidates = getSharedCandidates(record, x, y, z, radius, now)
    hostileZombies = not record.hostility
        or record.hostility.attackZombies ~= false
    for i = 1, #candidates do
        candidate = candidates[i]
        if type(candidate) == "table" and candidate.zombie then
            candidate = candidate.zombie
        end
        if candidate
            and (not candidate.isDead or not candidate:isDead())
            and (
                not Core.IsManagedNPCBody
                or not Core.IsManagedNPCBody(candidate)
            )
            and candidate.getX
            and candidate.getY
            and candidate.getZ
            and math.abs(candidate:getZ() - z) < 1
        then
            zx = candidate:getX()
            zy = candidate:getY()
            dx = x - zx
            dy = y - zy
            distSq = (dx * dx) + (dy * dy)
            if distSq <= radiusSq then
                distance = math.sqrt(math.max(0.0025, distSq))
                weight = math.max(0, (radius - distance) / radius)
                cached.count = cached.count + 1
                cached.nearestDistance = math.min(
                    cached.nearestDistance,
                    distance
                )
                cached.repelX = cached.repelX
                    + ((dx / distance) * weight * weight)
                cached.repelY = cached.repelY
                    + ((dy / distance) * weight * weight)
            end
            combatCount = distSq <= combatRadiusSq
            if combatCount and hostileZombies then
                cached.combatCount = cached.combatCount + 1
            end
        end
    end
    hordeThreshold = tonumber(Const.FOLLOW_HORDE_AVOID_COUNT) or 3
    cached.active = cached.count >= hordeThreshold
        or cached.nearestDistance <= nearDistance
    if cached.count <= 0 then
        cached.nearestDistance = nil
    end
    runtime.followHazard = cached
    observeZombieHorde(record, cached.count, hordeThreshold, now)
    return cached
end

if not Internal.ResolveHordeAwareFollowTarget then
    Internal.FollowHazardCandidatePlanner = {
        Const = Const,
        TraversalQuery = TraversalQuery,
        NormalizeDirection = Internal.NormalizeDirection,
    }
    require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowHazardSteering_CandidatePlanner"
    Internal.FollowHazardTargetResolver = {
        Core = Core,
        Const = Const,
        CandidatePlanner = Internal.FollowHazardCandidatePlanner,
    }
    require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowHazardSteering_TargetResolver"
    Internal.FollowHazardSteering = {
        TargetResolver = Internal.FollowHazardTargetResolver,
    }
    require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_FollowHazardSteering"
end
