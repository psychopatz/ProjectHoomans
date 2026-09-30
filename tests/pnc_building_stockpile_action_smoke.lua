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
        -- Mirrors the shared module: a missing state means already built.
        ConstructionState = function(facility)
            local value = facility and facility.constructionState
            if value == nil or tostring(value) == "" then return "BUILT" end
            return tostring(value)
        end,
    }
end

local beginBuild
package.preload["PNC/UI/SettlementManagement/PNC_SettlementManagement_FacilityActions"] = function()
    return {
        BeginBuild = function(window, definitionId)
            beginBuild = { window = window, definitionId = definitionId }
            return true
        end,
    }
end

local playerInventory = {
    getItemsFromType = function(_, fullType)
        return {
            size = function()
                return fullType == "Base.Money" and 1 or 0
            end,
        }
    end,
}
function getSpecificPlayer()
    return { getInventory = function() return playerInventory end }
end

PNC = {
    CommandHub = {},
    FacilityDefinitions = {
        Get = function(id)
            if id ~= "stockpile" then return nil end
            return {
                buildCosts = {
                    { fullType = "Base.Money", amount = 1 },
                },
            }
        end,
    },
}
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

-- A stockpile record that is only PLANNED and idle must keep the bootstrap
-- button: the FACILITIES tab never lists the stockpile, so hiding the button
-- left a stuck stockpile with no rebuild path at all (a soft-lock).
snapshot = {
    colony = { id = "colony-1" },
    settlement = { facilities = {
        { definitionId = "stockpile", constructionState = "PLANNED" },
    } },
}
T.truthy(Registry.IsVisible(stockpile),
    "planned stockpile hid its own rebuild path")
T.falsy(PNC.CommandHub.Gates.GetBaseAndStockpileStatus().hasStockpile,
    "planned stockpile was reported as usable storage")

-- Work in flight hides the button; it is already being handled.
snapshot.settlement.facilities[1].constructionState = "RECONSTRUCTING"
T.falsy(Registry.IsVisible(stockpile),
    "stockpile being reconstructed still offered a second build")

snapshot.settlement.facilities[1].constructionState = "BUILT"
local status = PNC.CommandHub.Gates.GetBaseAndStockpileStatus()
T.truthy(status.hasStockpile, "built stockpile was not recognized")
T.truthy(Registry.IsEnabled(building),
    "building safeguard did not enable after stockpile completion")
T.falsy(Registry.IsVisible(stockpile),
    "stockpile bootstrap remained visible after being built")

local buildingTabSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Base/PNC_BaseBuildingCatalog.lua")
T.falsy(string.find(buildingTabSource, '"build_stockpile"', 1, true),
    "stockpile bootstrap leaked back into the Building child UI")

T.finish("pnc_building_stockpile_action_smoke")
