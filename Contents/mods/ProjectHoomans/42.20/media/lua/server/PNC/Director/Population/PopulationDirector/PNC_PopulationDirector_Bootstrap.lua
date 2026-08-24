if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PopulationDirector = PNC.PopulationDirector or {}
PNC.PopulationDirector.Internal =
    PNC.PopulationDirector.Internal or {}

local Director = PNC.PopulationDirector
local Internal = Director.Internal
local Config = PNC.DirectorConfig.Population
local Queue = PNC.GenerationQueue
local Scheduler = PNC.Scheduler
local Log = PNC.PopulationLog
local Starter = PNC.StarterPopulation
local refresh = Internal.refresh
local reconcile = Internal.reconcile

local function bootstrap(now, budget)
    refresh(now)
    if Director.BootstrapPhase == "WAITING_DRY" then
        local groupCursor = PNC.PopulationReconciler.Cursors.GROUP
        local settlementCursor = PNC.PopulationReconciler.Cursors.SETTLEMENT
        local processed = reconcile("GROUP", now, budget, true)
            + reconcile("SETTLEMENT", now, budget, true)
        -- The live bootstrap pass must revisit exactly what the dry pass
        -- diagnosed instead of advancing to a disjoint rotating batch.
        PNC.PopulationReconciler.Cursors.GROUP = groupCursor
        PNC.PopulationReconciler.Cursors.SETTLEMENT = settlementCursor
        Director.DryRunPending = { GROUP = false, SETTLEMENT = false }
        Director.BootstrapPhase = "WAITING_GENERATION"
        Log.Info("BOOTSTRAP_DRY_RECONCILIATION", { processed = processed,
            nextInHours = Config.BOOTSTRAP_RECONCILE_DELAY_HOURS })
        return processed
    end
    if Starter and Starter.IsPending and Starter.IsPending() then
        Starter.Run(now)
    end
    local processed = reconcile("GROUP", now, budget, false)
        + reconcile("SETTLEMENT", now, budget, false)
    Director.BootstrapPhase = "COMPLETE"
    Scheduler.SetJobEnabled("PopulationBootstrapReconciliation", false)
    Log.Info("BOOTSTRAP_GENERATION_RECONCILIATION", { processed = processed,
        pendingGroups = Queue.Count("GROUP"),
        pendingSettlements = Queue.Count("SETTLEMENT") })
    return processed
end

Internal.bootstrap = bootstrap
