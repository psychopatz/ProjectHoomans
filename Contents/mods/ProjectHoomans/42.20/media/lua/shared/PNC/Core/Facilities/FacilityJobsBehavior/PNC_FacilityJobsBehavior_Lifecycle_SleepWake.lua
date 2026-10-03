local Jobs = PNC.FacilityJobs
local Internal = PNC.FacilityJobsBehaviorInternal
local SLEEP_WAKE_ANIMATION_TIMEOUT_MS = 2000

local function preserveCombatThreatForWake(record, runtime, reason, now)
    local ownerRuntime = record and record.runtime or nil
    local state
    local target
    local kind
    local id
    local expiresAt
    local existing
    if string.find(tostring(reason or ""), "combat", 1, true) == nil then
        return
    end
    state = ownerRuntime and ownerRuntime.threatGuard or nil
    target = state and state.target or ownerRuntime
        and ownerRuntime.target or runtime and runtime.target or nil
    if type(target) ~= "table" then return end
    kind = tostring(target.kind or "")
    if kind == "npc" then
        id = target.id
    elseif kind == "zombie" then
        id = target.zombieId
    elseif kind == "player" then
        id = target.onlineID or target.username
    end
    if id == nil or id == "" then return end
    expiresAt = now + (
        tonumber(PNC.Const and PNC.Const.TARGET_RECENT_ATTACKER_MS) or 5000
    )
    existing = ownerRuntime and ownerRuntime.recentThreat or nil
    if existing and (tonumber(existing.expiresAt) or 0) > expiresAt then
        return
    end
    if not ownerRuntime then return end
    ownerRuntime.recentThreat = {
        kind = kind,
        id = kind == "player" and nil or id,
        onlineID = kind == "player" and target.onlineID or nil,
        username = kind == "player" and target.username or nil,
        expiresAt = expiresAt,
    }
end

local function logSleepWake(eventName, record, zombie, runtime, reason)
    local modData
    if not PNC.Core or not PNC.Core.LogInfo then return end
    modData = zombie and zombie.getModData and zombie:getModData() or nil
    PNC.Core.LogInfo(
        "[PNC][ANIM] sleep_wake_" .. tostring(eventName)
            .. " npc=" .. tostring(record and record.id or "")
            .. " surface=" .. tostring(runtime and runtime.sleepSurface or "")
            .. " phase=" .. tostring(runtime and runtime.phase or "")
            .. " reason=" .. tostring(reason or "")
            .. " action=" .. tostring(zombie and zombie.getActionStateName
                and zombie:getActionStateName() or "")
            .. " bump=" .. tostring(modData
                and modData.PNC_BumpRequestedType or "")
            .. " releasePending=" .. tostring(modData
                and modData.PNC_BumpReleasePending == true or false))
end

function Internal.HasLiveTaskLease(leaseId)
    leaseId = tostring(leaseId or "")
    if leaseId == "" then return false end
    local leases = PNC.TaskLeaseService
    if not leases or type(leases.Get) ~= "function" then
        -- This module is shared. Clients do not own the server lease table,
        -- so an opaque client-side ID is not evidence of an orphan.
        return true
    end
    return leases.Get(leaseId) ~= nil
end

function Internal.RestorePosition(record, zombie, runtime)
    if not runtime or runtime.positioned ~= true then return end
    local position = runtime.approachPosition
    if zombie and position and PNC.LiveBodyControl
        and PNC.LiveBodyControl.SetAuthoritativePosition
    then
        PNC.LiveBodyControl.SetAuthoritativePosition(
            zombie, position.x, position.y, position.z)
        record.x, record.y, record.z = position.x, position.y, position.z
    end
    runtime.positioned = false
end

function Internal.BeginSleepWake(record, zombie, reason)
    local runtime = Internal.State(record)
    local now
    if not runtime then return false end
    now = PNC.Core and PNC.Core.Now and tonumber(PNC.Core.Now()) or 0
    preserveCombatThreatForWake(record, runtime, reason, now)
    if runtime.sleepWakePending == true then
        runtime.sleepWakeReason = tostring(
            reason or runtime.sleepWakeReason or "sleep_stopped")
        return true
    end
    runtime.sleepWakePending = true
    runtime.sleepWakeStartedAt = now
    runtime.sleepWakeDeadlineAt = now + 1000
    runtime.sleepWakeReason = tostring(reason or "sleep_stopped")
    runtime.sleepWakeFinish = true
    runtime.sleepWakeRestoreOrder = true
    runtime.sleepWakeAnimationStarted = false
    runtime.sleepWakeBodyPrepared = false
    runtime.sleepSceneActive = false
    runtime.phase = "WAKING"
    logSleepWake("begin", record, zombie, runtime, reason)
    return true
end

function Internal.TickSleepWake(record, zombie)
    local runtime = Internal.State(record)
    local now
    local releasePending
    local deadline
    local modData
    local finishAfterWake
    local restoreOrder
    local wakeTaskLeaseId
    local wakeReason
    local finished
    local surface
    local animationFinished
    local animationDeadline
    local releaseDeadline
    local played
    local wakeExit
    local wakeExitReason
    local wakeExitPlaced
    if not runtime or runtime.sleepWakePending ~= true then
        return false
    end
    if PNC.Core and PNC.Core.IsAuthority
        and PNC.Core.IsAuthority() == false
    then
        return true
    end
    now = PNC.Core and PNC.Core.Now and tonumber(PNC.Core.Now()) or 0
    if runtime.sleepWakeExitPending == true
        and now < (tonumber(runtime.sleepWakeExitRetryAt) or 0)
    then
        return true
    end
    deadline = tonumber(runtime.sleepWakeDeadlineAt) or (now + 1000)
    surface = tostring(runtime.sleepSurface or "")
    if runtime.sleepWakeAnimationStarted ~= true then
        if PNC.Animation and PNC.Animation.PumpBumpRelease then
            releasePending = PNC.Animation.PumpBumpRelease(zombie, now)
        end
        modData = zombie and zombie.getModData and zombie:getModData() or nil
        if releasePending == true and now < deadline
            or modData and modData.PNC_BumpReleasePending == true
                and now < deadline
        then
            return true
        end
        if zombie and not runtime.sleepWakeBodyPrepared
            and PNC.LiveBodyControl
        then
            if PNC.LiveBodyControl.Internal
                and PNC.LiveBodyControl.Internal.clearVanillaIntent
            then
                PNC.LiveBodyControl.Internal.clearVanillaIntent(zombie)
            end
            if PNC.LiveBodyControl.ResetPresentationNativeMovementState then
                PNC.LiveBodyControl.ResetPresentationNativeMovementState(zombie)
            end
            if PNC.LiveBodyControl.ApplyHumanizedBodyFlags then
                PNC.LiveBodyControl.ApplyHumanizedBodyFlags(zombie, false)
            end
            runtime.sleepWakeBodyPrepared = true
        end
        if (surface == "bed" or surface == "sofa")
            and PNC.Animation
            and PNC.Animation.PlayBump
        then
            played = PNC.Animation.PlayBump(
                zombie,
                record,
                "AwakeBed",
                {
                    sceneId = "facility.sleep.wake",
                    leaseUntil = now + SLEEP_WAKE_ANIMATION_TIMEOUT_MS,
                    keepManagedUseless = true,
                }
            )
            if played ~= false then
                runtime.sleepWakeAnimationStarted = true
                runtime.sleepWakeAnimationStartedAt = now
                runtime.sleepWakeAnimationDeadlineAt = now
                    + SLEEP_WAKE_ANIMATION_TIMEOUT_MS
                return true
            end
        end
    else
        animationDeadline = tonumber(
            runtime.sleepWakeAnimationDeadlineAt) or (now + 1000)
        animationFinished = zombie
            and zombie.getVariableBoolean
            and zombie:getVariableBoolean("BumpAnimFinished") == true
            or false
        if not animationFinished and now < animationDeadline then
            if PNC.Animation and PNC.Animation.MaintainBump then
                PNC.Animation.MaintainBump(
                    zombie,
                    record,
                    "AwakeBed",
                    animationDeadline,
                    {
                        sceneId = "facility.sleep.wake",
                        keepManagedUseless = true,
                    }
                )
            end
            return true
        end
        if PNC.Animation and PNC.Animation.FinishBump then
            PNC.Animation.FinishBump(zombie, true)
        end
        releaseDeadline = now + 1000
        runtime.sleepWakeReleaseDeadlineAt = releaseDeadline
        if PNC.Animation and PNC.Animation.PumpBumpRelease then
            releasePending = PNC.Animation.PumpBumpRelease(zombie, now)
        end
        modData = zombie and zombie.getModData and zombie:getModData() or nil
        if releasePending == true and now < releaseDeadline
            or modData and modData.PNC_BumpReleasePending == true
                and now < releaseDeadline
        then
            return true
        end
    end
    if zombie and PNC.LiveBodyControl then
        if PNC.LiveBodyControl.Internal
            and PNC.LiveBodyControl.Internal.clearVanillaIntent
        then
            PNC.LiveBodyControl.Internal.clearVanillaIntent(zombie)
        end
        if PNC.LiveBodyControl.ResetPresentationNativeMovementState then
            PNC.LiveBodyControl.ResetPresentationNativeMovementState(zombie)
        end
        if PNC.LiveBodyControl.ApplyHumanizedBodyFlags then
            PNC.LiveBodyControl.ApplyHumanizedBodyFlags(zombie, false)
        end
    end
    if tostring(runtime.capability or "") == "sleep"
        and Internal.FindSleepExit
    then
        wakeExit, wakeExitReason = Internal.FindSleepExit(
            record, zombie, runtime, record.orderSpec)
        if not wakeExit then
            runtime.sleepWakeExitPending = true
            runtime.sleepWakeExitRetryAt = now + 250
            runtime.phase = "WAKING_EXIT_WAIT"
            logSleepWake("exit_wait", record, zombie, runtime,
                wakeExitReason or "SLEEP_EXIT_UNAVAILABLE")
            return true
        end
    end
    Internal.ClearSleepSurface(record, zombie, runtime)
    if wakeExit and Internal.CommitSleepExit then
        wakeExitPlaced, wakeExitReason = Internal.CommitSleepExit(
            record, zombie, runtime, wakeExit)
        if not wakeExitPlaced then
            runtime.sleepWakeExitPending = true
            runtime.sleepWakeExitRetryAt = now + 250
            runtime.phase = "WAKING_EXIT_WAIT"
            logSleepWake("exit_wait", record, zombie, runtime,
                wakeExitReason or "SLEEP_EXIT_WRITE_FAILED")
            return true
        end
    else
        Internal.RestorePosition(record, zombie, runtime)
    end
    runtime.sleepWakeExitPending = nil
    runtime.sleepWakeExitRetryAt = nil
    runtime.arrivalSettled = false
    runtime.facingApplied = false
    runtime.sleepSurfaceEntered = false
    finishAfterWake = runtime.sleepWakeFinish == true
    restoreOrder = runtime.sleepWakeRestoreOrder ~= false
    wakeTaskLeaseId = tostring(runtime.sleepWakeTaskLeaseId or "")
    wakeReason = tostring(runtime.sleepWakeReason or "sleep_stopped")
    runtime.sleepWakePending = nil
    runtime.sleepWakeStartedAt = nil
    runtime.sleepWakeDeadlineAt = nil
    runtime.sleepWakeAnimationStarted = nil
    runtime.sleepWakeAnimationStartedAt = nil
    runtime.sleepWakeAnimationDeadlineAt = nil
    runtime.sleepWakeReleaseDeadlineAt = nil
    runtime.sleepWakeBodyPrepared = nil
    runtime.sleepWakeReason = nil
    runtime.sleepWakeFinish = nil
    runtime.sleepWakeRestoreOrder = nil
    runtime.sleepWakeTaskLeaseId = nil
    logSleepWake(
        "complete",
        record,
        zombie,
        runtime,
        wakeReason
    )
    if finishAfterWake then
        finished = Internal.Finish(
            record,
            zombie,
            runtime.completionRequested == true
                and "complete"
                or "sleep_stopped",
            restoreOrder
        ) == true
        if not restoreOrder and wakeTaskLeaseId ~= "" then
            Internal.ReleaseTaskLeaseAfterAbort(
                record,
                wakeTaskLeaseId,
                wakeReason
            )
        end
        return finished
    end
    runtime.phase = "INTERRUPTED"
    return true
end
