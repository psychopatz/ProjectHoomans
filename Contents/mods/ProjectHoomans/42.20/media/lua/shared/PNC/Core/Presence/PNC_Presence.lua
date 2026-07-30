PNC = PNC or {}
PNC.Presence = PNC.Presence or {}

local Presence = PNC.Presence
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local Health = PNC.Health
local Animation = PNC.Animation
local Visuals = PNC.Visuals
local Equipment = PNC.Equipment
local PathService = PNC.PathService
local LiveBodyControl = PNC.LiveBodyControl
local ZombieAggro = PNC.ZombieAggro
local Spatial = PNC.SpatialIndex
local Admission = PNC.PresenceAdmission
local MaterializationSafety = PNC.MaterializationSafety
local Network = nil
local lastInterestRefreshAt = 0
local materializationBudget = {
    tickAt = nil,
    count = 0,
}

local function resolveNetwork()
    if not Network then
        Network = PNC.Network
    end
    return Network
end

function Presence.BeginServerTick(now)
    materializationBudget.tickAt = tonumber(now) or Core.Now()
    materializationBudget.count = 0
end

local function consumeMaterializationBudget(record, reason, nearest)
    local now
    local maximum
    local allowed
    local admissionReason
    if tostring(reason or "") ~= "range_enter" then return true end
    now = Core.Now()
    if materializationBudget.tickAt ~= now then
        materializationBudget.tickAt = now
        materializationBudget.count = 0
    end
    maximum = math.max(
        1,
        math.floor(tonumber(Const.MATERIALIZE_MAX_PER_TICK) or 2)
    )
    if Admission and Admission.Evaluate then
        allowed, admissionReason = Admission.Evaluate(record, nearest)
        if allowed == false then
            record.runtime = record.runtime or {}
            record.runtime.materializeAdmissionReason = admissionReason
            record.runtime.materializeRetryAt = now
                + (tonumber(Const.LIVE_BODY_ADMISSION_RETRY_MS) or 1000)
            return false
        end
    end
    if materializationBudget.count < maximum then
        materializationBudget.count = materializationBudget.count + 1
        record.runtime = record.runtime or {}
        record.runtime.materializeAdmissionReason = nil
        return true
    end
    record.runtime = record.runtime or {}
    record.runtime.forcePresenceCheck = true
    if PNC.SimulationClock and PNC.SimulationClock.Wake then
        PNC.SimulationClock.Wake(record, "presence", now)
    end
    return false
end

local function findMaterializeSquare(record, now, reason)
    local cell
    local query
    local safeX
    local safeY
    local safeZ
    local recoveryReason

    if not getCell then
        return record.x, record.y, record.z, nil
    end

    cell = getCell()
    if MaterializationSafety and MaterializationSafety.Resolve then
        return MaterializationSafety.Resolve(record, now, cell, {
            requireSettle = tostring(reason or "") == "range_enter",
        })
    end
    query = PNC.TraversalQuery
    if query and query.FindNearestMaterializationSquare then
        safeX, safeY, safeZ, recoveryReason =
            query.FindNearestMaterializationSquare(
            record.x,
            record.y,
            record.z,
            tonumber(Const.MATERIALIZE_SAFE_RADIUS) or 8,
            cell
        )
        return safeX, safeY, safeZ, recoveryReason
    end
    return record.x, record.y, record.z, nil
end

local function logPositionRecovery(record, eventName, recoveryReason, fromX, fromY, fromZ, toX, toY, toZ)
    local recovery
    local message
    if not record then return end
    record.runtime = record.runtime or {}
    recovery = record.runtime.positionRecovery or {}
    record.runtime.positionRecovery = recovery
    recovery.count = (tonumber(recovery.count) or 0) + 1
    recovery.lastAt = Core.Now()
    recovery.lastEvent = eventName
    recovery.lastReason = recoveryReason
    recovery.fromX = fromX
    recovery.fromY = fromY
    recovery.fromZ = fromZ
    recovery.toX = toX
    recovery.toY = toY
    recovery.toZ = toZ
    message = "NPC position recovery npc=" .. tostring(record.id)
        .. " name=" .. tostring(record.name or "Unknown NPC")
        .. " event=" .. tostring(eventName)
        .. " reason=" .. tostring(recoveryReason or "blocked")
        .. " from=" .. tostring(fromX) .. "," .. tostring(fromY) .. "," .. tostring(fromZ)
        .. " to=" .. tostring(toX) .. "," .. tostring(toY) .. "," .. tostring(toZ)
        .. " count=" .. tostring(recovery.count)
    Core.LogWarn(message)
    Core.LogRecordDebug(record, message)
end

local function findNearestPlayer(record)
    local radius = math.max(
        tonumber(Const.ABSTRACT_NEAR_DISTANCE) or 80,
        tonumber(Const.ABSTRACT_DISTANCE) or 40
    )
    local players = Spatial and Spatial.QueryPlayers
        and Spatial.QueryPlayers(record.x, record.y, radius) or nil
    local nearest
    local bestDistSq = math.huge
    local i
    local player
    local distSq
    if not players then
        return Core.GetNearestPlayerPosition(record.x, record.y)
    end
    for i = 1, #players do
        player = players[i]
        if player then
            distSq = Core.DistanceSq(
                record.x,
                record.y,
                player:getX(),
                player:getY()
            )
            if distSq < bestDistSq then
                bestDistSq = distSq
                nearest = {
                    player = player,
                    x = player:getX(),
                    y = player:getY(),
                    z = player:getZ(),
                    distSq = distSq,
                }
            end
        end
    end
    return nearest
end

function Presence.ShouldMaterialize(record, nearest)
    nearest = nearest or findNearestPlayer(record)
    if record.alive == false or record.presenceState == Const.PRESENCE_CORPSE then
        return false
    end
    if record.runtime and record.runtime.forceAbstract then
        return false
    end
    if PNC.BodyLifecycle
        and PNC.BodyLifecycle.IsStartupBodyCleanupComplete
        and not PNC.BodyLifecycle.IsStartupBodyCleanupComplete()
    then
        return false
    end
    -- Vehicle companions intentionally have no IsoZombie body. The companion
    -- vehicle coordinator updates their abstract position and explicitly
    -- materializes them after the owner exits.
    if record.runtime and record.runtime.vehiclePassenger
        and record.runtime.vehiclePassenger.active == true
    then
        return false
    end
    if record.runtime
        and Core.Now() < (tonumber(record.runtime.materializeRetryAt) or 0)
    then
        return false
    end
    if record.runtime and record.runtime.forceLive then
        return true
    end
    return nearest and nearest.distSq <= (Const.MATERIALIZE_DISTANCE * Const.MATERIALIZE_DISTANCE) or false
end

function Presence.ShouldAbstract(record, nearest)
    nearest = nearest or findNearestPlayer(record)
    if record.presenceState ~= Const.PRESENCE_LIVE then
        return false
    end
    if record.runtime and record.runtime.forceLive then
        return false
    end
    if record.runtime and record.runtime.forceAbstract then
        return true
    end
    if record.runtime and record.runtime.target then
        return false
    end
    return (not nearest) or nearest.distSq >= (Const.ABSTRACT_DISTANCE * Const.ABSTRACT_DISTANCE)
end

function Presence.Materialize(record, reason, nearest)
    local zombieList
    local zombie
    local spawnX
    local spawnY
    local spawnZ
    local recoveryReason
    local deferredReason
    local originalX
    local originalY
    local originalZ
    local now
    local net = resolveNetwork()
    if not Core.IsAuthority() or record.alive == false or record.presenceState == Const.PRESENCE_LIVE then
        return Registry.GetLiveZombie(record.id)
    end
    if PNC.BodyLifecycle
        and PNC.BodyLifecycle.IsStartupBodyCleanupComplete
        and not PNC.BodyLifecycle.IsStartupBodyCleanupComplete()
    then
        return nil
    end

    record.runtime = record.runtime or {}
    if PNC.Inventory and PNC.Inventory.EnsureRecordInventory then
        PNC.Inventory.EnsureRecordInventory(record)
    end
    if PNC.Travel and PNC.Travel.Service
        and PNC.Travel.Service.Get(record)
    then
        PNC.Travel.Service.Advance(record, PNC.Travel.Service.WorldHour())
    end
    originalX = record.x
    originalY = record.y
    originalZ = record.z
    now = Core.Now()
    spawnX, spawnY, spawnZ, recoveryReason, deferredReason =
        findMaterializeSquare(record, now, reason)
    if deferredReason and deferredReason ~= "no_safe_square" then
        if MaterializationSafety and MaterializationSafety.Defer then
            MaterializationSafety.Defer(record, deferredReason, now)
        else
            record.runtime.materializeRetryAt = now
                + (tonumber(Const.MATERIALIZE_CHUNK_RETRY_MS) or 250)
        end
        record.runtime.lifecycle = record.runtime.lifecycle or {}
        record.runtime.lifecycle.phase = Const.PRESENCE_ABSTRACT
        record.runtime.lifecycle.bodyState = "missing"
        record.runtime.lifecycle.lastReason = "materialize_deferred"
        record.runtime.lifecycle.lastError = tostring(deferredReason)
        return nil
    end
    if spawnX == nil or spawnY == nil or spawnZ == nil then
        record.runtime.lifecycle = record.runtime.lifecycle or {}
        record.runtime.lifecycle.phase = Const.PRESENCE_ABSTRACT
        record.runtime.lifecycle.bodyState = "missing"
        record.runtime.lifecycle.lastReason = "materialize_position_blocked"
        record.runtime.lifecycle.lastError = "no_safe_square:" .. tostring(recoveryReason or "unknown")
        record.runtime.materializeRetryAt = Core.Now() + 5000
        Core.LogWarn("NPC position recovery deferred npc=" .. tostring(record.id)
            .. " name=" .. tostring(record.name or "Unknown NPC")
            .. " event=materialize_no_safe_square"
            .. " reason=" .. tostring(recoveryReason or "unknown")
            .. " at=" .. tostring(originalX) .. "," .. tostring(originalY) .. "," .. tostring(originalZ))
        return nil
    end
    if not consumeMaterializationBudget(record, reason, nearest) then
        return nil
    end
    if PNC.BodyLifecycle and PNC.BodyLifecycle.CleanupRecordShells
        and PNC.BodyLifecycle.CleanupRecordShells(record, now) > 0
    then
        return nil
    end

    record.runtime.bodyLease = nil
    record.runtime.lifecycle = record.runtime.lifecycle or {}
    record.runtime.lifecycle.phase = "materializing"
    record.runtime.lifecycle.lastReason = reason or "materialize"
    record.runtime.lifecycle.lastError = nil
    record.runtime.lifecycle.lastTransitionAt = now
    if MaterializationSafety and MaterializationSafety.Reset then
        MaterializationSafety.Reset(record)
    end
    record.runtime.materializeRetryAt = nil
    zombieList = addZombiesInOutfit(
        spawnX,
        spawnY,
        spawnZ,
        1,
        "Naked",
        record.isFemale and 100 or 0,
        false,
        false,
        false,
        false,
        true,
        false,
        1
    )

    if not zombieList or zombieList:size() <= 0 then
        record.runtime.lifecycle.phase = Const.PRESENCE_ABSTRACT
        record.runtime.lifecycle.bodyState = "missing"
        record.runtime.lifecycle.lastReason = "materialize_failed"
        record.runtime.lifecycle.lastError = "spawn_returned_no_body"
        Core.LogWarn("Failed to materialize NPC " .. tostring(record.id) .. " reason=" .. tostring(reason))
        return nil
    end

    zombie = zombieList:get(0)
    if zombie.DoZombieStats then
        zombie:DoZombieStats()
    end
    record.runtime.target = nil
    Animation.ApplyLiveSetup(zombie, record)
    Visuals.ApplyHumanVisuals(zombie, record)
    Equipment.Apply(zombie, record)
    if LiveBodyControl and LiveBodyControl.SetManagedBodyUseless then
        LiveBodyControl.SetManagedBodyUseless(zombie, true)
    end

    record.x = spawnX
    record.y = spawnY
    record.z = spawnZ
    if recoveryReason and Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "position_recovery")
    end
    if recoveryReason then
        logPositionRecovery(
            record,
            "materialize_relocate",
            recoveryReason,
            originalX,
            originalY,
            originalZ,
            spawnX,
            spawnY,
            spawnZ
        )
    end
    record.presenceState = Const.PRESENCE_LIVE
    Registry.RegisterLiveZombie(record, zombie)
    if PNC.Travel and PNC.Travel.Service then
        PNC.Travel.Service.OnMaterialized(record)
    end
    Health.Update(record, zombie, Core.Now())
    if record.alive == false then
        return nil
    end
    Animation.Apply(zombie, record, "Idle")

    if net and net.BroadcastRecord then
        net.BroadcastRecord(record, "materialize")
    end

    return zombie
end

function Presence.Abstract(record, reason)
    local zombie = Registry.GetLiveZombie(record.id)
    local net = resolveNetwork()
    if not Core.IsAuthority() or record.presenceState ~= Const.PRESENCE_LIVE then
        return false
    end
    if PNC.FactionIncidentService
        and PNC.FactionIncidentService.CleanupEntity
        and PNC.EntityRef
    then
        PNC.FactionIncidentService.CleanupEntity(
            PNC.EntityRef.ForNPC(record.id),
            getGameTime and getGameTime()
                and getGameTime().getWorldAgeHours
                and getGameTime():getWorldAgeHours() or 0,
            reason or "target_abstracted"
        )
    end
    if PNC.FactionTelemetry then
        PNC.FactionTelemetry.RecordCallback({
            operation = "npc_abstraction",
            worldAgeHours = getGameTime and getGameTime()
                and getGameTime().getWorldAgeHours
                and getGameTime():getWorldAgeHours() or 0,
            actorKey = PNC.EntityRef
                and PNC.EntityRef.ForNPC(record.id) or nil,
            sourceFactionID = PNC.Factions
                and PNC.Factions.GetOrganizationalFactionID
                and PNC.Factions.GetOrganizationalFactionID(record)
                or nil,
            result = "accepted",
            reason = reason or "abstract",
        })
    end
    if PNC.SocialEncounterTracker
        and PNC.SocialEncounterTracker.OnParticipantLeft
        and PNC.SocialEventHooks
    then
        PNC.SocialEncounterTracker.OnParticipantLeft(
            PNC.EntityRef.ForNPC(record.id),
            PNC.SocialEventHooks.WorldAgeHours(),
            reason or "abstract"
        )
    end

    record.runtime.target = nil
    record.runtime.lastPathX = nil
    record.runtime.lastPathY = nil
    record.runtime.roaming = nil
    record.runtime.roamGoalX = nil
    record.runtime.roamGoalY = nil
    record.runtime.roamGoalZ = nil

    if zombie then
        if PNC.Travel and PNC.Travel.Service then
            PNC.Travel.Service.OnAbstracted(record, zombie)
        end
        record.x = zombie:getX()
        record.y = zombie:getY()
        record.z = zombie:getZ()
        PathService.Reset(zombie, record)
        if ZombieAggro and ZombieAggro.ClearForNPCBody then
            ZombieAggro.ClearForNPCBody(zombie)
        end
        PNC.BodyLifecycle.RemoveLiveBody(record, zombie, reason or "abstract")
    else
        if PNC.Travel and PNC.Travel.Service then
            PNC.Travel.Service.OnAbstracted(record, nil)
        end
        PNC.BodyLifecycle.RemoveLiveBody(record, nil, reason or "abstract_missing")
    end

    record.presenceState = Const.PRESENCE_ABSTRACT
    if net and net.BroadcastRemoval then
        net.BroadcastRemoval(record.id, reason or "abstract")
    end
    return true
end

function Presence.Reconcile(record)
    local nearest
    if record.alive == false then
        return
    end
    nearest = findNearestPlayer(record)
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

function Presence.RefreshMaterializationCandidates(now, force)
    local seen = {}
    local ordered = {}
    local candidates
    local i
    local record
    local distSq
    local count = 0
    local entry
    local slotMs
    local radius = tonumber(Const.MATERIALIZE_DISTANCE) or 28
    now = tonumber(now) or Core.Now()
    if force ~= true and now - lastInterestRefreshAt
        < (tonumber(Const.PRESENCE_INTEREST_REFRESH_MS) or 250)
    then
        return 0
    end
    lastInterestRefreshAt = now
    if not Spatial or not Spatial.QueryNPCs then return 0 end
    Core.ForEachPlayer(function(player)
        candidates = Spatial.QueryNPCs(player:getX(), player:getY(), radius)
        for i = 1, #candidates do
            record = candidates[i]
            if record and record.id and record.alive ~= false
                and record.presenceState == Const.PRESENCE_ABSTRACT
            then
                distSq = Core.DistanceSq(
                    record.x,
                    record.y,
                    player:getX(),
                    player:getY()
                )
                if distSq <= radius * radius then
                    entry = seen[record.id]
                    if not entry then
                        entry = {
                            record = record,
                            distSq = distSq,
                        }
                        seen[record.id] = entry
                        ordered[#ordered + 1] = entry
                    elseif distSq < entry.distSq then
                        entry.distSq = distSq
                    end
                end
            end
        end
    end)
    table.sort(ordered, function(left, right)
        if left.distSq == right.distSq then
            return tostring(left.record.id) < tostring(right.record.id)
        end
        return left.distSq < right.distSq
    end)
    slotMs = tonumber(PNC.Scheduler and PNC.Scheduler.SLOT_MS) or 50
    for i = 1, #ordered do
        entry = ordered[i]
        record = entry.record
        count = count + 1
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
    if count > 0 and Spatial.Rebuild then
        -- One fresh census/index for the whole entering batch keeps
        -- pre-materialization shell cleanup and first-frame perception safe
        -- without returning to one global scan per NPC.
        Spatial.Rebuild(now, true)
    end
    return count
end
