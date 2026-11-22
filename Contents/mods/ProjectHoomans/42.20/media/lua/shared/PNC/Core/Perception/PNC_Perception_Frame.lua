-- Short-lived per-NPC perception frames. A frame performs one spatial query
-- and reuses its distance/visibility work across targeting and combat tactics.

PNC = PNC or {}
PNC.Perception = PNC.Perception or {}

local Perception = PNC.Perception
local Core = PNC.Core
local Const = PNC.Const

local function isActualZombieBody(zombie)
    if type(Perception.IsActualZombieBody) == "function" then
        return Perception.IsActualZombieBody(zombie) == true
    end
    -- Keep this module safe when a focused harness loads it without the
    -- ordered PNC_Perception composition. The production path always uses
    -- the registry-aware classifier above.
    return not Core.IsManagedNPCBody(zombie)
end

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
    local tolerance = tonumber(Const.PERCEPTION_FRAME_MOVE_TOLERANCE) or 0.5
    local cacheKey = "frame:" .. tostring(record.id or record)
    local candidates = Perception.GetZombieCandidatesAt
        and Perception.GetZombieCandidatesAt(
            record.x,
            record.y,
            record.z,
            radius,
            cacheKey,
            tonumber(Const.PERCEPTION_FRAME_MS) or 200,
            tolerance,
            now
        ) or {}
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
            and isActualZombieBody(zombie)
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
        return frame
    end
    frame = buildFrame(record, radius, now)
    record.runtime.perceptionFrame = frame
    return frame
end

local function zombieEntryId(zombie)
    local modData = zombie and zombie.getModData and zombie:getModData() or nil
    if modData and modData.PNC_ZombieID ~= nil then
        return tostring(modData.PNC_ZombieID)
    end
    if PNC.SpatialIndex and type(PNC.SpatialIndex.GetZombieID) == "function" and zombie then
        local zId = PNC.SpatialIndex.GetZombieID(zombie)
        if zId ~= nil then return tostring(zId) end
    end
    return nil
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
    local lastChecked
    local i
    local entry
    local visible
    local visibilityKind
    local recent
    local recentID
    local attackerID
    local activeTargetID
    local zId
    local svc
    local observer
    local profile
    local coneRejected = 0
    local checked = 0
    local losCount = 0
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
        recent = record.runtime and record.runtime.recentThreat or nil
        recentID = recent and recent.kind == "zombie"
            and tostring(recent.id or "") or nil
        attackerID = record.runtime and record.runtime.zombieAttacker
            and tostring(record.runtime.zombieAttacker.zombieId or "") or nil
        activeTargetID = record.runtime and record.runtime.target
            and record.runtime.target.kind == "zombie"
            and tostring(record.runtime.target.zombieId or "") or nil
        svc = PNC.PerceptionService
        observer = PNC.Registry and PNC.Registry.GetLiveZombie
            and PNC.Registry.GetLiveZombie(record.id) or nil
        profile = svc and type(svc.GetProfile) == "function"
            and svc.GetProfile(record) or nil
        local useConeFilter = svc
            and type(svc.PassesBodyVisionCone) == "function"
        local totalEntries = #frame.entries
        lastChecked = startIndex - 1
        while checked < totalEntries and losCount < limit do
            i = ((startIndex + checked - 1) % totalEntries) + 1
            checked = checked + 1
            lastChecked = i
            entry = frame.entries[i]
            zId = zombieEntryId(entry.zombie)
            local isEngaged = zId ~= nil and (
                zId == recentID or zId == attackerID or zId == activeTargetID
                or (Perception.IsWarnedThreat ~= nil
                    and Perception.IsWarnedThreat(record, "zombie", zId) == true)
            )
            local inCone = true
            if useConeFilter then
                inCone = svc.PassesBodyVisionCone(
                    record,
                    entry.zombie,
                    profile,
                    observer,
                    { radius = frame.radius, bypassCone = isEngaged }
                )
            end
            if not inCone then
                coneRejected = coneRejected + 1
            else
                losCount = losCount + 1
                visible, visibilityKind = Perception.CanSeeWorldObject(
                    record,
                    entry.zombie
                )
                if visible then
                    output[#output + 1] = {
                        zombie = entry.zombie,
                        distSq = entry.distSq,
                        visibilityKind = visibilityKind,
                    }
                end
            end
        end
        frame.coneRejectedCount = coneRejected
        if #output <= 0 and totalEntries > 0 and lastChecked < totalEntries then
            record.runtime.perceptionLosCursor = lastChecked + 1
        else
            record.runtime.perceptionLosCursor = 1
        end
        if recentID and recentID ~= "" then
            local alreadyIncluded = false
            for j = 1, #output do
                if zombieEntryId(output[j].zombie) == recentID then
                    alreadyIncluded = true
                    break
                end
            end
            if not alreadyIncluded then
                for k = 1, totalEntries do
                    entry = frame.entries[k]
                    if zombieEntryId(entry.zombie) == recentID then
                        visible, visibilityKind = Perception.CanSeeWorldObject(
                            record,
                            entry.zombie
                        )
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
