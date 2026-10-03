local Rebuild = {}
local UI = PsychopatzCore and PsychopatzCore.UI or nil
local InventoryModel = require "PNC/UI/Inventory/PNC_InventoryUI_Model"
local FacilityState = require "PNC/Core/Settlement/PNC_FacilityState"

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

Rebuild.ApplySubtab = applySubtab

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
    local BuildModal = require "PNC/UI/SettlementManagement/PNC_SettlementManagement_FacilityBuildModal"
    local Facility = require "PNC/UI/SettlementManagement/PNC_SettlementManagement_FacilityActions"
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

function Rebuild.OnCatalogCell(window, row, key, localX, width)
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


PNC = PNC or {}
PNC.WorkshopCatalogRebuild = Rebuild
Rebuild.Internal = Rebuild.Internal or {}
local Internal = Rebuild.Internal
Internal.ActiveOrders = activeOrders
Internal.DefaultStation = defaultStation
Internal.StationFor = stationFor
Internal.StationLabel = stationLabel
Internal.HasStation = hasStation
Internal.StationSortKey = stationSortKey
Internal.ProductionSkillId = productionSkillId
Internal.ProductionSkillLabel = productionSkillLabel
Internal.SkillSortKey = skillSortKey
Internal.SortBySkillAndStation = sortBySkillAndStation
Internal.AddSkillHeader = addSkillHeader
Internal.AddStationHeader = addStationHeader
Internal.OpenStationBuild = openStationBuild
Internal.CanCraft = canCraft
Internal.QuantityFor = quantityFor
Internal.SelectedOrder = selectedOrder

return Rebuild
