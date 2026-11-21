-- Compiled AutonomyAd scorer, hysteresis gate, cooldown tracker, and promotion hydrator.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AutonomyScorer = PNC.AutonomyScorer or {}

local Scorer = PNC.AutonomyScorer
local AutonomyAdRegistry = PNC.AutonomyAd and PNC.AutonomyAd.Registry
if not AutonomyAdRegistry and type(require) == "function" then
    AutonomyAdRegistry = require "PNC/AutonomyAd/Registry"
end

Scorer.MAX_ADS_EVALUATED = 64
Scorer.DEFAULT_COOLDOWN_MS = 6000
Scorer.SAME_BAND_STICKY_BONUS = 0.05
Scorer.Cooldowns = Scorer.Cooldowns or {}
Scorer.LastRejections = Scorer.LastRejections or {}

local ALLOWED_BANDS = {
    OPTIONAL = true,
    IDLE = true,
}

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    return PNC.Core and type(PNC.Core.Now) == "function" and PNC.Core.Now() or 0
end

local function clamp01(value)
    local num = tonumber(value) or 0
    if num < 0 then return 0 end
    if num > 1 then return 1 end
    return num
end

local function normalizeBand(band)
    local key = tostring(band or "IDLE")
    if ALLOWED_BANDS[key] then return key end
    return "IDLE"
end

local function registry()
    if PNC.AutonomyAd and PNC.AutonomyAd.Registry then
        return PNC.AutonomyAd.Registry
    end
    return AutonomyAdRegistry
end

local function sortedAdIds(reg)
    local ids = {}
    local ads = reg and reg.ads or nil
    if type(ads) ~= "table" then return ids end
    for adId in pairs(ads) do
        ids[#ids + 1] = adId
    end
    table.sort(ids)
    return ids
end

local function containsKeyOrValue(collection, targetKey)
    if type(collection) ~= "table" then return false end
    if collection[targetKey] == true then return true end
    if tonumber(collection[targetKey]) and tonumber(collection[targetKey]) > 0 then
        return true
    end
    for i = 1, #collection do
        if tostring(collection[i]) == targetKey then
            return true
        end
    end
    return false
end

local function recordHasTrait(record, traitKey)
    if type(record) ~= "table" then return false end
    if containsKeyOrValue(record.traits, traitKey) then return true end
    local persona = record.persona
    if type(persona) == "table" and containsKeyOrValue(persona.traits, traitKey) then
        return true
    end
    local social = record.social
    if type(social) == "table" and containsKeyOrValue(social.traits, traitKey) then
        return true
    end
    local runtime = record.runtime
    if type(runtime) == "table" and containsKeyOrValue(runtime.traits, traitKey) then
        return true
    end
    return false
end

local function moodStrength(record, moodKey)
    if type(record) ~= "table" then return 0 end
    local moods = record.moods
    if type(moods) == "table" and moods[moodKey] ~= nil then
        local v = moods[moodKey]
        if v == true then return 1 end
        return math.max(0, math.min(1, tonumber(v) or 0))
    end
    local runtime = record.runtime
    if type(runtime) == "table" and type(runtime.moods) == "table"
        and runtime.moods[moodKey] ~= nil
    then
        local v = runtime.moods[moodKey]
        if v == true then return 1 end
        return math.max(0, math.min(1, tonumber(v) or 0))
    end
    local social = record.social
    if type(social) == "table" and type(social.moods) == "table"
        and social.moods[moodKey] ~= nil
    then
        local v = social.moods[moodKey]
        if v == true then return 1 end
        return math.max(0, math.min(1, tonumber(v) or 0))
    end
    if moodKey == "tired" then
        local fatigue = Scorer.ResolveNeedValue(record, "fatigue")
        if fatigue >= 0.45 then return fatigue end
    elseif moodKey == "bored" then
        local boredom = Scorer.ResolveNeedValue(record, "boredom")
        if boredom >= 0.40 then return boredom end
    end
    return 0
end

---Piecewise-linear interpolation over sorted curve points `{ { value = x, score = y }, ... }`.
function Scorer.EvaluateCurve(curve, rawValue)
    local x = clamp01(rawValue)
    if type(curve) ~= "table" or #curve == 0 then
        return clamp01(x)
    end
    local first = curve[1]
    if x <= (tonumber(first.value) or 0) then
        return clamp01(first.score)
    end
    local count = #curve
    local last = curve[count]
    if x >= (tonumber(last.value) or 1) then
        return clamp01(last.score)
    end
    for i = 1, count - 1 do
        local p0 = curve[i]
        local p1 = curve[i + 1]
        local x0 = tonumber(p0.value) or 0
        local x1 = tonumber(p1.value) or 1
        if x >= x0 and x <= x1 then
            local y0 = tonumber(p0.score) or 0
            local y1 = tonumber(p1.score) or 0
            if x1 <= x0 then
                return clamp01(y1)
            end
            local t = (x - x0) / (x1 - x0)
            return clamp01(y0 + (y1 - y0) * t)
        end
    end
    return clamp01(last.score)
end

---Reads the bounded [0,1] need value driving an AutonomyAd curve.
function Scorer.ResolveNeedValue(record, needKey)
    local key = tostring(needKey or "")
    if key == "" or type(record) ~= "table" then
        return 0.5
    end
    if PNC.IndividualNeeds and type(PNC.IndividualNeeds.Get) == "function" then
        local val = tonumber(PNC.IndividualNeeds.Get(record, key))
        if val ~= nil then
            return clamp01(val)
        end
    end
    if type(record.needs) == "table" and record.needs[key] ~= nil then
        return clamp01(record.needs[key])
    end
    if key == "boredom" and type(record.social) == "table"
        and record.social.boredom ~= nil
    then
        return clamp01(record.social.boredom)
    end
    return 0.35
end

---Sums trait weight contributions matching `traitWeights`. Allocates `outBreakdown` only when provided.
function Scorer.ResolveTraitModifier(record, traitWeights, outBreakdown)
    local delta = 0
    if type(traitWeights) ~= "table" or type(record) ~= "table" then
        return 0
    end
    for traitKey, weight in pairs(traitWeights) do
        local numWeight = tonumber(weight) or 0
        if numWeight ~= 0 and recordHasTrait(record, tostring(traitKey)) then
            delta = delta + numWeight
            if type(outBreakdown) == "table" then
                outBreakdown[#outBreakdown + 1] = {
                    key = tostring(traitKey),
                    weight = numWeight,
                }
            end
        end
    end
    if type(outBreakdown) == "table" then
        table.sort(outBreakdown, function(a, b) return a.key < b.key end)
    end
    return delta
end

---Sums mood weight contributions matching `moodWeights`. Allocates `outBreakdown` only when provided.
function Scorer.ResolveMoodModifier(record, moodWeights, outBreakdown)
    local delta = 0
    if type(moodWeights) ~= "table" or type(record) ~= "table" then
        return 0
    end
    for moodKey, weight in pairs(moodWeights) do
        local numWeight = tonumber(weight) or 0
        if numWeight ~= 0 then
            local strength = moodStrength(record, tostring(moodKey))
            if strength > 0 then
                local contribution = numWeight * strength
                delta = delta + contribution
                if type(outBreakdown) == "table" then
                    outBreakdown[#outBreakdown + 1] = {
                        key = tostring(moodKey),
                        weight = numWeight,
                        strength = strength,
                        contribution = contribution,
                    }
                end
            end
        end
    end
    if type(outBreakdown) == "table" then
        table.sort(outBreakdown, function(a, b) return a.key < b.key end)
    end
    return delta
end

---Records a cooldown for `(npcId, adId)` after rejection, failure, or cancellation.
function Scorer.RecordFailure(npcId, adId, reason, at, cooldownMs)
    local npcKey = tostring(npcId or "")
    local adKey = tostring(adId or "")
    if npcKey == "" or adKey == "" then return false end
    local current = nowMs(at)
    local duration = tonumber(cooldownMs)
    if duration == nil then
        local reg = registry()
        local adSpec = reg and reg.GetAd and reg.GetAd(adKey) or nil
        duration = adSpec and tonumber(adSpec.cooldownMs) or Scorer.DEFAULT_COOLDOWN_MS
    end
    Scorer.Cooldowns[npcKey] = Scorer.Cooldowns[npcKey] or {}
    Scorer.Cooldowns[npcKey][adKey] = {
        untilMs = current + math.max(0, duration),
        reason = tostring(reason or "autonomy_failed"),
        recordedAt = current,
    }
    return true
end

---Checks whether `(npcId, adId)` is currently suppressed by cooldown.
function Scorer.IsInCooldown(npcId, adId, at)
    local npcKey = tostring(npcId or "")
    local adKey = tostring(adId or "")
    local byAd = Scorer.Cooldowns[npcKey]
    local entry = byAd and byAd[adKey] or nil
    if not entry then return false end
    local current = nowMs(at)
    local untilMs = tonumber(entry.untilMs) or 0
    if current < untilMs then
        return true, untilMs, entry.reason
    end
    byAd[adKey] = nil
    return false
end

---Scores a single compiled AutonomyAd against `record` and `targetContext`.
function Scorer.ScoreAd(record, adSpec, targetContext, at, activeAdId, includeDiagnostics)
    if type(record) ~= "table" or type(adSpec) ~= "table" then
        return nil, "INVALID_AD_INPUT"
    end
    local npcKey = tostring(record.id or "")
    local adKey = tostring(adSpec.id or "")
    local current = nowMs(at)
    local onCooldown, untilMs, cooldownReason = Scorer.IsInCooldown(npcKey, adKey, current)
    if onCooldown then
        return nil, "COOLDOWN_ACTIVE", includeDiagnostics and {
            adId = adKey,
            cooldownUntil = untilMs,
            cooldownReason = cooldownReason,
        } or nil
    end

    local maxRange = tonumber(adSpec.maxRange) or 0
    local distance = nil
    local distancePenalty = 0
    if type(targetContext) == "table" and maxRange > 0 then
        if targetContext.distance ~= nil then
            distance = tonumber(targetContext.distance)
        elseif targetContext.x ~= nil and targetContext.y ~= nil
            and record.x ~= nil and record.y ~= nil
        then
            local dx = (tonumber(targetContext.x) or 0) - (tonumber(record.x) or 0)
            local dy = (tonumber(targetContext.y) or 0) - (tonumber(record.y) or 0)
            local sqDist = dx * dx + dy * dy
            if sqDist > maxRange * maxRange then
                return nil, "OUT_OF_RANGE", includeDiagnostics and {
                    adId = adKey,
                    distanceSq = sqDist,
                    maxRange = maxRange,
                } or nil
            end
            distance = math.sqrt(sqDist)
        end
        if distance ~= nil then
            if distance > maxRange then
                return nil, "OUT_OF_RANGE", includeDiagnostics and {
                    adId = adKey,
                    distance = distance,
                    maxRange = maxRange,
                } or nil
            end
            local distanceWeight = tonumber(adSpec.distanceWeight) or 0
            distancePenalty = distanceWeight * (distance / maxRange)
        end
    end

    local rawNeed = Scorer.ResolveNeedValue(record, adSpec.needKey)
    local baseCurveScore = Scorer.EvaluateCurve(adSpec.curve, rawNeed)
    local traitBreakdown = includeDiagnostics and {} or nil
    local moodBreakdown = includeDiagnostics and {} or nil
    local traitDelta = Scorer.ResolveTraitModifier(record, adSpec.traitWeights, traitBreakdown)
    local moodDelta = Scorer.ResolveMoodModifier(record, adSpec.moodWeights, moodBreakdown)

    local isCurrent = tostring(activeAdId or "") == adKey
    local stickyBonus = isCurrent and Scorer.SAME_BAND_STICKY_BONUS or 0
    local finalScore = clamp01(baseCurveScore + traitDelta + moodDelta - distancePenalty + stickyBonus)

    local hysteresis = type(adSpec.hysteresis) == "table" and adSpec.hysteresis or nil
    local enterThreshold = tonumber(hysteresis and hysteresis.enter) or 0.30
    local exitThreshold = tonumber(hysteresis and hysteresis.exit) or 0.15
    local criticalThreshold = tonumber(hysteresis and hysteresis.critical) or 0.85

    if isCurrent and finalScore < exitThreshold then
        return nil, "BELOW_HYSTERESIS_EXIT", includeDiagnostics and {
            adId = adKey,
            score = finalScore,
            exitThreshold = exitThreshold,
        } or nil
    end
    if not isCurrent and finalScore < enterThreshold then
        return nil, "BELOW_HYSTERESIS_ENTER", includeDiagnostics and {
            adId = adKey,
            score = finalScore,
            enterThreshold = enterThreshold,
        } or nil
    end

    local details = nil
    if includeDiagnostics then
        details = {
            adId = adKey,
            band = normalizeBand(adSpec.band),
            capability = adSpec.capability,
            needKey = adSpec.needKey,
            rawNeed = rawNeed,
            baseCurve = baseCurveScore,
            traitDelta = traitDelta,
            moodDelta = moodDelta,
            distance = distance,
            distancePenalty = distancePenalty,
            stickyBonus = stickyBonus,
            score = finalScore,
            isCritical = finalScore >= criticalThreshold,
            traits = traitBreakdown,
            moods = moodBreakdown,
        }
    end
    return finalScore, normalizeBand(adSpec.band), details
end

---Evaluates compiled AutonomyAds up to `MAX_ADS_EVALUATED` (64).
function Scorer.EvaluateAll(record, contextsByAdOrFn, at, options)
    options = type(options) == "table" and options or nil
    local includeDiagnostics = options ~= nil and options.includeDiagnostics == true
    local reg = registry()
    if type(record) ~= "table" or not reg or type(reg.ads) ~= "table" then
        return {}, includeDiagnostics and {} or nil
    end

    local current = nowMs(at)
    local activeAdId = options and options.activeAdId
        or (record.runtime and record.runtime.autonomyAdId)
    local ids = sortedAdIds(reg)
    local scored = {}
    local rejected = includeDiagnostics and {} or nil
    local evaluated = 0

    for i = 1, #ids do
        if evaluated >= Scorer.MAX_ADS_EVALUATED then
            break
        end
        local adId = ids[i]
        local adSpec = reg.ads[adId]
        if type(adSpec) == "table" then
            evaluated = evaluated + 1
            local context
            if type(contextsByAdOrFn) == "function" then
                context = contextsByAdOrFn(adSpec, record, current)
            elseif type(contextsByAdOrFn) == "table" then
                context = contextsByAdOrFn[adId]
            end
            if context == false then
                if includeDiagnostics then
                    rejected[#rejected + 1] = { adId = adId, reason = "CONTEXT_UNAVAILABLE" }
                end
            else
                local score, bandOrReason, diag = Scorer.ScoreAd(
                    record, adSpec, context, current, activeAdId, includeDiagnostics)
                if score ~= nil then
                    scored[#scored + 1] = {
                        adId = adId,
                        ad = adSpec,
                        context = context,
                        band = bandOrReason,
                        urgency = score,
                        diagnostics = diag,
                    }
                elseif includeDiagnostics then
                    rejected[#rejected + 1] = {
                        adId = adId,
                        reason = tostring(bandOrReason or "REJECTED"),
                        details = diag,
                    }
                end
            end
        end
    end

    table.sort(scored, function(a, b)
        local rankA = a.band == "OPTIONAL" and 2 or 1
        local rankB = b.band == "OPTIONAL" and 2 or 1
        if rankA ~= rankB then return rankA > rankB end
        if math.abs(a.urgency - b.urgency) > 1e-6 then
            return a.urgency > b.urgency
        end
        return tostring(a.adId) < tostring(b.adId)
    end)

    if includeDiagnostics then
        Scorer.LastRejections[tostring(record.id or "")] = rejected
    end
    return scored, rejected
end

---Hydrates newly promoted NPCs with bounded need catch-up and clean cooldown state.
function Scorer.HydrateOnPromotion(record, elapsedHours, at)
    if type(record) ~= "table" then return false, "RECORD_REQUIRED" end
    local current = nowMs(at)
    local hours = math.max(0, math.min(24, tonumber(elapsedHours) or 0))
    record.runtime = type(record.runtime) == "table" and record.runtime or {}
    record.needs = type(record.needs) == "table" and record.needs or {}

    if hours > 0 then
        -- Promoted SurvivorWorld NPCs settle into baseline colony sufficiency
        -- instead of inheriting extreme offline deficits at spawn time.
        local decayRelief = math.min(0.45, 0.15 + hours * 0.05)
        for _, key in ipairs({ "hunger", "thirst", "fatigue", "boredom" }) do
            local existing = tonumber(record.needs[key])
            if existing == nil then
                record.needs[key] = 0.20
            else
                record.needs[key] = clamp01(math.min(existing, math.max(0.20, existing - decayRelief)))
            end
        end
    elseif record.needs.boredom == nil then
        record.needs.boredom = 0.25
    end

    local npcKey = tostring(record.id or "")
    if npcKey ~= "" then
        Scorer.Cooldowns[npcKey] = nil
        Scorer.LastRejections[npcKey] = nil
    end

    record.runtime.lastAutonomyHydratedAt = current
    record.runtime.autonomyHydration = {
        hydrated = true,
        at = current,
        elapsedHours = hours,
    }
    return true, record.runtime.autonomyHydration
end

function Scorer.Reset()
    Scorer.Cooldowns = {}
    Scorer.LastRejections = {}
end

return Scorer
