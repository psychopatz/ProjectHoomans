local function equal(actual, expected, message)
    if actual ~= expected then
        error((message or "values differ") .. ": expected="
            .. tostring(expected) .. " actual=" .. tostring(actual), 2)
    end
end

local arrivals = {}
local startedRequest
local released
local abstracted
local reconciled
local broadcast

package.preload["PsychopatzCore/World/PC_ZoneRegistry"] = function()
    return {
        get = function(id)
            if id == "zone-1" then
                return { geometry = { minX = 10, maxX = 20,
                    minY = 10, maxY = 20 } }
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
    Const = { PRESENCE_LIVE = "live", PRESENCE_ABSTRACT = "abstract" },
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
    WorkService = { Commands = { ReleaseWorker = function(id, reason)
        released = id .. ":" .. reason
        return true
    end } },
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

dofile("Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Production/PNC_HomeDutyService.lua")

local npc = {
    id = "npc-1", alive = true, x = 1, y = 2, z = 0,
    presenceState = "abstract", runtime = {},
    affiliation = { communityID = "colony-1" },
}

equal(PNC.HomeDutyService.IsAtHome(npc, "base-1"), false,
    "away colonist not at home")
local sent, reason = PNC.HomeDutyService.SendHome(npc, "base-1", "test")
equal(sent, true, "return-home journey accepted")
equal(reason, "RETURNING_HOME", "return-home state")
equal(startedRequest.destination.x, 15, "journey targets stockpile x")
equal(startedRequest.arrivalAction.type, "colony_home",
    "journey uses durable home arrival")
equal(startedRequest.metadata.purpose, "return_home",
    "journey metadata identifies home travel")
equal(PNC.HomeDutyService.BuildState(npc).state, "RETURNING_HOME",
    "home state exposes travel")

npc.x, npc.y, npc.travel.state = 15, 16, "arrived"
local arrived = arrivals.colony_home(npc, npc.travel,
    startedRequest.arrivalAction)
equal(arrived, true, "arrival handled")
equal(npc.orderSpec.kind, "colony_home", "arrival installs At Home order")
equal(PNC.HomeDutyService.BuildState(npc).state, "AT_HOME",
    "home state after arrival")

npc.x, npc.y = 2, 3
npc.presenceState = "live"
npc.runtime.workOrderId = "work-1"
npc.travel = nil
local recovered, recoverReason, details =
    PNC.HomeDutyService.Recover(npc, "base-1")
equal(recovered, true, "recovery accepted")
equal(recoverReason, "COLONIST_RECOVERED", "recovery reason")
equal(released, "npc-1:colonist_recovered", "work claim released")
equal(abstracted, "colonist_recovery", "live body safely abstracted")
equal(npc.x, 15, "recovered beside stockpile x")
equal(npc.y, 16, "recovered beside stockpile y")
equal(npc.orderSpec.kind, "colony_home", "recovered colonist is At Home")
equal(details.stockpileNodeId, "stockpile-1", "recovery reports stockpile")
equal(reconciled, true, "presence reconciled at destination")
equal(broadcast, "colonist_recovered", "recovery replicated")

print("pnc_home_duty_smoke: ok")
