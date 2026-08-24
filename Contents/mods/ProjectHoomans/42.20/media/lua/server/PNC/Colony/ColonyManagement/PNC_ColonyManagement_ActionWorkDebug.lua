if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ColonyManagement = PNC.ColonyManagement or {}
PNC.ColonyManagement.Internal = PNC.ColonyManagement.Internal or {}

local Management = PNC.ColonyManagement
local Internal = Management.Internal
local Definitions = PNC.NeedsDefinitions


local startNearbyWaterAction = Internal.startNearbyWaterAction
local debugNeedAction = Internal.debugNeedAction
local debugFacilityWorkAction = Internal.debugFacilityWorkAction

function Internal.handleWorkDebugAction(player, args, action)
    local ok
    local reason
    local details
    if action == "work_cancel" then
        ok, details = PNC.TaskRequestService.Commands.CancelForPlayer(
            player, args.requestId or args.workOrderId, "player_cancelled")
        reason = ok and "CANCELLED" or details
    elseif action == "work_pause" then
        ok, details = PNC.TaskRequestService.Commands.PauseForPlayer(
            player, args.requestId or args.workOrderId, args.paused ~= false)
        reason = ok and "PAUSED" or details
    elseif action == "work_resume" then
        ok, details = PNC.TaskRequestService.Commands.ResumeForPlayer(
            player, args.requestId or args.workOrderId)
        reason = ok and "RESUMED" or details
    elseif action == "work_retry" then
        ok, details = PNC.TaskRequestService.Commands.RetryForPlayer(
            player, args.requestId or args.workOrderId)
        reason = ok and "RETRYING" or details
    elseif action == "work_priority" then
        ok, details = PNC.WorkService.Commands.SetPriorityForPlayer(
            player, args.workOrderId, args.priority)
        reason = ok and "PRIORITY_CHANGED" or details
    elseif action == "provision_set" then
        ok, reason, details = PNC.ProvisionPolicyService.Apply(
            player, args.submission)
    elseif action == "npc_drink_at_water" then
        ok, reason, details = startNearbyWaterAction(player, args, false)
    elseif action == "debug_need" then
        ok, reason, details = debugNeedAction(player, args)
    elseif action == "debug_facility_work" then
        ok, reason, details = debugFacilityWorkAction(player, args)
    else
        return nil
    end
    return { ok = ok, reason = reason, details = details }
end

return Management
