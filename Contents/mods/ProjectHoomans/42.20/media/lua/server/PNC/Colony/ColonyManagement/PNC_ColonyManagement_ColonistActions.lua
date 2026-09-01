if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ColonyManagement = PNC.ColonyManagement or {}
PNC.ColonyManagement.Internal = PNC.ColonyManagement.Internal or {}

local Management = PNC.ColonyManagement
local Internal = Management.Internal
local Definitions = PNC.NeedsDefinitions
local owned = Internal.owned

local function stopSpecialOrder(record, job, reason)
    local npcId = tostring(record and record.id or "")
    local lease = PNC.TaskLeaseService and PNC.TaskLeaseService.ForNPC
        and PNC.TaskLeaseService.ForNPC(npcId) or nil
    local tasking = PNC.Tasking and PNC.Tasking.Commands

    if job == "Fishing" then
        if lease and lease.sourceDomain == "fishing"
            and tasking and tasking.CancelForNPC
        then
            return tasking.CancelForNPC(npcId, reason or "order_cancelled")
        end
        return PNC.FishingService and PNC.FishingService.CancelJob
            and PNC.FishingService.CancelJob(npcId,
                reason or "order_cancelled") or true
    end
    if job == "Lumber" then
        if lease and lease.sourceDomain == "lumber"
            and tasking and tasking.CancelForNPC
        then
            local stopped, stopReason = tasking.CancelForNPC(npcId,
                reason or "order_cancelled")
            if stopped == false or stopReason == "CANCELLATION_DEFERRED" then
                return stopped, stopReason
            end
        end
        local lumber = PNC.LumberService
        local lumberJob = lumber and lumber.GetJob and lumber.GetJob(npcId)
        if lumber and lumber.UnassignWorker and lumberJob
            and lumberJob.zoneId
        then
            return lumber.UnassignWorker(lumberJob.zoneId, npcId,
                reason or "order_cancelled")
        end
        return lumber and lumber.CancelJob and lumber.CancelJob(npcId,
            reason or "order_cancelled") or true
    end
    if job == "CorpseHaul" then
        if lease and lease.sourceDomain == "corpse_haul"
            and tasking and tasking.CancelForNPC
        then
            return tasking.CancelForNPC(npcId, reason or "order_cancelled")
        end
        return true
    end
    return false, "UNKNOWN_ORDER"
end

local function cancelSpecialOrder(player, args)
    local record = PNC.Registry and PNC.Registry.Get(args.npcID) or nil
    local job = tostring(args.job or "")
    if not record or record.alive == false or not owned(record, player) then
        return false, "npc_not_owned"
    end
    if job ~= "Fishing" and job ~= "Lumber" and job ~= "CorpseHaul" then
        return false, "UNKNOWN_ORDER"
    end
    local ok, reason = stopSpecialOrder(record, job,
        "player_order_cancelled")
    return ok ~= false, reason or "ORDER_CANCELLED", {
        npcID = record.id, job = job,
    }
end

local function colonistHomeAction(player, args, recover)
    local record = PNC.Registry and PNC.Registry.Get(args.npcID) or nil
    if not record or record.alive == false or not owned(record, player) then
        return false, "npc_not_owned"
    end
    if not PNC.HomeDutyService then return false, "HOME_SERVICE_UNAVAILABLE" end
    if recover == true then
        return PNC.HomeDutyService.Recover(record, args.baseId)
    end
    if PNC.WorkService and PNC.WorkService.Commands
        and PNC.WorkService.Commands.ReleaseWorker
        and record.runtime and record.runtime.workOrderId
    then
        PNC.WorkService.Commands.ReleaseWorker(record.id, "return_home_requested")
    end
    return PNC.HomeDutyService.SendHome(
        record, args.baseId, "player_requested")
end

local function colonistFollowAction(player, args)
    local record = PNC.Registry and PNC.Registry.Get(args.npcID) or nil
    if not record or record.alive == false or not owned(record, player) then
        return false, "npc_not_owned"
    end
    if not PNC.HomeDutyService or not PNC.HomeDutyService.SendToPlayer then
        return false, "HOME_SERVICE_UNAVAILABLE"
    end
    return PNC.HomeDutyService.SendToPlayer(record, player,
        "player_requested")
end

local function setJobPermission(player, args)
    local record = PNC.Registry and PNC.Registry.Get(args.npcID) or nil
    if not record or record.alive == false or not owned(record, player) then
        return false, "npc_not_owned"
    end
    local job = tostring(args.job or "")
    local known = false
    for _, candidate in ipairs(PNC.WorkDefinitions.COLONY_JOBS or {}) do
        if candidate == job then known = true; break end
    end
    if not known then return false, "UNKNOWN_JOB" end
    record.allowedJobs = record.allowedJobs or {}
    record.allowedJobs[job] = args.enabled == true
    if args.enabled ~= true
        and (job == "Fishing" or job == "Lumber" or job == "CorpseHaul")
    then
        local stopped, stopReason = stopSpecialOrder(record, job,
            "job_permission_disabled")
        if stopped == false then return false, stopReason end
    end
    if args.enabled ~= true and record.runtime and record.runtime.workOrderId then
        local order = PNC.WorkRepository.Get(record.runtime.workOrderId)
        if order and PNC.WorkDefinitions.JOB_BY_OPERATION[order.operation] == job then
            PNC.WorkService.Commands.Cancel(order.id, "job_permission_disabled")
        end
    end
    if PNC.Registry.MarkDirty then PNC.Registry.MarkDirty(record, "allowed_jobs") end
    return true, args.enabled == true and "JOB_ENABLED" or "JOB_DISABLED", {
        npcID = record.id, job = job, enabled = args.enabled == true,
    }
end


Internal.colonistHomeAction = colonistHomeAction
Internal.colonistFollowAction = colonistFollowAction
Internal.setJobPermission = setJobPermission
Internal.cancelSpecialOrder = cancelSpecialOrder

return Management
