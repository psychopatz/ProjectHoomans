if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityJobs = PNC.FacilityJobs or {}
PNC.FacilityJobsServiceInternal = PNC.FacilityJobsServiceInternal or {}

local Jobs = PNC.FacilityJobs
local H = PNC.FacilityJobsServiceInternal
local Repository = PNC.SettlementRepository
local ActorControl = PNC.ActorControl
    or require "PNC/Core/ActorControl/PNC_ActorControl"

-- Durable progress baseline is installed by StartState with
-- lastProgressAt = activityStartedAt.

local function campPlacementLocked(record)
    local runtime = record and record.runtime or nil
    local placement = runtime and runtime.campPlacement or nil
    local order = record and record.orderSpec or nil
    local state = placement and placement.state
        or order and order.placementState or nil
    state = string.lower(tostring(state or ""))
    return state == "queued" or state == "moving" or state == "failed"
end

function Jobs.Start(record, facilityOrId, capability, options)
    options = type(options) == "table" and options or {}
    if ActorControl and ActorControl.CanWrite then
        local allowed, ownerReason = ActorControl.CanWrite(
            record,
            options.owner,
            "facility_start",
            { reason = options.reason or "facility_start" }
        )
        if allowed == false then
            return false, ownerReason or "puppet_opera_owned"
        end
    end
    if campPlacementLocked(record) then
        return false, "camp_placement_active"
    end
    local facility = type(facilityOrId) == "table" and facilityOrId
        or Repository.GetFacility(facilityOrId)
    local base = facility and PNC.BaseService.Get(facility.baseId) or nil
    capability = tostring(capability or H.DefinitionCapability(facility) or "")
    local definition = PNC.FacilityJobDefinitions.Get(capability)
    local activityItemFullType
    local activityConsumptionMode
    if not record or record.alive == false then return false, "NPC_UNAVAILABLE" end
    if not base and options.nearby == true then
        base = { id = tostring(facility.baseId or "nearby") }
    end
    if not base or not facility then return false, "FACILITY_NOT_FOUND" end
    if not definition then return false, "FACILITY_HAS_NO_ACTIVITY" end
    activityItemFullType = H.ResolveFoodItemFullType(
        record, capability, options)
    activityConsumptionMode = H.ResolveActivityConsumptionMode
        and H.ResolveActivityConsumptionMode(record, capability, options)
        or nil
    if record.runtime and record.runtime.facilityActivity then
        local stopped, stopReason = H.StopExistingActivity(
            record, "activity_replaced")
        if record.runtime.facilityActivity then
            return false, stopReason or "FACILITY_ACTIVITY_BUSY"
        end
    end
    local acquired = options.acquired or PNC.FacilityService.AcquireActivity(
        base.id, record.id, capability, { ttlMs = 30000,
            abstract = options.abstract == true,
            componentId = options.componentId })
    if not acquired.ok or not acquired.target then
        return false, acquired.reason or "FACILITY_HAS_NO_WORK_TARGET"
    end
    local startContext, startReason = H.PrepareStartContext({
        record = record,
        facility = facility,
        options = options,
        capability = capability,
        definition = definition,
        acquired = acquired,
        activityItemFullType = activityItemFullType,
        activityConsumptionMode = activityConsumptionMode,
    })
    if not startContext then return false, startReason end
    return H.InstallActivity(startContext)

end

function Jobs.StartForFacility(record, facilityId, options)
    options = type(options) == "table" and options or {}
    local facility = type(facilityId) == "table" and facilityId
        or Repository.GetFacility(facilityId)
    local capability = options.capability
        or options.componentId
            and PNC.FacilityService.GetActivityCapability
            and PNC.FacilityService.GetActivityCapability(
                facility, options.componentId)
        or H.DefinitionCapability(facility)
    return Jobs.Start(record, facility, capability, options)
end

return Jobs
