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
                .. " / " .. faction.status,
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
            "Members", faction.memberCount or 0
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
