local T = require "tests/support/test"

local SERVER_ROOT = T.path("ProjectHoomans", "server", "")
local stopped = {}
local cancelledLeases = 0
local acquiredCount = 0

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local facilities = {
    ["bed:home"] = {
        id = "bed:home", baseId = "home", definitionId = "barracks",
    },
}

PNC = {
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
    Registry = { GetLiveZombie = function() return nil end },
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
        HasPersonalSupply = function() return true, "Base.Apple" end,
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
T.equal(acquiredCount, 2, "only sleep starts reserve a home activity")
T.truthy(#stopped >= 1, "manual stop path was exercised")

T.finish("pnc_manual_activity_commands_smoke")
