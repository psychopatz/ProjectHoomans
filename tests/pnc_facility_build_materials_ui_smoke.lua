local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "shared" },
})

local function derive(self)
    local child = {}; child.__index = child
    setmetatable(child, { __index = self })
    return child
end
ISPanel = { derive = derive }
PsychopatzWindow = { derive = derive }
package.preload["ISUI/ISPanel"] = function() return ISPanel end
PsychopatzCore = { UI = { Theme = { colors = {} }, Layout = {} } }
package.preload["PsychopatzCore/UI/PsychopatzUI"] = function()
    return PsychopatzCore.UI
end

getText = function(key) return key end
getTexture = function() return nil end
local carried = 0
getSpecificPlayer = function()
    return { getInventory = function()
        return { getItemsFromType = function()
            return { size = function() return carried end }
        end }
    end }
end

PNC = { FacilityDefinitions = { ByID = {
    barracks = true, stockpile = true, workshop = true,
} } }
function PNC.FacilityDefinitions.Get(id)
    return { id = id, displayNameKey = id,
        category = id == "barracks" and "housing" or "production",
        descriptionKey = id .. " description",
        bootstrapFromPlayer = id == "stockpile",
        requiredTechnology = id == "workshop" and "facility:workshop" or nil,
        buildCosts = {{ fullType = "Base.Money", amount = 1 }} }
end
function PNC.FacilityDefinitions.GetLevel()
    return { requiredHQLevel = 1 }
end

local BuildUI = require(
    "PNC/UI/Communities/ColonyManagement/PNC_FacilityBuildModal")
local settlement = { hqLevel = 1, facilities = {{
    definitionId = "stockpile", constructionState = "BUILT",
}} }
local options = BuildUI.BuildOptions(settlement, {
    rows = {{ fullType = "Base.Money", quantity = 1 }},
})
T.truthy(options[1].enabled, "built stockpile unlocks barracks")
T.equal(options[1].category, "housing", "building category reaches catalog")
T.equal(options[1].costText, "1 Base.Money (1 total)", "stockpile total")
T.equal(options[1].sourceText, "1 stockpile", "stockpile source")
T.falsy(options[2].enabled, "second stockpile is disabled")
T.falsy(options[3].enabled, "locked workshop is unavailable")

options = BuildUI.BuildOptions({ hqLevel = 1, facilities = {} }, {
    rows = {{ fullType = "Base.Money", quantity = 9 }},
})
T.falsy(options[1].enabled, "ordinary building requires built stockpile")
T.equal(options[1].status, "BUILD STOCKPILE FIRST",
    "stockpile prerequisite is visible")
T.falsy(options[2].enabled, "bootstrap stockpile requires player money")
carried = 1
options = BuildUI.BuildOptions({ hqLevel = 1, facilities = {} }, {
    rows = {{ fullType = "Base.Money", quantity = 9 }},
})
T.truthy(options[2].enabled, "player money funds the first stockpile")
T.equal(options[2].sourceText, "1 player", "bootstrap source is player")

options = BuildUI.BuildOptions(settlement, {
    rows = {{ fullType = "Base.Money", quantity = 1 }},
}, { learnedTechnologyIds = { "facility:workshop" } })
T.truthy(options[3].enabled, "researched workshop becomes available")
T.finish("pnc_facility_build_materials_ui_smoke")
