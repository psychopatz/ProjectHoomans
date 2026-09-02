require "PNC/UI/Inventory/PNC_InventoryUI_List"

local Controller = {}
local Shared = require
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
local Components = require
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Components"
local Presentation = require "PNC/UI/Storage/PNC_StoragePresentation"
local LayoutModule = require "PNC/UI/Storage/PNC_StorageLayout"
local Client = require "PNC/UI/Storage/PNC_StorageClient"

local SORT_LABEL_KEY = "UI_PNC_Storage_Sort"

local function tr(key, fallback)
    return Shared.Tr(key, fallback)
end

function Controller.CreateChildren(window)
    local UI = PsychopatzCore.UI
    window.tab = "storage"
    window.storageSort = "name"
    window.storageCollapsedGroups = {}
    window.storageDebugExpanded = false
    window.snapshot = window.snapshot or {}
    window.lastReceiveRevision = 0
    window.lastReceiveAt = 0
    window.lastRequestAt = 0

    window.detailsPane, window.details = Components.CreateDetailPane(window)
    window.detailsPane:setHeader(tr("UI_PNC_Storage_DebugTools",
        "DEBUG TOOLS"), "")
    window.detailsPane:setVisible(false)

    window.storageSearch = UI.CreateTextEntry(window, {
        clearButton = true,
        width = 180,
        height = 26,
        onTextChange = function() window:rebuild() end,
    })
    window.storageList = ISPNCInventoryList:new(0, 0, 100, 100,
        window, "storage")
    window.storageList:initialise()
    window.storageList:instantiate()
    window:addChild(window.storageList)
    window.storageActivityPane, window.storageActivityList =
        Components.CreatePane(window, 24, Presentation.DrawActivityRow)
    window.storageActivityPane:setHeader(
        tr("UI_PNC_Storage_RecentActivity", "RECENT ACTIVITY"), "0")

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
            window, {
                id = definition[1],
                title = tr(definition[2], definition[3]),
                target = window,
                onclick = window.onStorageControl,
                variant = "quiet",
            })
    end
end

function Controller.ApplyResponsiveLayout(window)
    local Layout = PsychopatzCore.UI.Layout
    local rect = window:getContentRect({ top = 28, bottom = 12 })
    local summaryHeight = Layout.Pixels(64, window.uiScale)
    local contentY = rect.y + summaryHeight + Layout.Pixels(10,
        window.uiScale)
    window.layout = {
        summary = { x = rect.x, y = rect.y,
            width = rect.width, height = summaryHeight },
        content = { x = rect.x, y = contentY, width = rect.width,
            height = math.max(100, rect.y + rect.height - contentY) },
    }
    LayoutModule.Measure(window, window.layout.content)
    LayoutModule.Apply(window, true)
end

function Controller.ApplyContentStyle(window)
    local Options = require "PsychopatzCore/UI/PsychopatzCommandHubOptions"
    local signature = Options.GetContentOpacitySignature()
    if window.lastContentOpacitySignature == signature then return end
    Options.ApplySurfaceOpacity(window.storageList, "detail")
    Options.ApplySurfaceOpacity(window.storageActivityList, "detail")
    Options.ApplySurfaceOpacity(window.details, "detail")
    window.contentOpacity = Options.GetContentOpacity("detail")
    window.lastContentOpacitySignature = signature
end

function Controller.AddDetail(window, label, detail, colorName)
    local PresentationBase = require
        "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Presentation"
    Components.AddRow(window.details,
        PresentationBase.Detail(label, detail, colorName))
end

function Controller.ToggleInventoryGroup(window, role, groupKey)
    if role ~= "storage" or not groupKey then return false end
    window.storageCollapsedGroups[groupKey] =
        window.storageCollapsedGroups[groupKey] ~= true
    window:rebuild()
    return true
end

local function rebuildStorage(window, snapshot)
    local storage = snapshot.storage
    if not storage then
        window.storageList:addItem(tr("UI_PNC_Storage_Unavailable",
            "Storage unavailable"), {
                name = tr("UI_PNC_Storage_Unavailable", "Storage unavailable"),
                category = tr("UI_PNC_Storage_NoStockpile",
                    "No faction stockpile"),
                stack = 1,
                restricted = true,
            })
        return
    end

    if storage.debugAuthorized == true
        and window.storageDebugExpanded == true
    then
        window:addDetail("STORAGE ID", tostring(storage.storageId), "accent")
        window:addDetail("OWNER FACTION", tostring(storage.ownerFactionId))
        window:addDetail("REVISION", string.format(
            "Storage %d  |  Inventory %d", storage.revision or 0,
            storage.inventoryRevision or 0))
        window:addDetail("RECORDS", string.format(
            "Logical %d  |  Serialized %d  |  Batches %d  |  Unique %d",
            storage.logicalItemCount or 0, storage.serializedRecordCount or 0,
            storage.batchCount or 0, storage.uniqueRecordCount or 0))
        local result = snapshot.actionResult
        if result and (result.reason == "valid" or result.reason == "invalid") then
            window:addDetail("VALIDATION", string.upper(result.reason),
                result.ok and "success" or "danger")
        end
    end

    local rows = Presentation.BuildInventoryRows(storage,
        window.storageSearch:getText(), window.storageSort,
        window.storageCollapsedGroups)
    if #rows == 0 then
        window.storageList:addItem(tr("UI_PNC_Storage_Empty",
            "No items stored"), {
                name = tr("UI_PNC_Storage_Empty", "No items stored"),
                category = tr("UI_PNC_Storage_DepositHint",
                    "Deposit from an inventory"),
                stack = 1,
                restricted = true,
            })
        return
    end
    for _, row in ipairs(rows) do
        window.storageList:addItem(row.name, row)
    end
end

local function rebuildActivity(window, storage)
    local rows = Presentation.BuildActivityRows(storage, tr)
    window.storageActivityPane:setHeader(
        tr("UI_PNC_Storage_RecentActivity", "RECENT ACTIVITY"),
        tostring(storage and #(storage.activity or {}) or 0))
    Components.SetRows(window.storageActivityList, rows)
end

function Controller.Rebuild(window)
    Components.SetRows(window.storageList, {})
    Components.SetRows(window.storageActivityList, {})
    Components.SetRows(window.details, {})
    rebuildStorage(window, window.snapshot or {})
    rebuildActivity(window, window.snapshot and window.snapshot.storage)
    LayoutModule.Apply(window, true)
end

function Controller.Refresh(window, update)
    local value = update or Client.ReadSnapshot()
    window.snapshot = value.snapshot or {}
    window.lastReceiveRevision = tonumber(value.revision) or 0
    window.lastReceiveAt = value.receivedAt
    Controller.Rebuild(window)
end

function Controller.RequestSnapshot(window)
    local _, _, requestedAt = Client.RequestSnapshot()
    window.lastRequestAt = requestedAt
end

function Controller.OnControl(window, button)
    local action = button and button.internal or ""
    if action == "transfer" then
        local storage = window.snapshot and window.snapshot.storage or nil
        if not storage or not PNC.InventoryWindow then
            if not PNC.InventoryWindow then
                require "PNC/UI/Inventory/PNC_InventoryWindow"
            end
        end
        if not storage or not PNC.InventoryWindow
            or not PNC.InventoryWindow.OpenStorage
        then return false end
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
        window:requestResponsiveLayout(true)
        window:rebuild()
        return true
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
        window:rebuild()
        return true
    end

    local selected = window.storageList and window.storageList:selectedRow()
        or nil
    local debugAction = action
    local extra = {}
    if action == "job_requirements_lumber" then
        debugAction = "job_requirements"
        extra.operation = "LUMBER"
        extra.target = "worker"
        extra.npcId = window.selectedPersonID
    end
    if PNC.Client and PNC.Client.RequestColonyAction then
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
                and math.max(1, math.floor(tonumber(selected.stack) or 1))
                or 100,
            search = window.storageSearch:getText(),
            sort = window.storageSort,
        })
    end
    return true
end

return Controller
