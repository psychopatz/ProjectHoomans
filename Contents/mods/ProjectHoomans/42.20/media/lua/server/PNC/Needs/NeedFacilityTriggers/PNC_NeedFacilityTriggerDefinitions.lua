if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NeedFacilityTriggerDefinitions =
    PNC.NeedFacilityTriggerDefinitions or {}

local Definitions = PNC.NeedFacilityTriggerDefinitions
Definitions.ByID = Definitions.ByID or {}
Definitions.ByCapability = Definitions.ByCapability or {}
Definitions.Ordered = Definitions.Ordered or {}

function Definitions.Register(definition)
    if type(definition) ~= "table" or type(definition.id) ~= "string"
        or definition.id == "" or type(definition.capability) ~= "string"
        or definition.capability == ""
    then return false, "INVALID_NEED_FACILITY_TRIGGER" end
    local previous = Definitions.ByID[definition.id]
    if not previous then
        Definitions.Ordered[#Definitions.Ordered + 1] = definition
    else
        for index = 1, #Definitions.Ordered do
            if Definitions.Ordered[index] == previous then
                Definitions.Ordered[index] = definition
                break
            end
        end
    end
    Definitions.ByID[definition.id] = definition
    Definitions.ByCapability[definition.capability] = definition
    return true, definition
end

function Definitions.Get(id)
    return Definitions.ByID[tostring(id or "")]
end

function Definitions.ForCapability(capability)
    return Definitions.ByCapability[tostring(capability or "")]
end

function Definitions.List()
    return Definitions.Ordered
end

local function needValue(record, needType)
    return PNC.IndividualNeeds and PNC.IndividualNeeds.Get
        and tonumber(PNC.IndividualNeeds.Get(record, needType)) or 0
end

function Definitions.Evaluate(definition, record, continuing)
    if not definition or not record then return false end
    if definition.signal == "sleep" then
        local value = needValue(record, "fatigue")
        if continuing then
            return value > (tonumber(definition.completion) or 0.12),
                { value = value, urgency = value,
                    precedence = value >= 0.82 and "CRITICAL_NEED"
                        or "NORMAL_NEED" }
        end
        local metadata = PNC.IndividualNeeds.Queries.GetSleepIntent(record)
        if not metadata then return false end
        metadata.value = value
        return true, metadata
    end
    if definition.signal == "need" then
        local value = needValue(record, definition.needType)
        local supply = PNC.NeedsDefinitions and PNC.NeedsDefinitions.SUPPLY
            and PNC.NeedsDefinitions.SUPPLY[definition.needType] or nil
        local threshold = continuing
            and (definition.completion or supply and supply.target)
            or (definition.trigger or supply and supply.trigger)
        return value > (tonumber(threshold) or 0), {
            value = value,
            urgency = math.max(0, math.min(1, value)),
            precedence = value >= (tonumber(definition.critical) or 0.70)
                and "CRITICAL_NEED" or "NORMAL_NEED",
        }
    end
    if definition.signal == "health" then
        local health = PNC.Health and PNC.Health.Ensure
            and PNC.Health.Ensure(record) or record.health
        local maximum = math.max(1, tonumber(health and health.max) or 100)
        local ratio = math.max(0, math.min(1,
            (tonumber(health and health.current) or maximum) / maximum))
        local threshold = continuing and definition.completion
            or definition.trigger
        return ratio < (tonumber(threshold) or 1), {
            value = 1 - ratio,
            urgency = 1 - ratio,
            precedence = ratio <= (tonumber(definition.critical) or 0.40)
                and "CRITICAL_NEED" or "NORMAL_NEED",
        }
    end
    if definition.signal == "condition" then
        local condition = PNC.ConditionStats and PNC.ConditionStats.Ensure
            and PNC.ConditionStats.Ensure(record) or record.conditionStats or {}
        local value = tonumber(condition[definition.conditionType]) or 0
        local threshold = continuing and definition.completion
            or definition.trigger
        return value > (tonumber(threshold) or 0), {
            value = value,
            urgency = math.max(0, math.min(1, value / 100)),
            precedence = value >= (tonumber(definition.critical) or 70)
                and "CRITICAL_NEED" or "NORMAL_NEED",
        }
    end
    return false
end

Definitions.Register({
    id = "sleep", kind = "SLEEP", signal = "sleep", needType = "fatigue",
    capability = "sleep", completion = 0.12,
})
Definitions.Register({
    id = "hydration", kind = "DRINK", signal = "need", needType = "thirst",
    capability = "water.drink",
    critical = 0.70,
})
Definitions.Register({
    id = "hunger", kind = "EAT", signal = "need", needType = "hunger",
    capability = "food.dine",
    critical = 0.70,
})
Definitions.Register({
    id = "health", kind = "RECOVER", signal = "health",
    capability = "health.recover", trigger = 0.80, completion = 0.98,
    critical = 0.40,
})
Definitions.Register({
    id = "recreation", kind = "RECREATE", signal = "condition",
    conditionType = "boredom", capability = "recreation",
    trigger = 45, completion = 15, critical = 70,
})

return Definitions
