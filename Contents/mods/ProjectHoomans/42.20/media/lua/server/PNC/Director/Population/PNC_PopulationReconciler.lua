-- Turns advisory deficits into at most one deduplicated request per sector/type.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PopulationReconciler = PNC.PopulationReconciler or {}

local Reconciler = PNC.PopulationReconciler
local Sectors = PNC.PopulationSectors
local Queue = PNC.GenerationQueue
local Store = PNC.AbstractWorldStore

Reconciler.Cursors = Reconciler.Cursors or { GROUP = 1, SETTLEMENT = 1 }
Reconciler.Metrics = Reconciler.Metrics or { runs = 0, sectorsProcessed = 0,
    deficits = 0, queued = 0 }

function Reconciler.Run(kind, now, budget, context, dryRun)
    kind = tostring(kind or "GROUP")
    local sectors = Sectors.ListRelevant()
    if #sectors == 0 then return 0 end
    budget = math.max(1, math.floor(tonumber(budget) or 1))
    local cursor = math.max(1, math.min(#sectors, Reconciler.Cursors[kind] or 1))
    local processed = 0
    while processed < budget and processed < #sectors do
        local sector = sectors[cursor]
        local populationBudget = PNC.PopulationBudget.Calculate(sector, context)
        local values = kind == "SETTLEMENT"
            and populationBudget.settlements or populationBudget.groups
        local state = Sectors.Ensure(sector.id)
        state.lastReconciledAt = now
        if values.deficit > 0 then
            Reconciler.Metrics.deficits = Reconciler.Metrics.deficits + 1
            Store.Emit("POPULATION_DEFICIT_DETECTED", { sectorId = sector.id,
                kind = kind, deficit = values.deficit })
            local cooldown = kind == "SETTLEMENT"
                and state.settlementGenerationCooldownUntil
                or state.groupGenerationCooldownUntil
            local resolved = context.resolved
            local hadPopulation = kind == "SETTLEMENT"
                and state.hadSettlements or state.hadGroups
            local recoveryEnabled = kind == "SETTLEMENT"
                and resolved.settlementRegenerationEnabled
                or resolved.groupRegenerationEnabled
            local reason
            if dryRun then reason = "STARTUP_DRY_RECONCILIATION"
            elseif now < (tonumber(cooldown) or 0) then reason = "GENERATION_COOLDOWN"
            elseif hadPopulation and not recoveryEnabled then reason = "REGENERATION_DISABLED"
            elseif Queue.CountForSector(kind, sector.id) >= values.deficit then
                reason = "ALREADY_PENDING"
            else
                local priority = math.max(0, 1 - math.min(1, values.pressure))
                    + (sector.active and 0.5 or 0)
                    + math.max(0, 1 - PNC.PopulationBudget.NeighborPressure(
                        sector.id, kind)) * 0.2
                local ok, queueReason = Queue.Enqueue(kind, {
                    sectorId = sector.id, priority = priority,
                    source = "WORLD_POPULATION_DIRECTOR" }, now)
                if ok then
                    Reconciler.Metrics.queued = Reconciler.Metrics.queued + 1
                    Store.Emit(kind .. "_GENERATION_QUEUED", {
                        sectorId = sector.id, deficit = values.deficit })
                    if PNC.PopulationLog and PNC.PopulationLog.Info then
                        PNC.PopulationLog.Info("GENERATION_QUEUED", {
                            kind = kind, sectorId = sector.id,
                            deficit = values.deficit,
                            desired = values.desired,
                            current = values.current,
                            priority = priority })
                    end
                    reason = "QUEUED"
                else reason = string.upper(tostring(queueReason)) end
            end
            Sectors.SetSuppression(sector.id, kind, reason)
        else
            Sectors.SetSuppression(sector.id, kind, "NO_DEFICIT")
        end
        processed = processed + 1
        cursor = cursor % #sectors + 1
    end
    Reconciler.Cursors[kind] = cursor
    Reconciler.Metrics.runs = Reconciler.Metrics.runs + 1
    Reconciler.Metrics.sectorsProcessed = Reconciler.Metrics.sectorsProcessed + processed
    Store.Touch("population_reconciled")
    return processed
end

return Reconciler
