-- Compact, engine-free dashboard projection used by the overlay.

PNC = PNC or {}
PNC.FactionDebugModel = PNC.FactionDebugModel or {}

local Model = PNC.FactionDebugModel
local Internal = Model.Internal or {}
Model.Internal = Internal

local function selectedNPC(snapshot)
    local selectedID = snapshot and snapshot.selectedNPCID
    if not selectedID then return nil end
    for _, npc in ipairs(snapshot.roster or {}) do
        if npc.id == selectedID then return npc end
    end
    return nil
end

local function relationDashboard(relation)
    local value = relation or {}
    return {
        exists = relation ~= nil,
        state = tostring(value.state or "unknown"),
        previousState = tostring(value.previousState or "unknown"),
        standing = tonumber(value.standing) or 0,
        trust = tonumber(value.trust) or 0,
        fear = tonumber(value.fear) or 0,
        grievance = tonumber(value.grievance) or 0,
        atWar = value.atWar == true,
        allied = value.allied == true,
        truceUntil = tonumber(value.truceUntil) or 0,
        revision = tonumber(value.revision) or 0,
        incidents = value.incidents or {},
    }
end

-- Compact, read-only presentation state used by the graphical inspector and
-- overlay. It intentionally contains no engine objects and never changes the
-- server snapshot.
function Model.BuildDashboard(snapshot, authorized, reason)
    if authorized ~= true then
        return {
            authorized = false,
            status = tostring(reason or "not_authorized"),
        }
    end
    if not snapshot then
        return {
            authorized = true,
            status = tostring(reason or "waiting_for_snapshot"),
        }
    end
    local source = snapshot.selectedFaction
    local target = snapshot.selectedTargetFaction
    local npc = selectedNPC(snapshot)
    local intent = snapshot.intentPreview or {}
    local trace = snapshot.intentTrace or {}
    local telemetry = snapshot.telemetry or {}
    local validation = snapshot.validationResult
    local scenario = snapshot.scenarioResult
    return {
        authorized = true,
        status = source and "ready" or "select_faction",
        generatedAt = tonumber(snapshot.generatedAt) or 0,
        registryRevision =
            tonumber(snapshot.registryRevision) or 0,
        source = source and {
            id = source.id,
            name = source.name,
            archetypeID = source.archetypeID,
            archetypeLabel = source.archetypeLabel,
            status = source.status,
            revision = tonumber(source.revision) or 0,
            memberCount = tonumber(source.memberCount) or 0,
            playerMemberCount =
                tonumber(source.playerMemberCount) or 0,
            communityCount =
                tonumber(source.communityCount) or 0,
            communityNames = source.communityNames or {},
            communityPopulation =
                tonumber(source.communityPopulation) or 0,
            communitySupplies =
                source.communitySupplies or {},
            mobile = source.mobile,
        } or nil,
        target = target and {
            id = target.id,
            name = target.name,
            archetypeID = target.archetypeID,
            archetypeLabel = target.archetypeLabel,
            status = target.status,
            revision = tonumber(target.revision) or 0,
        } or nil,
        forward = relationDashboard(snapshot.relationForward),
        reverse = relationDashboard(snapshot.relationReverse),
        intent = {
            value = tostring(intent.intent or "none"),
            reason = tostring(intent.reason or "no_target"),
            attackAllowed = intent.attackAllowed == true,
            pursueAllowed = intent.pursueAllowed == true,
            commandable = intent.commandable == true,
            rule = tostring(trace.selectedRule or "none"),
            fallback = trace.fallback == nil
                and "none" or tostring(trace.fallback),
        },
        npc = npc and {
            id = npc.id,
            name = npc.name,
            factionID = npc.factionID
                or npc.affiliation
                    and npc.affiliation.factionID or nil,
            tacticalClass = npc.tacticalClass,
            colonyOwned = npc.colonyOwned == true
                or npc.identity and npc.identity.colonyOwned == true,
            recruited = npc.recruited == true
                or npc.identity and npc.identity.recruited == true,
            identity = npc.identity,
            identityVerification = npc.identityVerification,
            recordRevision =
                tonumber(npc.recordRevision) or 0,
            presenceRevision =
                tonumber(npc.presenceRevision) or 0,
            affiliation = npc.affiliation or {},
        } or nil,
        activeEpisodeCount =
            #(snapshot.activeAggregationEpisodes or {}),
        activeEpisode =
            (snapshot.activeAggregationEpisodes or {})[1],
        reconciliationJobCount =
            #(snapshot.reconciliationJobs or {}),
        reconciliationJob =
            (snapshot.reconciliationJobs or {})[1],
        telemetry = {
            enabled = telemetry.enabled == true,
            count = tonumber(telemetry.count) or 0,
            maximum = tonumber(telemetry.maximum) or 0,
            entries = telemetry.entries or {},
        },
        validation = validation and {
            ok = validation.ok == true,
            checks = tonumber(validation.checks) or 0,
            errorCount = #(validation.errors or {}),
            warningCount = #(validation.warnings or {}),
        } or nil,
        scenario = scenario and {
            name = scenario.name,
            state = scenario.finalDiplomaticState,
        } or nil,
        action = snapshot.actionResult,
    }
end
return Model

