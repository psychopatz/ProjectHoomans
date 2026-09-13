require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/Inventory/PNC_InventoryUI_List"

local Components = require
    "PNC/UI/Shared/PNC_ColonyUIComponents"
local Data = require "PNC/UI/Base/PNC_BaseBuildingData"
local Cards = require "PNC/UI/Base/PNC_BaseBuildingCards"
local Rows = require "PNC/UI/Base/PNC_BaseBuildingRows"
local LayoutModel = require "PNC/UI/Base/PNC_BaseBuildingLayout"
local BuildUI = require
    "PNC/UI/SettlementManagement/PNC_SettlementManagement_FacilityBuildModal"
local QueueOverlay = require
    "PNC/UI/Base/PNC_BaseBuildingQueueOverlay"
local QueueActions = require
    "PNC/UI/Base/PNC_BaseBuildingQueueActions"

local View = {}
local UI = PsychopatzCore.UI
local function tr(key, fallback)
    local value = getText and getText(key) or nil
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
    window.baseBuildCardOwner.setSelected = function(_, id)
        View.SetSelected(window, id)
    end
    window.baseBuildingSearch = UI.CreateTextEntry(window, {
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
        window.baseBuildingCloseButton,
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
        settlement, snapshot.storage, snapshot.research) or {}
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

return View
