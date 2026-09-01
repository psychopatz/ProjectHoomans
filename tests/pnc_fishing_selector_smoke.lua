local T = require "tests/support/test"

T.addPackagePaths()

getSpecificPlayer = function()
    return { getZ = function() return 0 end }
end

local squares = {}
local function key(x, y, z)
    return tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
end
for x = 0, 2 do
    for y = 0, 0 do
        squares[key(x, y, 0)] = {
            water = x == 2,
            isFree = function() return true end,
        }
    end
end
_G.getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            return squares[key(x, y, z)]
        end,
    }
end

local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local opened
local request
package.preload[
    "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_SelectorSupport"
] = function()
    return {
        Tr = function(_, fallback) return fallback end,
        EmptyRegion = function() return { levels = {} } end,
        ValidateConnected = function(region)
            return GridRegion.countTiles(region) > 0
                and GridRegion.isConnected(region, 4)
        end,
        OpenSelector = function(_, options)
            opened = options
            return options
        end,
        ApplyLocalResult = function() end,
    }
end

PNC = {
    Const = { FISHING_MAX_ZONE_TILES = 10000 },
    Client = {
        SendMapCommand = function(commandID, npcIds, target, options)
            request = {
                commandID = commandID, npcIds = npcIds,
                target = target, options = options,
            }
            return true, { ok = true }
        end,
    },
}

local Actions = require(
    "PNC/UI/Communities/ColonyManagement/SettlementManagement/"
    .. "PNC_SettlementManagement_FishingActions")
local window = {
    selectedPersonID = "npc:1",
    snapshot = { settlement = { geometry = { region = { levels = {} } } } },
}

T.truthy(Actions.Begin(window), "fishing selector did not open")
local validRegion = { levels = { [0] = { rows = { [0] = { 0, 2 } } } } }
local selectorState = {}
local valid, reason = opened.validate(validRegion, {}, selectorState)
T.truthy(valid, reason or "land and water should validate")
T.equal(selectorState.highlightColor.g, 1.00,
    "valid fishing selection is not shown green")
opened.onConfirm(validRegion)
T.equal(request.commandID, "fishing_zone", "wrong fishing command")
T.equal(request.npcIds[1], "npc:1", "selected NPC was not assigned")
T.equal(request.options.region, validRegion,
    "selected region was not submitted")

local invalidRegion = { levels = { [0] = { rows = { [0] = { 0, 1 } } } } }
local invalidState = {}
local invalid = opened.validate(invalidRegion, {}, invalidState)
T.falsy(invalid, "land-only selection should be rejected")
T.equal(invalidState.highlightColor.r, 1.00,
    "invalid fishing selection is not shown red")

T.finish("pnc_fishing_selector_smoke")
