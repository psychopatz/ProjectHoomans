--[[
    PNC Network Snapshots - Detailed Debug State
    Builds the diagnostic section embedded in a full NPC snapshot.
]]

local Network = PNC.Network
local Parts = Network.Internal.SnapshotParts

local CAMP_RESOURCE_DEBUG_MAX = 8
local SEATING_DEBUG_MAX = 12
local SEATING_SPOT_DEBUG_MAX = 16

local function copyCampPoint(value)
    if type(value) ~= "table" then return nil end
    if value.x == nil and value.y == nil and value.z == nil then
        return nil
    end
    return {
        x = tonumber(value.x),
        y = tonumber(value.y),
        z = tonumber(value.z),
    }
end

local function campResourceCategory(resource)
    local resourceKind = tostring(resource and resource.resourceKind or "")
    local detectorId = tostring(resource and resource.detectorId or "")
    local role = tostring(resource and resource.role or "")
    if resourceKind == "sleep_surface"
        or detectorId == "bed"
        or string.sub(role, 1, 6) == "sleep."
    then
        return "bed"
    end
    if resourceKind == "water_source"
        or resourceKind == "nearby_water"
        or detectorId == "faucet"
        or string.sub(role, 1, 6) == "water."
    then
        return "water"
    end
    if resourceKind == "seating_surface"
        or detectorId == "seat"
        or string.sub(role, 1, 7) == "living."
    then
        return "seating"
    end
    return "other"
end

local function addResourceJob(jobs, seen, value)
    value = tostring(value or "")
    if value ~= "" and not seen[value] then
        seen[value] = true
        jobs[#jobs + 1] = value
    end
end

local function campResourceJobs(resource)
    local jobs = {}
    local seen = {}
    local explicit = resource and (resource.supportedJobs
        or resource.supportedActivities)
    if type(explicit) == "table" then
        for index = 1, #explicit do
            addResourceJob(jobs, seen, explicit[index])
        end
    elseif type(explicit) == "string" then
        addResourceJob(jobs, seen, explicit)
    end

    if #jobs == 0 then
        local category = campResourceCategory(resource)
        if category == "bed" then
            addResourceJob(jobs, seen, "sleep")
        elseif category == "water" then
            addResourceJob(jobs, seen, "drink")
        elseif category == "seating" then
            addResourceJob(jobs, seen, "sit")
        end
    end

    if #jobs == 0 and resource then
        addResourceJob(jobs, seen, resource.capability)
    end
    return jobs
end

local function copyCampResource(resource)
    if type(resource) ~= "table" then return nil end
    local category = campResourceCategory(resource)
    local available = resource.available ~= false
    local blocked = false
    if category == "seating" and type(resource.seatSpots) == "table"
        and #resource.seatSpots > 0
    then
        local usable = false
        local deferred = false
        for index = 1, #resource.seatSpots do
            local spot = resource.seatSpots[index]
            if type(spot) == "table" then
                if spot.validationState == "DEFERRED" then
                    deferred = true
                elseif spot.valid ~= false
                    and spot.approachValid ~= false
                then
                    usable = true
                end
            end
        end
        if not usable and not deferred then
            available = false
            blocked = true
        end
    end
    return {
        resourceKey = tostring(resource.resourceKey or resource.key or ""),
        detectorId = tostring(resource.detectorId or ""),
        resourceKind = tostring(resource.resourceKind or resource.kind or ""),
        role = tostring(resource.role or ""),
        capability = tostring(resource.capability or ""),
        category = category,
        supportedJobs = campResourceJobs(resource),
        x = tonumber(resource.x),
        y = tonumber(resource.y),
        z = tonumber(resource.z),
        originX = tonumber(resource.originX),
        originY = tonumber(resource.originY),
        originZ = tonumber(resource.originZ),
        available = available,
        blocked = blocked,
        selected = resource.selected == true,
    }
end

local function copySeatingResource(resource, character, selectedKey,
    selectedTarget)
    if type(resource) ~= "table" then return nil end
    local output = copyCampResource(resource)
    output.seatCount = tonumber(resource.seatCount) or 1
    output.facilityId = resource.facilityId
    output.selected = tostring(resource.resourceKey or "")
        == tostring(selectedKey or "")
    output.available = output.available
        and not (PNC.FacilityReservations
            and PNC.FacilityReservations.ByResource
            and PNC.FacilityReservations.ByResource[
                tostring(resource.resourceKey or "")
            ] ~= nil
            and not output.selected)
    local spots = resource.seatSpots
    local targets = PNC.FacilityInteractionTargets
        and PNC.FacilityInteractionTargets.ResolveResource
        and PNC.FacilityInteractionTargets.ResolveResource(resource, {
            abstract = character == nil, character = character,
            includeInvalid = true,
        }) or nil
    if type(targets) == "table" and #targets > 0 then spots = targets end
    output.spots = {}
    for index = 1, math.min(SEATING_SPOT_DEBUG_MAX, #(spots or {})) do
        local spot = spots[index]
        if type(spot) == "table" and tonumber(spot.x)
            and tonumber(spot.y) and tonumber(spot.z)
        then
            local selectedSpot = output.selected
                and ((selectedTarget
                    and math.abs(tonumber(spot.x) - tonumber(selectedTarget.x or 0)) < 0.2
                    and math.abs(tonumber(spot.y) - tonumber(selectedTarget.y or 0)) < 0.2
                    and math.abs(tonumber(spot.z) - tonumber(selectedTarget.z or 0)) < 0.2)
                    or (selectedTarget == nil and index == 1))
                or false
            output.spots[#output.spots + 1] = {
                x = tonumber(spot.x), y = tonumber(spot.y),
                z = tonumber(spot.z),
                seatAnchorX = tonumber(spot.seatAnchorX or spot.x),
                seatAnchorY = tonumber(spot.seatAnchorY or spot.y),
                seatAnchorZ = tonumber(spot.seatAnchorZ or spot.z),
                direction = spot.direction or spot.seatDirection,
                side = spot.side or spot.seatSide,
                approachKey = spot.approachKey,
                validationState = spot.validationState,
                rejectionReason = spot.rejectionReason,
                routeStatus = spot.routeStatus,
                source = (spot.valid == false or spot.validSpot == false
                    or spot.approachValid == false)
                    and "invalid" or "engine",
                valid = spot.valid ~= false
                    and spot.validSpot ~= false
                    and spot.approachValid ~= false,
                selected = selectedSpot,
            }
        end
    end
    return output
end

function Parts.BuildSeatingDebugState(record)
    local order = record and record.orderSpec or nil
    local runtime = record and record.runtime or nil
    local activity = runtime and runtime.facilityActivity or nil
    local orderKind = tostring(order and order.kind or "")
    local previousOrder = activity and activity.previousOrder or nil
    local camped = orderKind == tostring(PNC.Const and PNC.Const.ORDER_CAMP
        or "camp") or activity and activity.campActivity == true
    local atHome = orderKind == "colony_home"
        or tostring(previousOrder and previousOrder.kind or "")
            == "colony_home"
    local selectedKey = activity and activity.seating == true
        and activity.resourceKey or nil
    local selectedTarget = activity and activity.seating == true
        and activity.target or nil
    local character = record and PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    local facilities = {}
    local sourceCount = 0
    local bodyPosition
    local seatAnchor
    local seatDistance

    if character and character.getX and character.getY and character.getZ then
        local bodyOk, bodyX, bodyY, bodyZ = pcall(function()
            return character:getX(), character:getY(), character:getZ()
        end)
        if bodyOk then
            bodyPosition = { x = tonumber(bodyX), y = tonumber(bodyY),
                z = tonumber(bodyZ) }
        end
    end
    if activity and activity.seating == true then
        seatAnchor = copyCampPoint(activity.seatAnchor or activity.target)
        if bodyPosition and seatAnchor then
            seatDistance = PNC.Core.Distance(
                bodyPosition.x, bodyPosition.y,
                seatAnchor.x, seatAnchor.y)
        end
    end

    local function add(resource, facilityId)
        if type(resource) ~= "table"
            or tostring(resource.resourceKind or "")
                ~= "seating_surface"
        then return end
        sourceCount = sourceCount + 1
        if #facilities >= SEATING_DEBUG_MAX then return end
        local copied = copySeatingResource(
            resource, character, selectedKey, selectedTarget)
        if copied then
            copied.facilityId = facilityId or copied.facilityId
            facilities[#facilities + 1] = copied
        end
    end

    if camped then
        local state = record and record.campState or nil
        for index = 1, #(state and state.resources or {}) do
            add(state.resources[index], tostring(
                state and state.campId or activity and activity.campId or ""))
        end
    elseif atHome and PNC.HomeDutyService
        and PNC.HomeDutyService.GetBase and PNC.FacilityService
        and PNC.FacilityService.ListByCapability
    then
        local base = PNC.HomeDutyService.GetBase(record)
        local homes = base and PNC.FacilityService.ListByCapability(
            base.id, "living") or {}
        for facilityIndex = 1, #homes do
            local facility = homes[facilityIndex]
            local resources = PNC.FacilityResources
                and PNC.FacilityResources.GetResources
                and PNC.FacilityResources.GetResources(facility, "seat") or {}
            for resourceIndex = 1, #resources do
                add(resources[resourceIndex], facility.id)
            end
        end
    end

    if activity and activity.seating == true and activity.resource
        and sourceCount == 0
    then
        add(activity.resource, activity.facilityId)
    end
    if sourceCount == 0 and not camped and not atHome then return nil end
    return {
        active = activity and activity.seating == true or false,
        mode = camped and "camp" or atHome and "home" or "none",
        facilityCount = #facilities,
        foundCount = sourceCount,
        selectedResourceKey = selectedKey,
        phase = activity and activity.seating == true
            and tostring(activity.phase or "") or "IDLE",
        target = activity and activity.seating == true
            and copyCampPoint(activity.target) or nil,
        anchor = seatAnchor,
        body = bodyPosition,
        distance = seatDistance,
        seatState = activity and activity.seating == true
            and tostring(activity.seatState or activity.phase or "") or nil,
        seatDirection = activity and activity.seating == true
            and tostring(activity.seatDirection or "") or nil,
        seatSide = activity and activity.seating == true
            and tostring(activity.seatSide or "") or nil,
        approachKey = activity and activity.seating == true
            and tostring(activity.approachKey or "") or nil,
        stopDistance = activity and activity.seating == true
            and tonumber(activity.seatStopDistance) or nil,
        arrivalDistance = activity and activity.seating == true
            and tonumber(activity.seatArrivalDistance) or nil,
        facilities = facilities,
        facilitiesTruncated = sourceCount > #facilities,
    }
end

-- Compact, primitive-only camp diagnostics shared by detailed and presence
-- snapshots. The full campState remains server persistence; nameplates only
-- receive bounded information needed to explain what the NPC found.
function Parts.BuildCampResourceDebugState(record)
    local order = record and record.orderSpec or nil
    local runtime = record and record.runtime or nil
    local activity = runtime and runtime.facilityActivity or nil
    local state = record and record.campState or nil
    local orderIsCamp = tostring(order and order.kind or "") == "camp"
    local activityIsCamp = activity and activity.campActivity == true or false
    local resources = state and state.resources or {}
    local campId
    local anchorX
    local anchorY
    local anchorZ
    local campRadius
    local resourceRadius
    local facilities = {}
    local activeResource
    local bedCount = 0
    local waterCount = 0
    local seatingCount = 0
    local otherCount = 0

    if type(resources) ~= "table" then resources = {} end
    if not orderIsCamp and not activityIsCamp and type(state) ~= "table" then
        return nil
    end

    campId = tostring(state and state.campId
        or activity and activity.campId
        or order and order.campId
        or "")
    anchorX = tonumber(state and state.anchorX
        or activity and activity.campX
        or order and order.x
        or record and record.x or 0)
    anchorY = tonumber(state and state.anchorY
        or activity and activity.campY
        or order and order.y
        or record and record.y or 0)
    anchorZ = tonumber(state and state.anchorZ
        or activity and activity.campZ
        or order and order.z
        or record and record.z or 0)
    campRadius = tonumber(state and state.campRadius
        or activity and activity.campRadius
        or order and order.radius or 3)
    resourceRadius = tonumber(state and state.resourceRadius
        or activity and activity.resourceRadius
        or order and order.resourceRadius or 12)

    for index = 1, #resources do
        local resource = resources[index]
        local category = campResourceCategory(resource)
        if category == "bed" then
            bedCount = bedCount + 1
        elseif category == "water" then
            waterCount = waterCount + 1
        elseif category == "seating" then
            seatingCount = seatingCount + 1
        else
            otherCount = otherCount + 1
        end
        if #facilities < CAMP_RESOURCE_DEBUG_MAX then
            local copied = copyCampResource(resource)
            if copied then
                local resourceKey = tostring(resource.resourceKey
                    or resource.key or "")
                local selected = activity
                    and tostring(activity.resourceKey or "") ~= ""
                    and tostring(activity.resourceKey) == resourceKey
                local reserved = PNC.FacilityReservations
                    and PNC.FacilityReservations.ByResource
                    and PNC.FacilityReservations.ByResource[resourceKey]
                    ~= nil
                copied.selected = selected == true
                copied.available = copied.available
                    and (not reserved or copied.selected)
                facilities[#facilities + 1] = copied
            end
        end
        if activity and tostring(activity.resourceKey or "") ~= ""
            and tostring(activity.resourceKey or "")
                == tostring(resource and (resource.resourceKey or resource.key) or "")
        then
            activeResource = copyCampResource(resource)
        end
    end

    return {
        active = orderIsCamp or activityIsCamp,
        mode = activityIsCamp and "activity" or "camp",
        campId = campId,
        anchor = { x = anchorX, y = anchorY, z = anchorZ },
        campRadius = campRadius,
        resourceRadius = resourceRadius,
        capturedAtWorldHour = tonumber(state and state.capturedAtWorldHour),
        resourceCount = #resources,
        bedCount = bedCount,
        waterCount = waterCount,
        seatingCount = seatingCount,
        otherCount = otherCount,
        facilities = facilities,
        facilitiesTruncated = #resources > #facilities,
            activeResource = activeResource,
            activity = activityIsCamp and {
            capability = tostring(activity.capability or ""),
            phase = tostring(activity.phase or ""),
            resourceKind = tostring(activity.resourceKind or ""),
            resourceKey = tostring(activity.resourceKey or ""),
            sleepSurface = tostring(activity.sleepSurface or ""),
            abstract = activity.abstract == true,
                target = copyCampPoint(activity.target),
            } or nil,
    }
end

function Parts.BuildDetailedDebugState(
    record,
    combat,
    firearmState,
    staminaInfo,
    canRevive,
    aiState,
    vehiclePassenger
)
    local pathing = record.runtime and record.runtime.pathing or nil
    local navigation = record.runtime
        and record.runtime.localNavigation or nil
    local navigationRouter = record.runtime
        and record.runtime.navigationRouter or nil
    return {
            aiState = aiState,
            activeJob = record.activeJob,
            activeBehavior = record.activeBehavior,
            lumberRuntime = record.runtime and record.runtime.lumber
                and PNC.Core.DeepCopy(record.runtime.lumber) or nil,
            orderKind = record.orderSpec and record.orderSpec.kind or nil,
            attackType = record.attackType or "auto",
            targetKind = combat.targetKind,
            healthState = record.health and record.health.state or nil,
            canRevive = canRevive,
            weaponMode = record.weaponMode,
            combatModeResolved = combat.combatModeResolved,
            weaponStatus = combat.weaponStatus,
            magazineCount = firearmState and firearmState.count or nil,
            magazineCapacity = firearmState and firearmState.capacity or nil,
            ammoReserveUnlimited = firearmState and firearmState.unlimitedReserve == true or false,
            ammoReserveCount = firearmState and firearmState.reserveCount or nil,
            firearmReloadActive = firearmState and firearmState.reloadActive == true or false,
            vehiclePassenger = vehiclePassenger and vehiclePassenger.active == true or false,
            vehicleId = vehiclePassenger and vehiclePassenger.vehicleId or nil,
            vehicleSeat = vehiclePassenger and vehiclePassenger.seat or nil,
            vehicleBlockReason = record.runtime and record.runtime.vehicleBlockReason or nil,
            combatBlockReason = combat.combatBlockReason,
            tacticalDecision = combat.tacticalDecision,
            pressureCount = combat.pressureCount,
            visiblePressureCount = combat.visiblePressureCount,
            hordeCount = combat.hordeCount,
            visibleHordeCount = combat.visibleHordeCount,
            pressureTolerance = combat.pressureTolerance,
            aimConfidence = combat.aimConfidence,
            aimReadyAt = combat.aimReadyAt,
            fireLaneSafe = combat.fireLaneSafe,
            fireLaneBlockerKind = combat.fireLaneBlockerKind,
            staminaState = staminaInfo.state,
            staminaCurrent = staminaInfo.current,
            staminaMax = staminaInfo.max,
            staminaBaseMax = staminaInfo.baseMax,
            encumbranceLevel = staminaInfo.encumbranceLevel,
            encumbranceRatio = staminaInfo.encumbranceRatio,
            stealthActive = record.runtime and record.runtime.stealthActive == true or false,
            debugEnabled = record.runtime and record.runtime.debug == true or false,
            presenceState = record.presenceState,
            campResourceDebug = Parts.BuildCampResourceDebugState(record),
            seatingDebug = Parts.BuildSeatingDebugState(record),
            movePhase = pathing and pathing.phase or "idle",
            moveMode = pathing
                and (pathing.resolvedMode or pathing.mode) or nil,
            moveGoal = pathing and pathing.goal or nil,
            moveFinalGoal = pathing
                and pathing.finalGoalX ~= nil and {
                    x = pathing.finalGoalX,
                    y = pathing.finalGoalY,
                    z = pathing.finalGoalZ,
                } or nil,
            moveCancelReason = pathing and pathing.cancelReason or nil,
            moveBlockReason = pathing and pathing.blockReason or nil,
            moveIntentReason = pathing and pathing.intentReason or nil,
            moveOwnerMode = pathing and pathing.ownerMode or nil,
            moveLastStep = pathing and pathing.lastStepLabel or nil,
            moveLastStepDistance = pathing
                and pathing.lastStepDistance or nil,
            moveLastProgressDelta = pathing
                and pathing.lastProgressDelta or nil,
            moveGoalDistance = pathing and pathing.goalDistance or nil,
            moveBestGoalDistance = pathing
                and pathing.bestGoalDistance or nil,
            moveNonProgressSteps = pathing
                and pathing.nonProgressStepCount or 0,
            moveBlockedStepReason = pathing
                and pathing.blockedStepReason or nil,
            navigationPolicy = pathing
                and pathing.navigationPolicy
                or navigationRouter and navigationRouter.policy
                or nil,
            navigationProvider = pathing
                and pathing.navigationProvider
                or navigationRouter and navigationRouter.provider
                or nil,
            navigationPlanReason = navigation
                and navigation.lastPlanReason or nil,
            navigationSteeringKind = navigation
                and navigation.steeringKind or nil,
            navigationTraversalKind = navigation
                and navigation.currentTraversalKind or nil,
            navigationPathIndex = navigation
                and navigation.index or nil,
            navigationPathLength = navigation
                and navigation.path and #navigation.path or 0,
            navigationPlanFailures = navigation
                and navigation.planFailures or 0,
            navigationInvalidations = navigationRouter
                and navigationRouter.invalidations or 0,
            navigationInvalidationReason = navigationRouter
                and navigationRouter.lastInvalidationReason or nil,
    }
end

return Parts
