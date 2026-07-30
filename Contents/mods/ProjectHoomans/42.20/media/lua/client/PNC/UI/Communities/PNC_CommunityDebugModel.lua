-- Pure presentation model for the Community Inspector.

PNC = PNC or {}
PNC.CommunityDebugModel = PNC.CommunityDebugModel or {}

local Model = PNC.CommunityDebugModel

local function row(label, value, tone)
    return {
        label = tostring(label or ""),
        value = tostring(value == nil and "" or value),
        tone = tone or "text",
    }
end

local function text(key)
    return getText and getText(key) or key
end

local function number(value)
    return string.format("%.1f", tonumber(value) or 0)
end

function Model.BuildCommunityItems(snapshot)
    local output = {}
    for _, community in ipairs(
        snapshot and snapshot.communities or {}
    ) do
        output[#output + 1] = {
            id = community.id,
            label = community.name,
            detail = community.mode .. "/" .. community.status
                .. " | " .. community.factionID,
            community = community,
        }
    end
    return output
end

function Model.BuildFactionItems(snapshot)
    local output = {}
    for _, faction in ipairs(
        snapshot and snapshot.factions or {}
    ) do
        output[#output + 1] = {
            id = faction.id,
            label = faction.name,
            detail = faction.archetypeID
                .. "/" .. faction.status,
            faction = faction,
        }
    end
    return output
end

function Model.BuildNPCItems(snapshot)
    local output = {}
    for _, npc in ipairs(snapshot and snapshot.roster or {}) do
        output[#output + 1] = {
            id = npc.id,
            label = npc.name,
            detail = npc.communityName
                and npc.communityName .. " / "
                    .. tostring(npc.communityRole)
                or text("UI_PNC_CommunityNone"),
            npc = npc,
        }
    end
    return output
end

function Model.BuildRows(snapshot, authorized, reason)
    local rows = {}
    if authorized ~= true then
        rows[#rows + 1] = row(
            text("UI_PNC_CommunityAuthorization"),
            reason or "not_authorized",
            "danger"
        )
        return rows
    end
    snapshot = snapshot or {}
    local registry = snapshot.registry or {}
    local community = snapshot.selectedCommunity
    local npc = snapshot.selectedNPC
    rows[#rows + 1] = row(
        text("UI_PNC_CommunityRegistry"),
        "schema " .. tostring(registry.schemaVersion or 0)
            .. " / revision "
            .. tostring(registry.revision or 0)
            .. " / count " .. tostring(registry.count or 0)
    )
    if snapshot.action then
        rows[#rows + 1] = row(
            text("UI_PNC_CommunityLastAction"),
            tostring(snapshot.action.action) .. ": "
                .. tostring(snapshot.action.reason),
            snapshot.action.ok and "success" or "danger"
        )
    end
    if not community then
        rows[#rows + 1] = row(
            text("UI_PNC_CommunitySelection"),
            text("UI_PNC_CommunityNone"),
            "textMuted"
        )
        return rows
    end
    rows[#rows + 1] = row(
        text("UI_PNC_CommunityName"), community.name
    )
    rows[#rows + 1] = row(
        text("UI_PNC_CommunityID"), community.id
    )
    rows[#rows + 1] = row(
        text("UI_PNC_CommunityFaction"),
        community.factionID
    )
    rows[#rows + 1] = row(
        text("UI_PNC_CommunityModeStatus"),
        community.mode .. " / " .. community.status
    )
    rows[#rows + 1] = row(
        text("UI_PNC_CommunityHome"),
        number(community.home.x) .. ", "
            .. number(community.home.y) .. ", "
            .. number(community.home.z)
            .. " r=" .. number(community.home.radius)
    )
    rows[#rows + 1] = row(
        text("UI_PNC_CommunityLeader"),
        community.leaderNPCID or text("UI_PNC_CommunityNone")
    )
    rows[#rows + 1] = row(
        text("UI_PNC_CommunityPopulation"),
        tostring(community.currentPopulation)
            .. "/" .. tostring(
                community.populationCapacity
            )
            .. (community.overcrowded
                and " (overcrowded)" or "")
    )
    rows[#rows + 1] = row(
        text("UI_PNC_CommunityCapacity"),
        "beds=" .. tostring(community.capacity.beds)
            .. " storage="
            .. tostring(community.capacity.storage)
    )
    rows[#rows + 1] = row(
        text("UI_PNC_CommunitySecurity"),
        community.security
    )
    rows[#rows + 1] = row(
        text("UI_PNC_CommunityMorale"), community.morale
    )
    for _, category in ipairs(
        snapshot.supplyCategories or {}
    ) do
        rows[#rows + 1] = row(
            text("UI_PNC_CommunitySupply")
                .. " " .. category,
            community.supplies[category]
        )
    end
    rows[#rows + 1] = row(
        text("UI_PNC_CommunityRevisions"),
        "community=" .. tostring(community.revision)
            .. " registry=" .. tostring(registry.revision)
    )
    if npc then
        rows[#rows + 1] = row(
            text("UI_PNC_CommunitySelectedNPC"), npc.name
        )
        rows[#rows + 1] = row(
            text("UI_PNC_CommunityNPCAffiliation"),
            tostring(npc.communityID or "none")
                .. " / " .. tostring(npc.communityRole)
        )
        rows[#rows + 1] = row(
            text("UI_PNC_CommunityNPCLocation"),
            number(npc.x) .. ", " .. number(npc.y)
                .. ", " .. number(npc.z)
        )
        rows[#rows + 1] = row(
            text("UI_PNC_CommunityContainment"),
            tostring(npc.insideHome)
                .. " / distance "
                .. number(npc.distanceFromHome),
            npc.insideHome and "success" or "warning"
        )
        rows[#rows + 1] = row(
            text("UI_PNC_CommunityNPCRevisions"),
            "affiliation="
                .. tostring(npc.affiliationRevision)
                .. " record=" .. tostring(npc.recordRevision)
                .. " presence="
                .. tostring(npc.presenceRevision)
        )
    end
    local validation = snapshot.validation
    if validation then
        rows[#rows + 1] = row(
            text("UI_PNC_CommunityValidation"),
            validation.ok and "valid"
                or ("errors=" .. tostring(
                    #(validation.errors or {})
                )),
            validation.ok and "success" or "danger"
        )
    end
    return rows
end

return Model
