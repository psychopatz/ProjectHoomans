local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")
local records = {
    one = { id = "one", alive = true },
}
local created

PNC = {
    Const = {
        MAP_COMMAND_MAX_SELECTION = 32,
        MAP_COMMAND_COORDINATE_LIMIT = 1000000,
        COMPANION_COMMAND_RADIUS = 20,
        LUMBER_DEFAULT_RADIUS = 12,
        LUMBER_MAX_RADIUS = 32,
    },
    Core = {
        LogWarn = function() end,
    },
    Registry = {
        Get = function(id) return records[id] end,
    },
    CompanionCommands = {
        CanPlayerCommand = function() return true end,
    },
    LumberService = {
        CreateZone = function(args)
            created = args
            return { id = "lumber-zone-1" }
        end,
        GetSnapshot = function(id) return { id = id } end,
    },
}

T.load(ROOT .. "MapCommands/PNC_MapCommandService.lua")
T.load(ROOT .. "MapCommands/PNC_MapCommand_Lumber.lua")

local player = {
    getUsername = function() return "map-tester" end,
}
local region = {
    levels = {
        [0] = {
            rows = {
                [10] = { 100, 102 },
                [11] = { 100, 102 },
            },
        },
    },
}

local result = PNC.MapCommandService.Execute(player, {
    commandID = "lumber_zone",
    npcIds = { "one" },
    target = { x = 101, y = 10, z = 0 },
    options = { region = region },
}, {})

T.truthy(result.ok == true and result.accepted == 1
    and result.reason == "lumber_zone_created",
    "lumber region command was rejected")
T.truthy(created and created.region == region
    and created.minX == nil and created.maxX == nil,
    "lumber map command did not forward authoritative region geometry")

local legacy = PNC.MapCommandService.Execute(player, {
    commandID = "lumber_zone",
    npcIds = { "one" },
    target = { x = 100, y = 200, z = 0 },
    options = { radius = 3 },
}, {})

T.truthy(legacy.ok == true and created.minX == 97 and created.maxX == 103
    and created.minY == 197 and created.maxY == 203,
    "legacy lumber radius request lost compatibility")

T.finish("pnc_lumber_map_command_smoke")
