local Items = require "PNC/UI/Research/PNC_ResearchModel_Items"
local Shared = require
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"

local Model = {}
local GROUPS = {
    colony_upgrades = { titleKey = "UI_PNC_Research_Group_ColonyUpgrades",
        fallback = "COLONY UPGRADES", order = 10 },
    utilities = { titleKey = "UI_PNC_Research_Group_Utilities",
        fallback = "UTILITIES", order = 20 },
    facilities = { titleKey = "UI_PNC_Research_Group_Facilities",
        fallback = "FACILITIES", order = 30 },
    blueprints = { titleKey = "UI_PNC_Research_Group_Blueprints",
        fallback = "BLUEPRINTS", order = 40, sourceGroup = true },
    books = { titleKey = "UI_PNC_Research_Group_Books",
        fallback = "RECIPE BOOKS", order = 50, sourceGroup = true },
}
local FILTERS = { all = true, technology = true, blueprint = true, book = true }

local function number(value, fallback)
    value = tonumber(value)
    return value ~= nil and value or fallback
end

local function translate(key, fallback)
    if key == nil or key == "" then return fallback end
    return Shared.Tr(key, fallback)
end

local function groupSpec(entry, source)
    local id = source == "blueprint" and "blueprints"
        or source == "book" and "books" or entry and entry.groupId
    id = tostring(id or "utilities")
    local fallback = GROUPS[id] or { titleKey = "UI_PNC_Research_Group_Utilities",
        fallback = string.upper(id), order = 100 }
    return {
        id = id, titleKey = entry and entry.groupTitleKey or fallback.titleKey,
        titleFallback = fallback.fallback,
        order = number(entry and entry.groupOrder, fallback.order),
        sourceGroup = fallback.sourceGroup == true,
    }
end

local function addGroup(groups, byID, spec)
    local group = byID[spec.id]
    if group then
        group.order = math.min(group.order, spec.order)
        return group
    end
    group = {
        id = spec.id, titleKey = spec.titleKey,
        title = translate(spec.titleKey, spec.titleFallback), order = spec.order,
        sourceGroup = spec.sourceGroup == true, items = {}, knownCount = 0,
        activeCount = 0, availableCount = 0,
    }
    byID[spec.id] = group
    groups[#groups + 1] = group
    return group
end

local function appendItem(group, item)
    group.items[#group.items + 1] = item
    if item.known then group.knownCount = group.knownCount + 1 end
    if item.order then group.activeCount = group.activeCount + 1 end
    if item.researchable then group.availableCount = group.availableCount + 1 end
end

local function include(item, filter)
    return filter == "all" or item.source == filter
end

local function sortItems(left, right)
    local leftOrder = number(left.itemOrder, 100000)
    local rightOrder = number(right.itemOrder, 100000)
    if leftOrder ~= rightOrder then return leftOrder < rightOrder end
    return string.lower(left.name) < string.lower(right.name)
end

local function sortGroups(left, right)
    if left.order ~= right.order then return left.order < right.order end
    return left.title < right.title
end

local function queueKey(order)
    local payload = order.payload or {}
    local mode = payload.mode or "technology"
    local id = mode == "technology" and payload.technologyId
        or mode == "book" and payload.bookFullType or order.recipeId
    return mode .. ":" .. tostring(id or ""), mode, id
end

function Model.ProgressPercent(order)
    return Items.ProgressPercent(order)
end

function Model.ActiveOrders(snapshot)
    return Items.ActiveOrders(snapshot)
end

function Model.Build(snapshot, options)
    snapshot = snapshot or {}
    options = options or {}
    local filter = FILTERS[options.filter] and options.filter or "all"
    local collapsed = options.collapsedGroups or {}
    local orders = Items.ActiveOrders(snapshot)
    local groups, byID, itemsByKey = {}, {}, {}
    local research = snapshot.research or {}
    local station = Items.StationAvailable(snapshot)

    for _, entry in ipairs(research.entries or {}) do
        local item = Items.BuildTechnology(entry, orders, station, groupSpec)
        if include(item, filter) then
            local group = addGroup(groups, byID, item.group)
            appendItem(group, item)
            itemsByKey[item.key] = item
        end
    end
    for _, candidate in ipairs(research.candidates or {}) do
        local item = Items.BuildCandidate(candidate, orders, station, groupSpec)
        if include(item, filter) then
            local group = addGroup(groups, byID, item.group)
            appendItem(group, item)
            itemsByKey[item.key] = item
        end
    end
    for _, group in ipairs(groups) do
        table.sort(group.items, sortItems)
        group.collapsed = collapsed[group.id] == true
        group.totalCount = #group.items
    end
    table.sort(groups, sortGroups)

    local activeQueue = {}
    for _, order in ipairs(orders) do
        local key, mode, id = queueKey(order)
        local item = itemsByKey[key]
        activeQueue[#activeQueue + 1] = { key = key, order = order, item = item,
            name = item and item.name or tostring(id or mode), source = mode,
            progress = Items.ProgressPercent(order) }
    end
    local selectedKey = options.selectedKey
    if not selectedKey or not itemsByKey[selectedKey] then
        selectedKey = activeQueue[1] and activeQueue[1].key or nil
    end
    if not selectedKey then
        for _, group in ipairs(groups) do
            if group.items[1] then selectedKey = group.items[1].key break end
        end
    end
    local total, known, available = 0, 0, 0
    for _, group in ipairs(groups) do
        total = total + group.totalCount
        known = known + group.knownCount
        available = available + group.availableCount
    end
    return { groups = groups, itemsByKey = itemsByKey, selectedKey = selectedKey,
        selected = selectedKey and itemsByKey[selectedKey] or nil,
        activeQueue = activeQueue, stationAvailable = station, filter = filter,
        summary = { total = total, known = known, available = available,
            active = #activeQueue } }
end

return Model
