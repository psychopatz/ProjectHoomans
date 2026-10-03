-- Public catalog queries, rebuilding, favorites, and controls.
local Building = PNC.BaseBuildingCatalog
local Internal = Building.Internal
local activeRecipe = Internal.activeRecipe
local giveRecipeMaterials = Internal.giveRecipeMaterials
local updateFavoriteControls = Internal.updateFavoriteControls
local isFavorite = Internal.isFavorite
local setFavorite = Internal.setFavorite
local selectedQueue = Internal.selectedQueue
local Placement = Internal.Placement
local QueueOverlay = Internal.QueueOverlay
local QueueActions = Internal.QueueActions
local RecipeState = Internal.RecipeState
local BuildAudit = Internal.BuildAudit
local rebuildCategories = Internal.rebuildCategories
local rebuildRecipes = Internal.rebuildRecipes
local rebuildQueue = Internal.rebuildQueue
local rebuildMaterials = Internal.rebuildMaterials

function Building.CatalogRecipes(window, building)
    return RecipeState.Catalog(window, building)
end

function Building.Rebuild(window, snapshot)
    snapshot = snapshot or window.snapshot or {}
    window.snapshot = snapshot
    local integrated = window.baseIntegrated == true
        and window.tab == "buildings"
    if window.tab and window.tab ~= "building" and not integrated
        and window.buildingActive ~= true
    then
        return false
    end
    local building = snapshot.building or {}
    QueueActions.Reconcile(window, snapshot, building.queue or {})
    local recipes = Building.CatalogRecipes(window, building)
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
        if not recipe then return false end
        if BuildAudit.Enabled() then
            BuildAudit.Log("click", {
                "button=place_blueprint",
                "object=" .. tostring(recipe.objectInfoName or recipe.recipeKey),
            })
        end
        local started, reason = Placement.Begin(window, recipe)
        if started == false then
            -- The placement cursor never appeared, so this click did nothing.
            -- Report it instead of returning success.
            local Shared = require "PNC/UI/Shared/PNC_ColonyUIShared"
            Shared.NotifyBuildFailure(reason)
            return false
        end
        return true
    elseif action == "cancel_placement" then
        if BuildAudit.Enabled() then
            BuildAudit.Log("cancel_clicked", {
                "button=cancel_placement",
                "placement=" .. tostring(window.buildPlacement ~= nil),
            })
        end
        Placement.Cancel(window, "user_cancel")
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
            QueueActions.RequestCancel(window, order)
        end
        return true
    end
    return false
end


return Building
