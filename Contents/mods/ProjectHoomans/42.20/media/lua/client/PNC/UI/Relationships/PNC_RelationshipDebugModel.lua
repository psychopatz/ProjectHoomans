-- Pure presentation model for the developer relationship inspector.

PNC = PNC or {}
PNC.RelationshipDebugModel = PNC.RelationshipDebugModel or {}

local Model = PNC.RelationshipDebugModel

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

function Model.BuildRows(snapshot, authorized, reason)
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
    for _, dimension in ipairs({
        "compassion", "sociability", "forgiveness", "bravery",
        "materialism", "aggression", "loyalty",
    }) do
        rows[#rows + 1] = row(
            "  " .. dimension,
            number(profile[dimension])
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

return Model
