local T = require "tests/support/test"

PsychopatzCore = { UI = {} }
local CoreRegistry = T.load("PsychopatzCore", "client",
    "PsychopatzCore/UI/PsychopatzCommandHubRegistry.lua")
package.preload["PsychopatzCore/UI/PsychopatzCommandHub"] = function()
    return { Registry = CoreRegistry, Trace = function() end }
end
package.preload["PNC/Core/Settlement/PNC_FacilityState"] = function()
    return {
        IsBuilt = function(facility)
            return facility and facility.constructionState == "BUILT"
        end,
    }
end

local beginBuild
package.preload["PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_FacilityActions"] = function()
    return {
        BeginBuild = function(window, definitionId)
            beginBuild = { window = window, definitionId = definitionId }
            return true
        end,
    }
end

PNC = { CommandHub = {} }
local Registry = T.load("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_Registry.lua")

local snapshot = {}
PNC.ColonyManagementClient = {
    ReadSnapshot = function() return { snapshot = snapshot } end,
}

local stockpile = Registry.Get("stockpile")
local building = Registry.Get("base")
T.truthy(stockpile, "stockpile bootstrap is not registered on the hub")
T.truthy(stockpile.onClick, "stockpile bootstrap has no hub action")
T.truthy(building, "base category is missing")

T.truthy(Registry.IsVisible(stockpile),
    "stockpile bootstrap disappeared without a settlement")
T.falsy(Registry.IsEnabled(stockpile),
    "stockpile bootstrap enabled without a colony base")

snapshot = {
    colony = { id = "colony-1" },
    settlement = { facilities = {} },
}
T.truthy(Registry.IsVisible(stockpile),
    "stockpile bootstrap disappeared before being built")
T.truthy(Registry.IsEnabled(stockpile),
    "stockpile bootstrap did not enable with a colony base")
T.truthy(Registry.IsEnabled(building),
    "Base did not open before a stockpile existed")

local owner = {}
local handled = stockpile.onClick(stockpile, owner)
T.truthy(handled, "hub stockpile button did not start the build workflow")
T.equal(beginBuild.window, owner,
    "hub stockpile button did not pass the hub as selector owner")
T.equal(beginBuild.definitionId, "stockpile",
    "hub stockpile button did not use the stockpile definition")

snapshot = {
    colony = { id = "colony-1" },
    settlement = { facilities = {
        { definitionId = "stockpile", constructionState = "PLANNED" },
    } },
}
T.falsy(Registry.IsVisible(stockpile),
    "stockpile bootstrap remained visible after being planned")

snapshot.settlement.facilities[1].constructionState = "BUILT"
local status = PNC.CommandHub.Gates.GetBaseAndStockpileStatus()
T.truthy(status.hasStockpile, "built stockpile was not recognized")
T.truthy(Registry.IsEnabled(building),
    "building safeguard did not enable after stockpile completion")
T.falsy(Registry.IsVisible(stockpile),
    "stockpile bootstrap remained visible after being built")

local buildingTabSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagementBuildingTab.lua")
T.falsy(string.find(buildingTabSource, '"build_stockpile"', 1, true),
    "stockpile bootstrap leaked back into the Building child UI")

T.finish("pnc_building_stockpile_action_smoke")
