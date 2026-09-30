-- Footer buttons in the Facilities tab were fixed at 120/132px, so longer
-- titles ("GIVE BUILDING MATERIALS", "SHOW QUEUE OVERLAY") were painted wider
-- than their own button and bled over the neighbour. Buttons are now measured
-- from their labels and wrapped onto extra rows when the window is narrow, and
-- the right-aligned CANCEL can never overlap an action button.
local T = require "tests/support/test"

T.addPackagePaths()

package.preload["PsychopatzCore/UI/PsychopatzUI"] = function()
    return PsychopatzCore.UI
end

local function control(title, visible)
    local value = { title = title, visible = visible ~= false }
    function value:getIsVisible() return self.visible end
    function value:setVisible(state) self.visible = state end
    function value:setHeader() end
    function value:setEnable() end
    return value
end

PsychopatzCore = {
    UI = {
        Theme = {
            Font = function() return "Small" end,
            TextWidth = function(_, text) return #tostring(text or "") * 7 end,
        },
        Layout = {
            Pixels = function(value) return value end,
            SetBounds = function(element, x, y, width, height)
                element.bounds = { x = x, y = y, width = width, height = height }
            end,
        },
    },
}

local LayoutModel = T.load("ProjectHoomans", "client",
    "PNC/UI/Base/PNC_BaseBuildingLayout.lua")

local function buildWindow()
    local window = {
        uiScale = 1,
        baseBuildingCategoryButtons = {},
        baseBuildingSearch = control(""),
        baseBuildingPrevious = control(""),
        baseBuildingNext = control(""),
        baseBuildingBuildButton = control("BUILD"),
        baseBuildingDebugButton = control("GIVE BUILDING MATERIALS"),
        baseBuildingCancelPlacement = control("CANCEL PLACEMENT"),
        baseBuildingQueueOverlay = control("SHOW QUEUE OVERLAY"),
        baseBuildingCloseButton = control("CANCEL"),
        baseBuildingCards = {},
        baseBuildingDetails = control(""),
        baseBuildingMaterialPane = control(""),
        baseBuildingNativeQueuePane = control(""),
        baseBuildingPage = 1,
        baseBuildingPageCount = 1,
    }
    function window:layoutPane(pane, x, y, width, height)
        pane.bounds = { x = x, y = y, width = width, height = height }
    end
    return window
end

local content = { x = 10, y = 20, width = 1100, height = 700 }
local window = buildWindow()
LayoutModel.Apply(window, content)

local debug = window.baseBuildingDebugButton.bounds
local build = window.baseBuildingBuildButton.bounds
local cancel = window.baseBuildingCloseButton.bounds
T.truthy(debug and build and cancel, "footer buttons were laid out")

-- The label must fit inside its own button (no bleed into the neighbour).
local function labelWidth(text) return #text * 7 end
T.truthy(debug.width >= labelWidth("GIVE BUILDING MATERIALS"),
    "long footer label fits its button")
T.truthy(window.baseBuildingQueueOverlay.bounds.width
        >= labelWidth("SHOW QUEUE OVERLAY"),
    "queue overlay label fits its button")

-- Width follows the label, so the shorter action is the narrower button.
T.truthy(build.width < debug.width,
    "button width follows the measured label")

-- Nothing overlaps the right-aligned CANCEL on the same row.
local controls = { build, debug,
    window.baseBuildingCancelPlacement.bounds,
    window.baseBuildingQueueOverlay.bounds }
for _, bounds in ipairs(controls) do
    if math.abs(bounds.y - cancel.y) < 1 then
        T.truthy(bounds.x + bounds.width <= cancel.x,
            "action button overlaps CANCEL")
    end
end

-- A narrow window wraps instead of overlapping: rows stay inside the content.
local narrow = buildWindow()
LayoutModel.Apply(narrow, { x = 10, y = 20, width = 560, height = 520 })
local rows = {}
for _, element in ipairs({ narrow.baseBuildingBuildButton,
    narrow.baseBuildingDebugButton, narrow.baseBuildingCancelPlacement,
    narrow.baseBuildingQueueOverlay, narrow.baseBuildingCloseButton }) do
    T.truthy(element.bounds, "narrow layout placed every footer button")
    T.truthy(element.bounds.x >= 10, "footer button left inside the content")
    T.truthy(element.bounds.x + element.bounds.width <= 570,
        "footer button stays inside the content width")
    rows[tostring(element.bounds.y)] = true
end
local rowCount = 0
for _ in pairs(rows) do rowCount = rowCount + 1 end
T.truthy(rowCount >= 1, "narrow layout produced footer rows")

T.finish("pnc_base_building_footer_layout_smoke")
