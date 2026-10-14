require "PNC/UI/Inventory/PNC_InventoryUI_List"
local Settings = require "PsychopatzCore/Settings/PsychopatzSettings"

local Workshop = {}
local Theme = PsychopatzCore and PsychopatzCore.UI
    and PsychopatzCore.UI.Theme or {}
local Components = require "PNC/UI/Shared/PNC_ColonyUIComponents"
local GroupState = require "PNC/UI/Workshop/PNC_WorkshopGroupState"
local Rebuild = require
    "PNC/UI/Workshop/PNC_WorkshopCatalog_Rebuild"
local DEFAULT_SPLIT_RATIO = 0.34
local MINIMUM_QUEUE_WIDTH = 250
local MINIMUM_CATALOG_WIDTH = 480
local SPLITTER_HIT_WIDTH = 16
local SEARCH_ROW_HEIGHT = 32
local CATALOG_HEADER_HEIGHT = 32
local SEARCH_CONTROL_GAP = 6
local SEARCH_CONTROL_WIDTH = 112
local SPLIT_STORE = Settings.Open("ProjectHoomansWorkshopUI", {
    fileName = "ProjectHoomans_WorkshopUI.txt",
    defaults = {
        workshopSplitRatio = DEFAULT_SPLIT_RATIO,
        workshopCollapsedGroups = "",
    },
})
local CATALOG_COLUMNS = {
    { key = "category", x = 0.40 }, { key = "quantity", x = 0.57 },
    { key = "availability", x = 0.70 }, { key = "action", x = 0.82 },
}
local QUEUE_COLUMNS = {
    { key = "worker", x = 0.50 }, { key = "progress", x = 0.72 },
}

local function makeList(window, role, columns, controlCallback)
    local list = ISPNCInventoryList:new(0, 0, 100, 100, window, role)
    list.selectOnly, list.catalogColumns = true, columns
    list.onCatalogControl = controlCallback
    list:initialise(); list:instantiate(); window:addChild(list)
    return list
end

local function button(window, UIBuilder, id, key, variant)
    return UIBuilder.CreateButton(window, { id = id, title = PNC.Translation.GetKey(key),
        target = window, onclick = window.onWorkshopControl,
        variant = variant })
end

local function loadSplitRatio()
    if SPLIT_STORE and not SPLIT_STORE.loaded then SPLIT_STORE:Load() end
    local value = SPLIT_STORE and SPLIT_STORE:Get("workshopSplitRatio",
        DEFAULT_SPLIT_RATIO) or DEFAULT_SPLIT_RATIO
    return math.max(0.2, math.min(0.7, tonumber(value)
        or DEFAULT_SPLIT_RATIO))
end

local function saveSplitRatio(value)
    if not SPLIT_STORE then return end
    SPLIT_STORE:Set("workshopSplitRatio", math.max(0.2,
        math.min(0.7, tonumber(value) or DEFAULT_SPLIT_RATIO)), true)
end

local function loadCollapsedGroups()
    return GroupState.Load(SPLIT_STORE)
end

local function saveCollapsedGroups(groups)
    GroupState.Save(SPLIT_STORE, groups)
end

function Workshop.Create(window, UIBuilder)
    window.workshopQuantities = window.workshopQuantities or {}
    window.workshopCollapsedGroups = window.workshopCollapsedGroups
        or loadCollapsedGroups()
    window.workshopSubtab = window.workshopSubtab or "craft"
    window.workshopSplitRatio = window.workshopSplitRatio
        or loadSplitRatio()
    window.workshopQueueColumnState = Components.CreateCatalogColumnState({
        namespace = "ProjectHoomansWorkshopUI",
        fileName = "ProjectHoomans_WorkshopUI.txt",
        key = "queueColumns",
        columns = QUEUE_COLUMNS,
    })
    window.workshopCatalogColumnState = Components.CreateCatalogColumnState({
        namespace = "ProjectHoomansWorkshopUI",
        fileName = "ProjectHoomans_WorkshopUI.txt",
        key = "catalogColumns",
        columns = CATALOG_COLUMNS,
    })
    window.workshopQueueColumns = window.workshopQueueColumnState.columns
    window.workshopCatalogColumns = window.workshopCatalogColumnState.columns
    window.workshopQueueList = makeList(window, "workshop_queue",
        window.workshopQueueColumns)
    window.workshopRecipeList = makeList(window, "workshop_recipe",
        window.workshopCatalogColumns, Workshop.OnCatalogControl)
    window.workshopSalvageList = makeList(window, "workshop_salvage",
        window.workshopCatalogColumns, Workshop.OnCatalogControl)
    window.workshopStockpileList = window.workshopSalvageList
    window.workshopQueueHeader = Components.CreateCatalogHeader(window,
        window.workshopQueueColumns, {
            lists = { window.workshopQueueList },
            minWidths = { 120, 100, 100 },
            onColumnResizeEnd = function()
                window.workshopQueueColumnState:save()
            end,
        })
    window.workshopRecipeHeader = Components.CreateCatalogHeader(window,
        window.workshopCatalogColumns, {
            lists = { window.workshopRecipeList, window.workshopSalvageList },
            minWidths = { 150, 80, 45, 95, 95 },
            onColumnResizeEnd = function()
                window.workshopCatalogColumnState:save()
            end,
        })
    window.workshopSalvageHeader = Components.CreateCatalogHeader(window,
        window.workshopCatalogColumns, {
            lists = { window.workshopRecipeList, window.workshopSalvageList },
            minWidths = { 150, 80, 45, 95, 95 },
            onColumnResizeEnd = function()
                window.workshopCatalogColumnState:save()
            end,
        })
    window.workshopCraftTab = button(window, UIBuilder, "tab_craft",
        "UI_PNC_Workshop_CraftingTab")
    window.workshopSalvageTab = button(window, UIBuilder, "tab_salvage",
        "UI_PNC_Workshop_SalvageTab")
    window.workshopSearch = UIBuilder.CreateSearchEntry(window, {
        clearButton = true,
        tooltip = PNC.Translation.GetKey("UI_PNC_Search", "Search catalog"),
        onTextChange = function()
            window:rebuildDetails()
        end,
    })
    window.workshopCollapseAll = button(window, UIBuilder, "collapse_all",
        "UI_PNC_Workshop_CollapseAll", "quiet")
    window.workshopExpandAll = button(window, UIBuilder, "expand_all",
        "UI_PNC_Workshop_ExpandAll", "quiet")
    window.workshopPause = button(window, UIBuilder, "pause",
        "UI_PNC_Work_Pause", "warning")
    window.workshopCancel = button(window, UIBuilder, "cancel",
        "UI_PNC_Work_Cancel", "warning")
    window.workshopSplitDivider = UIBuilder.CreateResizableDivider(window, {
        width = 8,
        value = 0,
        drawIndicator = true,
        onChange = function(value)
            local available = tonumber(window.workshopSplitAvailableWidth) or 1
            window.workshopSplitRatio = math.max(0.2, math.min(0.7,
                tonumber(value) / available))
            -- The divider changes pane geometry while the pointer is
            -- captured. Mark the host dirty and let the normal responsive
            -- pass perform one layout for the current input frame. Forcing a
            -- full pass from every mouse delta caused visible flicker and
            -- made the long catalog repaint far more often than necessary.
            window:invalidateLayout("workshop_split_drag")
            window:requestResponsiveLayout(false)
        end,
        onRelease = function()
            saveSplitRatio(window.workshopSplitRatio)
        end,
    })
end

function Workshop.Layout(window, Layout, content)
    local split = Layout.HorizontalSplit(content, {
        gap = 8,
        firstRatio = window.workshopSplitRatio or DEFAULT_SPLIT_RATIO,
        minFirst = MINIMUM_QUEUE_WIDTH,
        minSecond = MINIMUM_CATALOG_WIDTH,
    })
    local left, right, gap = split.first.width, split.second.width,
        split.gap
    window.workshopSplitAvailableWidth = split.available
    window.workshopSplitRatio = split.first.width / split.available
    local halfLeft = math.floor((left - 6) / 2)
    Layout.SetBounds(window.workshopPause, content.x, content.y, halfLeft, 27)
    Layout.SetBounds(window.workshopCancel, content.x + halfLeft + 6,
        content.y, left - halfLeft - 6, 27)
    local rightX = content.x + left + gap
    local halfRight = math.floor((right - 6) / 2)
    Layout.SetBounds(window.workshopCraftTab, rightX, content.y, halfRight, 27)
    Layout.SetBounds(window.workshopSalvageTab, rightX + halfRight + 6,
        content.y, right - halfRight - 6, 27)
    local top, height = content.y + 34, math.max(1, content.height - 34)
    local headerTop = top + SEARCH_ROW_HEIGHT
    local listTop = headerTop + CATALOG_HEADER_HEIGHT
    local listHeight = math.max(1, height - SEARCH_ROW_HEIGHT
        - CATALOG_HEADER_HEIGHT)
    local controlWidth = math.min(SEARCH_CONTROL_WIDTH,
        math.max(80, math.floor((right - SEARCH_CONTROL_GAP) / 3)))
    local searchWidth = math.max(120, right - controlWidth * 2
        - SEARCH_CONTROL_GAP * 2)
    Layout.SetBounds(window.workshopSearch, rightX, top, searchWidth, 27)
    local collapseX = rightX + searchWidth + SEARCH_CONTROL_GAP
    Layout.SetBounds(window.workshopCollapseAll, collapseX, top,
        controlWidth, 27)
    Layout.SetBounds(window.workshopExpandAll,
        collapseX + controlWidth + SEARCH_CONTROL_GAP, top,
        controlWidth, 27)
    Layout.SetBounds(window.workshopQueueHeader, content.x, headerTop, left,
        CATALOG_HEADER_HEIGHT)
    Layout.SetBounds(window.workshopRecipeHeader, rightX, headerTop, right,
        CATALOG_HEADER_HEIGHT)
    Layout.SetBounds(window.workshopSalvageHeader, rightX, headerTop, right,
        CATALOG_HEADER_HEIGHT)
    Layout.SetBounds(window.workshopQueueList, content.x, listTop, left,
        listHeight)
    Layout.SetBounds(window.workshopRecipeList, rightX, listTop, right,
        listHeight)
    Layout.SetBounds(window.workshopSalvageList, rightX, listTop, right,
        listHeight)
    window.workshopQueueHeader:layoutSplitters()
    window.workshopRecipeHeader:layoutSplitters()
    window.workshopSalvageHeader:layoutSplitters()
    if window.workshopSplitDivider then
        -- Keep the visual line centered in the pane gap, while extending the
        -- native hit target over both adjacent list edges. This matches the
        -- base game's column splitter, where the draggable edge is easier to
        -- acquire than the one-pixel line that is rendered.
        local hitWidth = math.max(SPLITTER_HIT_WIDTH, gap)
        Layout.SetBounds(window.workshopSplitDivider,
            content.x + left + math.floor((gap - hitWidth) / 2), top,
            hitWidth, height)
        window.workshopSplitDivider:setRange(split.minimumFirst,
            split.maximumFirst)
        window.workshopSplitDivider:setValue(left, true)
        window.workshopSplitDivider:bringToTop()
    end
end

function Workshop.RenderSplitter(window)
    local divider = window and window.workshopSplitDivider or nil
    if not divider or not divider:getIsVisible() then return end
    local width = divider:getWidth()
    local lineWidth = math.min(3, math.max(2, width))
    local lineX = math.floor(divider:getX() + (width - lineWidth) / 2)
    local color = Theme.colors.borderStrong or Theme.colors.border
        or Theme.colors.textMuted
    local alpha = 0.95
    if divider.mouseOverResize or divider.dragging then
        color = Theme.colors.accent
        alpha = divider.dragging and 1 or 0.95
    end
    window:drawRectStatic(lineX, divider:getY(), lineWidth,
        divider:getHeight(), alpha, color.r, color.g, color.b)
end

function Workshop.Apply(window, active)
    window.workshopPause:setVisible(active)
    window.workshopCancel:setVisible(active)
    window.workshopCraftTab:setVisible(active)
    window.workshopSalvageTab:setVisible(active)
    window.workshopQueueList:setVisible(active)
    window.workshopQueueHeader:setVisible(active)
    window.workshopSearch:setVisible(active)
    window.workshopCollapseAll:setVisible(active)
    window.workshopExpandAll:setVisible(active)
    window.workshopRecipeHeader:setVisible(active
        and window.workshopSubtab == "craft")
    window.workshopSalvageHeader:setVisible(active
        and window.workshopSubtab == "salvage")
    if window.workshopSplitDivider then
        window.workshopSplitDivider:setVisible(active)
    end
    if active then window.detailsPane:setVisible(false) end
    Rebuild.ApplySubtab(window, active)
end

function Workshop.Rebuild(window, snapshot, tr)
    window.workshopQueueHeader:setContent(
        tr("UI_PNC_Workshop_ProductionQueue", "PRODUCTION QUEUE"),
        { worker = "WORKER", progress = "PROGRESS" },
        window.workshopQueueColumns)
    window.workshopRecipeHeader:setContent(
        tr("UI_PNC_Workshop_Craftable", "CRAFTABLE ITEMS"),
        { category = "CATEGORY", quantity = "COUNT",
            availability = "STOCK", action = "ACTION" },
        window.workshopCatalogColumns)
    window.workshopSalvageHeader:setContent(
        tr("UI_PNC_Workshop_Salvageable", "SALVAGEABLE ITEMS"),
        { category = "CATEGORY", quantity = "COUNT",
            availability = tr("UI_PNC_Workshop_PotentialYield", "YIELD"),
            action = "ACTION" }, window.workshopCatalogColumns)
    return Rebuild.Build(window, snapshot, tr)
end

function Workshop.OnCatalogControl(window, row, key, control)
    return Rebuild.OnCatalogControl(window, row, key, control)
end

local function setAllGroups(window, collapsed)
    window.workshopCollapsedGroups = window.workshopCollapsedGroups or {}
    local known = window.workshopKnownGroupKeys or {}
    for key in pairs(known) do
        window.workshopCollapsedGroups[key] = collapsed == true
    end
    saveCollapsedGroups(window.workshopCollapsedGroups)
    window:rebuildDetails()
    return true
end

function Workshop.SaveCollapsedGroups(window)
    saveCollapsedGroups(window and window.workshopCollapsedGroups or {})
end

function Workshop.OnControl(window, buttonValue)
    local action = tostring(buttonValue and buttonValue.internal or "")
    if action == "collapse_all" then return setAllGroups(window, true) end
    if action == "expand_all" then return setAllGroups(window, false) end
    return Rebuild.OnControl(window, buttonValue)
end

return Workshop
