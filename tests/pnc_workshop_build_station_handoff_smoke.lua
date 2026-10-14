local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "client" },
    { "PsychopatzCore", "shared" },
})

PsychopatzCore = {
    UI = {
        Theme = { colors = {} },
        ImageResolver = { Resolve = function() return nil end },
    },
}
package.preload["PsychopatzCore/UI/PsychopatzUI"] = function()
    return PsychopatzCore.UI
end
package.preload["PNC/UI/Inventory/PNC_InventoryUI_Model"] = function()
    return {}
end
package.preload["PNC/Core/Settlement/PNC_FacilityState"] = function()
    return { IsBuilt = function() return true end }
end

getText = function(key) return key end
getTexture = function() return nil end
getItemNameFromFullType = function(fullType) return fullType end

PNC = {
    Translation = { GetKey = function(_, key) return key end },
    WorkDefinitions = {
        CRAFTING_SKILL_ORDER = { "Blacksmithing" },
        GetProductionSkillLabel = function(_, skill) return skill end,
        GetStationSkillProfile = function(_, stationId)
            return stationId == "forge" and { "Blacksmithing" } or {}
        end,
    },
    FacilityDefinitions = { ByID = {
        stockpile = true, workshop = true, forge = true,
    } },
}

function PNC.FacilityDefinitions.Get(id)
    if id == "workshop" then
        return {
            id = id, legacyOnly = true, category = "production",
            displayNameKey = id, descriptionKey = id,
            buildCosts = {{ fullType = "Base.Money", amount = 1 }},
        }
    end
    if id == "forge" then
        return {
            id = id, category = "production", directWorkstation = true,
            stationId = id, displayNameKey = id, descriptionKey = id,
            buildRecipeObjectInfoName = "Base.Forge",
            buildCosts = {{ fullType = "Base.IronBar", amount = 1 }},
        }
    end
    return nil
end

function PNC.FacilityDefinitions.GetLevel()
    return { requiredHQLevel = 1 }
end

PNC.BuildRecipeCatalog = {
    Get = function(objectInfoName)
        if objectInfoName ~= "Base.Forge" then return nil end
        return {
            objectInfoName = objectInfoName, displayName = "Forge",
            category = "Blacksmithing", requirements = {},
        }
    end,
}

local BuildUI = T.load("ProjectHoomans", "client",
    "PNC/UI/SettlementManagement/PNC_SettlementManagement_FacilityBuildCatalog.lua")
local settlement = { hqLevel = 1, facilities = {
    { definitionId = "stockpile", constructionState = "BUILT" },
} }

local normal = BuildUI.BuildOptions(settlement, { rows = {} }, {})
local forgeOption
for _, option in ipairs(normal) do
    T.falsy(option.id == "workshop",
        "legacy workshop leaked into the facility catalog")
    if option.id == "forge" then forgeOption = option end
end
T.truthy(forgeOption, "Forge was missing from the facility build catalog")
T.equal(forgeOption.buildRecipeObjectInfoName, "Base.Forge",
    "Forge option lost its native object identity")
T.equal(forgeOption.buildRecipe.objectInfoName, "Base.Forge",
    "Forge option did not resolve through BuildRecipeCatalog")

local opened
PNC.CommandHub = { ChildController = {
    Open = function(branch, owner, options)
        opened = { branch = branch, owner = owner, options = options }
        return true
    end,
} }

local Helpers = T.load("ProjectHoomans", "client",
    "PNC/UI/Workshop/PNC_WorkshopCatalog_Rebuild_Helpers.lua")
local Internal = Helpers.Internal
T.equal(Internal.StationTargetId({
    definitionId = "unregistered_alias", facilityId = "forge", id = "forge",
}), "forge", "station resolver did not choose the registered facility id")
T.equal(Internal.StationTargetId(nil), nil,
    "station resolver recreated the removed generic workshop fallback")
T.truthy(Internal.OpenStationBuild({ owner = "owner" }, {
    definitionId = "unregistered_alias", facilityId = "forge", id = "forge",
}), "Workshop station action did not open the Base branch")
T.equal(opened.options.focusDefinitionId, "forge",
    "Workshop station action used an unregistered display or alias name")
T.equal(opened.options.focusObjectInfoName, "Base.Forge",
    "Workshop station action did not carry the native Forge identity")
T.equal(opened.options.searchText, "forge",
    "Workshop station action did not search the canonical facility id")

return T.finish("pnc_workshop_build_station_handoff_smoke")
