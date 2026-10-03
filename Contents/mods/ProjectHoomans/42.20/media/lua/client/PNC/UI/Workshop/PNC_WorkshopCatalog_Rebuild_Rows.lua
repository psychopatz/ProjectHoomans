-- Workshop queue, craft, and salvage row providers.

PNC = PNC or {}
local Rebuild = PNC.WorkshopCatalogRebuild
local Internal = Rebuild.Internal or {}
Rebuild.Internal = Internal
local UI = PsychopatzCore and PsychopatzCore.UI or nil
local InventoryModel = require "PNC/UI/Inventory/PNC_InventoryUI_Model"
local FacilityState = require "PNC/Core/Settlement/PNC_FacilityState"
local activeOrders = Internal.ActiveOrders
local stationFor = Internal.StationFor
local stationLabel = Internal.StationLabel
local stationSortKey = Internal.StationSortKey
local productionSkillId = Internal.ProductionSkillId
local productionSkillLabel = Internal.ProductionSkillLabel
local sortBySkillAndStation = Internal.SortBySkillAndStation
local addSkillHeader = Internal.AddSkillHeader
local addStationHeader = Internal.AddStationHeader
local openStationBuild = Internal.OpenStationBuild
local canCraft = Internal.CanCraft
local quantityFor = Internal.QuantityFor
local selectedOrder = Internal.SelectedOrder

function Rebuild.OnControl(window, buttonValue)
    local action = tostring(buttonValue and buttonValue.internal or "")
    if action == "tab_craft" and window.workshopLaneAvailability.craft then
        window.workshopSubtab = "craft"; Rebuild.ApplySubtab(window, true); return true
    elseif action == "tab_salvage" and window.workshopLaneAvailability.salvage then
        window.workshopSubtab = "salvage"; Rebuild.ApplySubtab(window, true); return true
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

local function rebuildCraftRows(window, recipes, tr, isStationReady)
    window.workshopRecipeList:clear()
    addCatalogHeader(window.workshopRecipeList,
        tr("UI_PNC_Workshop_Craftable", "CRAFTABLE ITEMS"))
    local rows = {}
    for _, recipe in ipairs(recipes or {}) do
        if recipe and recipe.descriptor and recipe.status == "AVAILABLE" then
            rows[#rows + 1] = recipe
        end
    end
    local activeSkill, activeStation
    for _, recipe in ipairs(sortBySkillAndStation(rows, "CRAFT")) do
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
end

local function rebuildSalvageRows(window, candidates, tr, isStationReady)
    window.workshopSalvageList:clear()
    addCatalogHeader(window.workshopSalvageList,
        tr("UI_PNC_Workshop_Salvageable", "SALVAGEABLE ITEMS"),
        tr("UI_PNC_Workshop_PotentialYield", "POTENTIAL YIELD"))
    local activeSkill, activeStation = nil, nil
    for _, candidate in ipairs(sortBySkillAndStation(
        candidates or {}, "DISASSEMBLE")) do
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
end


Internal.RebuildQueue = rebuildQueue
Internal.RebuildCraftRows = rebuildCraftRows
Internal.RebuildSalvageRows = rebuildSalvageRows

return Rebuild
