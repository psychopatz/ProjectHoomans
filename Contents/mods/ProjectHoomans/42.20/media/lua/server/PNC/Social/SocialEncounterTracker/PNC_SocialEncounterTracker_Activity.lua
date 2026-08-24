if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEncounterTracker = PNC.SocialEncounterTracker or {}
PNC.SocialEncounterTracker.Internal =
    PNC.SocialEncounterTracker.Internal or {}

local Tracker = PNC.SocialEncounterTracker
local Internal = Tracker.Internal
local EntityRef = PNC.EntityRef
local finite = Internal.finite
local validKey = Internal.validKey
local addParticipant = Internal.addParticipant
local findEncounter = Internal.findEncounter
local newEncounter = Internal.newEncounter
local participantAlive = Internal.participantAlive
local emit = Internal.emit

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
