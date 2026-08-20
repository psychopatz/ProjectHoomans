if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityJobs = PNC.FacilityJobs or {}

local Jobs = PNC.FacilityJobs
local Repository = PNC.SettlementRepository

local function definitionCapability(facility)
    local level = facility and PNC.FacilityDefinitions.GetLevel(
        facility.definitionId, facility.level) or nil
    local index
    for index = 1, #(level and level.capabilities or {}) do
        local capability = level.capabilities[index]
        if PNC.FacilityJobDefinitions.Get(capability) then return capability end
    end
    return nil
end

local function baseForRecord(record)
    local affiliation = record and record.affiliation or {}
    local factionId = tostring(affiliation.factionID
        or affiliation.factionId or record and record.factionId or "")
    local colonyId = tostring(affiliation.communityID
        or affiliation.communityId or record and record.communityId or "")
    local id
    local base
    for id, base in pairs(Repository.State.bases or {}) do
        if factionId ~= "" and tostring(base.factionId or "") == factionId then
            return base
        end
        if colonyId ~= "" and tostring(base.colonyId or "") == colonyId then
            return base
        end
    end
    return nil
end

function Jobs.Start(record, facilityOrId, capability, options)
    options = type(options) == "table" and options or {}
    local facility = type(facilityOrId) == "table" and facilityOrId
        or Repository.GetFacility(facilityOrId)
    local base = facility and PNC.BaseService.Get(facility.baseId) or nil
    capability = tostring(capability or definitionCapability(facility) or "")
    local definition = PNC.FacilityJobDefinitions.Get(capability)
    if not record or record.alive == false then return false, "NPC_UNAVAILABLE" end
    if not base and options.nearby == true then
        base = { id = tostring(facility.baseId or "nearby") }
    end
    if not base or not facility then return false, "FACILITY_NOT_FOUND" end
    if not definition then return false, "FACILITY_HAS_NO_ACTIVITY" end
    if record.runtime and record.runtime.facilityActivity then
        Jobs.Stop(record, "activity_replaced")
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
        taskLeaseId = tostring(options.taskLeaseId or ""),
        abstract = options.abstract == true,
        resourceKind = tostring(options.resourceKind or ""),
        resourceKey = tostring(options.resourceKey or ""),
        resource = options.resource,
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
        or definitionCapability(facility)
    return Jobs.Start(record, facility, capability, options)
end

return Jobs
