-- Compact player-owned NPC mood stats (stress, boredom, unhappiness, pain).
PNC = PNC or {}
PNC.Mood = PNC.Mood or {}

local Mood = PNC.Mood
local Skills = PNC.Skills

local VALID_STATS = {
    stress = true,
    boredom = true,
    unhappiness = true,
    pain = true,
}

local function clamp01(value)
    return math.max(0, math.min(1, tonumber(value) or 0))
end

local function round3(value)
    return math.floor(clamp01(value) * 1000 + 0.5) / 1000
end

local function ensureMood(record)
    if not Skills or not Skills.CanLearn or not Skills.CanLearn(record) then
        return nil
    end
    if type(record.progression) ~= "table" then record.progression = {} end
    if type(record.progression.mood) ~= "table" then
        record.progression.mood = {}
    end
    return record.progression.mood
end

local function peekMood(record)
    if type(record) ~= "table" or type(record.progression) ~= "table" then
        return nil
    end
    return type(record.progression.mood) == "table"
        and record.progression.mood or nil
end

function Mood.Get(record, stat)
    if not VALID_STATS[stat] then return 0 end
    local state = peekMood(record)
    return state and clamp01(state[stat]) or 0
end

function Mood.Set(record, stat, value)
    if not VALID_STATS[stat] then return false end
    local state = ensureMood(record)
    if not state then return false end
    local rounded = round3(value)
    state[stat] = rounded > 0.001 and rounded or nil
    return true
end

function Mood.Adjust(record, stat, delta)
    if not VALID_STATS[stat] then return false end
    local current = Mood.Get(record, stat)
    return Mood.Set(record, stat, current + (tonumber(delta) or 0))
end

function Mood.SyncPainFromExercise(record, stiffness)
    local painFloor = clamp01((tonumber(stiffness) or 0) / 100)
    local current = Mood.Get(record, "pain")
    if painFloor > current then
        return Mood.Set(record, "pain", painFloor)
    end
    return false
end

function Mood.ApplyExerciseFeedback(record, stiffness, reps)
    local count = math.max(1, tonumber(reps) or 1)
    Mood.Adjust(record, "boredom", -0.02 * count)
    Mood.Adjust(record, "stress", -0.015 * count)
    Mood.SyncPainFromExercise(record, stiffness)
end

function Mood.Update(record, deltaHours, activity)
    if not Skills or not Skills.CanLearn or not Skills.CanLearn(record) then
        return false
    end
    local dt = math.max(0, tonumber(deltaHours) or 0)
    if dt <= 0 then return false end
    activity = tostring(activity or "idle")

    local stress = Mood.Get(record, "stress")
    local boredom = Mood.Get(record, "boredom")
    local unhappiness = Mood.Get(record, "unhappiness")
    local pain = Mood.Get(record, "pain")

    if activity == "fighting" then
        stress = clamp01(stress + 0.14 * dt)
        boredom = clamp01(boredom - 0.20 * dt)
    elseif activity == "working" then
        stress = clamp01(stress - 0.04 * dt)
        boredom = clamp01(boredom - 0.12 * dt)
    elseif activity == "sleeping" or activity == "resting" then
        stress = clamp01(stress - 0.10 * dt)
        boredom = clamp01(boredom - 0.04 * dt)
        unhappiness = clamp01(unhappiness - 0.06 * dt)
    else
        stress = clamp01(stress - 0.05 * dt)
        boredom = clamp01(boredom + 0.05 * dt)
    end

    if boredom >= 0.65 or stress >= 0.70 or pain >= 0.50 then
        unhappiness = clamp01(unhappiness + 0.05 * dt)
    else
        unhappiness = clamp01(unhappiness - 0.03 * dt)
    end

    local exercisePain = PNC.Exercise and PNC.Exercise.GetStiffness
        and clamp01(PNC.Exercise.GetStiffness(record) / 100) or 0
    if pain > exercisePain then
        pain = math.max(exercisePain, pain - (0.08 * dt))
    else
        pain = exercisePain
    end

    Mood.Set(record, "stress", stress)
    Mood.Set(record, "boredom", boredom)
    Mood.Set(record, "unhappiness", unhappiness)
    Mood.Set(record, "pain", pain)
    return true
end

function Mood.GetCombatModifiers(record)
    local ex = PNC.Exercise and PNC.Exercise.GetDebuffModifiers
        and PNC.Exercise.GetDebuffModifiers(record)
        or {
            damageMultiplier = 1.0,
            cooldownMultiplier = 1.0,
            staminaDrainMultiplier = 1.0,
        }
    local stress = Mood.Get(record, "stress")
    local unhappiness = Mood.Get(record, "unhappiness")
    local pain = Mood.Get(record, "pain")

    local dmg = tonumber(ex.damageMultiplier) or 1.0
    if pain >= 0.50 and dmg > 0.70 then dmg = 0.70 end
    if stress >= 0.70 then dmg = dmg * 0.90 end

    local cd = tonumber(ex.cooldownMultiplier) or 1.0
    if unhappiness >= 0.65 then cd = cd * 1.15 end

    local drain = tonumber(ex.staminaDrainMultiplier) or 1.0
    local hitBias = 0
    if stress >= 0.60 then hitBias = hitBias - 0.06 end
    if pain >= 0.50 then hitBias = hitBias - 0.08 end

    return {
        damageMultiplier = dmg,
        cooldownMultiplier = cd,
        staminaDrainMultiplier = drain,
        hitChanceBias = hitBias,
    }
end

return Mood
