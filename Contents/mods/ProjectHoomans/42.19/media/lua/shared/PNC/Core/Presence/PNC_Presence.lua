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
local ZombieAggro = PNC.ZombieAggro
local Network = nil

local function resolveNetwork()
    if not Network then
        Network = PNC.Network
    end
    return Network
end

local function findMaterializeSquare(record)
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
    query = PNC.TraversalQuery
    if query and query.FindNearestOccupable then
        safeX, safeY, safeZ, recoveryReason = query.FindNearestOccupable(
            record.x,
            record.y,
            record.z,
            4,
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

function Presence.ShouldMaterialize(record)
    local nearest = Core.GetNearestPlayerPosition(record.x, record.y)
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

function Presence.ShouldAbstract(record)
    local nearest = Core.GetNearestPlayerPosition(record.x, record.y)
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

function Presence.Materialize(record, reason)
    local zombieList
    local zombie
    local spawnX
    local spawnY
    local spawnZ
    local recoveryReason
    local originalX
    local originalY
    local originalZ
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

    if PNC.BodyLifecycle and PNC.BodyLifecycle.CleanupRecordShells
        and PNC.BodyLifecycle.CleanupRecordShells(record, Core.Now()) > 0
    then
        return nil
    end

    record.runtime = record.runtime or {}
    record.runtime.bodyLease = nil
    record.runtime.lifecycle = record.runtime.lifecycle or {}
    record.runtime.lifecycle.phase = "materializing"
    record.runtime.lifecycle.lastReason = reason or "materialize"
    record.runtime.lifecycle.lastTransitionAt = Core.Now()
    if PNC.Inventory and PNC.Inventory.EnsureRecordInventory then
        PNC.Inventory.EnsureRecordInventory(record)
    end
    originalX = record.x
    originalY = record.y
    originalZ = record.z
    spawnX, spawnY, spawnZ, recoveryReason = findMaterializeSquare(record)
    if spawnX == nil or spawnY == nil or spawnZ == nil then
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
    if zombie.setUseless then
        zombie:setUseless(true)
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

    record.runtime.target = nil
    record.runtime.lastPathX = nil
    record.runtime.lastPathY = nil
    record.runtime.roaming = nil
    record.runtime.roamGoalX = nil
    record.runtime.roamGoalY = nil
    record.runtime.roamGoalZ = nil

    if zombie then
        record.x = zombie:getX()
        record.y = zombie:getY()
        record.z = zombie:getZ()
        PathService.Reset(zombie, record)
        if ZombieAggro and ZombieAggro.ClearForNPCBody then
            ZombieAggro.ClearForNPCBody(zombie)
        end
        PNC.BodyLifecycle.RemoveLiveBody(record, zombie, reason or "abstract")
    else
        PNC.BodyLifecycle.RemoveLiveBody(record, nil, reason or "abstract_missing")
    end

    record.presenceState = Const.PRESENCE_ABSTRACT
    if net and net.BroadcastRemoval then
        net.BroadcastRemoval(record.id, reason or "abstract")
    end
    return true
end

function Presence.Reconcile(record)
    if record.alive == false then
        return
    end
    if Presence.ShouldMaterialize(record) then
        Presence.Materialize(record, "range_enter")
    elseif Presence.ShouldAbstract(record) then
        Presence.Abstract(record, "range_exit")
    end
end
