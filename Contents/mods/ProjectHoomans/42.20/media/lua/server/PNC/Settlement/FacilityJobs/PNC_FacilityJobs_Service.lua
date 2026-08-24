if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityJobs = PNC.FacilityJobs or {}

local Jobs = PNC.FacilityJobs
local Repository = PNC.SettlementRepository
local baseForRecord

local function livePosition(record)
    local zombie = record and record.id and PNC.Registry
        and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    if zombie and (not zombie.isDead or not zombie:isDead()) then
        return zombie:getX(), zombie:getY(), zombie:getZ()
    end
    return tonumber(record and record.x) or 0,
        tonumber(record and record.y) or 0,
        tonumber(record and record.z) or 0
end

local function stopExistingActivity(record, reason)
    local runtime = record and record.runtime or nil
    local activity = runtime and runtime.facilityActivity or nil
    local taskLeaseId = tostring(activity and activity.taskLeaseId or "")
    if taskLeaseId ~= "" and PNC.Tasking and PNC.Tasking.Commands
        and PNC.Tasking.Commands.CancelForNPC
    then
        PNC.Tasking.Commands.CancelForNPC(record.id, reason)
    end
    if record and record.runtime and record.runtime.facilityActivity
        and Jobs.Stop
    then
        return Jobs.Stop(record, reason)
    end
    return true, "facility_activity_stopped"
end

function Jobs.StopControlled(record, reason)
    if not record or not record.runtime
        or not record.runtime.facilityActivity
    then
        return false, "facility_activity_not_active"
    end
    return stopExistingActivity(record, reason or "player_stop")
end

local function hasPersonalFood(record)
    local available
    local fullType
    if not PNC.NPCSupplyService
        or not PNC.NPCSupplyService.HasPersonalSupply
    then
        return false
    end
    available, fullType = PNC.NPCSupplyService.HasPersonalSupply(
        record, "FOOD", {
            hunger = math.max(0.001, tonumber(record and record.needs
                and record.needs.hunger) or 0.001),
            thirst = 0,
        })
    return available == true, fullType
end

local function manualFoodAssignment(record)
    local x, y, z = livePosition(record)
    return {
        ok = true,
        facilityId = "manual_food:" .. tostring(record.id),
        componentId = "",
        reservationId = "",
        target = { x = x, y = y, z = z },
    }
end

local function manualHomeActivity(record, capability)
    local base = baseForRecord(record)
    local acquired
    if not base or not PNC.FacilityService
        or not PNC.FacilityService.AcquireActivity
    then
        return nil, "BASE_NOT_FOUND"
    end
    acquired = PNC.FacilityService.AcquireActivity(
        base.id, record.id, capability, { ttlMs = 30000 })
    if not acquired.ok or not acquired.target then
        return nil, acquired.reason or "NO_ACTIVITY_CAPACITY"
    end
    return acquired
end

local function manualNearbyWaterActivity(record)
    local routes = PNC.NeedFacilityAwayRoutes
    local route = routes and routes.Get and routes.Get("nearby_water") or nil
    local assignment
    if not route or type(route.Assign) ~= "function" then
        return nil, "NEARBY_WATER_NOT_FOUND"
    end
    assignment = route.Assign(record)
    if not assignment then
        return nil, "NEARBY_WATER_NOT_FOUND"
    end
    return assignment
end

local function manualStart(record, capability)
    local live = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    local assignment
    local facility
    local started
    local reason
    local options = {
        manual = true,
        manualToggleable = capability == "sleep",
        abstract = live == nil,
    }
    if capability == "survival.eat.inventory" then
        local hasFood
        local foodFullType
        hasFood, foodFullType = hasPersonalFood(record)
        if not hasFood then
            return false, "PERSONAL_FOOD_MISSING"
        end
        assignment = manualFoodAssignment(record)
        options.acquired = assignment
        options.nearby = true
        options.resourceKind = "personal_food"
        options.activityItemFullType = foodFullType
        facility = {
            id = assignment.facilityId,
            baseId = "nearby",
            definitionId = "manual_food",
        }
    elseif capability == "water.drink" or capability == "sleep" then
        assignment = manualHomeActivity(record, capability)
        if assignment then
            facility = assignment.facilityId
            options.acquired = assignment
        elseif capability == "water.drink" then
            assignment = manualNearbyWaterActivity(record)
            if not assignment then
                return false, "NO_WATER_ACTIVITY"
            end
            options.acquired = assignment
            options.nearby = true
            options.resource = assignment.resource
            options.resourceKey = assignment.resourceKey
            options.resourceKind = "nearby_water"
            options.approachCandidates = assignment.approachCandidates
            facility = {
                id = assignment.facilityId,
                baseId = "nearby",
                definitionId = "nearby_water",
            }
            capability = "water.nearby"
            options.manualToggleable = false
        else
            return false, "NO_SLEEP_ACTIVITY"
        end
    else
        return false, "UNKNOWN_MANUAL_ACTIVITY"
    end
    started, reason = Jobs.Start(record, facility, capability, options)
    if started ~= true and assignment and assignment.reservationId
        and assignment.reservationId ~= ""
        and PNC.FacilityReservations
        and PNC.FacilityReservations.Release
    then
        PNC.FacilityReservations.Release(
            assignment.reservationId,
            reason or "manual_activity_start_failed")
    end
    return started, reason
end

local function sameManualActivity(requested, active)
    requested = tostring(requested or "")
    active = tostring(active or "")
    if requested == active then return true end
    if requested == "survival.eat.inventory" and active == "food.dine"
        or requested == "water.drink" and active == "water.nearby"
    then
        return true
    end
    return false
end

function Jobs.ToggleManual(record, capability)
    local runtime = record and record.runtime or nil
    local activity = runtime and runtime.facilityActivity or nil
    local requested = tostring(capability or "")
    local activeCapability = tostring(activity and activity.capability or "")
    local toggleable = requested == "sleep"
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    if not record or record.alive == false then
        return false, "NPC_UNAVAILABLE"
    end
    if requested == "" then return false, "UNKNOWN_MANUAL_ACTIVITY" end
    if activity and sameManualActivity(requested, activeCapability) then
        if not toggleable then return true, "facility_activity_active" end
        local stopped, reason = Jobs.StopControlled(record, "manual_toggle_off")
        if stopped and toggleable then
            record.runtime.manualActivityDisabled = requested
        end
        return stopped, reason
    end
    if runtime and (runtime.workOrderId or runtime.attackAction
        or runtime.target or now < (tonumber(runtime.inCombatUntil) or 0))
    then
        return false, "NPC_BUSY"
    end
    if record.health and record.health.state == "incapacitated" then
        return false, "NPC_INCAPACITATED"
    end
    if activity then
        local stopped = Jobs.StopControlled(record, "manual_activity_replaced")
        if not stopped and record.runtime.facilityActivity then
            return false, "FACILITY_ACTIVITY_BUSY"
        end
    end
    local started, reason = manualStart(record, requested)
    if started and requested == "sleep" then
        record.runtime.manualActivityDisabled = nil
    end
    return started, reason
end

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

local function resolveFoodItemFullType(record, capability, options)
    local explicit = options and options.activityItemFullType or nil
    local supply = record and record.runtime
        and record.runtime.supply and record.runtime.supply.byKind
        and record.runtime.supply.byKind.FOOD or nil
    local used = supply and supply.lastUsedItem or nil
    local candidates = supply and supply.personalCandidates or nil
    local required = {
        hunger = math.max(0.001, tonumber(record and record.needs
            and record.needs.hunger) or 0.001),
        thirst = 0,
    }
    if explicit and tostring(explicit) ~= "" then
        return tostring(explicit)
    end
    if capability ~= "food.dine"
        and capability ~= "survival.eat.inventory"
    then return nil end
    if used and used.fullType then return tostring(used.fullType) end
    if candidates and candidates[1] and candidates[1].fullType then
        return tostring(candidates[1].fullType)
    end
    if PNC.NPCSupplyService
        and PNC.NPCSupplyService.HasPersonalSupply
    then
        local _, fullType = PNC.NPCSupplyService.HasPersonalSupply(
            record, "FOOD", required)
        return fullType and tostring(fullType) or nil
    end
    return nil
end

baseForRecord = function(record)
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
    local activityItemFullType
    if not record or record.alive == false then return false, "NPC_UNAVAILABLE" end
    if not base and options.nearby == true then
        base = { id = tostring(facility.baseId or "nearby") }
    end
    if not base or not facility then return false, "FACILITY_NOT_FOUND" end
    if not definition then return false, "FACILITY_HAS_NO_ACTIVITY" end
    activityItemFullType = resolveFoodItemFullType(
        record, capability, options)
    if record.runtime and record.runtime.facilityActivity then
        local stopped, stopReason = stopExistingActivity(
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
        or definitionCapability(facility)
    return Jobs.Start(record, facility, capability, options)
end

return Jobs
