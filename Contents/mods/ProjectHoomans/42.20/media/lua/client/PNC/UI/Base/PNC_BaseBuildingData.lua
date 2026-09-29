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

-- Sum matching stock rows. Availability is additive across stacks of the same
-- type; the previous max() under-reported a material spread over several
-- stacks and could show a build as unaffordable when it was affordable.
local function storedCount(storage, types)
    local total = 0
    for _, row in ipairs(storage and storage.rows or {}) do
        for _, fullType in ipairs(types or {}) do
            if tostring(row.fullType or "") == tostring(fullType or "") then
                total = total + math.max(0,
                    math.floor(tonumber(row.quantity) or 0))
            end
        end
    end
    return total
end

-- Quantity, not stack count. getItemsFromType lists stacks, and one stack can
-- hold more than one unit.
local function playerCount(types)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local inventory = player and player.getInventory
        and player:getInventory() or nil
    if not inventory or not inventory.getItemsFromType then return 0 end
    local total = 0
    for _, fullType in ipairs(types or {}) do
        local values = inventory:getItemsFromType(fullType, true)
        local size = values and values.size and tonumber(values:size()) or 0
        if size > 0 then
            if type(values.get) ~= "function" then
                -- Lightweight list stub (isolated smoke tests).
                total = total + size
            else
                for index = 0, size - 1 do
                    local item = values:get(index)
                    total = total + math.max(1, math.floor(tonumber(
                        item and item.getCount and item:getCount() or 1)
                        or 1))
                end
            end
        end
    end
    return total
end

--[[
    The Base window polls its own lightweight snapshot, while the Colony
    Storage window polls the colony-management one. The base projection now
    carries the stockpile rows; when it does not (an older server, or before
    the first base poll lands), reuse the cached management projection rather
    than pricing every requirement at zero.
]]
local function stockpileFor(window)
    local base = window and window.snapshot and window.snapshot.storage or nil
    if base and type(base.rows) == "table" then return base end
    local ClientState = PNC.Network and PNC.Network.ClientState or nil
    local management = ClientState and ClientState.colonyManagement or nil
    local fallback = management and management.storage or nil
    if fallback and type(fallback.rows) == "table" then return fallback end
    return base or fallback
end

-- Stockpile projection the build UI prices requirements against. Exported so
-- the view passes the same storage into BuildOptions that the requirement rows
-- use; passing snapshot.storage directly is what produced "0 in stock".
function Data.Stockpile(window, snapshot)
    if snapshot and snapshot ~= (window and window.snapshot) then
        if type(snapshot.storage) == "table"
            and type(snapshot.storage.rows) == "table"
        then
            return snapshot.storage
        end
    end
    return stockpileFor(window)
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

--[[
    Availability for a native build requirement list, computed from the
    stockpile projection the Base window now receives.

    Mirrors the server's BuildingService requirement snapshot, including summing
    alternative item types the way CountProductionAvailable does, so a recipe
    row built on the client reports the same available/ready numbers the server
    would use when it reserves the materials.
]]
function Data.MaterialAvailability(storage, requirements)
    local output = {}
    for _, requirement in ipairs(requirements or {}) do
        local types = requirement.itemTypes or costTypes(requirement)
        local names = {}
        for _, fullType in ipairs(types or {}) do
            names[#names + 1] = tostring(fullType)
        end
        local amount = math.max(1, math.floor(
            tonumber(requirement.amount) or 1))
        local available = storedCount(storage, types)
        output[#output + 1] = {
            itemTypes = types,
            names = names,
            amount = amount,
            consumed = requirement.consumed ~= false,
            available = available,
            ready = available >= amount,
        }
    end
    return output
end

function Data.MaterialRows(window, option)
    local rows = {}
    if not option then return rows end
    local definition = PNC.FacilityDefinitions
        and PNC.FacilityDefinitions.Get(option.id) or nil
    local fromPlayer = definition and definition.bootstrapFromPlayer == true
    local storage = fromPlayer and nil or stockpileFor(window)
    for _, cost in ipairs(option.buildMaterials or {}) do
        local types = costTypes(cost)
        local fullType = types[1]
        local required = math.max(0, math.floor(tonumber(
            cost.amount or cost.quantity) or 0))
        local available = fromPlayer and playerCount(types)
            or storedCount(storage, types)
        local metadata = InventoryModel.Probe(fullType)
        rows[#rows + 1] = {
            fullType = fullType,
            name = metadata.name or fullType or "ITEM",
            texture = metadata.texture,
            required = required,
            available = available,
            ready = available >= required,
            source = fromPlayer and "PLAYER" or "STOCKPILE",
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
