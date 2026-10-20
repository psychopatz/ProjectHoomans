-- Pure helpers for the read-only P0B import planner.

local Utils = {}

local function copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local output = {}
    seen[value] = output
    for key, child in pairs(value) do
        output[copy(key, seen)] = copy(child, seen)
    end
    return output
end

local function keyLabel(value)
    return type(value) .. ":" .. tostring(value)
end

local function canonical(value, seen)
    local kind = type(value)
    if value == nil then return "nil" end
    if kind == "string" then return "string:" .. string.format("%q", value) end
    if kind == "number" then return "number:" .. string.format("%.17g", value) end
    if kind == "boolean" then return "boolean:" .. tostring(value) end
    if kind ~= "table" then return kind .. ":" .. tostring(value) end
    seen = seen or {}
    if seen[value] then return "<cycle>" end
    seen[value] = true
    local keys = {}
    local parts = { "{" }
    local i
    for key in pairs(value) do keys[#keys + 1] = key end
    table.sort(keys, function(left, right)
        return keyLabel(left) < keyLabel(right)
    end)
    for i = 1, #keys do
        parts[#parts + 1] = canonical(keys[i], seen)
        parts[#parts + 1] = "="
        parts[#parts + 1] = canonical(value[keys[i]], seen)
        parts[#parts + 1] = ";"
    end
    parts[#parts + 1] = "}"
    seen[value] = nil
    return table.concat(parts)
end

function Utils.Copy(value)
    return copy(value)
end

function Utils.Canonical(value)
    return canonical(value)
end

function Utils.Hash(value, identity)
    local text = canonical(value)
    if identity and type(identity.HashText) == "function" then
        return identity.HashText(text, 5381)
    end
    return text
end

function Utils.AddDecision(decisions, field, action, sourcePath, reason)
    decisions[#decisions + 1] = {
        field = field,
        action = action,
        sourcePath = sourcePath,
        reason = reason,
    }
end

function Utils.FirstBlockingReason(decisions)
    local i
    for i = 1, #decisions do
        if decisions[i].action == "quarantined"
            or decisions[i].action == "rejected"
        then
            return decisions[i].reason
        end
    end
    return nil
end

return Utils
