if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityJobs = PNC.FacilityJobs or {}
PNC.FacilityJobsServiceInternal = PNC.FacilityJobsServiceInternal or {}

local Jobs = PNC.FacilityJobs
local H = PNC.FacilityJobsServiceInternal
local Repository = PNC.SettlementRepository

function H.HasPersonalFood(record)
    local available
    local fullType
    local itemID
    if not PNC.NPCSupplyService
        or not PNC.NPCSupplyService.HasPersonalSupply
    then
        return false
    end
    available, fullType, itemID = PNC.NPCSupplyService.HasPersonalSupply(
        record, "FOOD", {
            hunger = math.max(0.001, tonumber(record and record.needs
                and record.needs.hunger) or 0.001),
            thirst = 0,
        })
    return available == true, fullType, itemID
end

function H.HasPersonalHydration(record)
    local current = PNC.IndividualNeeds and PNC.IndividualNeeds.Get
        and PNC.IndividualNeeds.Get(record, "thirst")
        or record and record.needs and record.needs.thirst
    local available
    local fullType
    local itemID
    if not PNC.NPCSupplyService
        or not PNC.NPCSupplyService.HasPersonalSupply
    then
        return false
    end
    available, fullType, itemID = PNC.NPCSupplyService.HasPersonalSupply(
        record, "HYDRATION", {
            hunger = 0,
            thirst = math.max(0.001, tonumber(current) or 0.001),
        })
    return available == true, fullType, itemID
end

function H.ManualFoodAssignment(record)
    local x, y, z = H.LivePosition(record)
    return {
        ok = true,
        facilityId = "manual_food:" .. tostring(record.id),
        componentId = "",
        reservationId = "",
        target = { x = x, y = y, z = z },
    }
end

function H.ManualDrinkAssignment(record)
    local x, y, z = H.LivePosition(record)
    return {
        ok = true,
        facilityId = "manual_drink:" .. tostring(record.id),
        componentId = "",
        reservationId = "",
        target = { x = x, y = y, z = z },
    }
end

function H.ManualHomeActivity(record, capability, options)
    local base = H.BaseForRecord(record)
    local acquired
    if not base or not PNC.FacilityService
        or not PNC.FacilityService.AcquireActivity
    then
        return nil, "BASE_NOT_FOUND"
    end
    acquired = PNC.FacilityService.AcquireActivity(
        base.id, record.id, capability,
        { ttlMs = 30000, abstract = options and options.abstract == true })
    if not acquired.ok or not acquired.target then
        return nil, acquired.reason or "NO_ACTIVITY_CAPACITY"
    end
    if capability == "sleep" then
        acquired.sleepVariant = "HOME_BARRACKS"
        acquired.sleepTargetPolicy = "BARRACKS_BED_FIRST"
    end
    return acquired
end

-- Manual sleep follows the same two physical-resource policies as automatic
-- sleep. A camped companion must never be sent through the home resolver: the
-- camp service owns the bounded nearby-bed snapshot and its reservation.
function H.ManualSleepActivity(record, options)
    options = type(options) == "table" and options or {}
    local routes = PNC.NeedFacilityAwayRoutes
    local camped = routes and routes.IsCamped
        and routes.IsCamped(record) == true
    if camped then
        local service = PNC.CampResourceService
        if not service or not service.AcquireSleep then
            return nil, "CAMP_RESOURCES_UNAVAILABLE"
        end
        local acquired, reason = service.AcquireSleep(record, {
            abstract = options.abstract == true,
            allowFloor = options.allowFloor,
        })
        if not acquired or acquired.ok ~= true then
            return nil, reason or acquired and acquired.reason
                or "CAMP_SLEEP_UNAVAILABLE"
        end
        acquired.sleepVariant = "CAMP_NEARBY"
        acquired.sleepTargetPolicy = acquired.resourceKind == "sleep_surface"
            and "CAMP_NEARBY_BED" or "CAMP_FLOOR_FALLBACK"
        return acquired
    end
    return H.ManualHomeActivity(record, "sleep", options)
end

function H.ManualWorldWaterActivity(record)
    local routes = PNC.NeedFacilityAwayRoutes
    local routeId = routes and routes.IsCampContext
        and routes.IsCampContext(record) and "camp_water"
        or "world_hydration"
    local route = routes and routes.Get and routes.Get(routeId) or nil
    local assignment
    if not route or type(route.Assign) ~= "function" then
        return nil, "WORLD_WATER_NOT_FOUND"
    end
    assignment = route.Assign(record, { forceWorld = true })
    if not assignment then
        return nil, "WORLD_WATER_NOT_FOUND"
    end
    return assignment
end

function H.ManualWaterRefillActivity(record)
    local water = PNC.NearbyWaterService
    local routes = PNC.NeedFacilityAwayRoutes
    local route = routes and routes.Get and routes.Get("water_refill") or nil
    local plan
    local planReason
    local assignment
    local reason
    if not water or type(water.ResolveHydrationPlan) ~= "function" then
        return nil, "WATER_REFILL_UNAVAILABLE"
    end
    plan, planReason = water.ResolveHydrationPlan(record, "refill")
    if not plan or plan.action ~= "fill_container" then
        return nil, planReason or "WATER_CONTAINER_NOT_REFILLABLE"
    end
    if not route or type(route.Assign) ~= "function" then
        return nil, "WATER_REFILL_UNAVAILABLE"
    end
    assignment, reason = route.Assign(record)
    if not assignment or assignment.ok ~= true then
        return nil, reason or "WATER_FILL_SOURCE_UNAVAILABLE"
    end
    return assignment
end

-- Compatibility alias for older command/debug callers. It now resolves a
-- valid world source rather than the removed settlement water facility.
H.ManualNearbyWaterActivity = H.ManualWorldWaterActivity

function H.ManualStart(record, capability, commandContext)
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
        manualCommandID = commandContext and commandContext.commandID
            or capability == "survival.fill.water" and "manual_refill"
            or capability == "survival.drink.inventory" and "manual_drink"
            or capability == "survival.eat.inventory" and "manual_eat"
            or capability == "sleep" and "manual_sleep" or nil,
        manualRequestID = commandContext and commandContext.requestID or nil,
        manualCommandSource = commandContext and commandContext.commandSource
            or nil,
    }
    -- Manual item actions have no task lease. An abstract record therefore has
    -- no executor that can advance the delayed transaction or clear the
    -- activity. Reject it before creating a misleading, permanent "Eating"
    -- state; automatic abstract needs use the normal task executor instead.
    if not live and (capability == "survival.eat.inventory"
        or capability == "survival.drink.inventory")
    then
        return false, "NPC_NOT_MATERIALIZED"
    end
    if capability == "survival.eat.inventory" then
        local hasFood
        local foodFullType
        local foodItemID
        hasFood, foodFullType, foodItemID = H.HasPersonalFood(record)
        if not hasFood then
            return false, "PERSONAL_FOOD_MISSING"
        end
        assignment = H.ManualFoodAssignment(record)
        options.acquired = assignment
        options.nearby = true
        options.resourceKind = "personal_food"
        options.activityItemID = foodItemID
        options.activityItemFullType = foodFullType
        facility = {
            id = assignment.facilityId,
            baseId = "nearby",
            definitionId = "manual_food",
        }
    elseif capability == "sleep" then
        local assignmentReason
        assignment, assignmentReason = H.ManualSleepActivity(record, options)
        if not assignment then
            return false, assignmentReason or "NO_SLEEP_ACTIVITY"
        end
        options.acquired = assignment
        options.sleepVariant = assignment.sleepVariant
        options.sleepTargetPolicy = assignment.sleepTargetPolicy
        if assignment.campActivity == true then
            options.nearby = true
            options.campActivity = true
            options.resource = assignment.resource
            options.resourceKey = assignment.resourceKey
            options.resourceKind = assignment.resourceKind
            options.approachCandidates = assignment.approachCandidates
            options.campId = assignment.campId
            options.campX = assignment.campX
            options.campY = assignment.campY
            options.campZ = assignment.campZ
            options.campRadius = assignment.campRadius
            options.resourceRadius = assignment.resourceRadius
            facility = {
                id = assignment.facilityId,
                baseId = "nearby",
                definitionId = "camp",
            }
        else
            facility = assignment.facilityId
        end
    elseif capability == "survival.drink.inventory" then
        local hasDrink, drinkFullType, drinkItemID = H.HasPersonalHydration(record)
        if hasDrink then
            assignment = H.ManualDrinkAssignment(record)
            options.acquired = assignment
            options.nearby = true
            options.resourceKind = "personal_drink"
            options.activityItemID = drinkItemID
            options.activityItemFullType = drinkFullType
            facility = {
                id = assignment.facilityId,
                baseId = "nearby",
                definitionId = "manual_drink",
            }
        else
            assignment = H.ManualWorldWaterActivity(record)
            if not assignment then
                return false, "NO_DRINK_OR_WORLD_WATER"
            end
            options.acquired = assignment
            options.nearby = true
            options.resource = assignment.resource
            options.resourceKey = assignment.resourceKey
            options.resourceKind = "world_water"
            options.approachCandidates = assignment.approachCandidates
            if assignment.campActivity == true then
                options.campActivity = true
                options.campId = assignment.campId
                options.campX = assignment.campX
                options.campY = assignment.campY
                options.campZ = assignment.campZ
                options.campRadius = assignment.campRadius
                options.resourceRadius = assignment.resourceRadius
            end
            facility = {
                id = assignment.facilityId,
                baseId = "nearby",
                definitionId = "world_water",
            }
            capability = "survival.drink.world"
            options.manualToggleable = false
        end
    elseif capability == "survival.fill.water" then
        local assignmentReason
        assignment, assignmentReason = H.ManualWaterRefillActivity(record)
        if not assignment then
            return false, assignmentReason or "NO_WATER_REFILL"
        end
        options.acquired = assignment
        options.nearby = true
        options.abstract = false
        options.resource = assignment.resource
        options.resourceKey = assignment.resourceKey
        options.resourceKind = "water_refill"
        options.activityItemID = assignment.activityItemID
        options.activityItemFullType = assignment.activityItemFullType
        options.approachCandidates = assignment.approachCandidates
        facility = {
            id = assignment.facilityId,
            baseId = "nearby",
            definitionId = "water_refill",
        }
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
