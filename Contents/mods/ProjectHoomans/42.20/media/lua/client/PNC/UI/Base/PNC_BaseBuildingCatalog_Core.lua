require "PNC/UI/Inventory/PNC_InventoryUI_List"

PNC = PNC or {}
PNC.BaseBuildingCatalog = PNC.BaseBuildingCatalog or {}
local Building = PNC.BaseBuildingCatalog
local InventoryModel = require "PNC/UI/Inventory/PNC_InventoryUI_Model"
local Placement = require "PNC/UI/Base/PNC_BaseBuildingPlacement"
local QueueOverlay = require
    "PNC/UI/Base/PNC_BaseBuildingQueueOverlay"
local QueueActions = require
    "PNC/UI/Base/PNC_BaseBuildingQueueActions"
local Data = require "PNC/UI/Base/PNC_BaseBuildingData"
local BuildAudit = require "PNC/Core/Diagnostics/PNC_BuildAudit"
local RecipeState = require
    "PNC/UI/Base/PNC_BaseBuildingCatalog_Recipes"
local Preview = require
    "PNC/UI/Base/PNC_BaseBuildingCatalog_Preview"
local BuildingLayout = require
    "PNC/UI/Base/PNC_BaseBuildingCatalog_Layout"

local function trace(event, message)
    local hub = PNC.CommandHub
    if hub and hub.Trace then hub.Trace(event, message) end
end

local function tr(key, fallback)
    local value = getText and PNC.Translation.GetKey(key) or nil
    if not value or value == key then return fallback end
    return value
end

local RECIPE_COLUMNS = {
    { key = "category", x = 0.56 },
    { key = "stock", x = 0.76 },
    { key = "action", x = 0.91 },
}
local RECIPE_COLUMNS_COMPACT = {
    { key = "category", x = 0.50 },
    { key = "stock", x = 0.72 },
    { key = "action", x = 0.90 },
}
local QUEUE_COLUMNS = {
    { key = "worker", x = 0.38 },
    { key = "progress", x = 0.67 },
    { key = "action", x = 0.89 },
}
local MATERIAL_COLUMNS = {
    { key = "required", x = 0.62 },
    { key = "available", x = 0.82 },
}

local function makeList(window, role, columns, callback)
    local list = ISPNCInventoryList:new(0, 0, 100, 100, window, role)
    list.selectOnly = true
    list.catalogColumns = columns
    list.onCatalogCell = callback
    list:initialise(); list:instantiate(); window:addChild(list)
    return list
end

local function button(window, builder, id, title, variant)
    return builder.CreateButton(window, { id = id, title = title,
        target = window, onclick = window.onBuildingControl,
        variant = variant })
end

local function labelFor(fullType)
    if getItemNameFromFullType then
        return tostring(getItemNameFromFullType(fullType) or fullType)
    end
    return tostring(fullType or "Item")
end

local function activeRecipe(window)
    return window.buildSelectedRecipe
end

local nativeRecipe = RecipeState.NativeRecipe
local recipeDescriptor = RecipeState.Descriptor
local isFavorite = RecipeState.IsFavorite
local setFavorite = RecipeState.SetFavorite

function Building.FilterFacilityRecipes(recipes)
    return RecipeState.FilterFacilityRecipes(recipes)
end

local function giveRecipeMaterials(window, recipe)
    if not recipe or window.buildDebugAvailable ~= true
        or not PNC.Client or not PNC.Client.RequestColonyAction
    then return false end
    PNC.Client.RequestColonyAction("building_debug_get_items", {
        recipeKey = recipe.recipeKey or recipe.objectInfoName,
    })
    return true
end

local function updateFavoriteControls(window)
    local recipe = activeRecipe(window)
    if window.buildFavoriteButton then
        window.buildFavoriteButton:setTitle(isFavorite(recipe)
            and "UNFAVORITE" or "FAVORITE")
    end
    if window.buildFavoritesFilter then
        window.buildFavoritesFilter:setTitle(window.buildFavoritesOnly
            and "SHOW ALL" or "SHOW FAVORITES")
    end
end

local function listState(list, keyForRow)
    local selected = list and list.selectedRow and list:selectedRow() or nil
    return {
        key = selected and keyForRow and keyForRow(selected) or nil,
        yScroll = list and list.yScroll or nil,
        topIndex = list and list.topIndex or nil,
        topItem = list and list.topItem or nil,
    }
end

local function restoreListState(list, state, keyForRow)
    if not list then return end
    local wanted = state and state.key or nil
    local selectedIndex = 0
    if wanted ~= nil then
        for index, entry in ipairs(list.items or {}) do
            local row = entry and entry.item or nil
            if row and keyForRow and tostring(keyForRow(row))
                == tostring(wanted)
            then
                selectedIndex = index
                break
            end
        end
    end
    list.selected = selectedIndex
    if state and state.yScroll ~= nil then list.yScroll = state.yScroll end
    if state and state.topIndex ~= nil then list.topIndex = state.topIndex end
    if state and state.topItem ~= nil then list.topItem = state.topItem end
end

local function selectedQueue(window)
    local row = window.buildQueueList and window.buildQueueList:selectedRow()
    return row and row.order or nil
end

local Components
local componentsLoadAttempted = false

local function setCatalogRows(list, rows)
    -- Keep the catalog usable in lightweight/headless callers that provide
    -- only the legacy list stub. The game path uses the shared component
    -- helper; the local fallback preserves the same stable-key contract.
    if not Components and not componentsLoadAttempted then
        componentsLoadAttempted = true
        local ok, loaded = pcall(require,
            "PNC/UI/Shared/PNC_ColonyUIComponents")
        if ok then
            Components = loaded
        end
    end
    if Components and Components.SetRowsStable then
        Components.SetRowsStable(list, rows)
        return
    end
    local items = list and list.items or {}
    if #items ~= #rows then
        list:clear()
        for _, row in ipairs(rows or {}) do
            list:addItem(tostring(row.key or row.label or row.name or ""), row)
        end
        return
    end
    local function rowKey(row, index)
        return (row and row.kind or "") .. ":"
            .. tostring(row and (row.key or row.id or row.fullType
                or row.label or row.name or index) or index)
    end
    for index, row in ipairs(rows or {}) do
        local old = items[index] and items[index].item or nil
        if rowKey(old, index) ~= rowKey(row, index) then
            list:clear()
            for _, replacement in ipairs(rows or {}) do
                list:addItem(tostring(replacement.key or replacement.label
                    or replacement.name or ""), replacement)
            end
            return
        end
    end
    for index, row in ipairs(rows or {}) do
        items[index].item = row
        items[index].text = tostring(row.key or row.label or row.name or "")
    end
end

local function rebuildMaterials(window)
    local list = window.buildMaterialList
    if not list then return end
    local state = listState(list, function(row)
        return row and row.fullType or row and row.name
    end)
    local rows = {{
        kind = "catalog_header", key = "materials", name = "REQUIRED ITEMS",
        restricted = true, catalogHeader = true,
        catalogCells = { required = "REQUIRED", available = "STOCK" },
    }}
    local recipe = activeRecipe(window)
    local selectedOrder = selectedQueue(window)
    local materials = selectedOrder and selectedOrder.materials
        or recipe and recipe.materials or {}
    for _, material in ipairs(materials) do
        local first = material.itemTypes and material.itemTypes[1]
        local metadata = InventoryModel.Probe(first)
        local required = tonumber(material.amount) or 1
        local available = tonumber(material.available) or 0
        rows[#rows + 1] = {
            kind = "material", key = tostring(first or "unknown"),
            name = labelFor(first), texture = metadata.texture,
            restricted = not material.ready,
            catalogCells = {
                required = tostring(required) .. (material.consumed
                    and " uses" or " kept"),
                available = tostring(available) .. "/" .. tostring(required),
            },
            catalogColors = {
                available = material.ready and "success" or "warning",
            },
            fullType = first,
        }
    end
    setCatalogRows(list, rows)
    restoreListState(list, state, function(row)
        return row and row.fullType or row and row.name
    end)
end

function Building.OnRecipeCell(window, row, key)
    if row and row.recipe then
        window.buildSelectedRecipe = row.recipe
        trace("pnc_building_recipe_click", "key="
            .. tostring(row.recipe.objectInfoName or row.recipe.recipeKey)
            .. " cell=" .. tostring(key or "row") .. " enabled="
            .. tostring(row.enabled == true))
        rebuildMaterials(window)
        updateFavoriteControls(window)
        if key == "action" then
            if row.enabled == true then
                if BuildAudit.Enabled() then
                    BuildAudit.Log("click", {
                        "button=recipe_row_action",
                        "object=" .. tostring(row.recipe.objectInfoName
                            or row.recipe.recipeKey),
                    })
                end
                Placement.Begin(window, row.recipe)
            elseif row.debugGrantEnabled == true then
                giveRecipeMaterials(window, row.recipe)
            end
        end
    end
end

function Building.OnQueueCell(window, row, key)
    trace("pnc_building_queue_click", "key="
        .. tostring(row and row.order and row.order.id or "")
        .. " cell=" .. tostring(key or "row"))
    if row and row.order and key == "action" then
        QueueActions.RequestCancel(window, row.order)
    end
end

function Building.Create(window, builder)
    window.buildCategory = window.buildCategory or "ALL"
    window.buildCategoryList = makeList(window, "build_category")
    window.buildRecipeList = makeList(window, "build_recipe", RECIPE_COLUMNS,
        Building.OnRecipeCell)
    window.buildQueueList = makeList(window, "build_queue", QUEUE_COLUMNS,
        Building.OnQueueCell)
    window.buildMaterialList = makeList(window, "build_material",
        MATERIAL_COLUMNS)
    window.buildRecipePreview = Preview.Create(window)
    window.buildPlace = button(window, builder, "place",
        "PLACE BLUEPRINT", "accent")
    window.buildCancelPlacement = button(window, builder,
        "cancel_placement", "CANCEL PLACEMENT", "warning")
    window.buildGetItems = button(window, builder, "get_items",
        tr("UI_PNC_Building_GiveMaterials", "GIVE MATERIALS"), "warning")
    window.buildQueueOverlay = button(window, builder,
        "toggle_queue_overlay", "SHOW QUEUE OVERLAY", "quiet")
    window.buildCancelOrder = button(window, builder, "cancel_order",
        "CANCEL ORDER", "warning")
    window.buildSearch = builder.CreateTextEntry(window, {
        clearButton = true,
        width = 1,
        height = 1,
        onTextChange = function()
            Building.Rebuild(window, window.snapshot or {})
        end,
    })
    window.buildFavoriteButton = button(window, builder,
        "toggle_favorite", "FAVORITE", "quiet")
    window.buildFavoritesFilter = button(window, builder,
        "toggle_favorites", "SHOW FAVORITES", "quiet")
    window.buildCategoryList.onMouseDown = function(list, x, y)
        local inputX, inputY = list:resolveMouse(x, y)
        ISScrollingListBox.onMouseDown(list, inputX, inputY)
        local row = list:selectedRow()
        if row and row.category then
            trace("pnc_building_category_click", "category="
                .. tostring(row.category))
            window.buildCategory = row.category
            Building.Rebuild(window, window.snapshot or {})
        end
        return true
    end
    window.buildRecipeList.onMouseDown = function(list, x, y)
        ISPNCInventoryList.onMouseDown(list, x, y)
        local row = list:selectedRow()
        if row and row.recipe then
            Building.OnRecipeCell(window, row, "row")
        end
        return true
    end
    window.buildQueueList.onMouseDown = function(list, x, y)
        ISPNCInventoryList.onMouseDown(list, x, y)
        rebuildMaterials(window)
        return true
    end
end

function Building.Layout(window, LayoutApi, content)
    return BuildingLayout.Apply(window, LayoutApi, content,
        RECIPE_COLUMNS, RECIPE_COLUMNS_COMPACT)
end

function Building.Apply(window, active)
    local building = window.snapshot and window.snapshot.building or {}
    QueueOverlay.SetQueue(building.queue or {})
    window.buildCategoryList:setVisible(active)
    window.buildRecipeList:setVisible(active)
    window.buildQueueList:setVisible(active)
    window.buildMaterialList:setVisible(active)
    window.buildPlace:setVisible(active)
    window.buildCancelPlacement:setVisible(active)
    local debugAvailable = PNC.Client and PNC.Client.CanUseDebug
        and PNC.Client.CanUseDebug() == true
    window.buildDebugAvailable = debugAvailable
    window.buildGetItems:setVisible(active and debugAvailable)
    window.buildQueueOverlay:setVisible(active)
    window.buildQueueOverlay:setTitle(QueueOverlay.IsEnabled()
        and "HIDE QUEUE OVERLAY" or "SHOW QUEUE OVERLAY")
    window.buildCancelOrder:setVisible(active)
    window.buildSearch:setVisible(active)
    window.buildFavoriteButton:setVisible(active)
    window.buildFavoritesFilter:setVisible(active)
    if window.buildRecipePreview then
        window.buildRecipePreview:setVisible(active
            and window.buildRecipePreviewCompact ~= true)
    end
    updateFavoriteControls(window)
    -- Do NOT cancel the placement here.
    --
    -- The placement cursor is window-level state (window.buildPlacement), not
    -- catalog state, and this Apply runs with active=false on every snapshot
    -- refresh whenever the FACILITIES tab is the visible one. Cancelling here
    -- tore down every facility placement roughly one refresh after BUILD, which
    -- is why a native workstation could never be placed. Tab-level deactivation
    -- in PNC_BaseBuildingTab.Apply already cancels when the player leaves both
    -- build tabs, and the CANCEL PLACEMENT button covers the explicit case.
    if active and window.detailsPane then window.detailsPane:setVisible(false) end
end

Building.Internal = Building.Internal or {}
local Internal = Building.Internal
Internal.trace = trace
Internal.tr = tr
Internal.makeList = makeList
Internal.button = button
Internal.labelFor = labelFor
Internal.activeRecipe = activeRecipe
Internal.giveRecipeMaterials = giveRecipeMaterials
Internal.updateFavoriteControls = updateFavoriteControls
Internal.listState = listState
Internal.restoreListState = restoreListState
Internal.selectedQueue = selectedQueue
Internal.setCatalogRows = setCatalogRows
Internal.rebuildMaterials = rebuildMaterials
Internal.isFavorite = isFavorite
Internal.setFavorite = setFavorite
Internal.Placement = Placement
Internal.QueueOverlay = QueueOverlay
Internal.QueueActions = QueueActions
Internal.RecipeState = RecipeState
Internal.BuildAudit = BuildAudit
Internal.InventoryModel = InventoryModel
Internal.Preview = Preview
Internal.BuildingLayout = BuildingLayout
Internal.RECIPE_COLUMNS = RECIPE_COLUMNS
Internal.RECIPE_COLUMNS_COMPACT = RECIPE_COLUMNS_COMPACT
Internal.QUEUE_COLUMNS = QUEUE_COLUMNS
Internal.MATERIAL_COLUMNS = MATERIAL_COLUMNS

return Building
