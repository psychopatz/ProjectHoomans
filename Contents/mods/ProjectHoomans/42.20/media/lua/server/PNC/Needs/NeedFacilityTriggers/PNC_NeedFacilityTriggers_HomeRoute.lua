if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC.NeedFacilityHomeRoute = PNC.NeedFacilityHomeRoute or {}

local Home = PNC.NeedFacilityHomeRoute
local Definitions = PNC.NeedFacilityTriggerDefinitions

local function personalSupply(record, resourceKind, needType)
    local service = PNC.NPCSupplyService
    local current = PNC.IndividualNeeds and PNC.IndividualNeeds.Get
        and PNC.IndividualNeeds.Get(record, needType)
        or record and record.needs and record.needs[needType]
    local required = { hunger = 0, thirst = 0 }
    required[needType] = math.max(0.001, tonumber(current) or 0.001)
    if not service or not service.HasPersonalSupply then return false end
    return service.HasPersonalSupply(record, resourceKind, required)
end

local function hasPersonalSupply(record, resourceKind, needType)
    local available = personalSupply(record, resourceKind, needType)
    return available == true
end

local function personalFoodRetryBlocked(record)
    local runtime = record and record.runtime or nil
    local retryAt = tonumber(runtime and runtime.personalFoodRetryAt) or 0
    local now = PNC.Core and PNC.Core.Now and tonumber(PNC.Core.Now()) or 0
    return retryAt > now
end

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
        return not personalFoodRetryBlocked(record)
            and hasPersonalSupply(record, "FOOD", "hunger")
    end
    if definition and definition.needType == "thirst" then
        -- Hydration no longer belongs to a settlement facility. Route it
        -- through the personal-item or valid-world-source lanes, including
        -- when an old save still exposes a stale spigot capability.
        return false
    end
    return true
end

function Home.IsAvailable(record, definition)
    return Home.IsAtHome(record) and Home.HasFacility(record, definition.id)
        and hasRequiredPersonalSupply(record, definition)
end

function Home.Validate(record, definition)
    if definition and definition.needType == "thirst" then
        return false, "HOME_WATER_FACILITY_REMOVED"
    end
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
    local foodAvailable
    local foodFullType
    local foodItemID
    if not base then return nil, "BASE_NOT_FOUND" end
    if record.runtime and record.runtime.facilityActivity
        and record.runtime.facilityActivity.automatic == true
        and PNC.FacilityJobs
    then
        PNC.FacilityJobs.Stop(record,
            "need_trigger_" .. tostring(intent.sourceRef))
    end
    if intent.capability == "food.dine" then
        foodAvailable, foodFullType, foodItemID = personalSupply(
            record, "FOOD", "hunger")
        if not foodAvailable then return nil, "PERSONAL_FOOD_MISSING" end
        if personalFoodRetryBlocked(record) then
            return nil, "PERSONAL_FOOD_RETRY_COOLDOWN"
        end
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
    if intent.capability == "sleep" then
        acquired.sleepVariant = "HOME_BARRACKS"
        acquired.sleepTargetPolicy = acquired.resourceKind == "sleep_surface"
            and "BARRACKS_BED_FIRST" or "BARRACKS_FLOOR_FALLBACK"
    elseif intent.capability == "food.dine" then
        acquired.resourceKind = "personal_food"
        acquired.activityItemID = foodItemID
        acquired.activityItemFullType = foodFullType
    end
    acquired.executionMode = live and "LIVE" or "ABSTRACT"
    return acquired
end

function Home.Start(record, lease, assignment)
    local ok, reason = PNC.FacilityJobs.Start(record, assignment.facilityId,
        lease.capability, { automatic = true, acquired = assignment,
            taskLeaseId = lease.leaseId,
            abstract = lease.executionMode == "ABSTRACT",
            resourceKind = assignment.resourceKind,
            activityItemID = assignment.activityItemID,
            activityItemFullType = assignment.activityItemFullType })
    if ok then
        PNC.TaskLeaseService.SetPhase(lease.leaseId,
            lease.executionMode == "LIVE" and "TRAVEL" or "WORKING")
    end
    return ok, reason
end

function Home.CanContinue(record, lease)
    local facilityOK = PNC.SettlementRepository.GetFacility(lease.facilityId)
        ~= nil
    local reservationOK = lease.reservationId == nil
        or PNC.FacilityReservations.ByID[lease.reservationId] ~= nil
    return facilityOK and reservationOK
end

return Home
