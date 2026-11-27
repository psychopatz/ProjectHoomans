-- Generic O(1) deterministic anchor-and-slope stat math kernel.
-- Shared between server and client so stats (hunger, thirst, fatigue, stamina,
-- stress, panic) evolve identically without per-tick mutation or periodic
-- network sync packets. Mutate and broadcast ONLY on discrete events or
-- activity-rate transitions ("bake-on-transition").

PNC = PNC or {}
PNC.DeterministicStat = PNC.DeterministicStat or {}

local Stat = PNC.DeterministicStat

-- Reference conversion constants piggybacking vanilla PZ item stats:
-- ~2000 kcal ≈ 24 world-hours of baseline metabolic burn (~83.3 kcal/h).
Stat.KCAL_PER_DAY = 2000
Stat.KCAL_PER_HOUR = Stat.KCAL_PER_DAY / 24
Stat.HUNGER_BURN_HOURS = 24
Stat.THIRST_BURN_HOURS = 18
Stat.FATIGUE_BURN_HOURS = 16
Stat.MAX_FUEL_BANK_HOURS = 48
Stat.MIN_FUEL_DEFICIT_HOURS = -36
Stat.MAX_WATER_BANK_HOURS = 24

local function clamp(val, lo, hi)
    val = tonumber(val) or lo
    if val < lo then return lo end
    if val > hi then return hi end
    return val
end

-- Creates a compact 3-number anchor `{ v = value, t = timestamp, r = ratePerUnitTime }`.
function Stat.Anchor(value, at, rate, minVal, maxVal)
    local lo = tonumber(minVal) or 0
    local hi = tonumber(maxVal) or 1
    return {
        v = clamp(value, lo, hi),
        t = tonumber(at) or 0,
        r = tonumber(rate) or 0,
    }
end

-- Pure O(1) evaluation at `now` (same time unit as `anchor.t` and `anchor.r`).
function Stat.Evaluate(anchor, now, minVal, maxVal)
    local lo = tonumber(minVal) or 0
    local hi = tonumber(maxVal) or 1
    if type(anchor) ~= "table" then return lo end
    local elapsed = (tonumber(now) or 0) - (tonumber(anchor.t) or 0)
    if elapsed < 0 then elapsed = 0 end
    return clamp((tonumber(anchor.v) or lo) + elapsed * (tonumber(anchor.r) or 0), lo, hi)
end

-- Bake-on-transition: evaluates current value at `now`, stamps `t = now`, and
-- applies `newRate` (e.g. idle -> sprinting, awake -> sleeping).
function Stat.Bake(anchor, now, newRate, minVal, maxVal)
    local lo = tonumber(minVal) or 0
    local hi = tonumber(maxVal) or 1
    local current = Stat.Evaluate(anchor, now, lo, hi)
    anchor.v = current
    anchor.t = tonumber(now) or 0
    anchor.r = tonumber(newRate) or 0
    return current
end

-- Discrete mutation (e.g. melee swing stamina cost, stress spike, cigarette relief).
function Stat.Shift(anchor, now, delta, minVal, maxVal)
    local lo = tonumber(minVal) or 0
    local hi = tonumber(maxVal) or 1
    local current = Stat.Evaluate(anchor, now, lo, hi)
    local updated = clamp(current + (tonumber(delta) or 0), lo, hi)
    anchor.v = updated
    anchor.t = tonumber(now) or 0
    return updated
end

-- Evaluates a world-hour satiety horizon (`horizonH`) into a normalized need [0, maxNeed].
-- Positive surplus (`horizonH >= nowH`) => 0 need (satisfied).
-- Negative deficit (`horizonH < nowH`) => linear rise over `burnHours`.
function Stat.HorizonNeed(horizonH, nowH, burnHours, maxNeed)
    local cap = tonumber(maxNeed) or 1
    local burn = math.max(1, tonumber(burnHours) or 24)
    local surplus = (tonumber(horizonH) or 0) - (tonumber(nowH) or 0)
    if surplus >= 0 then return 0, surplus end
    return clamp((-surplus) / burn, 0, cap), surplus
end

-- Converts a normalized need [0, 1] back into a world-hour horizon at `nowH`.
function Stat.NeedToHorizon(needVal, nowH, burnHours)
    local n = clamp(needVal, 0, 1)
    local burn = math.max(1, tonumber(burnHours) or 24)
    return (tonumber(nowH) or 0) - (n * burn)
end

-- Converts vanilla/modded PZ food stats (`calories`, `hungerChange`) into world-hours of fuel.
function Stat.CaloriesToFuelHours(calories, hungerChange)
    local kcal = math.max(0, tonumber(calories) or 0)
    local hRelief = math.abs(tonumber(hungerChange) or 0)
    if hRelief > 1 then hRelief = hRelief / 100 end
    local fromCalories = kcal / Stat.KCAL_PER_HOUR
    local fromHunger = hRelief * 10
    if kcal > 0 and hRelief > 0 then
        return clamp((fromCalories * 0.65) + (fromHunger * 0.35), 0.25, 24)
    elseif kcal > 0 then
        return clamp(fromCalories, 0.25, 24)
    elseif hRelief > 0 then
        return clamp(fromHunger, 0.25, 18)
    end
    return 0
end

function Stat.FuelHoursToCalories(fuelHours)
    return math.floor((tonumber(fuelHours) or 0) * Stat.KCAL_PER_HOUR + 0.5)
end

-- Converts vanilla/modded PZ drink `thirstChange` into world-hours of hydration.
function Stat.ThirstToWaterHours(thirstChange)
    local tRelief = math.abs(tonumber(thirstChange) or 0)
    if tRelief > 1 then tRelief = tRelief / 100 end
    return clamp(tRelief * 12, 0, Stat.MAX_WATER_BANK_HOURS)
end

-- Deterministic weight evolution directly from world-hour fuel surplus/deficit
-- (eliminates carbs/proteins/lipids macro tracking).
function Stat.EvaluateWeightFromFuelHours(weight, surplusHours, elapsedHours, hasWeightGain, hasWeightLoss, minW, maxW)
    local w = clamp(weight, tonumber(minW) or 35, tonumber(maxW) or 200)
    local dt = math.max(0, tonumber(elapsedHours) or 0)
    if dt <= 0 then return w end
    local s = tonumber(surplusHours) or 0

    -- Surplus threshold: heavier bodies need more banked hours to gain;
    -- weightgain trait lowers threshold; weightloss raises deficit resistance.
    local gainAt = (hasWeightGain == true and w < 90 and 8 or 12) + math.max(0, (w - 80) * 0.35)
    local lossAt = math.min(-4, (hasWeightLoss == true and w > 70 and -20 or -12) + (w - 70) * 0.25)

    local delta = 0
    if s > gainAt then
        local factor = clamp((s - gainAt) / 24, 0.15, 1.5)
        delta = 0.045 * factor * dt -- ~1.0 kg/day at sustained high surplus
    elseif s < lossAt then
        local factor = clamp((lossAt - s) / 24, 0.15, 1.5)
        delta = -0.035 * factor * dt -- ~0.8 kg/day at sustained deep deficit
    end
    return clamp(w + delta, tonumber(minW) or 35, tonumber(maxW) or 200)
end

-- Deterministic lightweight hash [0, 1) from string ID (zero RNG state needed).
function Stat.HashUnit(id)
    local s = tostring(id or "")
    local h = 2166136261
    for i = 1, #s do
        h = ((h * 33) + string.byte(s, i)) % 16777216
    end
    return (h % 10000) / 10000
end

return Stat
