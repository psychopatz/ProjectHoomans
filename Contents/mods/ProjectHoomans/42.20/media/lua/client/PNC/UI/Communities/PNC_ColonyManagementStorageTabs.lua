require "PNC/UI/Inventory/PNC_InventoryUI_List"

local StorageTabs = {}
local ViewModel = require "PNC/UI/Communities/PNC_ColonyStorageViewModel"
local ActivityPresentation = require "PNC/UI/Communities/PNC_ColonyStorageActivityPresentation"
local Components = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Components"
local SORT_LABEL_KEY = "UI_PNC_Storage_Sort"

local function drawActivityRow(list, y, entry, alternate)
    local item = entry.item or {}
    local UI = PsychopatzCore.UI
    local Theme = UI.Theme
    UI.DrawListSelection(list, y, list.itemheight, false, alternate)
    local timeWidth = Theme.TextWidth(UIFont.Small, item.time or "")
    local maximum = math.max(40, list:getWidth() - timeWidth - 28)
    list:drawText(UI.Layout.Ellipsize(item.message, UIFont.Small, maximum),
        8, y + 5, Theme.colors.text.r, Theme.colors.text.g,
        Theme.colors.text.b, Theme.colors.text.a, UIFont.Small)
    list:drawTextRight(item.time or "", list:getWidth() - 8, y + 5,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
    return y + list.itemheight
end

function StorageTabs.Create(window, UI, tr)
    window.storageSearch = UI.CreateTextEntry(window, {
        clearButton = true,
        width = 180,
        height = 26,
        onTextChange = function()
            window:rebuildDetails()
        end,
    })
    window.storageList = ISPNCInventoryList:new(0, 0, 100, 100, window, "storage")
    window.storageList:initialise()
    window.storageList:instantiate()
    window:addChild(window.storageList)
    window.storageActivityPane, window.storageActivityList =
        Components.CreatePane(window, 24, drawActivityRow)
    window.storageActivityPane:setHeader(
        tr("UI_PNC_Storage_RecentActivity", "RECENT ACTIVITY"), "10")
    window.storageSortButton = UI.CreateButton(window, {
        id = "sort",
        title = tr("UI_PNC_Storage_SortName", "Sort: Name"),
        target = window,
        onclick = window.onStorageControl,
        variant = "quiet",
    })
    window.storageTransferButton = UI.CreateButton(window, {
        id = "transfer",
        title = tr("UI_PNC_Storage_Manage", "Manage Inventory"),
        target = window,
        onclick = window.onStorageControl,
        variant = "primary",
    })
    window.storageDebugToggle = UI.CreateButton(window, {
        id = "debug_toggle",
        title = tr("UI_PNC_Storage_DebugTools", "Debug Tools") .. "  >",
        target = window,
        onclick = window.onStorageControl,
        variant = "quiet",
    })
    window.storageControls = {}
    local definitions = {
        { "add", "UI_PNC_Storage_AddTest", "Add Test Item" },
        { "remove", "UI_PNC_Storage_RemoveSelected", "Remove Selected" },
        { "clear", "UI_PNC_Storage_Clear", "Clear Storage" },
        { "fill", "UI_PNC_Storage_FillTest", "Fill Test Storage" },
        { "validate", "UI_PNC_Storage_Validate", "Validate" },
        { "compact", "UI_PNC_Storage_Compact", "Compact" },
        { "recalculate", "UI_PNC_Storage_Recalculate", "Recalculate Weight" },
        { "job_requirements_lumber", "UI_PNC_Storage_DebugForLumber",
            "Debug for Lumber" },
    }
    for _, definition in ipairs(definitions) do
        window.storageControls[#window.storageControls + 1] = UI.CreateButton(
            window,
            {
                id = definition[1],
                title = tr(definition[2], definition[3]),
                target = window,
                onclick = window.onStorageControl,
                variant = "quiet",
            }
        )
    end
end

function StorageTabs.Layout(window, Layout, content)
    local scale = window.uiScale
    local gap = Layout.Pixels(6, scale)
    local height = Layout.Pixels(28, scale)
    local sortWidth = Layout.Pixels(132, scale)
    local transferWidth = Layout.Pixels(150, scale)
    local debugWidth = Layout.Pixels(152, scale)
    local minimumSearch = Layout.Pixels(100, scale)
    local required = minimumSearch + sortWidth + transferWidth + debugWidth
        + gap * 3
    local compact = content.width < required
    local searchWidth
    if compact then
        searchWidth = math.max(minimumSearch,
            content.width - sortWidth - gap)
        Layout.SetBounds(window.storageSearch, content.x, content.y,
            searchWidth, height)
        Layout.SetBounds(window.storageSortButton,
            content.x + searchWidth + gap, content.y, sortWidth, height)
        local secondY = content.y + height + gap
        Layout.SetBounds(window.storageTransferButton,
            content.x, secondY, transferWidth, height)
        Layout.SetBounds(window.storageDebugToggle,
            content.x + content.width - debugWidth,
            secondY, debugWidth, height)
        window.layout.storageListY = secondY + height
            + Layout.Pixels(28, scale)
    else
        searchWidth = content.width - sortWidth - transferWidth
            - debugWidth - gap * 3
        Layout.SetBounds(window.storageSearch, content.x, content.y,
            searchWidth, height)
        Layout.SetBounds(window.storageSortButton,
            content.x + searchWidth + gap, content.y, sortWidth, height)
        Layout.SetBounds(window.storageTransferButton,
            content.x + searchWidth + sortWidth + gap * 2,
            content.y, transferWidth, height)
        Layout.SetBounds(window.storageDebugToggle,
            content.x + content.width - debugWidth,
            content.y, debugWidth, height)
        window.layout.storageListY = content.y + Layout.Pixels(56, scale)
    end
end

function StorageTabs.ApplyLayout(window, Layout, active)
    if not window.layout then return end
    active = active == true
    window.storageSearch:setVisible(active)
    window.storageList:setVisible(active)
    window.storageActivityPane:setVisible(active)
    window.storageSortButton:setVisible(active)
    local transferVisible = active and window.snapshot ~= nil
        and window.snapshot.storage ~= nil
    window.storageTransferButton:setVisible(transferVisible == true)
    if window.storageTransferButton.setEnable then
        local access = window.snapshot and window.snapshot.storage
            and window.snapshot.storage.access or nil
        window.storageTransferButton:setEnable(access
            and access.writable == true or false)
    end
    local debugVisible = active and window.snapshot ~= nil
        and window.snapshot.storage ~= nil
        and window.snapshot.storage.debugAuthorized == true
    debugVisible = debugVisible == true
    window.storageDebugToggle:setVisible(debugVisible)
    if not debugVisible then window.storageDebugExpanded = false end
    local drawerVisible = debugVisible == true
        and window.storageDebugExpanded == true
    for _, button in ipairs(window.storageControls or {}) do
        button:setVisible(drawerVisible == true)
        if button.internal == "job_requirements_lumber"
            and button.setEnable
        then
            button:setEnable(window.selectedPersonID ~= nil)
        end
    end
    if not active then return end
    local content = window.layout.content
    local scale = window.uiScale
    local gap = Layout.Pixels(12, scale)
    local bottom = content.y + content.height
    local compactDrawer = drawerVisible == true and Layout.IsCompact(
        content.width, Layout.Pixels(820, scale)) or false
    local listWidth = content.width
    if drawerVisible and not compactDrawer then
        local drawerWidth = math.max(Layout.Pixels(300, scale),
            math.floor((content.width - gap) * 0.36))
        listWidth = content.width - gap - drawerWidth
    end
    local availableHeight = bottom - window.layout.storageListY
    local showActivity = not compactDrawer
    window.storageActivityPane:setVisible(showActivity == true)
    local activityHeight = showActivity and math.min(
        Layout.Pixels(265, scale),
        math.max(Layout.Pixels(105, scale),
            availableHeight - Layout.Pixels(120, scale) - gap)) or 0
    local listHeight = availableHeight
        - (showActivity and activityHeight + gap or 0)
    if compactDrawer then
        listHeight = math.max(Layout.Pixels(110, scale),
            math.floor(listHeight * 0.48))
    end
    Layout.SetBounds(window.storageList, content.x,
        window.layout.storageListY, listWidth,
        math.max(Layout.Pixels(60, scale), listHeight))
    Components.LayoutScrollbar(window.storageList)
    if showActivity then
        window:layoutPane(window.storageActivityPane, content.x,
            window.layout.storageListY + listHeight + gap,
            listWidth, activityHeight)
    end
    window.detailsPane:setVisible(drawerVisible == true)
    if drawerVisible then
        local drawerX = compactDrawer and content.x
            or content.x + listWidth + gap
        local drawerWidth = compactDrawer and content.width
            or content.width - listWidth - gap
        local controlsY = compactDrawer
            and window.layout.storageListY + listHeight + gap
            or window.layout.storageListY
        local flow = Layout.Flow(window.storageControls,
            { x = drawerX, y = controlsY, width = drawerWidth },
            { scale = window.uiScale, minWidth = 104, gap = 5 })
        local detailsY = flow.bottom + Layout.Pixels(28, scale)
        window:layoutPane(window.detailsPane, drawerX, detailsY,
            drawerWidth, math.max(Layout.Pixels(40, scale),
                bottom - detailsY))
    end
end

function StorageTabs.OnControl(window, button, tr)
    local action = button and button.internal or ""
    if action == "transfer" then
        local storage = window.snapshot and window.snapshot.storage or nil
        if not storage then return false end
        if not PNC.InventoryWindow then
            require "PNC/UI/Inventory/PNC_InventoryWindow"
        end
        PNC.InventoryWindow.OpenStorage(storage.storageId, {
            displayName = tr("UI_PNC_Storage_Colony", "Colony Storage"),
            readOnly = not storage.access
                or storage.access.writable ~= true,
        })
        return true
    end
    if action == "debug_toggle" then
        window.storageDebugExpanded = window.storageDebugExpanded ~= true
        button:setTitle(tr("UI_PNC_Storage_DebugTools", "Debug Tools")
            .. (window.storageDebugExpanded and "  v" or "  >"))
        window:applyTabLayout()
        window:rebuildDetails()
        return
    end
    if action == "sort" then
        local order = { "name", "quantity", "weight" }
        local nextIndex = 1
        for index = 1, #order do
            if order[index] == window.storageSort then
                nextIndex = index % #order + 1
            end
        end
        window.storageSort = order[nextIndex]
        button:setTitle(tr(SORT_LABEL_KEY, "Sort") .. ": "
            .. string.upper(window.storageSort))
        window:rebuildDetails()
        return
    end
    local selected = window.storageList and window.storageList:selectedRow() or nil
    local debugAction = action
    local extra = {}
    if action == "job_requirements_lumber" then
        debugAction = "job_requirements"
        extra.operation = "LUMBER"
        extra.target = "worker"
        extra.npcId = window.selectedPersonID
    end
    PNC.Client.RequestColonyAction("storage_debug", {
        storageId = window.snapshot and window.snapshot.storage
            and window.snapshot.storage.storageId,
        debugAction = debugAction,
        operation = extra.operation,
        target = extra.target,
        npcId = extra.npcId,
        recordIndex = selected and selected.recordIndex,
        fullType = "Base.Nails",
        quantity = action == "remove" and selected
            and math.max(1, math.floor(tonumber(selected.stack) or 1)) or 100,
        search = window.storageSearch:getText(),
        sort = window.storageSort,
    })
end

local function rebuildStorage(window, snapshot)
    local storage = snapshot.storage
    if not storage then
        window.storageList:addItem("Storage unavailable", {
            name = "Storage unavailable",
            category = "No faction stockpile",
            stack = 1,
            restricted = true,
        })
        return
    end
    if storage.debugAuthorized == true and window.storageDebugExpanded == true then
        window:addDetail("STORAGE ID", tostring(storage.storageId), "accent")
        window:addDetail("OWNER FACTION", tostring(storage.ownerFactionId))
        window:addDetail("REVISION", string.format("Storage %d  |  Inventory %d",
            storage.revision or 0, storage.inventoryRevision or 0))
        window:addDetail("RECORDS", string.format(
            "Logical %d  |  Serialized %d  |  Batches %d  |  Unique %d",
            storage.logicalItemCount or 0,
            storage.serializedRecordCount or 0,
            storage.batchCount or 0,
            storage.uniqueRecordCount or 0))
        local result = snapshot.actionResult
        if result and (result.reason == "valid" or result.reason == "invalid") then
            window:addDetail("VALIDATION", string.upper(result.reason),
                result.ok and "success" or "danger")
        end
    end
    local rows = ViewModel.BuildInventoryRows(storage,
        window.storageSearch:getText(), window.storageSort,
        window.storageCollapsedGroups)
    if #rows == 0 then
        window.storageList:addItem("No items stored", {
            name = "No items stored",
            category = "Deposit from an inventory",
            stack = 1,
            restricted = true,
        })
        return
    end
    for _, row in ipairs(rows) do
        window.storageList:addItem(row.name, row)
    end
end

local function rebuildActivity(window, storage, tr)
    Components.SetRows(window.storageActivityList, {})
    local rows = ActivityPresentation.Rows(storage and storage.activity or {})
    if #rows == 0 then
        rows[1] = {
            message = tr("UI_PNC_Storage_NoActivity",
                "No inventory activity yet"),
            time = "",
        }
    end
    window.storageActivityPane:setHeader(
        tr("UI_PNC_Storage_RecentActivity", "RECENT ACTIVITY"),
        tostring(storage and #(storage.activity or {}) or 0))
    Components.SetRows(window.storageActivityList, rows)
end

function StorageTabs.Rebuild(window, snapshot, tr)
    if window.tab == "storage" then
        rebuildStorage(window, snapshot)
        rebuildActivity(window, snapshot.storage, tr)
        return true
    end
    return false
end

function StorageTabs.RenderSummary(window, Theme)
    local storage = window.snapshot and window.snapshot.storage or nil
    if window.tab ~= "storage" or not storage then return end
    local summary = window.layout.summary
    window:drawTextRight(
        string.format("TIER %d  |  %.1f / %.1f  |  FREE %.1f%s",
            storage.tier or 1, storage.usedWeight or 0,
            storage.capacity or 0, storage.freeWeight or 0,
            storage.overCapacity and "  OVER CAPACITY" or ""),
        summary.x + summary.width - 14, summary.y + summary.height - 23,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
end

return StorageTabs
