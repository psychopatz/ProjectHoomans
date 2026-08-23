local Presence = PNC.Presence
local Internal = Presence.Internal
local Core = PNC.Core
local Const = PNC.Const
local Spatial = PNC.SpatialIndex

function Presence.Reconcile(record)
    local nearest
    if record.alive == false then return end
    nearest = Internal.FindNearestPlayer(record)
    record.runtime = record.runtime or {}
    record.runtime.nearestPlayerDistSq = nearest and nearest.distSq or nil
    record.runtime.lastPresenceCheckAt = Core.Now()
    record.runtime.forcePresenceCheck = nil
    if Presence.ShouldMaterialize(record, nearest) then
        Presence.Materialize(record, "range_enter", nearest)
    elseif Presence.ShouldAbstract(record, nearest) then
        Presence.Abstract(record, "range_exit")
    end
end

local function collectCandidate(
    seen, ordered, record, player, radiusSq
)
    local distSq
    local entry
    if not record or not record.id or record.alive == false
        or record.presenceState ~= Const.PRESENCE_ABSTRACT
    then
        return
    end
    distSq = Core.DistanceSq(
        record.x, record.y, player:getX(), player:getY()
    )
    if distSq > radiusSq then return end
    entry = seen[record.id]
    if not entry then
        entry = { record = record, distSq = distSq }
        seen[record.id] = entry
        ordered[#ordered + 1] = entry
    elseif distSq < entry.distSq then
        entry.distSq = distSq
    end
end

local function collectCandidates(radius)
    local seen = {}
    local ordered = {}
    local candidates
    local i
    Core.ForEachPlayer(function(player)
        candidates = Spatial.QueryNPCs(
            player:getX(),
            player:getY(),
            radius
        )
        for i = 1, #candidates do
            collectCandidate(
                seen,
                ordered,
                candidates[i],
                player,
                radius * radius
            )
        end
    end)
    table.sort(ordered, function(left, right)
        if left.distSq == right.distSq then
            return tostring(left.record.id) < tostring(right.record.id)
        end
        return left.distSq < right.distSq
    end)
    return ordered
end

local function wakeCandidates(ordered, now)
    local slotMs = tonumber(PNC.Scheduler and PNC.Scheduler.SLOT_MS)
        or 50
    local i
    local entry
    local record
    for i = 1, #ordered do
        entry = ordered[i]
        record = entry.record
        record.runtime = record.runtime or {}
        record.runtime.nearestPlayerDistSq = entry.distSq
        record.runtime.forcePresenceCheck = true
        if PNC.SimulationClock and PNC.SimulationClock.Wake then
            PNC.SimulationClock.Wake(record, "presence", now)
        end
        if PNC.Scheduler and PNC.Scheduler.Schedule then
            PNC.Scheduler.Schedule(record, now + i * slotMs)
        end
    end
end

function Presence.RefreshMaterializationCandidates(now, force)
    local ordered
    local count
    local radius = tonumber(Const.MATERIALIZE_DISTANCE) or 28
    now = tonumber(now) or Core.Now()
    if force ~= true
        and now - (tonumber(Internal.LastInterestRefreshAt) or 0)
            < (tonumber(Const.PRESENCE_INTEREST_REFRESH_MS) or 250)
    then
        return 0
    end
    Internal.LastInterestRefreshAt = now
    if not Spatial or not Spatial.QueryNPCs then return 0 end
    ordered = collectCandidates(radius)
    count = #ordered
    wakeCandidates(ordered, now)
    if count > 0 and Spatial.Rebuild then
        -- One fresh index keeps batch shell cleanup and first-frame
        -- perception safe without returning to one global scan per NPC.
        Spatial.Rebuild(now, true)
    end
    return count
end
