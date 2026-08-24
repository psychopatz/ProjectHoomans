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

function H.ManualHomeActivity(record, capability)
    local base = H.BaseForRecord(record)
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

function H.ManualNearbyWaterActivity(record)
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

function H.ManualStart(record, capability)
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
        hasFood, foodFullType = H.HasPersonalFood(record)
        if not hasFood then
            return false, "PERSONAL_FOOD_MISSING"
        end
        assignment = H.ManualFoodAssignment(record)
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
        assignment = H.ManualHomeActivity(record, capability)
        if assignment then
            facility = assignment.facilityId
            options.acquired = assignment
        elseif capability == "water.drink" then
            assignment = H.ManualNearbyWaterActivity(record)
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

