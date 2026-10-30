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
local Diagnostics = PNC.PerformanceScalingDiagnostics
local PresenceDiagnostics = Internal.PresenceDiagnostics
local ActorOwnership = PNC.Compatibility
    and PNC.Compatibility.ActorOwnership or nil

local function isFollower(record)
    return record
        and record.orderSpec
        and tostring(record.orderSpec.kind or "") == tostring(
            Const.ORDER_FOLLOW or "follow"
        )
end

local function prepareMaterializedFollower(record)
    local companion = PNC.BehaviorCompanion
    local internal = companion and companion.Internal or nil
    record.runtime = record.runtime or {}
    record.runtime.followReconcilePending = true
    -- A bodyless follower cannot complete a native attack action. Drop any
    -- stale action lease before the recreated body reaches live behavior.
    record.runtime.attackAction = nil
    record.runtime.inCombatUntil = 0
    if internal and internal.ResetFollowMoveIssue then
        -- Abstraction clears the native path state, while the follow issue
        -- cache survives. Reset it so the first live tick always republishes
        -- a movement target after the body is recreated.
        internal.ResetFollowMoveIssue(record)
    end
end

local function logFollowerTransition(record, fromState, toState, reason, zombie)
    local orderKind
    if not Diagnostics
        or not Diagnostics.IsFollowerPresenceAuditEnabled
        or Diagnostics.IsFollowerPresenceAuditEnabled() ~= true
        or not Diagnostics.LogFollowerPresence
    then
        return
    end
    orderKind = record.orderSpec and record.orderSpec.kind or nil
    if tostring(orderKind or "") ~= tostring(Const.ORDER_FOLLOW or "follow") then
        return
    end
    Diagnostics.LogFollowerPresence("presence_transition", {
        "npc=" .. tostring(record.id),
        "name=" .. tostring(record.name or "nil"),
        "authority=server",
        "from=" .. tostring(fromState),
        "to=" .. tostring(toState),
        "reason=" .. tostring(reason or "unknown"),
        "order=" .. tostring(orderKind),
        "owner=" .. tostring(record.ownerUsername or "nil"),
        "ownerOnlineID=" .. tostring(record.ownerOnlineID or "nil"),
        "position=" .. tostring(record.x) .. "," .. tostring(record.y)
            .. "," .. tostring(record.z),
        "nearestDistSq=" .. tostring(record.runtime
            and record.runtime.nearestPlayerDistSq or "nil"),
        "bodyPresent=" .. tostring(zombie ~= nil),
        "bodyLease=" .. tostring(record.runtime
            and record.runtime.bodyLease or "nil"),
        "presenceRevision=" .. tostring(record.presenceRevision or "nil"),
    })
end

local function startupReady()
    return not PNC.BodyLifecycle
        or not PNC.BodyLifecycle.IsStartupBodyCleanupComplete
        or PNC.BodyLifecycle.IsStartupBodyCleanupComplete()
end

local function markLifecycleFailure(record, reason, detail)
    record.runtime.lifecycle = record.runtime.lifecycle or {}
    record.runtime.lifecycle.phase = Const.PRESENCE_ABSTRACT
    record.runtime.lifecycle.bodyState = "missing"
    record.runtime.lifecycle.lastReason = reason
    record.runtime.lifecycle.lastError = detail
    record.runtime.lifecycle.lastTransitionAt = Core.Now()
end

local function scheduleMaterializationRetry(record, dueAt)
    if not record then return end
    record.runtime = record.runtime or {}
    record.runtime.materializeRetryAt = tonumber(dueAt) or Core.Now()
    record.runtime.forcePresenceCheck = true
    if PNC.SimulationClock and PNC.SimulationClock.Wake then
        PNC.SimulationClock.Wake(
            record,
            "presence",
            record.runtime.materializeRetryAt
        )
    end
    if PNC.Scheduler and PNC.Scheduler.Schedule then
        PNC.Scheduler.Schedule(record, record.runtime.materializeRetryAt)
    end
end

local function allowStartupMaterialization(record, now)
    local lifecycle = PNC.BodyLifecycle
    local state = lifecycle and lifecycle.StartupCleanup or nil
    local nextAt
    local burstUntil
    if not state or state.complete ~= true then
        return true
    end
    burstUntil = (tonumber(state.completedAt) or 0)
        + (tonumber(Const.BODY_SHELL_STARTUP_BURST_MS) or 5000)
    if (tonumber(now) or 0) > burstUntil then
        return true
    end
    nextAt = tonumber(state.nextMaterializeAt) or 0
    if nextAt > (tonumber(now) or 0) then
        record.runtime = record.runtime or {}
        scheduleMaterializationRetry(record, nextAt)
        markLifecycleFailure(record, "materialize_deferred",
            "startup_population_settle")
        return false
    end
    state.nextMaterializeAt = (tonumber(now) or 0)
        + (tonumber(Const.BODY_SHELL_STARTUP_MATERIALIZE_SPACING_MS) or 250)
    return true
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
        if Internal.LogTraversal then
            Internal.LogTraversal(record, "materialize_deferred", nil, {
                "reason=" .. tostring(deferredReason),
                "chunkReady=false",
            })
        end
        if MaterializationSafety and MaterializationSafety.Defer then
            MaterializationSafety.Defer(record, deferredReason, now)
        else
            scheduleMaterializationRetry(
                record,
                now + (tonumber(Const.MATERIALIZE_CHUNK_RETRY_MS) or 250)
            )
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
        scheduleMaterializationRetry(record, Core.Now() + 5000)
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
    if Presence.ClearTraversalHandoff then
        Presence.ClearTraversalHandoff(record, "materialize_begin")
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
end

local function spawnBody(record, position, reason)
    local lifecycle = PNC.BodyLifecycle
    local zombie
    local factoryReason
    if lifecycle and lifecycle.SpawnLiveBody then
        zombie, factoryReason = lifecycle.SpawnLiveBody(
            record, position, reason)
        if zombie then
            return zombie
        end
        markLifecycleFailure(
            record,
            "materialize_failed",
            tostring(factoryReason or "spawn_returned_no_body")
        )
        Core.LogWarn(
            "Failed to materialize NPC " .. tostring(record.id)
                .. " reason=" .. tostring(reason)
                .. " factory=" .. tostring(factoryReason or "unknown")
        )
        return nil
    end
    -- Load-order fallback: BodyLifecycle is composed before Presence, so this
    -- lane is only reachable if that ordering is ever broken.
    local zombieList = addZombiesInOutfit(
        position.x, position.y, position.z, 1,
        Const.BODY_SHELL_OUTFIT or "PNCShellCarrier",
        record.isFemale and 100 or 0,
        false, false, false, false, false, false, 1
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
    zombie = zombieList:get(0)
    -- Claim the IsoZombie before visual/equipment setup and before the next
    -- engine/mod update can observe a partially configured body.
    if ActorOwnership and ActorOwnership.MarkHoomansOwned then
        ActorOwnership.MarkHoomansOwned(zombie)
    end
    return zombie
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
    if PNC.BodyLifecycle
        and PNC.BodyLifecycle.EnsureLiveShellIdentityToken
    then
        local _, _, tokenReason =
            PNC.BodyLifecycle.EnsureLiveShellIdentityToken(record, zombie)
        if tokenReason ~= "created" and tokenReason ~= "existing"
            and Core and Core.LogWarn
        then
            Core.LogWarn("PNC live shell token unavailable npc="
                .. tostring(record.id)
                .. " reason=" .. tostring(tokenReason))
        end
    end
    if LiveBodyControl and LiveBodyControl.SetManagedBodyUseless then
        LiveBodyControl.SetManagedBodyUseless(zombie, true)
    end
end

local function abortMaterialization(record, zombie, reason)
    local lifecycle = PNC.BodyLifecycle
    local removed = false
    if lifecycle and lifecycle.AbortSpawnedBody then
        removed = lifecycle.AbortSpawnedBody(zombie) == true
    elseif lifecycle and lifecycle.Internal
        and lifecycle.Internal.removeZombie
    then
        removed = lifecycle.Internal.removeZombie(zombie) == true
    elseif zombie then
        if zombie.removeFromWorld then zombie:removeFromWorld() end
        if zombie.removeFromSquare then zombie:removeFromSquare() end
        removed = not zombie.getCurrentSquare
            or zombie:getCurrentSquare() == nil
    end
    markLifecycleFailure(record, "materialize_failed", reason)
    scheduleMaterializationRetry(
        record,
        Core.Now() + (tonumber(Const.MATERIALIZE_CHUNK_RETRY_MS) or 250)
    )
    if not removed then
        Core.LogWarn("PNC materialization rollback unverified npc="
            .. tostring(record and record.id or "unknown")
            .. " reason=" .. tostring(reason or "unknown"))
    end
    return nil
end

local function finishMaterialization(
    record, zombie, position, original, net, reason
)
    local fromState = record.presenceState
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
        local applied = false
        if position.activityTarget.campResource
            and PNC.CampResourceService
            and PNC.CampResourceService.ApplyMaterializationTarget
        then
            applied = PNC.CampResourceService.ApplyMaterializationTarget(
                record, zombie, position.activityTarget)
        end
        if not applied then
            PNC.FacilityResources.ApplyMaterializationTarget(
                record, zombie, position.activityTarget)
        end
    end
    record.presenceState = Const.PRESENCE_LIVE
    record.runtime = record.runtime or {}
    record.runtime.lifecycle = record.runtime.lifecycle or {}
    record.runtime.lifecycle.phase = "live"
    record.runtime.lifecycle.bodyState = "present"
    record.runtime.lifecycle.lastReason = reason or "materialize"
    record.runtime.lifecycle.lastError = nil
    record.runtime.lifecycle.lastTransitionAt = Core.Now()
    if record.runtime
        and record.runtime.abstractFollowMaterializeRequested == true
    then
        -- This force-live flag is a one-shot wake from the abstract follow
        -- lane. Do not leave it attached to the live record or it will defeat
        -- the normal live-to-abstract distance policy on the next pass.
        if record.runtime.abstractFollowOwnsForceLive == true then
            record.runtime.forceLive = nil
        end
        record.runtime.abstractFollowOwnsForceLive = nil
        record.runtime.abstractFollowMaterializeRequested = nil
    end
    Registry.RegisterLiveZombie(record, zombie)
    if Internal.LogTraversal then
        Internal.LogTraversal(record, "presence_transition", zombie, {
            "from=" .. tostring(fromState or Const.PRESENCE_ABSTRACT),
            "to=live",
            "reason=" .. tostring(reason or "materialize"),
        })
    end
    if PNC.Travel and PNC.Travel.Service then
        PNC.Travel.Service.OnMaterialized(record)
    end
    Health.Update(record, zombie, Core.Now())
    if record.alive == false then return nil end
    if isFollower(record) then
        prepareMaterializedFollower(record)
        logFollowerTransition(
            record,
            fromState or Const.PRESENCE_ABSTRACT,
            Const.PRESENCE_LIVE,
            reason or "materialize",
            zombie
        )
    end
    Animation.Apply(zombie, record, "Idle")
    if net and net.BroadcastRecord then
        net.BroadcastRecord(record, "materialize")
    end
    return zombie
end

function Presence.RebindRestoredBody(record, zombie, reason)
    local position
    local configured
    local configureError
    local result
    if not Core.IsAuthority() or not record or not zombie then
        return false
    end
    record.runtime = record.runtime or {}
    if record.runtime.vehiclePassenger
        and record.runtime.vehiclePassenger.active == true
    then
        -- A persisted vehicle passenger is intentionally bodyless. Startup
        -- sweep owns the identity-safe removal of the restored shell.
        return false
    end
    if record.runtime.bodyLease == nil
        and record.runtime.startupBodyHint
        and record.runtime.startupBodyHint.lease ~= nil
    then
        record.runtime.bodyLease = record.runtime.startupBodyHint.lease
    end
    position = {
        x = tonumber(zombie:getX()) or tonumber(record.x) or 0,
        y = tonumber(zombie:getY()) or tonumber(record.y) or 0,
        z = tonumber(zombie:getZ()) or tonumber(record.z) or 0,
    }
    configured, configureError = pcall(configureBody, record, zombie)
    if not configured then
        Core.LogWarn("PNC restored body configure failed npc="
            .. tostring(record.id) .. " reason=" .. tostring(configureError))
        return false
    end
    if PNC.BodyLifecycle
        and PNC.BodyLifecycle.ClearEngineInvulnerability
        and not PNC.BodyLifecycle.ClearEngineInvulnerability(zombie)
    then
        Core.LogWarn("PNC restored body rejected as invulnerable npc="
            .. tostring(record.id))
        return false
    end
    record.runtime.restoredBodyRebindPending = true
    result = finishMaterialization(
        record,
        zombie,
        position,
        position,
        Internal.ResolveNetwork(),
        reason or "startup_population_rebind"
    )
    record.runtime.restoredBodyRebindPending = nil
    if Core.LogInfo then
        Core.LogInfo("PNC restored body rebound npc=" .. tostring(record.id)
            .. " populationId="
            .. tostring(PNC.BodyLifecycle.GetBodyPopulationID
                and PNC.BodyLifecycle.GetBodyPopulationID(zombie) or "nil"))
    end
    return result ~= nil
end

function Presence.Materialize(record, reason, nearest)
    local now
    local position
    local zombie
    local original
    local pendingHusk
    local pendingHuskReason
    local cleanedShells
    local shellCleanupBlocked
    local shellCleanupReason
    local startupBodyBlocked
    local startupBodyBlockReason
    local lateStreamStatus
    local lateStreamBody
    local net = Internal.ResolveNetwork()
    if not Core.IsAuthority() or record.alive == false
        or record.presenceState == Const.PRESENCE_LIVE
    then
        if PresenceDiagnostics and PresenceDiagnostics.LogMaterializeGate then
            PresenceDiagnostics.LogMaterializeGate(record, "precondition",
                "authority_or_dead_or_already_live")
        end
        return Registry.GetLiveZombie(record.id)
    end
    if record.runtime and record.runtime.lifecycle
        and record.runtime.lifecycle.phase == "materializing"
    then
        if PresenceDiagnostics and PresenceDiagnostics.LogMaterializeGate then
            PresenceDiagnostics.LogMaterializeGate(record, "lifecycle_phase",
                "already_materializing")
        end
        return nil
    end
    if not startupReady() then
        if PresenceDiagnostics and PresenceDiagnostics.LogMaterializeGate then
            PresenceDiagnostics.LogMaterializeGate(record, "startup_cleanup",
                "startup_not_ready")
        end
        return nil, "startup_not_ready"
    end

    now = Core.Now()
    if PNC.BodyLifecycle
        and PNC.BodyLifecycle.ReconcileLateStreamRehydrate
    then
        lateStreamStatus, lateStreamBody =
            PNC.BodyLifecycle.ReconcileLateStreamRehydrate(
                record,
                now
            )
        if lateStreamStatus == "rebound" then
            return Registry.GetLiveZombie(record.id)
                or lateStreamBody
        elseif lateStreamStatus == "pending"
            or lateStreamStatus == "ambiguous"
        then
            scheduleMaterializationRetry(
                record,
                now + (
                    lateStreamStatus == "ambiguous"
                        and (tonumber(Const.BODY_SHELL_MAINTENANCE_MS)
                            or 1000)
                        or (tonumber(Const.MATERIALIZE_CHUNK_RETRY_MS)
                            or 250)
                )
            )
            markLifecycleFailure(
                record,
                "materialize_deferred",
                "late_stream_rehydration_" .. lateStreamStatus
            )
            if PresenceDiagnostics
                and PresenceDiagnostics.LogMaterializeGate
            then
                PresenceDiagnostics.LogMaterializeGate(
                    record,
                    "late_stream_rehydration",
                    lateStreamStatus
                )
            end
            return nil, "late_stream_rehydration_" .. lateStreamStatus
        end
    end

    if record.runtime
        and record.runtime.startupRehydrateExpected == true
    then
        if PresenceDiagnostics and PresenceDiagnostics.LogMaterializeGate then
            PresenceDiagnostics.LogMaterializeGate(
                record,
                "startup_rehydration",
                "startup_rehydration_pending"
            )
        end
        return nil, "startup_rehydration_pending"
    end
    prepareRecord(record)
    if not allowStartupMaterialization(record, now) then
        if PresenceDiagnostics and PresenceDiagnostics.LogMaterializeGate then
            PresenceDiagnostics.LogMaterializeGate(record, "startup_spacing",
                record.runtime.lifecycle.lastError or "deferred")
        end
        return nil
    end
    if PNC.BodyLifecycle and PNC.BodyLifecycle.IsStartupRecordBlocked then
        startupBodyBlocked, startupBodyBlockReason =
            PNC.BodyLifecycle.IsStartupRecordBlocked(record, now)
        if startupBodyBlocked then
            scheduleMaterializationRetry(
                record,
                now + (tonumber(Const.BODY_SHELL_MAINTENANCE_MS) or 1000)
            )
            markLifecycleFailure(record, "materialize_deferred",
                startupBodyBlockReason or "startup_body_reconciliation")
            if PresenceDiagnostics
                and PresenceDiagnostics.LogMaterializeGate
            then
                PresenceDiagnostics.LogMaterializeGate(
                    record,
                    "startup_body_reconciliation",
                    startupBodyBlockReason or "ambiguous_or_unmarked_body"
                )
            end
            return nil
        end
    end
    if PNC.BodyLifecycle and PNC.BodyLifecycle.HasPendingHuskForRecord then
        pendingHusk, pendingHuskReason =
            PNC.BodyLifecycle.HasPendingHuskForRecord(record.id)
    end
    if pendingHusk
    then
        scheduleMaterializationRetry(
            record,
            Core.Now() + (tonumber(Const.BODY_SHELL_MAINTENANCE_MS) or 1000)
        )
        markLifecycleFailure(record, "materialize_deferred",
            "husk_reclamation_pending")
        if PresenceDiagnostics and PresenceDiagnostics.LogMaterializeGate then
            PresenceDiagnostics.LogMaterializeGate(record, "husk_reclamation",
                pendingHuskReason or "pending_husk")
        end
        return nil
    end
    original = { x = record.x, y = record.y, z = record.z }
    position = resolveSpawnPosition(record, reason, now)
    if not position then
        if PresenceDiagnostics and PresenceDiagnostics.LogMaterializeGate then
            PresenceDiagnostics.LogMaterializeGate(record, "spawn_position",
                record.runtime.lifecycle.lastError or "position_unavailable")
        end
        return nil
    end
    if not Internal.ConsumeMaterializationBudget(record, reason, nearest) then
        if PresenceDiagnostics and PresenceDiagnostics.LogMaterializeGate then
            PresenceDiagnostics.LogMaterializeGate(record, "admission_budget",
                record.runtime.materializeAdmissionReason
                    or "tick_budget")
        end
        return nil
    end
    if PNC.BodyLifecycle and PNC.BodyLifecycle.CleanupRecordShells then
        cleanedShells, shellCleanupBlocked, shellCleanupReason =
            PNC.BodyLifecycle.CleanupRecordShells(record, now)
        if shellCleanupBlocked then
            markLifecycleFailure(record, "materialize_deferred",
                shellCleanupReason or "recognized_shell_removal_failed")
            scheduleMaterializationRetry(
                record,
                now + (tonumber(Const.BODY_SHELL_MAINTENANCE_MS) or 1000)
            )
            if PresenceDiagnostics and PresenceDiagnostics.LogMaterializeGate then
                PresenceDiagnostics.LogMaterializeGate(record,
                    "record_shell_cleanup",
                    shellCleanupReason or "recognized_shell_removal_failed")
            end
            return nil
        end
        if (tonumber(cleanedShells) or 0) > 0 then
            if PresenceDiagnostics and PresenceDiagnostics.LogMaterializeGate then
                PresenceDiagnostics.LogMaterializeGate(record,
                    "record_shell_cleanup", "shell_removed_before_spawn")
            end
            return nil
        end
    end
    beginMaterialization(record, reason, now)
    local spawnOk, spawnResult = pcall(spawnBody, record, position, reason)
    if not spawnOk then
        markLifecycleFailure(
            record,
            "materialize_failed",
            "spawn_exception:" .. tostring(spawnResult)
        )
        scheduleMaterializationRetry(
            record,
            now + (tonumber(Const.MATERIALIZE_CHUNK_RETRY_MS) or 250)
        )
        Core.LogWarn("PNC materialization spawn exception npc="
            .. tostring(record.id) .. " reason=" .. tostring(spawnResult))
        if PresenceDiagnostics and PresenceDiagnostics.LogMaterializeGate then
            PresenceDiagnostics.LogMaterializeGate(record, "spawn_exception",
                tostring(spawnResult))
        end
        return nil
    end
    zombie = spawnResult
    if not zombie then
        scheduleMaterializationRetry(
            record,
            now + (tonumber(Const.MATERIALIZE_CHUNK_RETRY_MS) or 250)
        )
        if PresenceDiagnostics and PresenceDiagnostics.LogMaterializeGate then
            PresenceDiagnostics.LogMaterializeGate(record, "spawn_body",
                "spawn_returned_no_body")
        end
        return nil
    end
    local configured, configureError = pcall(configureBody, record, zombie)
    if not configured then
        if PresenceDiagnostics and PresenceDiagnostics.LogMaterializeGate then
            PresenceDiagnostics.LogMaterializeGate(record, "configure_body",
                "configure_failed:" .. tostring(configureError))
        end
        return abortMaterialization(record, zombie,
            "configure_failed:" .. tostring(configureError))
    end
    if PNC.BodyLifecycle
        and PNC.BodyLifecycle.ClearEngineInvulnerability
        and not PNC.BodyLifecycle.ClearEngineInvulnerability(zombie)
    then
        if PresenceDiagnostics and PresenceDiagnostics.LogMaterializeGate then
            PresenceDiagnostics.LogMaterializeGate(record, "body_safety",
                "invulnerable_body_rejected")
        end
        return abortMaterialization(record, zombie,
            "invulnerable_body_rejected")
    end
    return finishMaterialization(
        record,
        zombie,
        position,
        original,
        net,
        reason
    )
end
