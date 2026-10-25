-- Shared bounded value mechanisms for semantic contracts.
--
-- This module owns generic copying and text truncation only. Callers keep
-- ownership of domain-specific limits and validation policy.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local ValueBounds = PNC.Semantics.ValueBounds or {}
PNC.Semantics.ValueBounds = ValueBounds

ValueBounds.DEFAULT_COPY_DEPTH = 10
ValueBounds.DEFAULT_TEXT_LENGTH = 256

function ValueBounds.Copy(value, depth, maximumDepth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    maximumDepth = tonumber(maximumDepth)
        or ValueBounds.DEFAULT_COPY_DEPTH
    if depth >= maximumDepth then return nil end

    local output = {}
    local key
    local item
    for key, item in pairs(value) do
        if type(key) ~= "function" and type(item) ~= "function" then
            output[key] = ValueBounds.Copy(item, depth + 1, maximumDepth)
        end
    end
    return output
end

function ValueBounds.Text(value, maximum, defaultMaximum)
    value = tostring(value or "")
    maximum = tonumber(maximum) or tonumber(defaultMaximum)
        or ValueBounds.DEFAULT_TEXT_LENGTH
    if #value > maximum then return string.sub(value, 1, maximum) end
    return value
end

return ValueBounds
