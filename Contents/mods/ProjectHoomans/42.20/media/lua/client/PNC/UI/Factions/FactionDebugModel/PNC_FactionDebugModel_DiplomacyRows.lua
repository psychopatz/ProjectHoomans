-- GUI diplomacy view rows.

PNC = PNC or {}
PNC.FactionDebugModel = PNC.FactionDebugModel or {}

local Model = PNC.FactionDebugModel
local Internal = Model.Internal or {}
Model.Internal = Internal

local function addRelationRows(rows, prefix, relation, now)
    rows[#rows + 1] = Internal.Row(
        prefix .. " state",
        relation.state .. " (previous "
            .. relation.previousState .. ")",
        relation.atWar and "danger"
            or relation.allied and "success" or "text"
    )
    rows[#rows + 1] = Internal.Row(
        prefix .. " standing", relation.standing,
        relation.standing < 0 and "danger" or "success"
    )
    rows[#rows + 1] = Internal.Row(
        prefix .. " trust", relation.trust,
        relation.trust < 0 and "danger" or "success"
    )
    rows[#rows + 1] = Internal.Row(prefix .. " fear", relation.fear)
    rows[#rows + 1] = Internal.Row(
        prefix .. " grievance", relation.grievance,
        relation.grievance > 0 and "warning" or "text"
    )
    rows[#rows + 1] = Internal.Row(
        prefix .. " treaties",
        "war=" .. tostring(relation.atWar)
            .. " / allied=" .. tostring(relation.allied)
            .. " / truce "
            .. tostring(math.max(
                0, relation.truceUntil - (tonumber(now) or 0)
            )) .. " h"
    )
    rows[#rows + 1] = Internal.Row(
        prefix .. " revision", relation.revision
    )
end

function Internal.AppendDiplomacyRows(rows, snapshot, dashboard)
    local source = dashboard.source
    local target = dashboard.target
        rows[#rows + 1] = Internal.Row("Source", source.name)
        rows[#rows + 1] = Internal.Row(
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
            rows[#rows + 1] = Internal.Row(
                "Intent",
                dashboard.intent.value .. " / "
                    .. dashboard.intent.reason,
                dashboard.intent.attackAllowed
                    and "danger" or "success"
            )
            rows[#rows + 1] = Internal.Row(
                "Intent rule",
                dashboard.intent.rule
                    .. " / fallback="
                    .. tostring(dashboard.intent.fallback)
            )
            rows[#rows + 1] = Internal.Row(
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
                rows[#rows + 1] = Internal.Row(
                    "Incident " .. tostring(incident.type),
                    tostring(incident.id) .. " / severity "
                        .. tostring(incident.severity),
                    "warning"
                )
            end
        end
end

return Model
