-- Snapshot rows for actions, episodes, reconciliation, and telemetry.

PNC = PNC or {}
PNC.FactionDebugModel = PNC.FactionDebugModel or {}

local Model = PNC.FactionDebugModel
local Internal = Model.Internal or {}
Model.Internal = Internal

local function appendActionRows(rows, action)
    if action then
        rows[#rows + 1] = Internal.Row(
            "Last action",
            action.ok
                and (tostring(action.action) .. " / "
                    .. tostring(action.reason))
                or tostring(action.reason),
            action.ok and "success" or "warning"
        )
        local group = action.groupResult
        if group then
            rows[#rows + 1] = Internal.Row(
                "Generated group",
                tostring(group.createdCount or 0)
                    .. " NPCs / live "
                    .. tostring(group.liveCount or 0)
                    .. " / abstract "
                    .. tostring(group.abstractCount or 0)
                    .. " / " .. tostring(
                        group.siteKind or "site"
                    ),
                "success"
            )
        end
        local objective = action.objectiveResult
        if objective then
            local target = objective.controlMode == "strategic"
                and objective.strategicTarget
                or objective.ambient
                    and objective.ambient.target
            rows[#rows + 1] = Internal.Row(
                "  objective refresh",
                tostring(objective.controlMode or "ambient")
                    .. " / "
                    .. tostring(target and (
                        target.kind or target.siteID
                            or target.baseID
                    ) or "pending")
            )
        end
        rows[#rows + 1] = Internal.Row(
            "  faction", action.factionID or "(none)"
        )
        rows[#rows + 1] = Internal.Row(
            "  NPC", action.npcID or "(none)"
        )
    end
end

local function appendEpisodeRows(rows, episodes)
    rows[#rows + 1] = Internal.Row(
        "Active attack episodes",
        #episodes,
        #episodes > 0 and "warning" or "textMuted"
    )
    for _, episode in ipairs(episodes) do
        rows[#rows + 1] = Internal.Row(
            "  " .. Model.ShortenID(episode.key, 32),
            tostring(episode.state) .. " / hits "
                .. tostring(episode.hitCount)
                .. " / damage " .. tostring(episode.totalDamage)
                .. " / expires " .. tostring(episode.expiresAt)
        )
        rows[#rows + 1] = Internal.Row(
            "    full episode key", episode.key
        )
    end
end

local function appendJobRows(rows, jobs)
    rows[#rows + 1] = Internal.Row(
        "Treaty reconciliation jobs",
        #jobs,
        #jobs > 0 and "warning" or "textMuted"
    )
    for _, job in ipairs(jobs) do
        rows[#rows + 1] = Internal.Row(
            "  " .. tostring(job.operation),
            tostring(job.processedCount) .. "/"
                .. tostring(job.memberCount)
                .. " / cleared "
                .. tostring(job.staleTargetsCleared)
        )
    end
end

local function appendValidationRows(rows, validation)
    if validation then
        rows[#rows + 1] = Internal.Row(
            "Invariant validation",
            validation.ok and "PASS" or "FAIL",
            validation.ok and "success" or "danger"
        )
        rows[#rows + 1] = Internal.Row(
            "  checks/errors/warnings",
            tostring(validation.checks) .. " / "
                .. tostring(#(validation.errors or {})) .. " / "
                .. tostring(#(validation.warnings or {}))
        )
        for _, issue in ipairs(validation.errors or {}) do
            rows[#rows + 1] = Internal.Row(
                "  " .. tostring(issue.code),
                issue.detail,
                "danger"
            )
        end
        for _, issue in ipairs(validation.warnings or {}) do
            rows[#rows + 1] = Internal.Row(
                "  " .. tostring(issue.code),
                issue.detail,
                "warning"
            )
        end
    end
end

local function appendScenarioRows(rows, scenario)
    if scenario then
        rows[#rows + 1] = Internal.Row(
            "Scenario preview",
            tostring(scenario.name) .. " -> "
                .. tostring(scenario.finalDiplomaticState),
            "success"
        )
        rows[#rows + 1] = Internal.Row(
            "  incidents",
            table.concat(scenario.incidentsCreated or {}, ", ")
        )
        if scenario.resolvedIntent then
            rows[#rows + 1] = Internal.Row(
                "  resolved intent",
                tostring(scenario.resolvedIntent.intent)
                    .. " / "
                    .. tostring(scenario.resolvedIntent.reason)
            )
        end
    end
end

local function appendTelemetryRows(rows, telemetry)
    rows[#rows + 1] = Internal.Row(
        "Runtime telemetry",
        tostring(telemetry.count or 0) .. "/"
            .. tostring(telemetry.maximum or 0),
        telemetry.enabled and "success" or "textMuted"
    )
    for _, entry in ipairs(telemetry.entries or {}) do
        rows[#rows + 1] = Internal.Row(
            "#" .. tostring(entry.sequence)
                .. " " .. tostring(entry.category),
            tostring(entry.operation or "")
                .. " / " .. tostring(entry.result or "")
                .. " / " .. tostring(entry.reason or "")
        )
    end
end

function Internal.AppendSnapshotDiagnosticsRows(rows, snapshot)
    appendActionRows(rows, snapshot.actionResult)
    appendEpisodeRows(
        rows, snapshot.activeAggregationEpisodes or {}
    )
    appendJobRows(rows, snapshot.reconciliationJobs or {})
    appendValidationRows(rows, snapshot.validationResult)
    appendScenarioRows(rows, snapshot.scenarioResult)
    appendTelemetryRows(rows, snapshot.telemetry or {})
end

return Model
