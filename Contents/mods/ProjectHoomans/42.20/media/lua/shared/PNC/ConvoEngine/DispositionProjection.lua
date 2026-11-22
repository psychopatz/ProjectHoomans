-- Unified deterministic disposition and affect projection for ConvoEngine.
-- Read-only: never mutates actor.social.personality, traits, or persistent storage.
-- Pure Kahlua2-safe Lua 5.1 (no protected calls, zero per-tick loops).
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Projection = PNC.ConvoEngine.DispositionProjection or {}
PNC.ConvoEngine.DispositionProjection = Projection

Projection.VERSION = 1

Projection.DIMENSIONS = {
    "bravery",
    "confidence",
    "aggression",
    "compassion",
    "sociability",
    "forgiveness",
    "materialism",
    "loyalty",
}

Projection.DEMEANOR_AXES = {
    "moraleHope",
    "scarcityAnxiety",
    "vigilanceFear",
    "hostilityIrritability",
    "griefStress",
    "confidencePressure",
}

Projection.STYLES = {
    "brave",
    "aggressive",
    "shaken",
    "supportive",
    "cold",
    "reserved",
    "practical",
    "default",
}

-- Used ONLY when an actor has no resolved numeric personality at all
-- (e.g. player or bare test stub). Never applied on top of social.personality.
local FALLBACK_TRAIT_DELTAS = {
    Brave = { bravery = 22, confidence = 22 },
    Desensitized = { bravery = 24, confidence = 24, compassion = -6 },
    Cowardly = { bravery = -22, confidence = -22 },
    Pacifist = { compassion = 18, forgiveness = 12, aggression = -16 },
    Kind = { compassion = 22, forgiveness = 12, sociability = 8 },
    KindHearted = { compassion = 22, forgiveness = 14, sociability = 8 },
    Empathetic = { compassion = 24, forgiveness = 10, sociability = 6 },
    Friendly = { sociability = 18, compassion = 10, forgiveness = 8 },
    Aggressive = { aggression = 24, bravery = 8, confidence = 8, compassion = -10 },
    Cold = { compassion = -18, sociability = -16, forgiveness = -12 },
    Reserved = { sociability = -20 },
    Withdrawn = { sociability = -22, confidence = -6 },
    Loyal = { loyalty = 22 },
    Greedy = { materialism = 22, compassion = -8 },
    Generous = { compassion = 14, materialism = -18 },
    pnc_brave = { bravery = 20, confidence = 20 },
    pnc_veteran = { bravery = 22, confidence = 22, aggression = 4 },
    pnc_ironnerves = { bravery = 20, confidence = 20 },
    pnc_disciplined_fighter = { bravery = 16, confidence = 16 },
    pnc_cowardly = { bravery = -22, confidence = -22 },
    pnc_nervous_fighter = { bravery = -18, confidence = -18 },
    pnc_frayednerves = { bravery = -18, confidence = -18 },
    pnc_berserker = { aggression = 26, bravery = 14, confidence = 10, compassion = -10 },
    pnc_reckless = { aggression = 16, bravery = 10, confidence = 8 },
    pnc_trigger_happy = { aggression = 18, bravery = 8 },
    pnc_brawler = { aggression = 16, bravery = 8 },
    pnc_peacemaker = { compassion = 20, forgiveness = 14, aggression = -12 },
    pnc_friendly = { sociability = 18, compassion = 12, forgiveness = 8 },
    pnc_reserved = { sociability = -20 },
    pnc_withdrawn = { sociability = -22 },
    PNC_Friendly = { sociability = 18, compassion = 10, forgiveness = 8 },
    PNC_Reserved = { sociability = -20 },
    PNC_Withdrawn = { sociability = -22, forgiveness = -4 },
}

local SOURCE_ALIASES = {
    "bravery", "confidence", "aggression", "compassion",
    "sociability", "forgiveness", "materialism", "loyalty",
    "empathy", "riskTolerance",
}

local SEED_MOD = 2147483646

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil
        or value ~= value
        or value == math.huge
        or value == -math.huge
    then
        return fallback
    end
    return value
end

local function clamp(value, minimum, maximum)
    value = finite(value, minimum)
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function round2(value)
    return math.floor(value * 100 + 0.5) / 100
end

local function hashText(text, seed)
    local value = math.floor(finite(seed, 5381) or 5381)
    if value <= 0 then value = 5381 end
    value = value % SEED_MOD
    if value <= 0 then value = 1 end
    local source = tostring(text or "")
    for index = 1, #source do
        value = ((value * 33) + string.byte(source, index)) % SEED_MOD
    end
    if value <= 0 then value = 1 end
    return value
end

local function seedFloat(seed, salt)
    local base = math.floor(finite(seed, 0) or 0)
    if base <= 0 then
        base = hashText(tostring(seed or "pnc_seed"), 5381)
    else
        base = base % SEED_MOD
        if base <= 0 then base = 1 end
    end
    return hashText(tostring(salt or "seed"), base) / SEED_MOD
end

local function hasNumericSource(tbl)
    if type(tbl) ~= "table" then return false end
    for index = 1, #SOURCE_ALIASES do
        if finite(tbl[SOURCE_ALIASES[index]], nil) ~= nil then
            return true
        end
    end
    return false
end

local function isScale100(tbl)
    if type(tbl) ~= "table" then return false end
    if tbl.scale == 100 then return true end
    for index = 1, #SOURCE_ALIASES do
        local v = finite(tbl[SOURCE_ALIASES[index]], nil)
        if v ~= nil and (v > 1 or v < 0) then
            return true
        end
    end
    return false
end

local function toScale100(value, scale100, fallback)
    local v = finite(value, nil)
    if v == nil then return fallback end
    if not scale100 then v = v * 100 end
    return clamp(v, 0, 100)
end

local function unitFromAny(value, fallback)
    local v = finite(value, fallback)
    if v == nil then return 0 end
    if v > 1 then v = v / 100 end
    return clamp(v, 0, 1)
end

local function pickNumericSource(actor, opts)
    if type(opts) == "table" then
        if hasNumericSource(opts.baseDisposition) then
            return opts.baseDisposition
        end
        if hasNumericSource(opts.personality) then
            return opts.personality
        end
        if hasNumericSource(opts.disposition) then
            return opts.disposition
        end
    end
    if type(actor) ~= "table" then return nil end
    if hasNumericSource(actor.baseDisposition) then
        return actor.baseDisposition
    end
    if hasNumericSource(actor.personality) then
        return actor.personality
    end
    if type(actor.socialProfile) == "table" then
        if hasNumericSource(actor.socialProfile.personality) then
            return actor.socialProfile.personality
        end
        if hasNumericSource(actor.socialProfile) then
            return actor.socialProfile
        end
    end
    if type(actor.social) == "table" and hasNumericSource(actor.social.personality) then
        return actor.social.personality
    end
    if hasNumericSource(actor.disposition) then
        return actor.disposition
    end
    return nil
end

local function collectTraitMap(actor, opts)
    local collected = {}
    local function addFrom(source)
        if type(source) ~= "table" then return end
        for key, value in pairs(source) do
            if type(key) == "string" and value == true then
                collected[key] = true
            elseif type(value) == "string" and value ~= "" then
                collected[value] = true
            elseif type(value) == "table" then
                local id = value.id or value.type or value.name
                if type(id) == "string" and id ~= "" then
                    collected[id] = true
                end
            end
        end
    end
    if type(opts) == "table" then
        addFrom(opts.traits)
        addFrom(opts.playerTraits)
    end
    if type(actor) == "table" then
        addFrom(actor.npcTraits)
        addFrom(actor.dynamicTraits)
        addFrom(actor.traits)
        addFrom(actor.playerTraits)
    end
    return collected
end

local function deriveBaselineFromContext(actor, opts)
    local base = {}
    local seed = (type(opts) == "table" and (opts.identitySeed or opts.seed))
        or (type(actor) == "table" and (actor.identitySeed or actor.seed))
        or nil
    for index = 1, #Projection.DIMENSIONS do
        local dim = Projection.DIMENSIONS[index]
        if seed ~= nil and seed ~= "" then
            base[dim] = 30 + seedFloat(seed, "disp_base:" .. dim) * 40
        else
            base[dim] = 50
        end
    end
    if seed ~= nil and seed ~= "" then
        base.confidence = base.bravery
    end

    local traitMap = collectTraitMap(actor, opts)
    local traitIDs = {}
    for traitID, enabled in pairs(traitMap) do
        if enabled == true then
            traitIDs[#traitIDs + 1] = traitID
        end
    end
    table.sort(traitIDs)

    local applied = {}
    local registry = PNC and PNC.NPCTraits or nil
    local getDef = type(registry) == "table"
        and type(registry.GetDefinition) == "function"
        and registry.GetDefinition or nil

    for index = 1, #traitIDs do
        local traitID = traitIDs[index]
        local def = getDef and getDef(traitID) or nil
        local personalityEffects = type(def) == "table"
            and type(def.effects) == "table"
            and type(def.effects.personality) == "table"
            and def.effects.personality or nil
        local touched = false
        if personalityEffects then
            for dim, delta in pairs(personalityEffects) do
                if base[dim] ~= nil then
                    local num = finite(delta, 0) or 0
                    if math.abs(num) <= 1 then num = num * 100 end
                    base[dim] = base[dim] + num
                    touched = true
                end
            end
            if finite(personalityEffects.bravery, nil) ~= nil
                and finite(personalityEffects.confidence, nil) == nil
            then
                local num = finite(personalityEffects.bravery, 0) or 0
                if math.abs(num) <= 1 then num = num * 100 end
                base.confidence = base.confidence + num
            end
        else
            local fallbackDeltas = FALLBACK_TRAIT_DELTAS[traitID]
            if fallbackDeltas then
                for dim, delta in pairs(fallbackDeltas) do
                    if base[dim] ~= nil then
                        base[dim] = base[dim] + delta
                        touched = true
                    end
                end
            end
        end
        if touched then
            applied[#applied + 1] = traitID
        end
    end

    for index = 1, #Projection.DIMENSIONS do
        local dim = Projection.DIMENSIONS[index]
        base[dim] = round2(clamp(base[dim], 0, 100))
    end
    return base, applied
end

local function normalizeDemeanor(actor, opts)
    local source = nil
    if type(opts) == "table" and type(opts.temporaryDemeanor) == "table" then
        source = opts.temporaryDemeanor
    elseif type(actor) == "table" and type(actor.temporaryDemeanor) == "table" then
        source = actor.temporaryDemeanor
    elseif type(actor) == "table" and type(actor.runtime) == "table"
        and type(actor.runtime.temporaryDemeanor) == "table"
    then
        source = actor.runtime.temporaryDemeanor
    end
    local output = {}
    for index = 1, #Projection.DEMEANOR_AXES do
        local axis = Projection.DEMEANOR_AXES[index]
        local raw = source and finite(source[axis], 0) or 0
        output[axis] = round2(clamp(raw, -50, 50))
    end
    return output
end

local function normalizeCondition(actor, opts)
    local cond = {}
    local rawActor = type(actor) == "table" and actor or {}
    local rawOpts = type(opts) == "table" and opts or {}
    local c = type(rawOpts.condition) == "table" and rawOpts.condition
        or (type(rawActor.condition) == "table" and rawActor.condition)
        or (type(rawActor.conditionStats) == "table" and rawActor.conditionStats)
        or {}
    local n = type(rawOpts.needs) == "table" and rawOpts.needs
        or (type(rawActor.needs) == "table" and rawActor.needs)
        or (type(rawActor.runtime) == "table" and type(rawActor.runtime.needs) == "table"
            and type(rawActor.runtime.needs.cachedLevels) == "table"
            and rawActor.runtime.needs.cachedLevels)
        or {}
    local h = type(rawActor.health) == "table" and rawActor.health or {}
    local body = type(h.body) == "table" and h.body or {}

    cond.panic = unitFromAny(c.panic, 0)
    cond.stress = unitFromAny(c.stress, 0)
    cond.fatigue = unitFromAny(c.fatigue ~= nil and c.fatigue or n.fatigue, 0)
    cond.injury = unitFromAny(c.injury ~= nil and c.injury or rawActor.injury, 0)
    cond.pain = unitFromAny(c.pain, 0)
    cond.bleeding = (c.bleeding == true)
        or (h.bleeding == true)
        or (finite(body.bleedingRate, 0) or 0) > 0
        or (finite(body.openWoundCount, 0) or 0) > 0
        or (finite(h.bleedingRate, 0) or 0) > 0
        or (finite(h.openWoundCount, 0) or 0) > 0
        or false
    return cond
end

local function normalizeDispositionTable(tbl)
    if type(tbl) ~= "table" then
        return {
            bravery = 50, confidence = 50, aggression = 50, compassion = 50,
            sociability = 50, forgiveness = 50, materialism = 50, loyalty = 50,
        }
    end
    local scale100 = isScale100(tbl)
    local bravery = toScale100(tbl.bravery, scale100, nil)
        or toScale100(tbl.riskTolerance, scale100, nil)
        or toScale100(tbl.confidence, scale100, 50)
    local confidence = toScale100(tbl.confidence, scale100, nil)
        or bravery
    local compassion = toScale100(tbl.compassion, scale100, nil)
        or toScale100(tbl.empathy, scale100, 50)
    return {
        bravery = round2(bravery),
        confidence = round2(confidence),
        aggression = round2(toScale100(tbl.aggression, scale100, 50)),
        compassion = round2(compassion),
        sociability = round2(toScale100(tbl.sociability, scale100, 50)),
        forgiveness = round2(toScale100(tbl.forgiveness, scale100, 50)),
        materialism = round2(toScale100(tbl.materialism, scale100, 50)),
        loyalty = round2(toScale100(tbl.loyalty, scale100, 50)),
    }
end

function Projection.ResolveStyle(disposition, condition, opts)
    local d = normalizeDispositionTable(disposition)
    local c = type(condition) == "table" and condition or {}
    local o = type(opts) == "table" and opts or {}

    local panic = unitFromAny(c.panic, 0)
    local stress = unitFromAny(c.stress, 0)
    local relationshipState = string.lower(tostring(
        o.relationshipState or c.relationshipState or ""
    ))
    local isHostile = o.isHostile == true or c.isHostile == true
        or relationshipState == "enemy" or relationshipState == "rival"

    if panic >= 0.65
        or (panic >= 0.45 and d.confidence < 60)
        or (stress >= 0.80 and d.confidence < 70)
        or d.confidence <= 32
        or d.bravery <= 32
    then
        return "shaken"
    end
    if isHostile
        or (d.compassion <= 25 and d.sociability <= 35 and d.forgiveness <= 35)
    then
        return "cold"
    end
    if d.aggression >= 70
        or (d.aggression >= 68 and d.compassion < 50)
    then
        return "aggressive"
    end
    if d.compassion >= 66 and d.sociability >= 42 then
        return "supportive"
    end
    if d.bravery >= 68 and d.confidence >= 65 and panic < 0.45 then
        return "brave"
    end
    if d.sociability <= 34 then
        return "reserved"
    end
    if d.materialism >= 60 or o.tactical == true then
        return "practical"
    end
    return "default"
end

function Projection.ToUnitDisposition(disposition)
    local d = normalizeDispositionTable(disposition)
    return {
        bravery = round2(d.bravery / 100),
        confidence = round2(d.confidence / 100),
        aggression = round2(d.aggression / 100),
        compassion = round2(d.compassion / 100),
        empathy = round2(d.compassion / 100),
        sociability = round2(d.sociability / 100),
        forgiveness = round2(d.forgiveness / 100),
        materialism = round2(d.materialism / 100),
        loyalty = round2(d.loyalty / 100),
        riskTolerance = round2(d.bravery / 100),
    }
end

function Projection.Resolve(actor, opts)
    opts = type(opts) == "table" and opts or {}

    local numericSource = pickNumericSource(actor, opts)
    local baseDisposition
    local derivedFromTraits = false
    local appliedTraits = {}

    if numericSource then
        baseDisposition = normalizeDispositionTable(numericSource)
    else
        baseDisposition, appliedTraits = deriveBaselineFromContext(actor, opts)
        derivedFromTraits = #appliedTraits > 0
    end

    local temporaryDemeanor = normalizeDemeanor(actor, opts)
    local cond = normalizeCondition(actor, opts)

    local moraleHope = temporaryDemeanor.moraleHope
    local scarcityAnxiety = temporaryDemeanor.scarcityAnxiety
    local vigilanceFear = temporaryDemeanor.vigilanceFear
    local hostilityIrritability = temporaryDemeanor.hostilityIrritability
    local griefStress = temporaryDemeanor.griefStress
    local confidencePressure = temporaryDemeanor.confidencePressure

    local panicPenalty = math.max(0, cond.panic - 0.40) * 65
    local stressPenalty = math.max(0, cond.stress - 0.35) * 36
    local fatiguePenalty = math.max(0, cond.fatigue - 0.50) * 30
    local injuryPenalty = cond.injury * 25
        + (cond.bleeding and 10 or 0)
        + math.max(0, cond.pain - 0.35) * 18

    local effective = {
        bravery = baseDisposition.bravery
            + 0.35 * moraleHope
            - 0.60 * vigilanceFear
            - 0.50 * griefStress
            - 0.50 * confidencePressure
            - panicPenalty
            - stressPenalty * 0.60
            - fatiguePenalty * 0.40
            - injuryPenalty * 0.50,
        confidence = baseDisposition.confidence
            + 0.45 * moraleHope
            - 0.20 * scarcityAnxiety
            - 0.55 * vigilanceFear
            - 0.55 * griefStress
            - 0.70 * confidencePressure
            - panicPenalty * 1.10
            - stressPenalty * 0.80
            - fatiguePenalty * 0.50
            - injuryPenalty * 0.70,
        aggression = baseDisposition.aggression
            - 0.15 * moraleHope
            + 0.20 * scarcityAnxiety
            + 0.65 * hostilityIrritability
            + stressPenalty * 0.45
            - fatiguePenalty * 0.25,
        compassion = baseDisposition.compassion
            + 0.25 * moraleHope
            - 0.25 * scarcityAnxiety
            - 0.40 * hostilityIrritability
            - 0.15 * griefStress
            - stressPenalty * 0.35
            - fatiguePenalty * 0.20,
        sociability = baseDisposition.sociability
            + 0.30 * moraleHope
            - 0.20 * vigilanceFear
            - 0.35 * hostilityIrritability
            - 0.40 * griefStress
            - panicPenalty * 0.40
            - stressPenalty * 0.30
            - fatiguePenalty * 0.50
            - injuryPenalty * 0.30,
        forgiveness = baseDisposition.forgiveness
            + 0.25 * moraleHope
            - 0.30 * scarcityAnxiety
            - 0.15 * vigilanceFear
            - 0.45 * hostilityIrritability
            - stressPenalty * 0.35
            - fatiguePenalty * 0.25,
        materialism = baseDisposition.materialism
            + 0.50 * scarcityAnxiety
            - 0.15 * moraleHope,
        loyalty = baseDisposition.loyalty
            + 0.20 * moraleHope
            - 0.15 * scarcityAnxiety
            - 0.25 * hostilityIrritability,
    }

    for index = 1, #Projection.DIMENSIONS do
        local dim = Projection.DIMENSIONS[index]
        effective[dim] = round2(clamp(effective[dim], 0, 100))
    end

    local styleProfile = Projection.ResolveStyle(effective, cond, opts)

    return {
        schemaVersion = Projection.VERSION,
        baseDisposition = baseDisposition,
        temporaryDemeanor = temporaryDemeanor,
        effectiveDisposition = effective,
        condition = cond,
        styleProfile = styleProfile,
        derivedFromTraits = derivedFromTraits,
        appliedTraits = appliedTraits,
    }
end

return Projection
