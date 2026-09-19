-- Normalizes item labels and performs bounded semantic text matching.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Selector = PNC.Semantics.ItemSelector
local Internal = Selector.Internal

function Internal.ItemType(item)
    return tostring(item and (item.type or item.fullType) or "")
end

local function searchText(value)
    local text = string.lower(tostring(value or ""))
    text = string.gsub(text, "[^%w]+", " ")
    text = string.gsub(text, "%s+", " ")
    text = string.gsub(text, "^%s+", "")
    return string.gsub(text, "%s+$", "")
end

local function singular(value)
    value = searchText(value)
    if string.sub(value, -3) == "ies" and #value > 3 then
        return string.sub(value, 1, -4) .. "y"
    end
    if string.sub(value, -1) == "s"
        and string.sub(value, -2) ~= "ss"
        and string.sub(value, -2) ~= "us"
        and string.sub(value, -2) ~= "is"
    then
        return string.sub(value, 1, -2)
    end
    return value
end

local function fuzzyLimit(value)
    local length = #tostring(value or "")
    if length < 4 then return 0 end
    return length >= 8 and 2 or 1
end

local function editDistanceAtMost(left, right, limit)
    left = tostring(left or "")
    right = tostring(right or "")
    limit = tonumber(limit) or 0
    if left == right then return true end
    if limit < 1 then return false end
    if math.abs(#left - #right) > limit then return false end

    local previous = {}
    local current
    local row
    local column
    for column = 0, #right do previous[column] = column end
    for row = 1, #left do
        current = { [0] = row }
        for column = 1, #right do
            local cost = string.sub(left, row, row)
                == string.sub(right, column, column) and 0 or 1
            current[column] = math.min(
                current[column - 1] + 1,
                previous[column] + 1,
                previous[column - 1] + cost
            )
        end
        previous = current
    end
    return previous[#right] <= limit
end

local function fuzzySingleWord(query, candidate)
    local limit = fuzzyLimit(query)
    if limit < 1 then return false end
    for token in string.gmatch(candidate, "%S+") do
        if editDistanceAtMost(query, singular(token), limit) then
            return true
        end
    end
    return false
end

function Internal.ItemText(item, fullType)
    local values = {}
    local function add(value)
        value = searchText(value)
        if value ~= "" then values[#values + 1] = value end
    end
    add(item and item.customName)
    add(item and item.displayName)
    add(item and item.itemState and item.itemState.customName)
    add(item and item.itemState and item.itemState.displayName)
    add(fullType or Internal.ItemType(item))
    return table.concat(values, " ")
end

function Internal.TextMatches(item, queryText, fullType)
    local query = searchText(queryText)
    if query == "" then return false end
    local candidate = Internal.ItemText(item, fullType)
    if string.find(candidate, query, 1, true) then return true end
    local reduced = singular(query)
    if reduced ~= query and string.find(candidate, reduced, 1, true)
        ~= nil
    then
        return true
    end
    -- Keep typo recovery deliberately narrow: one short English word and a
    -- maximum edit distance of one (two only for long words). This avoids
    -- turning an item request into an expensive or overly permissive parser.
    return not string.find(query, " ", 1, true)
        and fuzzySingleWord(reduced, candidate)
end

return Selector
