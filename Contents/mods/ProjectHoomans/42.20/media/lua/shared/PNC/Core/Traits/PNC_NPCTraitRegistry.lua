-- Data-only NPC trait registry. Player CharacterTrait definitions must not
-- leak into this catalog: NPC traits are owned by Project Hoomans and may
-- affect simulation, behavior, personality, and presentation together.

PNC = PNC or {}
PNC.NPCTraits = PNC.NPCTraits or {}

local Traits = PNC.NPCTraits

Traits.VERSION = 1
Traits.Definitions = Traits.Definitions or {}
Traits.Ordered = Traits.Ordered or {}
Traits.Aliases = Traits.Aliases or {}
Traits.Revision = tonumber(Traits.Revision) or 0
Traits.GenerationGroups = Traits.GenerationGroups or {}
Traits.GenerationGroupOrder = Traits.GenerationGroupOrder or {}
Traits.GenerationRevision = tonumber(Traits.GenerationRevision) or 0

local function copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local output = {}
    seen[value] = output
    for key, item in pairs(value) do
        output[copy(key, seen)] = copy(item, seen)
    end
    return output
end

local function normalize(value)
    if type(value) ~= "string" then return nil end
    value = string.lower(value)
    if value == "" or string.find(value, "%s") then return nil end
    return value
end

local function validFiniteNumber(value)
    local numeric = tonumber(value)
    return numeric ~= nil
        and numeric == numeric
        and numeric ~= math.huge
        and numeric ~= -math.huge
end

-- Generation groups are registry data rather than generator code. A mod can
-- register a new slot once, then add traits to it through the normal trait
-- registration API without editing the core generator.
function Traits.RegisterGenerationGroup(definition, options)
    local id
    local existing
    local noneWeight
    local priority
    local spec
    options = type(options) == "table" and options or {}
    if type(definition) ~= "table" then
        return false, "invalid_generation_group"
    end
    id = normalize(definition.id)
    if not id then return false, "invalid_generation_group_id" end
    noneWeight = tonumber(definition.noneWeight)
    if not validFiniteNumber(noneWeight) or noneWeight < 0 then
        return false, "invalid_generation_none_weight:" .. id
    end
    priority = tonumber(definition.priority) or 100
    if not validFiniteNumber(priority) then
        return false, "invalid_generation_priority:" .. id
    end
    existing = Traits.GenerationGroups[id]
    if existing and options.override ~= true then
        return false, "duplicate_generation_group:" .. id
    end
    spec = copy(definition)
    spec.id = id
    spec.noneWeight = noneWeight
    spec.priority = priority
    if not existing then
        Traits.GenerationGroupOrder[#Traits.GenerationGroupOrder + 1] = id
    end
    Traits.GenerationGroups[id] = spec
    Traits.GenerationRevision = Traits.GenerationRevision + 1
    return true, id
end

function Traits.GetGenerationGroups()
    local output = {}
    local seen = {}
    local index
    local id
    local specification
    for index = 1, #Traits.GenerationGroupOrder do
        id = Traits.GenerationGroupOrder[index]
        specification = Traits.GenerationGroups[id]
        if specification and not seen[id] then
            output[#output + 1] = copy(specification)
            seen[id] = true
        end
    end
    table.sort(output, function(left, right)
        local leftPriority = tonumber(left.priority) or 100
        local rightPriority = tonumber(right.priority) or 100
        if leftPriority ~= rightPriority then
            return leftPriority < rightPriority
        end
        return left.id < right.id
    end)
    return output
end

local CORE_GENERATION_GROUPS = {
    { id = "nerves", noneWeight = 68, priority = 10 },
    { id = "tempo", noneWeight = 65, priority = 20 },
    { id = "constitution", noneWeight = 68, priority = 30 },
    { id = "fatigue", noneWeight = 72, priority = 40 },
    { id = "combat_style", noneWeight = 55, priority = 50 },
    { id = "combat_temperament", noneWeight = 65, priority = 60 },
}

local function ensureCoreGenerationGroups()
    local index
    local specification
    for index = 1, #CORE_GENERATION_GROUPS do
        specification = CORE_GENERATION_GROUPS[index]
        if not Traits.GenerationGroups[specification.id] then
            Traits.RegisterGenerationGroup(specification)
        end
    end
end

ensureCoreGenerationGroups()

local function validateGeneration(definition, id)
    local generation = definition and definition.generation
    local group
    local weight
    if generation == nil then return true end
    if type(generation) ~= "table" then
        return false, "invalid_generation:" .. id
    end
    group = normalize(generation.group)
    if not group then
        return false, "generation_group_required:" .. id
    end
    if not Traits.GenerationGroups[group] then
        return false, "unknown_generation_group:" .. group .. ":" .. id
    end
    weight = tonumber(generation.weight)
    if not validFiniteNumber(weight) or weight < 0 then
        return false, "invalid_generation_weight:" .. id
    end
    return true
end

local function validateCombatEffects(effects, id)
    local combat = type(effects) == "table" and effects.combat or nil
    local firearm
    local melee
    local key
    local value
    if combat ~= nil and type(combat) ~= "table" then
        return false, "invalid_combat_channel:" .. id
    end
    firearm = combat and combat.firearm or nil
    if firearm ~= nil then
        if type(firearm) ~= "table" then
            return false, "invalid_combat_firearm:" .. id
        end
        for _, key in ipairs({
            "fireRateMultiplier",
            "aimTimeMultiplier",
            "hitChanceBias",
            "pressureAccuracyBias",
            "confidenceThresholdBias",
        }) do
            value = firearm[key]
            if value ~= nil and not validFiniteNumber(value) then
                return false, "invalid_combat_firearm_" .. key .. ":" .. id
            end
        end
    end
    melee = combat and combat.melee or nil
    if melee == nil then return true end
    if type(melee) ~= "table" then
        return false, "invalid_combat_melee:" .. id
    end
    for _, key in ipairs({
        "attackRateMultiplier",
        "windupTimeMultiplier",
        "hitChanceBias",
        "pressureAccuracyBias",
    }) do
        value = melee[key]
        if value ~= nil and not validFiniteNumber(value) then
            return false, "invalid_combat_melee_" .. key .. ":" .. id
        end
    end
    return true
end

local function addAlias(value, id)
    value = normalize(value)
    if value then Traits.Aliases[value] = id end
end

local function addSource(output, source)
    local key
    local value
    local candidate
    local id
    if type(source) ~= "table" then return end
    for key, value in pairs(source) do
        candidate = type(key) == "number" and value
            or value == true and key or nil
        id = candidate and normalize(candidate) or nil
        id = id and Traits.Aliases[id] or nil
        if id then output[id] = true end
    end
end

local function conflicts(left, right)
    local leftDefinition = Traits.Definitions[left]
    local rightDefinition = Traits.Definitions[right]
    local index
    if not leftDefinition or not rightDefinition then return false end
    for index = 1, #(leftDefinition.excludes or {}) do
        if leftDefinition.excludes[index] == right then return true end
    end
    for index = 1, #(rightDefinition.excludes or {}) do
        if rightDefinition.excludes[index] == left then return true end
    end
    return false
end

local function shouldReplace(candidate, current)
    local candidateDefinition = Traits.Definitions[candidate] or {}
    local currentDefinition = Traits.Definitions[current] or {}
    local candidatePriority = tonumber(candidateDefinition.priority) or 0
    local currentPriority = tonumber(currentDefinition.priority) or 0
    if candidatePriority ~= currentPriority then
        return candidatePriority > currentPriority
    end
    return candidate < current
end

function Traits.NormalizeID(value)
    local id = normalize(value)
    return id and (Traits.Aliases[id] or Traits.Definitions[id] and id) or nil
end

function Traits.Register(definition, options)
    local id
    local spec
    local alias
    local index
    local existing
    local combatValid
    local combatReason
    local generationValid
    local generationReason
    options = type(options) == "table" and options or {}
    if type(definition) ~= "table" then return false, "invalid_definition" end
    id = normalize(definition.id)
    if not id then return false, "invalid_id" end
    if type(definition.labelKey) ~= "string"
        or definition.labelKey == ""
    then
        return false, "label_key_required" .. ":" .. id
    end
    combatValid, combatReason = validateCombatEffects(definition.effects, id)
    if not combatValid then return false, combatReason end
    generationValid, generationReason = validateGeneration(definition, id)
    if not generationValid then return false, generationReason end
    existing = Traits.Definitions[id]
    if existing and options.override ~= true then
        return false, "duplicate_id:" .. id
    end
    spec = copy(definition)
    spec.id = id
    spec.descriptionKey = type(spec.descriptionKey) == "string"
        and spec.descriptionKey or spec.labelKey
    spec.source = type(spec.source) == "string" and spec.source or "npc"
    spec.priority = tonumber(spec.priority) or 0
    spec.effects = type(spec.effects) == "table" and spec.effects or {}
    spec.tags = type(spec.tags) == "table" and spec.tags or {}
    spec.excludes = type(spec.excludes) == "table" and spec.excludes or {}
    spec.generation = type(spec.generation) == "table"
        and spec.generation or nil
    if spec.generation then
        spec.generation.group = normalize(spec.generation.group)
        spec.generation.weight = tonumber(spec.generation.weight)
    end
    if not existing then Traits.Ordered[#Traits.Ordered + 1] = id end
    Traits.Definitions[id] = spec
    addAlias(id, id)
    if type(spec.aliases) == "table" then
        for index = 1, #spec.aliases do
            alias = normalize(spec.aliases[index])
            if alias then addAlias(alias, id) end
        end
    end
    Traits.Revision = Traits.Revision + 1
    return true, id
end

function Traits.GetDefinition(value)
    local id = Traits.NormalizeID(value)
    return id and copy(Traits.Definitions[id]) or nil
end

function Traits.GetDefinitions()
    local output = {}
    local index
    for index = 1, #Traits.Ordered do
        output[index] = copy(Traits.Definitions[Traits.Ordered[index]])
    end
    return output
end

function Traits.NormalizeSet(source)
    local output = {}
    addSource(output, source)
    return output
end

function Traits.ResolveSet(source)
    local selected = Traits.NormalizeSet(source)
    local output = {}
    local conflictsFound = {}
    local index
    local candidate
    local current
    local keepCandidate
    for index = 1, #Traits.Ordered do
        candidate = Traits.Ordered[index]
        if selected[candidate] then
            keepCandidate = true
            for current, _ in pairs(output) do
                if conflicts(candidate, current) then
                    if shouldReplace(candidate, current) then
                        output[current] = nil
                        conflictsFound[#conflictsFound + 1] = {
                            preferred = candidate, discarded = current,
                        }
                    else
                        keepCandidate = false
                        conflictsFound[#conflictsFound + 1] = {
                            preferred = current, discarded = candidate,
                        }
                        break
                    end
                end
            end
            if keepCandidate then output[candidate] = true end
        end
    end
    return output, conflictsFound
end

function Traits.Fingerprint(source)
    local selected = Traits.ResolveSet(source)
    local ids = {}
    local index
    for index = 1, #Traits.Ordered do
        if selected[Traits.Ordered[index]] then
            ids[#ids + 1] = Traits.Ordered[index]
        end
    end
    return table.concat(ids, "|")
end

function Traits.Collect(record)
    local output = {}
    if type(record) ~= "table" then return output end
    addSource(output, record.npcTraits)
    addSource(output, record.dynamicTraits)
    return Traits.ResolveSet(output)
end

function Traits.GetActiveTraitIDs(record)
    local selected = Traits.Collect(record)
    local output = {}
    local index
    for index = 1, #Traits.Ordered do
        if selected[Traits.Ordered[index]] then
            output[#output + 1] = Traits.Ordered[index]
        end
    end
    return output
end

function Traits.Set(record, source)
    local selected
    local conflictsFound
    if type(record) ~= "table" then return false, "npc_missing" end
    selected, conflictsFound = Traits.ResolveSet(source)
    record.npcTraits = selected
    record.npcTraitFingerprint = Traits.Fingerprint(selected)
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "npc_traits_changed")
    end
    return true, selected, conflictsFound
end

return Traits
