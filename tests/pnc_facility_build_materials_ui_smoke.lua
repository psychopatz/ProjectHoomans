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
local windowSpec = BuildUI.WindowSpec()
T.equal(windowSpec.width, 1180,
    "facility build modal uses the responsive baseline width")
T.equal(windowSpec.height, 760,
    "facility build modal uses enough baseline height for the recipe card")
T.equal(windowSpec.minWidth, 760,
    "facility build modal rejects the legacy narrow geometry")
T.equal(windowSpec.minHeight, 540,
    "facility build modal rejects the legacy short geometry")
windowSpec.width = 1
T.equal(BuildUI.WindowSpec().width, 1180,
    "facility window spec is copied instead of shared")
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

local requested
local closed = false
PNC.Client = {
    CanUseDebug = function() return true end,
    RequestDebugFacilityMaterials = function(args)
        requested = args
        return true
    end,
}
local actionWindow = setmetatable({
    selectedOption = { id = "forge" },
    debugMaterialsButton = { setEnable = function() end },
}, { __index = ISPNCFacilityBuildWindow })
function actionWindow:close() closed = true end
ISPNCFacilityBuildWindow.onAction(actionWindow, {
    internal = "debug_materials",
})
T.equal(requested.definitionId, "forge",
    "facility debug button sends the selected definition")
T.falsy(closed, "facility debug button keeps the modal open")

local buildStarted, restorePrevious
local buildActionWindow = setmetatable({
    selectedOption = { id = "forge", enabled = true },
    onConfirm = function(id)
        buildStarted = id
        return true
    end,
}, { __index = ISPNCFacilityBuildWindow })
function buildActionWindow:close(restore)
    restorePrevious = restore
end
ISPNCFacilityBuildWindow.onAction(buildActionWindow, { internal = "build" })
T.equal(buildStarted, "forge", "build action invokes the placement callback")
T.equal(restorePrevious, false,
    "placement-starting build closes without restoring the hidden colony UI")

local refreshed = BuildUI.BuildOptions(settlement, {
    rows = {},
})
local refreshWindow = setmetatable({
    options = refreshed,
    selectedId = refreshed[1] and refreshed[1].id,
    selectedOption = refreshed[1],
    settlement = settlement,
    snapshotRevision = 1,
    cards = {{ option = refreshed[1] }},
}, { __index = ISPNCFacilityBuildWindow })
function refreshWindow:requestResponsiveLayout() end
PNC.ColonyManagementClient = {
    ReadSnapshot = function()
        return {
            revision = 2,
            snapshot = {
                settlement = settlement,
                storage = { rows = {{ fullType = "Base.Money", quantity = 1 }} },
            },
        }
    end,
}
refreshWindow:refreshFromSnapshot()
T.truthy(refreshWindow.options[1].enabled,
    "facility modal refreshes affordability from the new snapshot")
T.finish("pnc_facility_build_materials_ui_smoke")
