-- Pure presentation model for the developer relationship inspector.

PNC = PNC or {}
PNC.RelationshipDebugModel = PNC.RelationshipDebugModel or {}

local Model = PNC.RelationshipDebugModel
local Graph = PNC.RelationshipGraph
local Presentation = PNC.RelationshipPresentation

local function row(label, value, tone)
    return {
        label = tostring(label or ""),
        value = tostring(value == nil and "" or value),
        tone = tone or "text",
    }
end

local function number(value, decimals)
    return string.format(
        "%." .. tostring(decimals or 2) .. "f",
        tonumber(value) or 0
    )
end

local function signed(value)
    return string.format("%+.2f", tonumber(value) or 0)
end

local function mapValue(value)
    local parts = {}
    local keys = {}
    local key
    if type(value) ~= "table" then
        return tostring(value)
    end
    for key, _ in pairs(value) do
        keys[#keys + 1] = tostring(key)
    end
    table.sort(keys)
    for _, name in ipairs(keys) do
        parts[#parts + 1] = name .. "="
            .. tostring(value[name])
    end
    return #parts > 0 and table.concat(parts, ", ") or "(empty)"
end

local function appendMap(rows, prefix, values)
    local keys = {}
    local key
    for key, _ in pairs(values or {}) do
        keys[#keys + 1] = tostring(key)
    end
    table.sort(keys)
    for _, name in ipairs(keys) do
        rows[#rows + 1] = row(
            prefix .. " " .. name,
            mapValue(values[name])
        )
    end
    if #keys == 0 then
        rows[#rows + 1] = row(prefix, "(none)", "textMuted")
    end
end

local function enabledKeys(values)
    local keys = {}
    local key
    for key, enabled in pairs(values or {}) do
        if enabled == true then
            keys[#keys + 1] = tostring(key)
        end
    end
    table.sort(keys)
    return #keys > 0 and table.concat(keys, ", ") or "(none)"
end

local CONDUCT_DIMENSIONS = {
    "reliability", "generosity", "compassion", "courage",
    "restraint", "honesty", "groupLoyalty",
}

local function appendConduct(rows, title, conduct)
    rows[#rows + 1] = row(title, conduct
        and ("revision " .. tostring(conduct.revision or 0))
        or "(unavailable)", conduct and "success" or "warning")
    if not conduct then return end
    rows[#rows + 1] = row("  entity", conduct.entityKey)
    for _, dimension in ipairs(CONDUCT_DIMENSIONS) do
        rows[#rows + 1] = row(
            "  " .. dimension,
            number(conduct.scores and conduct.scores[dimension])
        )
    end
    rows[#rows + 1] = row(
        "  evidence",
        tostring(conduct.evidenceCount or #(conduct.evidence or {}))
    )
    for index, evidence in ipairs(conduct.evidence or {}) do
        rows[#rows + 1] = row(
            "  " .. tostring(index) .. ". "
                .. tostring(evidence.eventType),
            tostring(evidence.id)
        )
        local effects = {}
        for _, dimension in ipairs(CONDUCT_DIMENSIONS) do
            if evidence.effects
                and evidence.effects[dimension] ~= nil
            then
                effects[#effects + 1] = dimension .. " "
                    .. signed(evidence.effects[dimension])
            end
        end
        rows[#rows + 1] = row(
            "    effects", table.concat(effects, " / ")
        )
        rows[#rows + 1] = row(
            "    strength",
            number(evidence.currentStrength, 4)
                .. " current / decay "
                .. number(evidence.decayPerDay, 4) .. "/day"
        )
        rows[#rows + 1] = row(
            "    visibility",
            tostring(evidence.visibility)
                .. (evidence.shareable and " / shareable" or "")
        )
        rows[#rows + 1] = row(
            "    event", tostring(evidence.eventID)
        )
        rows[#rows + 1] = row(
            "    subject", tostring(evidence.subjectKey)
        )
        rows[#rows + 1] = row(
            "    timestamps",
            number(evidence.createdAt, 3) .. " h created / "
                .. number(evidence.lastEvaluatedAt, 3)
                .. " h evaluated"
        )
        rows[#rows + 1] = row(
            "    tags", enabledKeys(evidence.tags)
        )
    end
end

local function appendFaction(rows, title, faction)
    faction = faction or {}
    rows[#rows + 1] = row(
        title,
        faction.label or "No organizational faction",
        faction.organizationalFaction and "success" or "textMuted"
    )
    if not faction.organizationalFaction then return end
    rows[#rows + 1] = row(
        "  faction ID", faction.factionID
    )
    rows[#rows + 1] = row(
        "  archetype", faction.archetypeID
    )
    rows[#rows + 1] = row(
        "  membership", faction.membershipStatus
    )
    rows[#rows + 1] = row("  role", faction.role)
    rows[#rows + 1] = row("  rank", faction.rank)
    rows[#rows + 1] = row(
        "  affiliation revision",
        faction.affiliationRevision or 0
    )
    if faction.communityID then
        rows[#rows + 1] = row(
            "  community",
            tostring(faction.communityName)
                .. " (" .. tostring(faction.communityID) .. ")"
        )
        rows[#rows + 1] = row(
            "  community role",
            faction.communityRole
        )
        rows[#rows + 1] = row(
            "  inside community home",
            tostring(faction.insideCommunityHome == true)
        )
    end
end

local function signedBand(value)
    value = tonumber(value) or 0
    if value <= -45 then return "very_negative" end
    if value <= -15 then return "negative" end
    if value >= 30 then return "positive" end
    return "neutral"
end

local function grievanceBand(value)
    value = tonumber(value) or 0
    if value >= 65 then return "severe" end
    if value >= 30 then return "high" end
    if value >= 10 then return "moderate" end
    return "low"
end

local function personalityBand(value)
    value = tonumber(value) or 0
    if value < 0.20 then return "Very Low" end
    if value < 0.40 then return "Low" end
    if value < 0.60 then return "Average" end
    if value < 0.80 then return "High" end
    return "Very High"
end

local function conversationDeltaFor(snapshot, conversationDelta, deltas)
    local observer = snapshot and snapshot.observer or {}
    local observerID = tostring(
        observer.npcID or observer.id or observer.key or ""
    )
    if type(deltas) == "table" and observerID ~= ""
        and type(deltas[observerID]) == "table"
    then
        return deltas[observerID]
    end
    if type(conversationDelta) == "table"
        and tostring(conversationDelta.npcID or "") == observerID
    then
        return conversationDelta
    end
    return nil
end

function Model.BuildTargets(roster, observerNPCID)
    local targets = {
        {
            kind = "current_player",
            id = "current_player",
            label = "Current player character",
        },
    }
    for _, item in ipairs(roster or {}) do
        if item.deathMarker ~= true
            and item.alive ~= false
            and tostring(item.id or "") ~=
                tostring(observerNPCID or "")
        then
            targets[#targets + 1] = {
                kind = "npc",
                id = tostring(item.id),
                npcID = tostring(item.id),
                label = tostring(
                    item.name or item.displayName or item.id
                ),
            }
        end
    end
    table.sort(targets, function(left, right)
        if left.kind ~= right.kind then
            return left.kind == "current_player"
        end
        return left.label < right.label
    end)
    return targets
end

function Model.BuildGraph(snapshot, actionID, context)
    context = type(context) == "table" and context or {}
    local relationship = snapshot and snapshot.relationship or {}
    local delta = conversationDeltaFor(
        snapshot,
        context.conversationDelta,
        context.conversationDeltas
    )
    if type(delta) == "table" and delta.after
    then
        relationship = delta.after
    end
    if not Presentation or not Presentation.BuildEvaluation then return nil end
    local modifiers = {}
    local profile = snapshot and snapshot.observer
        and snapshot.observer.personality or {}
    local policy = snapshot and snapshot.observer
        and snapshot.observer.faction
        and snapshot.observer.faction.policy or {}
    local function modifier(id, label, value)
        value = tonumber(value) or 0
        if math.abs(value) < 0.01 then return end
        modifiers[#modifiers + 1] = {
            id = id,
            label = label,
            value = value,
        }
    end
    if actionID == "request_mercy" then
        modifier(
            "compassion",
            "Extorter compassion",
            (tonumber(profile.compassion) or 0) * 20
        )
        modifier(
            "materialism",
            "Extorter materialism",
            -(tonumber(profile.materialism) or 0) * 15
        )
        modifier(
            "aggression",
            "Extorter aggression",
            -(tonumber(profile.aggression) or 0) * 20
        )
    elseif actionID == "challenge_extorter" then
        modifier(
            "caution",
            "Faction caution",
            (tonumber(policy.caution) or 0) * 15
        )
        modifier(
            "aggression",
            "Extorter aggression",
            -(tonumber(profile.aggression) or 0) * 15
        )
    elseif actionID == "offer_less" then
        modifier(
            "materialism",
            "Extorter materialism",
            -(tonumber(profile.materialism) or 0) * 12
        )
    end
    modifier(
        "manual_debug",
        "Manual debug context",
        context.bonus
    )
    return Presentation.BuildEvaluation(
        Presentation.Summarize(relationship, relationship.exists == true),
        actionID or "inspect",
        {
            modifiers = modifiers,
            neutralBand = context.neutralBand,
        }
    )
end

function Model.BuildRows(
    snapshot,
    authorized,
    reason,
    graphEvaluation,
    conversationDelta,
    conversationDeltas
)
    local rows = {}
    local observer
    local target
    local relationship
    local profile
    local reverse
    local action
    local detail
    if authorized ~= true then
        return {
            row("Access", "Admin/debug mode required", "danger"),
        }
    end
    if not snapshot then
        return {
            row("Status", reason or "Select an observer and target",
                reason and "warning" or "textMuted"),
        }
    end
    observer = snapshot.observer or {}
    target = snapshot.target or {}
    relationship = snapshot.relationship or {}
    conversationDelta = conversationDeltaFor(
        snapshot,
        conversationDelta,
        conversationDeltas
    )
    if type(conversationDelta) == "table" and conversationDelta.after
    then
        relationship = conversationDelta.after
    end
    profile = observer.personality or {}
    rows[#rows + 1] = row("Observer", observer.label)
    rows[#rows + 1] = row("Observer key", observer.key)
    rows[#rows + 1] = row("Target", target.label)
    rows[#rows + 1] = row("Target key", target.key)
    appendFaction(rows, "Observer faction", observer.faction)
    appendFaction(rows, "Target faction", target.faction)
    local factionRelation = snapshot.factionRelation
    if factionRelation then
        rows[#rows + 1] = row(
            "Faction relation",
            tostring(factionRelation.state)
                .. " / standing "
                .. tostring(factionRelation.standing)
                .. " / trust "
                .. tostring(factionRelation.trust),
            factionRelation.atWar and "danger" or "text"
        )
        rows[#rows + 1] = row(
            "Faction fear / grievance",
            tostring(factionRelation.fear)
                .. " / " .. tostring(factionRelation.grievance)
        )
        rows[#rows + 1] = row(
            "Faction metric bands",
            "standing=" .. signedBand(factionRelation.standing)
                .. " / trust=" .. signedBand(factionRelation.trust)
                .. " / grievance="
                .. grievanceBand(factionRelation.grievance)
        )
        rows[#rows + 1] = row(
            "Faction treaty",
            "war=" .. tostring(factionRelation.atWar)
                .. " allied=" .. tostring(factionRelation.allied)
                .. " truceUntil="
                .. tostring(factionRelation.truceUntil)
        )
    end
    if snapshot.factionIntent then
        rows[#rows + 1] = row(
            "Faction intent",
            tostring(snapshot.factionIntent.intent)
                .. " / " .. tostring(snapshot.factionIntent.reason)
                .. " / attack="
                .. tostring(snapshot.factionIntent.attackAllowed),
            snapshot.factionIntent.attackAllowed
                and "danger" or "success"
        )
    end
    if snapshot.playerPacification then
        rows[#rows + 1] = row(
            "Player pacification",
            tostring(snapshot.playerPacification.reason)
                .. " / until "
                .. number(
                    snapshot.playerPacification
                        .untilWorldAgeHours,
                    3
                ) .. " h",
            "success"
        )
    elseif target.kind == "player" then
        rows[#rows + 1] = row(
            "Player pacification",
            "inactive",
            "textMuted"
        )
    end
    if snapshot.pacificationAction then
        rows[#rows + 1] = row(
            "Pacification action",
            tostring(snapshot.pacificationAction.reason),
            snapshot.pacificationAction.ok
                and "success" or "warning"
        )
    end
    graphEvaluation = graphEvaluation
        or Model.BuildGraph(snapshot, "inspect")
    if graphEvaluation then
        rows[#rows + 1] = row(
            "Derived attitude",
            tostring(graphEvaluation.attitude)
        )
        rows[#rows + 1] = row(
            "Selected interaction",
            tostring(graphEvaluation.requirement.label)
        )
        if graphEvaluation.requirement.enabled then
            rows[#rows + 1] = row(
                "Interaction score",
                number(graphEvaluation.finalScore)
                    .. " / threshold "
                    .. number(graphEvaluation.threshold)
            )
            rows[#rows + 1] = row(
                "Inside green region",
                tostring(
                    graphEvaluation.insideSuccessRegion
                ),
                graphEvaluation.insideSuccessRegion
                    and "success" or "warning"
            )
            rows[#rows + 1] = row(
                "Score components",
                "base=" .. number(graphEvaluation.baseScore)
                    .. " context="
                    .. signed(graphEvaluation.contextBonus)
            )
        end
    end
    rows[#rows + 1] = row(
        "Snapshot world age",
        number(snapshot.generatedAt, 3) .. " h"
    )
    rows[#rows + 1] = row("Stored record",
        relationship.exists and "yes" or "no (preview defaults)",
        relationship.exists and "success" or "warning")
    rows[#rows + 1] = row("Approval", number(relationship.approval))
    rows[#rows + 1] = row("Respect", number(relationship.respect))
    rows[#rows + 1] = row("Familiarity", number(relationship.familiarity))
    if type(conversationDelta) == "table"
        and tostring(conversationDelta.npcID or "") == tostring(
            observer.npcID or observer.id or observer.key or ""
        )
    then
        local delta = conversationDelta.delta or {}
        rows[#rows + 1] = row(
            "Last conversation",
            tostring(conversationDelta.source or "conversation")
                .. " / " .. tostring(conversationDelta.blockID or "gift"),
            "success"
        )
        rows[#rows + 1] = row(
            "  changed",
            "Approval " .. signed(delta.approval)
                .. " / Respect " .. signed(delta.respect)
                .. " / Familiarity " .. signed(delta.familiarity),
            "success"
        )
        if conversationDelta.effects then
            rows[#rows + 1] = row(
                "  effects",
                mapValue(conversationDelta.effects)
            )
        end
        if conversationDelta.itemTypes then
            rows[#rows + 1] = row(
                "  gift items",
                table.concat(conversationDelta.itemTypes, ", ")
            )
        end
    end
    rows[#rows + 1] = row("State", relationship.state)
    rows[#rows + 1] = row("Previous state", relationship.previousState)
    rows[#rows + 1] = row(
        "Baseline approval",
        number(relationship.baselineApproval)
    )
    rows[#rows + 1] = row(
        "Baseline respect",
        number(relationship.baselineRespect)
    )
    rows[#rows + 1] = row("Morale", number(observer.morale))
    rows[#rows + 1] = row(
        "Morale baseline",
        number(observer.moraleBaseline)
    )
    rows[#rows + 1] = row(
        "Revisions",
        string.format(
            "relationship %s / social %s / record %s / presence %s",
            relationship.revision or 0,
            observer.socialRevision or 0,
            observer.recordRevision or 0,
            observer.presenceRevision or 0
        )
    )
    rows[#rows + 1] = row(
        "Last interaction",
        number(relationship.lastInteractionAt, 3) .. " h"
    )
    rows[#rows + 1] = row(
        "Last evaluated",
        number(relationship.lastEvaluatedAt, 3) .. " h"
    )
    rows[#rows + 1] = row(
        "Personality",
        tostring(profile.socialStyle or "unknown")
    )
    rows[#rows + 1] = row("  orientation", profile.orientation)
    rows[#rows + 1] = row(
        "  food preference", profile.foodPreference
    )
    rows[#rows + 1] = row("  romance style", profile.romanceStyle)
    rows[#rows + 1] = row("  jealousy style", profile.jealousyStyle)
    rows[#rows + 1] = row("  social style", profile.socialStyle)
    rows[#rows + 1] = row(
        "  identity seed", observer.identitySeed or "(unavailable)"
    )
    rows[#rows + 1] = row(
        "  archetype", observer.archetypeID or "(unavailable)"
    )
    for _, dimension in ipairs({
        "compassion", "sociability", "forgiveness", "bravery",
        "materialism", "aggression", "loyalty",
    }) do
        rows[#rows + 1] = row(
            "  " .. dimension,
            number(profile[dimension])
                .. " (" .. personalityBand(profile[dimension]) .. ")"
        )
    end
    reverse = snapshot.reverse
    if reverse then
        rows[#rows + 1] = row("Reverse direction",
            reverse.exists and "stored" or "not stored",
            reverse.exists and "success" or "textMuted")
        rows[#rows + 1] = row(
            "  scores",
            string.format(
                "approval %s / respect %s / familiarity %s",
                number(reverse.approval),
                number(reverse.respect),
                number(reverse.familiarity)
            )
        )
        rows[#rows + 1] = row(
            "  state",
            tostring(reverse.state)
                .. " (revision "
                .. tostring(reverse.revision or 0) .. ")"
        )
    end
    appendMap(rows, "Cooldown", snapshot.cooldowns)
    appendMap(rows, "Saturation", snapshot.saturation)
    appendConduct(rows, "Observer conduct", snapshot.observerConduct)
    appendConduct(rows, "Target conduct", snapshot.targetConduct)
    rows[#rows + 1] = row(
        "Memories",
        tostring(#(snapshot.memories or {}))
    )
    local approvalContribution = 0
    local respectContribution = 0
    for _, memory in ipairs(snapshot.memories or {}) do
        approvalContribution = approvalContribution
            + (tonumber(memory.approvalEffect) or 0)
                * (tonumber(memory.currentStrength) or 0)
        respectContribution = respectContribution
            + (tonumber(memory.respectEffect) or 0)
                * (tonumber(memory.currentStrength) or 0)
    end
    rows[#rows + 1] = row(
        "  contribution total",
        "approval " .. signed(approvalContribution)
            .. " / respect " .. signed(respectContribution)
    )
    for index, memory in ipairs(snapshot.memories or {}) do
        rows[#rows + 1] = row(
            tostring(index) .. ". " .. tostring(memory.type),
            tostring(memory.id),
            memory.permanent and "success" or "text"
        )
        rows[#rows + 1] = row(
            "  effects",
            signed(memory.approvalEffect) .. " approval / "
                .. signed(memory.respectEffect) .. " respect / "
                .. signed(memory.moraleEffect) .. " morale"
        )
        rows[#rows + 1] = row(
            "  strength",
            number(memory.currentStrength, 4)
                .. " current / " .. number(memory.strength, 4)
                .. " stored; decay " .. number(memory.decayPerDay, 4)
                .. "/day"
        )
        rows[#rows + 1] = row(
            "  source",
            tostring(memory.knowledgeSource)
                .. (memory.permanent and " / permanent" or "")
                .. (memory.shareable and " / shareable" or "")
        )
        rows[#rows + 1] = row(
            "  timestamps",
            number(memory.createdAt, 3) .. " h created / "
                .. number(memory.lastEvaluatedAt, 3)
                .. " h evaluated"
        )
        rows[#rows + 1] = row(
            "  tags",
            enabledKeys(memory.tags)
        )
    end
    action = snapshot.actionResult
    if action then
        rows[#rows + 1] = row(
            "Last trigger",
            action.ok == true
                and tostring(action.eventType or "processed")
                or tostring(action.reason or "rejected"),
            action.ok == true and "success" or "warning"
        )
        rows[#rows + 1] = row(
            "  event",
            tostring(action.eventID or "(none)")
        )
        rows[#rows + 1] = row(
            "  changes",
            tostring(action.memoriesCreated or 0)
                .. " memories / "
                .. tostring(action.relationshipsChanged or 0)
                .. " relationships / "
                .. tostring(action.conductEvidenceCreated or 0)
                .. " conduct evidence"
        )
        detail = action.details and action.details[1] or nil
        if detail and detail.baseEffects and detail.modifiedEffects then
            rows[#rows + 1] = row(
                "  approval effect",
                signed(detail.baseEffects.approvalEffect)
                    .. " -> "
                    .. signed(detail.modifiedEffects.approvalEffect)
            )
            rows[#rows + 1] = row(
                "  respect effect",
                signed(detail.baseEffects.respectEffect)
                    .. " -> "
                    .. signed(detail.modifiedEffects.respectEffect)
            )
            rows[#rows + 1] = row(
                "  familiarity",
                signed(detail.baseEffects.familiarityGain)
                    .. " -> "
                    .. signed(detail.modifiedEffects.familiarityGain)
            )
            appendMap(
                rows,
                "  modifier",
                detail.modifierBreakdown
            )
        end
    end
    return rows
end

-- Sections deliberately preserve the separation between personal
-- relationship, personality, memories, conduct, and faction/tactical context.
-- The full row builder remains the single source of presentation data.
function Model.FilterRows(rows, section)
    if section == nil or section == "all" then return rows or {} end
    local output = {}
    local mode = nil
    local relationshipLabels = {
        ["Observer"] = true, ["Observer key"] = true,
        ["Target"] = true, ["Target key"] = true,
        ["Derived attitude"] = true, ["Selected interaction"] = true,
        ["Interaction score"] = true, ["Inside green region"] = true,
        ["Score components"] = true, ["Stored record"] = true,
        ["Approval"] = true, ["Respect"] = true,
        ["Familiarity"] = true, ["State"] = true,
        ["Previous state"] = true, ["Baseline approval"] = true,
        ["Baseline respect"] = true, ["Morale"] = true,
        ["Morale baseline"] = true, ["Reverse direction"] = true,
        ["  scores"] = true, ["  state"] = true,
    }
    local personalityLabels = {
        ["Personality"] = true,
        ["  orientation"] = true, ["  food preference"] = true,
        ["  romance style"] = true, ["  jealousy style"] = true,
        ["  social style"] = true, ["  identity seed"] = true,
        ["  archetype"] = true,
        ["  compassion"] = true, ["  sociability"] = true,
        ["  forgiveness"] = true, ["  bravery"] = true,
        ["  materialism"] = true, ["  aggression"] = true,
        ["  loyalty"] = true,
    }
    local diagnosticsLabels = {
        ["Snapshot world age"] = true, ["Revisions"] = true,
        ["Last interaction"] = true, ["Last evaluated"] = true,
    }
    for _, item in ipairs(rows or {}) do
        local label = tostring(item.label or "")
        local include = false
        if section == "relationship" then
            include = relationshipLabels[label] == true
        elseif section == "personality" then
            include = personalityLabels[label] == true
        elseif section == "context" then
            include = string.find(label, "faction", 1, true) ~= nil
                or string.find(label, "Faction", 1, true) ~= nil
                or label == "Player pacification"
        elseif section == "conduct" then
            if label == "Observer conduct" or label == "Target conduct" then
                mode = "conduct"
            elseif mode == "conduct" and string.sub(label, 1, 2) ~= "  " then
                mode = nil
            end
            include = mode == "conduct"
        elseif section == "memories" then
            if label == "Memories" then
                mode = "memories"
            elseif mode == "memories" and label == "Last trigger" then
                mode = nil
            end
            include = mode == "memories"
        elseif section == "trace" then
            if label == "Last trigger" then mode = "trace" end
            include = mode == "trace"
        elseif section == "diagnostics" then
            include = diagnosticsLabels[label] == true
        end
        if include then output[#output + 1] = item end
    end
    if #output == 0 then
        output[1] = row("Status", "No data for this section", "textMuted")
    end
    return output
end

return Model
