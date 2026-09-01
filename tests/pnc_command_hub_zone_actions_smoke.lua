local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local player = {
    getUsername = function() return "Tester" end,
}
local region = {
    levels = { [0] = { rows = { [12] = { 12, 14 } } } },
}

local function newWorkService(prefix)
    local service = { Data = { zones = {} } }
    function service.CreateZone(args)
        local zone = {
            id = prefix .. ":one", ownerType = args.ownerType,
            ownerId = args.ownerId, enabled = true,
        }
        service.Data.zones[zone.id] = zone
        service.created = args
        return zone
    end
    function service.GetSnapshot(id) return { id = id } end
    function service.DeleteZone(id, reason)
        service.deleted = { id = id, reason = reason }
        service.Data.zones[id] = nil
        return true, "deleted"
    end
    return service
end

local lumber = newWorkService("lumber")
local fishing = newWorkService("fishing")
local corpseClear

PNC = {
    CompanionCommands = {
        IsOwnedByPlayer = function(record, currentPlayer)
            return record.ownerUsername == currentPlayer:getUsername()
        end,
    },
    Registry = {
        Data = {
            lumberWorker = {
                id = "lumberWorker", alive = true,
                ownerUsername = "Tester",
                allowedJobs = { Lumber = true, Fishing = true },
            },
            optedOut = {
                id = "optedOut", alive = true,
                ownerUsername = "Tester",
                allowedJobs = { Lumber = false, Fishing = false },
            },
        },
    },
    LumberService = lumber,
    FishingService = fishing,
    CorpseHaulService = {
        ClearConfiguration = function(currentPlayer, args)
            corpseClear = { player = currentPlayer, args = args }
            return true, "CORPSE_HAUL_ZONES_CLEARED"
        end,
    },
}

T.load("ProjectHoomans", "server",
    "PNC/Colony/ColonyManagement/PNC_ColonyManagement_ActionTasking.lua")
local handle = PNC.ColonyManagement.Internal.handleTaskingAction

local result = handle(player, { region = region }, "lumber_zone_set")
T.truthy(result and result.ok, "lumber create action failed")
T.equal(lumber.created.ownerId, "Tester", "lumber zone owner was not server-side")
T.equal(lumber.created.npcIds[1], "lumberWorker",
    "authorized lumber worker was not assigned")
T.equal(#lumber.created.npcIds, 1,
    "opted-out colonist was assigned to the lumber zone")

result = handle(player, { region = region }, "lumber_zone_set")
T.falsy(result and result.ok, "duplicate lumber zone was allowed")
T.equal(result.reason, "ZONE_EXISTS", "wrong duplicate lumber reason")

result = handle(player, {}, "lumber_zone_clear")
T.truthy(result and result.ok, "lumber delete action failed")
T.equal(lumber.deleted.id, "lumber:one", "wrong lumber zone was deleted")

result = handle(player, { region = region }, "fishing_zone_set")
T.truthy(result and result.ok, "fishing create action failed")
T.equal(fishing.created.npcIds[1], "lumberWorker",
    "authorized fishing worker was not assigned")
result = handle(player, {}, "fishing_zone_clear")
T.truthy(result and result.ok, "fishing delete action failed")
T.equal(fishing.deleted.id, "fishing:one", "wrong fishing zone was deleted")

result = handle(player, { baseId = "base:one" },
    "corpse_haul_zones_clear")
T.truthy(result and result.ok, "corpse clear action failed")
T.equal(corpseClear.args.baseId, "base:one",
    "corpse clear did not preserve the active base")

T.finish("pnc_command_hub_zone_actions_smoke")
