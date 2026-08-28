if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ColonyManagement = PNC.ColonyManagement or {}
PNC.ColonyManagement.Internal = PNC.ColonyManagement.Internal or {}

local Management = PNC.ColonyManagement
local Internal = Management.Internal
local Definitions = PNC.NeedsDefinitions
local canUseDebug = Internal.canUseDebug
local owned = Internal.owned

local function stopActivity(record, reason)
    local lease = PNC.TaskLeaseService and PNC.TaskLeaseService.ForNPC
        and PNC.TaskLeaseService.ForNPC(record.id) or nil
    if lease and PNC.Tasking and PNC.Tasking.Commands
        and PNC.Tasking.Commands.CancelLease
    then
        local stopped = PNC.Tasking.Commands.CancelLease(
            lease.leaseId, reason or "debug_stop")
        if stopped == true or not record.runtime.facilityActivity then
            return stopped == true
        end
    end
    return PNC.FacilityJobs and PNC.FacilityJobs.Stop
        and PNC.FacilityJobs.Stop(record, reason or "debug_stop") == true
        or false
end

local function debugFacilityWorkAction(player, args)
    if not canUseDebug(player) then return false, "not_authorized" end
    local record = PNC.Registry and PNC.Registry.Get(args.npcID) or nil
    if not record or record.alive == false or not owned(record, player) then
        return false, "npc_not_owned"
    end
    record.runtime = record.runtime or {}
    if tostring(args.operation or "start") == "stop" then
        local stopped = stopActivity(record, "debug_stop")
        return stopped, stopped and "facility_activity_stopped"
            or "facility_activity_not_active", { npcID = record.id }
    end
    local facility = PNC.SettlementRepository.GetFacility(args.facilityId)
    local base = facility and PNC.BaseService.Get(facility.baseId) or nil
    if not base then return false, "FACILITY_NOT_FOUND" end
    if not PNC.BaseValidationService.CanUse(player, base) then
        return false, "NO_PERMISSION"
    end
    local componentId = tostring(args.componentId or "")
    if componentId == "" and PNC.FacilityService.ResolveWorkTarget then
        local target = PNC.FacilityService.ResolveWorkTarget(facility)
        componentId = tostring(target and target.componentId or "")
    end
    local getComponent = PNC.SettlementRepository.GetComponent
    local component = componentId ~= "" and getComponent
        and getComponent(componentId) or nil
    if getComponent and componentId ~= "" and (not component
        or component.facilityId ~= facility.id)
    then return false, "FACILITY_COMPONENT_NOT_FOUND" end
    local capability = component
        and PNC.FacilityService.GetActivityCapability
        and PNC.FacilityService.GetActivityCapability(facility, component.id)
        or nil
    if component and not capability then
        return false, "FACILITY_COMPONENT_NOT_TESTABLE"
    end
    return PNC.FacilityJobs.StartForFacility(record, facility.id, {
        debugHold = true,
        componentId = componentId ~= "" and componentId or nil,
        capability = capability,
    })
end


Internal.debugFacilityWorkAction = debugFacilityWorkAction

return Management
