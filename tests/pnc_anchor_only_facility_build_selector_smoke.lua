local T = require "tests/support/test"

T.addPackagePaths()

getSpecificPlayer = function()
    return { getZ = function() return 0 end }
end

package.preload[
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
] = function()
    return { SettlementReason = function(reason) return reason end }
end
package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return { containsRegion = function() return true end }
end

local openedOptions
local request
local placement
package.preload[
    "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_SelectorSupport"
] = function()
    return {
        Tr = function(_, fallback) return fallback end,
        EmptyRegion = function() return { levels = {} } end,
        BaseRegion = function() return { levels = {} } end,
        FacilityRegion = function() return { levels = {} } end,
        UsedGuideLayers = function() return {} end,
        ValidateConnected = function() return true end,
        OpenSelector = function(_, options)
            T.truthy(type(options) == "table",
                "anchor-only facility passed nil selector options")
            openedOptions = options
            return true
        end,
        ApplyLocalResult = function() end,
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
    FacilityDefinitions = {
        Get = function(definitionId)
            T.truthy(definitionId == "research_facility",
                "unexpected facility definition")
            return { directWorkstation = true,
                buildRecipeObjectInfoName = "Base.Log_Table",
                entityScript = "Base.Log_Table" }
        end,
    },
    BuildRecipeCatalog = {
        Get = function(name)
            return { recipeKey = name, objectInfoName = name }
        end,
    },
    Client = {
        RequestCreateFacility = function(payload) request = payload end,
    },
}

local Facility = require(
    "PNC/UI/Communities/ColonyManagement/SettlementManagement/"
    .. "PNC_SettlementManagement_FacilityActions")
local window = { snapshot = { settlement = { id = "base:1", revision = 4 } } }

T.truthy(Facility.BeginBuild(window, "research_facility") == true,
    "research facility build did not open")
T.falsy(openedOptions ~= nil, "research facility opened a room selector")
T.equal(placement.objectInfoName, "Base.Log_Table",
    "research facility routes the native Log Table to placement")
T.finish("pnc_anchor_only_facility_build_selector_smoke")

T.finish("pnc_anchor_only_facility_build_selector_smoke")
