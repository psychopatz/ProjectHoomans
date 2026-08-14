local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
local JournalPresentation = require "PNC/UI/Communities/PNC_ColonistJournalPresentation"
local Presentation = {}

local function regionFloor(region)
    local minimum
    for z, _ in pairs(type(region) == "table"
        and type(region.levels) == "table" and region.levels or {})
    do
        z = tonumber(z)
        if z and (not minimum or z < minimum) then minimum = z end
    end
    return minimum
end

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
            "ALL NEEDS NORMAL",
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

function Presentation.BuildSettlement(snapshot)
    local settlement = snapshot and snapshot.settlement or nil
    local result = snapshot and snapshot.actionResult or nil
    local resultRow = result and Presentation.Detail(
        Shared.Tr("UI_PNC_Base_LastAction", "LAST ACTION"),
        string.upper(tostring(result.action or "ACTION")) .. " - "
            .. Shared.SettlementReason(result.reason
                or (result.ok and "OK" or "FAILED")),
        result.ok and "success" or "danger") or nil
    if not settlement then
        local rows = { Presentation.Detail(
            Shared.Tr("UI_PNC_Base_NotEstablished", "BASE NOT ESTABLISHED"),
            Shared.Tr("UI_PNC_Base_NotEstablishedHelp",
                "Claim a connected territory to establish this settlement.")) }
        if resultRow then table.insert(rows, 1, resultRow) end
        return rows
    end
    local territory = settlement.territory or {}
    local rows = {
        Presentation.Detail(Shared.Tr("UI_PNC_Base_HQ", "SETTLEMENT HQ"),
            Shared.TrFormat("UI_PNC_Base_Level", "Level %s",
                tostring(settlement.hqLevel or 1)), "accent"),
        Presentation.Detail(Shared.Tr("UI_PNC_Base_Claimed", "CLAIMED AREA"),
            tostring(territory.claimedArea or 0)),
        Presentation.Detail(Shared.Tr("UI_PNC_Base_Capacity", "TERRITORY CAPACITY"),
            tostring(territory.territoryCapacity or 0)),
        Presentation.Detail(Shared.Tr("UI_PNC_Base_Limit", "HQ TERRITORY LIMIT"),
            tostring(territory.territoryLimit or 0)),
        Presentation.Detail(Shared.Tr("UI_PNC_Base_Free", "FREE EXPANSION CAPACITY"),
            tostring(territory.freeExpansionCapacity or 0)),
        Presentation.Detail(Shared.Tr("UI_PNC_Base_Barricades", "PERIMETER REINFORCEMENTS"),
            tostring(territory.barricadeCount or 0)),
        Presentation.Detail(Shared.Tr("UI_PNC_Base_Revision", "BASE REVISION"),
            tostring(settlement.revision or 0)),
    }
    local geometry = settlement.geometry or {}
    if resultRow then table.insert(rows, 1, resultRow) end
    rows[#rows + 1] = Presentation.Detail(
        Shared.Tr("UI_PNC_Base_Geometry", "TERRITORY GEOMETRY"),
        tostring(geometry.spanCount or 0) .. " spans; "
            .. (geometry.connected and "connected" or "disconnected"))
    for _, facility in ipairs(settlement.facilities or {}) do
        rows[#rows + 1] = Presentation.Detail(
            Shared.Tr("UI_PNC_Facility_Entry", "FACILITY") .. "  "
                .. tostring(facility.definitionId or facility.id),
            Shared.TrFormat("UI_PNC_Facility_Summary", "Level %s - %s - %s components",
                tostring(facility.level or 1), tostring(facility.cachedState or "PLANNED"),
                tostring(#(facility.components or {}))),
            facility.cachedState == "OPERATIONAL" and "success" or "warning")
        for _, component in ipairs(facility.components or {}) do
            local description
            if component.kind == "anchor" then
                description = tostring(component.x) .. ", "
                    .. tostring(component.y) .. "  Floor "
                    .. tostring((tonumber(component.z) or 0) + 1)
            else
                local floor = regionFloor(component.region)
                description = tostring(component.tileCount or 0) .. " tiles"
                    .. (floor and "  Floor " .. tostring(floor + 1) or "")
            end
            rows[#rows + 1] = Presentation.Detail(
                "  " .. tostring(component.role or component.kind), description)
        end
    end
    rows[#rows + 1] = Presentation.Detail(
        Shared.Tr("UI_PNC_Stockpile_Nodes", "STOCKPILE ACCESS NODES"),
        tostring(#(settlement.stockpileNodes or {})))
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
    rows[#rows + 1] = Presentation.Detail(
        Shared.Tr("UI_PNC_Nutrition_Calories", "CALORIE BALANCE"),
        string.format("%.0f kcal", tonumber(value.nutrition
            and value.nutrition.calories) or 0), "accent")
    rows[#rows + 1] = Presentation.Detail(
        Shared.Tr("UI_PNC_Nutrition_Weight", "WEIGHT"),
        string.format("%.1f kg", tonumber(value.nutrition
            and value.nutrition.weight) or 0), "accent")
    local journalRows = JournalPresentation.Rows(value.journal)
    rows[#rows + 1] = Presentation.Detail(Shared.Tr(
        "UI_PNC_Journal_Title", "COLONIST JOURNAL"), Shared.TrFormat(
            "UI_PNC_Journal_EntryCount", "%s entries",
            tostring(#journalRows)), "accent")
    if #journalRows == 0 then
        rows[#rows + 1] = Presentation.Detail(Shared.Tr(
            "UI_PNC_Journal_Empty", "No recorded history yet"), "")
    else
        for _, journalRow in ipairs(journalRows) do
            rows[#rows + 1] = Presentation.Detail(
                journalRow.message, journalRow.time
            )
        end
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
    rows[#rows + 1] = Presentation.Detail(
        Shared.Tr("UI_PNC_Nutrition_Calories", "CALORIE BALANCE"),
        string.format("%.0f kcal", tonumber(value.nutrition
            and value.nutrition.calories) or 0), "accent")
    rows[#rows + 1] = Presentation.Detail(
        Shared.Tr("UI_PNC_Nutrition_Weight", "WEIGHT"),
        string.format("%.1f kg", tonumber(value.nutrition
            and value.nutrition.weight) or 0), "accent")
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
