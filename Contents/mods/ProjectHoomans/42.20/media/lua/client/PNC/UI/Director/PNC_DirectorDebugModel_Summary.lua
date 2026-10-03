-- Director and population summary rows.
PNC = PNC or {}
PNC.DirectorDebugModel = PNC.DirectorDebugModel or {}

local Model = PNC.DirectorDebugModel
local row = (Model.Internal or {}).row

local function appendDirectorRows(rows, snapshot, metrics)
    rows[#rows + 1] = row('Director', metrics.paused and 'PAUSED' or 'RUNNING',
        metrics.paused and 'warning' or 'success')
    rows[#rows + 1] = row('Registry', 'revision ' .. tostring(metrics.registryRevision or 0)
        .. (metrics.dirty and ' / dirty' or ' / saved'))
    rows[#rows + 1] = row('Population', string.format(
        'groups=%d traveling=%d active=%d actions=%d engaged=%d', metrics.groups or 0,
        metrics.traveling or 0, metrics.materialized or 0,
        metrics.activeActions or 0, metrics.engaged or 0))
    local mobileCounts = snapshot and snapshot.mobileCounts or {}
    rows[#rows + 1] = row('Mobile groups', string.format(
        'road=%d street=%d en_route=%d pending=%d',
        mobileCounts.road_roaming or 0,
        mobileCounts.street_roaming or 0,
        mobileCounts.en_route or 0,
        mobileCounts.arrival_pending or 0))
    rows[#rows + 1] = row('World', string.format(
        'locations=%d encounters=%d jobs=%d', metrics.locations or 0,
        metrics.encounters or 0, metrics.scheduledJobs or 0))
    rows[#rows + 1] = row('Director work', string.format(
        'actions=%d/%d queue=%d resolved=%d combat=%d retreat=%d casualty=%d invalidations=%d avgEncounter=%.2fms',
        metrics.actionsCompleted or 0, metrics.actionsStarted or 0,
        metrics.encountersQueued or 0, metrics.encountersResolved or 0,
        metrics.abstractCombats or 0, metrics.abstractRetreats or 0,
        metrics.casualties or 0, metrics.profileInvalidations or 0,
        metrics.averageEncounterProcessingMS or 0))
end

local function appendPopulationSummaryRows(rows, population)
    local pm = population.metrics or {}
    local resolved = population.resolved or {}
    local starter = population.starter or pm.starter or {}
    rows[#rows + 1] = row('POPULATION DIRECTOR',
        (pm.enabled and 'ENABLED' or 'DISABLED') .. ' / '
            .. (pm.paused and 'PAUSED' or 'RUNNING') .. ' / bootstrap='
            .. tostring(pm.bootstrapPhase or 'UNKNOWN'),
        pm.enabled and not pm.paused and 'success' or 'warning')
    rows[#rows + 1] = row('Population footprint', string.format(
        'players=%d activeSectors=%d', pm.players or 0, pm.activeSectors or 0))
    rows[#rows + 1] = row('Starter population', string.format(
        '%s attempts=%d settlement=%s completedAt=%.3f',
        starter.completed and 'READY' or 'PENDING',
        starter.attempts or 0, tostring(starter.settlementId or 'none'),
        starter.completedAt or 0), starter.completed and 'success' or 'warning')
    rows[#rows + 1] = row('World / population seed', tostring(
        starter.worldSeed or 'unavailable') .. ' / '
        .. tostring(starter.populationSeed or 'unavailable'))
    local starterRun = starter.lastRun or {}
    rows[#rows + 1] = row('Starter last attempt', string.format(
        'at=%.3f queried=%d discovered=%d sector=%s queued=%s reason=%s',
        starterRun.at or 0, starterRun.sectorsQueried or 0,
        starterRun.discovered or 0,
        tostring(starterRun.selectedSectorId or 'none'),
        tostring(starterRun.queued == true),
        tostring(starterRun.reason or 'none')))
    rows[#rows + 1] = row('Population groups', string.format(
        'desired=%d current=%d deficit=%d pending=%d',
        pm.desiredGroups or 0, pm.currentGroups or 0,
        pm.groupDeficit or 0, pm.pendingGroups or 0))
    rows[#rows + 1] = row('Population settlements', string.format(
        'desired=%d current=%d deficit=%d pending=%d',
        pm.desiredSettlements or 0, pm.currentSettlements or 0,
        pm.settlementDeficit or 0, pm.pendingSettlements or 0))
    rows[#rows + 1] = row('Population generation', string.format(
        'groups=%d/%d/%d settlements=%d/%d/%d npc=%d candidates=%d avg/max=%.2f/%.2fms',
        pm.groupSuccesses or 0, pm.groupAttempts or 0, pm.groupFailures or 0,
        pm.settlementSuccesses or 0, pm.settlementAttempts or 0,
        pm.settlementFailures or 0, pm.npcRecordsCreated or 0,
        pm.candidateEvaluations or 0, pm.averageProcessingMS or 0,
        pm.maxProcessingMS or 0))
    rows[#rows + 1] = row('Resolved density', string.format(
        'population=%.2f groups=%.2f settlements=%.2f recovery=%.2f/%.2f mp=%.2f',
        resolved.populationMultiplier or 0, resolved.roamingGroupMultiplier or 0,
        resolved.settlementMultiplier or 0,
        resolved.groupRegenerationMultiplier or 0,
        resolved.settlementRegenerationMultiplier or 0,
        resolved.multiplayerScaling or 0))
    rows[#rows + 1] = row('Generation bands', string.format(
        'exclude=%.0f restricted=%.0f preferred=%.0f',
        resolved.minPlayerGenerationDistance or 0,
        resolved.restrictedPlayerGenerationDistance or 0,
        resolved.preferredPlayerGenerationDistance or 0))
    local candidateMetrics = population.candidateMetrics or {}
    rows[#rows + 1] = row('Candidate discovery', string.format(
        'discovered=%d evaluated=%d rejected=%d metaQueries=%d matched=%d inspected=%d meta=%d starter=%d',
        candidateMetrics.discovered or 0,
        candidateMetrics.evaluated or 0, candidateMetrics.rejected or 0,
        candidateMetrics.metaQueries or 0, candidateMetrics.metaMatched or 0,
        candidateMetrics.metaInspected or 0,
        candidateMetrics.metaDiscovered or 0,
        candidateMetrics.starterDiscovered or 0))
    local discovery = population.selectedDiscovery or {}
    rows[#rows + 1] = row('Selected-sector discovery', string.format(
        'purpose=%s reason=%s matched=%d inspected=%d found=%d residential=%d seed=%s',
        tostring(discovery.purpose or 'not_run'),
        tostring(discovery.reason or 'not_run'), discovery.matched or 0,
        discovery.inspected or 0, discovery.found or 0,
        discovery.residential or 0, tostring(discovery.seed or 'none')))
    local store = population.store or {}
    rows[#rows + 1] = row('Population persistence', string.format(
        'revision=%d %s last=%s', store.revision or 0,
        store.dirty and 'DIRTY' or 'SAVED',
        tostring(store.lastMutationReason or 'none')))
end


Model.Internal = Model.Internal or {}
Model.Internal.appendDirectorRows = appendDirectorRows
Model.Internal.appendPopulationSummaryRows = appendPopulationSummaryRows

return Model
