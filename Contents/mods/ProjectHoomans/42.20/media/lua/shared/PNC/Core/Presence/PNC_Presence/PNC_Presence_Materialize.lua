local Presence = PNC.Presence
local Internal = Presence.Internal
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local Health = PNC.Health
local Animation = PNC.Animation
local Visuals = PNC.Visuals
local Equipment = PNC.Equipment
local LiveBodyControl = PNC.LiveBodyControl
local MaterializationSafety = PNC.MaterializationSafety

local function startupReady()
    return not PNC.BodyLifecycle
        or not PNC.BodyLifecycle.IsStartupBodyCleanupComplete
        or PNC.BodyLifecycle.IsStartupBodyCleanupComplete()
end

local function prepareRecord(record)
    record.runtime = record.runtime or {}
    if PNC.Inventory and PNC.Inventory.EnsureRecordInventory then
        PNC.Inventory.EnsureRecordInventory(record)
    end
    if PNC.Travel and PNC.Travel.Service
        and PNC.Travel.Service.Get(record)
    then
        PNC.Travel.Service.Advance(
            record,
            PNC.Travel.Service.WorldHour()
        )
    end
end

local function markLifecycleFailure(record, reason, detail)
    record.runtime.lifecycle = record.runtime.lifecycle or {}
    record.runtime.lifecycle.phase = Const.PRESENCE_ABSTRACT
    record.runtime.lifecycle.bodyState = "missing"
    record.runtime.lifecycle.lastReason = reason
    record.runtime.lifecycle.lastError = detail
end

local function resolveSpawnPosition(record, reason, now)
    local x
    local y
    local z
    local recoveryReason
    local deferredReason
    local resourceTarget
    x, y, z, recoveryReason, deferredReason, resourceTarget =
        Internal.FindMaterializeSquare(record, now, reason)
    if deferredReason and deferredReason ~= "no_safe_square" then
        if MaterializationSafety and MaterializationSafety.Defer then
            MaterializationSafety.Defer(record, deferredReason, now)
        else
            record.runtime.materializeRetryAt = now
                + (tonumber(Const.MATERIALIZE_CHUNK_RETRY_MS) or 250)
        end
        markLifecycleFailure(
            record,
            "materialize_deferred",
            tostring(deferredReason)
        )
        return nil
    end
    if x == nil or y == nil or z == nil then
        markLifecycleFailure(
            record,
            "materialize_position_blocked",
            "no_safe_square:" .. tostring(recoveryReason or "unknown")
        )
        record.runtime.materializeRetryAt = Core.Now() + 5000
        Core.LogWarn(
            "NPC position recovery deferred npc=" .. tostring(record.id)
                .. " name=" .. tostring(record.name or "Unknown NPC")
                .. " event=materialize_no_safe_square"
                .. " reason=" .. tostring(recoveryReason or "unknown")
                .. " at=" .. tostring(record.x) .. ","
                .. tostring(record.y) .. "," .. tostring(record.z)
        )
        return nil
    end
    return {
        x = x,
        y = y,
        z = z,
        recoveryReason = recoveryReason,
        activityTarget = resourceTarget,
    }
end

local function beginMaterialization(record, reason, now)
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
end

local function spawnBody(record, position, reason)
    local zombieList = addZombiesInOutfit(
        position.x, position.y, position.z, 1, "Naked",
        record.isFemale and 100 or 0,
        false, false, false, false, true, false, 1
    )
    if not zombieList or zombieList:size() <= 0 then
        markLifecycleFailure(
            record,
            "materialize_failed",
            "spawn_returned_no_body"
        )
        Core.LogWarn(
            "Failed to materialize NPC " .. tostring(record.id)
                .. " reason=" .. tostring(reason)
        )
        return nil
    end
    return zombieList:get(0)
end

local function configureBody(record, zombie)
    local inventoryOk
    local inventoryReason
    if zombie.DoZombieStats then zombie:DoZombieStats() end
    record.runtime.target = nil
    Animation.ApplyLiveSetup(zombie, record)
    Visuals.ApplyHumanVisuals(zombie, record)
    if PNC.Inventory and PNC.Inventory.MaterializeLooseInventory then
        inventoryOk, inventoryReason =
            PNC.Inventory.MaterializeLooseInventory(record, zombie)
        if not inventoryOk then
            Core.LogWarn(
                "PNC inventory materialization failed npc="
                    .. tostring(record.id)
                    .. " reason=" .. tostring(inventoryReason)
            )
        end
    end
    Equipment.Apply(zombie, record)
    if LiveBodyControl and LiveBodyControl.SetManagedBodyUseless then
        LiveBodyControl.SetManagedBodyUseless(zombie, true)
    end
end

local function finishMaterialization(
    record, zombie, position, original, net
)
    record.x = position.x
    record.y = position.y
    record.z = position.z
    if position.recoveryReason and Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "position_recovery")
    end
    if position.recoveryReason then
        Internal.LogPositionRecovery(
            record,
            "materialize_relocate",
            position.recoveryReason,
            original.x,
            original.y,
            original.z,
            position.x,
            position.y,
            position.z
        )
    end
    if position.activityTarget and PNC.FacilityResources
        and PNC.FacilityResources.ApplyMaterializationTarget
    then
        PNC.FacilityResources.ApplyMaterializationTarget(
            record, zombie, position.activityTarget)
    end
    record.presenceState = Const.PRESENCE_LIVE
    Registry.RegisterLiveZombie(record, zombie)
    if PNC.Travel and PNC.Travel.Service then
        PNC.Travel.Service.OnMaterialized(record)
    end
    Health.Update(record, zombie, Core.Now())
    if record.alive == false then return nil end
    Animation.Apply(zombie, record, "Idle")
    if net and net.BroadcastRecord then
        net.BroadcastRecord(record, "materialize")
    end
    return zombie
end

function Presence.Materialize(record, reason, nearest)
    local now
    local position
    local zombie
    local original
    local net = Internal.ResolveNetwork()
    if not Core.IsAuthority() or record.alive == false
        or record.presenceState == Const.PRESENCE_LIVE
    then
        return Registry.GetLiveZombie(record.id)
    end
    if not startupReady() then return nil end
    prepareRecord(record)
    original = { x = record.x, y = record.y, z = record.z }
    now = Core.Now()
    position = resolveSpawnPosition(record, reason, now)
    if not position then return nil end
    if not Internal.ConsumeMaterializationBudget(record, reason, nearest) then
        return nil
    end
    if PNC.BodyLifecycle and PNC.BodyLifecycle.CleanupRecordShells
        and PNC.BodyLifecycle.CleanupRecordShells(record, now) > 0
    then
        return nil
    end
    beginMaterialization(record, reason, now)
    zombie = spawnBody(record, position, reason)
    if not zombie then return nil end
    configureBody(record, zombie)
    return finishMaterialization(record, zombie, position, original, net)
end
