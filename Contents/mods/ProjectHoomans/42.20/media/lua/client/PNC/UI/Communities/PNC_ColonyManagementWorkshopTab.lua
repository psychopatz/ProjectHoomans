require "PNC/UI/Inventory/PNC_InventoryUI_List"

local Workshop = {}
local ViewModel = require "PNC/UI/Communities/PNC_ColonyStorageViewModel"

function Workshop.Create(window, UI, tr)
    window.workshopRecipeIndex, window.workshopItemIndex = 1, 1
    window.workshopQuantity = 1
    window.workshopRecipeList = ISPNCInventoryList:new(
        0, 0, 100, 100, window, "workshop_recipe")
    window.workshopRecipeList.selectOnly = true
    window.workshopRecipeList:initialise()
    window.workshopRecipeList:instantiate()
    window:addChild(window.workshopRecipeList)
    window.workshopStockpileList = ISPNCInventoryList:new(
        0, 0, 100, 100, window, "workshop_stockpile")
    window.workshopStockpileList.selectOnly = true
    window.workshopStockpileList:initialise()
    window.workshopStockpileList:instantiate()
    window:addChild(window.workshopStockpileList)
    local function button(id, key, variant)
        return UI.CreateButton(window, { id = id, title = getText(key),
            target = window,
            onclick = ISPNCColonyManagementWindow.onWorkshopControl,
            variant = variant })
    end
    window.workshopRecipePrevious = button("recipe_previous",
        "UI_PNC_Workshop_PreviousRecipe")
    window.workshopRecipeNext = button("recipe_next",
        "UI_PNC_Workshop_NextRecipe")
    window.workshopQuantityLess = button("quantity_less",
        "UI_PNC_Workshop_QuantityLess")
    window.workshopQuantityMore = button("quantity_more",
        "UI_PNC_Workshop_QuantityMore")
    window.workshopCraft = UI.CreateButton(window, { id = "craft",
        title = getText("UI_PNC_Workshop_Craft"), target = window,
        onclick = ISPNCColonyManagementWindow.onWorkshopControl })
    window.workshopItemPrevious = button("item_previous",
        "UI_PNC_Workshop_PreviousItem")
    window.workshopItemNext = button("item_next",
        "UI_PNC_Workshop_NextItem")
    window.workshopDisassemble = UI.CreateButton(window, { id = "disassemble",
        title = getText("UI_PNC_Workshop_Disassemble"), target = window,
        onclick = ISPNCColonyManagementWindow.onWorkshopControl })
    window.workshopPause = button("pause", "UI_PNC_Work_Pause", "warning")
    window.workshopCancel = UI.CreateButton(window, { id = "cancel",
        title = getText("UI_PNC_Work_Cancel"), target = window,
        onclick = ISPNCColonyManagementWindow.onWorkshopControl,
        variant = "warning" })
end

function Workshop.Layout(window, Layout, content)
    local controls = { window.workshopQuantityLess, window.workshopQuantityMore,
        window.workshopCraft, window.workshopDisassemble,
        window.workshopPause, window.workshopCancel }
    local gap, columns = 6, 3
    local width = math.floor((content.width - gap * (columns - 1)) / columns)
    for index, control in ipairs(controls) do
        local column, row = (index - 1) % columns, math.floor((index - 1) / columns)
        Layout.SetBounds(control, content.x + column * (width + gap),
            content.y + row * 32, width, 27)
    end
    local top = content.y + 68
    local listHeight = math.max(110, math.floor((content.height - 80) * 0.55))
    local listWidth = math.floor((content.width - gap) / 2)
    Layout.SetBounds(window.workshopRecipeList, content.x, top,
        listWidth, listHeight)
    Layout.SetBounds(window.workshopStockpileList,
        content.x + listWidth + gap, top, listWidth, listHeight)
    Layout.SetBounds(window.detailsPane, content.x, top + listHeight + gap,
        content.width, math.max(60,
            content.y + content.height - top - listHeight - gap))
end

function Workshop.Apply(window, active, Layout)
    window.workshopCraft:setVisible(active)
    window.workshopDisassemble:setVisible(active)
    window.workshopCancel:setVisible(active)
    window.workshopRecipePrevious:setVisible(active)
    window.workshopRecipeNext:setVisible(active)
    window.workshopQuantityLess:setVisible(active)
    window.workshopQuantityMore:setVisible(active)
    window.workshopItemPrevious:setVisible(active)
    window.workshopItemNext:setVisible(active)
    window.workshopPause:setVisible(active)
    window.workshopRecipeList:setVisible(active)
    window.workshopStockpileList:setVisible(active)
    window.workshopRecipePrevious:setVisible(false)
    window.workshopRecipeNext:setVisible(false)
    window.workshopItemPrevious:setVisible(false)
    window.workshopItemNext:setVisible(false)
end

local function availableRecipes(window)
    local output = {}
    for _, resolved in ipairs(window.snapshot and window.snapshot.workshop
        and window.snapshot.workshop.knownRecipes or {}) do
        if resolved.status == "AVAILABLE" then output[#output + 1] = resolved end
    end
    return output
end

local function disassemblyRows(window)
    local output = {}
    for _, row in ipairs(window.snapshot and window.snapshot.storage
        and window.snapshot.storage.rows or {}) do
        if row.fullType ~= "PNC.RecipeBlueprint" then output[#output + 1] = row end
    end
    return output
end

local cycle

local function selectedRecipe(window, recipes)
    local row = window.workshopRecipeList:selectedRow()
    if row and row.recipe then return row.recipe end
    return recipes[cycle(window.workshopRecipeIndex, 0, #recipes)]
end

local function selectedItem(window, items)
    local row = window.workshopStockpileList:selectedRow()
    if row and row.recordIndex then return row end
    return items[cycle(window.workshopItemIndex, 0, #items)]
end

cycle = function(value, delta, count)
    if count <= 0 then return 1 end
    return ((math.max(1, tonumber(value) or 1) - 1 + delta) % count) + 1
end

local function firstActive(snapshot)
    for _, order in ipairs(snapshot.workshop and snapshot.workshop.orders or {}) do
        if order.status ~= "COMPLETED" and order.status ~= "CANCELLED" then
            return order
        end
    end
end

function Workshop.OnControl(window, button)
    local action = tostring(button and button.internal or "")
    local recipes, items = availableRecipes(window), disassemblyRows(window)
    if action == "recipe_previous" or action == "recipe_next" then
        window.workshopRecipeIndex = cycle(window.workshopRecipeIndex,
            action == "recipe_next" and 1 or -1, #recipes)
        window:rebuildDetails(); return true
    elseif action == "quantity_less" or action == "quantity_more" then
        window.workshopQuantity = math.max(1, math.min(99,
            (tonumber(window.workshopQuantity) or 1)
                + (action == "quantity_more" and 1 or -1)))
        window:rebuildDetails(); return true
    elseif action == "item_previous" or action == "item_next" then
        window.workshopItemIndex = cycle(window.workshopItemIndex,
            action == "item_next" and 1 or -1, #items)
        window:rebuildDetails(); return true
    elseif action == "craft" then
        local resolved = selectedRecipe(window, recipes)
        if resolved then
            PNC.Client.RequestColonyAction("craft_queue", {
                recipeId = resolved.id, quantity = window.workshopQuantity,
            })
            return true
        end
    elseif action == "disassemble" then
        local row = selectedItem(window, items)
        if row then
            PNC.Client.RequestColonyAction("disassemble_queue", {
                recordIndex = row.recordIndex,
            })
            return true
        end
    elseif action == "pause" then
        local order = firstActive(window.snapshot or {})
        if order then PNC.Client.RequestColonyAction("work_pause", {
            workOrderId = order.id, paused = order.status ~= "PAUSED",
        }) return true end
    elseif action == "cancel" then
        local order = firstActive(window.snapshot or {})
        if order then PNC.Client.RequestColonyAction("work_cancel", {
            workOrderId = order.id,
        }) return true end
    end
    return false
end

function Workshop.Rebuild(window, snapshot, tr)
    if window.tab ~= "workshop" then return false end
    local workshop = snapshot.workshop or {}
    window:addDetail(tr("UI_PNC_Workshop_KnownRecipes", "KNOWN RECIPES"),
        tostring(#(workshop.knownRecipes or {})))
    local recipes, items = availableRecipes(window), disassemblyRows(window)
    window.workshopRecipeList:clear()
    for _, recipe in ipairs(recipes) do
        local descriptor = recipe.descriptor or {}
        local output = descriptor.outputs and descriptor.outputs[1]
        window.workshopRecipeList:addItem(
            tostring(descriptor.displayName or recipe.key), {
                name = tostring(descriptor.displayName or recipe.key),
                category = "Recipe",
                stack = output and output.amount or 1,
                recipe = recipe,
            })
    end
    window.workshopStockpileList:clear()
    local inventoryRows = ViewModel.BuildInventoryRows(snapshot.storage,
        "", "name", {})
    for _, row in ipairs(inventoryRows) do
        if row.fullType ~= "PNC.RecipeBlueprint" then
            window.workshopStockpileList:addItem(row.name, row)
        end
    end
    if #recipes > 0 and (tonumber(window.workshopRecipeList.selected) or 0) <= 0 then
        window.workshopRecipeList.selected = 1
    end
    if #inventoryRows > 0 and (tonumber(window.workshopStockpileList.selected) or 0) <= 0 then
        window.workshopStockpileList.selected = 1
    end
    window.workshopRecipeIndex = cycle(window.workshopRecipeIndex, 0, #recipes)
    window.workshopItemIndex = cycle(window.workshopItemIndex, 0, #items)
    local selected = selectedRecipe(window, recipes)
    if selected and selected.descriptor then
        window:addDetail(getText("UI_PNC_Workshop_SelectedRecipe"),
            tostring(selected.descriptor.displayName or selected.key), "success")
        window:addDetail(getText("UI_PNC_Workshop_Quantity"),
            tostring(window.workshopQuantity))
        for index, input in ipairs(selected.descriptor.inputs or {}) do
            local available = selected.availability and selected.availability[index]
                or 0
            window:addDetail(input.consumed == false
                    and getText("UI_PNC_Workshop_RequiredTool")
                    or getText("UI_PNC_Workshop_RequiredMaterial"),
                table.concat(input.itemTypes or {}, " / ") .. "  "
                    .. tostring(input.amount) .. "  [" .. tostring(available) .. "]",
                available >= input.amount * (input.consumed == false and 1
                    or window.workshopQuantity) and "success" or "warning")
        end
        for _, skill in ipairs(selected.descriptor.requiredSkills or {}) do
            window:addDetail(getText("UI_PNC_Workshop_RequiredSkill"),
                tostring(skill.skillId) .. " " .. tostring(skill.level))
        end
    end
    local selectedStockItem = selectedItem(window, items)
    if selectedStockItem then window:addDetail(getText("UI_PNC_Workshop_SelectedItem"),
        tostring(selectedStockItem.name or selectedStockItem.fullType) .. " ×"
            .. tostring(selectedStockItem.quantity or selectedStockItem.stack or 1),
        "accent") end
    for _, resolved in ipairs(workshop.knownRecipes or {}) do
        window:addDetail(resolved.descriptor and resolved.descriptor.displayName
            or resolved.key, resolved.status,
            resolved.status == "AVAILABLE" and "success" or "warning")
    end
    for _, order in ipairs(workshop.orders or {}) do
        if order.operation ~= "RESEARCH" then
            window:addDetail(order.operation .. " " .. order.status,
                string.format("%.1f / %.1f WP", order.progress, order.requiredWork),
                order.blockedReason and "warning" or "accent")
            window:addDetail("WORKER / STATION",
                tostring(order.workerId or "UNASSIGNED") .. " / "
                    .. tostring(order.stationId or "UNCLAIMED"))
            if order.blockedReason then
                window:addDetail("BLOCKED", tostring(order.blockedReason), "warning")
            end
        end
    end
    for _, facility in ipairs(snapshot.settlement and snapshot.settlement.facilities or {}) do
        if facility.definitionId == "workshop" then
            for stationId, station in pairs(facility.workstations or {}) do
                window:addDetail("STATION " .. string.upper(stationId),
                    tostring(station.workOrderId or "AVAILABLE"))
            end
        end
    end
    return true
end

return Workshop
