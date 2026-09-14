-- Player-like secondary NPC stats plus Project Hoomans trait dynamics.
PNC = PNC or {}
PNC.ConditionStats = PNC.ConditionStats or {}

local Stats = PNC.ConditionStats
local TraitEffects = PNC.NPCTraitEffects
local NPCTraits = PNC.NPCTraits

local function ensureCurrentTraits(record)
    local currentVersion
    local version
    if type(record) ~= "table" or record.dynamicTraits == nil
        or record.dynamicTraitsAuthored == true
        or not Stats.EnsureTraits
    then
        return
    end
    currentVersion = math.max(1, math.floor(
        tonumber(Stats.TRAIT_GENERATION_VERSION) or 1
    ))
    version = math.max(0, math.floor(
        tonumber(record.dynamicTraitsGenerationVersion) or 0
    ))
    if version ~= currentVersion then
        Stats.EnsureTraits(record)
    end
end

Stats.VERSION = 1
-- Bump when the seed-derived dynamic trait catalog or rules change.
Stats.TRAIT_GENERATION_VERSION = 2
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

local function traitID(value)
    if NPCTraits and NPCTraits.NormalizeID then
        return NPCTraits.NormalizeID(value) or ""
    end
    return string.lower(tostring(value or ""))
end

local function updateTraitFingerprint(record)
    if type(record) == "table"
        and NPCTraits and NPCTraits.Fingerprint
    then
        record.dynamicTraitFingerprint = NPCTraits.Fingerprint(
            record.dynamicTraits or {})
    end
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

local function generationGroups()
    local output = {}
    local definitions = NPCTraits and NPCTraits.GetDefinitions
        and NPCTraits.GetDefinitions() or {}
    local specifications = NPCTraits and NPCTraits.GetGenerationGroups
        and NPCTraits.GetGenerationGroups() or {}
    for index = 1, #specifications do
        local specification = specifications[index]
        local candidates = {}
        local group = {
            salt = specification.id,
            choices = { { false, specification.noneWeight } },
        }
        for definitionIndex = 1, #definitions do
            local definition = definitions[definitionIndex]
            local generation = definition and definition.generation
            if type(generation) == "table"
                and generation.group == specification.id
            then
                candidates[#candidates + 1] = {
                    definition.id, tonumber(generation.weight) or 0,
                }
            end
        end
        table.sort(candidates, function(left, right)
            return left[1] < right[1]
        end)
        for candidateIndex = 1, #candidates do
            group.choices[#group.choices + 1] = candidates[candidateIndex]
        end
        output[#output + 1] = group
    end
    return output
end

local function choice(seed, salt, values)
    local totalWeight = 0
    local roll
    for index = 1, #values do
        totalWeight = totalWeight + (tonumber(values[index][2]) or 0)
    end
    if totalWeight <= 0 then return false end
    roll = PNC.Identity and PNC.Identity.Float
        and PNC.Identity.Float(seed, salt) * totalWeight or 0
    local cursor = 0
    for index = 1, #values do
        cursor = cursor + (tonumber(values[index][2]) or 0)
        if roll < cursor then return values[index][1] end
    end
    return values[#values][1] or false
end

function Stats.GenerateTraits(identitySeed, archetypeID)
    local seed = PNC.Identity and PNC.Identity.NormalizeSeed
        and PNC.Identity.NormalizeSeed(identitySeed, archetypeID)
        or math.max(1, math.floor(tonumber(identitySeed) or 1))
    local output = {}
    local groups = generationGroups()
    for index = 1, #groups do
        local group = groups[index]
        local selected = choice(seed, "npc_dynamic_traits:v"
            .. tostring(Stats.TRAIT_GENERATION_VERSION) .. ":"
            .. tostring(archetypeID or "General") .. ":" .. group.salt,
            group.choices)
        if selected then output[selected] = true end
    end
    if NPCTraits and NPCTraits.ResolveSet then
        return NPCTraits.ResolveSet(output)
    end
    return output
end

function Stats.ResolveInitialTraits(source, seed, archetypeID, authored)
    if authored == true then return Stats.NormalizeTraits(source), true, 0 end
    return Stats.GenerateTraits(seed, archetypeID), false,
        Stats.TRAIT_GENERATION_VERSION
end

function Stats.HasTrait(record, id)
    ensureCurrentTraits(record)
    return Stats.NormalizeTraits(record and record.dynamicTraits)[traitID(id)]
        == true
end

function Stats.SetTraits(record, source)
    if type(record) ~= "table" then return false, "npc_missing" end
    record.dynamicTraits = Stats.NormalizeTraits(source)
    updateTraitFingerprint(record)
    record.dynamicTraitsAuthored = true
    record.dynamicTraitsGenerationVersion = 0
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "dynamic_traits_changed")
    end
    return true, "updated", Stats.NormalizeTraits(record.dynamicTraits)
end

function Stats.EnsureTraits(record)
    if type(record) ~= "table" then return nil, false end
    local currentVersion = math.max(1, math.floor(
        tonumber(Stats.TRAIT_GENERATION_VERSION) or 1
    ))
    local version = math.max(0, math.floor(
        tonumber(record.dynamicTraitsGenerationVersion) or 0))
    if record.dynamicTraitsAuthored == true then
        record.dynamicTraits = Stats.NormalizeTraits(record.dynamicTraits)
        updateTraitFingerprint(record)
        record.dynamicTraitsGenerationVersion = 0
        return record.dynamicTraits, false
    end
    if version == currentVersion then
        record.dynamicTraits = Stats.NormalizeTraits(record.dynamicTraits)
        updateTraitFingerprint(record)
        return record.dynamicTraits, false
    end
    local existing = Stats.NormalizeTraits(record.dynamicTraits)
    local hasExisting = false
    for _, enabled in pairs(existing) do
        if enabled == true then hasExisting = true break end
    end
    if version == 0 and hasExisting then
        record.dynamicTraits = existing
        record.dynamicTraitsAuthored = true
        record.dynamicTraitsGenerationVersion = 0
    else
        record.dynamicTraits = Stats.GenerateTraits(
            record.identitySeed, record.archetypeID)
        record.dynamicTraitsAuthored = false
        record.dynamicTraitsGenerationVersion = currentVersion
    end
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, version == 0 and hasExisting
            and "dynamic_traits_initialized"
            or "dynamic_traits_regenerated")
    end
    updateTraitFingerprint(record)
    return record.dynamicTraits, true
end

function Stats.GetActiveTraitIDs(source)
    ensureCurrentTraits(source)
    local traits = Stats.NormalizeTraits(source and source.dynamicTraits or source)
    local output = {}
    local definitions = NPCTraits and NPCTraits.GetDefinitions
        and NPCTraits.GetDefinitions() or {}
    for index = 1, #definitions do
        local id = definitions[index].id
        if traits[id] then
            output[#output + 1] = id
        end
    end
    return output
end

function Stats.GetTraitLabelKey(id)
    id = traitID(id)
    local definition = NPCTraits and NPCTraits.GetDefinition
        and NPCTraits.GetDefinition(id)
    return definition and definition.labelKey or nil
end

function Stats.GetNeedRateMultiplier(record, needType, state, activity)
    if TraitEffects and TraitEffects.GetNeedRateMultiplier then
        return TraitEffects.GetNeedRateMultiplier(
            record, needType, state, activity)
    end
    return 1
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
    local repositoryState = PNC.NeedsRepository
        and PNC.NeedsRepository.Get(record, false) or nil
    local needs = repositoryState and repositoryState.needs or {}
    local condition = record.conditionStats or {}
    local pressure = math.max(tonumber(needs.hunger) or 0,
        tonumber(needs.thirst) or 0, tonumber(needs.fatigue) or 0)
    local morale = tonumber(record.social and record.social.morale) or 0
    local stress = -0.02 + math.max(0, pressure - 0.35) * 0.10
        + math.max(0, -morale) / 100 * 0.04
    local boredom = activity == "idle" and 6
        or activity == "resting" and 4
        or activity == "sleeping" and 0
        or activity == "fighting" and -12 or -6
    local panic = activity == "fighting" and 18 or -12
    if TraitEffects and TraitEffects.GetConditionRateMultiplier then
        stress = stress * TraitEffects.GetConditionRateMultiplier(
            record, "stress", stress)
        boredom = boredom * TraitEffects.GetConditionRateMultiplier(
            record, "boredom", boredom)
        panic = panic * TraitEffects.GetConditionRateMultiplier(
            record, "panic", panic)
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
