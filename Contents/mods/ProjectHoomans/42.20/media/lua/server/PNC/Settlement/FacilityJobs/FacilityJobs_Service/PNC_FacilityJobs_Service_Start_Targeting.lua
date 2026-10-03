-- Facility activity target normalization and start-context preparation.
--
-- This provider owns live-object lookup, approach candidate copying, sleep
-- validation, and the durable context passed to the StartState installer.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityJobs = PNC.FacilityJobs or {}
PNC.FacilityJobsServiceInternal = PNC.FacilityJobsServiceInternal or {}

local H = PNC.FacilityJobsServiceInternal
local Diagnostics = PNC.PerformanceScalingDiagnostics

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
                sleepSlotId = candidate.sleepSlotId,
                sleepSlotIndex = tonumber(candidate.sleepSlotIndex),
                sleepCapacity = tonumber(candidate.sleepCapacity),
                bedCapacity = tonumber(candidate.bedCapacity),
                sleepAnchorX = tonumber(candidate.sleepAnchorX),
                sleepAnchorY = tonumber(candidate.sleepAnchorY),
                sleepAnchorZ = tonumber(candidate.sleepAnchorZ),
                sleepAxis = candidate.sleepAxis,
                sleepFacing = candidate.sleepFacing,
                sleepSprite = candidate.sleepSprite,
                sleepGridX = tonumber(candidate.sleepGridX),
                sleepGridY = tonumber(candidate.sleepGridY),
                sleepGridWidth = tonumber(candidate.sleepGridWidth),
                sleepGridHeight = tonumber(candidate.sleepGridHeight),
                sleepSurface = candidate.sleepSurface,
                sceneId = candidate.sceneId,
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
function H.PrepareStartContext(context)
    context = type(context) == "table" and context or {}
    local record = context.record
    local facility = context.facility
    local options = context.options
    local capability = context.capability
    local definition = context.definition
    local acquired = context.acquired
    local activityItemFullType = context.activityItemFullType
    local activityConsumptionMode = context.activityConsumptionMode
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
    local floorSeating = options.floorSeating == true
        or acquired.floorSeating == true
        or target.floorSeating == true
        or resource and resource.floorSeating == true
        or resourceKind == "floor_seating"
    local liveObject = resource and resource.object
        or target.object or target.furnitureObject
    local approachCandidates = copyApproachCandidates(
        options.approachCandidates or acquired.approachCandidates
            or acquired.targets)
    if not activityItemFullType and resource and resource.item
        and type(resource.item.getFullType) == "function"
    then
        local fullType = resource.item:getFullType()
        if tostring(fullType or "") ~= "" then
            activityItemFullType = tostring(fullType)
        end
    end
    if resource and PNC.FacilityResources
        and PNC.FacilityResources.CopyDescriptor
    then
        resource = PNC.FacilityResources.CopyDescriptor(resource)
    end
    local sceneId = tostring(target.sceneId or definition.sceneId or "")
    local facilityDefinition = PNC.FacilityDefinitions.Get(facility.definitionId)
    local seatSessionId = seating and Diagnostics
        and Diagnostics.NewSeatingSessionId
        and Diagnostics.NewSeatingSessionId(record.id) or ""
    if capability == "sleep" and PNC.FacilityResources
        and PNC.FacilityResources.IsValidSleepTarget
        and not PNC.FacilityResources.IsValidSleepTarget(
            resource or { resourceKind = resourceKind }, target)
    then
        if acquired.reservationId and PNC.FacilityReservations
            and PNC.FacilityReservations.Release
        then
            PNC.FacilityReservations.Release(
                acquired.reservationId, "invalid_sleep_target")
        end
        return false, "INVALID_SLEEP_TARGET"
    end
    local previousOrder = PNC.Core.DeepCopy(record.orderSpec)
    local campOrderSpec = record.orderSpec
    local campScope = options.scope or options.siteScope
        or acquired.scope or acquired.siteScope
        or campOrderSpec and (campOrderSpec.scope or campOrderSpec.siteScope)
    local campRoomBounds = options.roomBounds or acquired.roomBounds
        or campOrderSpec and campOrderSpec.roomBounds
    local activityStartedAt = PNC.Core.Now()
    return {
        record = record,
        facility = facility,
        options = options,
        capability = capability,
        acquired = acquired,
        target = target,
        resource = resource,
        resourceKind = resourceKind,
        resourceKey = resourceKey,
        seating = seating,
        floorSeating = floorSeating,
        liveObject = liveObject,
        live = live,
        approachCandidates = approachCandidates,
        activityItemFullType = activityItemFullType,
        activityConsumptionMode = activityConsumptionMode,
        sceneId = sceneId,
        facilityDefinition = facilityDefinition,
        seatSessionId = seatSessionId,
        previousOrder = previousOrder,
        campOrderSpec = campOrderSpec,
        campScope = campScope,
        campRoomBounds = campRoomBounds,
        activityStartedAt = activityStartedAt,
    }
end

return H
