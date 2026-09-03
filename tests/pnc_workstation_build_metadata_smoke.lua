local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "client" },
    { "PsychopatzCore", "shared" },
})

local function derive(self)
    local child = {}; child.__index = child
    setmetatable(child, { __index = self })
    return child
end

ISPanel = { derive = derive }
PsychopatzWindow = { derive = derive }
PsychopatzCore = {
    UI = {
        Theme = { colors = {} },
        Layout = {},
    },
}
package.preload["ISUI/ISPanel"] = function() return ISPanel end
package.preload["PsychopatzCore/UI/PsychopatzUI"] = function()
    return PsychopatzCore.UI
end

getText = function(key)
    return key == "UI_PNC_Facility_ResearchTable" and "RESEARCH TABLE"
        or key
end
getItemNameFromFullType = function(fullType)
    return ({ ["Base.IronBar"] = "Iron Bar" })[fullType] or fullType
end
getTexture = function(path) return path end

PNC = {
    WorkDefinitions = {
        CRAFTING_SKILL_ORDER = { "Blacksmithing", "Cooking" },
        GetStationSkillProfile = function(id)
            return id == "forge" and { "Blacksmithing" } or {}
        end,
        GetProductionSkillLabel = function(id) return id end,
    },
    BuildRecipeCatalog = {
        Get = function(objectInfoName)
            if objectInfoName == "Base.Forge" then
                return {
                    objectInfoName = "Base.Forge",
                    recipeKey = "Base.Forge",
                    displayName = "Forge",
                    category = "Blacksmithing",
                    iconName = "forge_sprite",
                    iconTexture = "native_forge_texture",
                    requirements = {
                        { itemTypes = { "Base.IronBar" }, amount = 3 },
                    },
                }
            end
            if objectInfoName == "Base.Log_Table" then
                return {
                    objectInfoName = "Base.Log_Table",
                    recipeKey = "Base.Log_Table",
                    displayName = "Log Table",
                    category = "Carpentry",
                    iconName = "log_table_sprite",
                    iconTexture = "native_log_table_texture",
                    requirements = {
                        { itemTypes = { "Base.Log" }, amount = 1 },
                    },
                }
            end
            return nil
        end,
    },
    FacilityDefinitions = { ByID = {
        stockpile = true, primitive_forge = true, forge = true,
        research_facility = true,
    } },
}

function PNC.FacilityDefinitions.Get(id)
    if id == "stockpile" then
        return { id = id, category = "housing", displayNameKey = id,
            descriptionKey = id, buildCosts = {
                { fullType = "Base.Money", amount = 1 },
            } }
    end
    if id == "primitive_forge" then
        return { id = id, category = "Blacksmithing", displayNameKey = id,
            descriptionKey = id, directWorkstation = true,
            stationId = id, entityScript = "Base.Primitive_Forge",
                buildRecipeObjectInfoName = "Base.Forge", requiredTechnology = nil }
    end
    if id == "research_facility" then
        return { id = id, category = "technology", displayNameKey = id,
            buildDisplayNameKey = "UI_PNC_Facility_ResearchTable",
            descriptionKey = id, directWorkstation = true,
            stationId = "research_facility", entityScript = "Base.Log_Table",
            buildRecipeObjectInfoName = "Base.Log_Table",
            requiredTechnology = nil }
    end
    return { id = id, category = "Blacksmithing", displayNameKey = id,
        descriptionKey = id, directWorkstation = true, stationId = "forge",
        entityScript = "Base.Forge", buildRecipeObjectInfoName = "Base.Forge",
        requiredTechnology = "facility:workshop" }
end

function PNC.FacilityDefinitions.GetLevel()
    return { requiredHQLevel = 1 }
end

local BuildUI = T.load("ProjectHoomans", "client",
    "PNC/UI/Communities/ColonyManagement/PNC_FacilityBuildModal.lua")
local options = BuildUI.BuildOptions({ hqLevel = 1, facilities = {
    { definitionId = "stockpile", constructionState = "BUILT" },
} }, {
    rows = {
        { fullType = "Base.IronBar", quantity = 3 },
        { fullType = "Base.Log", quantity = 1 },
        { fullType = "Base.Money", quantity = 1 },
    },
})

local primitive, proper, research
for _, option in ipairs(options) do
    if option.id == "primitive_forge" then primitive = option end
    if option.id == "forge" then proper = option end
    if option.id == "research_facility" then research = option end
end
T.truthy(primitive, "primitive workstation is present")
T.equal(primitive.name, "Forge", "native build name replaces facility id")
T.equal(primitive.category, "Blacksmithing",
    "native production category is used")
T.equal(primitive.texture, "native_forge_texture",
    "native build texture is used before the sprite-name fallback")
T.equal(primitive.costText, "3 Iron Bar (3 total)",
    "native material cost is shown")
T.truthy(primitive.enabled, "primitive workstation is not research gated")
T.falsy(proper.enabled, "proper workstation remains research gated")
T.equal(proper.status, "RESEARCH REQUIRED",
    "proper workstation exposes research gating")
T.truthy(research, "research Log Table workstation is present")
T.equal(research.name, "RESEARCH TABLE",
    "research facility uses its build-specific Research Table name")
T.equal(research.texture, "native_log_table_texture",
    "research facility uses the native Log Table icon")
T.equal(research.costText, "1 Base.Log (1 total)",
    "research facility uses the native Log Table materials")
T.truthy(research.enabled,
    "research Log Table workstation is not technology gated")

T.finish("pnc_workstation_build_metadata_smoke")
