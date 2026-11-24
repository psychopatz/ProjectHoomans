-- Player-owned NPC exercise system with vanilla regularity and stiffness debuffs.
PNC = PNC or {}
PNC.Exercise = PNC.Exercise or {}

local Exercise = PNC.Exercise
local Skills = PNC.Skills

local EXERCISES = {
    squats = {
        id = "squats",
        xp = { { skillId = "Fitness", amount = 4.0 } },
        heavy = false,
        staminaPerRep = 3.5,
        fatiguePerRep = 0.008,
        regularityGain = 0.5,
    },
    pushups = {
        id = "pushups",
        xp = { { skillId = "Strength", amount = 4.0 } },
        heavy = false,
        staminaPerRep = 3.5,
        fatiguePerRep = 0.008,
        regularityGain = 0.5,
    },
    situps = {
        id = "situps",
        xp = { { skillId = "Fitness", amount = 3.5 } },
        heavy = false,
        staminaPerRep = 3.0,
        fatiguePerRep = 0.007,
        regularityGain = 0.5,
    },
    burpees = {
        id = "burpees",
        xp = {
            { skillId = "Fitness", amount = 3.5 },
            { skillId = "Strength", amount = 3.5 },
        },
        heavy = true,
        staminaPerRep = 5.0,
        fatiguePerRep = 0.012,
        regularityGain = 0.65,
    },
}

Exercise.Definitions = EXERCISES
Exercise.ONSET_DELAY_HOURS = 12.0
Exercise.STIFFNESS_DECAY_PER_HOUR = 4.0
Exercise.STIFFNESS_REST_DECAY_PER_HOUR = 7.5

local function clamp(value, lo, hi)
    return math.max(lo, math.min(hi, tonumber(value) or lo))
end

local function round2(value)
    return math.floor((tonumber(value) or 0) * 100 + 0.5) / 100
end

local function ensureExerciseState(record)
    if not Skills or not Skills.CanLearn or not Skills.CanLearn(record) then
        return nil
    end
    if type(record.progression) ~= "table" then record.progression = {} end
    if type(record.progression.exercise) ~= "table" then
        record.progression.exercise = {
            stiffness = 0,
            pendingStiffness = 0,
            onsetHours = 0,
            regularity = {},
        }
    end
    local state = record.progression.exercise
    if type(state.regularity) ~= "table" then state.regularity = {} end
    return state
end

local function peekExerciseState(record)
    if type(record) ~= "table" or type(record.progression) ~= "table" then
        return nil
    end
    return type(record.progression.exercise) == "table"
        and record.progression.exercise or nil
end

function Exercise.GetStiffness(record)
    local state = peekExerciseState(record)
    return state and clamp(state.stiffness, 0, 100) or 0
end

function Exercise.GetRegularity(record, exerciseType)
    local state = peekExerciseState(record)
    if not state or type(state.regularity) ~= "table" then return 0 end
    return clamp(state.regularity[tostring(exerciseType or "")], 0, 100)
end

function Exercise.GetDebuffModifiers(record)
    local stiffness = Exercise.GetStiffness(record)
    if stiffness >= 80 then
        return {
            stiffness = stiffness,
            painLevel = 3,
            damageMultiplier = 0.50,
            cooldownMultiplier = 1.60,
            staminaDrainMultiplier = 1.75,
        }
    elseif stiffness >= 50 then
        return {
            stiffness = stiffness,
            painLevel = 2,
            damageMultiplier = 0.68,
            cooldownMultiplier = 1.35,
            staminaDrainMultiplier = 1.45,
        }
    elseif stiffness >= 20 then
        return {
            stiffness = stiffness,
            painLevel = 1,
            damageMultiplier = 0.85,
            cooldownMultiplier = 1.15,
            staminaDrainMultiplier = 1.20,
        }
    end
    return {
        stiffness = stiffness,
        painLevel = 0,
        damageMultiplier = 1.0,
        cooldownMultiplier = 1.0,
        staminaDrainMultiplier = 1.0,
    }
end

function Exercise.PerformRep(record, exerciseType, reps)
    local def = EXERCISES[string.lower(tostring(exerciseType or ""))]
    if not def then return false, "invalid_exercise" end
    local state = ensureExerciseState(record)
    if not state then return false, "not_player_owned" end
    local count = math.max(1, math.floor(tonumber(reps) or 1))

    -- Award Fitness / Strength XP
    local awards = {}
    for i = 1, #def.xp do
        awards[i] = {
            skillId = def.xp[i].skillId,
            amount = def.xp[i].amount * count,
        }
    end
    Skills.AddXPBatch(record, awards)

    -- Regularity progression & vanilla Fitness.java stiffness curve
    local reg = clamp(state.regularity[def.id], 0, 100)
    local baseInc = 0.5 * ((120 - reg) / 170) * count
    if def.heavy then baseInc = baseInc * 1.3 end

    -- Over-exercising while fatigued increases stiffness and triggers immediate ache
    local fatigue = record.needs and tonumber(record.needs.fatigue) or 0
    if fatigue >= 0.60 then
        baseInc = baseInc * (1 + math.min(1.0, fatigue))
    end
    state.regularity[def.id] = round2(clamp(reg + (def.regularityGain * count), 0, 100))

    if (tonumber(state.pendingStiffness) or 0) <= 0 then
        state.onsetHours = Exercise.ONSET_DELAY_HOURS
    end
    state.pendingStiffness = round2(clamp(
        (tonumber(state.pendingStiffness) or 0) + baseInc, 0, 100
    ))

    -- Acute over-exertion hurts immediately if pushed hard in one session
    if state.pendingStiffness >= 35 or fatigue >= 0.75 then
        local acute = baseInc * 0.45
        state.stiffness = round2(clamp((tonumber(state.stiffness) or 0) + acute, 0, 100))
    end

    -- Drain stamina & add fatigue
    if type(record.stamina) == "table" and record.stamina.current ~= nil then
        local cost = def.staminaPerRep * count
        record.stamina.current = math.max(0, (tonumber(record.stamina.current) or 0) - cost)
    end
    if PNC.Mood and PNC.Mood.ApplyExerciseFeedback then
        PNC.Mood.ApplyExerciseFeedback(record, state.stiffness, count)
    end
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "exercise")
    end
    return true, {
        exercise = def.id,
        reps = count,
        regularity = state.regularity[def.id],
        stiffness = state.stiffness,
        pendingStiffness = state.pendingStiffness,
    }
end

function Exercise.Update(record, deltaHours, isResting)
    local state = peekExerciseState(record)
    if not state then return false end
    local dt = math.max(0, tonumber(deltaHours) or 0)
    if dt <= 0 then return false end

    local pending = tonumber(state.pendingStiffness) or 0
    local onset = tonumber(state.onsetHours) or 0
    local stiffness = tonumber(state.stiffness) or 0
    local changed = false

    if pending > 0 then
        local activeDt = dt
        if onset > 0 then
            local consumed = math.min(onset, dt)
            onset = math.max(0, onset - consumed)
            activeDt = math.max(0, dt - consumed)
            state.onsetHours = round2(onset)
            changed = true
        end
        if onset <= 0 and activeDt > 0 then
            local transfer = math.min(pending, activeDt * 12.0)
            pending = math.max(0, pending - transfer)
            stiffness = clamp(stiffness + transfer, 0, 100)
            state.pendingStiffness = round2(pending)
            state.stiffness = round2(stiffness)
            changed = true
        end
    elseif stiffness > 0 then
        local rate = isResting and Exercise.STIFFNESS_REST_DECAY_PER_HOUR
            or Exercise.STIFFNESS_DECAY_PER_HOUR
        stiffness = math.max(0, stiffness - (rate * dt))
        state.stiffness = round2(stiffness)
        changed = true
    end

    if PNC.Mood and PNC.Mood.SyncPainFromExercise then
        PNC.Mood.SyncPainFromExercise(record, state.stiffness)
    end
    return changed
end

return Exercise
