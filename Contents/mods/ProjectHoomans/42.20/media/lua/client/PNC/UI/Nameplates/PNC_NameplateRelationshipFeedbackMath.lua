-- Pure relationship-feedback projection helpers.  Keeping these separate
-- makes the nameplate state pipe easy to reuse from other client surfaces.
PNC = PNC or {}
PNC.NameplateRelationshipFeedbackMath =
    PNC.NameplateRelationshipFeedbackMath or {}

local Math = PNC.NameplateRelationshipFeedbackMath

local function number(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return 0
    end
    return value
end

local function axis(delta, name)
    if type(delta) ~= "table" then return 0 end
    if delta[name] ~= nil then return number(delta[name]) end
    return number(delta[name .. "Delta"])
end

local function stateValue(value)
    local normalized = string.lower(tostring(value or ""))
    local values = {
        enemy = -2,
        despise = -2,
        rival = -1,
        hostile = -1,
        neutral = 0,
        firstmeet = 0,
        acquaintance = 0.5,
        friend = 1,
        member = 1,
        companion = 1,
        lover = 2,
        partner = 2,
        spouse = 2,
    }
    return values[normalized]
end

function Math.Number(value)
    return number(value)
end

function Math.Axis(delta, name)
    return axis(delta, name)
end

function Math.Score(delta, before, after)
    local value = axis(delta, "approval")
        + axis(delta, "respect")
        + axis(delta, "familiarity")
    if value ~= 0 then return value end
    local beforeState = stateValue(before and before.state)
    local afterState = stateValue(after and after.state)
    if beforeState ~= nil and afterState ~= nil
        and beforeState ~= afterState
    then
        return afterState - beforeState
    end
    return 0
end

function Math.Delta(before, after)
    return {
        approval = number(after and after.approval)
            - number(before and before.approval),
        respect = number(after and after.respect)
            - number(before and before.respect),
        familiarity = number(after and after.familiarity)
            - number(before and before.familiarity),
    }
end

function Math.CopyDelta(delta)
    return {
        approval = axis(delta, "approval"),
        respect = axis(delta, "respect"),
        familiarity = axis(delta, "familiarity"),
    }
end

return Math
