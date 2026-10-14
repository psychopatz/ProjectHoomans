local T = require "tests/support/test"

T.addPackagePaths()

package.preload["PNC/UI/Inventory/PNC_InventoryUI_Model"] = function()
    return {}
end

PNC = PNC or {}

local data = T.load("ProjectHoomans", "client",
    "PNC/UI/Base/PNC_BaseBuildingData.lua")

local function searchField(value)
    return { getText = function() return value end }
end

local options = {
    { id = "housing_bed", name = "Wooden Bed", category = "housing" },
    { id = "research_lab", name = "Research Lab", category = "technology" },
    { id = "forge", name = "Simple Forge", category = "blacksmithing" },
}

local window = {
    baseBuildingOptions = options,
    baseBuildingCategory = "housing",
    baseBuildingSearch = searchField("research"),
    lastReceiveRevision = 1,
}

local globalResults = data.FilteredOptions(window)
T.equal(#globalResults, 1,
    "facilities search did not search outside the selected category")
T.equal(globalResults[1].id, "research_lab",
    "facilities search returned the wrong cross-category result")
T.truthy(data.IsSearchActive(window),
    "facilities search did not enter global-search mode")

window.baseBuildingSearch = searchField("")
local categoryResults = data.FilteredOptions(window)
T.equal(#categoryResults, 1,
    "clearing facilities search did not restore category filtering")
T.equal(categoryResults[1].id, "housing_bed",
    "clearing facilities search did not restore the selected category")
T.falsy(data.IsSearchActive(window),
    "empty facilities search is still marked active")

local layoutSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Base/PNC_BaseBuildingLayout_Panes.lua")
local viewSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Base/PNC_BaseBuildingView.lua")
local paneSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Shared/PNC_ColonyUIComponents.lua")
T.contains(viewSource, "UI.CreateResizableDivider",
    "Base facilities did not create a shared Core resize divider")
T.contains(viewSource, "facilityLowerSplitRatio",
    "Base facilities splitter has no per-window saved setting")
T.contains(viewSource, "ProjectHoomans_BaseBuildingUI.txt",
    "Base facilities splitter is not stored with the Base UI settings")
T.contains(layoutSource, "Layout.HorizontalSplit",
    "Base facilities lower panes do not use the shared split layout")
T.contains(paneSource, "Layout.SetBounds(self.content, 0, headerHeight",
    "colony pane content is not offset below its sticky header")
T.contains(paneSource, "UI.DrawSectionTitle(self, self.headerTitle",
    "colony pane does not render its header outside the scrolling content")

local function control()
    local value = { bounds = nil }
    function value:getIsVisible() return false end
    function value:layoutContent() self.contentLaidOut = true end
    return value
end

local function divider()
    local value = { bounds = nil }
    function value:setRange(minimum, maximum)
        self.minimum, self.maximum = minimum, maximum
    end
    function value:setValue(nextValue)
        self.value = nextValue
    end
    function value:bringToTop() self.broughtToTop = true end
    return value
end

local Layout = {
    Pixels = function(value) return value end,
    SetBounds = function(element, x, y, width, height)
        element.bounds = { x = x, y = y, width = width, height = height }
    end,
    HorizontalSplit = function(rect, splitOptions)
        local available = rect.width - splitOptions.gap
        local firstWidth = math.floor(available
            * (splitOptions.firstRatio or 0.4) + 0.5)
        local minimumFirst = splitOptions.minFirst
        local minimumSecond = splitOptions.minSecond
        firstWidth = math.max(minimumFirst,
            math.min(available - minimumSecond, firstWidth))
        return {
            gap = splitOptions.gap,
            available = available,
            first = { x = rect.x, width = firstWidth },
            second = {
                x = rect.x + firstWidth + splitOptions.gap,
                width = available - firstWidth,
            },
            minimumFirst = minimumFirst,
            maximumFirst = available - minimumSecond,
        }
    end,
}

local function buildLayoutWindow(ratio)
    local value = {
        uiScale = 1,
        baseBuildingLowerSplitRatio = ratio,
        baseBuildingCards = {},
        baseBuildingDetails = control(),
        baseBuildingMaterialPane = control(),
        baseBuildingNativeQueuePane = control(),
        baseBuildingLowerSplitDivider = divider(),
    }
    function value:layoutPane(pane, x, y, width, height)
        Layout.SetBounds(pane, x, y, width, height)
        pane:layoutContent()
    end
    return value
end

local panes = T.load("ProjectHoomans", "client",
    "PNC/UI/Base/PNC_BaseBuildingLayout_Panes.lua")
local firstWindow = buildLayoutWindow(0.66)
panes.Apply(firstWindow, { x = 0, y = 0, width = 1000, height = 800 },
    Layout, {
        gap = 8, width = 1000, cardsY = 0, detailsHeight = 100,
        lowerHeight = 300, cardsHeight = 100,
    })
T.truthy(firstWindow.baseBuildingMaterialPane.bounds.width
        > firstWindow.baseBuildingNativeQueuePane.bounds.width,
    "default facilities split did not give Requirements more room")
T.truthy(firstWindow.baseBuildingLowerSplitDivider.broughtToTop,
    "facilities splitter was not raised above the lower panes")
T.equal(firstWindow.baseBuildingLowerSplitDivider.minimum, 320,
    "facilities splitter did not apply the material minimum width")
T.equal(firstWindow.baseBuildingLowerSplitDivider.maximum, 772,
    "facilities splitter did not apply the queue minimum width")

local secondWindow = buildLayoutWindow(0.4)
panes.Apply(secondWindow, { x = 0, y = 0, width = 1000, height = 800 },
    Layout, {
        gap = 8, width = 1000, cardsY = 0, detailsHeight = 100,
        lowerHeight = 300, cardsHeight = 100,
    })
T.truthy(secondWindow.baseBuildingMaterialPane.bounds.width
        < firstWindow.baseBuildingMaterialPane.bounds.width,
    "changing the saved ratio did not resize Requirements")
T.truthy(secondWindow.baseBuildingNativeQueuePane.bounds.width
        > firstWindow.baseBuildingNativeQueuePane.bounds.width,
    "changing the saved ratio did not resize Blueprint Queue")

T.finish("pnc_base_facilities_search_split_smoke")
