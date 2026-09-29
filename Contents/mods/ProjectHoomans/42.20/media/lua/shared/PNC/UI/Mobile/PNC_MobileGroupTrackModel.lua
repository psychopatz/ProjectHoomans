-- Engine-free read-model that smooths abstract mobile-group markers on the
-- world map.
--
-- Abstract director groups only ever write `group.location` at the arrival
-- instant (see AbstractTraversal.Arrive). The map therefore sees a discrete
-- origin -> destination jump. This module reconstructs an in-between position
-- purely for presentation, using the world-hour span the server already ships
-- in the director debug snapshot (`groupStateStartedAt` / `groupStateEndsAt`).
--
-- Boundaries:
--   * presentation read model only - no simulation, no state mutation;
--   * no network, no new payload fields, no per-frame allocation;
--   * callers own the track table lifecycle and the snapshot receive stamp.

PNC = PNC or {}
PNC.MobileGroupTrackModel = PNC.MobileGroupTrackModel or {}

local Model = PNC.MobileGroupTrackModel

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
    return pointOf(group.location) ~= nil
        and pointOf(group.targetLocation) ~= nil
end

-- Builds or reuses a track. `existing` is optional so the caller can keep one
-- table per group id and avoid churning garbage every snapshot.
function Model.Begin(group, worldHour, existing)
    if not Model.ShouldTrack(group) then return nil end
    local from = pointOf(group.location)
    local to = pointOf(group.targetLocation)
    local startedAt = finite(group.groupStateStartedAt)
    local endsAt = finite(group.groupStateEndsAt)
    if startedAt == nil or endsAt == nil or endsAt <= startedAt then
        return nil
    end
    local now = finite(worldHour) or startedAt
    -- Clamp the visible window to the moment the marker was last confirmed.
    -- Without this a leg that has already ended server-side could glide past
    -- the snapshot and then snap backwards when the next packet arrives.
    if now > endsAt then now = endsAt end
    local track = existing or {}
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