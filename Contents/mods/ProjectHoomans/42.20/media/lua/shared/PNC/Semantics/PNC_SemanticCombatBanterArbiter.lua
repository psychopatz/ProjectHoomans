-- Unified runtime arbiter for semantic combat chatter.
-- It owns bounded coalescing/budgets/priority only; combat facts, semantic
-- realization, gameplay authority and persistence stay with their owners.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Arbiter = PNC.Semantics.CombatBanterArbiter or {}
PNC.Semantics.CombatBanterArbiter = Arbiter

Arbiter.VERSION = 1
Arbiter.DECISION_LIMIT = 64
Arbiter.STATE_LIMIT = 256
Arbiter.PRIORITY_HOLD_MS = 2500
Arbiter.Streams = Arbiter.Streams or {}
Arbiter.StreamOrder = Arbiter.StreamOrder or {}
Arbiter.Speakers = Arbiter.Speakers or {}
Arbiter.SpeakerOrder = Arbiter.SpeakerOrder or {}
Arbiter.Families = Arbiter.Families or {}
Arbiter.FamilyOrder = Arbiter.FamilyOrder or {}
Arbiter.Teams = Arbiter.Teams or {}
Arbiter.TeamOrder = Arbiter.TeamOrder or {}
Arbiter.Decisions = Arbiter.Decisions or {}
Arbiter.DecisionSequence = tonumber(Arbiter.DecisionSequence) or 0

local function clean(value)
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function boundedState(map, order, key)
    key = clean(key)
    if not key then return nil end
    local state = map[key]
    if state then return state end
    while #order >= Arbiter.STATE_LIMIT do
        local oldest = table.remove(order, 1)
        map[oldest] = nil
    end
    state = { key = key }
    map[key] = state
    order[#order + 1] = key
    return state
end

local function recordDecision(spec)
    Arbiter.DecisionSequence = Arbiter.DecisionSequence + 1
    local row = {
        sequence = Arbiter.DecisionSequence,
        accepted = spec.accepted == true,
        stage = tostring(spec.stage or "unknown"),
        reason = tostring(spec.reason or "unknown"),
        at = tonumber(spec.at) or 0,
        streamKey = clean(spec.streamKey),
        speakerID = clean(spec.speakerID),
        audienceKey = clean(spec.audienceKey),
        family = clean(spec.family),
        momentKind = clean(spec.moment and spec.moment.kind),
        eventType = clean(spec.moment and spec.moment.eventType),
        priority = tonumber(spec.priority
            or spec.moment and spec.moment.priority) or 0,
        burstCount = tonumber(spec.burstCount) or nil,
    }
    while #Arbiter.Decisions >= Arbiter.DECISION_LIMIT do
        table.remove(Arbiter.Decisions, 1)
    end
    Arbiter.Decisions[#Arbiter.Decisions + 1] = row
    return row
end

function Arbiter.Begin(spec)
    spec = type(spec) == "table" and spec or {}
    local now = tonumber(spec.now) or 0
    local streamKey = clean(spec.streamKey)
    if not streamKey then return nil, "stream_key_missing" end
    local state = boundedState(
        Arbiter.Streams, Arbiter.StreamOrder, streamKey
    )
    state.suppressed = math.min(
        99, math.max(0, math.floor(tonumber(state.suppressed) or 0)) + 1
    )
    if now < (tonumber(state.nextEligibleAt) or 0) then
        recordDecision({
            accepted = false,
            stage = "stream",
            reason = "stream_cooldown",
            at = now,
            streamKey = streamKey,
            moment = spec.moment,
            priority = spec.priority,
            burstCount = state.suppressed,
        })
        return nil, "stream_cooldown", state.suppressed
    end
    local burst = state.suppressed
    state.suppressed = 0
    state.nextEligibleAt = now + math.max(
        0, tonumber(spec.cooldownMs) or 0
    )
    state.lastAcceptedAt = now
    state.priority = tonumber(
        spec.priority or spec.moment and spec.moment.priority
    ) or 0
    local gate = {
        streamKey = streamKey,
        now = now,
        moment = spec.moment,
        burstCount = burst,
        maxSpeakers = math.max(
            1, math.floor(tonumber(spec.maxSpeakers) or 1)
        ),
        acceptedSpeakers = 0,
    }
    recordDecision({
        accepted = true,
        stage = "stream",
        reason = "stream_open",
        at = now,
        streamKey = streamKey,
        moment = spec.moment,
        priority = state.priority,
        burstCount = burst,
    })
    return gate, "stream_open", burst
end

function Arbiter.Consider(gate, spec)
    spec = type(spec) == "table" and spec or {}
    if type(gate) ~= "table" then return false, "stream_closed" end
    local now = tonumber(spec.now) or tonumber(gate.now) or 0
    local moment = spec.moment or gate.moment or {}
    local priority = tonumber(spec.priority or moment.priority) or 0
    local speakerID = clean(spec.speakerID)
    local audienceKey = clean(spec.audienceKey) or "local"
    local family = clean(spec.family) or clean(moment.kind) or "combat"
    local base = {
        at = now,
        streamKey = gate.streamKey,
        speakerID = speakerID,
        audienceKey = audienceKey,
        family = family,
        moment = moment,
        priority = priority,
        burstCount = gate.burstCount,
    }

    if gate.acceptedSpeakers >= gate.maxSpeakers then
        base.accepted = false
        base.stage = "budget"
        base.reason = "team_budget"
        recordDecision(base)
        return false, "team_budget"
    end

    local team = boundedState(Arbiter.Teams, Arbiter.TeamOrder, audienceKey)
    if now < (tonumber(team.priorityUntil) or 0)
        and priority < (tonumber(team.priority) or 0)
    then
        base.accepted = false
        base.stage = "priority"
        base.reason = "higher_priority_active"
        recordDecision(base)
        return false, "higher_priority_active"
    end

    if speakerID then
        local speaker = boundedState(
            Arbiter.Speakers, Arbiter.SpeakerOrder, speakerID
        )
        if now < (tonumber(speaker.nextEligibleAt) or 0) then
            base.accepted = false
            base.stage = "speaker"
            base.reason = "speaker_cooldown"
            recordDecision(base)
            return false, "speaker_cooldown"
        end
    end

    local familyKey = table.concat({
        audienceKey, family, speakerID or "any"
    }, "|")
    local familyState = boundedState(
        Arbiter.Families, Arbiter.FamilyOrder, familyKey
    )
    if now < (tonumber(familyState.nextEligibleAt) or 0) then
        base.accepted = false
        base.stage = "family"
        base.reason = "family_cooldown"
        recordDecision(base)
        return false, "family_cooldown"
    end

    gate.acceptedSpeakers = gate.acceptedSpeakers + 1
    if speakerID then
        local speaker = Arbiter.Speakers[speakerID]
        speaker.nextEligibleAt = now + math.max(
            0, tonumber(spec.speakerCooldownMs) or 0
        )
        speaker.lastFamily = family
        speaker.lastAcceptedAt = now
    end
    familyState.nextEligibleAt = now + math.max(
        0, tonumber(spec.familyCooldownMs) or 0
    )
    familyState.lastAcceptedAt = now
    if priority >= (tonumber(team.priority) or 0)
        or now >= (tonumber(team.priorityUntil) or 0)
    then
        team.priority = priority
        team.priorityUntil = now + math.max(
            0,
            tonumber(spec.priorityHoldMs)
                or Arbiter.PRIORITY_HOLD_MS
        )
        team.lastFamily = family
        team.lastSpeakerID = speakerID
    end

    base.accepted = true
    base.stage = "speaker"
    base.reason = "speak"
    recordDecision(base)
    return true, "speak"
end

function Arbiter.Reserve(spec)
    spec = type(spec) == "table" and spec or {}
    local gate, reason, burst = Arbiter.Begin(spec)
    if not gate then return false, reason, burst end
    local accepted, speakerReason = Arbiter.Consider(gate, spec)
    return accepted, speakerReason, burst, gate
end

function Arbiter.Snapshot(limit)
    limit = math.max(
        1,
        math.min(Arbiter.DECISION_LIMIT, math.floor(tonumber(limit) or 16))
    )
    local output = {
        schema = "semantic.combat.banter_arbiter.v1",
        decisionSequence = Arbiter.DecisionSequence,
        decisions = {},
    }
    local first = math.max(1, #Arbiter.Decisions - limit + 1)
    for index = first, #Arbiter.Decisions do
        local source = Arbiter.Decisions[index]
        local copy = {}
        for key, value in pairs(source) do copy[key] = value end
        output.decisions[#output.decisions + 1] = copy
    end
    return output
end

function Arbiter.ResetRuntime()
    Arbiter.Streams = {}
    Arbiter.StreamOrder = {}
    Arbiter.Speakers = {}
    Arbiter.SpeakerOrder = {}
    Arbiter.Families = {}
    Arbiter.FamilyOrder = {}
    Arbiter.Teams = {}
    Arbiter.TeamOrder = {}
    Arbiter.Decisions = {}
    Arbiter.DecisionSequence = 0
end

return Arbiter
