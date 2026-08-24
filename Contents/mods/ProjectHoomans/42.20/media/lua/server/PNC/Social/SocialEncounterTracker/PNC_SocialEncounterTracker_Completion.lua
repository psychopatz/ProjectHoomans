if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEncounterTracker = PNC.SocialEncounterTracker or {}
PNC.SocialEncounterTracker.Internal =
    PNC.SocialEncounterTracker.Internal or {}

local Tracker = PNC.SocialEncounterTracker
local Internal = Tracker.Internal
local EntityRef = PNC.EntityRef
local MIN_DURATION_HOURS = Tracker.MIN_DURATION_HOURS
local finite = Internal.finite
local countEntries = Internal.countEntries
local participantAlive = Internal.participantAlive
local emit = Internal.emit

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
