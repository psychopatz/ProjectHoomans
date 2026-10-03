-- Durable facility activity state construction.
--
-- This provider builds the save-safe runtime activity descriptor. It does not
-- mutate the record or install executor orders; those effects remain owned by
-- the StartState composition provider.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityJobs = PNC.FacilityJobs or {}
PNC.FacilityJobsServiceInternal = PNC.FacilityJobsServiceInternal or {}

local H = PNC.FacilityJobsServiceInternal

function H.BuildFacilityActivityState(context)
    context = type(context) == "table" and context or {}
    local record = context.record
    local facility = context.facility
    local options = context.options
    local capability = context.capability
    local acquired = context.acquired
    local target = context.target
    local resource = context.resource
    local resourceKind = context.resourceKind
    local resourceKey = context.resourceKey
    local seating = context.seating
    local floorSeating = context.floorSeating
    local liveObject = context.liveObject
    local live = context.live
    local approachCandidates = context.approachCandidates
    local activityItemFullType = context.activityItemFullType
    local activityConsumptionMode = context.activityConsumptionMode
    local sceneId = context.sceneId
    local facilityDefinition = context.facilityDefinition
    local seatSessionId = context.seatSessionId
    local previousOrder = context.previousOrder
    local campOrderSpec = context.campOrderSpec
    local campScope = context.campScope
    local campRoomBounds = context.campRoomBounds
    local activityStartedAt = context.activityStartedAt
    local activityState = {
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
        startedAt = activityStartedAt,
        lastProgressAt = activityStartedAt,
        lastProgressReason = "facility_activity_started",
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
        manualOverride = options.manualOverride == true,
        waterContextKind = tostring(options.waterContextKind or ""),
        waterBaseId = options.waterBaseId,
        manualToggleable = options.manualToggleable == true,
        manualCommandID = tostring(options.manualCommandID or ""),
        manualRequestID = options.manualRequestID,
        manualCommandSource = tostring(options.manualCommandSource or ""),
        sleepVariant = tostring(options.sleepVariant
            or acquired.sleepVariant or ""),
        sleepSlotId = tostring(target.sleepSlotId
            or acquired.sleepSlotId or ""),
        sleepSlotIndex = tonumber(target.sleepSlotIndex),
        sleepCapacity = tonumber(target.sleepCapacity
            or acquired.sleepCapacity),
        bedCapacity = tonumber(target.bedCapacity
            or target.sleepCapacity or acquired.sleepCapacity),
        sleepTargetPolicy = tostring(options.sleepTargetPolicy
            or acquired.sleepTargetPolicy or ""),
        sleepCompletionPolicy = capability == "sleep"
            and (options.manual == true and "MANUAL_TOGGLE"
                or "FATIGUE_THRESHOLD") or "",
        sleepSceneActive = false,
        taskLeaseId = tostring(options.taskLeaseId or ""),
        startupSceneId = sceneId,
        startupStartedAt = activityStartedAt,
        startupAttempts = 0,
        startupLastAttemptAt = 0,
        abstract = options.abstract == true,
        resourceKind = tostring(resourceKind),
        resourceKey = tostring(resourceKey),
        seating = seating,
        floorSeating = floorSeating,
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
        scope = campScope,
        siteScope = campScope,
        siteID = options.siteID or acquired.siteID
            or campOrderSpec and campOrderSpec.siteID,
        roomID = options.roomID or acquired.roomID
            or campOrderSpec and campOrderSpec.roomID,
        buildingID = options.buildingID or acquired.buildingID
            or campOrderSpec and campOrderSpec.buildingID,
        roomType = options.roomType or acquired.roomType
            or campOrderSpec and campOrderSpec.roomType,
        roomName = options.roomName or acquired.roomName
            or campOrderSpec and campOrderSpec.roomName,
        roomBounds = campRoomBounds and PNC.Core.DeepCopy(campRoomBounds)
            or nil,
        campfireID = options.campfireID or acquired.campfireID
            or campOrderSpec and campOrderSpec.campfireID,
        zoneID = options.zoneID or acquired.zoneID
            or campOrderSpec and campOrderSpec.zoneID,
        zoneLabel = options.zoneLabel or acquired.zoneLabel
            or campOrderSpec and campOrderSpec.zoneLabel,
        zoneScope = options.zoneScope or acquired.zoneScope
            or campOrderSpec and campOrderSpec.zoneScope,
        zoneNeedKind = options.zoneNeedKind or acquired.zoneNeedKind
            or campOrderSpec and campOrderSpec.zoneNeedKind,
        zoneReason = options.zoneReason or acquired.zoneReason
            or campOrderSpec and campOrderSpec.zoneReason,
        zoneScore = tonumber(options.zoneScore or acquired.zoneScore
            or campOrderSpec and campOrderSpec.zoneScore),
        zoneRevision = tonumber(options.zoneRevision or acquired.zoneRevision
            or campOrderSpec and campOrderSpec.zoneRevision),
        campRootX = tonumber(options.campRootX or acquired.campRootX
            or campOrderSpec and campOrderSpec.campRootX),
        campRootY = tonumber(options.campRootY or acquired.campRootY
            or campOrderSpec and campOrderSpec.campRootY),
        campRootZ = tonumber(options.campRootZ or acquired.campRootZ
            or campOrderSpec and campOrderSpec.campRootZ),
        campRootScope = options.campRootScope or acquired.campRootScope
            or campOrderSpec and campOrderSpec.campRootScope,
        campRootSiteID = options.campRootSiteID or acquired.campRootSiteID
            or campOrderSpec and campOrderSpec.campRootSiteID,
        campRootRoomID = options.campRootRoomID or acquired.campRootRoomID
            or campOrderSpec and campOrderSpec.campRootRoomID,
        campRootBuildingID = options.campRootBuildingID
            or acquired.campRootBuildingID
            or campOrderSpec and campOrderSpec.campRootBuildingID,
        campRootRoomType = options.campRootRoomType or acquired.campRootRoomType
            or campOrderSpec and campOrderSpec.campRootRoomType,
        campRootRoomName = options.campRootRoomName or acquired.campRootRoomName
            or campOrderSpec and campOrderSpec.campRootRoomName,
        campRootRoomBounds = options.campRootRoomBounds
            or acquired.campRootRoomBounds
            or campOrderSpec and campOrderSpec.campRootRoomBounds,
        campRootCampfireID = options.campRootCampfireID
            or acquired.campRootCampfireID
            or campOrderSpec and campOrderSpec.campRootCampfireID,
        campX = tonumber(options.campX or acquired.campX),
        campY = tonumber(options.campY or acquired.campY),
        campZ = tonumber(options.campZ or acquired.campZ),
        campRadius = tonumber(options.campRadius or acquired.campRadius),
        resourceRadius = tonumber(
            options.resourceRadius or acquired.resourceRadius),
        activityItemID = tostring(options.activityItemID or ""),
        activityItemFullType = activityItemFullType,
        activityConsumptionMode = activityConsumptionMode,
        resource = resource,
        approachCandidates = approachCandidates,
        approachIndex = 1,
        failedApproaches = {},
        seatSessionId = seatSessionId,
    }
    return activityState
end

return H
