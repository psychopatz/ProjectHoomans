PNC = PNC or {}
PNC.FacilityJobs = PNC.FacilityJobs or {}
PNC.FacilityJobsBehaviorInternal = PNC.FacilityJobsBehaviorInternal or {}

local Internal = PNC.FacilityJobsBehaviorInternal
local KIND = Internal.KIND

PNC.SeatingRuntime = PNC.SeatingRuntime or {}
PNC.SeatingRuntime.LiveObjects = PNC.SeatingRuntime.LiveObjects or {}
PNC.SleepRuntime = PNC.SleepRuntime or {}
PNC.SleepRuntime.LiveObjects = PNC.SleepRuntime.LiveObjects or {}

function Internal.Normalize(_, spec)
    return {
        kind = KIND,
        capability = tostring(spec.capability or ""),
        facilityId = tostring(spec.facilityId or ""),
        facilityName = tostring(spec.facilityName or spec.facilityId or "Facility"),
        componentId = tostring(spec.componentId or ""),
        componentRole = tostring(spec.componentRole or ""),
        reservationId = tostring(spec.reservationId or ""),
        x = tonumber(spec.x) or 0,
        y = tonumber(spec.y) or 0,
        z = tonumber(spec.z) or 0,
        interactionX = tonumber(spec.interactionX),
        interactionY = tonumber(spec.interactionY),
        interactionZ = tonumber(spec.interactionZ),
        interactionSurfaceOffset = tonumber(spec.interactionSurfaceOffset),
        interactionAxis = tostring(spec.interactionAxis or ""),
        interactionFacing = tostring(spec.interactionFacing or ""),
        sleepAnchorX = tonumber(spec.sleepAnchorX),
        sleepAnchorY = tonumber(spec.sleepAnchorY),
        sleepAnchorZ = tonumber(spec.sleepAnchorZ),
        sleepAxis = tostring(spec.sleepAxis or ""),
        sleepFacing = tostring(spec.sleepFacing or ""),
        sleepSprite = tostring(spec.sleepSprite or ""),
        sleepGridX = tonumber(spec.sleepGridX),
        sleepGridY = tonumber(spec.sleepGridY),
        sleepGridWidth = tonumber(spec.sleepGridWidth),
        sleepGridHeight = tonumber(spec.sleepGridHeight),
        seatDirection = tostring(spec.seatDirection or ""),
        seatSide = tostring(spec.seatSide or ""),
        approachKey = tostring(spec.approachKey or ""),
        validSpot = spec.validSpot ~= false,
        seatAnchorX = tonumber(spec.seatAnchorX),
        seatAnchorY = tonumber(spec.seatAnchorY),
        seatAnchorZ = tonumber(spec.seatAnchorZ),
        validationState = tostring(spec.validationState or ""),
        rejectionReason = tostring(spec.rejectionReason or ""),
        routeStatus = tostring(spec.routeStatus or "UNTESTED"),
        stopDistance = tonumber(spec.stopDistance),
        arrivalDistance = tonumber(spec.arrivalDistance),
        seating = spec.seating == true,
        sceneId = tostring(spec.sceneId or ""),
        sleepSurface = tostring(spec.sleepSurface or ""),
        taskLeaseId = tostring(spec.taskLeaseId or ""),
        resourceKind = tostring(spec.resourceKind or ""),
        resourceKey = tostring(spec.resourceKey or ""),
        campActivity = spec.campActivity == true,
        campId = tostring(spec.campId or ""),
        campX = tonumber(spec.campX),
        campY = tonumber(spec.campY),
        campZ = tonumber(spec.campZ),
        campRadius = tonumber(spec.campRadius),
        resourceRadius = tonumber(spec.resourceRadius),
        activityItemFullType = tostring(spec.activityItemFullType or ""),
        debugHold = spec.debugHold == true,
    }
end

function Internal.State(record)
    return record and record.runtime and record.runtime.facilityActivity or nil
end

function Internal.CurrentTime(runtime)
    if PNC.Core and PNC.Core.Now then return PNC.Core.Now() end
    return tonumber(runtime and runtime.lastProgressAt) or 1
end

function Internal.ResolveLiveObject(record, runtime, runtimeRegistry)
    local objects = runtimeRegistry and runtimeRegistry.LiveObjects
    local key = tostring(record and record.id or "")
    local object = objects and objects[key]
    if object then return object end
    if runtime and runtime.resource and PNC.FacilityResources
        and PNC.FacilityResources.ResolveLiveObject
    then
        object = PNC.FacilityResources.ResolveLiveObject(runtime.resource)
        if object and objects and key ~= "" then objects[key] = object end
    end
    return object
end

function Internal.LiveSeatObject(record, runtime)
    return Internal.ResolveLiveObject(record, runtime, PNC.SeatingRuntime)
end

function Internal.LiveSleepObject(record, runtime)
    return Internal.ResolveLiveObject(record, runtime, PNC.SleepRuntime)
end

return Internal
