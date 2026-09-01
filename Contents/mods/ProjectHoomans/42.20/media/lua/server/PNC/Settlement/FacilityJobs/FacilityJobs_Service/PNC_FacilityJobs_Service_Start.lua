if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityJobs = PNC.FacilityJobs or {}
PNC.FacilityJobsServiceInternal = PNC.FacilityJobsServiceInternal or {}

local Jobs = PNC.FacilityJobs
local H = PNC.FacilityJobsServiceInternal
local Repository = PNC.SettlementRepository

local function copyApproachCandidates(candidates)
    if type(candidates) ~= "table" then return nil end
    local output = {}
    for index = 1, #candidates do
        local candidate = candidates[index]
        if type(candidate) == "table" then
            output[#output + 1] = {
                x = tonumber(candidate.x), y = tonumber(candidate.y),
                z = tonumber(candidate.z),
                seatAnchorX = tonumber(candidate.seatAnchorX),
                seatAnchorY = tonumber(candidate.seatAnchorY),
                seatAnchorZ = tonumber(candidate.seatAnchorZ),
                interactionX = tonumber(candidate.interactionX),
                interactionY = tonumber(candidate.interactionY),
                interactionZ = tonumber(candidate.interactionZ),
                interactionAxis = candidate.interactionAxis,
                interactionFacing = candidate.interactionFacing,
                approachKey = candidate.approachKey,
                seatDirection = candidate.seatDirection
                    or candidate.direction,
                seatSide = candidate.seatSide or candidate.side,
                validSpot = candidate.validSpot,
                validationState = candidate.validationState,
                rejectionReason = candidate.rejectionReason,
                routeStatus = candidate.routeStatus,
                stopDistance = tonumber(candidate.stopDistance),
                arrivalDistance = tonumber(candidate.arrivalDistance),
            }
        end
    end
    return #output > 0 and output or nil
end

function Jobs.Start(record, facilityOrId, capability, options)
    options = type(options) == "table" and options or {}
    local facility = type(facilityOrId) == "table" and facilityOrId
        or Repository.GetFacility(facilityOrId)
    local base = facility and PNC.BaseService.Get(facility.baseId) or nil
    capability = tostring(capability or H.DefinitionCapability(facility) or "")
    local definition = PNC.FacilityJobDefinitions.Get(capability)
    local activityItemFullType
    if not record or record.alive == false then return false, "NPC_UNAVAILABLE" end
    if not base and options.nearby == true then
        base = { id = tostring(facility.baseId or "nearby") }
    end
    if not base or not facility then return false, "FACILITY_NOT_FOUND" end
    if not definition then return false, "FACILITY_HAS_NO_ACTIVITY" end
    activityItemFullType = H.ResolveFoodItemFullType(
        record, capability, options)
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
    -- The animation arbiter may be holding an ambient idle scene. Starting a
    -- facility order must release that presentation lease immediately or the
    -- behavior coordinator will keep servicing the idle scene and never reach
    -- the facility job (most visible with sleep, whose scene is otherwise
    -- perfectly valid once the NPC arrives).
    local live = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    if live and PNC.AnimationScenes and PNC.AnimationScenes.Interrupt then
        PNC.AnimationScenes.Interrupt(record, live, "movement")
    end
    local target = acquired.target
    local resourceKind = options.resourceKind or acquired.resourceKind or ""
    local resourceKey = options.resourceKey or acquired.resourceKey or ""
    local resource = options.resource or acquired.resource
    local seating = options.seating == true or target.seating == true
        or resourceKind == "seating_surface"
    local liveObject = resource and resource.object
        or target.object or target.furnitureObject
    local approachCandidates = copyApproachCandidates(
        options.approachCandidates or acquired.approachCandidates
            or acquired.targets)
    if resource and PNC.FacilityResources
        and PNC.FacilityResources.CopyDescriptor
    then
        resource = PNC.FacilityResources.CopyDescriptor(resource)
    end
    local sceneId = tostring(target.sceneId or definition.sceneId or "")
    local facilityDefinition = PNC.FacilityDefinitions.Get(facility.definitionId)
    local previousOrder = PNC.Core.DeepCopy(record.orderSpec)
    record.runtime = record.runtime or {}
    record.runtime.facilityActivity = {
        capability = capability,
        facilityId = facility.id,
        facilityName = facilityDefinition and facilityDefinition.displayNameKey
            or facility.definitionId,
        componentId = acquired.componentId,
        componentRole = acquired.role or "",
        reservationId = acquired.reservationId,
        sceneId = sceneId,
        sleepSurface = tostring(target.sleepSurface or ""),
        phase = "QUEUED",
        target = { x = target.x, y = target.y, z = target.z },
        seatAnchor = target.seatAnchorX and {
            x = tonumber(target.seatAnchorX),
            y = tonumber(target.seatAnchorY),
            z = tonumber(target.seatAnchorZ or target.z),
        } or nil,
        previousOrder = previousOrder,
        debugHold = options.debugHold == true,
        debugForceWater = options.debugForceWater == true,
        automatic = options.automatic == true,
        manual = options.manual == true,
        manualToggleable = options.manualToggleable == true,
        taskLeaseId = tostring(options.taskLeaseId or ""),
        abstract = options.abstract == true,
        resourceKind = tostring(resourceKind),
        resourceKey = tostring(resourceKey),
        seating = seating,
        seatDirection = tostring(target.seatDirection or ""),
        seatSide = tostring(target.seatSide or ""),
        approachKey = tostring(target.approachKey or ""),
        validSpot = target.validSpot ~= false,
        seatValidation = tostring(target.validationState or ""),
        seatRejectionReason = tostring(target.rejectionReason or ""),
        seatRouteStatus = tostring(target.routeStatus or "UNTESTED"),
        seatStopDistance = tonumber(target.stopDistance) or 0.10,
        seatArrivalDistance = tonumber(target.arrivalDistance) or 0.14,
        campActivity = options.campActivity == true,
        campId = tostring(options.campId or ""),
        campX = tonumber(options.campX or acquired.campX),
        campY = tonumber(options.campY or acquired.campY),
        campZ = tonumber(options.campZ or acquired.campZ),
        campRadius = tonumber(options.campRadius or acquired.campRadius),
        resourceRadius = tonumber(
            options.resourceRadius or acquired.resourceRadius),
        activityItemFullType = activityItemFullType,
        resource = resource,
        approachCandidates = approachCandidates,
        approachIndex = 1,
        failedApproaches = {},
    }
    if seating and live and liveObject and PNC.SeatingRuntime
        and PNC.SeatingRuntime.LiveObjects
    then
        PNC.SeatingRuntime.LiveObjects[tostring(record.id)] = liveObject
    end
    if options.debugHold == true then
        record.runtime.facilityDebugWork = record.runtime.facilityActivity
    end
    PNC.OrderSystem.SetOrder(record, {
        kind = "facility_activity",
        capability = capability,
        facilityId = facility.id,
        facilityName = record.runtime.facilityActivity.facilityName,
        componentId = acquired.componentId,
        componentRole = acquired.role or "",
        reservationId = acquired.reservationId,
        x = target.x, y = target.y, z = target.z,
        seatAnchorX = target.seatAnchorX,
        seatAnchorY = target.seatAnchorY,
        seatAnchorZ = target.seatAnchorZ,
        interactionX = target.interactionX,
        interactionY = target.interactionY,
        interactionZ = target.interactionZ,
        interactionSurfaceOffset = target.interactionSurfaceOffset,
        interactionAxis = target.interactionAxis,
        interactionFacing = target.interactionFacing,
        approachKey = target.approachKey,
        seatDirection = target.seatDirection,
        seatSide = target.seatSide,
        validSpot = target.validSpot,
        validationState = target.validationState,
        rejectionReason = target.rejectionReason,
        routeStatus = target.routeStatus,
        stopDistance = target.stopDistance,
        arrivalDistance = target.arrivalDistance,
        seating = seating,
        sceneId = sceneId,
        sleepSurface = target.sleepSurface,
        taskLeaseId = tostring(options.taskLeaseId or ""),
        debugHold = options.debugHold == true,
        resourceKind = tostring(resourceKind),
        resourceKey = tostring(resourceKey),
        campActivity = options.campActivity == true,
        campId = tostring(options.campId or ""),
        campX = tonumber(options.campX or acquired.campX),
        campY = tonumber(options.campY or acquired.campY),
        campZ = tonumber(options.campZ or acquired.campZ),
        campRadius = tonumber(options.campRadius or acquired.campRadius),
        resourceRadius = tonumber(
            options.resourceRadius or acquired.resourceRadius),
        activityItemFullType = activityItemFullType,
    })
    return true, "facility_activity_started", {
        npcID = record.id,
        facilityId = facility.id,
        capability = capability,
        target = { x = target.x, y = target.y, z = target.z },
    }
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
