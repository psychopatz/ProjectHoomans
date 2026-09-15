-- GUI diagnostics view rows.

PNC = PNC or {}
PNC.FactionDebugModel = PNC.FactionDebugModel or {}

local Model = PNC.FactionDebugModel
local Internal = Model.Internal or {}
Model.Internal = Internal

function Internal.AppendDiagnosticsRows(rows, snapshot, dashboard)
        rows[#rows + 1] = Internal.Row(
            "Active attack episodes",
            dashboard.activeEpisodeCount,
            dashboard.activeEpisodeCount > 0
                and "warning" or "textMuted"
        )
        for _, episode in ipairs(
            snapshot.activeAggregationEpisodes or {}
        ) do
            rows[#rows + 1] = Internal.Row(
                Model.ShortenID(episode.key, 36),
                tostring(episode.state)
                    .. " / hits " .. tostring(episode.hitCount)
                    .. " / damage "
                    .. tostring(episode.totalDamage)
            )
        end
        rows[#rows + 1] = Internal.Row(
            "Treaty reconciliation jobs",
            dashboard.reconciliationJobCount,
            dashboard.reconciliationJobCount > 0
                and "warning" or "textMuted"
        )
        for _, job in ipairs(
            snapshot.reconciliationJobs or {}
        ) do
            rows[#rows + 1] = Internal.Row(
                tostring(job.operation),
                tostring(job.processedCount) .. "/"
                    .. tostring(job.memberCount)
                    .. " / cleared "
                    .. tostring(job.staleTargetsCleared)
            )
        end
        if dashboard.validation then
            rows[#rows + 1] = Internal.Row(
                "Invariant validation",
                dashboard.validation.ok and "PASS" or "FAIL",
                dashboard.validation.ok and "success" or "danger"
            )
            rows[#rows + 1] = Internal.Row(
                "Checks / errors / warnings",
                tostring(dashboard.validation.checks) .. " / "
                    .. tostring(dashboard.validation.errorCount)
                    .. " / "
                    .. tostring(dashboard.validation.warningCount)
            )
        else
            rows[#rows + 1] = Internal.Row(
                "Invariant validation",
                "not run", "textMuted"
            )
        end
        if dashboard.scenario then
            rows[#rows + 1] = Internal.Row(
                "Last scenario",
                tostring(dashboard.scenario.name)
                    .. " -> "
                    .. tostring(dashboard.scenario.state),
                "success"
            )
        end
        rows[#rows + 1] = Internal.Row(
            "Runtime telemetry",
            tostring(dashboard.telemetry.count)
                .. "/" .. tostring(dashboard.telemetry.maximum),
            dashboard.telemetry.enabled
                and "success" or "textMuted"
        )
        for _, entry in ipairs(
            dashboard.telemetry.entries or {}
        ) do
            rows[#rows + 1] = Internal.Row(
                "#" .. tostring(entry.sequence)
                    .. " " .. tostring(entry.category),
                tostring(entry.operation or "")
                    .. " / " .. tostring(entry.result or "")
                    .. " / " .. tostring(entry.reason or "")
            )
        end
    end

return Model
