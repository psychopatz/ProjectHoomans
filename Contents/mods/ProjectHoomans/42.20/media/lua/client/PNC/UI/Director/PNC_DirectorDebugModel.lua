PNC = PNC or {}
PNC.DirectorDebugModel = PNC.DirectorDebugModel or {}

local Model = PNC.DirectorDebugModel

local function row(label, value, tone)
    return { label = tostring(label or ""),
        value = tostring(value == nil and "" or value), tone = tone }
end

function Model.GroupItems(snapshot)
    local output = {}
    for _, group in ipairs(snapshot and snapshot.groups or {}) do
        output[#output + 1] = { id = group.id, value = group,
            label = group.groupType .. " / " .. group.id,
            detail = group.mission .. " + " .. group.state }
    end
    return output
end

function Model.LocationItems(snapshot)
    local output = {}
    for _, location in ipairs(snapshot and snapshot.locations or {}) do
        output[#output + 1] = { id = location.id, value = location,
            label = location.type .. " / " .. location.id,
            detail = string.format("%.0f, %.0f | groups %d",
                location.x or 0, location.y or 0,
                #(location.occupantGroupIds or {})) }
    end
    return output
end

function Model.SectorItems(snapshot)
    local output = {}
    for _, sector in ipairs(snapshot and snapshot.population
        and snapshot.population.sectors or {}) do
        output[#output + 1] = { id = sector.id, value = sector,
            label = (sector.active and "ACTIVE / " or "SECTOR / ") .. sector.id,
            detail = string.format("G %d/%d  S %d/%d  sites %d",
                sector.groupCount or 0, sector.desiredGroups or 0,
                sector.settlementCount or 0, sector.desiredSettlements or 0,
                sector.candidatePool or 0) }
    end
    return output
end


function Model.DetailRows(snapshot, group, location, sector, authorized, reason)
    local rows, metrics = {}, snapshot and snapshot.metrics or {}
    if authorized ~= true then return { row("Authorization", reason, "danger") } end
    rows[#rows + 1] = row("Director", metrics.paused and "PAUSED" or "RUNNING",
        metrics.paused and "warning" or "success")
    rows[#rows + 1] = row("Registry", "revision " .. tostring(metrics.registryRevision or 0)
        .. (metrics.dirty and " / dirty" or " / saved"))
    rows[#rows + 1] = row("Population", string.format(
        "groups=%d traveling=%d active=%d actions=%d engaged=%d", metrics.groups or 0,
        metrics.traveling or 0, metrics.materialized or 0,
        metrics.activeActions or 0, metrics.engaged or 0))
    rows[#rows + 1] = row("World", string.format(
        "locations=%d encounters=%d jobs=%d", metrics.locations or 0,
        metrics.encounters or 0, metrics.scheduledJobs or 0))
    rows[#rows + 1] = row("Director work", string.format(
        "actions=%d/%d queue=%d resolved=%d combat=%d retreat=%d casualty=%d invalidations=%d avgEncounter=%.2fms",
        metrics.actionsCompleted or 0, metrics.actionsStarted or 0,
        metrics.encountersQueued or 0, metrics.encountersResolved or 0,
        metrics.abstractCombats or 0, metrics.abstractRetreats or 0,
        metrics.casualties or 0, metrics.profileInvalidations or 0,
        metrics.averageEncounterProcessingMS or 0))
    local population = snapshot and snapshot.population or {}
    local pm = population.metrics or {}
    local resolved = population.resolved or {}
    local starter = population.starter or pm.starter or {}
    rows[#rows + 1] = row("POPULATION DIRECTOR",
        (pm.enabled and "ENABLED" or "DISABLED") .. " / "
            .. (pm.paused and "PAUSED" or "RUNNING") .. " / bootstrap="
            .. tostring(pm.bootstrapPhase or "UNKNOWN"),
        pm.enabled and not pm.paused and "success" or "warning")
    rows[#rows + 1] = row("Population footprint", string.format(
        "players=%d activeSectors=%d", pm.players or 0, pm.activeSectors or 0))
    rows[#rows + 1] = row("Starter population", string.format(
        "%s attempts=%d settlement=%s completedAt=%.3f",
        starter.completed and "READY" or "PENDING",
        starter.attempts or 0, tostring(starter.settlementId or "none"),
        starter.completedAt or 0), starter.completed and "success" or "warning")
    rows[#rows + 1] = row("World / population seed", tostring(
        starter.worldSeed or "unavailable") .. " / "
        .. tostring(starter.populationSeed or "unavailable"))
    local starterRun = starter.lastRun or {}
    rows[#rows + 1] = row("Starter last attempt", string.format(
        "at=%.3f queried=%d discovered=%d sector=%s queued=%s reason=%s",
        starterRun.at or 0, starterRun.sectorsQueried or 0,
        starterRun.discovered or 0,
        tostring(starterRun.selectedSectorId or "none"),
        tostring(starterRun.queued == true),
        tostring(starterRun.reason or "none")))
    rows[#rows + 1] = row("Population groups", string.format(
        "desired=%d current=%d deficit=%d pending=%d",
        pm.desiredGroups or 0, pm.currentGroups or 0,
        pm.groupDeficit or 0, pm.pendingGroups or 0))
    rows[#rows + 1] = row("Population settlements", string.format(
        "desired=%d current=%d deficit=%d pending=%d",
        pm.desiredSettlements or 0, pm.currentSettlements or 0,
        pm.settlementDeficit or 0, pm.pendingSettlements or 0))
    rows[#rows + 1] = row("Population generation", string.format(
        "groups=%d/%d/%d settlements=%d/%d/%d npc=%d candidates=%d avg/max=%.2f/%.2fms",
        pm.groupSuccesses or 0, pm.groupAttempts or 0, pm.groupFailures or 0,
        pm.settlementSuccesses or 0, pm.settlementAttempts or 0,
        pm.settlementFailures or 0, pm.npcRecordsCreated or 0,
        pm.candidateEvaluations or 0, pm.averageProcessingMS or 0,
        pm.maxProcessingMS or 0))
    rows[#rows + 1] = row("Resolved density", string.format(
        "population=%.2f groups=%.2f settlements=%.2f recovery=%.2f/%.2f mp=%.2f",
        resolved.populationMultiplier or 0, resolved.roamingGroupMultiplier or 0,
        resolved.settlementMultiplier or 0,
        resolved.groupRegenerationMultiplier or 0,
        resolved.settlementRegenerationMultiplier or 0,
        resolved.multiplayerScaling or 0))
    rows[#rows + 1] = row("Generation bands", string.format(
        "exclude=%.0f restricted=%.0f preferred=%.0f",
        resolved.minPlayerGenerationDistance or 0,
        resolved.restrictedPlayerGenerationDistance or 0,
        resolved.preferredPlayerGenerationDistance or 0))
    local candidateMetrics = population.candidateMetrics or {}
    rows[#rows + 1] = row("Candidate discovery", string.format(
        "discovered=%d evaluated=%d rejected=%d metaQueries=%d matched=%d inspected=%d meta=%d starter=%d",
        candidateMetrics.discovered or 0,
        candidateMetrics.evaluated or 0, candidateMetrics.rejected or 0,
        candidateMetrics.metaQueries or 0, candidateMetrics.metaMatched or 0,
        candidateMetrics.metaInspected or 0,
        candidateMetrics.metaDiscovered or 0,
        candidateMetrics.starterDiscovered or 0))
    local discovery = population.selectedDiscovery or {}
    rows[#rows + 1] = row("Selected-sector discovery", string.format(
        "purpose=%s reason=%s matched=%d inspected=%d found=%d residential=%d seed=%s",
        tostring(discovery.purpose or "not_run"),
        tostring(discovery.reason or "not_run"), discovery.matched or 0,
        discovery.inspected or 0, discovery.found or 0,
        discovery.residential or 0, tostring(discovery.seed or "none")))
    local store = population.store or {}
    rows[#rows + 1] = row("Population persistence", string.format(
        "revision=%d %s last=%s", store.revision or 0,
        store.dirty and "DIRTY" or "SAVED",
        tostring(store.lastMutationReason or "none")))
    if sector then
        rows[#rows + 1] = row("SELECTED SECTOR", sector.id)
        rows[#rows + 1] = row("Sector state", string.format(
            "active=%s relevant=%s discovered=%s players=%d survivors=%d sites=%d",
            tostring(sector.active == true), tostring(sector.relevant == true),
            tostring(sector.discovered == true), sector.nearbyPlayers or 0,
            sector.survivorCount or 0, sector.candidatePool or 0))
        rows[#rows + 1] = row("Sector pending / cooldown", string.format(
            "groups=%d/%.2fh settlements=%d/%.2fh",
            sector.pendingGroups or 0, sector.groupCooldownRemaining or 0,
            sector.pendingSettlements or 0,
            sector.settlementCooldownRemaining or 0))
        rows[#rows + 1] = row("Sector suppression", tostring(
            sector.groupSuppressionReason or "NONE") .. " / "
            .. tostring(sector.settlementSuppressionReason or "NONE"))
    end
    for _, sector in ipairs(population.sectors or {}) do
        rows[#rows + 1] = row("SECTOR " .. sector.id, string.format(
            "active=%s players=%d groups=%d/%d p=%.2f settlements=%d/%d p=%.2f suppress=%s/%s",
            tostring(sector.active == true), sector.nearbyPlayers or 0,
            sector.groupCount or 0, sector.desiredGroups or 0,
            sector.groupPressure or 1, sector.settlementCount or 0,
            sector.desiredSettlements or 0, sector.settlementPressure or 1,
            tostring(sector.groupSuppressionReason or "NONE"),
            tostring(sector.settlementSuppressionReason or "NONE")))
    end
    for _, candidate in ipairs(population.candidateEvaluations or {}) do
        local componentText = {}
        for name, value in pairs(candidate.components or {}) do
            componentText[#componentText + 1] = tostring(name) .. "="
                .. string.format("%.1f", tonumber(value) or 0)
        end
        table.sort(componentText)
        rows[#rows + 1] = row("CANDIDATE " .. tostring(candidate.locationId),
            candidate.eligible and ("score=" .. string.format("%.1f", candidate.score or 0)
                .. " " .. table.concat(componentText, " "))
                or ("REJECTED " .. tostring(candidate.reason)),
            candidate.eligible and "success" or "warning")
    end
    for _, item in ipairs(population.queue or {}) do
        rows[#rows + 1] = row("QUEUE " .. tostring(item.kind), string.format(
            "%s priority=%.2f attempts=%d expires=%.2fh source=%s",
            tostring(item.sectorId), item.priority or 0, item.attempts or 0,
            item.remainingHours or 0, tostring(item.source or "unknown")),
            item.source == "WORLD_POPULATION_BOOTSTRAP"
                and "warning" or "textMuted")
    end
    for _, reservation in ipairs(population.reservations or {}) do
        rows[#rows + 1] = row("SITE RESERVATION",
            tostring(reservation.locationId) .. " / "
                .. tostring(reservation.generationId) .. " / "
                .. string.format("%.2fh", reservation.remainingHours or 0),
            "textMuted")
    end
    local history = population.history or {}
    for index = math.max(1, #history - 7), #history do
        local entry = history[index]
        if entry then rows[#rows + 1] = row("POP HISTORY", tostring(entry.event)
            .. " / " .. tostring(entry.sectorId or "") .. " / "
            .. tostring(entry.reason or entry.generationId or ""), "textMuted") end
    end
    local populationLog = population.log or {}
    for index = math.max(1, #populationLog - 9), #populationLog do
        local entry = populationLog[index]
        if entry then
            local fields = {}
            for key, value in pairs(entry.fields or {}) do
                fields[#fields + 1] = tostring(key) .. "=" .. tostring(value)
            end
            table.sort(fields)
            rows[#rows + 1] = row("POP LOG " .. tostring(entry.level or "INFO"),
                string.format("%.3f %s %s", tonumber(entry.at) or 0,
                    tostring(entry.event), table.concat(fields, " ")),
                entry.level == "WARN" and "warning" or "textMuted")
        end
    end
    if snapshot and snapshot.action then
        rows[#rows + 1] = row("Last action",
            tostring(snapshot.action.action) .. ": " .. tostring(snapshot.action.reason),
            snapshot.action.ok and "success" or "danger")
    end
    if group then
        rows[#rows + 1] = row("GROUP", group.id)
        rows[#rows + 1] = row("Faction / home", tostring(group.factionId)
            .. " / " .. tostring(group.homeCommunityId or "independent"))
        rows[#rows + 1] = row("Type", group.groupType)
        rows[#rows + 1] = row("Members / leader", tostring(#(group.memberIds or {}))
            .. " / " .. tostring(group.leaderId or "none"))
        rows[#rows + 1] = row("Mission + state", group.mission .. " + " .. group.state)
        local action = group.action
        rows[#rows + 1] = row("Current action", action and string.format(
            "%s @ %s / %.3f -> %.3f / seed %s", action.type,
            action.locationId, action.startedAt or 0, action.endsAt or 0,
            tostring(action.seed)) or "none")
        rows[#rows + 1] = row("Current location", group.location and group.location.id or "none")
        rows[#rows + 1] = row("Target", group.targetLocation and group.targetLocation.id or "none")
        rows[#rows + 1] = row("State time", string.format("%.3f -> %.3f",
            group.stateStartedAt or 0, group.stateEndsAt or 0))
        local needs = group.needs or {}
        rows[#rows + 1] = row("Needs H/W/R", string.format("%.1f / %.1f / %.1f",
            needs.hunger or 0, needs.hydration or 0, needs.fatigue or 0))
        local shortages = group.resourceNeeds or {}
        rows[#rows + 1] = row("Shortage F/W/A/Med/Mat", string.format(
            "%.2f / %.2f / %.2f / %.2f / %.2f", shortages.food or 0,
            shortages.water or 0, shortages.ammo or 0,
            shortages.medical or 0, shortages.materials or 0))
        local resources = group.resources or {}
        rows[#rows + 1] = row("Resources F/W/A/M", string.format("%.0f / %.0f / %.0f / %.0f",
            resources.food or 0, resources.water or 0, resources.ammo or 0,
            resources.medical or 0))
        rows[#rows + 1] = row("Morale / desperation", string.format("%.2f / %.2f",
            group.morale or 0, group.desperation or 0))
        local behavior = group.behaviorProfile or {}
        rows[#rows + 1] = row("Behavior A/B/G/C/M/D", string.format(
            "%.2f / %.2f / %.2f / %.2f / %.2f / %.2f",
            behavior.aggression or 0, behavior.bravery or 0,
            behavior.greed or 0, behavior.caution or 0,
            behavior.mercy or 0, behavior.discipline or 0))
        rows[#rows + 1] = row("Encounter active / recent",
            tostring(group.activeEncounterId or "none") .. " / "
                .. tostring(group.recentEncounterId or "none"))
        rows[#rows + 1] = row("Combat cache",
            (group.combatProfileDirty and "DIRTY" or "CACHED") .. " / "
                .. tostring(group.combatProfileCacheState or group.combatProfileReason or "none"),
            group.combatProfileDirty and "warning" or "success")
        local profile = group.combatProfile
        if profile then
            for _, field in ipairs({ "memberCount", "combatantCount", "manpower",
                "meleePower", "rangedPower", "defense", "mobility", "morale",
                "experience", "medical", "ammoState", "condition", "overallPower" }) do
                rows[#rows + 1] = row("Combat " .. field,
                    string.format("%.2f", tonumber(profile[field]) or 0))
            end
        end
        for _, evaluation in ipairs(group.destinationEvaluations or {}) do
            local c = evaluation.components or {}
            rows[#rows + 1] = row("SCORE " .. evaluation.locationId,
                string.format("%.1f = res %.1f tag %.1f mission %.1f unvisited %.1f distance %.1f danger %.1f scavenged %.1f",
                    c.final or 0, c.resources or 0, c.tags or 0, c.mission or 0,
                    c.unvisited or 0, c.distance or 0, c.danger or 0,
                    c.scavenged or 0))
        end
        local scavenge = group.lastScavenge
        if scavenge then
            rows[#rows + 1] = row("SCAVENGE", string.format(
                "depletion %.2f -> %.2f / total +%.0f / seed %s",
                scavenge.scavengedBefore or 0, scavenge.scavengedAfter or 0,
                scavenge.totalYield or 0, tostring(scavenge.seed)))
            for category, detail in pairs(scavenge.components or {}) do
                rows[#rows + 1] = row("SCAVENGE " .. category, string.format(
                    "potential %.1f need %.2f remain %.2f scav %.2f var %.2f => +%d",
                    detail.potential or 0, detail.need or 0,
                    detail.remainingFactor or 0, detail.scavengerFactor or 0,
                    detail.variance or 0, detail.yield or 0))
            end
        end
    end
    if location then
        rows[#rows + 1] = row("LOCATION", location.id)
        rows[#rows + 1] = row("Type / position", location.type .. " / "
            .. string.format("%.0f, %.0f, %.0f", location.x or 0,
                location.y or 0, location.z or 0))
        rows[#rows + 1] = row("Danger / scavenged",
            tostring(location.danger) .. " / " .. tostring(location.scavengedLevel))
        rows[#rows + 1] = row("Occupants",
            table.concat(location.occupantGroupIds or {}, ", "))
    end
    for _, job in ipairs(snapshot and snapshot.jobs or {}) do
        rows[#rows + 1] = row("JOB " .. job.name,
            string.format("every %.3fh / next %.3f / runs %d / errors %d",
                job.interval or 0, job.nextRun or 0, job.runs or 0, job.errors or 0),
            (job.errors or 0) > 0 and "danger" or "textMuted")
    end
    local encounters = snapshot and snapshot.recentEncounters or {}
    local first = math.max(1, #encounters - 7)
    for index = first, #encounters do
        local report = encounters[index]
        rows[#rows + 1] = row("ENCOUNTER " .. tostring(report.id),
            tostring(report.outcome) .. " / " .. tostring(report.locationId)
                .. " / seed " .. tostring(report.seed)
                .. " / " .. table.concat(report.participants or {}, " vs "),
            report.outcome == "MATERIALIZATION_REQUIRED"
                and "warning" or "textMuted")
        for groupID, intent in pairs(report.intentScores or {}) do
            local scoreText = {}
            for _, name in ipairs({ "IGNORE", "AVOID", "FLEE", "NEGOTIATE",
                "EXTORT", "ROB", "ATTACK" }) do
                scoreText[#scoreText + 1] = name .. "="
                    .. string.format("%.1f", intent.scores and intent.scores[name] or 0)
            end
            rows[#rows + 1] = row("INTENT " .. groupID,
                tostring(intent.selected) .. " | " .. table.concat(scoreText, " "))
        end
        for _, roundReport in ipairs(report.combatResult
            and report.combatResult.roundReports or {}) do
            rows[#rows + 1] = row("COMBAT ROUND " .. tostring(roundReport.round),
                "aggregate pressure/casualties available in report")
        end
    end
    return rows
end

return Model
