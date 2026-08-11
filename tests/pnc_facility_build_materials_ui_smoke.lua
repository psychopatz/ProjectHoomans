local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/"
package.path = ROOT .. "client/?.lua;" .. ROOT .. "shared/?.lua;" .. package.path

local function equal(actual, expected, message)
    if actual ~= expected then
        error((message or "assertion failed") .. ": expected "
            .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

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

PNC = { FacilityDefinitions = { ByID = { barracks = true } } }
function PNC.FacilityDefinitions.Get()
    return { id = "barracks", displayNameKey = "Barracks",
        descriptionKey = "Barracks description",
        buildCosts = {{ fullType = "Base.Money", amount = 1 }} }
end
function PNC.FacilityDefinitions.GetLevel()
    return { requiredHQLevel = 1 }
end

local BuildUI = require(
    "PNC/UI/Communities/ColonyManagement/PNC_FacilityBuildModal"
)
local options = BuildUI.BuildOptions({ hqLevel = 1 }, {
    rows = {{ fullType = "Base.Money", quantity = 1 }},
})
equal(options[1].enabled, true, "stockpile satisfies material cost")
equal(options[1].costText, "1 Base.Money (1 total)", "combined total")
equal(options[1].sourceText, "0 player + 1 stockpile", "source breakdown")

carried = 1
options = BuildUI.BuildOptions({ hqLevel = 1 }, {
    rows = {{ fullType = "Base.Money", quantity = 2 }},
})
equal(options[1].costText, "1 Base.Money (3 total)",
    "player and stockpile aggregate")
equal(options[1].sourceText, "1 player + 2 stockpile",
    "aggregate source breakdown")

print("pnc_facility_build_materials_ui_smoke: ok")
