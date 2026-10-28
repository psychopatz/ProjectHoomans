-- Canonical runtime zombie-pressure observation.
--
-- Reuses the existing WorldCensus -> SpatialIndex -> Perception frame. This
-- module never enumerates the engine zombie list and persists nothing.
PNC = PNC or {}
PNC.ZombieObservation = PNC.ZombieObservation or {}

local Observation = PNC.ZombieObservation
local Const = PNC.Const
local Core = PNC.Core
local Perception = PNC.Perception

Observation.VERSION = 1

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then return fallback end
    return value
end

function Observation.Classify(count)
    count = math.max(0, math.floor(finite(count, 0)))
    local band
    if count <= 0 then band = "none"
    elseif count <= 2 then band = "few"
    elseif count <= 5 then band = "several"
    elseif count <= 11 then band = "horde"
    else band = "massive_horde" end

    -- Compatibility labels are derived here so older presentation/world-fact
    -- fields no longer own separate threshold tables.
    local socialBand
    if count >= 8 then socialBand = "large"
    elseif count >= 5 then socialBand = "several"
    elseif count >= 3 then socialBand = "few" end

    local knowledgeBand
    if count >= 12 then knowledgeBand = "horde"
    elseif count >= 6 then knowledgeBand = "heavy"
    elseif count >= 3 then knowledgeBand = "moderate"
    else knowledgeBand = "light" end

    return {
        count = count,
        band = band,
        socialBand = socialBand,
        knowledgeBand = knowledgeBand,
    }
end

local function cacheValid(record, cached, now)
    if type(cached) ~= "table" then return false end
    local expiresAt = finite(cached.expiresAt, 0)
    if now >= expiresAt then return false end
    if tonumber(cached.z) ~= tonumber(record.z) then return false end
    local dx = (finite(record.x, 0) - finite(cached.x, 0))
    local dy = (finite(record.y, 0) - finite(cached.y, 0))
    return (dx * dx) + (dy * dy) <= 0.25
end

function Observation.Snapshot(record)
    local runtime = record and record.runtime or nil
    local value = runtime and runtime.zombieObservation or nil
    if type(value) ~= "table" then return nil end
    return {
        schemaVersion = Observation.VERSION,
        observedAt = value.observedAt,
        nearbyCount = value.nearbyCount,
        hordeCount = value.hordeCount,
        band = value.band,
        tacticalHorde = value.tacticalHorde == true,
        source = value.source,
    }
end

function Observation.ObserveRecord(record, now)
    if not record or record.alive == false then return nil end
    if record.presenceState ~= nil
        and tostring(record.presenceState) ~= "live"
        and tostring(record.presenceState) ~= tostring(
            Const and Const.PRESENCE_LIVE or "live"
        )
    then return nil end
    if not Perception or type(Perception.CountZombiesInFrame) ~= "function" then
        return nil
    end

    record.runtime = record.runtime or {}
    now = finite(now, Core and Core.Now and Core.Now() or 0)
    local cached = record.runtime.zombieObservation
    if cacheValid(record, cached, now) then return cached end

    local nearbyRadius = finite(Const and Const.ZOMBIE_TARGET_RADIUS, 12)
    local hordeRadius = finite(Const and Const.COMBAT_HORDE_RADIUS, 5.5)
    local threshold = math.max(1,
        math.floor(finite(Const and Const.COMBAT_HORDE_COUNT, 4)))
    local nearby = math.max(0,
        math.floor(finite(Perception.CountZombiesInFrame(
            record, nearbyRadius), 0)))
    local horde = math.max(0,
        math.floor(finite(Perception.CountZombiesInFrame(
            record, hordeRadius), 0)))
    local classified = Observation.Classify(horde)
    local cacheMs = math.max(100,
        math.floor(finite(Const and Const.ZOMBIE_OBSERVATION_CACHE_MS, 750)))

    cached = {
        schemaVersion = Observation.VERSION,
        x = finite(record.x, 0),
        y = finite(record.y, 0),
        z = finite(record.z, 0),
        observedAt = now,
        expiresAt = now + cacheMs,
        nearbyCount = nearby,
        hordeCount = horde,
        band = classified.band,
        socialBand = classified.socialBand,
        knowledgeBand = classified.knowledgeBand,
        tacticalHorde = horde >= threshold,
        source = "perception_frame",
    }
    record.runtime.zombieObservation = cached

    if cached.tacticalHorde then
        local hooks = PNC and PNC.SocialEventHooks
        if hooks and type(hooks.ObserveZombieHorde) == "function" then
            pcall(hooks.ObserveZombieHorde,
                record, horde, threshold, now, "ambient")
        end
    end
    return cached
end

return Observation
