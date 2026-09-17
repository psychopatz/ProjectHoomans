-- Authored preference override normalization.

PNC = PNC or {}
PNC.Gifts = PNC.Gifts or {}
PNC.Gifts.Foundation = PNC.Gifts.Foundation or {}
local Profile = PNC.Gifts.Foundation.PreferenceProfile

local function normalized(value)
    value = string.lower(tostring(value or ""))
    return string.gsub(value, "[^%w]", "")
end

local function addValue(output, value)
    local key = normalized(value)
    if key ~= "" then output[key] = true end
end

local function addValues(output, value)
    local index
    local key
    local child
    if type(value) == "string" or type(value) == "number" then
        addValue(output, value)
        return
    end
    if type(value) ~= "table" then return end
    for index = 1, #value do addValue(output, value[index]) end
    for key, child in pairs(value) do
        if type(key) ~= "number" then
            if child == true then
                addValue(output, key)
            elseif type(child) == "string" or type(child) == "number" then
                addValue(output, key)
                addValue(output, child)
            end
        end
    end
end

local function hasEntries(value)
    local key
    if type(value) ~= "table" then return false end
    for key in pairs(value) do return true end
    return false
end

function Profile.NormalizeOverrides(source)
    source = type(source) == "table" and source or {}
    local output = {}
    local fields = {
        { "exact", "Types" },
        { "leaf", "Leaves" },
        { "subcategory", "Subcategories" },
        { "category", "Categories" },
        { "tag", "Tags" },
        { "any", "" },
    }
    local disposition
    local field
    local nested
    for _, disposition in ipairs(Profile.DISPOSITION_ORDER) do
        output[disposition] = {}
        nested = source[disposition] or source[disposition .. "s"]
        for _, field in ipairs(fields) do
            output[disposition][field[1]] = {}
            if type(nested) == "table" then
                addValues(output[disposition][field[1]], nested[field[1]])
            end
            if field[2] ~= "" then
                addValues(output[disposition][field[1]],
                    source[disposition .. field[2]])
            elseif disposition == "neutral" then
                addValues(output[disposition][field[1]], source.neutral)
            end
        end
    end
    for _, disposition in ipairs({ "favorite", "liked", "disliked", "hated" }) do
        nested = source[disposition] or source[disposition .. "s"]
        if type(nested) == "table" and #nested > 0 then
            addValues(output[disposition].any, nested)
        end
    end
    for _, disposition in ipairs(Profile.DISPOSITION_ORDER) do
        for _, field in ipairs(fields) do
            if not hasEntries(output[disposition][field[1]]) then
                output[disposition][field[1]] = nil
            end
        end
        if not hasEntries(output[disposition]) then
            output[disposition] = nil
        end
    end
    if not hasEntries(output) then return nil end
    return output
end

return Profile
