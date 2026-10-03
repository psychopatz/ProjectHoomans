local PNC = _G.PNC or {}
local Opera = PNC.PuppetOpera or {}
local Normalization = Opera.BlueprintNormalization

local function cleanText(value, maximum)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    if string.find(value, "%c") then return "" end
    if maximum then value = string.sub(value, 1, maximum) end
    return value
end

local function validID(value, maximum)
    value = cleanText(value, maximum or 96)
    if value == "" or not string.match(value, "^[%w%._%-]+$") then
        return nil
    end
    return value
end

local function normalizeVariables(rawVariables)
    local variables = {}
    if type(rawVariables) ~= "table" then return variables end
    local index
    local raw
    local name
    local valueType
    local value
    for index, raw in ipairs(rawVariables) do
        if index > 16 or type(raw) ~= "table" then break end
        name = validID(raw.name, 64)
        valueType = type(raw.value)
        value = raw.value
        if name and (
            valueType == "boolean"
                or valueType == "string"
                or valueType == "number"
        ) then
            if valueType == "string" then
                value = cleanText(value, 96)
            elseif valueType == "number"
                and (value ~= value
                    or value == math.huge
                    or value == -math.huge)
            then
                value = nil
            end
            if value ~= nil then
                variables[#variables + 1] = {
                    name = name,
                    kind = validID(raw.kind, 16),
                    value = value,
                }
            end
        end
    end
    return variables
end

local function numberInRange(value, minimum, maximum, fallback)
    local number = tonumber(value)
    if not number or number ~= number
        or number == math.huge or number == -math.huge
    then
        return fallback
    end
    if number < minimum or number > maximum then return nil end
    return number
end

local function integerInRange(value, minimum, maximum, fallback)
    local number = numberInRange(value, minimum, maximum, fallback)
    if number == nil then return nil end
    if number ~= math.floor(number) then return nil end
    return number
end

local function normalizeAnchor(raw, anchorID)
    if type(raw) ~= "table" then
        return nil, "anchor_not_a_table:" .. tostring(anchorID)
    end
    local right = integerInRange(raw.right, -8, 8, 0)
    local forward = integerInRange(raw.forward, -8, 8, 0)
    local z = integerInRange(raw.z, -1, 1, 0)
    local faceTarget = validID(raw.faceTarget, 64)
    if right == nil or forward == nil or z == nil then
        return nil, "anchor_offset_invalid:" .. tostring(anchorID)
    end
    if not faceTarget then
        return nil, "anchor_face_target_required:" .. tostring(anchorID)
    end
    return {
        id = tostring(anchorID),
        right = right,
        forward = forward,
        z = z,
        faceTarget = faceTarget,
    }
end
Normalization._CleanText = cleanText
Normalization._ValidID = validID
Normalization._NormalizeVariables = normalizeVariables
Normalization._NumberInRange = numberInRange
Normalization._IntegerInRange = integerInRange
Normalization._NormalizeAnchor = normalizeAnchor
