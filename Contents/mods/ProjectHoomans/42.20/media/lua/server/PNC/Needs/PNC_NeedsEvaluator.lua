if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NeedsEvaluator = PNC.NeedsEvaluator or {}

local Evaluator = PNC.NeedsEvaluator
local Modifiers = PNC.MoraleModifierDefinitions
Evaluator.Commands = Evaluator.Commands or {}
Evaluator.Queries = Evaluator.Queries or {}

local function state(record)
    local value = PNC.NeedsRepository.Get(record, true)
    value.morale = value.morale or { conditions = {} }
    value.morale.conditions = value.morale.conditions or {}
    return value.morale
end

local function invalidate(record)
    record.runtime = record.runtime or {}
    record.runtime.needs = record.runtime.needs or { cachedLevels = {} }
    record.runtime.needs.moraleRevision =
        (tonumber(record.runtime.needs.moraleRevision) or 0) + 1
    record.runtime.needs.moraleCache = nil
    PNC.NeedsRepository.MarkDirty()
end

function Evaluator.Commands.SetCondition(record, modifierId, value, reason)
    local definition = Modifiers.Get(modifierId)
    if not record or not definition then return false, "UNKNOWN_MORALE_MODIFIER" end
    value = math.max(-1, math.min(1, tonumber(value) or 0))
    local morale = state(record)
    local previous = morale.conditions[definition.id]
    if value == 0 then
        if previous then morale.conditions[definition.id] = nil; invalidate(record) end
        return true, "CONDITION_RESOLVED"
    end
    local days = previous and tonumber(previous.days) or 0
    morale.conditions[definition.id] = {
        value = value, days = math.max(0, math.floor(days)),
        reason = reason and tostring(reason) or nil,
    }
    if not previous or previous.value ~= value then invalidate(record) end
    return true, morale.conditions[definition.id]
end

function Evaluator.Commands.AdvanceDay(record, worldAgeHours)
    local morale = state(record)
    local day = math.max(0, math.floor((tonumber(worldAgeHours) or 0) / 24))
    local previous = tonumber(morale.lastDay)
    morale.lastDay = day
    if previous == nil or day <= previous then return false end
    local elapsed = math.min(30, day - previous)
    local changed = false
    for id, condition in pairs(morale.conditions) do
        local definition = Modifiers.Get(id)
        if definition and definition.worsenPerDay > 0
            and tonumber(condition.value) < 0
        then
            condition.days = math.max(0,
                math.floor(tonumber(condition.days) or 0) + elapsed)
            changed = true
        end
    end
    if changed then invalidate(record) else PNC.NeedsRepository.MarkDirty() end
    return changed
end

local function syncKnownConditions(record)
    local runtime = record.runtime or {}
    local hasHome = tostring(runtime.homeBaseId or "") ~= ""
    Evaluator.Commands.SetCondition(record, "housing",
        hasHome and 0.12 or -0.20, hasHome and "HAS_HOME" or "NO_HOME")
    local enabled, configured = false, false
    for _, value in pairs(record.allowedJobs or {}) do
        configured = true
        if value ~= false then enabled = true; break end
    end
    if not configured then enabled = true end
    Evaluator.Commands.SetCondition(record, "employment",
        enabled and 0.06 or -0.10,
        enabled and "HAS_ELIGIBLE_WORK" or "NO_ELIGIBLE_WORK")
    local unsafe = record.health and record.health.state == "incapacitated"
    Evaluator.Commands.SetCondition(record, "safety",
        unsafe and -0.25 or 0, unsafe and "INCAPACITATED" or "SAFE")
end

function Evaluator.Commands.Reconcile(record, worldAgeHours)
    if not record then return false, "NPC_UNAVAILABLE" end
    syncKnownConditions(record)
    Evaluator.Commands.AdvanceDay(record, worldAgeHours)
    return true
end

function Evaluator.Queries.BuildView(record)
    if not record then return { score = 50, modifiers = {} } end
    local needsRuntime = record.runtime and record.runtime.needs or {}
    local revision = tonumber(needsRuntime.moraleRevision) or 0
    local cached = needsRuntime.moraleCache
    if cached and cached.revision == revision then
        return PNC.Core.DeepCopy(cached.view)
    end
    local rows, totalWeight, total = {}, 0, 0
    local morale = state(record)
    for _, definition in ipairs(Modifiers.List()) do
        local condition = morale.conditions[definition.id]
        if condition then
            local value = tonumber(condition.value) or 0
            if value < 0 then
                value = math.max(-1, value
                    - definition.worsenPerDay * (tonumber(condition.days) or 0))
            end
            local contribution = value * definition.weight
            total, totalWeight = total + contribution,
                totalWeight + definition.weight
            rows[#rows + 1] = {
                id = definition.id, translationKey = definition.translationKey,
                iconKey = definition.iconKey, value = value,
                days = tonumber(condition.days) or 0,
                contribution = contribution,
            }
        end
    end
    local normalized = totalWeight > 0 and total / totalWeight or 0
    local view = { score = math.floor(math.max(0, math.min(100,
        50 + normalized * 50)) + 0.5), modifiers = rows }
    needsRuntime.moraleCache = { revision = revision,
        view = PNC.Core.DeepCopy(view) }
    return view
end

function Evaluator.Queries.BuildNeedsView(record)
    local rows = {}
    for _, definition in ipairs(PNC.NeedsDefinitions.List()) do
        local value = tonumber(PNC.IndividualNeeds.Get(record, definition.id))
            or definition.default
        rows[#rows + 1] = {
            id = definition.id, translationKey = definition.translationKey,
            iconKey = definition.iconKey, format = definition.format,
            value = value,
            severity = PNC.NeedsDefinitions.GetLevel(definition.id, value),
        }
    end
    return rows
end

return Evaluator
