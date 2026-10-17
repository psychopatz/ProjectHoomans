-- Semantic situation emotional, relationship, and health projection provider.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Situation = PNC.Semantics.DialogueSituation
local Internal = Situation.Internal or {}
Situation.Internal = Internal
local text = Internal.Text
local finite = Internal.Finite
local bounded = Internal.Bounded
local fromSource = Internal.FromSource
local needLevel = Internal.NeedLevel
local NEED_TYPES = Internal.NeedTypes
local NEED_WEIGHTS = Internal.NeedWeights
local CONDITION_TYPES = Internal.ConditionTypes
local CONDITION_WEIGHTS = Internal.ConditionWeights

local function hasEntries(value)
    if type(value) ~= "table" then return false end
    for _ in pairs(value) do return true end
    return false
end

local function needs(context)
    local values = fromSource(context, "needs")
    local output = {
        highest = nil,
        urgency = "normal",
        level = "NORMAL",
    }
    if type(values) ~= "table" then return output end

    local highestWeight = 0
    local index
    local needType
    local value
    local level
    local urgency
    local weight
    for index = 1, math.min(#NEED_TYPES, Situation.MAX_NEED_VALUES) do
        needType = NEED_TYPES[index]
        value = bounded(values[needType], 0, 1)
        if value ~= nil then
            level, urgency, weight = needLevel(needType, value)
            weight = weight + (NEED_WEIGHTS[needType] or 0) * 0.01
            if weight > highestWeight then
                highestWeight = weight
                output.highest = needType
                output.urgency = urgency
                output.level = level
            end
        end
    end

    -- A network summary may be intentionally redacted down to its derived
    -- highest/urgency fields. Preserve that semantic information when raw
    -- values are unavailable.
    if output.highest == nil and values.highest ~= nil then
        output.highest = text(values.highest)
        output.urgency = text(values.urgency or values.highestLevel)
        output.urgency = output.urgency ~= "" and output.urgency or "normal"
        output.level = string.upper(output.urgency)
    end
    return output
end

local function attitude(context, relationship)
    local graph = PNC.RelationshipGraph
    if graph and type(graph.ResolveAttitude) == "function"
        and type(relationship) == "table"
    then
        local ok, value = pcall(
            graph.ResolveAttitude,
            relationship.approval,
            relationship.respect
        )
        if ok and value then return tostring(value) end
    end
    return nil
end

local function conditionLevel(conditionType, value)
    local stats = PNC.ConditionStats
    if stats and type(stats.GetLevel) == "function" then
        local ok, level = pcall(stats.GetLevel, conditionType, value)
        if ok and level then
            local normalized = text(level)
            local weights = {
                good = 0, stable = 0, low = 1,
                critical = 2, emergency = 3,
            }
            return tostring(level), normalized, weights[normalized] or 0
        end
    end
    if conditionType == "stress" then
        if value >= 0.90 then return "EMERGENCY", "emergency", 3 end
        if value >= 0.75 then return "CRITICAL", "critical", 2 end
        if value >= 0.50 then return "LOW", "low", 1 end
        return "STABLE", "stable", 0
    end
    if value >= 90 then return "EMERGENCY", "emergency", 3 end
    if value >= 70 then return "CRITICAL", "critical", 2 end
    if value >= 45 then return "LOW", "low", 1 end
    return "STABLE", "stable", 0
end

local function emotionalState(context)
    local values = fromSource(context, "conditionStats")
    local output = {
        highest = nil,
        urgency = "stable",
        level = "STABLE",
    }
    if type(values) ~= "table" then return output end

    local highestWeight = 0
    local index
    local conditionType
    local value
    local level
    local urgency
    local weight
    for index = 1, math.min(#CONDITION_TYPES, Situation.MAX_CONDITION_VALUES) do
        conditionType = CONDITION_TYPES[index]
        value = finite(values[conditionType])
        if value ~= nil then
            if conditionType == "stress" then
                value = math.max(0, math.min(1, value))
            else
                value = math.max(0, math.min(100, value))
            end
            level, urgency, weight = conditionLevel(conditionType, value)
            weight = weight + (CONDITION_WEIGHTS[conditionType] or 0) * 0.01
            if weight > highestWeight then
                highestWeight = weight
                output.highest = conditionType
                output.urgency = urgency
                output.level = level
            end
        end
    end
    return output
end

local function healthState(context)
    local value = text(fromSource(context, "healthState"))
    -- The live NPC health contract uses "normal" until incapacitation; the
    -- semantic response catalog needs a stable injury signal for ordinary
    -- wounds as well. Prefer explicit semantic states, then derive injury
    -- from the bounded body-health snapshot or scalar HP projection.
    if value == "incapacitated" then return "injured" end
    if value == "wounded" or value == "critical"
        or value == "injured"
    then
        return value
    end

    local bodyHealth = fromSource(context, "bodyHealth")
    if type(bodyHealth) == "table" then
        if bodyHealth.infected == true
            or (tonumber(bodyHealth.openWoundCount) or 0) > 0
            or (tonumber(bodyHealth.bandagedWoundCount) or 0) > 0
            or (tonumber(bodyHealth.overallPercent) or 100) < 99
            or hasEntries(bodyHealth.wounds)
        then
            return "injured"
        end
    end

    local current = finite(fromSource(context, "hpCurrent"))
    local maximum = finite(fromSource(context, "hpMax"))
    if current ~= nil and maximum ~= nil
        and maximum > 0 and current < maximum
    then
        return "injured"
    end

    return value ~= "" and value or nil
end

local function socialStyle(context)
    local personality = fromSource(context, "npcPersonality")
    local traits = fromSource(context, "npcTraits")
    local value = type(personality) == "table"
        and personality.socialStyle or nil
    value = text(value)
    if value == "friendly" or value == "withdrawn" or value == "neutral" then
        return value
    end
    if type(traits) == "table" then
        local key
        local enabled
        for key, enabled in pairs(traits) do
            local rawID = enabled == true and key
                or type(enabled) == "string" and enabled or nil
            if rawID then
                local id = text(rawID)
                if string.find(id, "withdrawn", 1, true) then
                    return "withdrawn"
                end
                if string.find(id, "reserved", 1, true)
                    or string.find(id, "guarded", 1, true)
                    or string.find(id, "suspicious", 1, true)
                    or string.find(id, "stoic", 1, true)
                then
                    return "withdrawn"
                end
                if string.find(id, "friendly", 1, true) then
                    return "friendly"
                end
                if string.find(id, "kind", 1, true)
                    or string.find(id, "protective", 1, true)
                    or string.find(id, "warm", 1, true)
                then
                    return "friendly"
                end
            end
        end
    end
    return nil
end


Internal.Needs = needs
Internal.Attitude = attitude
Internal.ConditionLevel = conditionLevel
Internal.EmotionalState = emotionalState
Internal.HealthState = healthState
Internal.SocialStyle = socialStyle

return Situation
