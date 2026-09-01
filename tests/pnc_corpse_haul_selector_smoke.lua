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

T.finish("pnc_corpse_haul_selector_smoke")
