local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "client" },
})

local opened = {}
local Selector = {
    Open = function(options)
        opened[#opened + 1] = options
        return options
    end,
}
package.preload["PsychopatzCore/UI/World/PsychopatzGridRegionSelector"] =
    function() return Selector end
package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    local function containsPoint(region, x, y, z)
        local level = region and region.levels and region.levels[z]
        local spans = level and level.rows and level.rows[y]
        for index = 1, #(spans or {}), 2 do
            if x >= spans[index] and x <= spans[index + 1] then
                return true
            end
        end
        return false
    end
    local function intersects(left, right)
        for z, level in pairs(left and left.levels or {}) do
            for y, spans in pairs(level.rows or {}) do
                for index = 1, #spans, 2 do
                    for x = spans[index], spans[index + 1] do
                        if containsPoint(right, x, y, z) then return true end
                    end
                end
            end
        end
        return false
    end
    return {
        countTiles = function(region)
            local count = 0
            for _, level in pairs(region and region.levels or {}) do
                for _, spans in pairs(level.rows or {}) do
                    for index = 1, #spans, 2 do
                        count = count + spans[index + 1] - spans[index] + 1
                    end
                end
            end
            return count
        end,
        isConnected = function() return true end,
        containsPoint = containsPoint,
        intersects = intersects,
    }
end

local request
PNC = {
    Network = {
        ClientState = {
            colonyManagement = {
                settlement = { id = "base:one" },
            },
        },
    },
    Client = {
        RequestColonyAction = function(action, args)
            request = { action = action, args = args }
            return true, "sent"
        end,
    },
}

local ownerWindow = {}
local UI = T.load("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_CorpseHaulUI.lua")
T.truthy(UI.Open(ownerWindow, "source"),
    "corpse haul opens its first selector")
T.equal(#opened, 1, "opening corpse haul creates one selector first")
T.contains(opened[1].title, "SOURCE", "first selector chooses corpse source")
T.equal(opened[1].ownerWindow, ownerWindow,
    "corpse source selector is owned by the zone window")

local source = { levels = { [0] = { rows = { [12] = { 12, 13 } } } } }
opened[1].onConfirm(source)
T.equal(#opened, 2, "source confirmation opens the destination selector")
T.contains(opened[2].title, "DESTINATION",
    "second selector chooses corpse destination")

local overlappingDestination = {
    levels = { [0] = { rows = { [12] = { 13, 14 } } } },
}
local overlapValid, overlapReason = opened[2].validate(overlappingDestination)
T.falsy(overlapValid, "destination selector allowed collect/dump overlap")
T.contains(overlapReason, "overlap",
    "destination selector did not explain the overlap rejection")
local tileValid, tileReason = opened[2].tileValidator(13, 12, 0)
T.falsy(tileValid, "destination selector did not mark overlap tiles invalid")
T.contains(tileReason, "overlap",
    "invalid overlap tile did not provide a useful reason")

local destination = { levels = { [0] = { rows = { [20] = { 20, 21 } } } } }
opened[2].onConfirm(destination)
T.equal(request.action, "corpse_haul_zones_set",
    "destination confirmation saves corpse-haul zones")
T.equal(request.args.baseId, "base:one", "zone save targets the active base")
T.equal(request.args.sourceRegion, source,
    "zone save preserves the selected corpse source")
T.equal(request.args.destinationRegion, destination,
    "zone save preserves the selected destination")

PNC.Network.ClientState.colonyManagement.settlement.corpseHaul = {
    sourceRegion = source, destinationRegion = destination,
}
T.truthy(UI.Open(ownerWindow, "destination"),
    "corpse dump opens directly when a source already exists")
T.equal(#opened, 3, "direct corpse dump creates one selector")
T.contains(opened[3].title, "DESTINATION",
    "dump button opens the destination selector")
T.equal(opened[3].initialRegion, destination,
    "dump selector starts from the saved destination")
T.equal(opened[3].guideLayers[1].region, source,
    "dump selector keeps the source region visible as a guide")

PNC.CommandHub = PNC.CommandHub or {}
PNC.CommandHub.CorpseHaulUI = UI
package.preload[
    "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_FishingActions"
] = function() return {} end
local ZoneRegistry = T.load("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_ZoneRegistry.lua")
local sourceSection = ZoneRegistry.Get("corpse_haul").sections[1]
T.equal(sourceSection.summary({
    sourceRegion = source,
    sourceCorpseCount = 2,
    sourceEligibleCorpseCount = 1,
}), "2 TILES | CORPSES: 2 | ELIGIBLE: 1",
    "corpse source summary reports total and eligible corpses")

T.finish("pnc_corpse_haul_selector_smoke")
