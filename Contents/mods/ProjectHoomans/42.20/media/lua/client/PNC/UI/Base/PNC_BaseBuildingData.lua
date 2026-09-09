local InventoryModel = require "PNC/UI/Inventory/PNC_InventoryUI_Model"

local Data = {}

Data.PAGE_SIZE = 4
Data.CATEGORY_ORDER = { "housing", "food", "technology",
    "utilities", "production" }

local function costTypes(cost)
    local types = cost and (cost.itemTypes or cost.types or cost.items)
    if type(types) == "table" then return types end
    if cost and (cost.fullType or cost.itemType or cost.type) then
        return { cost.fullType or cost.itemType or cost.type }
    end
    return {}
end

local function storedCount(storage, types)
    local total = 0
    for _, row in ipairs(storage and storage.rows or {}) do
        for _, fullType in ipairs(types or {}) do
            if tostring(row.fullType or "") == tostring(fullType or "") then
                total = math.max(total,
                    math.floor(tonumber(row.quantity) or 0))
            end
        end
    end
    return total
end

local function playerCount(types)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local inventory = player and player.getInventory
        and player:getInventory() or nil
    local best = 0
    for _, fullType in ipairs(types or {}) do
        local values = inventory and inventory.getItemsFromType
            and inventory:getItemsFromType(fullType, true) or nil
        if values and values.size then best = math.max(best, values:size()) end
    end
    return best
end

function Data.SelectedOption(window)
    for _, option in ipairs(window.baseBuildingOptions or {}) do
        if tostring(option.id) == tostring(window.baseBuildingSelectedID) then
            return option
        end
    end
    return nil
end

function Data.FilteredOptions(window)
    local output = {}
    local search = window.baseBuildingSearch and window.baseBuildingSearch:getText()
        or ""
    search = string.lower(tostring(search or ""))
    for _, option in ipairs(window.baseBuildingOptions or {}) do
        local categoryMatches = window.baseBuildingCategory == "ALL"
            or tostring(option.category) == tostring(window.baseBuildingCategory)
        local text = string.lower(table.concat({ tostring(option.name or ""),
            tostring(option.id or ""), tostring(option.status or "") }, " "))
        if categoryMatches and (search == ""
            or string.find(text, search, 1, true) ~= nil)
        then
            output[#output + 1] = option
        end
    end
    return output
end

-- The legacy facility catalog contains room facilities and direct workstation
-- facilities. Keep that provider intact as one NPC-facing catalog: bedrooms,
-- hospitals, farms, and crafting stations all have facility behavior that the
-- vanilla recipe browser must not own.
function Data.CatalogOptions(options, catalogKind)
    local output = {}
    for _, option in ipairs(options or {}) do
        local include = catalogKind == "facilities"
            and option.id ~= "stockpile"
        if include then output[#output + 1] = option end
    end
    return output
end

function Data.Categories(options)
    local seen = {}
    local categories = {}
    for _, option in ipairs(options or {}) do
        local category = tostring(option.category or "production")
        if not seen[category] then
            seen[category] = true
            categories[#categories + 1] = category
        end
    end
    table.sort(categories, function(left, right)
        local leftRank, rightRank = 1000, 1000
        for index, value in ipairs(Data.CATEGORY_ORDER) do
            if value == left then leftRank = index end
            if value == right then rightRank = index end
        end
        local skillOrder = PNC.WorkDefinitions
            and PNC.WorkDefinitions.CRAFTING_SKILL_ORDER or {}
        for index, value in ipairs(skillOrder) do
            if value == left then leftRank = 100 + index end
            if value == right then rightRank = 100 + index end
        end
        if leftRank ~= rightRank then return leftRank < rightRank end
        return tostring(left) < tostring(right)
    end)
    return categories, seen
end

function Data.MaterialRows(window, option)
    local rows = {}
    if not option then return rows end
    local definition = PNC.FacilityDefinitions
        and PNC.FacilityDefinitions.Get(option.id) or nil
    for _, cost in ipairs(option.buildMaterials or {}) do
        local types = costTypes(cost)
        local fullType = types[1]
        local required = math.max(0, math.floor(tonumber(
            cost.amount or cost.quantity) or 0))
        local available = definition and definition.bootstrapFromPlayer == true
            and playerCount(types) or storedCount(window.snapshot
                and window.snapshot.storage, types)
        local metadata = InventoryModel.Probe(fullType)
        rows[#rows + 1] = {
            fullType = fullType,
            name = metadata.name or fullType or "ITEM",
            texture = metadata.texture,
            required = required,
            available = available,
            ready = available >= required,
            source = definition and definition.bootstrapFromPlayer == true
                and "PLAYER" or "STOCKPILE",
        }
    end
    return rows
end

function Data.NativeQueueRows(snapshot)
    local rows = {}
    for _, order in ipairs(snapshot.building and snapshot.building.queue or {}) do
        rows[#rows + 1] = {
            id = order.id, order = order,
            title = order.displayName or order.objectInfoName or "BLUEPRINT",
            worker = order.workerName or "UNASSIGNED",
            percent = order.percent or 0, status = order.status or "QUEUED",
        }
    end
    return rows
end

return Data
