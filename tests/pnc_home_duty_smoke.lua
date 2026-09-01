local T = require "tests/support/test"

local arrivals = {}
local startedRequest
local released
local abstracted
local reconciled
local broadcast
local provisionOrder
local cancelledProvision

package.preload["PsychopatzCore/World/PC_ZoneRegistry"] = function()
    return {
        get = function(id)
            if id == "zone-1" then
                return { geometry = {
                    levels = { [0] = { rows = {
                        [10] = { 10, 20 }, [15] = { 10, 20 },
                        [20] = { 10, 20 },
                    } } },
                    minX = 10, maxX = 20, minY = 10, maxY = 20,
                } }
            end
        end,
    }
end
package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return {
        containsXY = function(region, x, y)
            return x >= region.minX and x <= region.maxX
                and y >= region.minY and y <= region.maxY
        end,
    }
end

PNC = {
    Const = { PRESENCE_LIVE = "live", PRESENCE_ABSTRACT = "abstract",
        ORDER_FOLLOW = "follow", ORDER_CAMP = "camp" },
    Core = { Now = function() return 1234 end },
    BaseService = {
        Get = function(id)
            return id == "base-1" and {
                id = "base-1", colonyId = "colony-1",
                baseZoneId = "zone-1",
            } or nil
        end,
        GetForColony = function(id)
            return id == "colony-1" and {
                id = "base-1", colonyId = "colony-1",
                baseZoneId = "zone-1",
            } or nil
        end,
    },
    StockpileAccessService = {
        FindNearest = function(baseId)
            if baseId == "base-1" then
                return { id = "stockpile-1", x = 15, y = 16, z = 0,
                    radius = 2 }
            end
        end,
    },
    Travel = {
        Model = { IsActive = function(travel)
            return travel and travel.state == "en_route"
        end },
        Arrivals = { RegisterHandler = function(id, handler)
            arrivals[id] = handler
        end },
        Service = {
            Start = function(record, request)
                startedRequest = request
                local journey = { journeyId = "journey-home", state = "en_route",
                    metadata = request.metadata }
                record.travel = journey
                return journey
            end,
            Cancel = function(record)
                record.travel.state = "cancelled"
                return true
            end,
        },
    },
    OrderSystem = { SetOrder = function(record, order)
        record.orderSpec = order
    end },
    Registry = {
        MarkDirty = function() end,
    },
    WorkService = {
        Queries = {
            Get = function(id)
                return provisionOrder and id == provisionOrder.id
                    and provisionOrder or nil
            end,
        },
        Commands = {
            Cancel = function(id, reason)
                if not provisionOrder or id ~= provisionOrder.id then
                    return false, "WORK_ORDER_UNAVAILABLE"
                end
                cancelledProvision = tostring(id) .. ":" .. tostring(reason)
                return true, provisionOrder
            end,
            ReleaseWorker = function(id, reason)
                released = id .. ":" .. reason
                return true
            end,
        },
    },
    Presence = {
        Abstract = function(record, reason)
            abstracted = reason
            record.presenceState = "abstract"
            return true
        end,
        Reconcile = function() reconciled = true end,
    },
    SpatialIndex = { UpdateNPC = function() end },
    Network = { BroadcastRecord = function(_, reason) broadcast = reason end },
}

T.load(T.path("ProjectHoomans", "server", "PNC/Production/PNC_HomeDutyService.lua"))

local npc = {
    id = "npc-1", alive = true, x = 1, y = 2, z = 0,
    presenceState = "abstract", runtime = {},
    affiliation = { communityID = "colony-1" },
}

local campOnly = {
    id = "npc-camp-only", alive = true, x = 1, y = 2, z = 0,
    runtime = {}, orderSpec = { kind = "camp", x = 1, y = 2, z = 0, radius = 3 },
}
local campState = PNC.HomeDutyService.BuildState(campOnly)
T.equal(campState.state, "AT_CAMP",
    "camp state is visible without requiring a home base")
T.equal(campState.atCamp, true, "camp state exposes its dedicated flag")

T.equal(PNC.HomeDutyService.IsAtHome(npc, "base-1"), false,
    "away colonist not at home")
local sent, reason = PNC.HomeDutyService.SendHome(npc, "base-1", "test")
T.equal(sent, true, "return-home journey accepted")
T.equal(reason, "RETURNING_HOME", "return-home state")
T.equal(startedRequest.destination.x, 15, "journey targets base-zone x")
T.equal(startedRequest.destination.y, 15, "journey targets base-zone y")
T.equal(startedRequest.arrivalAction.type, "colony_home",
    "journey uses durable home arrival")
T.equal(startedRequest.metadata.purpose, "return_home",
    "journey metadata identifies home travel")
T.equal(PNC.HomeDutyService.BuildState(npc).state, "RETURNING_HOME",
    "home state exposes travel")

npc.x, npc.y, npc.travel.state = 15, 15, "arrived"
local arrived = arrivals.colony_home(npc, npc.travel,
    startedRequest.arrivalAction)
T.equal(arrived, true, "arrival handled")
T.equal(npc.orderSpec.kind, "colony_home", "arrival installs At Home order")
T.equal(PNC.HomeDutyService.BuildState(npc).state, "AT_HOME",
    "home state after arrival")
npc.affiliation.communityID = nil
T.equal(PNC.HomeDutyService.BuildState(npc).state, "AT_HOME",
    "remembered home base survives missing legacy affiliation")
T.equal(PNC.HomeDutyService.GetColonyId(npc), "colony-1",
    "remembered home base resolves colony eligibility")

local staleHome = {
    id = "npc-stale-home", alive = true, x = 15, y = 16, z = 0,
    presenceState = "abstract", runtime = {},
    orderSpec = { kind = "colony_home", baseId = "base-1",
        x = 15, y = 9, z = 0, radius = 2 },
    affiliation = { communityID = "colony-1" },
}
local repaired, repairReason = PNC.HomeDutyService.EnsureHomeAnchor(
    staleHome, "base-1", "test_stale_anchor")
T.equal(repaired, true, "stale home anchor is repaired")
T.equal(repairReason, "RETURNING_HOME",
    "stale home anchor uses the durable return journey")
T.equal(startedRequest.destination.x, 15,
    "stale home anchor retargets to base-zone x")
T.equal(startedRequest.destination.y, 15,
    "stale home anchor retargets to base-zone y")

PNC.BehaviorCommon = {
    ClearCombatTarget = function() end,
    HaltMovement = function() end,
}
PNC.BehaviorCompanion = {
    Internal = { TryRespondToThreat = function() return false end },
}
PNC.Animation = {}
PNC.NavigationRouter = {}
PNC.BehaviorRegistry = { Register = function() end }
PNC.JobSystem = { RegisterOrder = function() end }
T.load(T.path("ProjectHoomans", "shared",
    "PNC/Core/Behaviors/PNC_Behavior_AtHome.lua"))
local idleStale = {
    id = "npc-idle-stale", alive = true, x = 15, y = 16, z = 0,
    presenceState = "abstract", runtime = {},
    orderSpec = { kind = "colony_home", baseId = "base-1",
        x = 15, y = 9, z = 0, radius = 2 },
    affiliation = { communityID = "colony-1" },
}
T.equal(PNC.BehaviorAtHome.Tick(idleStale), true,
    "idle behavior handles a stale home anchor")
T.equal(idleStale.activeBehavior, "AtHome:returning",
    "idle behavior hands stale anchor to travel")

npc.x, npc.y = 2, 3
npc.presenceState = "live"
npc.runtime.workOrderId = "work-1"
npc.travel = nil
local recovered, recoverReason, details =
    PNC.HomeDutyService.Recover(npc, "base-1")
T.equal(recovered, true, "recovery accepted")
T.equal(recoverReason, "COLONIST_RECOVERED", "recovery reason")
T.equal(released, "npc-1:colonist_recovered", "work claim released")
T.equal(abstracted, "colonist_recovery", "live body safely abstracted")
T.equal(npc.x, 15, "recovered at base-zone x")
T.equal(npc.y, 15, "recovered at base-zone y")
T.equal(npc.orderSpec.kind, "colony_home", "recovered colonist is At Home")
T.equal(details.stockpileNodeId, "stockpile-1",
    "recovery preserves legacy stockpile metadata")
T.equal(reconciled, true, "presence reconciled at destination")
T.equal(broadcast, "colonist_recovered", "recovery replicated")

local traveler = {
    id = "npc-2", alive = true, x = 15, y = 15, z = 0,
    presenceState = "abstract", runtime = {},
    affiliation = { communityID = "colony-1" },
}
local player = {
    getX = function() return 200 end,
    getY = function() return 300 end,
    getZ = function() return 0 end,
    getUsername = function() return "owner" end,
    getOnlineID = function() return 42 end,
}
local following, followReason = PNC.HomeDutyService.SendToPlayer(
    traveler, player, "test")
T.equal(following, true, "map-scale follow journey accepted")
T.equal(followReason, "TRAVELING_TO_PLAYER", "follow journey state")
T.equal(startedRequest.destination.x, 200, "follow journey targets player x")
T.equal(startedRequest.arrivalAction.type, "colony_follow_player",
    "follow journey uses durable arrival")
local followArrived = arrivals.colony_follow_player(traveler,
    traveler.travel, startedRequest.arrivalAction)
T.equal(followArrived, true, "follow arrival handled")
T.equal(traveler.orderSpec.kind, "follow", "arrival installs follow order")
T.equal(traveler.orderSpec.ownerUsername, "owner", "follow owner is preserved")

local buildingWorker = {
    id = "npc-builder", alive = true, x = 15, y = 15, z = 0,
    presenceState = "abstract", runtime = { workOrderId = "build-1" },
    affiliation = { communityID = "colony-1" },
}
local keptHome, keptReason = PNC.HomeDutyService.SendToPlayer(
    buildingWorker, player, "player_requested")
T.equal(keptHome, false, "building worker must not follow the player")
T.equal(keptReason, "WORK_ORDER_IN_PROGRESS",
    "building worker follow refusal is explicit")
T.equal(buildingWorker.runtime.workOrderId, "build-1",
    "follow refusal preserves the construction claim")

local provisionWorker = {
    id = "npc-provisioner", alive = true, x = 15, y = 15, z = 0,
    presenceState = "abstract", runtime = { workOrderId = "work-provision" },
    affiliation = { communityID = "colony-1" },
}
provisionOrder = { id = "work-provision", operation = "PROVISION_PICKUP" }
local provisionFollowed, provisionFollowReason =
    PNC.HomeDutyService.SendToPlayer(provisionWorker, player, "player_requested")
T.equal(provisionFollowed, true,
    "follow can override an interruptible provision pickup")
T.equal(provisionFollowReason, "TRAVELING_TO_PLAYER",
    "provision follow starts player travel")
T.equal(cancelledProvision, "work-provision:follow_player_requested",
    "follow cancels the provision pickup with an explicit reason")

local courierCompleted
PNC.ColonyStorageService = {
    CompleteNPCCourier = function(record)
        courierCompleted = record.id
        record.runtime.storageCourier.state = "COMPLETED"
        return true, "deposited"
    end,
}
local courier = {
    id = "npc-courier", alive = true, x = 1, y = 2, z = 0,
    presenceState = "abstract",
    runtime = { storageCourier = {
        state = "RETURNING_HOME", baseId = "base-1",
    } },
    affiliation = { communityID = "colony-1" },
}
T.equal(PNC.HomeDutyService.SendHome(courier, "base-1", "storage_courier"),
    true, "courier uses home journey")
courier.x, courier.y, courier.travel.state = 15, 15, "arrived"
T.equal(arrivals.colony_home(courier, courier.travel,
    startedRequest.arrivalAction), true, "courier arrival handled")
T.equal(courierCompleted, "npc-courier",
    "home arrival completes the pending courier job")
T.equal(courier.runtime.storageCourier.state, "COMPLETED",
    "courier completion remains visible")
T.finish("pnc_home_duty_smoke")

T.finish("pnc_home_duty_smoke")
