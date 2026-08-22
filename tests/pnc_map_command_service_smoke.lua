local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")

local records = {
    one = { id = "one", alive = true },
    two = { id = "two", alive = true },
}
local starts = {}

PNC = {
    Const = {
        MAP_COMMAND_MAX_SELECTION = 32,
        MAP_COMMAND_COORDINATE_LIMIT = 1000000,
    },
    Core = {
        LogWarn = function() end,
    },
    Registry = {
        Get = function(id) return records[id] end,
    },
    Travel = {
        Service = {
            Start = function(record, request)
                starts[#starts + 1] = {
                    record = record,
                    request = request,
                }
                return {
                    journeyId = "journey:" .. record.id,
                }
            end,
        },
    },
}

T.load(ROOT .. "MapCommands/PNC_MapCommandService.lua")
T.load(ROOT .. "MapCommands/PNC_MapCommand_Travel.lua")

local unauthorized = PNC.MapCommandService.Execute(nil, {
    commandID = "travel",
    npcIds = { "one" },
    target = { x = 100, y = 200, z = 0 },
}, {
    debugAuthorized = false,
})
T.truthy(unauthorized.ok == false
    and unauthorized.reason == "debug_unauthorized",
    "debug travel command bypassed authorization")

local result = PNC.MapCommandService.Execute(nil, {
    requestId = "request:1",
    commandID = "travel",
    npcIds = { "one", "two", "missing" },
    target = { x = 100, y = 200, z = 0 },
    options = {
        speedProfile = "walk",
        arrivalAction = {
            type = "trading",
            marketID = "fixture-market",
        },
    },
}, {
    debugAuthorized = true,
})
T.truthy(result.ok == true and result.accepted == 2 and result.rejected == 1,
    "travel map command did not report per-NPC results")
T.truthy(#starts == 2, "travel map command did not start both journeys")
T.truthy(starts[1].request.destination.x == 100
    and starts[1].request.ownerRef == "debug_map_command",
    "travel map command lost its destination or ownership metadata")
T.truthy(starts[1].request.arrivalAction.type == "trading"
    and starts[1].request.arrivalAction.marketID == "fixture-market",
    "travel map command lost its arrival action")

local invalid = PNC.MapCommandService.Execute(nil, {
    commandID = "travel",
    npcIds = { "one" },
    target = { x = 0 / 0, y = 0 },
}, {
    debugAuthorized = true,
})
T.truthy(invalid.ok == false and invalid.reason == "target_invalid",
    "invalid map coordinate reached a handler")

T.truthy(PNC.MapCommandService.RegisterHandler("scavenge_fixture", {
    execute = function(_, npcIds)
        return { accepted = #npcIds, rejected = 0 }
    end,
}), "future map-command handler could not register")
T.truthy(PNC.MapCommandService.UnregisterHandler("scavenge_fixture"),
    "future map-command handler could not unregister")
T.finish("pnc_map_command_service_smoke")

T.finish("pnc_map_command_service_smoke")
