if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Routes = PNC and PNC.NeedFacilityAwayRoutes
if not Routes then
    return
end

local Internal = Routes.Internal
if not Internal then
    return
end

local campSleep = Internal.campSleep
local routeOrder = Internal.routeOrder
local campWater = Internal.campWater
local liveBody = Internal.liveBody

Routes.Register({
    sourceRef = "camp_sleep",
    needId = "sleep",
    capability = "sleep",
    IsAvailable = function(record)
        return Routes.IsCamped(record)
            and not Routes.IsCombatActive(record)
            and PNC.CampResourceService ~= nil
    end,
    Validate = function(record)
        if not Routes.IsCamped(record) then return false, "NOT_CAMPED" end
        if Routes.IsCombatActive(record) then return false, "NPC_BUSY" end
        if not PNC.CampResourceService then
            return false, "CAMP_RESOURCES_UNAVAILABLE"
        end
        return true
    end,
    TaskSuffix = function(record)
        local order = record and record.orderSpec or {}
        return tostring(order.campId or record.id)
            .. ":" .. tostring(record.id)
    end,
    Assign = function(record)
        local live = PNC.Registry and PNC.Registry.GetLiveZombie
            and PNC.Registry.GetLiveZombie(record.id) or nil
        return campSleep(record, { abstract = live == nil })
    end,
    Start = function(record, lease, assignment)
        if not Routes.IsCamped(record) then return false, "NOT_CAMPED" end
        return PNC.FacilityJobs.Start(record, {
            id = assignment.facilityId, baseId = "nearby",
            definitionId = "camp",
        }, "sleep", {
            automatic = true, acquired = assignment,
            resource = assignment.resource,
            resourceKey = assignment.resourceKey,
            resourceKind = assignment.resourceKind,
            approachCandidates = assignment.approachCandidates,
            taskLeaseId = lease.leaseId, nearby = true,
            abstract = lease.executionMode == "ABSTRACT",
            campActivity = true, campId = assignment.campId,
            campX = assignment.campX,
            campY = assignment.campY,
            campZ = assignment.campZ,
            campRadius = assignment.campRadius,
            resourceRadius = assignment.resourceRadius,
        })
    end,
    CanContinue = function(record)
        return Routes.IsCampContext(record) and not Routes.IsCombatActive(record)
    end,
})

Routes.Register({
    sourceRef = "camp_water",
    needId = "hydration",
    capability = "survival.drink.world",
    IsAvailable = function(record)
        local live = liveBody(record)
        return Routes.IsCamped(record)
            and not Routes.IsCombatActive(record)
            and not Routes.HasPersonalHydration(record)
            and PNC.CampResourceService
            and PNC.CampResourceService.FindWater
            and PNC.CampResourceService.FindWater(record, {
                abstract = live == nil,
            }) ~= nil
    end,
    Validate = function(record)
        local live = liveBody(record)
        if not Routes.IsCampContext(record) then
            return false, "NOT_CAMPED"
        end
        if Routes.IsCombatActive(record) then return false, "NPC_BUSY" end
        if Routes.HasPersonalHydration(record) then
            return false, "PERSONAL_HYDRATION_AVAILABLE"
        end
        if not PNC.CampResourceService
            or not PNC.CampResourceService.FindWater
        then
            return false, "CAMP_RESOURCES_UNAVAILABLE"
        end
        local resource, _, _, _, reason = PNC.CampResourceService.FindWater(
            record, { abstract = live == nil })
        if not resource then return false, reason or "CAMP_WATER_UNAVAILABLE" end
        return true
    end,
    TaskSuffix = function(record)
        local live = liveBody(record)
        local resource = PNC.CampResourceService.FindWater(record, {
            abstract = live == nil,
        })
        local order = routeOrder(record)
        return tostring(order.campId or "camp") .. ":"
            .. tostring(resource and resource.resourceKey or "unknown")
            .. ":" .. tostring(record.id)
    end,
    Assign = function(record)
        local live = liveBody(record)
        return campWater(record, { abstract = live == nil })
    end,
    Start = function(record, lease, assignment)
        if not Routes.IsCampContext(record) then return false, "NOT_CAMPED" end
        return PNC.FacilityJobs.Start(record, {
            id = assignment.facilityId, baseId = "nearby",
            definitionId = "camp",
        }, "survival.drink.world", {
            automatic = true, acquired = assignment,
            resource = assignment.resource,
            resourceKey = assignment.resourceKey,
            resourceKind = assignment.resourceKind or "world_water",
            approachCandidates = assignment.approachCandidates,
            taskLeaseId = lease.leaseId, nearby = true,
            abstract = lease.executionMode == "ABSTRACT",
            campActivity = true, campId = assignment.campId,
            campX = assignment.campX,
            campY = assignment.campY,
            campZ = assignment.campZ,
            campRadius = assignment.campRadius,
            resourceRadius = assignment.resourceRadius,
        })
    end,
    CanContinue = function(record)
        local live = liveBody(record)
        return Routes.IsCampContext(record)
            and not Routes.IsCombatActive(record)
            and not Routes.HasPersonalHydration(record)
            and PNC.CampResourceService
            and PNC.CampResourceService.FindWater
            and PNC.CampResourceService.FindWater(record, {
                abstract = live == nil,
            }) ~= nil
    end,
})


return Routes
