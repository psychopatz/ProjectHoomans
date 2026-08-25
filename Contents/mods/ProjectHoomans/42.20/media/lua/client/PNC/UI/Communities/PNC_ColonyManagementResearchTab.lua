require "PNC/UI/Inventory/PNC_InventoryUI_List"

local ResearchTab = {}
local InventoryModel = require "PNC/UI/Inventory/PNC_InventoryUI_Model"
local UI = PsychopatzCore and PsychopatzCore.UI or nil
local CATALOG_COLUMNS = {
    { key = "category", x = 0.45 }, { key = "action", x = 0.65 },
    { key = "state", x = 0.80 },
}
local QUEUE_COLUMNS = {
    { key = "worker", x = 0.48 }, { key = "progress", x = 0.70 },
}

local function control(window, UIBuilder, id, key, callback, variant)
    return UIBuilder.CreateButton(window, { id = id, title = getText(key),
        target = window, onclick = callback, variant = variant })
end

local function makeList(window, role, columns, callback)
    local list = ISPNCInventoryList:new(0, 0, 100, 100, window, role)
    list.selectOnly, list.catalogColumns, list.onCatalogCell = true, columns, callback
    list:initialise(); list:instantiate(); window:addChild(list)
    return list
end

function ResearchTab.Create(window, UIBuilder, tr)
    window.researchSubtab = window.researchSubtab or "base"
    window.researchQueueList = makeList(window, "research_queue", QUEUE_COLUMNS)
    window.researchCatalog = makeList(window, "research_catalog",
        CATALOG_COLUMNS, ResearchTab.OnCatalogCell)
    window.researchBaseTab = control(window, UIBuilder, "tab_base",
        "UI_PNC_Research_BaseTab", ISPNCColonyManagementWindow.onResearchControl)
    window.researchBlueprintTab = control(window, UIBuilder, "tab_blueprint",
        "UI_PNC_Research_BlueprintTab", ISPNCColonyManagementWindow.onResearchControl)
    window.researchBooksTab = control(window, UIBuilder, "tab_books",
        "UI_PNC_Research_BooksTab", ISPNCColonyManagementWindow.onResearchControl)
    window.researchPause = control(window, UIBuilder, "research_pause",
        "UI_PNC_Work_Pause", ISPNCColonyManagementWindow.onResearchControl,
        "warning")
    window.researchCancel = control(window, UIBuilder, "research_cancel",
        "UI_PNC_Work_Cancel", ISPNCColonyManagementWindow.onResearchControl,
        "warning")
    window.researchDebugBlueprint = control(window, UIBuilder, "debug_blueprint",
        "UI_PNC_Research_DebugBlueprint",
        ISPNCColonyManagementWindow.onResearchControl, "warning")
    window.researchDebugSpearKit = control(window, UIBuilder, "debug_spear_kit",
        "UI_PNC_Research_DebugSpearKit",
        ISPNCColonyManagementWindow.onResearchControl, "warning")
end

local function widths(content)
    local gap = 8
    local minimumLeft = math.min(250, math.floor(content.width * 0.42))
    local minimumRight = math.min(420, math.floor(content.width * 0.58))
    local left = math.max(minimumLeft, math.floor(content.width * 0.34))
    left = math.min(left, math.max(1, content.width - gap - minimumRight))
    return left, math.max(1, content.width - left - gap), gap
end

function ResearchTab.Layout(window, Layout, content)
    local left, right, gap = widths(content)
    local half = math.floor((left - 6) / 2)
    Layout.SetBounds(window.researchPause, content.x, content.y, half, 27)
    Layout.SetBounds(window.researchCancel, content.x + half + 6,
        content.y, left - half - 6, 27)
    local rightX, tabGap = content.x + left + gap, 5
    local tabWidth = math.floor((right - tabGap * 2) / 3)
    Layout.SetBounds(window.researchBaseTab, rightX, content.y, tabWidth, 27)
    Layout.SetBounds(window.researchBlueprintTab,
        rightX + tabWidth + tabGap, content.y, tabWidth, 27)
    Layout.SetBounds(window.researchBooksTab,
        rightX + (tabWidth + tabGap) * 2, content.y,
        right - (tabWidth + tabGap) * 2, 27)
    local debugWidth = math.floor((content.width - 6) / 2)
    Layout.SetBounds(window.researchDebugBlueprint, content.x, content.y + 34,
        debugWidth, 27)
    Layout.SetBounds(window.researchDebugSpearKit,
        content.x + debugWidth + 6, content.y + 34, debugWidth, 27)
    local debugAuthorized = window.snapshot and window.snapshot.storage
        and window.snapshot.storage.debugAuthorized == true
    local controlsHeight = debugAuthorized and 68 or 34
    local top, height = content.y + controlsHeight,
        math.max(1, content.height - controlsHeight)
    Layout.SetBounds(window.researchQueueList, content.x, top, left, height)
    Layout.SetBounds(window.researchCatalog, rightX, top, right, height)
end

local function setButtonState(button, selected, enabled)
    if not button then return end
    button:setEnable(enabled == true)
    if UI and UI.SetButtonVariant then
        UI.SetButtonVariant(button, selected and "selected" or "quiet")
    end
end

local function applySubtab(window)
    local lanes = window.researchLaneAvailability or {}
    if lanes[window.researchSubtab] ~= true then
        window.researchSubtab = lanes.base and "base"
            or lanes.blueprint and "blueprint"
            or lanes.books and "books" or "base"
    end
    setButtonState(window.researchBaseTab,
        window.researchSubtab == "base", lanes.base)
    setButtonState(window.researchBlueprintTab,
        window.researchSubtab == "blueprint", lanes.blueprint)
    setButtonState(window.researchBooksTab,
        window.researchSubtab == "books", lanes.books)
end

function ResearchTab.ApplyVisibility(window, active)
    local debugAuthorized = window.snapshot and window.snapshot.storage
        and window.snapshot.storage.debugAuthorized == true
    window.researchQueueList:setVisible(active)
    window.researchCatalog:setVisible(active)
    window.researchBaseTab:setVisible(active)
    window.researchBlueprintTab:setVisible(active)
    window.researchBooksTab:setVisible(active)
    window.researchPause:setVisible(active)
    window.researchCancel:setVisible(active)
    window.researchDebugBlueprint:setVisible(active and debugAuthorized)
    window.researchDebugSpearKit:setVisible(active and debugAuthorized)
    if active then window.detailsPane:setVisible(false); applySubtab(window) end
end

local function activeResearch(snapshot)
    local output = {}
    for _, order in ipairs(snapshot.research and snapshot.research.orders or {}) do
        if (order.operation == "RESEARCH" or order.operation == "READ_BOOK")
            and order.status ~= "COMPLETED"
            and order.status ~= "CANCELLED" then output[#output + 1] = order end
    end
    return output
end

local function progress(order)
    local required = math.max(1, tonumber(order and order.requiredWork) or 1)
    return math.floor(math.min(1, math.max(0,
        tonumber(order and order.progress) or 0) / required) * 100 + 0.5)
end

local function matchingOrder(orders, mode, id)
    for _, order in ipairs(orders) do
        local payload = order.payload or {}
        local matches = mode == "technology"
            and tostring(payload.technologyId) == tostring(id)
            or mode == "book"
            and tostring(payload.bookFullType) == tostring(id)
            or mode ~= "technology" and mode ~= "book"
            and tonumber(order.recipeId) == tonumber(id)
        if payload.mode == mode and matches then return order end
    end
end

local function hasLane(snapshot, role)
    -- Base research, blueprint study, and book reading all use the same
    -- physical native Log Table. Keep the logical lane names for activity
    -- routing while checking only the shared workstation component.
    if role == "work.blueprint" or role == "work.reverse" then
        role = "work.research"
    end
    for _, facility in ipairs(snapshot.settlement
        and snapshot.settlement.facilities or {}) do
        if facility.definitionId == "research_facility"
            and facility.constructionState == "BUILT"
        then
            for _, component in ipairs(facility.components or {}) do
                if component.role == role then return true end
            end
        end
    end
    return false
end

function ResearchTab.OnCatalogCell(window, row, key)
    if key ~= "action" or row.researchable ~= true then return end
    if row.mode == "technology" then
        PNC.Client.RequestColonyAction("research_queue_technology",
            { technologyId = row.technologyId })
    elseif row.mode == "blueprint" then
        PNC.Client.RequestColonyAction("research_study_blueprint",
            { recordIndex = row.recordIndex })
    elseif row.mode == "book" then
        PNC.Client.RequestColonyAction("research_read_book",
            { recordIndex = row.recordIndex })
    end
end

local function selectedOrder(window)
    local row = window.researchQueueList:selectedRow()
    return row and row.order or activeResearch(window.snapshot or {})[1]
end

function ResearchTab.OnControl(window, buttonValue)
    local action = tostring(buttonValue and buttonValue.internal or "")
    local tab = action == "tab_base" and "base"
        or action == "tab_blueprint" and "blueprint"
        or action == "tab_books" and "books" or nil
    if tab and window.researchLaneAvailability[tab] then
        window.researchSubtab = tab; window:rebuildDetails(); return true
    end
    local order = selectedOrder(window)
    if action == "research_pause" and order then
        PNC.Client.RequestColonyAction("work_pause", { workOrderId = order.id,
            paused = order.status ~= "PAUSED" }); return true
    elseif action == "research_cancel" and order then
        PNC.Client.RequestColonyAction("work_cancel", { workOrderId = order.id })
        return true
    elseif action == "debug_blueprint" then
        PNC.Client.RequestColonyAction("blueprint_debug_create", {}); return true
    elseif action == "debug_spear_kit" then
        PNC.Client.RequestColonyAction("production_debug_spear_kit", {}); return true
    end
    return false
end

local function addRow(list, spec)
    local order = spec.order
    local state = spec.known and "LEARNED"
        or order and ("RESEARCHING " .. tostring(progress(order)) .. "%")
        or spec.prerequisiteKnown == false and "PREREQUISITE REQUIRED"
        or "NOT LEARNED"
    spec.catalogCells = { category = spec.category,
        action = spec.known and "—" or order and "QUEUED"
            or spec.prerequisiteKnown == false and "LOCKED"
            or spec.laneAvailable and "RESEARCH" or spec.missingStation,
        state = state }
    spec.catalogColors = { action = spec.laneAvailable and not spec.known
        and not order and "accent" or "warning",
        state = spec.known and "success" or order and "warning" or nil }
    spec.researchable = spec.laneAvailable and not spec.known
        and spec.prerequisiteKnown ~= false and order == nil
    spec.restricted = not spec.researchable
    list:addItem(spec.name, spec)
end

local function rebuildQueue(window, orders)
    if not window.researchQueueList then return end
    window.researchQueueList:clear()
    window.researchQueueList:addItem("RESEARCH QUEUE", { name = "RESEARCH QUEUE",
        restricted = true, catalogHeader = true,
        catalogCells = { worker = "WORKER", progress = "PROGRESS" } })
    for _, order in ipairs(orders) do
        local mode = tostring(order.payload and order.payload.mode or "technology")
        window.researchQueueList:addItem(string.upper(mode), {
            name = string.upper(mode), order = order,
            catalogCells = { worker = tostring(order.workerId or "UNASSIGNED"),
                progress = tostring(progress(order)) .. "%  "
                    .. tostring(order.status) },
            catalogColors = { progress = order.blockedReason
                and "warning" or "accent" } })
    end
end

function ResearchTab.Rebuild(window, snapshot, tr)
    if window.tab ~= "research" then return false end
    local research, orders = snapshot.research or {}, activeResearch(snapshot)
    window.researchLaneAvailability = {
        base = hasLane(snapshot, "work.research"),
        blueprint = hasLane(snapshot, "work.research"),
        books = hasLane(snapshot, "work.research"),
    }
    applySubtab(window)
    rebuildQueue(window, orders)
    window.researchCatalog:clear()
    local title = window.researchSubtab == "base" and getText("UI_PNC_Research_BaseTitle")
        or window.researchSubtab == "blueprint" and getText("UI_PNC_Research_BlueprintTitle")
        or getText("UI_PNC_Research_BooksTab")
    window.researchCatalog:addItem(title, { name = title, restricted = true,
        catalogHeader = true, catalogCells = { category = "CATEGORY",
            action = "RESEARCH", state = "STATE / PROGRESS" } })
    if window.researchSubtab == "base" then
        for _, entry in ipairs(research.entries or {}) do
            local lane = "base"
            addRow(window.researchCatalog, { name = tr(entry.labelKey, entry.id),
                mode = "technology", technologyId = entry.id,
                category = string.upper(tostring(entry.category or "TECHNOLOGY")),
                known = entry.known == true,
                prerequisiteKnown = entry.prerequisiteKnown ~= false,
                order = matchingOrder(orders, "technology", entry.id),
                laneAvailable = window.researchLaneAvailability[lane],
                missingStation = "NO RESEARCH TABLE" })
        end
    else
        local mode = window.researchSubtab
        for _, candidate in ipairs(research.candidates or {}) do
            local candidateMode = mode == "books" and "book" or mode
            if candidate.mode == candidateMode then
                local metadata = InventoryModel.Probe(candidate.fullType)
                addRow(window.researchCatalog, { name = candidate.displayName,
                    texture = metadata.texture, mode = candidate.mode,
                    recipeId = candidate.recipeId,
                    bookFullType = candidate.bookFullType,
                    recordIndex = candidate.recordIndex,
                    category = mode == "blueprint" and "BLUEPRINT" or "BOOK",
                    known = candidate.known == true,
                    order = matchingOrder(orders, candidate.mode,
                        candidate.mode == "book" and candidate.bookFullType
                            or candidate.recipeId),
                    laneAvailable = mode == "books"
                        and window.researchLaneAvailability.books
                        or window.researchLaneAvailability[mode],
                    missingStation = "NO RESEARCH TABLE" })
            end
        end
    end
    return true
end

return ResearchTab
