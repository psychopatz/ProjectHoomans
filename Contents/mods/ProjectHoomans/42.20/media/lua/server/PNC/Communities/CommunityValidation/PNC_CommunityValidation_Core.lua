if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local H = PNC.CommunityValidation.Internal
local CommunityMath = PNC.CommunityMath

function H.Result()
    return {
        ok = true,
        scope = "community_registry",
        errors = {},
        warnings = {},
        checks = 0,
    }
end

function H.Issue(output, severity, code, detail)
    local item = {
        severity = severity,
        code = code,
        detail = tostring(detail or ""),
    }
    if severity == "error" then
        output.ok = false
        output.errors[#output.errors + 1] = item
    else
        output.warnings[#output.warnings + 1] = item
    end
end

function H.SafePersistent(value, path, output, seen)
    local kind = type(value)
    output.checks = output.checks + 1
    if kind == "function" or kind == "userdata" or kind == "thread" then
        H.Issue(output, "error", "unsafe_persistent_value",
            path .. ":" .. kind)
        return
    end
    if kind == "number" and not CommunityMath.IsFinite(value) then
        H.Issue(output, "error", "non_finite_number", path)
        return
    end
    if kind ~= "table" then return end
    if getmetatable and getmetatable(value) ~= nil then
        H.Issue(output, "error", "persistent_metatable", path)
    end
    if seen[value] then
        H.Issue(output, "error", "persistent_cycle", path)
        return
    end
    seen[value] = true
    for key, child in pairs(value) do
        if type(key) ~= "string" and type(key) ~= "number" then
            H.Issue(output, "error", "unsafe_persistent_key", path)
        end
        H.SafePersistent(child, path .. "." .. tostring(key), output, seen)
    end
    seen[value] = nil
end

function H.CheckRange(output, value, minimum, maximum, code, detail)
    output.checks = output.checks + 1
    if not CommunityMath.IsFinite(value)
        or value < minimum or value > maximum
    then
        H.Issue(output, "error", code, detail)
    end
end

return H
