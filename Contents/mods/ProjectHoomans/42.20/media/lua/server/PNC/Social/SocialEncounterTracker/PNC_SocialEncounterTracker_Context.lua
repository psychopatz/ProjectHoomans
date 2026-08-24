if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEncounterTracker = PNC.SocialEncounterTracker or {}
PNC.SocialEncounterTracker.Internal =
    PNC.SocialEncounterTracker.Internal or {}

local Tracker = PNC.SocialEncounterTracker
local Internal = Tracker.Internal
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

Internal.finite = finite
Internal.validKey = validKey
Internal.makeEncounterID = makeEncounterID
Internal.countEntries = countEntries
Internal.addParticipant = addParticipant
Internal.findEncounter = findEncounter
Internal.newEncounter = newEncounter
Internal.targetActiveThreatCount = targetActiveThreatCount
Internal.npcRecordForKey = npcRecordForKey
Internal.participantAlive = participantAlive
Internal.participantCapable = participantCapable
Internal.targetInSeriousDanger = targetInSeriousDanger
Internal.emit = emit
