if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ColonyManagement = PNC.ColonyManagement or {}
PNC.ColonyManagement.Internal = PNC.ColonyManagement.Internal or {}

local Management = PNC.ColonyManagement
local Internal = Management.Internal
local Definitions = PNC.NeedsDefinitions
local owned = Internal.owned

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

return Management
