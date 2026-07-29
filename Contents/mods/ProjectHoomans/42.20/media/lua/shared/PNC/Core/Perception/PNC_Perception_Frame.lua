-- Short-lived per-NPC perception frames. A frame performs one spatial query
-- and reuses its distance/visibility work across targeting and combat tactics.

PNC = PNC or {}
PNC.Perception = PNC.Perception or {}

local Perception = PNC.Perception
local Core = PNC.Core
local Const = PNC.Const
local Spatial = PNC.SpatialIndex
local Performance = PNC.Performance

local function frameRadius(requested)
    return math.max(
        tonumber(requested) or 0,
        tonumber(Const.ZOMBIE_TARGET_RADIUS) or 12,
        tonumber(Const.ROAM_TARGET_RADIUS) or 12,
        tonumber(Const.COMBAT_HORDE_RADIUS) or 5.5
    )
end

local function frameIsReusable(frame, record, radius, now)
    local tolerance = tonumber(Const.PERCEPTION_FRAME_MOVE_TOLERANCE) or 0.5
    if not frame or now >= (tonumber(frame.expiresAt) or 0)
        or (tonumber(frame.radius) or 0) < radius
        or tonumber(frame.z) ~= tonumber(record.z)
    then
        return false
    end
    return Core.DistanceSq(frame.x, frame.y, record.x, record.y)
        <= tolerance * tolerance
end

local function buildFrame(record, radius, now)
    local startedAt = Performance and Performance.Begin and Performance.Begin() or nil
    local candidates = Spatial and Spatial.QueryZombies
        and Spatial.QueryZombies(record.x, record.y, radius) or {}
    local entries = {}
    local radiusSq = radius * radius
    local i
    local zombie
    local distSq
    local entry
    for i = 1, #candidates do
        zombie = candidates[i]
        if zombie
            and not zombie:isDead()
            and not Core.IsManagedNPCBody(zombie)
            and math.abs(zombie:getZ() - record.z) < 1
        then
            distSq = Core.DistanceSq(
                record.x,
                record.y,
                zombie:getX(),
                zombie:getY()
            )
            if distSq <= radiusSq then
                entry = {
                    zombie = zombie,
                    distSq = distSq,
                }
                entries[#entries + 1] = entry
            end
        end
    end
    table.sort(entries, function(left, right)
        return left.distSq < right.distSq
    end)
    local frame = {
        x = record.x,
        y = record.y,
        z = record.z,
        radius = radius,
        entries = entries,
        visibleEntries = nil,
        createdAt = now,
        expiresAt = now + (tonumber(Const.PERCEPTION_FRAME_MS) or 200),
    }
    if Performance then
        Performance.Count("perception.framesBuilt", 1)
        Performance.Count("perception.candidates", #candidates)
        Performance.Finish("perception.buildFrame", startedAt)
    end
    return frame
end

function Perception.InvalidateFrame(record)
    if record and record.runtime then
        record.runtime.perceptionFrame = nil
        record.runtime.perceptionVisibilityCache = nil
    end
end

function Perception.GetZombieFrame(record, requestedRadius)
    local now
    local radius
    local frame
    if not record then return nil end
    record.runtime = record.runtime or {}
    now = Core.Now()
    radius = frameRadius(requestedRadius)
    frame = record.runtime.perceptionFrame
    if frameIsReusable(frame, record, radius, now) then
        if Performance then Performance.Count("perception.frameHits", 1) end
        return frame
    end
    frame = buildFrame(record, radius, now)
    record.runtime.perceptionFrame = frame
    return frame
end

function Perception.GetVisibleZombieEntries(record, requestedRadius)
    local frame = Perception.GetZombieFrame(record, requestedRadius)
    local output
    local filtered
    local requestedRadiusSq = (tonumber(requestedRadius)
        or tonumber(Const.ZOMBIE_TARGET_RADIUS)
        or 12) ^ 2
    local limit
    local startIndex
    local endIndex
    local i
    local entry
    local visible
    local visibilityKind
    local recent
    local recentID
    local modData
    if not frame then return {} end
    if not frame.visibleEntries then
        output = {}
        limit = math.max(1, math.floor(
            tonumber(Const.PERCEPTION_LOS_MAX_CANDIDATES) or 6
        ))
        startIndex = math.max(
            1,
            math.floor(
                tonumber(record.runtime.perceptionLosCursor) or 1
            )
        )
        if startIndex > #frame.entries then startIndex = 1 end
        endIndex = math.min(#frame.entries, startIndex + limit - 1)
        for i = startIndex, endIndex do
            entry = frame.entries[i]
            visible, visibilityKind = Perception.CanSeeWorldObject(
                record,
                entry.zombie
            )
            if Performance then Performance.Count("perception.losChecks", 1) end
            if visible then
                output[#output + 1] = {
                    zombie = entry.zombie,
                    distSq = entry.distSq,
                    visibilityKind = visibilityKind,
                }
            end
        end
        if #output <= 0 and endIndex < #frame.entries then
            record.runtime.perceptionLosCursor = endIndex + 1
        else
            record.runtime.perceptionLosCursor = 1
        end
        recent = record.runtime and record.runtime.recentThreat or nil
        recentID = recent and recent.kind == "zombie"
            and tostring(recent.id or "") or nil
        if recentID and recentID ~= "" then
            for i = 1, #frame.entries do
                entry = frame.entries[i]
                modData = entry.zombie and entry.zombie.getModData
                    and entry.zombie:getModData() or nil
                if (i < startIndex or i > endIndex)
                    and modData
                    and tostring(modData.PNC_ZombieID or "") == recentID
                then
                    visible, visibilityKind = Perception.CanSeeWorldObject(
                        record,
                        entry.zombie
                    )
                    if Performance then
                        Performance.Count("perception.losChecks", 1)
                    end
                    if visible then
                        output[#output + 1] = {
                            zombie = entry.zombie,
                            distSq = entry.distSq,
                            visibilityKind = visibilityKind,
                        }
                    end
                    break
                end
            end
        end
        frame.visibleEntries = output
    end
    filtered = {}
    for i = 1, #frame.visibleEntries do
        entry = frame.visibleEntries[i]
        if entry.distSq <= requestedRadiusSq then
            filtered[#filtered + 1] = entry
        end
    end
    return filtered
end

function Perception.CountZombiesInFrame(record, radius)
    local frame = Perception.GetZombieFrame(record, radius)
    local radiusSq = (tonumber(radius) or 0) ^ 2
    local count = 0
    local i
    if not frame then return 0 end
    for i = 1, #frame.entries do
        if frame.entries[i].distSq <= radiusSq then
            count = count + 1
        else
            break
        end
    end
    return count
end
