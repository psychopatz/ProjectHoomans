require "PNC/UI/Inventory/PNC_InventoryUI_List"

local Workshop = {}
local Rebuild = require
    "PNC/UI/Workshop/PNC_WorkshopCatalog_Rebuild"
local CATALOG_COLUMNS = {
    { key = "category", x = 0.43 }, { key = "quantity", x = 0.59 },
    { key = "availability", x = 0.72 }, { key = "action", x = 0.87 },
}
local QUEUE_COLUMNS = {
    { key = "worker", x = 0.50 }, { key = "progress", x = 0.72 },
}

local function makeList(window, role, columns, callback)
    local list = ISPNCInventoryList:new(0, 0, 100, 100, window, role)
    list.selectOnly, list.catalogColumns, list.onCatalogCell = true, columns, callback
    list:initialise(); list:instantiate(); window:addChild(list)
    return list
end

local function button(window, UIBuilder, id, key, variant)
    return UIBuilder.CreateButton(window, { id = id, title = PNC.Translation.GetKey(key),
        target = window, onclick = window.onWorkshopControl,
        variant = variant })
end

function Workshop.Create(window, UIBuilder)
    window.workshopQuantities = window.workshopQuantities or {}
    window.workshopSubtab = window.workshopSubtab or "craft"
    window.workshopQueueList = makeList(window, "workshop_queue", QUEUE_COLUMNS)
    window.workshopRecipeList = makeList(window, "workshop_recipe",
        CATALOG_COLUMNS, Workshop.OnCatalogCell)
    window.workshopSalvageList = makeList(window, "workshop_salvage",
        CATALOG_COLUMNS, Workshop.OnCatalogCell)
    window.workshopStockpileList = window.workshopSalvageList
    window.workshopCraftTab = button(window, UIBuilder, "tab_craft",
        "UI_PNC_Workshop_CraftingTab")
    window.workshopSalvageTab = button(window, UIBuilder, "tab_salvage",
        "UI_PNC_Workshop_SalvageTab")
    window.workshopPause = button(window, UIBuilder, "pause",
        "UI_PNC_Work_Pause", "warning")
    window.workshopCancel = button(window, UIBuilder, "cancel",
        "UI_PNC_Work_Cancel", "warning")
end

local function widths(content)
    local gap = 8
    local minimumLeft = math.min(250, math.floor(content.width * 0.42))
    local minimumRight = math.min(360, math.floor(content.width * 0.58))
    local left = math.max(minimumLeft, math.floor(content.width * 0.34))
    left = math.min(left, math.max(1, content.width - gap - minimumRight))
    return left, math.max(1, content.width - left - gap), gap
end

function Workshop.Layout(window, Layout, content)
    local left, right, gap = widths(content)
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
    Layout.SetBounds(window.workshopQueueList, content.x, top, left, height)
    Layout.SetBounds(window.workshopRecipeList, rightX, top, right, height)
    Layout.SetBounds(window.workshopSalvageList, rightX, top, right, height)
end

function Workshop.Apply(window, active)
    window.workshopPause:setVisible(active)
    window.workshopCancel:setVisible(active)
    window.workshopCraftTab:setVisible(active)
    window.workshopSalvageTab:setVisible(active)
    window.workshopQueueList:setVisible(active)
    if active then window.detailsPane:setVisible(false) end
    Rebuild.ApplySubtab(window, active)
end

function Workshop.Rebuild(window, snapshot, tr)
    return Rebuild.Build(window, snapshot, tr)
end

function Workshop.OnCatalogCell(window, row, key, localX, width)
    return Rebuild.OnCatalogCell(window, row, key, localX, width)
end

function Workshop.OnControl(window, buttonValue)
    return Rebuild.OnControl(window, buttonValue)
end

return Workshop
