local T = require "tests/support/test"
T.addPackagePaths()

local placement
local selectorOpened = false
package.preload[
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
] = function() return { SettlementReason = function(reason) return reason end } end
package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return { bounds = function() return nil end,
        containsPoint = function() return true end }
end
package.preload[
    "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_SelectorSupport"
] = function()
    return {
        OpenSelector = function() selectorOpened = true end,
        BaseRegion = function() return {} end,
        EmptyRegion = function() return {} end,
        UsedGuideLayers = function() return {} end,
        Tr = function(_, fallback) return fallback end,
    }
end
package.preload[
    "PNC/UI/Communities/ColonyManagement/PNC_BuildingPlacement"
] = function()
    return {
        Begin = function(_, recipe)
            placement = recipe
            return true
        end,
    }
end

PNC = {
    Farming = {},
    BuildRecipeCatalog = {
        Get = function(name)
            return { recipeKey = name, objectInfoName = name }
        end,
    },
    FacilityDefinitions = {
        Get = function(id)
            if id ~= "forge" then return nil end
            return { directWorkstation = true,
                buildRecipeObjectInfoName = "Base.Forge",
                entityScript = "Base.Forge" }
        end,
    },
}

local Facility = T.load("ProjectHoomans", "client",
    "PNC/UI/Communities/ColonyManagement/SettlementManagement/"
    .. "PNC_SettlementManagement_FacilityActions.lua")
local window = { snapshot = {
    settlement = { id = "base:1", revision = 7 },
} }

T.truthy(Facility.BeginBuild(window, "forge"),
    "direct workstation build enters placement")
T.falsy(selectorOpened, "direct workstation bypasses room selector")
T.equal(placement.objectInfoName, "Base.Forge",
    "native object identity reaches builder")
T.equal(placement.facilityDefinitionId, "forge",
    "builder order retains facility identity")
T.equal(placement.facilityBaseId, "base:1",
    "builder order retains base identity")
T.equal(placement.facilityExpectedRevision, 7,
    "builder order retains revision guard")

T.finish("pnc_workstation_builder_launch_smoke")
