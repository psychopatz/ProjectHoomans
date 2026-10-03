-- Building recipe, category, and queue projections.
local Building = PNC.BaseBuildingCatalog
local Internal = Building.Internal
local listState = Internal.listState
local restoreListState = Internal.restoreListState
local activeRecipe = Internal.activeRecipe
local isFavorite = Internal.isFavorite
local setCatalogRows = Internal.setCatalogRows
local updateFavoriteControls = Internal.updateFavoriteControls
local RecipeState = Internal.RecipeState
local QueueActions = Internal.QueueActions

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
    local rows = {{
        kind = "catalog_header", key = "categories", name = "CATEGORIES",
        restricted = true, catalogHeader = true, catalogCells = {},
    }}
    for _, category in ipairs(categories(recipes)) do
        rows[#rows + 1] = { kind = "category", key = tostring(category),
            name = category, category = category,
            restricted = category ~= "ALL" and category
                ~= window.buildCategory }
    end
    setCatalogRows(list, rows)
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
    local rows = {{
        kind = "catalog_header", key = "recipes", name = "BUILDABLE RECIPES",
        restricted = true, catalogHeader = true,
        catalogCells = {
            category = "CATEGORY", stock = "STOCK", action = "ACTION",
        },
    }}
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
                    kind = "recipe",
                    key = tostring(recipe.objectInfoName
                        or recipe.recipeKey or recipe.id or recipe.displayName),
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
                rows[#rows + 1] = row
                if chosen and chosen.objectInfoName
                    == recipe.objectInfoName
                then
                    window.buildSelectedRecipe, found = recipe, true
                end
            end
        end
    end
    if #rows == 1 then
        local message = window.buildFavoritesOnly == true
            and "NO FAVORITED RECIPES" or "NO MATCHING RECIPES"
        rows[#rows + 1] = {
            kind = "empty", key = "recipes", name = message, restricted = true,
        }
    end
    setCatalogRows(list, rows)
    if not found then
        window.buildSelectedRecipe = rows[2] and rows[2].recipe or nil
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
    local rows = {{
        kind = "catalog_header", key = "queue", name = "BUILD QUEUE",
        restricted = true, catalogHeader = true,
        catalogCells = {
            worker = "WORKER", progress = "PROGRESS", action = "ACTION",
        },
    }}
    for _, order in ipairs(queue or {}) do
        local worker = order.workerName or "UNASSIGNED"
        local blocked = order.blockedReason
        rows[#rows + 1] = {
            kind = "queue", key = tostring(order.id or "unknown"),
            name = tostring(order.displayName or order.objectInfoName
                or "BUILD"), order = order, restricted = false,
            catalogCells = {
                worker = worker,
                progress = tostring(order.percent or 0) .. "% "
                    .. tostring(order.status or "QUEUED"),
                action = QueueActions.ActionLabel(window, order),
            },
            catalogColors = {
                progress = blocked and "warning" or "accent",
                action = "warning",
            },
        }
    end
    setCatalogRows(list, rows)
    restoreListState(list, state, function(row)
        return row and row.order and row.order.id
    end)
end


Internal.categories = categories
Internal.rebuildCategories = rebuildCategories
Internal.rebuildRecipes = rebuildRecipes
Internal.rebuildQueue = rebuildQueue

return Building
