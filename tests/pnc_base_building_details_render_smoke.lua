-- Regression guard for the Facilities tab render path.
--
-- A nil global inside DetailsPanel:render raised "Object tried to call nil in
-- render" every frame, which aborted the UI draw and left the whole tab blank.
-- A syntax check cannot catch that, so this test actually renders the panel.
local T = require "tests/support/test"

T.addPackagePaths()

local drawn = {}
local Option = { id = "research_table", name = "Research Table",
    description = "Construct the facility, then assign its research station.",
    status = "NEED MORE MATERIALS", enabled = false }

local function panelClass()
    local class = {}
    function class:derive() return panelClass() end
    function class:new(x, y, width, height)
        local object = setmetatable({ x = x, y = y, width = width,
            height = height, children = {} }, { __index = class })
        return object
    end
    function class:initialise() end
    function class:instantiate() end
    function class:addChild(child) self.children[#self.children + 1] = child end
    function class:setStencilRect() self.stencilled = true end
    function class:clearStencilRect() self.stencilled = false end
    function class:getWidth() return self.width end
    function class:getHeight() return self.height end
    function class:render() end
    function class:drawText(text, x, y)
        drawn[#drawn + 1] = { text = tostring(text), x = x, y = y }
    end
    function class:drawTextCentre(text, x, y)
        drawn[#drawn + 1] = { text = tostring(text), x = x, y = y }
    end
    return class
end

ISPanel = panelClass()
package.preload["ISUI/ISPanel"] = function() return ISPanel end
package.preload["PsychopatzCore/UI/PsychopatzUI"] = function()
    return PsychopatzCore.UI
end
package.preload["PNC/UI/Shared/PNC_ColonyUIComponents"] = function()
    return {}
end
package.preload["PNC/UI/Base/PNC_BaseBuildingData"] = function()
    return { SelectedOption = function() return Option end }
end
package.preload[
    "PNC/UI/SettlementManagement/PNC_SettlementManagement_FacilityBuildModal"
] = function()
    return { FacilityCard = panelClass() }
end

PsychopatzCore = {
    UI = {
        Theme = {
            colors = {
                textMuted = { r = 0.7, g = 0.7, b = 0.7, a = 1 },
                text = { r = 1, g = 1, b = 1, a = 1 },
                accent = { r = 0.2, g = 0.7, b = 0.8, a = 1 },
            },
            FontHeight = function() return 14 end,
            TextWidth = function(_, value) return #tostring(value or "") * 7 end,
        },
        Layout = { Ellipsize = function(value) return tostring(value) end },
    },
}
PNC = { Translation = { GetKey = function(_, fallback) return fallback end } }
UIFont = { Small = "Small", Medium = "Medium" }

local Cards = T.load("ProjectHoomans", "client",
    "PNC/UI/Base/PNC_BaseBuildingCards.lua")

local window = { baseBuildingCategoryButtons = {}, baseBuildingCards = {},
    baseBuildCardOwner = { selectedId = nil }, snapshot = {},
    children = {} }
function window:addChild(child) self.children[#self.children + 1] = child end
Cards.Create(window)
T.truthy(window.baseBuildingDetails ~= nil,
    "details strip is not created")
local panel = window.baseBuildingDetails
panel.width, panel.height = 900, 60
panel.owner = window
panel:render()
T.equal(#drawn, 1, "details strip draws exactly one description body")
T.contains(drawn[1].text, "Construct the facility",
    "details strip renders the selected facility description")
T.falsy(panel.stencilled, "details strip releases its stencil after render")

-- An empty selection must still render its guidance instead of erroring.
Option = nil
drawn = {}
panel:render()
T.equal(#drawn, 1, "empty details strip draws its empty-state hint")

T.finish("pnc_base_building_details_render_smoke")
