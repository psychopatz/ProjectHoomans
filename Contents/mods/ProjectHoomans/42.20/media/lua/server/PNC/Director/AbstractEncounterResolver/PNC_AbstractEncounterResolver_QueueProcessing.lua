if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AbstractEncounterResolver = PNC.AbstractEncounterResolver or {}
PNC.AbstractEncounterResolverInternal =
    PNC.AbstractEncounterResolverInternal or {}

local Resolver = PNC.AbstractEncounterResolver
local H = PNC.AbstractEncounterResolverInternal
local Config = PNC.DirectorConfig
local Store = PNC.AbstractWorldStore
local Groups = PNC.AbstractGroups
local Locations = PNC.AbstractLocations
local Evaluator = PNC.AbstractEncounterEvaluator
local Combat = PNC.AbstractCombatResolver

function Resolver.ProcessBatch(_, budget)
    local startedAt = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    budget = math.max(1, math.floor(tonumber(budget) or Config.EncounterQueue.WORK_BUDGET))
    local processed = 0
    while processed < budget and #Resolver.Queue > 0 do
        local entry = table.remove(Resolver.Queue, 1)
        Resolver.QueuedIDs[entry.encounterId] = nil
        local report = H.FindReport(entry.encounterId)
        if report and (report.outcome == "QUEUED" or report.outcome == "DETECTED") then
            local resolved, reason = Resolver.Resolve(report)
            if not resolved and reason == "participant_locked"
                and entry.attempts < Config.EncounterQueue.MAX_ATTEMPTS
            then
                entry.attempts = entry.attempts + 1
                Resolver.Queue[#Resolver.Queue + 1] = entry
                Resolver.QueuedIDs[entry.encounterId] = true
                Resolver.Metrics.deferred = Resolver.Metrics.deferred + 1
            else processed = processed + 1 end
        else processed = processed + 1 end
    end
    if PNC.AbstractEncounters and PNC.AbstractEncounters.TrimHistory then
        PNC.AbstractEncounters.TrimHistory()
    end
    local finishedAt = PNC.Core and PNC.Core.Now and PNC.Core.Now() or startedAt
    Resolver.Metrics.processingRuns = Resolver.Metrics.processingRuns + 1
    Resolver.Metrics.totalProcessingMS = Resolver.Metrics.totalProcessingMS
        + math.max(0, (tonumber(finishedAt) or 0) - (tonumber(startedAt) or 0))
    return processed
end

return Resolver

