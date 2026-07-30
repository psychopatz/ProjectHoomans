-- Pure presentation model for the guarded faction inspector.

PNC = PNC or {}
PNC.FactionDebugModel = PNC.FactionDebugModel or {}

local Model = PNC.FactionDebugModel

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
    return rows
end

return Model
