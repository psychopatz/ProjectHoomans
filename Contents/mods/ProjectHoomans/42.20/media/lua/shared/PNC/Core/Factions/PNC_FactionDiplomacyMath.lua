-- Pure faction diplomacy clamping, decay, and hysteresis.

PNC = PNC or {}
PNC.FactionDiplomacyMath = PNC.FactionDiplomacyMath or {}

local Math = PNC.FactionDiplomacyMath
local Constants = PNC.FactionConstants
local Balance = PNC.FactionBalance

local function tuning(name, fallback)
    local value = Balance and Balance.Get and Balance.Get(name)
    return value == nil and fallback or value
end

function Math.Clamp(value, minimum, maximum)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        value = 0
    end
    return math.max(minimum, math.min(maximum, value))
end

function Math.ClampStanding(value)
    return Math.Clamp(
        value,
        Constants.STANDING_MIN,
        Constants.STANDING_MAX
    )
end

function Math.ClampTrust(value)
    return Math.Clamp(
        value,
        Constants.TRUST_MIN,
        Constants.TRUST_MAX
    )
end

function Math.ClampFear(value)
    return Math.Clamp(
        value,
        Constants.FEAR_MIN,
        Constants.FEAR_MAX
    )
end

function Math.ClampGrievance(value)
    return Math.Clamp(
        value,
        Constants.GRIEVANCE_MIN,
        Constants.GRIEVANCE_MAX
    )
end

local function driftToZero(value, amount)
    if value > 0 then return math.max(0, value - amount) end
    if value < 0 then return math.min(0, value + amount) end
    return 0
end

function Math.HasMeaningfulContact(relation)
    return relation ~= nil and (
        #(relation.incidents or {}) > 0
        or (tonumber(relation.lastEvaluatedAt) or 0) > 0
        or (tonumber(relation.standing) or 0) ~= 0
        or (tonumber(relation.trust) or 0) ~= 0
        or (tonumber(relation.fear) or 0) ~= 0
        or (tonumber(relation.grievance) or 0) ~= 0
        or relation.atWar == true
        or relation.allied == true
        or (tonumber(relation.truceUntil) or 0) > 0
    )
end

function Math.ResolveState(relation, worldAgeHours)
    local now = math.max(0, tonumber(worldAgeHours) or 0)
    local current = Constants.VALID_RELATION_STATES[
        relation and relation.state
    ] and relation.state or "unknown"
    local standing = Math.ClampStanding(
        relation and relation.standing
    )
    local trust = Math.ClampTrust(relation and relation.trust)
    local fear = Math.ClampFear(relation and relation.fear)
    local grievance = Math.ClampGrievance(
        relation and relation.grievance
    )

    if relation and relation.atWar == true then return "war" end
    if relation and relation.allied == true then return "allied" end
    if relation
        and (tonumber(relation.truceUntil) or 0) > now
    then
        return "truce"
    end
    if not Math.HasMeaningfulContact(relation) then
        return "unknown"
    end

    if current == "friendly"
        and standing >= tuning("friendlyExitStanding", 20)
        and grievance <= tuning(
            "friendlyExitMaxGrievance", 30
        )
    then
        return "friendly"
    end
    if current == "hostile"
        and (
            standing <= tuning("hostileExitStanding", -30)
            or grievance >= tuning(
                "hostileExitGrievance", 50
            )
        )
    then
        return "hostile"
    end
    if current == "wary"
        and not (
            standing > tuning("waryExitStanding", -5)
            and trust > tuning("waryExitTrust", -15)
            and fear < tuning("waryExitFear", 40)
            and grievance < tuning("waryExitGrievance", 20)
        )
    then
        if standing <= tuning("hostileEntryStanding", -45)
            or grievance >= tuning(
                "hostileEntryGrievance", 65
            )
        then
            return "hostile"
        end
        return "wary"
    end

    if standing <= tuning("hostileEntryStanding", -45)
        or grievance >= tuning("hostileEntryGrievance", 65)
    then
        return "hostile"
    end
    if standing >= tuning("friendlyEntryStanding", 30)
        and trust >= tuning("friendlyEntryTrust", 10)
        and grievance <= tuning(
            "friendlyEntryMaxGrievance", 20
        )
    then
        return "friendly"
    end
    if standing <= tuning("waryEntryStanding", -15)
        or trust <= tuning("waryEntryTrust", -25)
        or fear >= tuning("waryEntryFear", 50)
        or grievance >= tuning("waryEntryGrievance", 30)
    then
        return "wary"
    end
    return "neutral"
end

function Math.RecalculateRelation(relation, worldAgeHours)
    local output = {}
    local key
    local now = math.max(0, tonumber(worldAgeHours) or 0)
    local last
    local elapsedDays
    local state
    local currentState
    local changed = false
    for key, value in pairs(relation or {}) do
        output[key] = value
    end
    last = math.max(
        0,
        math.min(now, tonumber(output.lastEvaluatedAt) or 0)
    )
    elapsedDays = math.max(0, now - last) / 24
    if elapsedDays > 0 then
        output.standing = Math.ClampStanding(driftToZero(
            Math.ClampStanding(output.standing),
            tuning("standingDecayPerDay", 0.05) * elapsedDays
        ))
        output.trust = Math.ClampTrust(driftToZero(
            Math.ClampTrust(output.trust),
            tuning("trustDecayPerDay", 0.025) * elapsedDays
        ))
        output.fear = Math.ClampFear(
            Math.ClampFear(output.fear)
                - tuning("fearDecayPerDay", 0.10) * elapsedDays
        )
        if output.atWar ~= true then
            output.grievance = Math.ClampGrievance(
                Math.ClampGrievance(output.grievance)
                    - tuning("grievanceDecayPerDay", 0.01)
                    * tuning(
                        "peaceGrievanceDecayMultiplier", 2
                    )
                    * elapsedDays
            )
        else
            output.grievance =
                Math.ClampGrievance(output.grievance)
        end
    end
    if (tonumber(output.truceUntil) or 0) > 0
        and (tonumber(output.truceUntil) or 0) <= now
    then
        output.truceUntil = 0
    end
    currentState = Constants.VALID_RELATION_STATES[
        output.state
    ] and output.state or "unknown"
    state = Math.ResolveState(output, now)
    if state ~= currentState then
        output.previousState = currentState
        output.state = state
    end
    output.lastEvaluatedAt = now
    for key, value in pairs(output) do
        if relation == nil or relation[key] ~= value then
            changed = true
            break
        end
    end
    if not changed then
        for key, _ in pairs(relation or {}) do
            if output[key] == nil then
                changed = true
                break
            end
        end
    end
    return output, changed
end

return Math
