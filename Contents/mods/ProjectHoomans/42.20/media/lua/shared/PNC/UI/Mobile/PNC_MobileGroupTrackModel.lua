-- Engine-free read-model that smooths abstract mobile-group markers on the
-- world map.
--
-- Core GroupJourney is the preferred presentation authority for abstract
-- mobile groups. Legacy snapshots without a journey retain the old straight-
-- line interpolation fallback so older save/network shapes remain readable.
--
-- Boundaries:
--   * presentation read model only - no canonical state mutation;
--   * Core route/progress is reused rather than reconstructed from a second
--     gameplay formula;
--   * all work is gated by the map layer/debug presentation lifecycle.

PNC = PNC or {}
PNC.MobileGroupTrackModel = PNC.MobileGroupTrackModel or {}

local Model = PNC.MobileGroupTrackModel

local CoreJourney
do
    local ok, module = pcall(
        require,
        "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldGroupJourney"
    )
    if ok then CoreJourney = module end
end

local function finite(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return nil
    end
    return value
end

local function pointOf(source)
    if type(source) ~= "table" then return nil end
    local x = finite(source.x)
    local y = finite(source.y)
    if x == nil or y == nil then return nil end
    return { x = x, y = y, z = finite(source.z) or 0 }
end

-- Contrast-preserving ease so slow and fast legs read as the same motion.
-- Cheaper than a smoothed step and symmetric, so mid-leg progress stays 0.5.
local function ease(progress)
    if progress <= 0 then return 0 end
    if progress >= 1 then return 1 end
    return progress * progress * (3 - 2 * progress)
end

function Model.Ease(progress)
    return ease(finite(progress) or 0)
end

-- True when a group's marker should be glided rather than snapped. Live groups
-- are authoritative elsewhere and must never be interpolated.
function Model.ShouldTrack(group)
    if type(group) ~= "table" then return false end
    if group.state ~= "TRAVELING" then return false end
    local mobile = group.mobile
    if type(mobile) == "table" and mobile.presence == "live" then
        return false
    end
    if CoreJourney and type(group.journey) == "table" then
        return true
    end
    return pointOf(group.location) ~= nil
        and pointOf(group.targetLocation) ~= nil
end

-- Builds or reuses a track. `existing` is optional so the caller can keep one
-- table per group id and avoid churning garbage every snapshot.
function Model.Begin(group, worldHour, existing)
    if not Model.ShouldTrack(group) then return nil end
    local track = existing or {}
    local now = finite(worldHour)

    if CoreJourney and type(group.journey) == "table" then
        local journey = CoreJourney.Normalize(
            group.journey,
            group.id,
            group.journey.lastAdvancedAt or now
        )
        if journey then
            track.coreJourney = journey
            track.receivedAt = now
                or journey.lastAdvancedAt
                or journey.startAt
            return track
        end
    end

    track.coreJourney = nil
    local from = pointOf(group.location)
    local to = pointOf(group.targetLocation)
    local startedAt = finite(group.groupStateStartedAt)
    local endsAt = finite(group.groupStateEndsAt)
    if startedAt == nil or endsAt == nil or endsAt <= startedAt then
        return nil
    end
    now = now or startedAt
    -- Legacy snapshots do not contain canonical route/progress. Keep the
    -- original receive clamp only for that compatibility path.
    if now > endsAt then now = endsAt end
    track.fromX, track.fromY, track.fromZ = from.x, from.y, from.z
    track.toX, track.toY, track.toZ = to.x, to.y, to.z
    track.startedAt = startedAt
    track.endsAt = endsAt
    track.receivedAt = now
    return track
end

-- Writes the interpolated marker position into `output` (or a fresh table).
-- Clamped on both ends; the span at or below `elapsed` is treated as arrived.
function Model.Position(track, worldHour, output)
    output = output or {}
    if type(track) ~= "table" then return nil end

    if CoreJourney and type(track.coreJourney) == "table" then
        local position, projected = CoreJourney.ProjectPosition(
            track.coreJourney,
            finite(worldHour)
                or track.coreJourney.lastAdvancedAt
        )
        if not position then return nil end
        output.progress = projected
            and tonumber(projected.progress) or 0
        output.x = position.x
        output.y = position.y
        output.z = position.z
        return output
    end

    local startedAt = finite(track.startedAt)
    local endsAt = finite(track.endsAt)
    if startedAt == nil or endsAt == nil or endsAt <= startedAt then
        return nil
    end
    local now = finite(worldHour) or startedAt
    -- Never run ahead of the last confirmed observation, and never rewind it.
    local ceiling = finite(track.receivedAt) or startedAt
    if now > ceiling then now = ceiling end
    local progress
    if now <= startedAt then
        progress = 0
    elseif now >= endsAt then
        progress = 1
    else
        progress = ease((now - startedAt) / (endsAt - startedAt))
    end
    output.progress = progress
    output.x = track.fromX + (track.toX - track.fromX) * progress
    output.y = track.fromY + (track.toY - track.fromY) * progress
    output.z = track.fromZ + (track.toZ - track.fromZ) * progress
    return output
end

return Model