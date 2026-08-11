PNC = PNC or {}
PNC.PlayerNeedsModel = PNC.PlayerNeedsModel or {}

local Model = PNC.PlayerNeedsModel
local Definitions = PNC.NeedsDefinitions

Model.GENERATION_VERSION = 1

Model.TRAITS = {
    HIGH_THIRST = "highthirst",
    LOW_THIRST = "lowthirst",
    HEARTY_APPETITE = "heartyappetite",
    LIGHT_EATER = "lighteater",
    NEEDS_LESS_SLEEP = "needslesssleep",
    NEEDS_MORE_SLEEP = "needsmoresleep",
    INSOMNIAC = "insomniac",
    NIGHT_OWL = "nightowl",
    OVERWEIGHT = "overweight",
    OBESE = "obese",
    UNDERWEIGHT = "underweight",
    VERY_UNDERWEIGHT = "veryunderweight",
    EMACIATED = "emaciated",
}

Model.TRAIT_DEFINITIONS = {
    { id = Model.TRAITS.HIGH_THIRST, labelKey = "UI_trait_HighThirst" },
    { id = Model.TRAITS.LOW_THIRST, labelKey = "UI_trait_LowThirst" },
    { id = Model.TRAITS.HEARTY_APPETITE,
        labelKey = "UI_trait_heartyappetite" },
    { id = Model.TRAITS.LIGHT_EATER, labelKey = "UI_trait_lighteater" },
    { id = Model.TRAITS.NEEDS_LESS_SLEEP, labelKey = "UI_trait_LessSleep" },
    { id = Model.TRAITS.NEEDS_MORE_SLEEP, labelKey = "UI_trait_MoreSleep" },
    { id = Model.TRAITS.INSOMNIAC, labelKey = "UI_trait_Insomniac" },
    { id = Model.TRAITS.NIGHT_OWL, labelKey = "UI_trait_nightowl" },
    { id = Model.TRAITS.OVERWEIGHT, labelKey = "UI_trait_overweight" },
    { id = Model.TRAITS.OBESE, labelKey = "UI_trait_obese" },
    { id = Model.TRAITS.UNDERWEIGHT, labelKey = "UI_trait_underweight" },
    { id = Model.TRAITS.VERY_UNDERWEIGHT,
        labelKey = "UI_trait_veryunderweight" },
    { id = Model.TRAITS.EMACIATED, labelKey = "UI_trait_emaciated" },
}

-- Vanilla does not define random-survivor frequencies for character-creation
-- traits. These neutral-heavy weights provide deterministic NPC variety while
-- preserving vanilla mutual exclusions and vanilla effect math.
Model.GENERATION_GROUPS = {
    { salt = "thirst", choices = {
        { id = false, weight = 70 },
        { id = Model.TRAITS.HIGH_THIRST, weight = 20 },
        { id = Model.TRAITS.LOW_THIRST, weight = 10 },
    } },
    { salt = "appetite", choices = {
        { id = false, weight = 72 },
        { id = Model.TRAITS.HEARTY_APPETITE, weight = 16 },
        { id = Model.TRAITS.LIGHT_EATER, weight = 12 },
    } },
    { salt = "sleep_need", choices = {
        { id = false, weight = 76 },
        { id = Model.TRAITS.NEEDS_LESS_SLEEP, weight = 10 },
        { id = Model.TRAITS.NEEDS_MORE_SLEEP, weight = 14 },
    } },
    { salt = "sleep_quality", choices = {
        { id = false, weight = 86 },
        { id = Model.TRAITS.INSOMNIAC, weight = 8 },
        { id = Model.TRAITS.NIGHT_OWL, weight = 6 },
    } },
    { salt = "body_weight", choices = {
        { id = false, weight = 61 },
        { id = Model.TRAITS.OVERWEIGHT, weight = 16 },
        { id = Model.TRAITS.OBESE, weight = 5 },
        { id = Model.TRAITS.UNDERWEIGHT, weight = 12 },
        { id = Model.TRAITS.VERY_UNDERWEIGHT, weight = 5 },
        { id = Model.TRAITS.EMACIATED, weight = 1 },
    } },
}

local function traitID(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "^base[%.:]", "")
    value = string.gsub(value, "[^%w]", "")
    return value
end

function Model.NormalizeTraits(source)
    local output = {}
    for key, value in pairs(type(source) == "table" and source or {}) do
        local id = type(key) == "number" and traitID(value) or traitID(key)
        local enabled = type(key) == "number" or value == true
        if id ~= "" and enabled then output[id] = true end
    end
    return output
end

local function weightedChoice(seed, salt, choices)
    local total = 0
    local index
    for index = 1, #choices do
        total = total + math.max(0, tonumber(choices[index].weight) or 0)
    end
    if total <= 0 then return nil end
    local roll
    if PNC.Identity and PNC.Identity.Float then
        roll = PNC.Identity.Float(seed, salt) * total
    elseif PNC.Identity and PNC.Identity.MixSeed then
        roll = (PNC.Identity.MixSeed(seed, salt) % 100000) / 100000 * total
    else
        roll = 0
    end
    local cursor = 0
    for index = 1, #choices do
        cursor = cursor + math.max(0, tonumber(choices[index].weight) or 0)
        if roll < cursor then return choices[index].id end
    end
    return choices[#choices].id
end

function Model.GenerateTraits(identitySeed, archetypeID)
    local seed = PNC.Identity and PNC.Identity.NormalizeSeed
        and PNC.Identity.NormalizeSeed(identitySeed, archetypeID)
        or math.max(1, math.floor(tonumber(identitySeed) or 1))
    local prefix = "npc_vanilla_traits:v"
        .. tostring(Model.GENERATION_VERSION) .. ":"
        .. tostring(archetypeID or "General") .. ":"
    local output = {}
    local index
    for index = 1, #Model.GENERATION_GROUPS do
        local group = Model.GENERATION_GROUPS[index]
        local selected = weightedChoice(
            seed, prefix .. tostring(group.salt), group.choices
        )
        if selected then output[selected] = true end
    end
    -- These exclusions are present in Build 42's generated trait catalog.
    if output[Model.TRAITS.VERY_UNDERWEIGHT] then
        output[Model.TRAITS.HEARTY_APPETITE] = nil
    end
    if output[Model.TRAITS.OBESE] then
        output[Model.TRAITS.LIGHT_EATER] = nil
    end
    return output
end

function Model.ResolveInitialTraits(source, identitySeed, archetypeID, authored)
    if authored == true then
        return Model.NormalizeTraits(source), true, 0
    end
    return Model.GenerateTraits(identitySeed, archetypeID), false,
        Model.GENERATION_VERSION
end

function Model.GetTraitDefinitions()
    local output = {}
    local index
    for index = 1, #Model.TRAIT_DEFINITIONS do
        local definition = Model.TRAIT_DEFINITIONS[index]
        output[index] = { id = definition.id, labelKey = definition.labelKey }
    end
    return output
end

function Model.GetActiveTraitIDs(source)
    local traits = source and source.vanillaTraits or source
    traits = Model.NormalizeTraits(traits)
    local output = {}
    local index
    for index = 1, #Model.TRAIT_DEFINITIONS do
        local id = Model.TRAIT_DEFINITIONS[index].id
        if traits[id] then output[#output + 1] = id end
    end
    return output
end

function Model.GetTraitLabelKey(id)
    id = traitID(id)
    local index
    for index = 1, #Model.TRAIT_DEFINITIONS do
        local definition = Model.TRAIT_DEFINITIONS[index]
        if definition.id == id then return definition.labelKey end
    end
    return nil
end

function Model.GetTraits(record)
    return Model.NormalizeTraits(record and (
        record.vanillaTraits or record.physiologicalTraits or record.traits
    ))
end

function Model.SetTraits(record, source)
    if type(record) ~= "table" then return false, "npc_missing" end
    record.vanillaTraits = Model.NormalizeTraits(source)
    record.vanillaTraitsAuthored = true
    record.vanillaTraitsGenerationVersion = 0
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "vanilla_traits_changed")
    end
    return true, "updated", Model.NormalizeTraits(record.vanillaTraits)
end

function Model.EnsureTraits(record)
    if type(record) ~= "table" then return nil, false end
    local generatedVersion = math.max(0, math.floor(
        tonumber(record.vanillaTraitsGenerationVersion) or 0
    ))
    if record.vanillaTraitsAuthored == true or generatedVersion > 0 then
        record.vanillaTraits = Model.NormalizeTraits(record.vanillaTraits)
        return record.vanillaTraits, false
    end
    local existing = Model.NormalizeTraits(record.vanillaTraits)
    local hasExisting = false
    for _, enabled in pairs(existing) do
        if enabled == true then hasExisting = true break end
    end
    if hasExisting then
        record.vanillaTraits = existing
        record.vanillaTraitsAuthored = true
        record.vanillaTraitsGenerationVersion = 0
    else
        record.vanillaTraits = Model.GenerateTraits(
            record.identitySeed, record.archetypeID
        )
        record.vanillaTraitsAuthored = false
        record.vanillaTraitsGenerationVersion = Model.GENERATION_VERSION
    end
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "vanilla_traits_initialized")
    end
    return record.vanillaTraits, true
end

function Model.HasTrait(record, id)
    id = traitID(id)
    local traits = Model.GetTraits(record)
    return traits[id] == true
end

function Model.AppetiteMultiplier(record, hunger)
    local value = math.max(0, 1 - (tonumber(hunger) or 0))
    if Model.HasTrait(record, Model.TRAITS.HEARTY_APPETITE) then
        value = value * 1.5
    end
    if Model.HasTrait(record, Model.TRAITS.LIGHT_EATER) then
        value = value * 0.75
    end
    return value
end

function Model.ThirstMultiplier(record)
    local value = 1
    if Model.HasTrait(record, Model.TRAITS.HIGH_THIRST) then value = value * 2 end
    if Model.HasTrait(record, Model.TRAITS.LOW_THIRST) then value = value * 0.5 end
    return value
end

function Model.FatigueGainMultiplier(record)
    if Model.HasTrait(record, Model.TRAITS.NEEDS_LESS_SLEEP) then return 0.7 end
    if Model.HasTrait(record, Model.TRAITS.NEEDS_MORE_SLEEP) then return 1.3 end
    return 1
end

function Model.SleepRecoveryMultiplier(record)
    local value = 1
    if Model.HasTrait(record, Model.TRAITS.INSOMNIAC) then value = value * 0.5 end
    if Model.HasTrait(record, Model.TRAITS.NIGHT_OWL) then value = value * 1.4 end
    if Model.HasTrait(record, Model.TRAITS.NEEDS_LESS_SLEEP) then
        value = value / 0.75
    elseif Model.HasTrait(record, Model.TRAITS.NEEDS_MORE_SLEEP) then
        value = value / 1.18
    end
    return value
end

local function fatigueActivity(activity)
    if activity == "resting" then return 1 / 1.5 end
    if activity == "walking" then return 1.05 end
    if activity == "working" or activity == "traveling" then return 1.25 end
    if activity == "running" then return 1.6 end
    if activity == "fighting" then return 1.85 end
    return 1
end

function Model.GetRates(record, state, activity)
    state = type(state) == "table" and state or {}
    activity = tostring(activity or "idle")
    local base = Definitions.VANILLA_RATES_PER_HOUR
    local hungerBase = activity == "sleeping" and base.hungerSleeping
        or activity == "running" and base.hungerRunning
        or activity == "fighting" and base.hungerFighting
        or base.hunger
    local hunger = hungerBase * Model.AppetiteMultiplier(record, state.hunger)
    local hydration = base.hydration * Model.ThirstMultiplier(record)
    if activity == "running" then hydration = hydration * 1.2 end
    local fatigue
    if activity == "sleeping" then
        local high = (tonumber(state.fatigue) or 0) > 0.3
        fatigue = -(high and 0.0875 or 0.0268)
            * Model.SleepRecoveryMultiplier(record)
    else
        fatigue = base.fatigue * Model.FatigueGainMultiplier(record)
            * fatigueActivity(activity)
    end
    if PNC.ConditionStats and PNC.ConditionStats.GetNeedRateMultiplier then
        hunger = hunger * PNC.ConditionStats.GetNeedRateMultiplier(
            record, "hunger", state, activity)
        hydration = hydration * PNC.ConditionStats.GetNeedRateMultiplier(
            record, "hydration", state, activity)
        fatigue = fatigue * PNC.ConditionStats.GetNeedRateMultiplier(
            record, "fatigue", state, activity)
    end
    return { hunger = hunger, hydration = hydration, fatigue = fatigue }
end

return Model
