if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.NeedsScheduler = PNC.NeedsScheduler or {}

local Scheduler = PNC.NeedsScheduler
local Definitions = PNC.NeedsDefinitions
local Utils = PNC.NeedsUtils

Scheduler.LastPumpAt = Scheduler.LastPumpAt or nil
Scheduler.Profile = Scheduler.Profile or { groupUpdates = 0, individualUpdates = 0, lastDurationMs = 0 }

function Scheduler.Pump(now)
    now = tonumber(now) or (PNC.Core and PNC.Core.Now and PNC.Core.Now()) or 0
    if Scheduler.LastPumpAt and now - Scheduler.LastPumpAt < Definitions.SCHEDULER_INTERVAL_MS then return 0 end
    Scheduler.LastPumpAt = now
    local profiling = PNC.NeedsDebug and PNC.NeedsDebug.ProfilingEnabled == true
    local started = profiling and PNC.Core and PNC.Core.Now and PNC.Core.Now() or now
    local count = 0
    if PNC.Factions and PNC.Factions.List and PNC.GroupNeeds then
        for _, faction in ipairs(PNC.Factions.List()) do
            if PNC.GroupNeeds.IsGroup(faction) then
                PNC.GroupNeeds.UpdateToNow(faction, "passive_decay")
                if profiling then Scheduler.Profile.groupUpdates = Scheduler.Profile.groupUpdates + 1 end
                count = count + 1
            end
        end
    end
    if PNC.Registry and PNC.Registry.Data and PNC.IndividualNeeds then
        for _, record in pairs(PNC.Registry.Data) do
            if record.alive ~= false and PNC.IndividualNeeds.IsEligible(record) then
                PNC.IndividualNeeds.UpdateToNow(record, "passive_decay")
                if PNC.NeedSupplyBridge and PNC.NeedSupplyBridge.Evaluate then
                    PNC.NeedSupplyBridge.Evaluate(record)
                end
                if profiling then Scheduler.Profile.individualUpdates = Scheduler.Profile.individualUpdates + 1 end
                count = count + 1
            end
        end
    end
    if profiling then
        Scheduler.Profile.lastDurationMs = ((PNC.Core and PNC.Core.Now and PNC.Core.Now()) or now) - started
    end
    return count
end

function Scheduler.SimulateGroup(faction, elapsedHours)
    return PNC.GroupNeeds and PNC.GroupNeeds.Update(faction, elapsedHours, "debug_simulate_time")
end

function Scheduler.SimulateIndividual(record, elapsedHours)
    return PNC.IndividualNeeds and PNC.IndividualNeeds.Update(record, elapsedHours, "debug_simulate_time")
end

return Scheduler
