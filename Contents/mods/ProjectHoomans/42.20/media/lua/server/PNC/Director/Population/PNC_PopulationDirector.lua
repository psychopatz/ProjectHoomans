-- Population orchestration entry: jobs, budgets, queues, and metrics.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PopulationDirector = PNC.PopulationDirector or {}
PNC.PopulationDirector.Internal =
    PNC.PopulationDirector.Internal or {}

local Director = PNC.PopulationDirector
Director.Initialized = Director.Initialized or false
Director.Paused = Director.Paused or false
Director.StartupGraceUntil = Director.StartupGraceUntil or 0
Director.DryRunPending =
    Director.DryRunPending or { GROUP = true, SETTLEMENT = true }
Director.BootstrapPhase =
    Director.BootstrapPhase or "WAITING_DRY"
Director.LastResolved = Director.LastResolved or nil
Director.Metrics = Director.Metrics or {
    queueRuns = 0,
    queueFailures = 0,
    queueSuccesses = 0,
    npcRecordsCreated = 0,
    processingRuns = 0,
    totalProcessingMS = 0,
    maxProcessingMS = 0,
}
Director.RateHistory =
    Director.RateHistory or { GROUP = {}, SETTLEMENT = {} }
Director.NextStarterRuntimeProbeAt =
    Director.NextStarterRuntimeProbeAt or 0

require "PNC/Director/Population/PopulationDirector/PNC_PopulationDirector_Context"
require "PNC/Director/Population/PopulationDirector/PNC_PopulationDirector_Reconciliation"
require "PNC/Director/Population/PopulationDirector/PNC_PopulationDirector_QueueProcessing"
require "PNC/Director/Population/PopulationDirector/PNC_PopulationDirector_Bootstrap"
require "PNC/Director/Population/PopulationDirector/PNC_PopulationDirector_Initialization"
require "PNC/Director/Population/PopulationDirector/PNC_PopulationDirector_API"
require "PNC/Director/Population/PopulationDirector/PNC_PopulationDirector_Lifecycle"

return Director
