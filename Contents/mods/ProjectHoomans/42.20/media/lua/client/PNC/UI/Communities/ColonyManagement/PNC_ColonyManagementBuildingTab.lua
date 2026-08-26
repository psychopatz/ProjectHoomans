require "PNC/UI/Inventory/PNC_InventoryUI_List"

local Building = {}
local InventoryModel = require "PNC/UI/Inventory/PNC_InventoryUI_Model"
local Placement = require "PNC/UI/Communities/ColonyManagement/PNC_BuildingPlacement"
local QueueOverlay = require
    "PNC/UI/Communities/ColonyManagement/PNC_BuildingQueueOverlay"
local function tr(key, fallback)
    local value = getText and getText(key) or nil
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
        target = window, onclick = ISPNCColonyManagementWindow.onBuildingControl,
        variant = variant })
end

local function header(list, name, cells)
    list:addItem(name, { name = name, restricted = true,
        catalogHeader = true, catalogCells = cells })
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

local function giveRecipeMaterials(window, recipe)
    if not recipe or window.buildDebugAvailable ~= true
        or not PNC.Client or not PNC.Client.RequestColonyAction
    then return false end
    PNC.Client.RequestColonyAction("building_debug_get_items", {
        recipeKey = recipe.recipeKey or recipe.objectInfoName,
    })
    return true
end

-- Building recipes are snapshots from the shared catalog. Resolve the native
-- CraftRecipe before reading or writing favorites so this tab uses the same
-- recipeFavourite:<recipe name> ModData key as the base-game build menu.
local function nativeRecipe(recipe)
    local objectInfoName = recipe
        and (recipe.objectInfoName or recipe.recipeKey) or nil
    local catalog = PNC.BuildRecipeCatalog
    local descriptor = objectInfoName and catalog and catalog.Get
        and catalog.Get(objectInfoName) or nil
    return descriptor and descriptor.nativeRecipe or nil
end

local function favoriteKey(recipe)
    local native = nativeRecipe(recipe)
    if not BaseCraftingLogic
        or type(BaseCraftingLogic.getFavouriteModDataString) ~= "function"
    then
        return nil
    end
    local name
    if native and native.getName then
        name = native:getName()
    end
    if name == nil and recipe then
        name = recipe.recipeName or recipe.objectInfoName or recipe.recipeKey
    end
    if name == nil then return nil end
    local ok, key = pcall(BaseCraftingLogic.getFavouriteModDataString,
        tostring(name))
    return ok and key or nil
end

local function isFavorite(recipe)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local key = favoriteKey(recipe)
    if not player or not key or not player.getModData then return false end
    local data = player:getModData()
    return data and data[key] == true or false
end

local function setFavorite(recipe, value)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local key = favoriteKey(recipe)
    if not player or not key or not player.getModData then return false end
    local data = player:getModData()
    if not data then return false end
    data[key] = value == true
    if player.transmitModData then player:transmitModData() end
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

local function rebuildMaterials(window)
    local list = window.buildMaterialList
    if not list then return end
    local state = listState(list, function(row)
        return row and row.fullType or row and row.name
    end)
    list:clear()
    header(list, "REQUIRED ITEMS", { required = "REQUIRED", available = "STOCK" })
    local recipe = activeRecipe(window)
    local selectedOrder = selectedQueue(window)
    local materials = selectedOrder and selectedOrder.materials
        or recipe and recipe.materials or {}
    for _, material in ipairs(materials) do
        local first = material.itemTypes and material.itemTypes[1]
        local metadata = InventoryModel.Probe(first)
        local required = tonumber(material.amount) or 1
        local available = tonumber(material.available) or 0
        list:addItem(labelFor(first), {
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
        })
    end
    restoreListState(list, state, function(row)
        return row and row.fullType or row and row.name
    end)
end

function Building.OnRecipeCell(window, row, key)
    if row and row.recipe then
        window.buildSelectedRecipe = row.recipe
        rebuildMaterials(window)
        updateFavoriteControls(window)
        if key == "action" then
            if row.enabled == true then
                Placement.Begin(window, row.recipe)
            elseif row.debugGrantEnabled == true then
                giveRecipeMaterials(window, row.recipe)
            end
        end
    end
end

function Building.OnQueueCell(window, row, key)
    if row and row.order and key == "action" then
        PNC.Client.RequestColonyAction("work_cancel", {
            workOrderId = row.order.id,
        })
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
        ISScrollingListBox.onMouseDown(list, x, y)
        local row = list:selectedRow()
        if row and row.category then
            window.buildCategory = row.category
            Building.Rebuild(window, window.snapshot or {})
        end
        return true
    end
    window.buildRecipeList.onMouseDown = function(list, x, y)
        ISPNCInventoryList.onMouseDown(list, x, y)
        local row = list:selectedRow()
        if row and row.recipe then
            window.buildSelectedRecipe = row.recipe
            rebuildMaterials(window)
            updateFavoriteControls(window)
        end
        return true
    end
    window.buildQueueList.onMouseDown = function(list, x, y)
        ISPNCInventoryList.onMouseDown(list, x, y)
        rebuildMaterials(window)
        return true
    end
end

function Building.Layout(window, Layout, content)
    local gap = 8
    local width = math.max(1, tonumber(content.width) or 1)
    local debugAvailable = PNC.Client and PNC.Client.CanUseDebug
        and PNC.Client.CanUseDebug() == true
    window.buildDebugAvailable = debugAvailable
    local buttons = {
        window.buildPlace,
        window.buildCancelPlacement,
    }
    if debugAvailable then buttons[#buttons + 1] = window.buildGetItems end
    buttons[#buttons + 1] = window.buildQueueOverlay
    buttons[#buttons + 1] = window.buildCancelOrder
    local buttonColumns = width < 800 and 2 or #buttons
    local buttonRows = width < 800
        and math.floor((#buttons + buttonColumns - 1) / buttonColumns) or 1
    local buttonHeight = 27
    local toolbarHeight = buttonRows * buttonHeight
        + (buttonRows - 1) * gap
    for index, control in ipairs(buttons) do
        local row = math.floor((index - 1) / buttonColumns)
        local column = (index - 1) % buttonColumns
        local remaining = #buttons - row * buttonColumns
        local columnsInRow = math.min(buttonColumns, remaining)
        local buttonWidth = math.floor((width
            - gap * (columnsInRow - 1)) / columnsInRow)
        local x = content.x + column * (buttonWidth + gap)
        Layout.SetBounds(control, x, content.y + row
            * (buttonHeight + gap), buttonWidth, buttonHeight)
    end

    local top = content.y + toolbarHeight + gap
    local height = math.max(1, (tonumber(content.height) or 1)
        - toolbarHeight - gap)
    local compact = width < 1000 or height < 600
    window.buildRecipeList.catalogColumns = compact
        and RECIPE_COLUMNS_COMPACT or RECIPE_COLUMNS
    local rowHeight = compact and height < 520 and 28 or 32
    for _, list in ipairs({ window.buildCategoryList,
        window.buildRecipeList, window.buildQueueList,
        window.buildMaterialList }) do
        list.itemheight = rowHeight
    end

    if compact then
        -- Small screens use a 2x2 grid.  This keeps the recipe name column
        -- readable while retaining the queue and stock information below it.
        local categoryWidth = math.floor(width * 0.25)
        categoryWidth = math.max(1, math.min(categoryWidth,
            math.max(1, width - gap - 1)))
        local recipeX = content.x + categoryWidth + gap
        local recipeWidth = math.max(1, width - categoryWidth - gap)
        local topHeight = math.floor((height - gap) * 0.54)
        topHeight = math.max(1, math.min(topHeight, height))
        local bottomY = top + topHeight + gap
        local bottomHeight = math.max(1, height - topHeight - gap)
        local queueWidth = math.floor((width - gap) * 0.58)
        queueWidth = math.max(1, math.min(queueWidth,
            math.max(1, width - gap - 1)))
        local materialX = content.x + queueWidth + gap
        local materialWidth = math.max(1, width - queueWidth - gap)
        local controlHeight = 27
        local controlGap = 6
        local favoriteWidth = 112
        local filterWidth = 126
        local searchWidth = math.max(80, recipeWidth - favoriteWidth
            - filterWidth - controlGap * 2)
        local favoriteX = recipeX + searchWidth + controlGap
        local filterX = favoriteX + favoriteWidth + controlGap
        Layout.SetBounds(window.buildCategoryList, content.x, top,
            categoryWidth, topHeight)
        Layout.SetBounds(window.buildSearch, recipeX, top, searchWidth,
            controlHeight)
        Layout.SetBounds(window.buildFavoriteButton, favoriteX, top,
            favoriteWidth, controlHeight)
        Layout.SetBounds(window.buildFavoritesFilter, filterX, top,
            filterWidth, controlHeight)
        local recipeListTop = top + controlHeight + controlGap
        Layout.SetBounds(window.buildRecipeList, recipeX, recipeListTop,
            recipeWidth, math.max(1, topHeight - controlHeight - controlGap))
        Layout.SetBounds(window.buildQueueList, content.x, bottomY,
            queueWidth, bottomHeight)
        Layout.SetBounds(window.buildMaterialList, materialX, bottomY,
            materialWidth, bottomHeight)
        return
    end

    local left = math.floor(width * 0.20)
    local middle = math.floor(width * 0.39)
    local right = math.max(1, width - left - middle - gap * 2)
    local middleX = content.x + left + gap
    local rightX = middleX + middle + gap
    Layout.SetBounds(window.buildCategoryList, content.x, top, left, height)
    local controlHeight = 27
    local controlGap = 6
    local favoriteWidth = 112
    local filterWidth = 126
    local searchWidth = math.max(80, middle - favoriteWidth - filterWidth
        - controlGap * 2)
    local favoriteX = middleX + searchWidth + controlGap
    local filterX = favoriteX + favoriteWidth + controlGap
    Layout.SetBounds(window.buildSearch, middleX, top, searchWidth,
        controlHeight)
    Layout.SetBounds(window.buildFavoriteButton, favoriteX, top,
        favoriteWidth, controlHeight)
    Layout.SetBounds(window.buildFavoritesFilter, filterX, top,
        filterWidth, controlHeight)
    local recipeListTop = top + controlHeight + controlGap
    Layout.SetBounds(window.buildRecipeList, middleX, recipeListTop, middle,
        math.max(1, height - controlHeight - controlGap))
    local queueHeight = math.max(1, math.floor((height - gap) * 0.52))
    Layout.SetBounds(window.buildQueueList, rightX, top, right, queueHeight)
    Layout.SetBounds(window.buildMaterialList, rightX,
        top + queueHeight + gap, right, math.max(1,
            height - queueHeight - gap))
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
    updateFavoriteControls(window)
    if not active then Placement.Cancel(window) end
    if active and window.detailsPane then window.detailsPane:setVisible(false) end
end

local function categories(recipes)
    local output, seen = { "ALL" }, { ALL = true }
    for _, recipe in ipairs(recipes or {}) do
        local category = tostring(recipe.category or "Miscellaneous")
        if not seen[category] then
            seen[category] = true
            output[#output + 1] = category
        end
    end
    table.sort(output, function(left, right)
        if left == right then return false end
        if left == "ALL" then return true end
        if right == "ALL" then return false end
        return left < right
    end)
    return output
end

local function rebuildCategories(window, recipes)
    local list = window.buildCategoryList
    local state = listState(list, function(row)
        return row and row.category
    end)
    state.key = state.key or window.buildCategory or "ALL"
    list:clear()
    header(list, "CATEGORIES", {})
    for _, category in ipairs(categories(recipes)) do
        list:addItem(category, { name = category, category = category,
            restricted = category ~= "ALL" and category
                ~= window.buildCategory })
    end
    restoreListState(list, state, function(row)
        return row and row.category
    end)
end

local function rebuildRecipes(window, recipes)
    local list = window.buildRecipeList
    local state = listState(list, function(row)
        local recipe = row and row.recipe
        return recipe and (recipe.objectInfoName or recipe.recipeKey)
    end)
    list:clear()
    header(list, "BUILDABLE RECIPES", {
        category = "CATEGORY", stock = "STOCK", action = "ACTION",
    })
    local search = window.buildSearch and window.buildSearch:getText() or ""
    search = string.lower(tostring(search or ""))
    local chosen = activeRecipe(window)
    state.key = state.key or chosen
        and (chosen.objectInfoName or chosen.recipeKey) or nil
    local found = false
    for _, recipe in ipairs(recipes or {}) do
        if window.buildCategory == "ALL"
            or tostring(recipe.category) == tostring(window.buildCategory)
        then
            local recipeText = string.lower(table.concat({
                tostring(recipe.displayName or ""),
                tostring(recipe.category or ""),
                tostring(recipe.recipeName or ""),
                tostring(recipe.objectInfoName or ""),
            }, " "))
            local favorite = isFavorite(recipe)
            local matchesSearch = search == ""
                or string.find(recipeText, search, 1, true) ~= nil
            if matchesSearch and (window.buildFavoritesOnly ~= true
                or favorite) then
                local ready = true
                for _, material in ipairs(recipe.materials or {}) do
                    if material.ready ~= true then ready = false; break end
                end
                local metadata = {
                    texture = recipe.iconName and getTexture
                        and getTexture(recipe.iconName) or nil,
                }
                local debugGrantEnabled = window.buildDebugAvailable == true
                local row = {
                    rowKind = "recipe", recipe = recipe, enabled = ready,
                    debugGrantEnabled = debugGrantEnabled,
                    restricted = not ready,
                    name = tostring(recipe.displayName), favorite = favorite,
                    texture = metadata.texture, catalogCells = {
                        category = tostring(recipe.category or "Miscellaneous"),
                        stock = ready and "AVAILABLE" or "MISSING",
                        action = ready and "PLACE"
                            or debugGrantEnabled and "GIVE" or "NO STOCK",
                    },
                    catalogColors = {
                        stock = ready and "success" or "warning",
                        action = ready and "accent" or "warning",
                    },
                }
                list:addItem(row.name, row)
                if chosen and chosen.objectInfoName
                    == recipe.objectInfoName
                then
                    window.buildSelectedRecipe, found = recipe, true
                end
            end
        end
    end
    if #list.items == 1 then
        local message = window.buildFavoritesOnly == true
            and "NO FAVORITED RECIPES" or "NO MATCHING RECIPES"
        list:addItem(message, {
            name = message, restricted = true,
        })
    end
    if not found then
        window.buildSelectedRecipe = list.items and list.items[2]
            and list.items[2].item and list.items[2].item.recipe or nil
        local fallback = window.buildSelectedRecipe
        state.key = fallback and (fallback.objectInfoName
            or fallback.recipeKey) or nil
    end
    restoreListState(list, state, function(row)
        local recipe = row and row.recipe
        return recipe and (recipe.objectInfoName or recipe.recipeKey)
    end)
    updateFavoriteControls(window)
end

local function rebuildQueue(window, queue)
    local list = window.buildQueueList
    local state = listState(list, function(row)
        return row and row.order and row.order.id
    end)
    list:clear()
    header(list, "BUILD QUEUE", {
        worker = "WORKER", progress = "PROGRESS", action = "ACTION",
    })
    for _, order in ipairs(queue or {}) do
        local worker = order.workerName or "UNASSIGNED"
        local blocked = order.blockedReason
        list:addItem(tostring(order.displayName or order.objectInfoName
            or "BUILD"), {
            name = tostring(order.displayName or order.objectInfoName
                or "BUILD"), order = order, restricted = false,
            catalogCells = {
                worker = worker,
                progress = tostring(order.percent or 0) .. "% "
                    .. tostring(order.status or "QUEUED"),
                action = "CANCEL",
            },
            catalogColors = {
                progress = blocked and "warning" or "accent",
                action = "warning",
            },
        })
    end
    restoreListState(list, state, function(row)
        return row and row.order and row.order.id
    end)
end

function Building.Rebuild(window, snapshot)
    if window.tab ~= "building" then return false end
    local building = snapshot.building or {}
    local recipes = building.recipes or {}
    QueueOverlay.SetQueue(building.queue or {})
    rebuildCategories(window, recipes)
    rebuildRecipes(window, recipes)
    rebuildQueue(window, building.queue or {})
    rebuildMaterials(window)
    updateFavoriteControls(window)
    return true
end

function Building.IsRecipeFavorite(recipe)
    return isFavorite(recipe)
end

function Building.ToggleRecipeFavorite(window)
    local recipe = activeRecipe(window)
    if not recipe then return false, "RECIPE_REQUIRED" end
    local updated = not isFavorite(recipe)
    if not setFavorite(recipe, updated) then
        return false, "FAVORITE_API_UNAVAILABLE"
    end
    Building.Rebuild(window, window.snapshot or {})
    updateFavoriteControls(window)
    return true, updated
end

function Building.OnControl(window, buttonValue)
    local action = tostring(buttonValue and buttonValue.internal or "")
    if action == "place" then
        local recipe = activeRecipe(window)
        if recipe then Placement.Begin(window, recipe) end
        return true
    elseif action == "cancel_placement" then
        Placement.Cancel(window)
        return true
    elseif action == "toggle_queue_overlay" then
        local building = window.snapshot and window.snapshot.building or {}
        local enabled = QueueOverlay.Toggle(building.queue or {})
        window.buildQueueOverlay:setTitle(enabled
            and "HIDE QUEUE OVERLAY" or "SHOW QUEUE OVERLAY")
        return true
    elseif action == "toggle_favorite" then
        local ok = Building.ToggleRecipeFavorite(window)
        if not ok and PNC.Core and PNC.Core.Warn then
            PNC.Core.Warn("building favorite unavailable")
        end
        return true
    elseif action == "toggle_favorites" then
        window.buildFavoritesOnly = not (window.buildFavoritesOnly == true)
        Building.Rebuild(window, window.snapshot or {})
        updateFavoriteControls(window)
        return true
    elseif action == "get_items" then
        local recipe = activeRecipe(window)
        giveRecipeMaterials(window, recipe)
        return true
    elseif action == "cancel_order" then
        local order = selectedQueue(window)
        if order then
            PNC.Client.RequestColonyAction("work_cancel",
                { workOrderId = order.id })
        end
        return true
    end
    return false
end

return Building
