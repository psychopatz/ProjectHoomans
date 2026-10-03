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


Model.Internal = Model.Internal or {}
Model.Internal.row = row
Model.Internal.number = number
Model.Internal.signed = signed
Model.Internal.mapValue = mapValue
Model.Internal.appendMap = appendMap
Model.Internal.enabledKeys = enabledKeys
Model.Internal.appendConduct = appendConduct
Model.Internal.appendFaction = appendFaction
Model.Internal.signedBand = signedBand
Model.Internal.grievanceBand = grievanceBand
Model.Internal.personalityBand = personalityBand
Model.Internal.conversationDeltaFor = conversationDeltaFor

return Model
