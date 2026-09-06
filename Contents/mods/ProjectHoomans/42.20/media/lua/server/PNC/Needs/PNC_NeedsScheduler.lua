if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NeedsScheduler = PNC.NeedsScheduler or {}

local Scheduler = PNC.NeedsScheduler
local Definitions = PNC.NeedsDefinitions
local Utils = PNC.NeedsUtils
local ScalingDiagnostics = PNC.PerformanceScalingDiagnostics

Scheduler.LastPumpAt = Scheduler.LastPumpAt or nil
Scheduler.Profile = Scheduler.Profile or { groupUpdates = 0, individualUpdates = 0, lastDurationMs = 0 }
Scheduler.IndividualIDs = Scheduler.IndividualIDs or {}
Scheduler.IndividualCursor = Scheduler.IndividualCursor or 1
Scheduler.NextCycleAt = Scheduler.NextCycleAt or 0
Scheduler.CycleActive = Scheduler.CycleActive == true

local function clockNow(fallback)
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return tonumber(PNC.Core.Now()) or fallback
    end
    return fallback
end

local function sliceExhausted(startedAt, processed)
    if processed >= (tonumber(Definitions.SCHEDULER_BATCH_SIZE) or 1) then
        return true
    end
    local budget = math.max(
        1,
        tonumber(Definitions.SCHEDULER_TIME_BUDGET_MS) or 2
    )
    return clockNow(startedAt) - startedAt >= budget
end

local function refreshIndividuals()
    Scheduler.IndividualIDs = {}
    for id, record in pairs(PNC.Registry and PNC.Registry.Data or {}) do
        if record.alive ~= false and PNC.IndividualNeeds.IsEligible(record) then
            Scheduler.IndividualIDs[#Scheduler.IndividualIDs + 1] = tostring(id)
        end
    end
    table.sort(Scheduler.IndividualIDs)
    Scheduler.IndividualCursor = 1
end

function Scheduler.Pump(now)
    now = tonumber(now) or (PNC.Core and PNC.Core.Now and PNC.Core.Now()) or 0
    local cycleStarted = false
    if Scheduler.CycleActive ~= true then
        if now < (tonumber(Scheduler.NextCycleAt) or 0) then return 0 end
        Scheduler.CycleActive = true
        Scheduler.LastPumpAt = now
        Scheduler.NextCycleAt = now + Definitions.SCHEDULER_INTERVAL_MS
        refreshIndividuals()
        cycleStarted = true
    end
    local timerName
    local timerStart
    if ScalingDiagnostics then
        timerName, timerStart = ScalingDiagnostics.BeginTiming(
            "Needs.Pump", now)
        ScalingDiagnostics.Increment("Needs.PumpCalls")
    end
    local profiling = PNC.NeedsDebug and PNC.NeedsDebug.ProfilingEnabled == true
    local started = profiling and PNC.Core and PNC.Core.Now and PNC.Core.Now() or now
    local count = 0
    local individualUpdated = 0
    local groupTimerName
    local groupTimerStart
    if cycleStarted and ScalingDiagnostics then
        groupTimerName, groupTimerStart = ScalingDiagnostics.BeginTiming(
            "Needs.Groups", now)
    end
    if cycleStarted and PNC.Factions and PNC.Factions.List and PNC.GroupNeeds then
        for _, faction in ipairs(PNC.Factions.List()) do
            if PNC.GroupNeeds.IsGroup(faction) then
                PNC.GroupNeeds.UpdateToNow(faction, "passive_decay")
                if profiling then Scheduler.Profile.groupUpdates = Scheduler.Profile.groupUpdates + 1 end
                count = count + 1
            end
        end
    end
    if groupTimerName then
        ScalingDiagnostics.EndTiming(groupTimerName, groupTimerStart)
    end

    local individualTimerName
    local individualTimerStart
    if ScalingDiagnostics then
        individualTimerName, individualTimerStart =
            ScalingDiagnostics.BeginTiming("Needs.Individuals", now)
    end
    if PNC.Registry and PNC.Registry.Data and PNC.IndividualNeeds then
        local processed = 0
        local sliceStartedAt = clockNow(now)
        while Scheduler.IndividualCursor <= #Scheduler.IndividualIDs do
            local id = Scheduler.IndividualIDs[Scheduler.IndividualCursor]
            Scheduler.IndividualCursor = Scheduler.IndividualCursor + 1
            processed = processed + 1
            local record = PNC.Registry.Data[id]
            if record and record.alive ~= false
                and PNC.IndividualNeeds.IsEligible(record) then
                PNC.IndividualNeeds.UpdateToNow(record, "passive_decay")
                if PNC.ConditionStats then
                    local at = Utils.WorldAgeHours()
                    local condition = PNC.ConditionStats.Ensure(record, at)
                    local elapsed = math.max(0, at
                        - (tonumber(condition.lastUpdateWorldAge) or at))
                    PNC.ConditionStats.Update(record, elapsed,
                        PNC.IndividualNeeds.GetActivity(record), at)
                    if elapsed > 0 and PNC.Registry.MarkDirty then
                        PNC.Registry.MarkDirty(record,
                            "condition_stats_update")
                    end
                end
                if PNC.NeedSupplyBridge and PNC.NeedSupplyBridge.Evaluate then
                    PNC.NeedSupplyBridge.Evaluate(record)
                end
                if PNC.NeedFacilityTriggers then
                    if PNC.NeedFacilityTriggers.WakeActionable then
                        PNC.NeedFacilityTriggers.WakeActionable(record)
                    else
                        PNC.NeedFacilityTriggers.PreferFacility(
                            record, "health")
                        PNC.NeedFacilityTriggers.PreferFacility(
                            record, "recreation")
                    end
                end
                if profiling then Scheduler.Profile.individualUpdates = Scheduler.Profile.individualUpdates + 1 end
                count = count + 1
                individualUpdated = individualUpdated + 1
            end
            if sliceExhausted(sliceStartedAt, processed) then break end
        end
        if ScalingDiagnostics then
            ScalingDiagnostics.Increment(
                "Needs.IndividualsInspected", processed)
        end
    end
    if individualTimerName then
        ScalingDiagnostics.EndTiming(individualTimerName, individualTimerStart)
    end
    if profiling then
        Scheduler.Profile.lastDurationMs = ((PNC.Core and PNC.Core.Now and PNC.Core.Now()) or now) - started
    end
    if ScalingDiagnostics then
        ScalingDiagnostics.Increment(
            "Needs.IndividualsUpdated", individualUpdated)
    end
    if Scheduler.CycleActive == true
        and Scheduler.IndividualCursor > #Scheduler.IndividualIDs
    then
        Scheduler.CycleActive = false
        if Scheduler.NextCycleAt <= now then
            Scheduler.NextCycleAt = now + Definitions.SCHEDULER_INTERVAL_MS
        end
    end
    if timerName then ScalingDiagnostics.EndTiming(timerName, timerStart) end
    return count
end

function Scheduler.SimulateGroup(faction, elapsedHours)
    return PNC.GroupNeeds and PNC.GroupNeeds.Update(faction, elapsedHours, "debug_simulate_time")
end

function Scheduler.SimulateIndividual(record, elapsedHours)
    local updated = PNC.IndividualNeeds and PNC.IndividualNeeds.Update(
        record, elapsedHours, "debug_simulate_time")
    if updated and PNC.ConditionStats then
        PNC.ConditionStats.Update(record, elapsedHours,
            PNC.IndividualNeeds.GetActivity(record), Utils.WorldAgeHours())
    end
    return updated
end

return Scheduler
