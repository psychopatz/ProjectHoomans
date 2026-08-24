if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityJobs = PNC.FacilityJobs or {}
PNC.FacilityJobsServiceInternal = PNC.FacilityJobsServiceInternal or {}

local Jobs = PNC.FacilityJobs
local H = PNC.FacilityJobsServiceInternal
local Repository = PNC.SettlementRepository

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
        previousOrder = previousOrder,
        debugHold = options.debugHold == true,
        debugForceWater = options.debugForceWater == true,
        automatic = options.automatic == true,
        manual = options.manual == true,
        manualToggleable = options.manualToggleable == true,
        taskLeaseId = tostring(options.taskLeaseId or ""),
        abstract = options.abstract == true,
        resourceKind = tostring(options.resourceKind or ""),
        resourceKey = tostring(options.resourceKey or ""),
        activityItemFullType = activityItemFullType,
        resource = options.resource,
        approachCandidates = options.approachCandidates
            or acquired.approachCandidates,
        approachIndex = 1,
        failedApproaches = {},
    }
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
        interactionX = target.interactionX,
        interactionY = target.interactionY,
        interactionZ = target.interactionZ,
        interactionAxis = target.interactionAxis,
        interactionFacing = target.interactionFacing,
        sceneId = sceneId,
        sleepSurface = target.sleepSurface,
        taskLeaseId = tostring(options.taskLeaseId or ""),
        debugHold = options.debugHold == true,
        resourceKind = tostring(options.resourceKind or ""),
        resourceKey = tostring(options.resourceKey or ""),
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

