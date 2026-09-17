-- Client-side bounded query parsing and candidate scoring for gifts.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Selection = PNC.Semantics.GiftSelection or {}
PNC.Semantics.GiftSelection = Selection
local Internal = Selection.Internal or {}
Selection.Internal = Internal

local function normalize(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "[^%w]+", " ")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function tokens(value)
    local output = {}
    for token in string.gmatch(normalize(value), "%w+") do
        output[#output + 1] = token
    end
    return output
end

local function editDistance(first, second)
    first = tostring(first or "")
    second = tostring(second or "")
    if first == second then return 0 end
    if #first == 0 then return #second end
    if #second == 0 then return #first end
    if math.abs(#first - #second) > 3 then return 99 end
    local previous = {}
    local current = {}
    local index
    local column
    for column = 0, #second do previous[column] = column end
    for index = 1, #first do
        current[0] = index
        for column = 1, #second do
            local cost = string.sub(first, index, index)
                == string.sub(second, column, column) and 0 or 1
            current[column] = math.min(previous[column] + 1,
                current[column - 1] + 1, previous[column - 1] + cost)
        end
        previous, current = current, previous
    end
    return previous[#second] or 99
end

local function fieldScore(query, field)
    query = normalize(query)
    field = normalize(field)
    if query == "" or field == "" then return 0 end
    if query == field then return 110 end
    if string.find(" " .. field .. " ", " " .. query .. " ", 1, true) then
        return 94
    end
    if string.find(field, query, 1, true) then return 78 end
    local wanted = tokens(query)
    local available = tokens(field)
    local matched = 0
    local bestDistance = 99
    local wantedIndex
    local availableIndex
    for wantedIndex = 1, #wanted do
        for availableIndex = 1, #available do
            if wanted[wantedIndex] == available[availableIndex] then
                matched = matched + 1
                bestDistance = 0
                break
            end
            if #wanted[wantedIndex] >= 4 and #available[availableIndex] >= 4 then
                bestDistance = math.min(bestDistance, editDistance(
                    wanted[wantedIndex], available[availableIndex]))
            end
        end
    end
    if matched == #wanted and matched > 0 then return 84 end
    if matched > 0 then return 52 + matched * 8 end
    if bestDistance <= 2 then return 66 - bestDistance * 10 end
    return 0
end

local function requestFor(offer)
    local object = offer and offer.object or nil
    local query = offer and offer.query or nil
    if query == nil and type(object) == "table" then
        query = object.text or object.value or object.category
            or object.concept
    end
    query = tostring(query or "")
    local quantity = tonumber(offer and offer.quantity)
    local countText, remainder = string.match(query, "^%s*(%d+)%s+(.+)$")
    if countText then
        quantity = tonumber(countText)
        query = remainder
    end
    quantity = math.max(1, math.min(999, math.floor(quantity or 1)))
    return normalize(query), quantity
end

local function scoreCandidate(candidate, query)
    local best = 0
    local bestField
    for index = 1, #(candidate.fields or {}) do
        local field = candidate.fields[index]
        local score = fieldScore(query, field.value)
            + (tonumber(field.priority) or 0)
        if score > best then
            best = score
            bestField = field
        end
    end
    candidate.score = best
    candidate.matchField = bestField and bestField.kind or nil
    return best
end

local function grouped(candidates)
    local groups = {}
    local order = {}
    for index = 1, #candidates do
        local candidate = candidates[index]
        local key = candidate.fullType
        local group = groups[key]
        if not group then
            group = { fullType = key, itemIDs = {}, score = candidate.score,
                matchField = candidate.matchField,
                displayName = candidate.displayName,
                facts = candidate.facts }
            groups[key] = group
            order[#order + 1] = group
        end
        group.itemIDs[#group.itemIDs + 1] = candidate.itemID
        if candidate.score > group.score then
            group.score = candidate.score
            group.matchField = candidate.matchField
            group.displayName = candidate.displayName
            group.facts = candidate.facts
        end
    end
    table.sort(order, function(first, second)
        if first.score == second.score then
            return tostring(first.fullType) < tostring(second.fullType)
        end
        return first.score > second.score
    end)
    return order
end

Internal.RequestFor = requestFor
Internal.ScoreCandidate = scoreCandidate
Internal.Grouped = grouped
return Selection
