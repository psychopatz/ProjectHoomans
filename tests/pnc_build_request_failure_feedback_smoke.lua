-- A BUILD click that cannot open its selector or placement cursor must report
-- failure. Previously BeginBuild returned true unconditionally, so the caller
-- closed the window and the player was left with nothing.
local T = require "tests/support/test"

T.addPackagePaths()

getSpecificPlayer = function()
    return { getZ = function() return 0 end }
end

package.preload[
    "PNC/UI/Shared/PNC_ColonyUIShared"
] = function()
    return { SettlementReason = function(reason) return reason end }
end
package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return { containsRegion = function() return true end }
end

local selectorResult = true
local selectorReason
local placementResult = true
local placementReason
local openedOptions

package.preload[
    "PNC/UI/SettlementManagement/PNC_SettlementManagement_SelectorSupport"
] = function()
    return {
        Tr = function(_, fallback) return fallback end,
        EmptyRegion = function() return { levels = {} } end,
        BaseRegion = function() return { levels = {} } end,
        FacilityRegion = function() return { levels = {} } end,
        UsedGuideLayers = function() return {} end,
        ValidateConnected = function() return true end,
        OpenSelector = function(_, options)
            openedOptions = options
            if selectorResult == false then return false, selectorReason end
            return true
        end,
        ApplyLocalResult = function() end,
    }
end
package.preload[
    "PNC/UI/Base/PNC_BaseBuildingPlacement"
] = function()
    return {
        Begin = function()
            if placementResult == false then
                return false, placementReason
            end
            return true
        end,
    }
end

local definitions = {
    legacy_hut = { buildCosts = { { fullType = "Base.Plank", amount = 2 } } },
    native_station = { directWorkstation = true,
        buildRecipeObjectInfoName = "Base.Log_Table",
        entityScript = "Base.Log_Table" },
}

PNC = {
    FacilityDefinitions = {
        Get = function(definitionId) return definitions[definitionId] end,
        GetLevel = function()
            return { componentLimits = {
                ["facility.footprint"] = { kind = "region", limit = 1 },
            } }
        end,
    },
    BuildRecipeCatalog = {
        Get = function(name)
            return { recipeKey = name, objectInfoName = name }
        end,
    },
    Client = {
        RequestCreateFacility = function() end,
    },
}

local Facility = require(
    "PNC/UI/SettlementManagement/"
    .. "PNC_SettlementManagement_FacilityActions")
local window = { snapshot = { settlement = { id = "base:1", revision = 4 } } }

local started, reason = Facility.BeginBuild(window, "legacy_hut")
T.truthy(started == true, "open area selector did not start the build")
T.truthy(openedOptions ~= nil, "area selector received no options")

-- The selector refuses to open: the caller must be told, not left with a
-- closed window and no build.
selectorResult, selectorReason = false, "PLAYER_UNAVAILABLE"
started, reason = Facility.BeginBuild(window, "legacy_hut")
T.truthy(started == false, "failed selector still reported success")
T.equal(reason, "PLAYER_UNAVAILABLE",
    "selector failure reason was not propagated")
selectorResult, selectorReason = true, nil

-- Native workstation placement cursor refuses to start.
placementResult, placementReason = false, "BUILD_RECIPE_NOT_FOUND"
started, reason = Facility.BeginBuild(window, "native_station")
T.truthy(started == false, "failed placement still reported success")
T.equal(reason, "BUILD_RECIPE_NOT_FOUND",
    "placement failure reason was not propagated")
placementResult, placementReason = true, nil

T.truthy(Facility.BeginBuild(window, "native_station") == true,
    "native workstation placement did not start")

local source = T.read("ProjectHoomans", "client",
    "PNC/UI/SettlementManagement/"
        .. "PNC_SettlementManagement_FacilityActions.lua")
T.contains(source, "if not selector then return false",
    "BeginBuild must fail when the selector does not open")

T.finish("pnc_build_request_failure_feedback_smoke")
