local Shared = {}

Shared.NEED_TYPES = { "hunger", "thirst", "fatigue" }
Shared.LEVELS = { "NORMAL", "MINOR", "MODERATE", "SEVERE", "CRITICAL" }
Shared.LEVEL_COLORS = {
    GOOD = "success",
    STABLE = "accent",
    LOW = "warning",
    EMERGENCY = "danger",
    NORMAL = "success",
    MINOR = "accent",
    MODERATE = "warning",
    SEVERE = "danger",
    CRITICAL = "danger",
}
Shared.NEED_LABEL_KEYS = {
    hunger = "UI_PNC_Need_Hunger",
    thirst = "UI_PNC_Need_Thirst",
    fatigue = "UI_PNC_Need_Fatigue",
}
Shared.ROSTER_ICON_PATHS = {
    hunger = "media/ui/Moodles/32/Status_Hunger.png",
    thirst = "media/ui/Moodles/32/Status_Thirst.png",
    fatigue = "media/ui/Moodles/32/Mood_Exhausted.png",
    bleeding = "media/ui/Moodles/32/Status_Bleeding.png",
    pained = "media/ui/Moodles/32/Mood_Pained.png",
    critical = "media/ui/Moodles/32/Mood_Angry.png",
}
Shared.ROSTER_ICON_TOOLTIP_KEYS = {
    hunger = "UI_PNC_Roster_Tooltip_Hunger",
    thirst = "UI_PNC_Roster_Tooltip_Thirst",
    fatigue = "UI_PNC_Roster_Tooltip_Fatigue",
    bleeding = "UI_PNC_Roster_Tooltip_Bleeding",
    pained = "UI_PNC_Roster_Tooltip_Pained",
    critical = "UI_PNC_Roster_Tooltip_Critical",
}
Shared.ROSTER_ICON_TOOLTIP_FALLBACKS = {
    hunger = "This colonist is hungry and needs food.",
    thirst = "This colonist is thirsty and needs water.",
    fatigue = "This colonist is tired and needs rest.",
    bleeding = "This colonist has an untreated wound and is bleeding.",
    pained = "This colonist has a bandaged wound and is still recovering.",
    critical = "This colonist has a critical need that requires immediate attention.",
}
Shared.CONDITION_LABEL_KEYS = {
    stress = "UI_PNC_Stat_Stress",
    boredom = "UI_PNC_Stat_Boredom",
    panic = "UI_PNC_Stat_Panic",
}
Shared.MORALE_LABEL_KEY = "UI_PNC_Stat_Morale"
Shared.REFRESH_LABEL_KEY = "UI_PNC_Colony_Refresh"
Shared.DIAGNOSTICS_LABEL_KEY = "UI_PNC_Colony_Diagnostics"
Shared.SETTLEMENT_REASON_KEYS = {
    COLONY_STATE_UNAVAILABLE = "UI_PNC_SettlementReason_ColonyUnavailable",
    FACTION_STATE_UNAVAILABLE = "UI_PNC_SettlementReason_FactionUnavailable",
    BASE_STATE_UNAVAILABLE = "UI_PNC_SettlementReason_BaseUnavailable",
    CLIENT_UNAVAILABLE = "UI_PNC_SettlementReason_ClientUnavailable",
    NO_PERMISSION = "UI_PNC_SettlementReason_NoPermission",
    REVISION_CONFLICT = "UI_PNC_SettlementReason_RevisionConflict",
    EMPTY_REGION = "UI_PNC_SettlementReason_EmptyRegion",
    BASE_DISCONNECTED = "UI_PNC_SettlementReason_Disconnected",
    BASE_CAPACITY_EXCEEDED = "UI_PNC_SettlementReason_CapacityExceeded",
    NO_NEW_TERRITORY = "UI_PNC_SettlementReason_NoNewTerritory",
    NO_TERRITORY_REMOVED = "UI_PNC_SettlementReason_NoneRemoved",
    HQ_TERRITORY_LIMIT = "UI_PNC_SettlementReason_HQLimit",
    HQ_LEVEL_TOO_LOW = "UI_PNC_SettlementReason_HQTooLow",
    TECHNOLOGY_REQUIRED = "UI_PNC_SettlementReason_TechnologyRequired",
    MAX_LEVEL = "UI_PNC_SettlementReason_MaxLevel",
    FACILITY_COMPONENT_LIMIT = "UI_PNC_SettlementReason_ComponentLimit",
    FACILITY_AREA_TOO_LARGE = "UI_PNC_SettlementReason_AreaTooLarge",
    OUTSIDE_BASE = "UI_PNC_SettlementReason_OutsideBase",
    OUTSIDE_FACILITY = "UI_PNC_SettlementReason_OutsideFacility",
    OVERLAP_NOT_ALLOWED = "UI_PNC_SettlementReason_Overlap",
    PLAYER_ZONE_OCCUPIED = "UI_PNC_SettlementReason_PlayerZoneOccupied",
    NPC_BASE_OCCUPIED = "UI_PNC_SettlementReason_NPCBaseOccupied",
    INSUFFICIENT_BUILD_MATERIALS = "UI_PNC_SettlementReason_Materials",
    MISSING_MATERIALS = "UI_PNC_SettlementReason_Materials",
    FACILITY_WORK_IN_PROGRESS = "UI_PNC_SettlementReason_WorkInProgress",
    FACILITY_IN_USE = "UI_PNC_SettlementReason_FacilityInUse",
    FACILITY_NOT_BUILT = "UI_PNC_SettlementReason_FacilityNotBuilt",
    STOCKPILE_CANNOT_DECONSTRUCT =
        "UI_PNC_SettlementReason_StockpileCannotDeconstruct",
    FACILITY_FOOTPRINT_REQUIRED = "UI_PNC_SettlementReason_FootprintRequired",
    BED_REQUIRED = "UI_PNC_SettlementReason_BedRequired",
    FARMLAND_REQUIRED = "UI_PNC_SettlementReason_FarmlandRequired",
    WORLD_SQUARE_UNLOADED = "UI_PNC_SettlementReason_SquareUnloaded",
    NO_STOCKPILE_ACCESS_NODE = "UI_PNC_SettlementReason_StockpileNode",
}
Shared.NEED_METER_THRESHOLDS = {
    hunger = {
        { maximum = 0.15, color = "success" },
        { maximum = 0.25, color = "accent" },
        { maximum = 0.45, color = "warning" },
        { maximum = 1.00, color = "danger" },
    },
    thirst = {
        { maximum = 0.12, color = "success" },
        { maximum = 0.25, color = "accent" },
        { maximum = 0.70, color = "warning" },
        { maximum = 1.00, color = "danger" },
    },
    fatigue = {
        { maximum = 0.60, color = "success" },
        { maximum = 0.70, color = "accent" },
        { maximum = 0.80, color = "warning" },
        { maximum = 1.00, color = "danger" },
    },
}

function Shared.Tr(key, fallback)
    return PNC.Translation.GetKey(key, fallback)
end

function Shared.TrFormat(key, fallback, ...)
    return PNC.Translation.TrFormat(key, fallback, ...)
end

function Shared.Text(value, fallback)
    value = value ~= nil and tostring(value) or ""
    return value ~= "" and value or tostring(fallback or "")
end

function Shared.SettlementReason(reason)
    reason = tostring(reason or "")
    local key = Shared.SETTLEMENT_REASON_KEYS[reason]
    return key and Shared.Tr(key, reason) or reason
end

function Shared.ListValue(list)
    local entry = list and list.getItem and list:getItem() or nil
    local row = entry and entry.item or nil
    -- Roster rows keep presentation metadata on the row and the authoritative
    -- colonist snapshot in value. Detail tabs must receive the snapshot; using
    -- the wrapper silently turns every missing need into zero.
    return row and (row.value or row) or nil
end

function Shared.NeedLevel(needType, value)
    if PNC.NeedsDefinitions and PNC.NeedsDefinitions.GetLevel then
        return PNC.NeedsDefinitions.GetLevel(needType, tonumber(value) or 0)
    end
    return "NORMAL"
end

function Shared.NeedMeterColor(value, _, spec)
    return Shared.LEVEL_COLORS[
        Shared.NeedLevel(spec.needType, value)
    ] or "accent"
end

function Shared.ConditionMeterColor(value, _, spec)
    local level = PNC.ConditionStats and PNC.ConditionStats.GetLevel
        and PNC.ConditionStats.GetLevel(spec.conditionType, value) or "STABLE"
    return Shared.LEVEL_COLORS[level] or "accent"
end

function Shared.MoraleMeterColor(value)
    value = tonumber(value) or 0
    if value < -50 then return "danger" end
    if value < 0 then return "warning" end
    if value < 50 then return "accent" end
    return "success"
end

function Shared.WorstNeed(person)
    local worstIndex = 1
    local worstType = Shared.NEED_TYPES[1]
    for _, needType in ipairs(Shared.NEED_TYPES) do
        local level = Shared.NeedLevel(
            needType, person.needs and person.needs[needType]
        )
        for index, candidate in ipairs(Shared.LEVELS) do
            if candidate == level and index > worstIndex then
                worstIndex = index
                worstType = needType
            end
        end
    end
    return Shared.LEVELS[worstIndex], worstType
end

function Shared.RosterIndicators(person)
    local indicators = {}
    local critical = false
    local function add(id)
        indicators[#indicators + 1] = {
            id = id,
            texturePath = Shared.ROSTER_ICON_PATHS[id],
            tooltip = Shared.Tr(Shared.ROSTER_ICON_TOOLTIP_KEYS[id],
                Shared.ROSTER_ICON_TOOLTIP_FALLBACKS[id]),
        }
    end

    person = person or {}
    local needs = person.needs or {}
    for _, needType in ipairs(Shared.NEED_TYPES) do
        local level = Shared.NeedLevel(needType, needs[needType])
        if level ~= "NORMAL" then add(needType) end
        if level == "CRITICAL" then critical = true end
    end

    local medical = person.medicalStatus or {}
    local openWoundCount = tonumber(medical.openWoundCount) or 0
    local bandagedWoundCount = tonumber(medical.bandagedWoundCount) or 0
    local bleeding = medical.bleeding == true
        or (tonumber(medical.bleedingRate) or 0) > 0
    if openWoundCount > 0 or bleeding then
        add("bleeding")
    elseif bandagedWoundCount > 0 then
        add("pained")
    end
    if critical then add("critical") end
    return indicators
end

return Shared
