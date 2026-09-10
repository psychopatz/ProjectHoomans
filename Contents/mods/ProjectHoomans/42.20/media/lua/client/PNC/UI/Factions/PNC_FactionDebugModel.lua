-- Pure presentation model for the guarded faction inspector.

require "PNC/UI/Mobile/PNC_MobileGroupDebugModel"

PNC = PNC or {}
PNC.FactionDebugModel = PNC.FactionDebugModel or {}

local Model = PNC.FactionDebugModel
local MobileModel = PNC.MobileGroupDebugModel

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

local function emblemText(emblem)
    if type(emblem) ~= "table" then return "(generated on load)" end
    local layers = {}
    local index
    for index = 1, #(emblem.layers or {}) do
        local layer = emblem.layers[index]
        layers[#layers + 1] = tostring(layer.symbolID)
            .. "/" .. tostring(layer.colorID)
    end
    return tostring(emblem.backgroundColorID or "unknown")
        .. " | " .. (
            #layers > 0 and table.concat(layers, " + ")
                or "(no layers)"
        )
end

function Model.BuildFactionItems(snapshot)
    local output = {}
    for _, faction in ipairs(
        snapshot and snapshot.factions or {}
    ) do
        local mobile = faction.mobile
        local detail = faction.archetypeLabel
            .. " / " .. faction.status
            .. (faction.ownerPlayerKey
                and " / player-owned" or "")
        if mobile and mobile.active == true then
            detail = detail .. " | " .. MobileModel.StateText(mobile)
        end
        output[#output + 1] = {
            id = faction.id,
            label = faction.name,
            detail = detail,
            faction = faction,
        }
    end
    return output
end

local MOBILE_POOL_ORDER = {
    staging = 1,
    en_route = 2,
    player_colony = 3,
    street_roaming = 4,
}

local MOBILE_POOL_MEANINGS = {
    staging = "Road-visible groups waiting for the daily departure roll.",
    en_route = "Abstract traversal toward an AI-owned settlement.",
    player_colony = "Abstract traversal toward a colony owned by your faction.",
    street_roaming = "Ambient street behavior; may shelter at night.",
}

local MOBILE_CATEGORY_ORDER = {
    staging = 1,
    ai_settlement = 2,
    player_colony = 3,
    street_roaming = 4,
}

local MOBILE_CATEGORY_LABELS = {
    staging = "WAITING ON ROAD",
    player_colony = "TRAVELING TO PLAYER COLONY",
    ai_settlement = "TRAVELING TO AI SETTLEMENT",
    street_roaming = "STREET ROAMING",
}

local MOBILE_CATEGORY_TONES = {
    staging = "success",
    player_colony = "danger",
    ai_settlement = "warning",
    street_roaming = "accent",
}

local MOBILE_FILTER_LABELS = {
    all = "ALL MOBILE GROUPS",
    staging = "WAITING ON ROAD",
    player_colony = "TO PLAYER COLONY",
    ai_settlement = "TO AI SETTLEMENT",
    street_roaming = "STREET ROAMING",
}

local MOBILE_FILTERS = {
    all = true,
    staging = true,
    player_colony = true,
    ai_settlement = true,
    street_roaming = true,
}

local function mobileFactionList(snapshot)
    if snapshot and snapshot.mobileGroups then
        return snapshot.mobileGroups
    end
    return snapshot and snapshot.factions or {}
end

local function mobileTargetsPlayerColony(mobile, playerFactionID)
    local target = MobileModel.Target(mobile)
    if not target then return false end
    if target.kind == "player_colony"
        or target.kind == "player_base"
    then
        return true
    end
    return playerFactionID ~= nil
        and target.factionID == playerFactionID
end

function Model.MobileCategory(mobile, playerFactionID)
    local pool = Model.MobilePool(mobile, playerFactionID)
    if pool == "staging" then return "staging" end
    if pool == "player_colony" then return "player_colony" end
    if pool == "en_route" then return "ai_settlement" end
    return "street_roaming"
end

function Model.MobileCategoryLabel(category)
    return MOBILE_CATEGORY_LABELS[category]
        or tostring(category or "UNKNOWN MOBILE STATE")
end

function Model.MobileCategoryTone(category)
    return MOBILE_CATEGORY_TONES[category] or "accent"
end

function Model.MobileFilterLabel(filter)
    return MOBILE_FILTER_LABELS[filter] or MOBILE_FILTER_LABELS.all
end

function Model.NormalizeMobileFilter(filter)
    filter = tostring(filter or "all")
    return MOBILE_FILTERS[filter] and filter or "all"
end

function Model.MobileFilterCount(counts, filter)
    counts = counts or {}
    filter = Model.NormalizeMobileFilter(filter)
    return tonumber(filter == "all" and counts.all
        or counts[filter]) or 0
end

function Model.MobilePool(mobile, playerFactionID)
    local state = MobileModel.State(mobile)
    if state == "road_roaming" then return "staging" end
    if state == "en_route" or state == "arrival_pending" then
        if mobileTargetsPlayerColony(mobile, playerFactionID) then
            return "player_colony"
        end
        return "en_route"
    end
    return "street_roaming"
end

function Model.BuildMobilePoolCounts(snapshot)
    local counts = {
        all = 0,
        staging = 0,
        en_route = 0,
        player_colony = 0,
        ai_settlement = 0,
        street_roaming = 0,
    }
    local playerFactionID = snapshot
        and snapshot.currentPlayerFactionID or nil
    for _, faction in ipairs(mobileFactionList(snapshot)) do
        if faction.mobile and faction.mobile.active == true then
            counts.all = counts.all + 1
            local pool = Model.MobilePool(
                faction.mobile, playerFactionID)
            local category = Model.MobileCategory(
                faction.mobile, playerFactionID)
            if pool == "staging" then
                counts.staging = counts.staging + 1
            elseif pool == "player_colony" then
                counts.player_colony = counts.player_colony + 1
                counts.en_route = counts.en_route + 1
            elseif pool == "en_route" then
                counts.en_route = counts.en_route + 1
            else
                counts.street_roaming = counts.street_roaming + 1
            end
            if category == "ai_settlement" then
                counts.ai_settlement = counts.ai_settlement + 1
            end
        end
    end
    return counts
end

function Model.BuildMobileItems(snapshot, requestedFilter)
    local output = {}
    local filter = Model.NormalizeMobileFilter(requestedFilter)
    local playerFactionID = snapshot
        and snapshot.currentPlayerFactionID or nil
    for _, faction in ipairs(mobileFactionList(snapshot)) do
        if faction.mobile and faction.mobile.active == true then
            local pool = Model.MobilePool(
                faction.mobile, playerFactionID)
            local category = Model.MobileCategory(
                faction.mobile, playerFactionID)
            if filter == "all" or filter == category then
                local destination = MobileModel.TargetText(
                    faction.mobile)
                output[#output + 1] = {
                    id = faction.id,
                    name = faction.name,
                    label = Model.MobileCategoryLabel(category)
                        .. " / " .. tostring(faction.name),
                    detail = MobileModel.StateText(faction.mobile)
                        .. " / " .. tostring(faction.archetypeID)
                        .. " / " .. tostring(faction.mobile.presence
                            or "unknown")
                        .. " / " .. destination,
                    listDetail = MobileModel.StateText(faction.mobile)
                        .. "  /  " .. tostring(faction.mobile.presence
                            or "unknown")
                        .. "  /  " .. destination,
                    faction = faction,
                    pool = pool,
                    category = category,
                    categoryLabel = Model.MobileCategoryLabel(category),
                    categoryTone = Model.MobileCategoryTone(category),
                }
            end
        end
    end
    table.sort(output, function(left, right)
        local leftOrder = MOBILE_CATEGORY_ORDER[left.category]
            or MOBILE_POOL_ORDER[left.pool] or 99
        local rightOrder = MOBILE_CATEGORY_ORDER[right.category]
            or MOBILE_POOL_ORDER[right.pool] or 99
        if leftOrder ~= rightOrder then
            return leftOrder < rightOrder
        end
        if left.label ~= right.label then
            return left.label < right.label
        end
        return tostring(left.id) < tostring(right.id)
    end)
    return output
end

function Model.BuildMobileRows(snapshot, authorized, reason)
    if authorized ~= true then
        return {
            row("Access", "Admin/debug mode required", "danger"),
        }
    end
    snapshot = snapshot or {}
    local counts = Model.BuildMobilePoolCounts(snapshot)
    local departure = snapshot.mobileDeparture or {}
    local playerBaseCount = math.max(
        0, math.floor(tonumber(departure.playerBaseCount) or 0)
    )
    local rows = {
        row("How to read this tab",
            "Choose a filter above. Every group belongs to one visible pool.",
            "success"),
        row("Your current colony",
            snapshot.currentPlayerFactionID or "not detected",
            snapshot.currentPlayerFactionID and "success" or "warning"),
        row("Player-colony gate",
            playerBaseCount > 0
                and ("OPEN / " .. tostring(playerBaseCount)
                    .. " registered player base(s)")
                or "LOCKED / no registered player base exists",
            playerBaseCount > 0 and "success" or "danger"),
        row("ALL MOBILE GROUPS",
            tostring(counts.all)
                .. " group(s) / all active mobile factions",
            counts.all > 0 and "success" or "textMuted"),
        row("WAITING ON ROAD",
            tostring(counts.staging)
                .. " group(s) / visible road lobby; not traveling yet",
            counts.staging > 0 and "success" or "textMuted"),
        row("TRAVELING TO PLAYER COLONY",
            tostring(counts.player_colony)
                .. " group(s) / abstract traversal toward your colony",
            counts.player_colony > 0 and "danger" or "textMuted"),
        row("TRAVELING TO AI SETTLEMENT",
            tostring(counts.ai_settlement)
                .. " group(s) / abstract traversal toward an AI settlement",
            counts.ai_settlement > 0 and "warning" or "textMuted"),
        row("STREET ROAMING",
            tostring(counts.street_roaming)
                .. " group(s) / ambient behavior or shelter",
            counts.street_roaming > 0 and "warning" or "textMuted"),
        row("Settlement travel total",
            tostring(counts.en_route)
                .. " group(s) / player + AI settlement destinations"),
        row("Waiting on road means", MOBILE_POOL_MEANINGS.staging),
        row("Player travel means", MOBILE_POOL_MEANINGS.player_colony),
        row("AI travel means", MOBILE_POOL_MEANINGS.en_route),
        row("Street roaming means", MOBILE_POOL_MEANINGS.street_roaming),
        row("Quick test",
            "Select a road group, then use Force Settlement Departure."
                .. " It should move into a travel pool."),
        row("Why groups may still be waiting",
            playerBaseCount > 0
                and "The daily roll is chance-based; force a departure to test immediately."
                or "Player-colony travel is disabled until the player creates a base; AI travel still needs an AI settlement."),
        row("Daily departure rule",
            string.format(
                "daytime / every %.0f h / base %.0f%% / sandbox x%.2f / budget %d",
                tonumber(departure.intervalHours) or 24,
                (tonumber(departure.baseChance) or 0.10) * 100,
                tonumber(departure.sandboxMultiplier) or 1,
                tonumber(departure.budget) or 12
            )),
    }
    local selected = snapshot.selectedFaction
    local mobile = selected and selected.mobile or nil
    if mobile and mobile.active == true then
        local pool = Model.MobilePool(
            mobile, snapshot.currentPlayerFactionID)
        local site = mobile.site or {}
        local home = site.home or {}
        rows[#rows + 1] = row(
            "Selected mobile group",
            tostring(selected.name) .. " / " .. tostring(selected.id),
            "success"
        )
        rows[#rows + 1] = row(
            "Selected pool",
            Model.MobileCategoryLabel(Model.MobileCategory(
                mobile, snapshot.currentPlayerFactionID)),
            Model.MobileCategoryTone(Model.MobileCategory(
                mobile, snapshot.currentPlayerFactionID))
        )
        rows[#rows + 1] = row(
            "Lifecycle / presence",
            MobileModel.StateText(mobile)
                .. " / " .. tostring(mobile.presence or "unknown")
        )
        rows[#rows + 1] = row(
            "Activity",
            tostring(mobile.activity or "street_roaming")
        )
        rows[#rows + 1] = row(
            "Destination",
            MobileModel.TargetText(mobile),
            pool == "player_colony" and "danger" or "text"
        )
        if mobile.travel then
            rows[#rows + 1] = row(
                "Travel started",
                tostring(mobile.travel.startedAt or 0)
                    .. " h / departure day "
                    .. tostring(mobile.travel.departureDay or 0),
                "danger"
            )
        end
        rows[#rows + 1] = row(
            "Staging site",
            tostring(site.id or "unknown") .. " @ "
                .. string.format(
                    "%.0f, %.0f, %.0f",
                    tonumber(home.x) or 0,
                    tonumber(home.y) or 0,
                    tonumber(home.z) or 0
                )
        )
    else
        rows[#rows + 1] = row(
            "Selection",
            reason or "Select a mobile group from the list.",
            "textMuted"
        )
    end
    return rows
end

function Model.BuildTargetFactionItems(snapshot)
    local output = Model.BuildFactionItems(snapshot)
    local provisional = snapshot
        and snapshot.currentPlayerDiplomacyFaction or nil
    if provisional then
        output[#output + 1] = {
            id = provisional.id,
            label = provisional.name,
            detail = "Player diplomacy identity / provisional",
            faction = provisional,
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
    if snapshot.currentPlayerDiplomacyFactionID
        and snapshot.currentPlayerDiplomacyFactionID
            ~= snapshot.currentPlayerFactionID
    then
        rows[#rows + 1] = row(
            "Diplomacy identity",
            snapshot.currentPlayerDiplomacyFactionID,
            "textMuted"
        )
    end
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
            "Emblem",
            emblemText(faction.emblem)
        )
        rows[#rows + 1] = row(
            "Created", tostring(faction.createdAt) .. " h"
        )
        rows[#rows + 1] = row(
            "Archived", tostring(faction.archivedAt) .. " h"
        )
        rows[#rows + 1] = row(
            "Tags", enabledKeys(faction.tags)
        )
        local mobile = faction.mobile
        if mobile and mobile.active == true then
            local site = mobile.site or {}
            local home = site.home or {}
            local ambient = mobile.ambient or {}
            local target = mobile.controlMode == "strategic"
                and mobile.strategicTarget or ambient.target
            rows[#rows + 1] = row(
                "Group type", "mobile / "
                    .. tostring(faction.archetypeID)
                    .. " / control="
                    .. tostring(mobile.controlMode or "ambient")
                    .. " / path="
                    .. tostring(mobile.pathMode or "random"),
                "warning"
            )
            rows[#rows + 1] = row(
                "Mobile state",
                MobileModel.StateText(mobile),
                MobileModel.State(mobile) == "en_route"
                    and "danger" or "warning"
            )
            rows[#rows + 1] = row(
                "Mobile objective",
                mobile.controlMode == "strategic"
                    and ("player base / "
                        .. tostring(target and target.baseID
                            or "pending"))
                    or (tostring(ambient.phase or "pending")
                        .. " / "
                        .. tostring(ambient.objective or "pending")),
                mobile.controlMode == "strategic"
                    and "danger" or "warning"
            )
            if target or mobile.travel then
                rows[#rows + 1] = row(
                    "Mobile target",
                    MobileModel.TargetText(mobile)
                )
            end
            if mobile.travel then
                rows[#rows + 1] = row(
                    "Settlement travel",
                    "started " .. tostring(mobile.travel.startedAt or 0)
                        .. " h / day "
                        .. tostring(mobile.travel.departureDay or 0),
                    "danger"
                )
            end
            rows[#rows + 1] = row(
                "Last departure",
                tostring(mobile.lastDepartureAt or -1) .. " h"
            )
            rows[#rows + 1] = row(
                "Mobile staging site",
                tostring(site.id or "unknown")
                    .. " @ " .. string.format(
                        "%.1f, %.1f, %.0f",
                        tonumber(home.x) or 0,
                        tonumber(home.y) or 0,
                        tonumber(home.z) or 0
                    )
            )
            rows[#rows + 1] = row(
                "Next relocation",
                tostring(mobile.nextMoveAt or 0)
                    .. " h / count "
                    .. tostring(mobile.relocationCount or 0)
            )
        end
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
            action.ok
                and (tostring(action.action) .. " / "
                    .. tostring(action.reason))
                or tostring(action.reason),
            action.ok and "success" or "warning"
        )
        local group = action.groupResult
        if group then
            rows[#rows + 1] = row(
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
            rows[#rows + 1] = row(
                "  objective refresh",
                tostring(objective.controlMode or "ambient")
                    .. " / "
                    .. tostring(target and (
                        target.kind or target.siteID
                            or target.baseID
                    ) or "pending")
            )
        end
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
    mobile = true,
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
    if view == "mobile" then
        return Model.BuildMobileRows(snapshot, authorized, reason)
    end
    if dashboard.status ~= "ready" then
        local population = snapshot and snapshot.populationDirector or {}
        local starter = population.starter or {}
        return {
            row("Status", dashboard.status, "warning"),
            row("Population starter", starter.completed and "READY" or "PENDING",
                starter.completed and "success" or "warning"),
            row("Generated population", string.format(
                "settlements=%d groups=%d pending=%d/%d",
                population.currentSettlements or 0,
                population.currentGroups or 0,
                population.pendingSettlements or 0,
                population.pendingGroups or 0)),
            row("Bootstrap phase", tostring(
                population.bootstrapPhase or "initializing")),
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
        if source.mobile and source.mobile.active == true then
            rows[#rows + 1] = row(
                "Mobile lifecycle",
                MobileModel.StateText(source.mobile)
                    .. " / " .. tostring(source.mobile.presence or "unknown"),
                MobileModel.State(source.mobile) == "en_route"
                    and "danger" or "warning"
            )
            rows[#rows + 1] = row(
                "Mobile destination",
                MobileModel.TargetText(source.mobile)
            )
            if source.mobile.travel then
                rows[#rows + 1] = row(
                    "Departure day",
                    tostring(source.mobile.travel.departureDay or 0)
                        .. " / started "
                        .. tostring(source.mobile.travel.startedAt or 0)
                        .. " h"
                )
            end
        end
        rows[#rows + 1] = row("Faction status", source.status)
        rows[#rows + 1] = row(
            "Members",
            tostring(source.memberCount) .. " NPC / "
                .. tostring(source.playerMemberCount) .. " player"
        )
        rows[#rows + 1] = row(
            "Communities",
            tostring(source.communityCount)
                .. " / active population "
                .. tostring(source.communityPopulation)
        )
        rows[#rows + 1] = row(
            "Community names",
            #(source.communityNames or {}) > 0
                and table.concat(
                    source.communityNames,
                    ", "
                ) or "(none)"
        )
        local supplies = source.communitySupplies or {}
        rows[#rows + 1] = row(
            "Community supplies",
            "food=" .. tostring(supplies.food or 0)
                .. " med=" .. tostring(
                    supplies.medicine or 0
                )
                .. " ammo=" .. tostring(
                    supplies.ammunition or 0
                )
                .. " tools=" .. tostring(
                    supplies.tools or 0
                )
                .. " materials=" .. tostring(
                    supplies.materials or 0
                )
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
                "Tactical class",
                dashboard.npc.tacticalClass or "(none)"
            )
            rows[#rows + 1] = row(
                "Identity authority",
                dashboard.npc.factionID or "(none)",
                dashboard.npc.factionID and "success" or "warning"
            )
            rows[#rows + 1] = row(
                "Ownership",
                dashboard.npc.colonyOwned
                    and "colony-owned" or "not colony-owned",
                dashboard.npc.colonyOwned and "success" or "textMuted"
            )
            local identityVerification =
                dashboard.npc.identityVerification
            if identityVerification then
                rows[#rows + 1] = row(
                    "Identity verifier",
                    identityVerification.ok and "PASS" or "FAIL",
                    identityVerification.ok and "success" or "danger"
                )
                rows[#rows + 1] = row(
                    "Verifier errors / warnings",
                    tostring(#(identityVerification.errors or {}))
                        .. " / "
                        .. tostring(#(identityVerification.warnings or {}))
                )
            end
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
