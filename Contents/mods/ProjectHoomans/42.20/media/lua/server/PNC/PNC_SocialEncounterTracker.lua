-- Minimal server-runtime combat encounter aggregation for social milestones.
-- This table is intentionally not persisted and contains no engine objects.

if isClient and isClient() and (not isServer or not isServer()) then
    return
end

PNC = PNC or {}
PNC.SocialEncounterTracker = PNC.SocialEncounterTracker or {}

local Tracker = PNC.SocialEncounterTracker
local EntityRef = PNC.EntityRef
local Registry = PNC.Registry

local MIN_DURATION_HOURS = 5 / 3600
local END_GRACE_HOURS = 15 / 3600
local ABANDON_GRACE_HOURS = 10 / 3600
local PUMP_INTERVAL_HOURS = 1 / 3600
local ABANDON_DISTANCE = 20

Tracker.Encounters = Tracker.Encounters or {}
Tracker.ByParticipant = Tracker.ByParticipant or {}
Tracker.ByThreat = Tracker.ByThreat or {}
Tracker.NextSequence = Tracker.NextSequence or 0
Tracker.LastPumpAt = Tracker.LastPumpAt

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil
        or value ~= value
        or value == math.huge
        or value == -math.huge
    then
        return fallback
    end
    return value
end

local function validKey(value)
    return type(value) == "string" and EntityRef.IsValid(value)
end

local function makeEncounterID(now, anchorKey)
    Tracker.NextSequence = Tracker.NextSequence + 1
    return "encounter:"
        .. tostring(math.floor(math.max(0, now) * 3600000))
        .. ":" .. tostring(anchorKey)
        .. ":" .. tostring(Tracker.NextSequence)
end

local function countEntries(value)
    local count = 0
    local _
    for _, _ in pairs(value or {}) do
        count = count + 1
    end
    return count
end

local function addParticipant(encounter, key, now, spec)
    local participant
    local isNew
    if not validKey(key) then
        return nil
    end
    isNew = encounter.participants[key] == nil
    participant = encounter.participants[key] or {
        key = key,
        joinedAt = now,
        lastAt = now,
        tookDamage = false,
        alive = true,
        present = true,
        eligibleForShared = true,
    }
    participant.lastAt = math.max(participant.lastAt, now)
    participant.present = true
    participant.eligibleForShared = true
    participant.x = finite(spec and spec.x, participant.x)
    participant.y = finite(spec and spec.y, participant.y)
    participant.z = finite(spec and spec.z, participant.z)
    if spec and spec.tookDamage == true then
        participant.tookDamage = true
    end
    if spec and spec.alive == false then
        participant.alive = false
    end
    encounter.participants[key] = participant
    Tracker.ByParticipant[key] = encounter.id
    if isNew
        and PNC.PlayerCharacterDebug
        and PNC.PlayerCharacterDebug.LogCombat
    then
        PNC.PlayerCharacterDebug.LogCombat({
            callback = "encounter_join",
            event = "participant_added",
            encounterID = encounter.id,
            worldAgeHours = now,
            result = "recorded",
        })
    end
    return participant
end

local function findEncounter(spec)
    local encounter
    if spec.encounterID then
        encounter = Tracker.Encounters[spec.encounterID]
    end
    if not encounter and spec.threatID then
        encounter = Tracker.Encounters[
            Tracker.ByThreat[tostring(spec.threatID)]
        ]
    end
    if not encounter and validKey(spec.actorKey) then
        encounter = Tracker.Encounters[
            Tracker.ByParticipant[spec.actorKey]
        ]
    end
    if not encounter and validKey(spec.targetKey) then
        encounter = Tracker.Encounters[
            Tracker.ByParticipant[spec.targetKey]
        ]
    end
    return encounter
end

local function newEncounter(spec, now)
    local anchor = spec.targetKey or spec.actorKey
        or ("threat:" .. tostring(spec.threatID or "unknown"))
    local id = spec.encounterID or makeEncounterID(now, anchor)
    local encounter = {
        id = id,
        startedAt = now,
        lastThreatAt = now,
        participants = {},
        threatIDs = {},
        activeThreatIDs = {},
        threatTargets = {},
        damageByParticipant = {},
        killsByParticipant = {},
        protectedTargetPairs = {},
        abandonmentCandidates = {},
        abandonmentConfirmed = {},
        x = finite(spec.x, 0),
        y = finite(spec.y, 0),
        z = finite(spec.z, 0),
    }
    Tracker.Encounters[id] = encounter
    return encounter
end

local function targetActiveThreatCount(encounter, targetKey)
    local count = 0
    local threatID
    for threatID, _ in pairs(encounter.activeThreatIDs) do
        if encounter.threatTargets[threatID] == targetKey then
            count = count + 1
        end
    end
    return count
end

local function npcRecordForKey(key)
    local parsed = EntityRef.Parse(key)
    if not parsed or parsed.kind ~= "npc" then
        return nil
    end
    return Registry and Registry.Get and Registry.Get(parsed.npcID) or nil
end

local function participantAlive(encounter, key)
    local participant = encounter.participants[key]
    local record = npcRecordForKey(key)
    if record then
        return record.alive ~= false
    end
    return participant and participant.alive ~= false
end

local function participantCapable(encounter, key)
    local record = npcRecordForKey(key)
    if record then
        return record.alive ~= false
            and not (record.health
                and record.health.state == "incapacitated")
    end
    return participantAlive(encounter, key)
end

local function targetInSeriousDanger(encounter, targetKey)
    local participant = encounter.participants[targetKey]
    local record = npcRecordForKey(targetKey)
    local threatCount = targetActiveThreatCount(encounter, targetKey)
    if threatCount <= 0 or not participantAlive(encounter, targetKey) then
        return false
    end
    if participant and participant.present == false then
        return false
    end
    return threatCount >= 2
        or (participant and participant.tookDamage == true)
        or (record and record.health
            and record.health.state == "incapacitated")
end

local function emit(spec)
    if not PNC.SocialEvents or not PNC.SocialEvents.Emit then
        return { ok = false, reason = "social_event_service_unavailable" }
    end
    return PNC.SocialEvents.Emit(spec)
end

function Tracker.Reset()
    Tracker.Encounters = {}
    Tracker.ByParticipant = {}
    Tracker.ByThreat = {}
    Tracker.NextSequence = 0
    Tracker.LastPumpAt = nil
end

function Tracker.GetEncounter(encounterID)
    return Tracker.Encounters[encounterID]
end

function Tracker.RecordActivity(spec)
    local now
    local encounter
    local threatID
    if type(spec) ~= "table" then
        return nil, "invalid_activity"
    end
    now = finite(spec.occurredAt, nil)
    if not now or now < 0 then
        return nil, "invalid_timestamp"
    end
    if not validKey(spec.actorKey) and not validKey(spec.targetKey) then
        return nil, "missing_participant"
    end
    encounter = findEncounter(spec) or newEncounter(spec, now)
    encounter.lastThreatAt = math.max(encounter.lastThreatAt, now)
    addParticipant(encounter, spec.actorKey, now, {
        x = spec.actorX or spec.x,
        y = spec.actorY or spec.y,
        z = spec.actorZ or spec.z,
        tookDamage = spec.actorTookDamage,
    })
    addParticipant(encounter, spec.targetKey, now, {
        x = spec.targetX or spec.x,
        y = spec.targetY or spec.y,
        z = spec.targetZ or spec.z,
        tookDamage = spec.targetTookDamage,
    })
    threatID = spec.threatID and tostring(spec.threatID) or nil
    if threatID and threatID ~= "" then
        encounter.threatIDs[threatID] = true
        encounter.activeThreatIDs[threatID] = true
        Tracker.ByThreat[threatID] = encounter.id
        if validKey(spec.targetKey)
            and spec.threatWasTargeting ~= false
        then
            encounter.threatTargets[threatID] = spec.targetKey
        end
    end
    if validKey(spec.actorKey) then
        local candidateKey
        for candidateKey, _ in pairs(encounter.abandonmentCandidates) do
            if string.sub(
                candidateKey,
                1,
                #spec.actorKey + 2
            ) == spec.actorKey .. "->"
            then
                encounter.abandonmentCandidates[candidateKey] = nil
            end
        end
    end
    return encounter.id, "recorded"
end

function Tracker.RecordNPCDamaged(
    targetRecord,
    threatID,
    occurredAt,
    position
)
    local targetKey = targetRecord
        and EntityRef.ForNPC(targetRecord.id) or nil
    local encounterID
    local reason
    if not targetKey or threatID == nil then
        return nil, "invalid_damage_activity"
    end
    encounterID, reason = Tracker.RecordActivity({
        targetKey = targetKey,
        threatID = tostring(threatID),
        threatWasTargeting = true,
        targetTookDamage = true,
        occurredAt = occurredAt,
        x = position and position.x or targetRecord.x,
        y = position and position.y or targetRecord.y,
        z = position and position.z or targetRecord.z,
    })
    local encounter = encounterID and Tracker.Encounters[encounterID]
    if encounter then
        encounter.damageByParticipant[targetKey] =
            (encounter.damageByParticipant[targetKey] or 0) + 1
    end
    return encounterID, reason
end

function Tracker.OnThreatNeutralized(spec)
    local now
    local encounter
    local encounterID
    local threatID
    local targetKey
    local pairKey
    local eventResult
    if type(spec) ~= "table"
        or not validKey(spec.actorKey)
        or spec.threatID == nil
    then
        return false, "invalid_neutralization"
    end
    now = finite(spec.occurredAt, nil)
    if not now then
        return false, "invalid_timestamp"
    end
    threatID = tostring(spec.threatID)
    encounter = findEncounter(spec)
    if not encounter then
        -- A neutralization alone is not evidence of protection. Record the
        -- actor's combat participation, but do not infer a protected target.
        encounterID = Tracker.RecordActivity({
            actorKey = spec.actorKey,
            threatID = threatID,
            threatWasTargeting = false,
            occurredAt = now,
            x = spec.x,
            y = spec.y,
            z = spec.z,
        })
        encounter = encounterID and Tracker.Encounters[encounterID]
    else
        addParticipant(encounter, spec.actorKey, now, spec)
        encounter.lastThreatAt = math.max(encounter.lastThreatAt, now)
    end
    if not encounter then
        return false, "encounter_unavailable"
    end
    encounter.threatIDs[threatID] = true
    encounter.activeThreatIDs[threatID] = nil
    Tracker.ByThreat[threatID] = encounter.id
    encounter.killsByParticipant[spec.actorKey] =
        (encounter.killsByParticipant[spec.actorKey] or 0) + 1
    targetKey = encounter.threatTargets[threatID]
    if not targetKey
        and spec.threatWasTargeting == true
        and validKey(spec.targetKey)
    then
        targetKey = spec.targetKey
        encounter.threatTargets[threatID] = targetKey
        addParticipant(encounter, targetKey, now, spec)
    end
    if not targetKey
        or not EntityRef.IsNPC(targetKey)
        or not participantAlive(encounter, targetKey)
    then
        return true, "neutralized_without_protection", encounter.id
    end
    pairKey = spec.actorKey .. "->" .. targetKey
    if encounter.protectedTargetPairs[pairKey] then
        return true, "protection_already_aggregated", encounter.id
    end
    eventResult = emit({
        id = "social:protect:" .. encounter.id .. ":"
            .. spec.actorKey .. ":" .. targetKey,
        type = "protected_from_attacker",
        actorKey = spec.actorKey,
        targetKey = targetKey,
        occurredAt = now,
        sourceSystem = "combat",
        x = finite(spec.x, encounter.x),
        y = finite(spec.y, encounter.y),
        z = finite(spec.z, encounter.z),
        context = {
            encounterID = encounter.id,
            threatID = threatID,
            attribution = "targeted_threat_neutralized",
        },
    })
    if eventResult.ok or eventResult.reason == "duplicate_event" then
        encounter.protectedTargetPairs[pairKey] = true
    end
    return eventResult.ok == true, eventResult.reason, encounter.id
end

function Tracker.MarkPotentialAbandonment(
    encounterID,
    actorKey,
    targetKey,
    occurredAt,
    reason
)
    local encounter = Tracker.Encounters[encounterID]
    local key
    if not encounter
        or not encounter.participants[actorKey]
        or not encounter.participants[targetKey]
        or actorKey == targetKey
        or not targetInSeriousDanger(encounter, targetKey)
        or not participantCapable(encounter, actorKey)
    then
        return false, "abandonment_not_qualified"
    end
    key = actorKey .. "->" .. targetKey
    if encounter.abandonmentConfirmed[key] then
        return false, "abandonment_already_confirmed"
    end
    encounter.abandonmentCandidates[key] = {
        actorKey = actorKey,
        targetKey = targetKey,
        markedAt = occurredAt,
        confirmAt = occurredAt + ABANDON_GRACE_HOURS,
        reason = tostring(reason or "left_encounter"),
    }
    return true, "abandonment_pending"
end

function Tracker.CancelAbandonment(
    encounterID,
    actorKey,
    targetKey
)
    local encounter = Tracker.Encounters[encounterID]
    local key = tostring(actorKey) .. "->" .. tostring(targetKey)
    if not encounter or not encounter.abandonmentCandidates[key] then
        return false
    end
    encounter.abandonmentCandidates[key] = nil
    return true
end

function Tracker.UpdateParticipantPosition(
    actorKey,
    x,
    y,
    z,
    occurredAt
)
    local encounter = Tracker.Encounters[Tracker.ByParticipant[actorKey]]
    local participant
    local candidateKey
    if not encounter then
        return false, "encounter_not_found"
    end
    participant = addParticipant(encounter, actorKey, occurredAt, {
        x = x,
        y = y,
        z = z,
    })
    for candidateKey, _ in pairs(encounter.abandonmentCandidates) do
        if string.sub(candidateKey, 1, #actorKey + 2)
            == actorKey .. "->"
        then
            encounter.abandonmentCandidates[candidateKey] = nil
        end
    end
    return participant ~= nil, "position_updated"
end

function Tracker.OnParticipantLeft(actorKey, occurredAt, reason)
    local encounter = Tracker.Encounters[Tracker.ByParticipant[actorKey]]
    local targetKey
    local candidateKey
    local candidate
    local marked = 0
    reason = tostring(reason or "left_encounter")
    if not encounter then
        return false, "not_an_abandonment_departure"
    end
    if encounter.participants[actorKey] then
        encounter.participants[actorKey].present = false
        encounter.participants[actorKey].eligibleForShared = false
    end
    for candidateKey, candidate
        in pairs(encounter.abandonmentCandidates)
    do
        if candidate.targetKey == actorKey then
            encounter.abandonmentCandidates[candidateKey] = nil
        end
    end
    if reason == "death"
        or reason == "incapacitated"
        or reason == "forced_separation"
    then
        return false, "not_an_abandonment_departure"
    end
    for targetKey, _ in pairs(encounter.participants) do
        if targetKey ~= actorKey
            and Tracker.MarkPotentialAbandonment(
                encounter.id,
                actorKey,
                targetKey,
                occurredAt,
                reason
            )
        then
            marked = marked + 1
        end
    end
    return marked > 0, marked > 0
        and "abandonment_pending" or "no_endangered_target"
end

local function encounterQualifies(encounter, endedAt)
    local participant
    local tookDamage = false
    for _, participant in pairs(encounter.participants) do
        if participant.tookDamage then
            tookDamage = true
            break
        end
    end
    return endedAt - encounter.startedAt >= MIN_DURATION_HOURS
        or countEntries(encounter.threatIDs) >= 2
        or tookDamage
end

local function releaseEncounter(encounter)
    local key
    local threatID
    for key, _ in pairs(encounter.participants) do
        if Tracker.ByParticipant[key] == encounter.id then
            Tracker.ByParticipant[key] = nil
        end
    end
    for threatID, _ in pairs(encounter.threatIDs) do
        if Tracker.ByThreat[threatID] == encounter.id then
            Tracker.ByThreat[threatID] = nil
        end
    end
    Tracker.Encounters[encounter.id] = nil
end

function Tracker.EndEncounter(encounterID, occurredAt)
    local encounter = Tracker.Encounters[encounterID]
    local keys = {}
    local left
    local right
    local i
    local j
    local resultValue
    local emitted = 0
    occurredAt = finite(occurredAt, nil)
    if not encounter or not occurredAt then
        return false, "encounter_not_found", 0
    end
    if PNC.PlayerCharacterDebug
        and PNC.PlayerCharacterDebug.LogCombat
    then
        PNC.PlayerCharacterDebug.LogCombat({
            callback = "encounter_end",
            event = "EndEncounter",
            encounterID = encounterID,
            worldAgeHours = occurredAt,
            result = "received",
        })
    end
    if encounterQualifies(encounter, occurredAt) then
        for left, _ in pairs(encounter.participants) do
            if participantAlive(encounter, left)
                and encounter.participants[left].eligibleForShared ~= false
            then
                keys[#keys + 1] = left
            end
        end
        table.sort(keys)
        for i = 1, #keys do
            for j = i + 1, #keys do
                left = keys[i]
                right = keys[j]
                if EntityRef.IsNPC(left) or EntityRef.IsNPC(right) then
                    resultValue = emit({
                        id = "social:shared_combat:" .. encounter.id
                            .. ":" .. left .. ":" .. right,
                        type = "survived_combat_together",
                        actorKey = left,
                        targetKey = right,
                        occurredAt = occurredAt,
                        sourceSystem = "combat",
                        x = encounter.x,
                        y = encounter.y,
                        z = encounter.z,
                        context = {
                            encounterID = encounter.id,
                            threatCount =
                                countEntries(encounter.threatIDs),
                            durationHours =
                                occurredAt - encounter.startedAt,
                        },
                    })
                    if resultValue.ok then
                        emitted = emitted
                            + (resultValue.memoriesCreated or 0)
                    end
                end
            end
        end
    end
    releaseEncounter(encounter)
    return true, emitted > 0
        and "encounter_socialized" or "encounter_not_qualifying",
        emitted
end

function Tracker.Pump(occurredAt)
    local encounterID
    local encounter
    local candidateKey
    local candidate
    local eventResult
    local toEnd = {}
    local actorKey
    local targetKey
    local actor
    local target
    local distanceSq
    occurredAt = finite(occurredAt, nil)
    if not occurredAt then
        return 0
    end
    if Tracker.LastPumpAt
        and occurredAt - Tracker.LastPumpAt < PUMP_INTERVAL_HOURS
    then
        return 0
    end
    Tracker.LastPumpAt = occurredAt
    for encounterID, encounter in pairs(Tracker.Encounters) do
        -- Only NPC positions are refreshed here because their authoritative
        -- records are directly available. Player distance is not guessed from
        -- stale online IDs; player departure needs an explicit adapter call.
        for actorKey, actor in pairs(encounter.participants) do
            local actorRecord = npcRecordForKey(actorKey)
            if actorRecord then
                actor.x = tonumber(actorRecord.x) or actor.x
                actor.y = tonumber(actorRecord.y) or actor.y
                actor.z = tonumber(actorRecord.z) or actor.z
            end
        end
        for actorKey, actor in pairs(encounter.participants) do
            if EntityRef.IsNPC(actorKey)
                and actor.present ~= false
                and actor.x ~= nil
                and actor.y ~= nil
            then
                for targetKey, target
                    in pairs(encounter.participants)
                do
                    if targetKey ~= actorKey
                        and EntityRef.IsNPC(targetKey)
                        and target.x ~= nil
                        and target.y ~= nil
                        and math.abs(
                            (tonumber(actor.z) or 0)
                                - (tonumber(target.z) or 0)
                        ) < 1
                    then
                        distanceSq =
                            ((actor.x - target.x) ^ 2)
                            + ((actor.y - target.y) ^ 2)
                        if distanceSq
                            > (ABANDON_DISTANCE ^ 2)
                        then
                            local candidateKey =
                                actorKey .. "->" .. targetKey
                            if not encounter.abandonmentCandidates[
                                candidateKey
                            ] then
                                Tracker.MarkPotentialAbandonment(
                                    encounter.id,
                                    actorKey,
                                    targetKey,
                                    occurredAt,
                                    "left_combat_radius"
                                )
                            end
                        else
                            Tracker.CancelAbandonment(
                                encounter.id,
                                actorKey,
                                targetKey
                            )
                        end
                    end
                end
            end
        end
        for candidateKey, candidate
            in pairs(encounter.abandonmentCandidates)
        do
            if occurredAt >= candidate.confirmAt then
                if targetInSeriousDanger(
                    encounter,
                    candidate.targetKey
                ) and participantCapable(
                    encounter,
                    candidate.actorKey
                ) then
                    eventResult = emit({
                        id = "social:abandon:" .. encounter.id
                            .. ":" .. candidate.actorKey
                            .. ":" .. candidate.targetKey,
                        type = "abandoned_in_combat",
                        actorKey = candidate.actorKey,
                        targetKey = candidate.targetKey,
                        occurredAt = occurredAt,
                        sourceSystem = "combat",
                        x = encounter.x,
                        y = encounter.y,
                        z = encounter.z,
                        context = {
                            encounterID = encounter.id,
                            graceHours =
                                occurredAt - candidate.markedAt,
                            departureReason = candidate.reason,
                            attribution =
                                "left_while_danger_continued",
                        },
                    })
                    if eventResult.ok
                        or eventResult.reason == "duplicate_event"
                    then
                        encounter.abandonmentConfirmed[candidateKey] =
                            true
                    end
                end
                encounter.abandonmentCandidates[candidateKey] = nil
            end
        end
        if occurredAt - encounter.lastThreatAt >= END_GRACE_HOURS then
            toEnd[#toEnd + 1] = encounterID
        end
    end
    table.sort(toEnd)
    for _, encounterID in ipairs(toEnd) do
        Tracker.EndEncounter(encounterID, occurredAt)
    end
    return #toEnd
end

Tracker.MIN_DURATION_HOURS = MIN_DURATION_HOURS
Tracker.END_GRACE_HOURS = END_GRACE_HOURS
Tracker.ABANDON_GRACE_HOURS = ABANDON_GRACE_HOURS
Tracker.ABANDON_DISTANCE = ABANDON_DISTANCE
Tracker.PUMP_INTERVAL_HOURS = PUMP_INTERVAL_HOURS

return Tracker
