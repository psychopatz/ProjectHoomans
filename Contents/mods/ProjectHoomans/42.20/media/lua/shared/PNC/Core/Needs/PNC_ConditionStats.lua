-- Player-like secondary NPC stats plus Project Hoomans trait dynamics.
PNC = PNC or {}
PNC.ConditionStats = PNC.ConditionStats or {}

local Stats = PNC.ConditionStats

Stats.VERSION = 1
Stats.TRAIT_GENERATION_VERSION = 1
Stats.TYPES = { "stress", "boredom", "panic" }
Stats.DEFINITIONS = {
    stress = { minimum = 0, maximum = 1, default = 0,
        thresholds = { 0.25, 0.50, 0.75, 0.90 } },
    boredom = { minimum = 0, maximum = 100, default = 0,
        thresholds = { 20, 45, 70, 90 } },
    panic = { minimum = 0, maximum = 100, default = 0,
        thresholds = { 20, 45, 70, 90 } },
}
Stats.LEVELS = { "GOOD", "STABLE", "LOW", "CRITICAL", "EMERGENCY" }
Stats.TRAITS = {
    IRON_NERVES = "pnc_ironnerves",
    FRAYED_NERVES = "pnc_frayednerves",
    BUSY_HANDS = "pnc_busyhands",
    RESTLESS_SOUL = "pnc_restlesssoul",
    HARDY = "pnc_hardy",
    DELICATE = "pnc_delicate",
    SECOND_WIND = "pnc_secondwind",
    HEAVY_SLEEPER = "pnc_heavysleeper",
}
Stats.TRAIT_DEFINITIONS = {
    { id = Stats.TRAITS.IRON_NERVES,
        labelKey = "UI_PNC_Trait_IronNerves" },
    { id = Stats.TRAITS.FRAYED_NERVES,
        labelKey = "UI_PNC_Trait_FrayedNerves" },
    { id = Stats.TRAITS.BUSY_HANDS,
        labelKey = "UI_PNC_Trait_BusyHands" },
    { id = Stats.TRAITS.RESTLESS_SOUL,
        labelKey = "UI_PNC_Trait_RestlessSoul" },
    { id = Stats.TRAITS.HARDY, labelKey = "UI_PNC_Trait_Hardy" },
    { id = Stats.TRAITS.DELICATE, labelKey = "UI_PNC_Trait_Delicate" },
    { id = Stats.TRAITS.SECOND_WIND,
        labelKey = "UI_PNC_Trait_SecondWind" },
    { id = Stats.TRAITS.HEAVY_SLEEPER,
        labelKey = "UI_PNC_Trait_HeavySleeper" },
}
Stats.TRAIT_GROUPS = {
    { salt = "nerves", choices = {
        { false, 68 }, { Stats.TRAITS.IRON_NERVES, 18 },
        { Stats.TRAITS.FRAYED_NERVES, 14 },
    } },
    { salt = "tempo", choices = {
        { false, 65 }, { Stats.TRAITS.BUSY_HANDS, 20 },
        { Stats.TRAITS.RESTLESS_SOUL, 15 },
    } },
    { salt = "constitution", choices = {
        { false, 68 }, { Stats.TRAITS.HARDY, 18 },
        { Stats.TRAITS.DELICATE, 14 },
    } },
    { salt = "fatigue", choices = {
        { false, 72 }, { Stats.TRAITS.SECOND_WIND, 16 },
        { Stats.TRAITS.HEAVY_SLEEPER, 12 },
    } },
}

local function traitID(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "^pnc[%.:]", "pnc_")
    value = string.gsub(value, "[^%w_]", "")
    return value
end

function Stats.NormalizeTraits(source)
    local output = {}
    for key, value in pairs(type(source) == "table" and source or {}) do
        local id = type(key) == "number" and traitID(value) or traitID(key)
        if id ~= "" and (type(key) == "number" or value == true) then
            output[id] = true
        end
    end
    return output
end

local function choice(seed, salt, values)
    local roll = PNC.Identity and PNC.Identity.Float
        and PNC.Identity.Float(seed, salt) * 100 or 0
    local cursor = 0
    for index = 1, #values do
        cursor = cursor + (tonumber(values[index][2]) or 0)
        if roll < cursor then return values[index][1] end
    end
    return values[#values][1]
end

function Stats.GenerateTraits(identitySeed, archetypeID)
    local seed = PNC.Identity and PNC.Identity.NormalizeSeed
        and PNC.Identity.NormalizeSeed(identitySeed, archetypeID)
        or math.max(1, math.floor(tonumber(identitySeed) or 1))
    local output = {}
    for index = 1, #Stats.TRAIT_GROUPS do
        local group = Stats.TRAIT_GROUPS[index]
        local selected = choice(seed, "npc_dynamic_traits:v"
            .. tostring(Stats.TRAIT_GENERATION_VERSION) .. ":"
            .. tostring(archetypeID or "General") .. ":" .. group.salt,
            group.choices)
        if selected then output[selected] = true end
    end
    return output
end

function Stats.ResolveInitialTraits(source, seed, archetypeID, authored)
    if authored == true then return Stats.NormalizeTraits(source), true, 0 end
    return Stats.GenerateTraits(seed, archetypeID), false,
        Stats.TRAIT_GENERATION_VERSION
end

function Stats.HasTrait(record, id)
    return Stats.NormalizeTraits(record and record.dynamicTraits)[traitID(id)]
        == true
end

function Stats.SetTraits(record, source)
    if type(record) ~= "table" then return false, "npc_missing" end
    record.dynamicTraits = Stats.NormalizeTraits(source)
    record.dynamicTraitsAuthored = true
    record.dynamicTraitsGenerationVersion = 0
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "dynamic_traits_changed")
    end
    return true, "updated", Stats.NormalizeTraits(record.dynamicTraits)
end

function Stats.EnsureTraits(record)
    if type(record) ~= "table" then return nil, false end
    local version = math.max(0, math.floor(
        tonumber(record.dynamicTraitsGenerationVersion) or 0))
    if record.dynamicTraitsAuthored == true or version > 0 then
        record.dynamicTraits = Stats.NormalizeTraits(record.dynamicTraits)
        return record.dynamicTraits, false
    end
    local existing = Stats.NormalizeTraits(record.dynamicTraits)
    local hasExisting = false
    for _, enabled in pairs(existing) do
        if enabled == true then hasExisting = true break end
    end
    if hasExisting then
        record.dynamicTraits = existing
        record.dynamicTraitsAuthored = true
        record.dynamicTraitsGenerationVersion = 0
    else
        record.dynamicTraits = Stats.GenerateTraits(
            record.identitySeed, record.archetypeID)
        record.dynamicTraitsAuthored = false
        record.dynamicTraitsGenerationVersion = Stats.TRAIT_GENERATION_VERSION
    end
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "dynamic_traits_initialized")
    end
    return record.dynamicTraits, true
end

function Stats.GetActiveTraitIDs(source)
    local traits = Stats.NormalizeTraits(source and source.dynamicTraits or source)
    local output = {}
    for index = 1, #Stats.TRAIT_DEFINITIONS do
        local id = Stats.TRAIT_DEFINITIONS[index].id
        if traits[id] then output[#output + 1] = id end
    end
    return output
end

function Stats.GetTraitLabelKey(id)
    id = traitID(id)
    for index = 1, #Stats.TRAIT_DEFINITIONS do
        if Stats.TRAIT_DEFINITIONS[index].id == id then
            return Stats.TRAIT_DEFINITIONS[index].labelKey
        end
    end
end

function Stats.GetNeedRateMultiplier(record, needType, state, activity)
    local value = 1
    if Stats.HasTrait(record, Stats.TRAITS.HARDY)
        and (needType == "hunger" or needType == "hydration")
    then value = value * 0.90 end
    if Stats.HasTrait(record, Stats.TRAITS.DELICATE)
        and (needType == "hunger" or needType == "hydration")
    then value = value * 1.10 end
    if needType == "fatigue" then
        if Stats.HasTrait(record, Stats.TRAITS.SECOND_WIND)
            and (tonumber(state and state.fatigue) or 0) >= 0.70
            and activity ~= "sleeping"
        then value = value * 0.70 end
        if Stats.HasTrait(record, Stats.TRAITS.HEAVY_SLEEPER) then
            value = value * (activity == "sleeping" and 1.25 or 1.10)
        end
    end
    return value
end

function Stats.NormalizeState(value, at)
    local source = type(value) == "table" and value or {}
    local output = { version = Stats.VERSION,
        lastUpdateWorldAge = math.max(0, tonumber(source.lastUpdateWorldAge)
            or tonumber(at) or 0) }
    for index = 1, #Stats.TYPES do
        local id = Stats.TYPES[index]
        local definition = Stats.DEFINITIONS[id]
        output[id] = math.max(definition.minimum, math.min(definition.maximum,
            tonumber(source[id]) or definition.default))
    end
    return output
end

function Stats.GetLevel(id, value)
    local definition = Stats.DEFINITIONS[id] or Stats.DEFINITIONS.stress
    value = tonumber(value) or definition.default
    for index = 1, #definition.thresholds do
        if value < definition.thresholds[index] then return Stats.LEVELS[index] end
    end
    return "EMERGENCY"
end

function Stats.Ensure(record, at)
    Stats.EnsureTraits(record)
    record.conditionStats = Stats.NormalizeState(record.conditionStats, at)
    return record.conditionStats
end

function Stats.GetRates(record, activity)
    local needs = record.needs or {}
    local condition = record.conditionStats or {}
    local pressure = math.max(tonumber(needs.hunger) or 0,
        tonumber(needs.hydration) or 0, tonumber(needs.fatigue) or 0)
    local morale = tonumber(record.social and record.social.morale) or 0
    local stress = -0.02 + math.max(0, pressure - 0.35) * 0.10
        + math.max(0, -morale) / 100 * 0.04
    local boredom = activity == "idle" and 6
        or activity == "resting" and 4
        or activity == "sleeping" and 0
        or activity == "fighting" and -12 or -6
    local panic = activity == "fighting" and 18 or -12
    if Stats.HasTrait(record, Stats.TRAITS.IRON_NERVES) then
        stress = stress > 0 and stress * 0.75 or stress * 1.20
        panic = panic > 0 and panic * 0.50 or panic * 1.50
    elseif Stats.HasTrait(record, Stats.TRAITS.FRAYED_NERVES) then
        stress = stress > 0 and stress * 1.25 or stress * 0.75
        panic = panic > 0 and panic * 1.50 or panic * 0.70
    end
    if Stats.HasTrait(record, Stats.TRAITS.BUSY_HANDS) then
        boredom = boredom > 0 and boredom * 0.60 or boredom * 1.20
    elseif Stats.HasTrait(record, Stats.TRAITS.RESTLESS_SOUL) then
        boredom = boredom > 0 and boredom * 1.50 or boredom * 1.25
    end
    return { stress = stress, boredom = boredom, panic = panic }
end

function Stats.Update(record, elapsedHours, activity, at)
    local state = Stats.Ensure(record, at)
    local rates = Stats.GetRates(record, activity)
    elapsedHours = math.max(0, tonumber(elapsedHours) or 0)
    for index = 1, #Stats.TYPES do
        local id = Stats.TYPES[index]
        local definition = Stats.DEFINITIONS[id]
        state[id] = math.max(definition.minimum, math.min(definition.maximum,
            state[id] + rates[id] * elapsedHours))
    end
    state.lastUpdateWorldAge = math.max(0, tonumber(at) or 0)
    return state
end

return Stats
