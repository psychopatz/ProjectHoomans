if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Needs = PNC.GroupNeeds
local H = Needs.Internal
local Definitions = PNC.NeedsDefinitions
local Utils = PNC.NeedsUtils

local function worldEventEffectsFor(faction, nowHours)
    local director = PNC.ScopedWorldEventDirector
    if director and type(director.AggregateEffectsForFaction) == "function" then
        local agg = director.AggregateEffectsForFaction(faction, nowHours)
        return type(agg) == "table" and agg.effects or {}
    end
    local swe = PsychopatzCore and PsychopatzCore.ScopedWorldEvents
    if swe and type(swe.AggregateEffects) == "function" then
        local agg = swe.AggregateEffects({
            factionID = faction and faction.id or nil,
            includeGlobal = true,
        }, nowHours)
        return type(agg) == "table" and agg.effects or {}
    end
    return {}
end

local function ratesFor(state, faction, nowHours)
    local activityKey = state and state.debugActivity or "idle"
    local activity = Definitions.GROUP_ACTIVITY[activityKey]
        or Definitions.GROUP_ACTIVITY.idle
    local size = Utils.GroupSizeModifier(H.MemberCount(faction))
    local effects = worldEventEffectsFor(faction, nowHours)
    local foodPressure = tonumber(effects.foodAvailabilityPressure) or 0
    local scarcity = math.max(0, tonumber(effects.tradeScarcity) or 0)
    local hungerScale = math.max(0.5, 1 + foodPressure + scarcity * 0.25)
    local thirstScale = math.max(0.7, 1 + math.max(0, foodPressure) * 0.25)
    local output = {}
    for _, needType in ipairs(Definitions.TYPES) do
        local rate = Definitions.GROUP_RATES_PER_HOUR[needType]
            * size * (activity[needType] or 1)
        if needType == "hunger" then
            rate = rate * hungerScale
        elseif needType == "thirst" then
            rate = rate * thirstScale
        end
        output[needType] = rate
    end
    return output
end

function Needs.GetActivity(factionOrID)
    local state = Needs.Ensure(factionOrID)
    return state and state.debugActivity or "idle"
end

function Needs.GetRates(factionOrID, nowHours)
    local state, faction = Needs.Ensure(factionOrID)
    if not state or not faction then return nil end
    return ratesFor(state, faction, nowHours or Utils.WorldAgeHours())
end

local function applyMemberConsequences(faction, beforeState, state, rates, elapsedHours)
    local consequences = PNC.NeedHealthConsequences
    local reg = PNC.Registry
    if not consequences or type(consequences.Apply) ~= "function"
        or not reg or type(reg.Get) ~= "function"
    then
        return
    end
    local memberIDs = {}
    for npcID, present in pairs(faction.memberIDs or {}) do
        if present == true then
            memberIDs[#memberIDs + 1] = tostring(npcID)
        end
    end
    table.sort(memberIDs)
    local individual = PNC.IndividualNeeds
    for i = 1, #memberIDs do
        local record = reg.Get(memberIDs[i])
        if record and record.alive ~= false
            and not (individual and individual.IsEligible and individual.IsEligible(record))
        then
            consequences.Apply(record, beforeState, state, rates, elapsedHours)
        end
    end
end

function Needs.Update(factionOrID, elapsedHours, reason, stateOverride,
    factionOverride, nowHours)
    local state, faction = stateOverride, factionOverride
    if not state or not faction then
        state, faction = Needs.Ensure(factionOrID)
    end
    if not state or not faction then return false end
    elapsedHours = math.max(0, tonumber(elapsedHours) or 0)
    if elapsedHours <= 0 then return true end
    local at = tonumber(nowHours) or Utils.WorldAgeHours()
    local rates = ratesFor(state, faction, at)
    local beforeState = {
        hunger = tonumber(state.hunger) or 0,
        thirst = tonumber(state.thirst) or 0,
        fatigue = tonumber(state.fatigue) or 0,
    }
    local anyChanged = false
    for _, needType in ipairs(Definitions.TYPES) do
        local before = state[needType]
        local after = Definitions.Clamp(
            needType, before + rates[needType] * elapsedHours)
        state[needType] = after
        if before ~= after then
            anyChanged = true
            H.History(faction, needType, before, after,
                reason or "passive_increase")
            H.PublishLevelChange(faction, needType, before, after,
                reason or "passive_increase")
        end
    end
    applyMemberConsequences(faction, beforeState, state, rates, elapsedHours)
    if anyChanged then
        state.lastUpdateWorldAge = at
        H.Write(faction, state, "group_needs_update")
    end
    return true
end

function Needs.UpdateToNow(factionOrID, reason)
    local state, faction = Needs.Ensure(factionOrID)
    if not state or not faction then return false end
    local now = Utils.WorldAgeHours()
    return Needs.Update(faction,
        math.max(0, now - (tonumber(state.lastUpdateWorldAge) or now)),
        reason, state, faction)
end

return Needs
