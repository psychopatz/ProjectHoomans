local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
local Presentation = {}

function Presentation.Detail(label, detail, colorName)
    return {
        key = tostring(label or ""),
        label = tostring(label or ""),
        detail = tostring(detail or ""),
        colorName = colorName,
    }
end

function Presentation.NeedMeter(needType, amount)
    local level = Shared.NeedLevel(needType, amount)
    return {
        key = needType,
        label = Shared.Tr(Shared.NEED_LABEL_KEYS[needType],
            string.upper(needType)),
        meter = true,
        value = tonumber(amount) or 0,
        minimum = 0,
        maximum = 1,
        needType = needType,
        colorName = Shared.LEVEL_COLORS[level] or "accent",
        thresholds = Shared.NEED_METER_THRESHOLDS[needType],
    }
end

function Presentation.ConditionMeter(statType, amount)
    local definition = PNC.ConditionStats
        and PNC.ConditionStats.DEFINITIONS[statType] or nil
    if not definition then return nil end
    return {
        key = statType,
        label = Shared.Tr(Shared.CONDITION_LABEL_KEYS[statType],
            string.upper(statType)),
        meter = true,
        value = tonumber(amount) or definition.default,
        minimum = definition.minimum,
        maximum = definition.maximum,
        conditionType = statType,
        colorResolver = Shared.ConditionMeterColor,
        decimals = statType == "stress" and 2 or 0,
    }
end

function Presentation.MoraleMeter(amount)
    return {
        key = "morale",
        label = Shared.Tr(Shared.MORALE_LABEL_KEY, "MORALE"),
        meter = true,
        value = tonumber(amount) or 0,
        minimum = -100,
        maximum = 100,
        colorResolver = Shared.MoraleMeterColor,
        decimals = 0,
    }
end

function Presentation.BuildRoster(snapshot)
    local rows = {}
    for _, person in ipairs(snapshot and snapshot.people or {}) do
        local level, needType = Shared.WorstNeed(person)
        rows[#rows + 1] = {
            id = person.id,
            key = person.id,
            label = Shared.Text(person.name, person.id),
            detail = string.upper(Shared.Text(person.role, "Companion"))
                .. "  -  " .. Shared.Text(person.activity, "Idle")
                .. "  -  " .. string.upper(needType),
            value = person,
            worstLevel = level,
        }
    end
    return rows
end

function Presentation.BuildOverview(snapshot)
    snapshot = snapshot or {}
    local colony = snapshot.colony or {}
    local rows = {
        Presentation.Detail("STATUS", "Active community"),
        Presentation.Detail("HOME", colony.mode
            and string.upper(colony.mode) or "CAMP NOT ESTABLISHED"),
        Presentation.Detail("POPULATION",
            tostring(#(snapshot.people or {})) .. " active companions"),
    }
    if #(snapshot.attention or {}) == 0 then
        rows[#rows + 1] = Presentation.Detail(
            "ALL NEEDS STABLE",
            "No companion currently needs attention.", "success"
        )
    else
        for _, warning in ipairs(snapshot.attention or {}) do
            rows[#rows + 1] = Presentation.Detail(
                Shared.Text(warning.name, "Unknown companion"),
                string.upper(Shared.Text(warning.needType, "need"))
                    .. "  " .. string.format("%.2f / 1",
                        tonumber(warning.value) or 0),
                Shared.LEVEL_COLORS[warning.severity] or "warning"
            )
        end
    end
    return rows
end

function Presentation.BuildPeople(person)
    if not person then
        return { Presentation.Detail("NO COMPANIONS",
            "Recruit someone to populate this colony.") }
    end
    local value = person.value or person
    local rows = {
        Presentation.Detail(Shared.Text(value.name, "Unknown"),
            string.upper(Shared.Text(value.role, "Companion")), "accent"),
        Presentation.Detail("ACTIVITY", Shared.Text(value.activity, "Idle")),
        Presentation.Detail("ASSIGNMENT",
            Shared.Text(value.job, "Unassigned")),
        Presentation.Detail("HEALTH",
            string.upper(Shared.Text(value.health, "Unknown"))),
    }
    for _, needType in ipairs(Shared.NEED_TYPES) do
        rows[#rows + 1] = Presentation.NeedMeter(
            needType, value.needs and value.needs[needType]
        )
    end
    return rows
end

function Presentation.BuildNeeds(person)
    if not person then
        return { Presentation.Detail(Shared.Tr(
            "UI_PNC_Needs_NoCompanions", "NO COMPANIONS"), "") }
    end
    local value = person.value or person
    local rows = {
        Presentation.Detail(Shared.Text(value.name, value.id),
            string.upper(Shared.Text(value.role, "Companion")), "accent"),
    }
    for _, needType in ipairs(Shared.NEED_TYPES) do
        rows[#rows + 1] = Presentation.NeedMeter(
            needType, value.needs and value.needs[needType]
        )
    end
    for _, statType in ipairs(PNC.ConditionStats
        and PNC.ConditionStats.TYPES or {})
    do
        local row = Presentation.ConditionMeter(
            statType, value.conditionStats and value.conditionStats[statType]
        )
        if row then rows[#rows + 1] = row end
    end
    rows[#rows + 1] = Presentation.MoraleMeter(value.morale)
    return rows
end

return Presentation
