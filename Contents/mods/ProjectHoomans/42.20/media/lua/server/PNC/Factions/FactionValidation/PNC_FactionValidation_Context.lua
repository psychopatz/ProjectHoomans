-- Shared faction invariant validation primitives.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionValidation = PNC.FactionValidation or {}
PNC.FactionValidation.Internal = PNC.FactionValidation.Internal or {}

local Validation = PNC.FactionValidation
local Factions = PNC.Factions
local Types = PNC.FactionTypes
local Math = PNC.FactionDiplomacyMath
local Definitions = PNC.FactionIncidentDefinitions
local Constants = PNC.FactionConstants
local EntityRef = PNC.EntityRef
local Balance = PNC.FactionBalance

Validation.Scenarios = {
    "single_minor_attack",
    "repeated_minor_attacks",
    "severe_attack",
    "member_killed",
    "leader_killed",
    "rescue_then_attack",
    "war_then_peace",
    "war_then_truce",
    "truce_broken",
    "alliance_then_betrayal",
    "looter_meets_stronger_outsider",
    "looter_meets_weaker_outsider",
    "unrelated_multiplayer_player",
    "new_survivor_after_owner_death",
}

local function copy(value)
    return PNC.Core.DeepCopy(value)
end

local function addIssue(result, severity, code, detail)
    local issue = {
        severity = severity,
        code = code,
        detail = tostring(detail or ""),
    }
    if severity == "error" then
        result.errors[#result.errors + 1] = issue
        result.ok = false
    else
        result.warnings[#result.warnings + 1] = issue
    end
end

local function newResult(scope)
    return {
        ok = true,
        scope = scope,
        errors = {},
        warnings = {},
        checks = 0,
    }
end

local function safePersistent(value, path, result, seen)
    local kind = type(value)
    result.checks = result.checks + 1
    if kind == "function" or kind == "userdata"
        or kind == "thread"
    then
        addIssue(result, "error", "unsafe_persistent_value",
            path .. ":" .. kind)
        return
    end
    if kind == "number"
        and (
            value ~= value
            or value == math.huge
            or value == -math.huge
        )
    then
        addIssue(result, "error", "non_finite_number", path)
        return
    end
    if kind ~= "table" then return end
    if getmetatable and getmetatable(value) ~= nil then
        addIssue(result, "error", "persistent_metatable", path)
    end
    if seen[value] then
        addIssue(result, "error", "persistent_cycle", path)
        return
    end
    seen[value] = true
    for key, child in pairs(value) do
        if type(key) ~= "string" and type(key) ~= "number" then
            addIssue(result, "error",
                "unsafe_persistent_key", path)
        end
        safePersistent(
            child,
            path .. "." .. tostring(key),
            result,
            seen
        )
    end
    seen[value] = nil
end

local Internal = Validation.Internal
Internal.Copy = copy
Internal.AddIssue = addIssue
Internal.NewResult = newResult
Internal.SafePersistent = safePersistent

return Internal
