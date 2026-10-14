require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/Inventory/PNC_InventoryUI_List"
local Settings = require "PsychopatzCore/Settings/PsychopatzSettings"

local Components = require
    "PNC/UI/Shared/PNC_ColonyUIComponents"
local Data = require "PNC/UI/Base/PNC_BaseBuildingData"
local Cards = require "PNC/UI/Base/PNC_BaseBuildingCards"
local Rows = require "PNC/UI/Base/PNC_BaseBuildingRows"
local LayoutModel = require "PNC/UI/Base/PNC_BaseBuildingLayout"
local BuildUI = require "PNC/UI/Shared/PNC_FacilityBuildProvider"
local QueueOverlay = require
    "PNC/UI/Base/PNC_BaseBuildingQueueOverlay"
local QueueActions = require
    "PNC/UI/Base/PNC_BaseBuildingQueueActions"
local FacilityBuildTarget = require
    "PNC/UI/Shared/PNC_FacilityBuildTarget"

local View = {}
local UI = PsychopatzCore.UI
local DEFAULT_LOWER_SPLIT_RATIO = 0.66
local SPLITTER_HIT_WIDTH = 16
local SPLIT_STORE = Settings.Open("ProjectHoomansBaseBuildingUI", {
    fileName = "ProjectHoomans_BaseBuildingUI.txt",
    defaults = { facilityLowerSplitRatio = DEFAULT_LOWER_SPLIT_RATIO },
})

local function loadLowerSplitRatio()
    if not SPLIT_STORE.loaded then SPLIT_STORE:Load() end
    local value = SPLIT_STORE:Get("facilityLowerSplitRatio",
        DEFAULT_LOWER_SPLIT_RATIO)
    return math.max(0.2, math.min(0.8,
        tonumber(value) or DEFAULT_LOWER_SPLIT_RATIO))
end

local function saveLowerSplitRatio(value)
    SPLIT_STORE:Set("facilityLowerSplitRatio", math.max(0.2,
        math.min(0.8, tonumber(value) or DEFAULT_LOWER_SPLIT_RATIO)), true)
end
local function tr(key, fallback)
    local value = getText and PNC.Translation.GetKey(key) or nil
    if not value or value == key then return fallback end
    return value
end

local function canUseDebug()
    return PNC.Client and PNC.Client.CanUseDebug
        and PNC.Client.CanUseDebug() == true
end

function View.SetSelected(window, id)
    window.baseBuildingSelectedID = id
    window.baseBuildCardOwner.selectedId = id
    local option = Data.SelectedOption(window)
    Components.SetRowsStable(window.baseBuildingMaterialList,
        Data.MaterialRows(window, option))
    if window.baseBuildingBuildButton then
        window.baseBuildingBuildButton:setEnable(option ~= nil
            and option.enabled == true)
    end
    if window.baseBuildingDebugButton then
        window.baseBuildingDebugButton:setEnable(canUseDebug() and option ~= nil)
    end
end

local function rebuildNativeQueue(window, snapshot)
    local rows = Data.NativeQueueRows(snapshot)
    for _, row in ipairs(rows) do
        row.actionLabel = QueueActions.ActionLabel(window, row.order)
    end
    Components.SetRowsStable(window.baseBuildingNativeQueue, rows)
    window.baseBuildingNativeQueue.selected = #rows > 0 and 1 or 0
    window.baseBuildingNativeQueueSelectedID = rows[1] and rows[1].id or nil
end

function View.Create(window)
    Cards.Create(window)
    window.baseBuildingLowerSplitRatio = loadLowerSplitRatio()
    window.baseBuildCardOwner.setSelected = function(_, id)
        View.SetSelected(window, id)
    end
    window.baseBuildingSearch = UI.CreateSearchEntry(window, {
        clearButton = true, width = 1, height = 1,
        onTextChange = function()
            View.Rebuild(window, window.snapshot or {})
            window:requestResponsiveLayout(true)
        end,
    })
    window.baseBuildingMaterialPane, window.baseBuildingMaterialList =
        Components.CreatePane(window, 42, Rows.Material)
    window.baseBuildingNativeQueuePane, window.baseBuildingNativeQueue =
        Components.CreatePane(window, 42, Rows.NativeQueue)
    window.baseBuildingLowerSplitDivider = UI.CreateResizableDivider(window, {
        width = SPLITTER_HIT_WIDTH,
        value = 0,
        drawIndicator = true,
        onChange = function(value)
            local available = tonumber(window.baseBuildingLowerSplitAvailable)
                or 1
            window.baseBuildingLowerSplitRatio = math.max(0.2, math.min(0.8,
                (tonumber(value) or 0) / available))
            window:invalidateLayout("base_facilities_split_drag")
            window:requestResponsiveLayout(false)
        end,
        onRelease = function()
            saveLowerSplitRatio(window.baseBuildingLowerSplitRatio)
        end,
    })
    window.baseBuildingBuildButton = UI.CreateButton(window, {
        id = "build_selected", title = tr("UI_PNC_Facility_BuildConfirm", "BUILD"),
        target = window, onclick = window.onBaseBuildingControl,
        variant = "success",
    })
    window.baseBuildingDebugButton = UI.CreateButton(window, {
        id = "debug_materials",
        title = tr("UI_PNC_Facility_DebugGiveMaterials", "GIVE MATERIALS"),
        target = window, onclick = window.onBaseBuildingControl,
        variant = "warning",
    })
    window.baseBuildingPlaceButton = UI.CreateButton(window, {
        id = "place", title = tr("UI_PNC_Base_PlaceBlueprint",
            "PLACE BLUEPRINT"),
        target = window, onclick = window.onBaseBuildingControl,
        variant = "accent",
    })
    window.baseBuildingCancelPlacement = UI.CreateButton(window, {
        id = "cancel_placement", title = tr("UI_PNC_Base_CancelPlacement",
            "CANCEL PLACEMENT"),
        target = window, onclick = window.onBaseBuildingControl,
        variant = "warning",
    })
    window.baseBuildingQueueOverlay = UI.CreateButton(window, {
        id = "toggle_queue_overlay", title = tr("UI_PNC_Base_ShowQueueOverlay",
            "SHOW QUEUE OVERLAY"),
        target = window, onclick = window.onBaseBuildingControl,
        variant = "quiet",
    })
    window.baseBuildingCancelOrder = UI.CreateButton(window, {
        id = "cancel_order", title = tr("UI_PNC_Building_CancelOrder",
            "CANCEL ORDER"),
        target = window, onclick = window.onBaseBuildingControl,
        variant = "warning",
    })
    window.baseBuildingCloseButton = UI.CreateButton(window, {
        id = "close_building", title = tr("UI_PNC_Base_Cancel", "CANCEL"),
        target = window, onclick = window.onBaseBuildingControl,
        variant = "danger",
    })
    window.baseBuildingPrevious = UI.CreateButton(window, {
        id = "page_previous", title = "<", target = window,
        onclick = window.onBaseBuildingControl, variant = "quiet",
    })
    window.baseBuildingNext = UI.CreateButton(window, {
        id = "page_next", title = ">", target = window,
        onclick = window.onBaseBuildingControl, variant = "quiet",
    })
    window.baseBuildingNativeQueue.onMouseDown = function(list, x, y)
        if ISScrollingListBox and ISScrollingListBox.onMouseDown then
            ISScrollingListBox.onMouseDown(list, x, y)
        end
        local rowIndex = list:rowAt(x, y)
        local entry = rowIndex > 0 and list.items[rowIndex] or nil
        local row = entry and entry.item or nil
        if row then
            list.selected = rowIndex
            window.baseBuildingNativeQueueSelectedID = row.id
            if x >= list:getWidth() - 120
                and PNC.Client and PNC.Client.RequestColonyAction
            then
                QueueActions.RequestCancel(window, row.order)
            end
        end
        return true
    end
end

function View.Layout(window, content)
    LayoutModel.Apply(window, content)
end

function View.Apply(window, active)
    local controls = {
        window.baseBuildingDetails, window.baseBuildingMaterialPane,
        window.baseBuildingNativeQueuePane, window.baseBuildingBuildButton,
        window.baseBuildingDebugButton, window.baseBuildingPlaceButton,
        window.baseBuildingCancelPlacement, window.baseBuildingQueueOverlay,
        window.baseBuildingCancelOrder, window.baseBuildingSearch,
        window.baseBuildingPrevious, window.baseBuildingNext,
        window.baseBuildingCloseButton, window.baseBuildingLowerSplitDivider,
    }
    for _, control in ipairs(controls) do control:setVisible(active) end
    for _, button in ipairs(window.baseBuildingCategoryButtons or {}) do
        button:setVisible(active and button.baseCategoryVisible ~= false)
    end
    -- Facility cards are real child panels. Hide them when the integrated
    -- Buildings catalog becomes active so an old Facilities projection cannot
    -- sit above the recipe list and consume its mouse input.
    if not active then
        for _, card in ipairs(window.baseBuildingCards or {}) do
            card:setVisible(false)
        end
    end
    local debug = canUseDebug()
    window.baseBuildingDebugButton:setVisible(active and debug)
    -- BUILD enters the existing placement protocol. Keep the legacy duplicate
    -- action out of the footer so this tab follows the reference layout.
    window.baseBuildingPlaceButton:setVisible(false)
    window.baseBuildingCancelPlacement:setVisible(active
        and window.buildPlacement ~= nil)
    window.baseBuildingQueueOverlay:setTitle(QueueOverlay.IsEnabled()
        and tr("UI_PNC_Base_HideQueueOverlay", "HIDE QUEUE OVERLAY")
        or tr("UI_PNC_Base_ShowQueueOverlay", "SHOW QUEUE OVERLAY"))
    window.baseBuildingCancelOrder:setVisible(false)
    window.baseBuildingCloseButton:setVisible(active)
    local option = Data.SelectedOption(window)
    window.baseBuildingBuildButton:setEnable(active and option ~= nil
        and option.enabled == true)
    window.baseBuildingDebugButton:setEnable(debug and option ~= nil)
end

function View.Rebuild(window, snapshot)
    snapshot = snapshot or window.snapshot or {}
    window.snapshot = snapshot
    local settlement = snapshot.settlement
    QueueActions.Reconcile(window, snapshot,
        snapshot.building and snapshot.building.queue or {})
    QueueOverlay.SetQueue(snapshot.building and snapshot.building.queue or {})
    local allOptions = settlement and BuildUI.BuildOptions(
        settlement, Data.Stockpile(window, snapshot),
        Data.Research(window, snapshot)) or {}
    window.baseBuildingOptions = Data.CatalogOptions(allOptions,
        window.baseBuildingCatalogKind or "buildings")
    Cards.RebuildCategories(window)
    Cards.Rebuild(window, function(id) View.SetSelected(window, id) end)
    Components.SetRowsStable(window.baseBuildingMaterialList,
        Data.MaterialRows(window, Data.SelectedOption(window)))
    window.baseBuildingMaterialPane:setHeader(
        tr("UI_PNC_Base_Requirements", "REQUIREMENTS"), "")
    rebuildNativeQueue(window, snapshot)
    window.baseBuildingNativeQueuePane:setHeader(
        tr("UI_PNC_Base_BlueprintQueue", "BLUEPRINT QUEUE"),
        tostring(#(snapshot.building and snapshot.building.queue or {})))
    return true
end

function View.Focus(window, id, objectInfoName)
    local wanted = tostring(id or "")
    if wanted == "" then return false end
    local target
    for _, option in ipairs(window.baseBuildingOptions or {}) do
        if FacilityBuildTarget.MatchesOption(option, wanted, objectInfoName) then
            target = option
            break
        end
    end
    -- Base can already be open with the same search text from a previous
    -- station request. Rebuild once so the active search can materialize
    -- compatibility definitions before giving up on the focus request.
    if not target then
        View.Rebuild(window, window.snapshot or {})
        for _, option in ipairs(window.baseBuildingOptions or {}) do
            if FacilityBuildTarget.MatchesOption(option, wanted,
                objectInfoName)
            then
                target = option
                break
            end
        end
    end
    if not target then return false end

    -- Put the focused facility on the visible category and page before the
    -- cards are rebuilt. Selecting an off-page id alone leaves the first page
    -- visible, which made a successful focus request look like a no-op.
    window.baseBuildingCategory = target.category
    local filtered = Data.FilteredOptions(window)
    for index, option in ipairs(filtered) do
        if FacilityBuildTarget.MatchesOption(option, wanted, objectInfoName) then
            window.baseBuildingPage = math.ceil(index / Data.PAGE_SIZE)
            break
        end
    end
    View.Rebuild(window, window.snapshot or {})
    View.SetSelected(window, target.id)
    return true
end

return View
