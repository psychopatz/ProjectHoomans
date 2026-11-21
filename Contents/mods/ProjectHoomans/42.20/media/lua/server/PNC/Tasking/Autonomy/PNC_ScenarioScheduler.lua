-- Time-of-day scenario scheduler and transition chaining driven by compiled WorkScenario IR.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ScenarioScheduler = PNC.ScenarioScheduler or {}

local Scheduler = PNC.ScenarioScheduler
local WorkScenarioRegistry = PNC.WorkScenario and PNC.WorkScenario.Registry
if not WorkScenarioRegistry and type(require) == "function" then
    WorkScenarioRegistry = require "PNC/WorkScenario/Registry"
end

Scheduler.SCENARIO_URGENCY_BOOST = 0.12

local function scenarioRegistry()
    if PNC.WorkScenario and PNC.WorkScenario.Registry then
        return PNC.WorkScenario.Registry
    end
    return WorkScenarioRegistry
end

local function worldHourNow(worldHour)
    if worldHour ~= nil then
        local h = tonumber(worldHour) or 0
        return h % 24
    end
    if type(getGameTime) == "function" then
        local gt = getGameTime()
        if gt and type(gt.getTimeOfDay) == "function" then
            return (tonumber(gt:getTimeOfDay()) or 0) % 24
        end
    end
    return 8.0
end

local function recordHasTags(record, requiredTags)
    if type(requiredTags) ~= "table" or #requiredTags == 0 then return true end
    local recTags = type(record) == "table" and record.tags or nil
    if type(recTags) ~= "table" then
        local orderKind = tostring(record and record.orderSpec and record.orderSpec.kind or "")
        for i = 1, #requiredTags do
            local tag = tostring(requiredTags[i])
            if tag == "colony" and (orderKind == "colony_home" or orderKind == "camp" or orderKind == "") then
                -- Colony/settlement NPCs satisfy default colony scenario tag unless explicitly overridden
            else
                return false
            end
        end
        return true
    end
    local tagSet = {}
    for k, v in pairs(recTags) do
        if type(k) == "number" then tagSet[tostring(v)] = true
        elseif v == true then tagSet[tostring(k)] = true end
    end
    for i = 1, #requiredTags do
        if not tagSet[tostring(requiredTags[i])] then
            return false
        end
    end
    return true
end

local function inHourWindow(hour, startHour, endHour)
    if startHour == endHour then return true end
    if startHour < endHour then
        return hour >= startHour and hour < endHour
    end
    return hour >= startHour or hour < endHour
end

---Selects active compiled WorkScenario for `record` at `worldHour` and applies secondary transitions on change.
function Scheduler.GetActiveScenario(record, worldHour, applySecondary)
    if type(record) ~= "table" then return nil end
    local reg = scenarioRegistry()
    local scenarios = reg and reg.scenarios or nil
    if type(scenarios) ~= "table" then return nil end

    local hour = worldHourNow(worldHour)
    local best = nil
    local bestWeight = -math.huge
    for id, spec in pairs(scenarios) do
        if type(spec) == "table"
            and inHourWindow(hour, tonumber(spec.startHour) or 0, tonumber(spec.endHour) or 24)
            and recordHasTags(record, spec.requiredTags)
        then
            local w = tonumber(spec.weight) or 1
            if w > bestWeight or (w == bestWeight and tostring(id) < tostring(best and best.id or "~")) then
                best = spec
                bestWeight = w
            end
        end
    end

    if applySecondary ~= false and best then
        record.runtime = type(record.runtime) == "table" and record.runtime or {}
        if record.runtime.activeScenarioId ~= best.id then
            record.runtime.previousScenarioId = record.runtime.activeScenarioId
            record.runtime.activeScenarioId = best.id
            record.runtime.nextScenarioId = best.nextScenarioId
            local secondary = PNC.SecondaryChannel
            if secondary then
                if best.animVar == "PNCPosture" and type(secondary.SetPosture) == "function" then
                    secondary.SetPosture(record, "relaxed")
                end
                if best.barkKey and type(secondary.RequestBark) == "function" then
                    secondary.RequestBark(record, best.barkKey)
                end
            end
        end
    end
    return best
end

function Scheduler.GetScenarioBoostForAd(record, adId, worldHour)
    local active = Scheduler.GetActiveScenario(record, worldHour, false)
    if active and active.adId ~= nil and tostring(active.adId) == tostring(adId) then
        return Scheduler.SCENARIO_URGENCY_BOOST, active.id
    end
    return 0, active and active.id or nil
end

return Scheduler
