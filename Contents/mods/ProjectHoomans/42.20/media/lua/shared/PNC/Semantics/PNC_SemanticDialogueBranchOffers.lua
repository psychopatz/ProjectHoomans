-- Shared, data-only contract for authored dialogue branch offers.
--
-- Offers describe public, non-executing semantic choices. They do not parse
-- text, mutate flow state, or dispatch gameplay work. The existing dialogue
-- input and flow policy remain responsible for admission and effects.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Offers = PNC.Semantics.DialogueBranchOffers or {}
PNC.Semantics.DialogueBranchOffers = Offers

Offers.VERSION = 1
Offers.MAX_OFFERS = 8
Offers.MAX_ID_LENGTH = 96
Offers.MAX_TEXT_LENGTH = 256
Offers.MAX_CONSTRAINT_DEPTH = 6
Offers.MAX_CONSTRAINT_FIELDS = 12

local FRAME_FIELDS = {
    "intent", "speechAct", "action", "subject", "target", "reference",
    "identityClaim", "selfDirected", "stateType", "stateValue", "pattern",
}
local FRAME_FIELD_SET = {}
for index = 1, #FRAME_FIELDS do
    FRAME_FIELD_SET[FRAME_FIELDS[index]] = true
end

local CONSTRAINT_FIELD_SET = {
    all = true,
    any = true,
    ["not"] = true,
    path = true,
    field = true,
    op = true,
    value = true,
    values = true,
}

local function boundedText(value, limit)
    value = tostring(value or "")
    limit = tonumber(limit) or Offers.MAX_TEXT_LENGTH
    if #value > limit then return string.sub(value, 1, limit) end
    return value
end

local function validID(value)
    value = tostring(value or "")
    return value ~= ""
        and #value <= Offers.MAX_ID_LENGTH
        and string.find(value, "[^%w_%.%-]") == nil
end

local function copyValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= Offers.MAX_CONSTRAINT_DEPTH then return nil end
    local output = {}
    local key
    local item
    local count = 0
    for key, item in pairs(value) do
        if count >= Offers.MAX_CONSTRAINT_FIELDS then break end
        if type(key) == "string" or type(key) == "number" then
            if type(item) ~= "function" then
                output[key] = copyValue(item, depth + 1)
                count = count + 1
            end
        end
    end
    return output
end

local function normalizeFrame(frame, label)
    if type(frame) ~= "table" then
        return nil, label .. "_must_be_object"
    end
    local output = {}
    local key
    local value
    local supported = false
    for key, value in pairs(frame) do
        if not FRAME_FIELD_SET[key] then
            return nil, label .. "_unsupported_field:" .. tostring(key)
        end
        if type(value) ~= "string"
            and type(value) ~= "number"
            and type(value) ~= "boolean"
        then
            return nil, label .. "_field_must_be_scalar:" .. tostring(key)
        end
        output[key] = value
        supported = true
    end
    if not supported then return nil, label .. "_empty" end
    return output
end

local function normalizeConstraints(value, label)
    if value == nil then return nil end
    if type(value) ~= "table" then
        return nil, label .. "_must_be_object"
    end

    local function validate(node, depth, nodeLabel)
        if depth > Offers.MAX_CONSTRAINT_DEPTH
            or type(node) ~= "table"
        then
            return nil, nodeLabel .. "_invalid"
        end
        local output = {}
        local fieldCount = 0
        local key
        local item
        for key, item in pairs(node) do
            fieldCount = fieldCount + 1
            if fieldCount > Offers.MAX_CONSTRAINT_FIELDS
                or type(key) ~= "string"
                or not CONSTRAINT_FIELD_SET[key]
            then
                return nil, nodeLabel .. "_unsupported_field"
            end
            output[key] = item
        end

        local structural = 0
        for _, key in ipairs({ "all", "any", "not" }) do
            if output[key] ~= nil then structural = structural + 1 end
        end
        local hasLeaf = output.path ~= nil or output.field ~= nil
        if structural > 1 or (structural > 0 and hasLeaf)
            or (structural == 0 and not hasLeaf)
        then
            return nil, nodeLabel .. "_shape_invalid"
        end
        if output.path ~= nil and output.field ~= nil then
            return nil, nodeLabel .. "_path_field_conflict"
        end

        if output.all ~= nil or output.any ~= nil then
            local list = output.all or output.any
            if type(list) ~= "table" or #list == 0
                or #list > Offers.MAX_CONSTRAINT_FIELDS
            then
                return nil, nodeLabel .. "_list_invalid"
            end
            local normalized = {}
            for index = 1, #list do
                local child, reason = validate(
                    list[index], depth + 1,
                    nodeLabel .. "_item"
                )
                if not child then return nil, reason end
                normalized[index] = child
            end
            if output.all ~= nil then output.all = normalized end
            if output.any ~= nil then output.any = normalized end
        elseif output["not"] ~= nil then
            local child, reason = validate(
                output["not"], depth + 1, nodeLabel .. "_not"
            )
            if not child then return nil, reason end
            output["not"] = child
        else
            local path = output.path or output.field
            if type(path) ~= "string" or path == "" then
                return nil, nodeLabel .. "_path_invalid"
            end
            if output.op ~= nil and type(output.op) ~= "string" then
                return nil, nodeLabel .. "_op_invalid"
            end
            if output.values ~= nil and type(output.values) ~= "table" then
                return nil, nodeLabel .. "_values_invalid"
            end
            if type(output.values) == "table"
                and #output.values > Offers.MAX_CONSTRAINT_FIELDS
            then
                return nil, nodeLabel .. "_values_limit"
            end
            for _, scalar in pairs(output.values or {}) do
                local scalarType = type(scalar)
                if scalar == nil
                    or (scalarType ~= "string" and scalarType ~= "number"
                        and scalarType ~= "boolean")
                then
                    return nil, nodeLabel .. "_values_scalar_invalid"
                end
            end
            if output.value ~= nil then
                local scalarType = type(output.value)
                if scalarType ~= "string" and scalarType ~= "number"
                    and scalarType ~= "boolean"
                then
                    return nil, nodeLabel .. "_value_scalar_invalid"
                end
            end
        end
        return output
    end

    return validate(value, 0, label)
end

function Offers.Normalize(value, label)
    label = tostring(label or "branch_offer")
    if type(value) ~= "table" then
        return nil, label .. "_must_be_object"
    end
    local id = tostring(value.id or "")
    if not validID(id) then return nil, label .. "_id_invalid" end

    local labelKey = tostring(value.labelKey or "")
    local labelFallback = boundedText(value.labelFallback)
    local utteranceKey = tostring(value.utteranceKey or "")
    local utteranceFallback = boundedText(value.utteranceFallback)
    if not validID(labelKey) or labelFallback == "" then
        return nil, label .. "_label_required"
    end
    if not validID(utteranceKey) or utteranceFallback == "" then
        return nil, label .. "_utterance_required"
    end

    local frame, reason = normalizeFrame(value.frame, label .. "_frame")
    if not frame then return nil, reason end
    local constraints
    constraints, reason = normalizeConstraints(
        value.constraints, label .. "_constraints"
    )
    if value.constraints ~= nil and not constraints then return nil, reason end
    if value.visibility ~= nil and value.visibility ~= "player" then
        return nil, label .. "_visibility_invalid"
    end

    return {
        id = id,
        labelKey = labelKey,
        labelFallback = labelFallback,
        utteranceKey = utteranceKey,
        utteranceFallback = utteranceFallback,
        frame = frame,
        constraints = constraints,
        visibility = value.visibility == "player" and "player" or nil,
        priority = tonumber(value.priority) or 0,
    }
end

function Offers.NormalizeList(values, label, maximum)
    label = tostring(label or "branch_offers")
    maximum = tonumber(maximum) or Offers.MAX_OFFERS
    if values == nil then return {} end
    if type(values) ~= "table" then
        return nil, label .. "_must_be_array"
    end
    if #values > maximum then return nil, label .. "_limit" end
    local output = {}
    local seen = {}
    local index
    local offer
    local reason
    for index = 1, #values do
        offer, reason = Offers.Normalize(values[index], label .. "_item")
        if not offer then return nil, reason end
        if seen[offer.id] then return nil, label .. "_duplicate_id" end
        seen[offer.id] = true
        output[#output + 1] = offer
    end
    return output
end

function Offers.Copy(value)
    return copyValue(value, 0)
end

return Offers
