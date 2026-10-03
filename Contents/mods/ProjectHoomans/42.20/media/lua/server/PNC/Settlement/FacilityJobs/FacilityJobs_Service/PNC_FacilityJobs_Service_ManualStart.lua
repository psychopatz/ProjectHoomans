if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityJobs = PNC.FacilityJobs or {}
PNC.FacilityJobsServiceInternal = PNC.FacilityJobsServiceInternal or {}

local Jobs = PNC.FacilityJobs
local H = PNC.FacilityJobsServiceInternal

-- Manual activity orchestration is kept separate from the reusable
-- assignment and resource-resolution helpers.

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
            assignment = H.ManualWorldWaterActivity(record, {
                manualOverride = true,
            })
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
            options.manualOverride = true
        end
    elseif capability == "survival.fill.water" then
        local assignmentReason
        assignment, assignmentReason = H.ManualWaterRefillActivity(record, {
            manualOverride = true,
        })
        if not assignment then
            return false, assignmentReason or "NO_WATER_REFILL"
        end
        options.acquired = assignment
        options.nearby = true
        options.abstract = false
        options.resource = assignment.resource
        options.resourceKey = assignment.resourceKey
        options.resourceKind = "water_refill"
        options.manualOverride = true
        options.waterContextKind = assignment.waterContextKind
        options.waterBaseId = assignment.waterBaseId
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

return H
