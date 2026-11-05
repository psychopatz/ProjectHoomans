--[[
    PNC Perception
    Stable entry point for target history, visibility, hostile scanning, and
    high-level target resolution providers.
]]

PNC = PNC or {}
PNC.Perception = PNC.Perception or {}
PNC.Perception.Internal = PNC.Perception.Internal or {}

local Perception = PNC.Perception
local Core = PNC.Core or {}
local Const = PNC.Const or {}
local Spatial = PNC.SpatialIndex
local Diagnostics = PNC.PerformanceScalingDiagnostics

Perception.CandidateCache = Perception.CandidateCache or {}
Perception.CandidateCacheKeys = Perception.CandidateCacheKeys or {}

local function isIsoZombieBody(body)
    if not body then return false end
    if type(instanceof) == "function" then
        return instanceof(body, "IsoZombie")
    end
    return type(body.isZombie) == "function"
        and body:isZombie() == true
end

-- The engine represents a materialized Hoomans NPC with an IsoZombie shell.
-- Target kind must therefore be decided by ownership/registry state, not by
-- the Java class alone. This is the shared boundary for perception, recent
-- threat recovery, and combat authorization.
function Perception.IsActualZombieBody(body)
    local registry
    if not isIsoZombieBody(body) then return false end
    if Core and type(Core.IsManagedNPCBody) == "function"
        and Core.IsManagedNPCBody(body) == true
    then
        return false
    end
    registry = PNC.Registry
    if registry and type(registry.FindRecordByZombie) == "function"
        and registry.FindRecordByZombie(body) ~= nil
    then
        return false
    end
    return true
end

function Perception.IsActualZombieTarget(target)
    local body
    if type(target) ~= "table" or target.kind ~= "zombie" then
        return false
    end
    body = target.zombie or target.worldObject
    if not body and target.zombieId
        and type(Perception.FindZombieByID) == "function"
    then
        body = Perception.FindZombieByID(target.zombieId)
    end
    return Perception.IsActualZombieBody(body)
end

local function candidateNow(value)
    if value ~= nil then return tonumber(value) or 0 end
    if Core and type(Core.Now) == "function" then
        return Core.Now()
    end
    return 0
end

-- The spatial index remains the storage/query primitive. This is the single
-- perception-owned boundary used by hazard, combat, defense, stealth, and
-- frame consumers. Callers retain their own domain filtering; this cache only
-- shares the bounded candidate list and never makes a gameplay decision.
function Perception.GetZombieCandidatesAt(
    x,
    y,
    z,
    radius,
    cacheKey,
    ttl,
    reuseDistance,
    now
)
    local cache = Perception.CandidateCache
    local keys = Perception.CandidateCacheKeys
    local scope = tostring(cacheKey or "default")
    local bucket = cache[scope]
    local entry
    local candidateNowValue = candidateNow(now)
    local distanceSq
    local reuseSq
    local queryRadius
    local candidates
    local maxScopes
    local i
    x = tonumber(x) or 0
    y = tonumber(y) or 0
    z = tonumber(z) or 0
    radius = math.max(0, tonumber(radius) or 0)
    ttl = math.max(
        0,
        tonumber(ttl) or tonumber(Const.PERCEPTION_CANDIDATE_CACHE_MS) or 100
    )
    reuseDistance = math.max(0, tonumber(reuseDistance) or 0)
    reuseSq = reuseDistance * reuseDistance

    if bucket then
        for i = 1, #bucket do
            entry = bucket[i]
            if entry
                and candidateNowValue < (tonumber(entry.expiresAt) or 0)
                and (tonumber(entry.radius) or 0) >= radius
                and math.abs((tonumber(entry.z) or z) - z) < 1
            then
                distanceSq = Core.DistanceSq(
                    tonumber(entry.x) or x,
                    tonumber(entry.y) or y,
                    x,
                    y
                )
                if distanceSq <= reuseSq then
                    if Diagnostics and Diagnostics.Increment then
                        Diagnostics.Increment(
                            "Perception.CandidateSnapshot.CacheHits"
                        )
                    end
                    return entry.candidates, true
                end
            end
        end
    end

    if not Spatial or type(Spatial.QueryZombies) ~= "function" then
        return {}, false
    end

    if not bucket then
        maxScopes = math.max(
            1,
            math.floor(
                tonumber(Const.PERCEPTION_CANDIDATE_CACHE_MAX) or 128
            )
        )
        if #keys >= maxScopes then
            cache[keys[1]] = nil
            table.remove(keys, 1)
        end
        bucket = {}
        cache[scope] = bucket
        keys[#keys + 1] = scope
    end

    queryRadius = radius + reuseDistance
    candidates = Spatial.QueryZombies(x, y, queryRadius) or {}
    entry = {
        x = x,
        y = y,
        z = z,
        radius = queryRadius,
        candidates = candidates,
        expiresAt = candidateNowValue + ttl,
    }
    if #bucket < 2 then
        bucket[#bucket + 1] = entry
    else
        bucket[1] = bucket[2]
        bucket[2] = entry
    end
    if Diagnostics and Diagnostics.Increment then
        Diagnostics.Increment("Perception.CandidateSnapshot.Queries")
    end
    return candidates, false
end

require "PNC/Core/Perception/PNC_Perception/ThreatHistory"
require "PNC/Core/Perception/PNC_Perception/Visibility"
require "PNC/Core/Perception/PNC_Perception/ActorSearch"
require "PNC/Core/Perception/PNC_Perception/NPCThreatAlert"
require "PNC/Core/Perception/PNC_Perception/ZombieSearch"
require "PNC/Core/Perception/PNC_Perception/ImmediateEnemy"
require "PNC/Core/Perception/PNC_Perception/ImmediateThreat"
require "PNC/Core/Perception/PNC_Perception/ZombieRanking"
require "PNC/Core/Perception/PNC_Perception/OwnerDefense"
require "PNC/Core/Perception/PNC_Perception/Resolvers"
