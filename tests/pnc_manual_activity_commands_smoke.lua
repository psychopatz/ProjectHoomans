local T = require "tests/support/test"

local SERVER_ROOT = T.path("ProjectHoomans", "server", "")
local stopped = {}
local cancelledLeases = 0
local acquiredCount = 0
local releasedAssignments = 0

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local facilities = {
    ["bed:home"] = {
        id = "bed:home", baseId = "home", definitionId = "barracks",
    },
}

PNC = {
    Const = {
        MODULE = "PNC",
        CMD_COMPANION_COMMAND_RESULT = "CompanionCommandResult",
    },
    Core = {
        Now = function() return 1000 end,
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, item in pairs(value) do output[key] = item end
            return output
        end,
    },
    FacilityJobs = {},
    SettlementRepository = {
        State = { bases = {
            home = { id = "home", factionId = "faction" },
        } },
        GetFacility = function(id) return facilities[tostring(id)] end,
    },
    FacilityJobDefinitions = {
        Get = function(capability)
            return {
                sceneId = capability == "sleep"
                    and "facility.sleep.floor" or "survival.eat.inventory",
                arrivalDistance = 0.85,
                activityLabel = capability == "sleep" and "SLEEPING" or "EATING",
                activeJob = capability == "sleep" and "Sleep" or "Eat",
                activityText = capability == "sleep" and "Sleeping" or "Eating",
            }
        end,
    },
    FacilityDefinitions = {
        Get = function() return { displayNameKey = "Barracks" } end,
        GetLevel = function() return { capabilities = { "sleep" } } end,
    },
    BaseService = { Get = function(id)
        return tostring(id) == "home" and { id = "home" } or nil
    end },
    Registry = { GetLiveZombie = function(target)
        local targetID = type(target) == "table" and target.id or target
        if targetID == "npc_manual" or targetID == "npc:manual-drink"
        then
            return {
                getX = function() return 10 end,
                getY = function() return 12 end,
                getZ = function() return 0 end,
            }
        end
        return nil
    end },
    FacilityService = {
        AcquireActivity = function(baseId, npcId, capability)
            acquiredCount = acquiredCount + 1
            return {
                ok = true,
                facilityId = "bed:home",
                componentId = "bed:1",
                reservationId = "reservation:1",
                role = "sleep.bed",
                target = { x = 10, y = 12, z = 0,
                    sceneId = "facility.sleep.floor" },
            }
        end,
    },
    NPCSupplyService = {
        HasPersonalSupply = function(_, kind)
            if kind == "FOOD" then
                return true, "Base.Apple", "food:1"
            end
            return true, "Base.Apple", "drink:1"
        end,
    },
    OrderSystem = {
        SetOrder = function(record, order) record.orderSpec = order end,
    },
    AnimationScenes = {},
    FacilityReservations = {
        Release = function() return true end,
    },
    Tasking = {
        Commands = {
            CancelForNPC = function(recordID, reason)
                cancelledLeases = cancelledLeases + 1
                return true
            end,
        },
    },
}

local record = {
    id = "npc_manual",
    alive = true,
    affiliation = { factionID = "faction" },
    x = 10, y = 12, z = 0,
    orderSpec = { kind = "follow", ownerUsername = "alice" },
    runtime = {},
    needs = { hunger = 0.8 },
}

local originalStop = function(target, reason)
    stopped[#stopped + 1] = reason
    local activity = target.runtime.facilityActivity
    target.runtime.facilityActivity = nil
    target.runtime.facilityDebugWork = nil
    target.orderSpec = activity and activity.previousOrder or nil
    return true, "facility_activity_stopped"
end
PNC.FacilityJobs.Stop = originalStop
T["load"](SERVER_ROOT .. "PNC/Settlement/FacilityJobs/PNC_FacilityJobs_Service.lua")

local started, reason = PNC.FacilityJobs.ToggleManual(record, "sleep")
T.equal(started, true, "manual sleep starts through facility service")
T.equal(reason, "facility_activity_started", "manual sleep start reason")
T.equal(record.runtime.facilityActivity.capability, "sleep",
    "sleep capability is authoritative")
T.equal(record.runtime.facilityActivity.manual, true,
    "manual ownership is recorded")
T.equal(record.orderSpec.kind, "facility_activity",
    "manual sleep owns the order")

local stoppedSleep, stopReason = PNC.FacilityJobs.ToggleManual(record, "sleep")
T.equal(stoppedSleep, true, "sleep toggles off")
T.equal(stopReason, "facility_activity_stopped", "sleep stop reason")
T.equal(record.runtime.facilityActivity, nil,
    "sleep toggle clears facility activity")
T.equal(record.runtime.manualActivityDisabled, "sleep",
    "sleep toggle suppresses automatic re-entry")
T.equal(record.orderSpec.kind, "follow",
    "sleep toggle restores the previous order")

local restarted = PNC.FacilityJobs.ToggleManual(record, "sleep")
T.equal(restarted, true, "sleep can be enabled again")
T.equal(record.runtime.manualActivityDisabled, nil,
    "explicit sleep enable clears suppression")

record.runtime.facilityActivity.taskLeaseId = "lease:automatic"
local replaced = PNC.FacilityJobs.ToggleManual(record, "survival.eat.inventory")
T.equal(replaced, true, "manual eat replaces an existing task activity")
T.equal(cancelledLeases, 1,
    "replacing task-owned activity cancels its lease first")
T.equal(record.runtime.facilityActivity.capability,
    "survival.eat.inventory", "manual eat capability is authoritative")
T.equal(record.runtime.facilityActivity.manual, true,
    "manual eat ownership is recorded")
T.equal(record.runtime.facilityActivity.activityItemFullType,
    "Base.Apple", "manual eating preserves the selected item type")
T.equal(record.runtime.facilityActivity.activityItemID, "food:1",
    "manual eating preserves the exact selected item ID")
T.equal(acquiredCount, 2, "only sleep starts reserve a home activity")
T.truthy(#stopped >= 1, "manual stop path was exercised")

local actualStart = PNC.FacilityJobs.Start
local drinkCapability
local drinkOptions
PNC.FacilityJobs.Start = function(_, _, capability, options)
    drinkCapability, drinkOptions = capability, options
    return true, "started"
end
local drinkRecord = {
    id = "npc:manual-drink", alive = true, x = 10, y = 12, z = 0,
    orderSpec = { kind = "follow" }, runtime = {},
    needs = { thirst = 0.80 },
}
local drinkStarted, drinkReason = PNC.FacilityJobs.ToggleManual(
    drinkRecord, "survival.drink.inventory")
T.equal(drinkStarted, true, "manual drink starts from personal hydration")
T.equal(drinkReason, "started", "manual drink returns the executor result")
T.equal(drinkCapability, "survival.drink.inventory",
    "manual drink uses the personal-item capability")
T.equal(drinkOptions.activityItemFullType, "Base.Apple",
    "manual drink passes the selected carried item")
T.equal(drinkOptions.activityItemID, "drink:1",
    "manual drink passes the exact selected carried item ID")
PNC.FacilityJobs.Start = actualStart

local abstractRecord = {
    id = "npc:abstract-manual", alive = true, x = 10, y = 12, z = 0,
    orderSpec = { kind = "follow" }, runtime = {},
    needs = { hunger = 0.80 },
}
local abstractStarted, abstractReason = PNC.FacilityJobs.ToggleManual(
    abstractRecord, "survival.eat.inventory")
T.falsy(abstractStarted, "abstract manual eating is rejected cleanly")
T.equal(abstractReason, "NPC_NOT_MATERIALIZED",
    "abstract manual eating reports why it cannot run")
T.falsy(abstractRecord.runtime.facilityActivity,
    "abstract manual rejection does not leave a stuck activity")

-- Manual refill must use the same planner and away route as automatic water
-- refilling, while preserving the selected source and container metadata.
local refillSource = { key = "sink:manual", object = {} }
local refillAssignment = {
    ok = true, facilityId = "water_refill:sink:manual",
    resource = refillSource, resourceKey = refillSource.key,
    activityItemID = "water-container:1",
    activityItemFullType = "Base.WaterBottle",
    approachCandidates = { { x = 11, y = 12, z = 0 } },
}
PNC.NearbyWaterService = {
    ResolveHydrationPlan = function(_, mode)
        T.equal(mode, "refill",
            "manual refill did not request the dedicated refill plan")
        return { action = "fill_container" }
    end,
}
PNC.NeedFacilityAwayRoutes = {
    Get = function(sourceRef)
        T.equal(sourceRef, "water_refill",
            "manual refill selected the wrong shared route")
        return {
            Assign = function()
                return refillAssignment
            end,
        }
    end,
}
local refillRecord = {
    id = "npc:manual-refill", alive = true, x = 10, y = 12, z = 0,
    orderSpec = { kind = "follow" }, runtime = {}, needs = { thirst = 0.8 },
}
local refillCapability
local refillOptions
PNC.FacilityJobs.Start = function(_, _, capability, options)
    refillCapability, refillOptions = capability, options
    return true, "started"
end
local refillStarted, refillReason = PNC.FacilityJobs.ToggleManual(
    refillRecord, "survival.fill.water")
T.equal(refillStarted, true, "manual water refill starts")
T.equal(refillReason, "started", "manual water refill returns executor result")
T.equal(refillCapability, "survival.fill.water",
    "manual refill uses the refill capability")
T.equal(refillOptions.resource, refillSource,
    "manual refill does not preserve the shared water source")
T.equal(refillOptions.resourceKey, "sink:manual",
    "manual refill does not preserve the source key")
T.equal(refillOptions.activityItemID, "water-container:1",
    "manual refill does not preserve the selected container")
PNC.FacilityJobs.Start = actualStart

-- A manual refill rejection must stop at the planner and preserve its exact
-- reason for the command/network response layer.
local originalHydrationPlanner = PNC.NearbyWaterService.ResolveHydrationPlan
PNC.NearbyWaterService.ResolveHydrationPlan = function(_, mode)
    T.equal(mode, "refill",
        "manual refill failure did not use the dedicated refill plan")
    return nil, "WATER_CONTAINER_FULL"
end
local rejectedRefill, rejectedRefillReason = PNC.FacilityJobs.ToggleManual({
    id = "npc:manual-refill-full", alive = true, x = 10, y = 12, z = 0,
    orderSpec = { kind = "follow" }, runtime = {}, needs = { thirst = 0.8 },
}, "survival.fill.water")
PNC.NearbyWaterService.ResolveHydrationPlan = originalHydrationPlanner
T.falsy(rejectedRefill, "manual refill forwards a planner rejection")
T.equal(rejectedRefillReason, "WATER_CONTAINER_FULL",
    "manual refill preserves the precise planner rejection reason")

-- Manual sleep is allowed to preempt durable work, but the work claim must be
-- released through the canonical WorkService boundary before sleep starts.
local workRecord
PNC.WorkService = {
    Commands = {
        ReleaseAssignment = function(targetID)
            releasedAssignments = releasedAssignments + 1
            T.equal(targetID, "npc:manual-work",
                "sleep releases the correct durable worker")
            workRecord.runtime.workOrderId = nil
            return true, "released"
        end,
    },
}
workRecord = {
    id = "npc:manual-work", alive = true,
    affiliation = { factionID = "faction" },
    x = 10, y = 12, z = 0,
    orderSpec = { kind = "follow" }, runtime = { workOrderId = "work:1" },
    needs = { fatigue = 0.01 },
}
local forced, forcedReason = PNC.FacilityJobs.ToggleManual(
    workRecord, "sleep")
T.equal(forced, true, "manual sleep overrides ordinary work")
T.equal(forcedReason, "facility_activity_started",
    "work override returns the sleep start result")
T.equal(releasedAssignments, 1,
    "manual sleep releases the durable work assignment")
T.equal(workRecord.runtime.facilityActivity.sleepCompletionPolicy,
    "MANUAL_TOGGLE", "manual sleep uses toggle completion")
PNC.FacilityJobs.Stop(workRecord, "test_cleanup")

-- A camped companion uses the nearby resource service rather than the home
-- facility resolver, even when sleep is manually requested.
PNC.NeedFacilityAwayRoutes = {
    IsCamped = function(target)
        return target.orderSpec and target.orderSpec.kind == "camp"
    end,
}
PNC.CampResourceService = {
    AcquireSleep = function(target)
        return {
            ok = true, facilityId = "camp:manual", campId = "camp:manual",
            campActivity = true, campX = target.x, campY = target.y,
            campZ = target.z, campRadius = 3, resourceRadius = 12,
            reservationId = "reservation:camp", resourceKey = "bed:camp",
            resourceKind = "sleep_surface", resource = { resourceKey = "bed:camp" },
            target = { x = target.x, y = target.y, z = target.z,
                sceneId = "facility.sleep.bed", sleepSurface = "bed" },
        }
    end,
}
local campRecord = {
    id = "npc:manual-camp", alive = true, x = 20, y = 20, z = 0,
    orderSpec = { kind = "camp", campId = "camp:manual" }, runtime = {},
    needs = { fatigue = 0.01 },
}
local campStarted, campReason = PNC.FacilityJobs.ToggleManual(
    campRecord, "sleep")
T.equal(campStarted, true, "manual camp sleep starts")
T.equal(campReason, "facility_activity_started",
    "camp sleep returns the shared facility start result")
T.equal(campRecord.runtime.facilityActivity.sleepVariant, "CAMP_NEARBY",
    "camp sleep records the nearby variant")
T.equal(campRecord.runtime.facilityActivity.sleepTargetPolicy,
    "CAMP_NEARBY_BED", "camp sleep records the nearby-bed policy")
PNC.FacilityJobs.Stop(campRecord, "test_cleanup")

-- Manual sleep must remain toggle-owned even when fatigue is already below
-- the automatic completion threshold, so future sleep healing can continue.
local restOptions
PNC.IndividualNeeds = {
    Commands = {
        ApplyRest = function(_, _, _, options)
            restOptions = options
            return true, "REST_COMPLETE", 0.05
        end,
    },
}
local Effects = T.load("ProjectHoomans", "server",
    "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityEffects.lua")
local manualResultPayload
triggerEvent = function(eventName, moduleName, commandName, payload)
    if eventName == "OnServerCommand"
        and moduleName == PNC.Const.MODULE
        and commandName == PNC.Const.CMD_COMPANION_COMMAND_RESULT
    then
        manualResultPayload = payload
    end
end
local manualResultState = {
    manual = true,
    manualCommandID = "manual_refill",
    manualRequestID = "activity-request-1",
    manualCommandSource = "colonist_activities",
}
local manualResultRecord = { id = "npc:manual-refill-full" }
T.truthy(Effects.ReportWaterRefillResult(manualResultRecord,
    manualResultState, false, "WATER_CONTAINER_FULL", {
        stage = "transaction", itemID = "water-container:1",
    }), "manual refill emits its delayed transaction result")
T.equal(manualResultPayload.commandID, "manual_refill",
    "manual refill result preserves its command ID")
T.falsy(manualResultPayload.accepted,
    "manual refill result marks the full-container transaction rejected")
T.equal(manualResultPayload.reason, "WATER_CONTAINER_FULL",
    "manual refill result preserves the precise transaction reason")
T.equal(manualResultPayload.requestID, "activity-request-1",
    "manual refill result preserves the Activities request correlation")
T.equal(manualResultPayload.details.itemID, "water-container:1",
    "manual refill result preserves the selected container diagnostic")
T.falsy(Effects.ReportWaterRefillResult(manualResultRecord,
    manualResultState, false, "WATER_CONTAINER_FULL"),
    "manual refill emits its final result only once")
local lowFatigueRecord = {
    runtime = { facilityActivity = {
        capability = "sleep", manual = true, manualToggleable = true,
    }},
}
local applied, complete = Effects.Tick(lowFatigueRecord,
    lowFatigueRecord.runtime.facilityActivity, {
        needEffect = "need", needType = "fatigue",
        recoveryPerGameHour = 0.45, completionThreshold = 0.12,
    }, 0.10, 1000)
T.truthy(applied, "manual low-fatigue sleep applies its effect")
T.falsy(complete, "manual low-fatigue sleep does not auto-complete")
T.truthy(restOptions and restOptions.ignoreCompletion == true,
    "manual sleep passes the toggle completion policy")

T.finish("pnc_manual_activity_commands_smoke")
