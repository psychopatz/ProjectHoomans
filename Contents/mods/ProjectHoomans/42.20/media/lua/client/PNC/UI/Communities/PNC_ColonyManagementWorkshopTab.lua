require "PNC/UI/Inventory/PNC_InventoryUI_List"

local Workshop = {}
local InventoryModel = require "PNC/UI/Inventory/PNC_InventoryUI_Model"
local UI = PsychopatzCore and PsychopatzCore.UI or nil
local FacilityState = require "PNC/Core/Settlement/PNC_FacilityState"
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
    return UIBuilder.CreateButton(window, { id = id, title = getText(key),
        target = window, onclick = ISPNCColonyManagementWindow.onWorkshopControl,
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

local function setButtonState(button, selected, enabled)
    if not button then return end
    button:setEnable(enabled == true)
    if UI and UI.SetButtonVariant then
        UI.SetButtonVariant(button, selected and "selected" or "quiet")
    end
end

local function applySubtab(window, active)
    local availability = window.workshopLaneAvailability or {}
    if availability[window.workshopSubtab] ~= true then
        window.workshopSubtab = availability.craft and "craft"
            or availability.salvage and "salvage" or "craft"
    end
    setButtonState(window.workshopCraftTab,
        window.workshopSubtab == "craft", availability.craft)
    setButtonState(window.workshopSalvageTab,
        window.workshopSubtab == "salvage", availability.salvage)
    if window.workshopRecipeList.setVisible then
        window.workshopRecipeList:setVisible(active
            and window.workshopSubtab == "craft")
    end
    if window.workshopSalvageList.setVisible then
        window.workshopSalvageList:setVisible(active
            and window.workshopSubtab == "salvage")
    end
end

function Workshop.Apply(window, active)
    window.workshopPause:setVisible(active)
    window.workshopCancel:setVisible(active)
    window.workshopCraftTab:setVisible(active)
    window.workshopSalvageTab:setVisible(active)
    window.workshopQueueList:setVisible(active)
    if active then window.detailsPane:setVisible(false) end
    applySubtab(window, active)
end

local function activeOrders(snapshot)
    local output = {}
    for _, order in ipairs(snapshot.workshop and snapshot.workshop.orders or {}) do
        if (order.operation == "CRAFT" or order.operation == "DISASSEMBLE")
            and order.status ~= "COMPLETED" and order.status ~= "CANCELLED"
        then output[#output + 1] = order end
    end
    return output
end

local function defaultStation()
    local definitions = PNC and PNC.WorkDefinitions or nil
    local station = definitions and definitions.GetStation
        and definitions.GetStation("CRAFT") or nil
    return station or {
        id = "workshop", facilityId = "workshop",
        capability = "work.craft", role = "work.craft",
        legacyRoles = { "work.disassemble" },
        labelKey = "UI_PNC_Workshop_CraftingStation",
    }
end

local function stationFor(entry, operation)
    return entry and entry.requiredStation
        or defaultStation()
end

local function stationLabel(station, tr)
    local key = station and station.labelKey
        or "UI_PNC_Workshop_CraftingStation"
    return tr(key, key)
end

local function hasStation(snapshot, station)
    local facilityId = station and station.facilityId or "workshop"
    local role = station and station.role or "work.craft"
    for _, facility in ipairs(snapshot.settlement
        and snapshot.settlement.facilities or {}) do
        if facility.definitionId == facilityId
            and FacilityState.IsBuilt(facility)
        then
            for _, component in ipairs(facility.components or {}) do
                if component.role == role then return true end
                for _, legacyRole in ipairs(station.legacyRoles or {}) do
                    if component.role == legacyRole then return true end
                end
            end
        end
    end
    return false
end

local function stationSortKey(entry, operation)
    local station = stationFor(entry, operation)
    return tostring(station and station.id or "workshop")
end

local function productionSkillId(entry, operation)
    local station = stationFor(entry, operation)
    local work = PNC and PNC.WorkDefinitions or nil
    if work and work.GetProductionSkillId then
        return work.GetProductionSkillId(entry and entry.descriptor, station)
    end
    return entry and entry.productionSkillId
        or station and station.productionSkillId
end

local function productionSkillLabel(skillId, tr)
    local work = PNC and PNC.WorkDefinitions or nil
    local label = work and work.GetProductionSkillLabel
        and work.GetProductionSkillLabel(skillId) or skillId
    if not label or label == "" then
        return tr("UI_PNC_Workshop_OtherSkill", "Other production")
    end
    return tostring(label)
end

local function skillSortKey(entry, operation)
    local skillId = productionSkillId(entry, operation)
    local order = PNC and PNC.WorkDefinitions
        and PNC.WorkDefinitions.CRAFTING_SKILL_ORDER or {}
    for index, value in ipairs(order) do
        if value == skillId then return string.format("%03d", index) end
    end
    return string.format("%03d:%s", #order + 1, tostring(skillId or ""))
end

local function sortBySkillAndStation(values, operation)
    local output = {}
    for _, value in ipairs(values or {}) do output[#output + 1] = value end
    table.sort(output, function(left, right)
        local leftSkill, rightSkill = skillSortKey(left, operation),
            skillSortKey(right, operation)
        if leftSkill ~= rightSkill then return leftSkill < rightSkill end
        local leftStation, rightStation = stationSortKey(left, operation),
            stationSortKey(right, operation)
        if leftStation ~= rightStation then return leftStation < rightStation end
        local leftName = left.descriptor and left.descriptor.displayName
            or left.fullType or left.name or ""
        local rightName = right.descriptor and right.descriptor.displayName
            or right.fullType or right.name or ""
        return tostring(leftName) < tostring(rightName)
    end)
    return output
end

local function addSkillHeader(list, skillId, tr)
    local label = productionSkillLabel(skillId, tr)
    list:addItem("skill:" .. tostring(skillId or "other"), {
        name = label, restricted = true, catalogHeader = true,
        skillHeader = true,
        catalogCells = { category = label, quantity = "", availability = "",
            action = "" },
    })
end

local function addStationHeader(list, station, tr)
    local label = stationLabel(station, tr)
    list:addItem("station:" .. tostring(station and station.id or "workshop"), {
        name = label, restricted = true, catalogHeader = true,
        stationHeader = true,
        catalogCells = { category = label, quantity = "", availability = "",
            action = "" },
    })
end

local function openStationBuild(window, station)
    local settlement = window.snapshot and window.snapshot.settlement
    if not settlement then return false end
    local BuildModal = require "PNC/UI/Communities/ColonyManagement/PNC_FacilityBuildModal"
    local Facility = require "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_FacilityActions"
    BuildModal.Open(settlement, function(definitionId)
        return Facility.BeginBuild(window, definitionId)
    end, window.snapshot.storage, window.snapshot.research,
        station and station.facilityId or "workshop")
    return true
end

local function canCraft(resolved, quantity)
    for index, input in ipairs(resolved.descriptor and resolved.descriptor.inputs
        or {}) do
        local required = math.max(1, tonumber(input.amount) or 1)
            * (input.consumed == false and 1 or quantity)
        if (tonumber(resolved.availability and resolved.availability[index]) or 0)
            < required then return false end
    end
    return resolved.status == "AVAILABLE"
end

local function quantityFor(window, recipeId)
    local id = tostring(recipeId or "")
    local quantity = math.max(1, math.min(99,
        math.floor(tonumber(window.workshopQuantities[id]) or 1)))
    window.workshopQuantities[id] = quantity
    return quantity
end

function Workshop.OnCatalogCell(window, row, key, localX, width)
    if row.enabled ~= true then return end
    if row.rowKind == "recipe" then
        local quantity = quantityFor(window, row.recipe.id)
        if key == "quantity" then
            quantity = math.max(1, math.min(99, quantity
                + (localX >= width * 0.5 and 1 or -1)))
            window.workshopQuantities[tostring(row.recipe.id)] = quantity
            window:rebuildDetails()
        elseif key == "action" then
            if row.stationMissing then
                openStationBuild(window, row.requiredStation)
            elseif canCraft(row.recipe, quantity) then
                PNC.Client.RequestColonyAction("craft_queue",
                    { recipeId = row.recipe.id, quantity = quantity })
            end
        end
    elseif row.rowKind == "salvage" and key == "action" then
        if row.stationMissing then
            openStationBuild(window, row.requiredStation)
        else
            PNC.Client.RequestColonyAction("disassemble_queue",
                { recordIndex = row.recordIndex })
        end
    end
end

local function selectedOrder(window)
    local row = window.workshopQueueList:selectedRow()
    return row and row.order or activeOrders(window.snapshot or {})[1]
end

function Workshop.OnControl(window, buttonValue)
    local action = tostring(buttonValue and buttonValue.internal or "")
    if action == "tab_craft" and window.workshopLaneAvailability.craft then
        window.workshopSubtab = "craft"; applySubtab(window, true); return true
    elseif action == "tab_salvage" and window.workshopLaneAvailability.salvage then
        window.workshopSubtab = "salvage"; applySubtab(window, true); return true
    end
    local order = selectedOrder(window)
    if action == "pause" and order then
        PNC.Client.RequestColonyAction("work_pause", { workOrderId = order.id,
            paused = order.status ~= "PAUSED" }); return true
    elseif action == "cancel" and order then
        PNC.Client.RequestColonyAction("work_cancel", { workOrderId = order.id })
        return true
    end
    return false
end

local function addCatalogHeader(list, name, availabilityTitle)
    list:addItem(name, { name = name, restricted = true, catalogHeader = true,
        catalogCells = { category = "CATEGORY", quantity = "COUNT",
            availability = availabilityTitle or "STOCK", action = "ACTION" } })
end

local function rebuildQueue(window, orders)
    if not window.workshopQueueList then return end
    window.workshopQueueList:clear()
    window.workshopQueueList:addItem("PRODUCTION QUEUE", { name = "PRODUCTION QUEUE",
        restricted = true, catalogHeader = true,
        catalogCells = { worker = "WORKER", progress = "PROGRESS" } })
    for _, order in ipairs(orders) do
        local required = math.max(1, tonumber(order.requiredWork) or 1)
        local percent = math.floor(math.min(1,
            (tonumber(order.progress) or 0) / required) * 100 + 0.5)
        window.workshopQueueList:addItem(order.operation, { name = order.operation,
            order = order, catalogCells = {
                worker = tostring(order.workerId or "UNASSIGNED"),
                progress = tostring(percent) .. "%  " .. tostring(order.status),
            }, catalogColors = { progress = order.blockedReason
                and "warning" or "accent" } })
    end
end

function Workshop.Rebuild(window, snapshot, tr)
    if window.tab ~= "workshop" then return false end
    local workshop = snapshot.workshop or {}
    local stationAvailability = {}
    local function isStationReady(station)
        local id = tostring(station and station.id or "workshop")
        if stationAvailability[id] == nil then
            stationAvailability[id] = hasStation(snapshot, station)
        end
        return stationAvailability[id]
    end
    local sharedStation = defaultStation()
    local stationReady = isStationReady(sharedStation)
    local function anyKnownStationReady(values, operation)
        if stationReady then return true end
        for _, value in ipairs(values or {}) do
            if isStationReady(stationFor(value, operation)) then return true end
        end
        return false
    end
    local craftStationReady = anyKnownStationReady(workshop.knownRecipes, "CRAFT")
    local salvageStationReady = anyKnownStationReady(
        workshop.disassemblyCandidates, "DISASSEMBLE")
    window.workshopLaneAvailability = {
        -- Crafting and salvaging are different work types. They can use
        -- different direct workstation definitions, while each recipe still
        -- resolves to the same physical station for both operations.
        craft = craftStationReady,
        salvage = salvageStationReady,
    }
    rebuildQueue(window, activeOrders(snapshot))
    window.workshopRecipeList:clear()
    addCatalogHeader(window.workshopRecipeList,
        tr("UI_PNC_Workshop_Craftable", "CRAFTABLE ITEMS"))
    local recipes = {}
    for _, recipe in ipairs(workshop.knownRecipes or {}) do
        if recipe and recipe.descriptor and recipe.status == "AVAILABLE" then
            recipes[#recipes + 1] = recipe
        end
    end
    local activeSkill, activeStation
    for _, recipe in ipairs(sortBySkillAndStation(recipes, "CRAFT")) do
        local skillId = productionSkillId(recipe, "CRAFT")
        if activeSkill ~= skillId then
            activeSkill, activeStation = skillId, nil
            addSkillHeader(window.workshopRecipeList, skillId, tr)
        end
        local requiredStation = stationFor(recipe, "CRAFT")
        if not activeStation
            or stationSortKey(activeStation, "CRAFT")
                ~= stationSortKey(recipe, "CRAFT")
        then
            activeStation = { requiredStation = requiredStation }
            addStationHeader(window.workshopRecipeList, requiredStation, tr)
        end
            local output = recipe.descriptor.outputs
                and recipe.descriptor.outputs[1] or nil
            local fullType = output and output.itemTypes and output.itemTypes[1]
            local metadata, quantity = InventoryModel.Probe(fullType),
                quantityFor(window, recipe.id)
            local stocked = canCraft(recipe, quantity)
            local missingStation = not isStationReady(requiredStation)
            local requiredStationReady = not missingStation
            local enabled = missingStation or stocked and requiredStationReady
            local action = missingStation
                and tr("UI_PNC_Workshop_BuildStation", "BUILD STATION")
                or stocked and requiredStationReady
                and tr("UI_PNC_Workshop_CraftAction", "CRAFT")
                or tr("UI_PNC_Workshop_MissingMaterials", "MISSING MATERIALS")
            window.workshopRecipeList:addItem(recipe.descriptor.displayName, {
                rowKind = "recipe", recipe = recipe, enabled = enabled,
                restricted = not enabled and not missingStation,
                station = requiredStation, requiredStation = requiredStation,
                stationMissing = missingStation,
                name = tostring(recipe.descriptor.displayName or recipe.key),
                texture = metadata.texture, catalogCells = {
                    category = productionSkillLabel(skillId, tr),
                    quantity = "-  " .. tostring(quantity) .. "  +",
                    availability = stocked and "AVAILABLE" or "UNAVAILABLE",
                    action = action },
                catalogColors = { availability = stocked and "success"
                    or "warning", action = missingStation and "warning"
                    or enabled and "accent" or "warning" },
            })
    end
    window.workshopSalvageList:clear()
    addCatalogHeader(window.workshopSalvageList,
        tr("UI_PNC_Workshop_Salvageable", "SALVAGEABLE ITEMS"),
        tr("UI_PNC_Workshop_PotentialYield", "POTENTIAL YIELD"))
    activeSkill, activeStation = nil, nil
    for _, candidate in ipairs(sortBySkillAndStation(
        workshop.disassemblyCandidates or {}, "DISASSEMBLE")) do
        local skillId = productionSkillId(candidate, "DISASSEMBLE")
        if activeSkill ~= skillId then
            activeSkill, activeStation = skillId, nil
            addSkillHeader(window.workshopSalvageList, skillId, tr)
        end
        local requiredStation = stationFor(candidate, "DISASSEMBLE")
        if not activeStation
            or stationSortKey(activeStation, "DISASSEMBLE")
                ~= stationSortKey(candidate, "DISASSEMBLE")
        then
            activeStation = { requiredStation = requiredStation }
            addStationHeader(window.workshopSalvageList, requiredStation, tr)
        end
        local metadata = InventoryModel.Probe(candidate.fullType)
        local missingStation = not isStationReady(requiredStation)
        local requiredStationReady = not missingStation
        local enabled = missingStation or requiredStationReady
        local yields = {}
        for _, value in ipairs(candidate.potentialYield or {}) do
            local yieldMetadata = InventoryModel.Probe(value.fullType)
            local quantity = tonumber(value.maximum) or 0
            yields[#yields + 1] = tostring(quantity) .. "x "
                .. tostring(yieldMetadata.name or value.fullType)
        end
        local yieldText = #yields > 0 and table.concat(yields, ", ") or "NONE"
        local row = { rowKind = "salvage", enabled = enabled,
            restricted = not enabled and not missingStation,
            station = requiredStation, requiredStation = requiredStation,
            stationMissing = missingStation, fullType = candidate.fullType,
            name = tostring(metadata.name or candidate.fullType),
            texture = metadata.texture, recordIndex = candidate.recordIndex,
            catalogCells = { category = productionSkillLabel(skillId, tr),
                quantity = tostring(candidate.quantity), availability = yieldText,
                action = missingStation
                    and tr("UI_PNC_Workshop_BuildStation", "BUILD STATION")
                    or enabled and tr("UI_PNC_Workshop_SalvageAction", "SALVAGE")
                    or tr("UI_PNC_Workshop_NoStation", "NO CRAFT STATION") },
            catalogColors = { availability = #yields > 0 and "success" or "warning",
                action = missingStation and "warning"
                    or enabled and "accent" or "warning" } }
        window.workshopSalvageList:addItem(row.name, row)
    end
    applySubtab(window, true)
    return true
end

return Workshop
