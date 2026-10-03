-- Sector, population-detail, and group detail rows.
PNC = PNC or {}
PNC.DirectorDebugModel = PNC.DirectorDebugModel or {}

local Model = PNC.DirectorDebugModel
local MobileModel = PNC.MobileGroupDebugModel
local row = (Model.Internal or {}).row

local function appendSelectedSectorRows(rows, sector)
    if not sector then return end
    rows[#rows + 1] = row('SELECTED SECTOR', sector.id)
    rows[#rows + 1] = row('Sector state', string.format(
        'active=%s relevant=%s discovered=%s players=%d survivors=%d sites=%d',
        tostring(sector.active == true), tostring(sector.relevant == true),
        tostring(sector.discovered == true), sector.nearbyPlayers or 0,
        sector.survivorCount or 0, sector.candidatePool or 0))
    rows[#rows + 1] = row('Sector pending / cooldown', string.format(
        'groups=%d/%.2fh settlements=%d/%.2fh',
        sector.pendingGroups or 0, sector.groupCooldownRemaining or 0,
        sector.pendingSettlements or 0,
        sector.settlementCooldownRemaining or 0))
    rows[#rows + 1] = row('Sector suppression', tostring(
        sector.groupSuppressionReason or 'NONE') .. ' / '
        .. tostring(sector.settlementSuppressionReason or 'NONE'))
end

local function appendPopulationDetailRows(rows, population)
    for _, sector in ipairs(population.sectors or {}) do
        rows[#rows + 1] = row('SECTOR ' .. sector.id, string.format(
            'active=%s players=%d groups=%d/%d p=%.2f settlements=%d/%d p=%.2f suppress=%s/%s',
            tostring(sector.active == true), sector.nearbyPlayers or 0,
            sector.groupCount or 0, sector.desiredGroups or 0,
            sector.groupPressure or 1, sector.settlementCount or 0,
            sector.desiredSettlements or 0, sector.settlementPressure or 1,
            tostring(sector.groupSuppressionReason or 'NONE'),
            tostring(sector.settlementSuppressionReason or 'NONE')))
    end
    for _, candidate in ipairs(population.candidateEvaluations or {}) do
        local componentText = {}
        for name, value in pairs(candidate.components or {}) do
            componentText[#componentText + 1] = tostring(name) .. '='
                .. string.format('%.1f', tonumber(value) or 0)
        end
        table.sort(componentText)
        rows[#rows + 1] = row('CANDIDATE ' .. tostring(candidate.locationId),
            candidate.eligible and ('score=' .. string.format('%.1f', candidate.score or 0)
                .. ' ' .. table.concat(componentText, ' '))
                or ('REJECTED ' .. tostring(candidate.reason)),
            candidate.eligible and 'success' or 'warning')
    end
    for _, item in ipairs(population.queue or {}) do
        rows[#rows + 1] = row('QUEUE ' .. tostring(item.kind), string.format(
            '%s priority=%.2f attempts=%d expires=%.2fh source=%s',
            tostring(item.sectorId), item.priority or 0, item.attempts or 0,
            item.remainingHours or 0, tostring(item.source or 'unknown')),
            item.source == 'WORLD_POPULATION_BOOTSTRAP'
                and 'warning' or 'textMuted')
    end
    for _, reservation in ipairs(population.reservations or {}) do
        rows[#rows + 1] = row('SITE RESERVATION',
            tostring(reservation.locationId) .. ' / '
                .. tostring(reservation.generationId) .. ' / '
                .. string.format('%.2fh', reservation.remainingHours or 0),
            'textMuted')
    end
    local history = population.history or {}
    for index = math.max(1, #history - 7), #history do
        local entry = history[index]
        if entry then rows[#rows + 1] = row('POP HISTORY', tostring(entry.event)
            .. ' / ' .. tostring(entry.sectorId or '') .. ' / '
            .. tostring(entry.reason or entry.generationId or ''), 'textMuted') end
    end
    local populationLog = population.log or {}
    for index = math.max(1, #populationLog - 9), #populationLog do
        local entry = populationLog[index]
        if entry then
            local fields = {}
            for key, value in pairs(entry.fields or {}) do
                fields[#fields + 1] = tostring(key) .. '=' .. tostring(value)
            end
            table.sort(fields)
            rows[#rows + 1] = row('POP LOG ' .. tostring(entry.level or 'INFO'),
                string.format('%.3f %s %s', tonumber(entry.at) or 0,
                    tostring(entry.event), table.concat(fields, ' ')),
                entry.level == 'WARN' and 'warning' or 'textMuted')
        end
    end
end

local function appendGroupSummaryRows(rows, group)
    rows[#rows + 1] = row('GROUP', group.id)
    rows[#rows + 1] = row('Faction / home', tostring(group.factionId)
        .. ' / ' .. tostring(group.homeCommunityId or 'independent'))
    rows[#rows + 1] = row('Type', group.groupType)
    rows[#rows + 1] = row('Members / leader', tostring(#(group.memberIds or {}))
        .. ' / ' .. tostring(group.leaderId or 'none'))
    rows[#rows + 1] = row('Mission + state', group.mission .. ' + ' .. group.state)
    local action = group.action
    rows[#rows + 1] = row('Current action', action and string.format(
        '%s @ %s / %.3f -> %.3f / seed %s', action.type,
        action.locationId, action.startedAt or 0, action.endsAt or 0,
        tostring(action.seed)) or 'none')
    rows[#rows + 1] = row('Current location', group.location and group.location.id or 'none')
    rows[#rows + 1] = row('Target', group.targetLocation and group.targetLocation.id or 'none')
end

local function appendGroupMobileRows(rows, group, snapshot)
    if not group.mobile then return end
    local mobile = group.mobile
    local state = MobileModel.State(mobile, group)
    rows[#rows + 1] = row('Mobile lifecycle',
        MobileModel.StateText(mobile, group) .. ' / '
            .. tostring(mobile.activity or 'street_roaming')
            .. ' / presence='
            .. tostring(MobileModel.Presence(mobile, group)),
        state == 'en_route' and 'danger' or 'warning')
    rows[#rows + 1] = row('Mobile destination',
        MobileModel.TargetText(mobile, group))
    if mobile.travel then
        local progress = MobileModel.Progress(
            mobile, group, snapshot.generatedAt)
        rows[#rows + 1] = row('Mobile departure',
            'day ' .. tostring(mobile.travel.departureDay or 0)
                .. ' / started '
                .. tostring(mobile.travel.startedAt or 0)
                .. ' h / progress '
                .. (progress and string.format('%.0f%%', progress * 100)
                    or 'unknown'))
    end
    rows[#rows + 1] = row('Mobile last departure',
        tostring(mobile.lastDepartureAt or -1) .. ' h')
end

local function appendGroupVitalsRows(rows, group)
    rows[#rows + 1] = row('State time', string.format('%.3f -> %.3f',
        group.stateStartedAt or 0, group.stateEndsAt or 0))
    local needs = group.needs or {}
    rows[#rows + 1] = row('Needs H/W/R', string.format('%.1f / %.1f / %.1f',
        needs.hunger or 0, needs.thirst or 0, needs.fatigue or 0))
    local shortages = group.resourceNeeds or {}
    rows[#rows + 1] = row('Shortage F/W/A/Med/Mat', string.format(
        '%.2f / %.2f / %.2f / %.2f / %.2f', shortages.food or 0,
        shortages.water or 0, shortages.ammo or 0,
        shortages.medical or 0, shortages.materials or 0))
    local resources = group.resources or {}
    rows[#rows + 1] = row('Resources F/W/A/M', string.format('%.0f / %.0f / %.0f / %.0f',
        resources.food or 0, resources.water or 0, resources.ammo or 0,
        resources.medical or 0))
    rows[#rows + 1] = row('Morale / desperation', string.format('%.2f / %.2f',
        group.morale or 0, group.desperation or 0))
    local behavior = group.behaviorProfile or {}
    rows[#rows + 1] = row('Behavior A/B/G/C/M/D', string.format(
        '%.2f / %.2f / %.2f / %.2f / %.2f / %.2f',
        behavior.aggression or 0, behavior.bravery or 0,
        behavior.greed or 0, behavior.caution or 0,
        behavior.mercy or 0, behavior.discipline or 0))
    rows[#rows + 1] = row('Encounter active / recent',
        tostring(group.activeEncounterId or 'none') .. ' / '
            .. tostring(group.recentEncounterId or 'none'))
    rows[#rows + 1] = row('Combat cache',
        (group.combatProfileDirty and 'DIRTY' or 'CACHED') .. ' / '
            .. tostring(group.combatProfileCacheState or group.combatProfileReason or 'none'),
        group.combatProfileDirty and 'warning' or 'success')
end

local function appendGroupCombatRows(rows, group)
    local profile = group.combatProfile
    if profile then
        for _, field in ipairs({ 'memberCount', 'combatantCount', 'manpower',
            'meleePower', 'rangedPower', 'defense', 'mobility', 'morale',
            'experience', 'medical', 'ammoState', 'condition', 'overallPower' }) do
            rows[#rows + 1] = row('Combat ' .. field,
                string.format('%.2f', tonumber(profile[field]) or 0))
        end
    end
    for _, evaluation in ipairs(group.destinationEvaluations or {}) do
        local c = evaluation.components or {}
        rows[#rows + 1] = row('SCORE ' .. evaluation.locationId,
            string.format('%.1f = res %.1f tag %.1f mission %.1f unvisited %.1f distance %.1f danger %.1f scavenged %.1f',
                c.final or 0, c.resources or 0, c.tags or 0, c.mission or 0,
                c.unvisited or 0, c.distance or 0, c.danger or 0,
                c.scavenged or 0))
    end
end

local function appendGroupScavengeRows(rows, group)
    local scavenge = group.lastScavenge
    if not scavenge then return end
    rows[#rows + 1] = row('SCAVENGE', string.format(
        'depletion %.2f -> %.2f / total +%.0f / seed %s',
        scavenge.scavengedBefore or 0, scavenge.scavengedAfter or 0,
        scavenge.totalYield or 0, tostring(scavenge.seed)))
    for category, detail in pairs(scavenge.components or {}) do
        rows[#rows + 1] = row('SCAVENGE ' .. category, string.format(
            'potential %.1f need %.2f remain %.2f scav %.2f var %.2f => +%d',
            detail.potential or 0, detail.need or 0,
            detail.remainingFactor or 0, detail.scavengerFactor or 0,
            detail.variance or 0, detail.yield or 0))
    end
end

local function appendGroupRows(rows, group, snapshot)
    appendGroupSummaryRows(rows, group)
    appendGroupMobileRows(rows, group, snapshot)
    appendGroupVitalsRows(rows, group)
    appendGroupCombatRows(rows, group)
    appendGroupScavengeRows(rows, group)
end


Model.Internal = Model.Internal or {}
Model.Internal.appendSelectedSectorRows = appendSelectedSectorRows
Model.Internal.appendPopulationDetailRows = appendPopulationDetailRows
Model.Internal.appendGroupRows = appendGroupRows

return Model
