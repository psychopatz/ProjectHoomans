if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC.NeedFacilityHomeRoute = PNC.NeedFacilityHomeRoute or {}

local Home = PNC.NeedFacilityHomeRoute
local Definitions = PNC.NeedFacilityTriggerDefinitions

function Home.GetBase(record)
    return PNC.HomeDutyService and PNC.HomeDutyService.GetBase
        and PNC.HomeDutyService.GetBase(record) or nil
end

function Home.IsAtHome(record)
    local base = Home.GetBase(record)
    return base and PNC.HomeDutyService and PNC.HomeDutyService.IsAtHome
        and PNC.HomeDutyService.IsAtHome(record, base.id) == true or false
end

function Home.HasFacility(record, triggerId)
    local definition = Definitions.Get(triggerId)
    local base = record and Home.GetBase(record)
    if not definition or not base or not PNC.FacilityService
        or not PNC.FacilityService.ListByCapability
    then return false end
    local facilities = PNC.FacilityService.ListByCapability(
        base.id, definition.capability)
    for index = 1, #facilities do
        if not PNC.FacilityReservations
            or not PNC.FacilityReservations.HasCapacity
            or PNC.FacilityReservations.HasCapacity(
                facilities[index], definition.capability)
        then return true end
    end
    return false
end

local function hasRequiredPersonalSupply(record, definition)
    if definition and definition.needType == "hunger" then
        return PNC.NPCSupplyService
            and PNC.NPCSupplyService.HasPersonalSupply
            and PNC.NPCSupplyService.HasPersonalSupply(record, "FOOD", {
                hunger = math.max(0.001, tonumber(record and record.needs
                    and record.needs.hunger) or 0.001),
                thirst = 0,
            }) == true
    end
    return true
end

function Home.IsAvailable(record, definition)
    return Home.IsAtHome(record) and Home.HasFacility(record, definition.id)
        and hasRequiredPersonalSupply(record, definition)
end

function Home.Validate(record, definition)
    local base = Home.GetBase(record)
    if not base or not PNC.HomeDutyService.IsAtHome(record, base.id) then
        return false, "NOT_AT_HOME"
    end
    if not Home.HasFacility(record, definition.id) then
        return false, "NEED_ROUTE_NOT_ACTIONABLE"
    end
    if not hasRequiredPersonalSupply(record, definition) then
        return false, "PERSONAL_SUPPLY_MISSING"
    end
    return true
end

function Home.Assign(record, intent)
    local base = record and Home.GetBase(record) or nil
    if not base then return nil, "BASE_NOT_FOUND" end
    if record.runtime and record.runtime.facilityActivity
        and record.runtime.facilityActivity.automatic == true
        and PNC.FacilityJobs
    then
        PNC.FacilityJobs.Stop(record,
            "need_trigger_" .. tostring(intent.sourceRef))
    end
    local live = PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    PNC.Tasking.Diagnostics.counters.facilityLookups =
        PNC.Tasking.Diagnostics.counters.facilityLookups + 1
    local acquired = PNC.FacilityService.AcquireActivity(base.id, record.id,
        intent.capability, { ttlMs = 30000, abstract = live == nil })
    if not acquired.ok or not acquired.target then
        return nil, acquired.reason or "NO_ACTIVITY_CAPACITY"
    end
    acquired.executionMode = live and "LIVE" or "ABSTRACT"
    return acquired
end

function Home.Start(record, lease, assignment)
    local ok, reason = PNC.FacilityJobs.Start(record, assignment.facilityId,
        lease.capability, { automatic = true, acquired = assignment,
            taskLeaseId = lease.leaseId,
            abstract = lease.executionMode == "ABSTRACT" })
    if ok then
        PNC.TaskLeaseService.SetPhase(lease.leaseId,
            lease.executionMode == "LIVE" and "TRAVEL" or "WORKING")
    end
    return ok, reason
end

function Home.CanContinue(record, lease)
    return PNC.SettlementRepository.GetFacility(lease.facilityId) ~= nil
        and PNC.FacilityReservations.ByID[lease.reservationId] ~= nil
end

return Home
