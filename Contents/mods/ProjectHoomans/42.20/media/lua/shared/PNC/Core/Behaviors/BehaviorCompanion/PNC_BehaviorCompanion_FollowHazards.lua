-- Zombie-density sensing and short-lived steering targets for followers.

local Internal = PNC.BehaviorCompanion.Internal
local Core = PNC.Core
local Const = PNC.Const
local Perception = PNC.Perception
local TraversalQuery = PNC.TraversalQuery
local Diagnostics = PNC.PerformanceScalingDiagnostics

-- Followers in one formation usually occupy the same few tiles. Reuse a
-- short-lived candidate pool for that owner instead of rebuilding the same
-- spatial query for every follower. The pool is deliberately wider than the
-- exact hazard radius; every follower still applies its own exact-distance
-- filter below, so sharing cannot make a follower react to a distant zombie.
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
    local reuseRadius = FOLLOW_CANDIDATE_REUSE_DISTANCE
    local candidates
    local cacheHit
    if not Perception or not Perception.GetZombieCandidatesAt then
        return {}
    end
    candidates, cacheHit = Perception.GetZombieCandidatesAt(
        x,
        y,
        z,
        radius,
        "follow:" .. tostring(ownerKey),
        tonumber(Const.FOLLOW_HORDE_SCAN_MS) or 150,
        reuseRadius,
        now
    )
    if Diagnostics then
        Diagnostics.Increment(
            cacheHit
                and "Follow.HazardCandidateCacheHits"
                or "Follow.HazardCandidateQueries"
        )
    end
    return candidates or {}
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
