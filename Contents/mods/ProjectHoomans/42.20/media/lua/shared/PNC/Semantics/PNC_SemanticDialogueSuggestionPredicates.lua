-- Generic, side-effect-free predicate evaluation for suggestion policy.
--
-- Hoomans owns the policy fields and predicate declarations.  This module
-- only supplies the typed all/any/not evaluator and bounded diagnostics; it
-- never reads live Java objects, sends commands, or changes authority state.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Predicates = PNC.Semantics.SuggestionPredicates or {}
PNC.Semantics.SuggestionPredicates = Predicates

Predicates.VERSION = 1
Predicates.MAX_DEPTH = 6
Predicates.MAX_TRACE = 16

local function normalized(value)
    return string.lower(tostring(value or ""))
end

local function privateKey(key)
    key = normalized(key)
    return key == "private"
        or key == "secret"
        or key == "undiscovered"
        or string.find(key, "private", 1, true) ~= nil
        or string.find(key, "secret", 1, true) ~= nil
end

local function appendTrace(trace, row)
    if #trace >= Predicates.MAX_TRACE then return end
    trace[#trace + 1] = row
end

local function unknown(reason)
    return {
        status = "unknown",
        allowed = false,
        reason = reason or "predicate_unknown",
        trace = {},
    }
end

local function combineAll(results)
    local index
    local result
    local hasUnknown = false
    local hasPrivate = false
    local trace = {}
    for index = 1, #results do
        result = results[index]
        for _, row in ipairs(result.trace or {}) do
            appendTrace(trace, row)
        end
        if result.status == "private" then hasPrivate = true end
        if result.status == "unknown" then hasUnknown = true end
        if result.status == "rejected" then
            return {
                status = "rejected",
                allowed = false,
                reason = result.reason or "predicate_rejected",
                trace = trace,
            }
        end
    end
    if hasPrivate then
        return {
            status = "private",
            allowed = false,
            reason = "private_field",
            trace = trace,
        }
    end
    if hasUnknown then
        return {
            status = "unknown",
            allowed = false,
            reason = "predicate_unknown",
            trace = trace,
        }
    end
    return { status = "allowed", allowed = true, reason = "all_allowed", trace = trace }
end

local function combineAny(results)
    local index
    local result
    local hasUnknown = false
    local hasPrivate = false
    local trace = {}
    for index = 1, #results do
        result = results[index]
        for _, row in ipairs(result.trace or {}) do
            appendTrace(trace, row)
        end
        if result.allowed == true then
            return {
                status = "allowed",
                allowed = true,
                reason = "any_allowed",
                trace = trace,
            }
        end
        if result.status == "private" then hasPrivate = true end
        if result.status == "unknown" then hasUnknown = true end
    end
    if hasPrivate then
        return {
            status = "private",
            allowed = false,
            reason = "private_field",
            trace = trace,
        }
    end
    if hasUnknown then
        return {
            status = "unknown",
            allowed = false,
            reason = "predicate_unknown",
            trace = trace,
        }
    end
    return {
        status = "rejected",
        allowed = false,
        reason = "none_allowed",
        trace = trace,
    }
end

local function typedEqual(left, right)
    if type(left) ~= type(right) then return false end
    return left == right
end

local function listContains(values, actual)
    if type(values) ~= "table" then return false end
    for index = 1, #values do
        if typedEqual(actual, values[index]) then return true end
    end
    return false
end

local function readPath(context, path)
    local current = context
    local segment
    local index
    local parts = {}
    for segment in string.gmatch(tostring(path or ""), "[^%.]+") do
        parts[#parts + 1] = segment
    end
    if #parts == 0 then return nil, "predicate_path_missing", false end

    for index = 1, #parts do
        segment = parts[index]
        if privateKey(segment) then return nil, "private_field", true end
        if type(current) ~= "table" or current[segment] == nil then
            return nil, "predicate_field_unknown", false
        end
        current = current[segment]
        if type(current) == "table"
            and (current.private == true or current.secret == true
                or current.undiscovered == true)
        then
            return nil, "private_field", true
        end
    end
    return current, nil, false
end

local function compare(value, predicate)
    local op = normalized(predicate.op or "eq")
    local expected = predicate.value
    if op == "exists" then return value ~= nil end
    if value == nil then return nil end
    if op == "eq" or op == "equals" then
        return typedEqual(value, expected)
    end
    if op == "neq" or op == "not_equals" then
        return type(value) == type(expected) and value ~= expected
    end
    if op == "in" then
        local values = predicate.values or expected
        if type(values) ~= "table" then return nil end
        local index
        for index = 1, #values do
            if type(values[index]) ~= type(value) then return nil end
            if typedEqual(value, values[index]) then return true end
        end
        return false
    end
    if op == "not_in" then
        local values = predicate.values or expected
        if type(values) ~= "table" then return nil end
        local index
        for index = 1, #values do
            if type(values[index]) ~= type(value) then return nil end
            if typedEqual(value, values[index]) then return false end
        end
        return true
    end
    if op == "gt" or op == "gte" or op == "lt" or op == "lte" then
        if type(value) ~= "number" or type(expected) ~= "number" then
            return nil
        end
        if op == "gt" then return value > expected end
        if op == "gte" then return value >= expected end
        if op == "lt" then return value < expected end
        return value <= expected
    end
    if op == "truthy" then return type(value) == "boolean" and value end
    if op == "falsy" then return type(value) == "boolean" and not value end
    return nil
end

local function evaluateNode(predicate, context, depth)
    depth = tonumber(depth) or 0
    if depth > Predicates.MAX_DEPTH then return unknown("predicate_depth_limit") end
    if type(predicate) ~= "table" then return unknown("predicate_invalid") end

    if predicate.all ~= nil then
        if type(predicate.all) ~= "table" then return unknown("all_invalid") end
        local results = {}
        for index = 1, #predicate.all do
            results[#results + 1] = evaluateNode(
                predicate.all[index], context, depth + 1
            )
        end
        return combineAll(results)
    end
    if predicate.any ~= nil then
        if type(predicate.any) ~= "table" then return unknown("any_invalid") end
        local results = {}
        for index = 1, #predicate.any do
            results[#results + 1] = evaluateNode(
                predicate.any[index], context, depth + 1
            )
        end
        return combineAny(results)
    end
    if predicate["not"] ~= nil then
        local result = evaluateNode(predicate["not"], context, depth + 1)
        if result.status == "unknown" or result.status == "private" then
            return result
        end
        if result.status == "rejected" then
            return {
                status = "allowed",
                allowed = true,
                reason = "not_allowed",
                trace = result.trace,
            }
        end
        return {
            status = "rejected",
            allowed = false,
            reason = "not_failed",
            trace = result.trace,
        }
    end

    local path = predicate.path or predicate.field
    if type(path) ~= "string" or path == "" then
        return unknown("predicate_field_required")
    end
    local value, readReason, isPrivate = readPath(context, path)
    local safePath = isPrivate and "<private>" or path
    if isPrivate then
        return {
            status = "private",
            allowed = false,
            reason = "private_field",
            trace = {
                { path = safePath, status = "private", reason = "private_field" },
            },
        }
    end
    if readReason and value == nil then
        return {
            status = "unknown",
            allowed = false,
            reason = readReason,
            trace = {
                { path = safePath, status = "unknown", reason = readReason },
            },
        }
    end
    local matched = compare(value, predicate)
    if matched == nil then
        return {
            status = "unknown",
            allowed = false,
            reason = "predicate_type_mismatch",
            trace = {
                { path = safePath, status = "unknown", reason = "type_mismatch" },
            },
        }
    end
    return {
        status = matched and "allowed" or "rejected",
        allowed = matched == true,
        reason = matched and "predicate_match" or "predicate_mismatch",
        trace = {
            { path = safePath, status = matched and "allowed" or "rejected", reason = "typed_compare" },
        },
    }
end

function Predicates.Evaluate(predicate, context)
    local result = evaluateNode(predicate, type(context) == "table" and context or {}, 0)
    result.schemaVersion = Predicates.VERSION
    result.trace = result.trace or {}
    if #result.trace > Predicates.MAX_TRACE then
        while #result.trace > Predicates.MAX_TRACE do
            table.remove(result.trace)
        end
        result.truncated = true
    else
        result.truncated = false
    end
    return result
end

return Predicates
