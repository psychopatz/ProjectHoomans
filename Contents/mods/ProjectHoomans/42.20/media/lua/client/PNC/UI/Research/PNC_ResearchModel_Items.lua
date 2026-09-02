local Items = {}
local Shared = require
    "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"

local function number(value, fallback)
    value = tonumber(value)
    return value ~= nil and value or fallback
end

local function text(value, fallback)
    value = value ~= nil and tostring(value) or ""
    return value ~= "" and value or tostring(fallback or "")
end

local function translate(key, fallback)
    if key == nil or key == "" then return fallback end
    return Shared.Tr(key, fallback)
end

local function activeOrders(snapshot)
    local result = {}
    for _, order in ipairs(snapshot and snapshot.research
        and snapshot.research.orders or {}) do
        local status = tostring(order.status or "")
        if (order.operation == "RESEARCH" or order.operation == "READ_BOOK")
            and status ~= "COMPLETED" and status ~= "CANCELLED"
        then
            result[#result + 1] = order
        end
    end
    return result
end

local function progressPercent(order)
    local required = math.max(1, number(order and order.requiredWork, 1))
    local current = math.max(0, number(order and order.progress, 0))
    return math.floor(math.min(1, current / required) * 100 + 0.5)
end

local function matchingOrder(orders, mode, id)
    for _, order in ipairs(orders or {}) do
        local payload = order.payload or {}
        local matches
        if mode == "technology" then
            matches = tostring(payload.technologyId) == tostring(id)
        elseif mode == "book" then
            matches = tostring(payload.bookFullType) == tostring(id)
        else
            matches = number(order.recipeId, 0) == number(id, -1)
        end
        if payload.mode == mode and matches then return order end
    end
    return nil
end

local function stationAvailable(snapshot)
    local FacilityState = require "PNC/Core/Settlement/PNC_FacilityState"
    for _, facility in ipairs(snapshot and snapshot.settlement
        and snapshot.settlement.facilities or {}) do
        if facility.definitionId == "research_facility"
            and FacilityState.IsBuilt(facility)
        then
            for _, component in ipairs(facility.components or {}) do
                if component.role == "work.research" then return true end
            end
        end
    end
    return false
end

local function statusFor(item, station)
    if item.known then return "known" end
    if item.order then return "active" end
    if item.prerequisiteKnown == false then return "locked" end
    if not station then return "unavailable" end
    return "available"
end

function Items.ActiveOrders(snapshot)
    return activeOrders(snapshot)
end

function Items.ProgressPercent(order)
    return progressPercent(order)
end

function Items.StationAvailable(snapshot)
    return stationAvailable(snapshot)
end

function Items.BuildTechnology(entry, orders, station, groupSpec)
    local order = matchingOrder(orders, "technology", entry.id)
    local item = {
        key = "technology:" .. tostring(entry.id),
        id = entry.id, source = "technology",
        name = translate(entry.labelKey, entry.id),
        description = translate(entry.descriptionKey,
            translate("UI_PNC_Research_DefaultDescription",
                "Research this colony upgrade when its prerequisites are met.")),
        itemOrder = number(entry.itemOrder, 100000),
        known = entry.known == true,
        prerequisite = entry.prerequisiteTechnology,
        prerequisiteKnown = entry.prerequisiteKnown ~= false,
        requiredWork = number(entry.requiredWork, 0),
        requiredSkills = entry.requiredSkills or {}, order = order,
        progress = order and progressPercent(order) or nil,
        stationAvailable = station, group = groupSpec(entry, "technology"),
    }
    item.status = statusFor(item, station)
    item.researchable = station and not item.known
        and item.prerequisiteKnown and not order or false
    item.disabledReason = not item.researchable and not item.known
        and (not station and "UI_PNC_Research_Disabled_NoTable"
            or not item.prerequisiteKnown and "UI_PNC_Research_Disabled_Prerequisite"
            or order and "UI_PNC_Research_Disabled_Queued" or nil) or nil
    item.action = item.researchable and "research_queue_technology" or nil
    return item
end

function Items.BuildCandidate(candidate, orders, station, groupSpec)
    local source = tostring(candidate.mode or "")
    local id = source == "book" and candidate.bookFullType or candidate.recipeId
    local order = matchingOrder(orders, source, id)
    local item = {
        key = source .. ":" .. tostring(id or candidate.recordIndex),
        id = id, source = source,
        name = text(candidate.displayName, candidate.fullType),
        description = source == "blueprint"
            and translate("UI_PNC_Research_BlueprintDescription",
                "Study this blueprint to add its recipe to the colony.")
            or translate("UI_PNC_Research_BookDescription",
                "Read this book to learn its available recipes."),
        itemOrder = number(candidate.recordIndex, 100000),
        known = candidate.known == true,
        quantity = number(candidate.quantity, 1),
        recordIndex = candidate.recordIndex, recipeId = candidate.recipeId,
        bookFullType = candidate.bookFullType, fullType = candidate.fullType,
        order = order, progress = order and progressPercent(order) or nil,
        stationAvailable = station, group = groupSpec(nil, source),
    }
    item.status = statusFor(item, station)
    item.researchable = station and not item.known and not order or false
    item.disabledReason = not item.researchable and not item.known
        and (not station and "UI_PNC_Research_Disabled_NoTable"
            or order and "UI_PNC_Research_Disabled_Queued" or nil) or nil
    item.action = item.researchable and (source == "blueprint"
        and "research_study_blueprint" or "research_read_book") or nil
    return item
end

return Items
