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
local stationGroupingRequired = Internal.StationGroupingRequired
local addSkillHeader = Internal.AddSkillHeader
local addStationHeader = Internal.AddStationHeader
local groupExpanded = Internal.GroupExpanded
local skillGroupKey = Internal.SkillGroupKey
local stationGroupKey = Internal.StationGroupKey
local openStationBuild = Internal.OpenStationBuild
local canCraft = Internal.CanCraft
local quantityFor = Internal.QuantityFor
local selectedOrder = Internal.SelectedOrder

local function quantityControls(quantity, canAdjustQuantity)
    quantity = math.max(1, math.floor(tonumber(quantity) or 1))
    canAdjustQuantity = canAdjustQuantity == true
    return {
        { id = "quantity_minus", title = "-", command = "decrement",
            enabled = canAdjustQuantity and quantity > 1, variant = "quiet" },
        { id = "quantity_value", title = tostring(quantity), enabled = false,
            variant = "quiet" },
        { id = "quantity_plus", title = "+", command = "increment",
            enabled = canAdjustQuantity and quantity < 99, variant = "quiet" },
    }
end

local function actionControl(title, enabled, variant)
    return {
        { id = "catalog_action", title = title, command = "activate",
            enabled = enabled == true, variant = variant or "primary" },
    }
end

local function stationHeaderStatus(tr, stationRequired, stationResolved,
    missingStation)
    if missingStation then
        return {
            kind = "missing",
            missing = true,
            label = tr("UI_PNC_Workshop_MissingStation", "MISSING STATION"),
            actionLabel = tr("UI_PNC_Workshop_BuildStation", "BUILD STATION"),
            colorName = "warning",
        }
    end
    if not stationRequired then return nil end
    if not stationResolved then
        return {
            kind = "unresolved",
            label = tr("UI_PNC_Workshop_NoStation", "NO CRAFT STATION"),
            colorName = "warning",
        }
    end
    return nil
end

function Rebuild.OnControl(window, buttonValue)
    local action = tostring(buttonValue and buttonValue.internal or "")
    local selectable = window.workshopLaneSelectable
        or window.workshopLaneAvailability or {}
    if action == "tab_craft" and selectable.craft then
        window.workshopSubtab = "craft"; Rebuild.ApplySubtab(window, true); return true
    elseif action == "tab_salvage" and selectable.salvage then
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

local function rebuildQueue(window, orders)
    if not window.workshopQueueList then return end
    window.workshopQueueList:clear()
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
    local rows = {}
    for _, recipe in ipairs(recipes or {}) do
        if recipe and recipe.descriptor and recipe.status == "AVAILABLE" then
            rows[#rows + 1] = recipe
        end
    end
    if #rows == 0 then
        local message = tr("UI_PNC_Workshop_NoMatchingItems",
            "NO MATCHING ITEMS")
        window.workshopRecipeList:addItem(message, {
            name = message, restricted = true, catalogCells = {},
        })
        return
    end
    local activeSkill, activeStation, skillExpanded, stationExpanded,
        showStationHeaders
    for _, recipe in ipairs(sortBySkillAndStation(rows, "CRAFT")) do
        local skillId = productionSkillId(recipe, "CRAFT")
        if activeSkill ~= skillId then
            activeSkill, activeStation = skillId, nil
            showStationHeaders = stationGroupingRequired(rows, "CRAFT",
                skillId)
            local key = skillGroupKey("CRAFT", skillId)
            skillExpanded = groupExpanded(window, key)
            stationExpanded = not showStationHeaders
            addSkillHeader(window.workshopRecipeList, skillId, tr, key,
                skillExpanded)
        end
        if skillExpanded then
            local requiredStation = stationFor(recipe, "CRAFT")
            local stationKey = stationGroupKey("CRAFT", skillId,
                requiredStation)
            local stationResolved = requiredStation ~= nil
            local stationRequired = recipe.descriptor
                and recipe.descriptor.requiresSpecificWorkstation == true
            local stationUnresolved = stationRequired and not stationResolved
            local missingStation = stationResolved
                and not isStationReady(requiredStation) or false
            local headerStatus = stationHeaderStatus(tr, stationRequired,
                stationResolved, missingStation)
            if (showStationHeaders or missingStation) and (not activeStation
                or stationSortKey(activeStation, "CRAFT")
                    ~= stationSortKey(recipe, "CRAFT")
            ) then
                activeStation = { requiredStation = requiredStation }
                stationExpanded = groupExpanded(window, stationKey)
                addStationHeader(window.workshopRecipeList, requiredStation,
                    tr, stationKey, stationExpanded, headerStatus)
            end
            if stationExpanded then
            local output = recipe.descriptor.outputs
                and recipe.descriptor.outputs[1] or nil
            local fullType = output and output.itemTypes and output.itemTypes[1]
            local metadata, quantity = InventoryModel.Probe(fullType),
                quantityFor(window, recipe.id)
            local stocked = canCraft(recipe, quantity)
            local requiredStationReady = not stationRequired
                or stationResolved and not missingStation
            local canAdjustQuantity = requiredStationReady
            local enabled = stationUnresolved and false
                or missingStation or stocked and requiredStationReady
            local action = stationUnresolved
                and tr("UI_PNC_Workshop_NoStation", "NO CRAFT STATION")
                or missingStation
                and tr("UI_PNC_Workshop_BuildStation", "BUILD STATION")
                or stocked and requiredStationReady
                and tr("UI_PNC_Workshop_CraftAction", "CRAFT")
                or tr("UI_PNC_Workshop_MissingMaterials", "MISSING MATERIALS")
            local rowAction = missingStation and "" or action
            local rowActionControl
            if not missingStation then
                rowActionControl = actionControl(action, enabled,
                    enabled and "primary" or "warning")
            end
            window.workshopRecipeList:addItem(recipe.descriptor.displayName, {
                rowKind = "recipe", recipe = recipe, enabled = enabled,
                groupChild = true, groupKey = stationKey,
                restricted = not enabled and not missingStation,
                station = requiredStation, requiredStation = requiredStation,
                stationMissing = missingStation,
                name = tostring(recipe.descriptor.displayName or recipe.key),
                texture = metadata.texture, catalogCells = {
                    category = productionSkillLabel(skillId, tr),
                    quantity = tostring(quantity),
                    availability = stocked and "AVAILABLE" or "UNAVAILABLE",
                    action = rowAction },
                catalogControls = {
                    quantity = quantityControls(quantity, canAdjustQuantity),
                    action = rowActionControl,
                },
                catalogColors = { availability = stocked and "success"
                    or "warning", action = missingStation and "warning"
                    or enabled and "accent" or "warning" },
                capabilities = {
                    adjustQuantity = canAdjustQuantity,
                    queue = stocked and requiredStationReady,
                    buildStation = missingStation,
                    unresolvedStation = stationUnresolved,
                },
            })
            end
        end
    end
end

local function rebuildSalvageRows(window, candidates, tr, isStationReady)
    window.workshopSalvageList:clear()
    if #(candidates or {}) == 0 then
        local message = tr("UI_PNC_Workshop_NoMatchingItems",
            "NO MATCHING ITEMS")
        window.workshopSalvageList:addItem(message, {
            name = message, restricted = true, catalogCells = {},
        })
        return
    end
    local activeSkill, activeStation, skillExpanded, stationExpanded,
        showStationHeaders = nil, nil, nil, nil, nil
    for _, candidate in ipairs(sortBySkillAndStation(
        candidates or {}, "DISASSEMBLE")) do
        local skillId = productionSkillId(candidate, "DISASSEMBLE")
        if activeSkill ~= skillId then
            activeSkill, activeStation = skillId, nil
            showStationHeaders = stationGroupingRequired(candidates,
                "DISASSEMBLE", skillId)
            local key = skillGroupKey("DISASSEMBLE", skillId)
            skillExpanded = groupExpanded(window, key)
            stationExpanded = not showStationHeaders
            addSkillHeader(window.workshopSalvageList, skillId, tr, key,
                skillExpanded)
        end
        if skillExpanded then
            local requiredStation = stationFor(candidate, "DISASSEMBLE")
            local stationKey = stationGroupKey("DISASSEMBLE", skillId,
                requiredStation)
            local stationResolved = requiredStation ~= nil
            local stationRequired = stationResolved
            local missingStation = stationResolved
                and not isStationReady(requiredStation) or false
            local headerStatus = stationHeaderStatus(tr, stationRequired,
                stationResolved, missingStation)
            if (showStationHeaders or missingStation) and (not activeStation
                or stationSortKey(activeStation, "DISASSEMBLE")
                    ~= stationSortKey(candidate, "DISASSEMBLE")
            ) then
                activeStation = { requiredStation = requiredStation }
                stationExpanded = groupExpanded(window, stationKey)
                addStationHeader(window.workshopSalvageList, requiredStation,
                    tr, stationKey, stationExpanded, headerStatus)
            end
            if stationExpanded then
        local metadata = InventoryModel.Probe(candidate.fullType)
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
        local action = missingStation
            and tr("UI_PNC_Workshop_BuildStation", "BUILD STATION")
            or enabled and tr("UI_PNC_Workshop_SalvageAction", "SALVAGE")
            or tr("UI_PNC_Workshop_NoStation", "NO CRAFT STATION")
        local rowAction = missingStation and "" or action
        local rowActionControl
        if not missingStation then
            rowActionControl = actionControl(action, enabled,
                enabled and "primary" or "warning")
        end
        local row = { rowKind = "salvage", enabled = enabled,
            groupChild = true, groupKey = stationKey,
            restricted = not enabled and not missingStation,
            station = requiredStation, requiredStation = requiredStation,
            stationMissing = missingStation, fullType = candidate.fullType,
            name = tostring(metadata.name or candidate.fullType),
            texture = metadata.texture, recordIndex = candidate.recordIndex,
            catalogCells = { category = productionSkillLabel(skillId, tr),
                quantity = tostring(candidate.quantity), availability = yieldText,
                action = rowAction },
            catalogControls = { action = rowActionControl },
            catalogColors = { availability = #yields > 0 and "success" or "warning",
                action = missingStation and "warning"
                    or enabled and "accent" or "warning" } }
        window.workshopSalvageList:addItem(row.name, row)
    end
        end
    end
end


Internal.RebuildQueue = rebuildQueue
Internal.RebuildCraftRows = rebuildCraftRows
Internal.RebuildSalvageRows = rebuildSalvageRows

return Rebuild
