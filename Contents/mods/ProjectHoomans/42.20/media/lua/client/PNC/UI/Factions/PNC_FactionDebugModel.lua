-- Pure presentation model for the guarded faction inspector.

PNC = PNC or {}
PNC.FactionDebugModel = PNC.FactionDebugModel or {}

local Model = PNC.FactionDebugModel

function Model.ShortenID(value, maximum)
    value = tostring(value or "")
    maximum = math.max(12, tonumber(maximum) or 36)
    if #value <= maximum then return value end
    local side = math.floor((maximum - 3) / 2)
    return string.sub(value, 1, side) .. "..."
        .. string.sub(value, -side)
end

local function row(label, value, tone)
    return {
        label = tostring(label or ""),
        value = tostring(value == nil and "" or value),
        tone = tone or "text",
    }
end

local function enabledKeys(values)
    local keys = {}
    for key, value in pairs(values or {}) do
        if value == true then
            keys[#keys + 1] = tostring(key)
        elseif type(value) == "string" then
            keys[#keys + 1] = tostring(key)
                .. "=" .. value
        end
    end
    table.sort(keys)
    return #keys > 0 and table.concat(keys, ", ") or "(none)"
end

function Model.BuildFactionItems(snapshot)
    local output = {}
    for _, faction in ipairs(
        snapshot and snapshot.factions or {}
    ) do
        output[#output + 1] = {
            id = faction.id,
            label = faction.name,
            detail = faction.archetypeLabel
                .. " / " .. faction.status
                .. (faction.ownerPlayerKey
                    and " / player-owned" or ""),
            faction = faction,
        }
    end
    return output
end

function Model.BuildNPCItems(snapshot)
    local output = {}
    for _, npc in ipairs(snapshot and snapshot.roster or {}) do
        local affiliation = npc.affiliation or {}
        output[#output + 1] = {
            id = npc.id,
            label = npc.name,
            detail = affiliation.factionID
                or "unaffiliated",
            npc = npc,
        }
    end
    return output
end

function Model.BuildRows(snapshot, authorized, reason)
    local rows = {}
    local faction
    if authorized ~= true then
        return {
            row("Access", "Admin/debug mode required", "danger"),
        }
    end
    if not snapshot then
        return {
            row("Status", reason or "Select a faction",
                reason and "warning" or "textMuted"),
        }
    end
    rows[#rows + 1] = row(
        "Registry",
        "schema " .. tostring(snapshot.registrySchemaVersion)
            .. " / revision "
            .. tostring(snapshot.registryRevision)
    )
    rows[#rows + 1] = row(
        "Faction count", #(snapshot.factions or {})
    )
    rows[#rows + 1] = row(
        "Your faction",
        snapshot.currentPlayerFactionID or "(none)",
        snapshot.currentPlayerFactionID
            and "success" or "warning"
    )
    faction = snapshot.selectedFaction
    if not faction then
        rows[#rows + 1] = row(
            "Selection",
            "Create or select a faction",
            "textMuted"
        )
    else
        rows[#rows + 1] = row("Faction", faction.name, "success")
        rows[#rows + 1] = row("Faction ID", faction.id)
        rows[#rows + 1] = row(
            "Archetype",
            tostring(faction.archetypeLabel)
                .. " (" .. tostring(faction.archetypeID) .. ")"
        )
        rows[#rows + 1] = row("Status", faction.status)
        rows[#rows + 1] = row(
            "Leader", faction.leaderNPCID or "(none)"
        )
        rows[#rows + 1] = row(
            "Player owner",
            faction.ownerPlayerKey or "(none)"
        )
        rows[#rows + 1] = row(
            "Members",
            tostring(faction.memberCount or 0)
                .. " NPC / "
                .. tostring(faction.playerMemberCount or 0)
                .. " player"
        )
        rows[#rows + 1] = row("Revision", faction.revision)
        rows[#rows + 1] = row(
            "Created", tostring(faction.createdAt) .. " h"
        )
        rows[#rows + 1] = row(
            "Archived", tostring(faction.archivedAt) .. " h"
        )
        rows[#rows + 1] = row(
            "Tags", enabledKeys(faction.tags)
        )
        local policy = faction.policy or {}
        rows[#rows + 1] = row(
            "Policy",
            tostring(policy.outsiderPolicy or "neutral")
                .. " / war " .. tostring(policy.warThreshold)
                .. " / peace " .. tostring(policy.peaceThreshold)
        )
        rows[#rows + 1] = row(
            "Policy dimensions",
            string.format(
                "agg %.2f / ret %.2f / caution %.2f / hosp %.2f / opp %.2f",
                tonumber(policy.aggression) or 0,
                tonumber(policy.retaliation) or 0,
                tonumber(policy.caution) or 0,
                tonumber(policy.hospitality) or 0,
                tonumber(policy.opportunism) or 0
            )
        )
        local target = snapshot.selectedTargetFaction
        if target then
            rows[#rows + 1] = row(
                "Target faction",
                target.name .. " (" .. target.id .. ")",
                "warning"
            )
            local function relationRows(prefix, relation)
                if not relation then
                    rows[#rows + 1] = row(
                        prefix, "unknown / no contact", "textMuted"
                    )
                    return
                end
                rows[#rows + 1] = row(
                    prefix,
                    tostring(relation.state)
                        .. " / standing "
                        .. tostring(relation.standing)
                        .. " / trust " .. tostring(relation.trust),
                    relation.atWar and "danger" or "text"
                )
                rows[#rows + 1] = row(
                    "  fear / grievance",
                    tostring(relation.fear) .. " / "
                        .. tostring(relation.grievance)
                )
                rows[#rows + 1] = row(
                    "  treaties",
                    "war=" .. tostring(relation.atWar)
                        .. " allied=" .. tostring(relation.allied)
                        .. " truceUntil="
                        .. tostring(relation.truceUntil)
                )
                rows[#rows + 1] = row(
                    "  truce remaining",
                    tostring(math.max(
                        0,
                        (tonumber(relation.truceUntil) or 0)
                            - (tonumber(snapshot.generatedAt) or 0)
                    )) .. " h"
                )
                rows[#rows + 1] = row(
                    "  war history",
                    "start " .. tostring(relation.warStartedAt)
                        .. " / end " .. tostring(relation.warEndedAt)
                        .. " / reason "
                        .. tostring(relation.warReason or "(none)")
                )
                rows[#rows + 1] = row(
                    "  war authority",
                    tostring(
                        relation.initiatingFactionID or "(none)"
                    ) .. " / incident "
                        .. tostring(
                            relation.triggeringIncidentID or "(none)"
                        )
                )
                rows[#rows + 1] = row(
                    "  state history",
                    tostring(relation.previousState)
                        .. " -> " .. tostring(relation.state)
                        .. " / rev " .. tostring(relation.revision)
                )
                for _, incident in ipairs(
                    relation.incidents or {}
                ) do
                    rows[#rows + 1] = row(
                        "  incident " .. tostring(incident.type),
                        tostring(incident.id)
                            .. " @ " .. tostring(incident.occurredAt)
                            .. " / severity "
                            .. tostring(incident.severity)
                    )
                    rows[#rows + 1] = row(
                        "    effects",
                        "standing " .. tostring(incident.standingEffect)
                            .. " / trust " .. tostring(incident.trustEffect)
                            .. " / fear " .. tostring(incident.fearEffect)
                            .. " / grievance "
                            .. tostring(incident.grievanceEffect)
                    )
                    rows[#rows + 1] = row(
                        "    actor / subject",
                        tostring(incident.actorKey or "(none)")
                            .. " / "
                            .. tostring(incident.subjectKey or "(none)")
                    )
                    rows[#rows + 1] = row(
                        "    source / target",
                        tostring(incident.sourceFactionID)
                            .. " / "
                            .. tostring(incident.targetFactionID)
                    )
                    rows[#rows + 1] = row(
                        "    tags",
                        enabledKeys(incident.tags)
                    )
                end
            end
            relationRows("Source -> target",
                snapshot.relationForward)
            relationRows("Target -> source",
                snapshot.relationReverse)
            local intent = snapshot.intentPreview
            if intent then
                rows[#rows + 1] = row(
                    "Intent preview",
                    tostring(intent.intent) .. " / "
                        .. tostring(intent.reason)
                        .. " / attack="
                        .. tostring(intent.attackAllowed),
                    intent.attackAllowed and "danger" or "success"
                )
            end
            local trace = snapshot.intentTrace
            if trace then
                rows[#rows + 1] = row(
                    "  intent rule",
                    tostring(trace.selectedRule)
                        .. " / fallback "
                        .. tostring(trace.fallback)
                )
            end
        end
        for _, member in ipairs(snapshot.members or {}) do
            local affiliation = member.affiliation or {}
            rows[#rows + 1] = row(
                "Member " .. tostring(member.name),
                tostring(member.npcID)
            )
            rows[#rows + 1] = row(
                "  affiliation",
                tostring(affiliation.membershipStatus)
                    .. " / " .. tostring(affiliation.role)
                    .. " / " .. tostring(affiliation.rank)
            )
            rows[#rows + 1] = row(
                "  joined/revision",
                tostring(affiliation.joinedAt) .. " h / "
                    .. tostring(affiliation.revision)
            )
        end
        for _, relation in ipairs(snapshot.diplomacy or {}) do
            local otherID = relation.targetFactionID
            rows[#rows + 1] = row(
                "Diplomacy " .. tostring(otherID),
                tostring(relation.state)
                    .. " / standing " .. tostring(relation.standing),
                relation.atWar
                    and "danger" or "success"
            )
        end
    end
    local action = snapshot.actionResult
    if action then
        rows[#rows + 1] = row(
            "Last action",
            action.ok and tostring(action.action)
                or tostring(action.reason),
            action.ok and "success" or "warning"
        )
        rows[#rows + 1] = row(
            "  faction", action.factionID or "(none)"
        )
        rows[#rows + 1] = row(
            "  NPC", action.npcID or "(none)"
        )
    end
    local episodes = snapshot.activeAggregationEpisodes or {}
    rows[#rows + 1] = row(
        "Active attack episodes",
        #episodes,
        #episodes > 0 and "warning" or "textMuted"
    )
    for _, episode in ipairs(episodes) do
        rows[#rows + 1] = row(
            "  " .. Model.ShortenID(episode.key, 32),
            tostring(episode.state) .. " / hits "
                .. tostring(episode.hitCount)
                .. " / damage " .. tostring(episode.totalDamage)
                .. " / expires " .. tostring(episode.expiresAt)
        )
        rows[#rows + 1] = row(
            "    full episode key", episode.key
        )
    end
    local jobs = snapshot.reconciliationJobs or {}
    rows[#rows + 1] = row(
        "Treaty reconciliation jobs",
        #jobs,
        #jobs > 0 and "warning" or "textMuted"
    )
    for _, job in ipairs(jobs) do
        rows[#rows + 1] = row(
            "  " .. tostring(job.operation),
            tostring(job.processedCount) .. "/"
                .. tostring(job.memberCount)
                .. " / cleared "
                .. tostring(job.staleTargetsCleared)
        )
    end
    local validation = snapshot.validationResult
    if validation then
        rows[#rows + 1] = row(
            "Invariant validation",
            validation.ok and "PASS" or "FAIL",
            validation.ok and "success" or "danger"
        )
        rows[#rows + 1] = row(
            "  checks/errors/warnings",
            tostring(validation.checks) .. " / "
                .. tostring(#(validation.errors or {})) .. " / "
                .. tostring(#(validation.warnings or {}))
        )
        for _, issue in ipairs(validation.errors or {}) do
            rows[#rows + 1] = row(
                "  " .. tostring(issue.code),
                issue.detail,
                "danger"
            )
        end
        for _, issue in ipairs(validation.warnings or {}) do
            rows[#rows + 1] = row(
                "  " .. tostring(issue.code),
                issue.detail,
                "warning"
            )
        end
    end
    local scenario = snapshot.scenarioResult
    if scenario then
        rows[#rows + 1] = row(
            "Scenario preview",
            tostring(scenario.name) .. " -> "
                .. tostring(scenario.finalDiplomaticState),
            "success"
        )
        rows[#rows + 1] = row(
            "  incidents",
            table.concat(scenario.incidentsCreated or {}, ", ")
        )
        if scenario.resolvedIntent then
            rows[#rows + 1] = row(
                "  resolved intent",
                tostring(scenario.resolvedIntent.intent)
                    .. " / "
                    .. tostring(scenario.resolvedIntent.reason)
            )
        end
    end
    local telemetry = snapshot.telemetry or {}
    rows[#rows + 1] = row(
        "Runtime telemetry",
        tostring(telemetry.count or 0) .. "/"
            .. tostring(telemetry.maximum or 0),
        telemetry.enabled and "success" or "textMuted"
    )
    for _, entry in ipairs(telemetry.entries or {}) do
        rows[#rows + 1] = row(
            "#" .. tostring(entry.sequence)
                .. " " .. tostring(entry.category),
            tostring(entry.operation or "")
                .. " / " .. tostring(entry.result or "")
                .. " / " .. tostring(entry.reason or "")
        )
    end
    return rows
end

Model.Views = {
    overview = true,
    diplomacy = true,
    members = true,
    diagnostics = true,
}

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
            legacyFaction = npc.legacyFaction,
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

local function addRelationRows(rows, prefix, relation, now)
    rows[#rows + 1] = row(
        prefix .. " state",
        relation.state .. " (previous "
            .. relation.previousState .. ")",
        relation.atWar and "danger"
            or relation.allied and "success" or "text"
    )
    rows[#rows + 1] = row(
        prefix .. " standing", relation.standing,
        relation.standing < 0 and "danger" or "success"
    )
    rows[#rows + 1] = row(
        prefix .. " trust", relation.trust,
        relation.trust < 0 and "danger" or "success"
    )
    rows[#rows + 1] = row(prefix .. " fear", relation.fear)
    rows[#rows + 1] = row(
        prefix .. " grievance", relation.grievance,
        relation.grievance > 0 and "warning" or "text"
    )
    rows[#rows + 1] = row(
        prefix .. " treaties",
        "war=" .. tostring(relation.atWar)
            .. " / allied=" .. tostring(relation.allied)
            .. " / truce "
            .. tostring(math.max(
                0, relation.truceUntil - (tonumber(now) or 0)
            )) .. " h"
    )
    rows[#rows + 1] = row(
        prefix .. " revision", relation.revision
    )
end

function Model.BuildGUIRows(
    snapshot,
    authorized,
    reason,
    requestedView
)
    local dashboard =
        Model.BuildDashboard(snapshot, authorized, reason)
    local view = Model.Views[requestedView]
        and requestedView or "overview"
    local rows = {}
    if dashboard.authorized ~= true then
        return {
            row("Access", "Admin/debug mode required", "danger"),
        }
    end
    if dashboard.status ~= "ready" then
        return {
            row("Status", dashboard.status, "warning"),
        }
    end
    local source = dashboard.source
    local target = dashboard.target
    if view == "overview" then
        rows[#rows + 1] = row(
            "Registry revision", dashboard.registryRevision
        )
        rows[#rows + 1] = row("Source faction", source.name, "success")
        rows[#rows + 1] = row("Source ID", source.id)
        rows[#rows + 1] = row(
            "Archetype",
            tostring(source.archetypeLabel)
                .. " (" .. tostring(source.archetypeID) .. ")"
        )
        rows[#rows + 1] = row("Faction status", source.status)
        rows[#rows + 1] = row(
            "Members",
            tostring(source.memberCount) .. " NPC / "
                .. tostring(source.playerMemberCount) .. " player"
        )
        rows[#rows + 1] = row(
            "Target faction",
            target and target.name or "(select a target)",
            target and "warning" or "textMuted"
        )
        if target then
            rows[#rows + 1] = row(
                "Diplomatic state",
                dashboard.forward.state,
                dashboard.forward.atWar and "danger"
                    or dashboard.forward.allied
                        and "success" or "text"
            )
            rows[#rows + 1] = row(
                "Resolved intent",
                dashboard.intent.value .. " / "
                    .. dashboard.intent.reason,
                dashboard.intent.attackAllowed
                    and "danger" or "success"
            )
        end
        if dashboard.npc then
            local affiliation =
                dashboard.npc.affiliation or {}
            rows[#rows + 1] = row(
                "Selected NPC", dashboard.npc.name
            )
            rows[#rows + 1] = row(
                "NPC affiliation",
                tostring(affiliation.membershipStatus or "none")
                    .. " / "
                    .. tostring(affiliation.role or "none")
                    .. " / "
                    .. tostring(affiliation.rank or "none")
            )
            rows[#rows + 1] = row(
                "Legacy faction",
                dashboard.npc.legacyFaction or "(none)"
            )
        end
        rows[#rows + 1] = row(
            "Active episodes", dashboard.activeEpisodeCount,
            dashboard.activeEpisodeCount > 0
                and "warning" or "textMuted"
        )
        rows[#rows + 1] = row(
            "Telemetry",
            tostring(dashboard.telemetry.count)
                .. "/" .. tostring(dashboard.telemetry.maximum),
            dashboard.telemetry.enabled
                and "success" or "textMuted"
        )
        if dashboard.validation then
            rows[#rows + 1] = row(
                "Invariant check",
                dashboard.validation.ok and "PASS" or "FAIL",
                dashboard.validation.ok and "success" or "danger"
            )
        end
    elseif view == "diplomacy" then
        rows[#rows + 1] = row("Source", source.name)
        rows[#rows + 1] = row(
            "Target", target and target.name or "(select a target)",
            target and "warning" or "textMuted"
        )
        if target then
            addRelationRows(
                rows, "Source -> target",
                dashboard.forward, dashboard.generatedAt
            )
            addRelationRows(
                rows, "Target -> source",
                dashboard.reverse, dashboard.generatedAt
            )
            rows[#rows + 1] = row(
                "Intent",
                dashboard.intent.value .. " / "
                    .. dashboard.intent.reason,
                dashboard.intent.attackAllowed
                    and "danger" or "success"
            )
            rows[#rows + 1] = row(
                "Intent rule",
                dashboard.intent.rule
                    .. " / fallback="
                    .. tostring(dashboard.intent.fallback)
            )
            rows[#rows + 1] = row(
                "Permissions",
                "attack=" .. tostring(
                    dashboard.intent.attackAllowed
                ) .. " / pursue=" .. tostring(
                    dashboard.intent.pursueAllowed
                ) .. " / commandable=" .. tostring(
                    dashboard.intent.commandable
                )
            )
            for _, incident in ipairs(
                dashboard.forward.incidents or {}
            ) do
                rows[#rows + 1] = row(
                    "Incident " .. tostring(incident.type),
                    tostring(incident.id) .. " / severity "
                        .. tostring(incident.severity),
                    "warning"
                )
            end
        end
    elseif view == "members" then
        rows[#rows + 1] = row("Faction", source.name, "success")
        rows[#rows + 1] = row(
            "Member total", source.memberCount
        )
        for _, member in ipairs(snapshot.members or {}) do
            local affiliation = member.affiliation or {}
            rows[#rows + 1] = row(
                tostring(member.name), member.npcID
            )
            rows[#rows + 1] = row(
                "  affiliation",
                tostring(affiliation.membershipStatus)
                    .. " / " .. tostring(affiliation.role)
                    .. " / " .. tostring(affiliation.rank)
            )
        end
        if dashboard.npc then
            rows[#rows + 1] = row(
                "Selected record revision",
                dashboard.npc.recordRevision
            )
            rows[#rows + 1] = row(
                "Selected presence revision",
                dashboard.npc.presenceRevision
            )
        end
    else
        rows[#rows + 1] = row(
            "Active attack episodes",
            dashboard.activeEpisodeCount,
            dashboard.activeEpisodeCount > 0
                and "warning" or "textMuted"
        )
        for _, episode in ipairs(
            snapshot.activeAggregationEpisodes or {}
        ) do
            rows[#rows + 1] = row(
                Model.ShortenID(episode.key, 36),
                tostring(episode.state)
                    .. " / hits " .. tostring(episode.hitCount)
                    .. " / damage "
                    .. tostring(episode.totalDamage)
            )
        end
        rows[#rows + 1] = row(
            "Treaty reconciliation jobs",
            dashboard.reconciliationJobCount,
            dashboard.reconciliationJobCount > 0
                and "warning" or "textMuted"
        )
        for _, job in ipairs(
            snapshot.reconciliationJobs or {}
        ) do
            rows[#rows + 1] = row(
                tostring(job.operation),
                tostring(job.processedCount) .. "/"
                    .. tostring(job.memberCount)
                    .. " / cleared "
                    .. tostring(job.staleTargetsCleared)
            )
        end
        if dashboard.validation then
            rows[#rows + 1] = row(
                "Invariant validation",
                dashboard.validation.ok and "PASS" or "FAIL",
                dashboard.validation.ok and "success" or "danger"
            )
            rows[#rows + 1] = row(
                "Checks / errors / warnings",
                tostring(dashboard.validation.checks) .. " / "
                    .. tostring(dashboard.validation.errorCount)
                    .. " / "
                    .. tostring(dashboard.validation.warningCount)
            )
        else
            rows[#rows + 1] = row(
                "Invariant validation",
                "not run", "textMuted"
            )
        end
        if dashboard.scenario then
            rows[#rows + 1] = row(
                "Last scenario",
                tostring(dashboard.scenario.name)
                    .. " -> "
                    .. tostring(dashboard.scenario.state),
                "success"
            )
        end
        rows[#rows + 1] = row(
            "Runtime telemetry",
            tostring(dashboard.telemetry.count)
                .. "/" .. tostring(dashboard.telemetry.maximum),
            dashboard.telemetry.enabled
                and "success" or "textMuted"
        )
        for _, entry in ipairs(
            dashboard.telemetry.entries or {}
        ) do
            rows[#rows + 1] = row(
                "#" .. tostring(entry.sequence)
                    .. " " .. tostring(entry.category),
                tostring(entry.operation or "")
                    .. " / " .. tostring(entry.result or "")
                    .. " / " .. tostring(entry.reason or "")
            )
        end
    end
    return rows
end

return Model
