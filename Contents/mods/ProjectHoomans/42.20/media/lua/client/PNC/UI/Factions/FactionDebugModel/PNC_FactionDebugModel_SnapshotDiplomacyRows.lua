-- Snapshot rows for target relations, members, and diplomacy.

PNC = PNC or {}
PNC.FactionDebugModel = PNC.FactionDebugModel or {}

local Model = PNC.FactionDebugModel
local Internal = Model.Internal or {}
Model.Internal = Internal

local function appendRelationRows(rows, snapshot, prefix, relation)
    if not relation then
        rows[#rows + 1] = Internal.Row(
            prefix, "unknown / no contact", "textMuted"
        )
        return
    end
    rows[#rows + 1] = Internal.Row(
        prefix,
        tostring(relation.state)
            .. " / standing " .. tostring(relation.standing)
            .. " / trust " .. tostring(relation.trust),
        relation.atWar and "danger" or "text"
    )
    rows[#rows + 1] = Internal.Row(
        "  fear / grievance",
        tostring(relation.fear) .. " / " .. tostring(relation.grievance)
    )
    rows[#rows + 1] = Internal.Row(
        "  treaties",
        "war=" .. tostring(relation.atWar)
            .. " allied=" .. tostring(relation.allied)
            .. " truceUntil=" .. tostring(relation.truceUntil)
    )
    rows[#rows + 1] = Internal.Row(
        "  truce remaining",
        tostring(math.max(
            0,
            (tonumber(relation.truceUntil) or 0)
                - (tonumber(snapshot.generatedAt) or 0)
        )) .. " h"
    )
    rows[#rows + 1] = Internal.Row(
        "  war history",
        "start " .. tostring(relation.warStartedAt)
            .. " / end " .. tostring(relation.warEndedAt)
            .. " / reason " .. tostring(relation.warReason or "(none)")
    )
    rows[#rows + 1] = Internal.Row(
        "  war authority",
        tostring(relation.initiatingFactionID or "(none)")
            .. " / incident "
            .. tostring(relation.triggeringIncidentID or "(none)")
    )
    rows[#rows + 1] = Internal.Row(
        "  state history",
        tostring(relation.previousState)
            .. " -> " .. tostring(relation.state)
            .. " / rev " .. tostring(relation.revision)
    )
    for _, incident in ipairs(relation.incidents or {}) do
        rows[#rows + 1] = Internal.Row(
            "  incident " .. tostring(incident.type),
            tostring(incident.id) .. " @ " .. tostring(incident.occurredAt)
                .. " / severity " .. tostring(incident.severity)
        )
        rows[#rows + 1] = Internal.Row(
            "    effects",
            "standing " .. tostring(incident.standingEffect)
                .. " / trust " .. tostring(incident.trustEffect)
                .. " / fear " .. tostring(incident.fearEffect)
                .. " / grievance " .. tostring(incident.grievanceEffect)
        )
        rows[#rows + 1] = Internal.Row(
            "    actor / subject",
            tostring(incident.actorKey or "(none)") .. " / "
                .. tostring(incident.subjectKey or "(none)")
        )
        rows[#rows + 1] = Internal.Row(
            "    source / target",
            tostring(incident.sourceFactionID) .. " / "
                .. tostring(incident.targetFactionID)
        )
        rows[#rows + 1] = Internal.Row(
            "    tags", Internal.EnabledKeys(incident.tags)
        )
    end
end

local function appendIntentRows(rows, snapshot)
    local intent = snapshot.intentPreview
    if intent then
        rows[#rows + 1] = Internal.Row(
            "Intent preview",
            tostring(intent.intent) .. " / " .. tostring(intent.reason)
                .. " / attack=" .. tostring(intent.attackAllowed),
            intent.attackAllowed and "danger" or "success"
        )
    end
    local trace = snapshot.intentTrace
    if trace then
        rows[#rows + 1] = Internal.Row(
            "  intent rule",
            tostring(trace.selectedRule)
                .. " / fallback " .. tostring(trace.fallback)
        )
    end
end

local function appendMemberRows(rows, snapshot)
    for _, member in ipairs(snapshot.members or {}) do
        local affiliation = member.affiliation or {}
        rows[#rows + 1] = Internal.Row(
            "Member " .. tostring(member.name),
            tostring(member.npcID)
        )
        rows[#rows + 1] = Internal.Row(
            "  affiliation",
            tostring(affiliation.membershipStatus)
                .. " / " .. tostring(affiliation.role)
                .. " / " .. tostring(affiliation.rank)
        )
        rows[#rows + 1] = Internal.Row(
            "  joined/revision",
            tostring(affiliation.joinedAt) .. " h / "
                .. tostring(affiliation.revision)
        )
    end
end

local function appendDiplomacyRows(rows, snapshot)
    for _, relation in ipairs(snapshot.diplomacy or {}) do
        local otherID = relation.targetFactionID
        rows[#rows + 1] = Internal.Row(
            "Diplomacy " .. tostring(otherID),
            tostring(relation.state)
                .. " / standing " .. tostring(relation.standing),
            relation.atWar and "danger" or "success"
        )
    end
end

function Internal.AppendSnapshotDiplomacyRows(rows, snapshot)
    local target = snapshot.selectedTargetFaction
    if target then
        rows[#rows + 1] = Internal.Row(
            "Target faction",
            target.name .. " (" .. target.id .. ")",
            "warning"
        )
        appendRelationRows(
            rows, snapshot, "Source -> target", snapshot.relationForward
        )
        appendRelationRows(
            rows, snapshot, "Target -> source", snapshot.relationReverse
        )
        appendIntentRows(rows, snapshot)
    end
    appendMemberRows(rows, snapshot)
    appendDiplomacyRows(rows, snapshot)
end

return Model
