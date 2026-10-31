local Presence = PNC.Presence
local Internal = Presence.Internal
local Core = PNC.Core
local Const = PNC.Const
local Spatial = PNC.SpatialIndex
local Registry = PNC.Registry
local Audit = Internal.PresenceDiagnostics

function Presence.Reconcile(record)
    local nearest
    local bodyLost
    local shouldMaterialize
    local materializeReason
    local shouldAbstract
    if record.alive == false then return end
    -- A live shell that left the loaded world must be released before anything
    -- else. ShouldMaterialize is consulted first and its forceLive branch
    -- returns true for an already-live record, so Materialize short-circuits
    -- and the abstraction lane would never run: the record would stay paired
    -- with a body the engine already virtualized into an anonymous husk.
    bodyLost = record.presenceState == Const.PRESENCE_LIVE
        and PNC.BodyLifecycle
        and PNC.BodyLifecycle.IsRecordBodyLost
        and PNC.BodyLifecycle.IsRecordBodyLost(record) == true
    if bodyLost then
        if Presence.LogTraversal then
            Presence.LogTraversal(record, "body_lease_lost", nil, {
                "reason=body_lost",
            })
        end
        Presence.Abstract(record, "body_lost")
        return
    end
    nearest = Internal.FindNearestPlayer(record)
    record.runtime = record.runtime or {}
    record.runtime.nearestPlayerDistSq = nearest and nearest.distSq or nil
    record.runtime.lastPresenceCheckAt = Core.Now()
    record.runtime.forcePresenceCheck = nil
    shouldMaterialize, materializeReason = Presence.ShouldMaterialize(
        record,
        nearest
    )
    shouldAbstract = not shouldMaterialize
        and Presence.ShouldAbstract(record, nearest)
    if record.presenceState == Const.PRESENCE_ABSTRACT
        and Audit
        and Audit.LogDecision
    then
        Audit.LogDecision(record,
            shouldMaterialize and "allow" or "block",
            materializeReason,
            nearest,
            {
                indexed = Internal.lastInterestIndexed,
                fallback = Internal.lastInterestUsedRegistryFallback,
                schedulerDueAt = record.runtime
                    and record.runtime.schedulerDueAt,
            })
    end
    if shouldMaterialize and record.presenceState ~= Const.PRESENCE_LIVE then
        if Presence.LogTraversal then
            Presence.LogTraversal(record, "presence_decision", nil, {
                "decision=materialize",
                "reason=range_enter",
            })
        end
        Presence.Materialize(record, "range_enter", nearest)
    elseif shouldAbstract then
        if Presence.LogTraversal then
            Presence.LogTraversal(record, "presence_decision", nil, {
                "decision=abstract",
                "reason=range_exit",
            })
        end
        Presence.Abstract(record, "range_exit")
    end
end

local function collectCandidate(
    seen, ordered, record, player, radiusSq, source
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
        entry = {
            record = record,
            distSq = distSq,
            source = source or "spatial",
        }
        seen[record.id] = entry
        ordered[#ordered + 1] = entry
    elseif distSq < entry.distSq then
        entry.distSq = distSq
        if source == "spatial" then entry.source = source end
    end
end

local function collectCandidates(radius, useRegistryFallback)
    local seen = {}
    local ordered = {}
    local players = {}
    local candidates
    local indexedCount = 0
    local i
    Core.ForEachPlayer(function(player)
        players[#players + 1] = player
        candidates = Spatial.QueryNPCs(
            player:getX(),
            player:getY(),
            radius
        )
        indexedCount = indexedCount + #candidates
        for i = 1, #candidates do
            collectCandidate(
                seen,
                ordered,
                candidates[i],
                player,
                radius * radius,
                "spatial"
            )
        end
    end)
    if useRegistryFallback and Registry and Registry.ForEach then
        Registry.ForEach(function(record)
            local player
            for i = 1, #players do
                player = players[i]
                collectCandidate(
                    seen,
                    ordered,
                    record,
                    player,
                    radius * radius,
                    "registry_fallback"
                )
            end
        end)
    end
    table.sort(ordered, function(left, right)
        if left.distSq == right.distSq then
            return tostring(left.record.id) < tostring(right.record.id)
        end
        return left.distSq < right.distSq
    end)
    return ordered, #players, indexedCount
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
        record.runtime.presenceInterestSource = entry.source
        record.runtime.presenceInterestIndexed = entry.source == "spatial"
        record.runtime.presenceInterestFallback =
            entry.source == "registry_fallback"
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
    local playerCount
    local indexedCount
    local useRegistryFallback
    local indexWasReady
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
    indexWasReady = Spatial.NPCInitialized == true
    if Spatial.Rebuild then
        -- Rebuild before querying. On a relog the registry can be loaded while
        -- the index is still empty; querying first creates a one-tick blind
        -- spot and makes the nearby NPC look permanently abstract.
        Spatial.Rebuild(now, false)
    end
    useRegistryFallback = not indexWasReady
        or Spatial.NPCInitialized ~= true
        or now - (tonumber(Internal.LastRegistryFallbackAt) or 0) >= 1000
    ordered, playerCount, indexedCount = collectCandidates(
        radius,
        useRegistryFallback
    )
    if useRegistryFallback then
        Internal.LastRegistryFallbackAt = now
    end
    count = #ordered
    Internal.lastInterestIndexed = indexedCount
    Internal.lastInterestUsedRegistryFallback = useRegistryFallback
    if Audit and Audit.LogInterest then
        Audit.LogInterest(now, playerCount, indexedCount,
            useRegistryFallback, count)
    end
    wakeCandidates(ordered, now)
    return count
end
