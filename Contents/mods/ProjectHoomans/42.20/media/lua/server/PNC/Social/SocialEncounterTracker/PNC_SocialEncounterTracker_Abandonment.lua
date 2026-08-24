if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEncounterTracker = PNC.SocialEncounterTracker or {}
PNC.SocialEncounterTracker.Internal =
    PNC.SocialEncounterTracker.Internal or {}

local Tracker = PNC.SocialEncounterTracker
local Internal = Tracker.Internal
local ABANDON_GRACE_HOURS = Tracker.ABANDON_GRACE_HOURS
local addParticipant = Internal.addParticipant
local participantCapable = Internal.participantCapable
local targetInSeriousDanger = Internal.targetInSeriousDanger

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
