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

Resolver.Queue = Resolver.Queue or {}
Resolver.QueuedIDs = Resolver.QueuedIDs or {}
Resolver.Metrics = Resolver.Metrics or { queued = 0, resolved = 0,
    deferred = 0, materializationRequired = 0,
    processingRuns = 0, totalProcessingMS = 0 }
Resolver.Metrics.processingRuns = tonumber(Resolver.Metrics.processingRuns) or 0
Resolver.Metrics.totalProcessingMS = tonumber(Resolver.Metrics.totalProcessingMS) or 0

function H.FindReport(id)
    for _, report in ipairs(Store.Registry.encounters) do
        if report.id == id then return report end
    end
end

function Resolver.Enqueue(report)
    if not report or report.abstractResolutionAllowed ~= true then return false end
    if Resolver.QueuedIDs[report.id] then return false end
    Resolver.Queue[#Resolver.Queue + 1] = { encounterId = report.id, attempts = 0 }
    Resolver.QueuedIDs[report.id] = true
    Resolver.Metrics.queued = Resolver.Metrics.queued + 1
    return true
end

return Resolver

