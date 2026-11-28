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

local function dispatchPairEvent(payload, beatState)
    local resultValue = emit(payload)
    local count = 0
    if resultValue and resultValue.ok then
        count = resultValue.memoriesCreated or 0
        if beatState and not beatState.notified then
            local beats = PNC.Semantics and PNC.Semantics.DialogueBeats
            if beats and type(beats.OnCombatEncounterCleared) == "function" then
                beatState.notified = true
                pcall(beats.OnCombatEncounterCleared, {
                    encounterID = beatState.encounterID,
                    actorKey = payload.actorKey,
                    targetKey = payload.targetKey,
                    hordeAttack = beatState.hordeAttack,
                    threatCount = beatState.threatCount,
                    earnedDelta = tonumber(resultValue.memoriesCreated) or 1,
                })
            end
        end
    end
    return count
end

function Tracker.DrainPendingPairs(maxCount)
    local queue = Tracker.PendingPairEmits
    local head = tonumber(Tracker.PendingPairHead) or 1
    local tail = tonumber(Tracker.PendingPairTail) or (type(queue) == "table" and #queue or 0)
    if type(queue) ~= "table" or head > tail then
        return 0
    end
    local limit = math.max(1, math.floor(tonumber(maxCount)
        or tonumber(Tracker.MAX_PENDING_EMITS_PER_PUMP) or 1))
    local processed = 0
    local emitted = 0
    while head <= tail and processed < limit do
        local item = queue[head]
        queue[head] = nil
        head = head + 1
        if item and item.payload then
            processed = processed + 1
            emitted = emitted + dispatchPairEvent(item.payload, item.beatState)
        end
    end
    if head > tail then
        Tracker.PendingPairEmits = {}
        Tracker.PendingPairHead = 1
        Tracker.PendingPairTail = 0
    else
        Tracker.PendingPairHead = head
    end
    return emitted
end

function Tracker.EndEncounter(encounterID, occurredAt, options)
    local encounter = Tracker.Encounters[encounterID]
    local keys = {}
    local left
    local right
    local i
    local j
    local emitted = 0
    local eventType
    local actorKey
    local targetKey
    local hordeAttack
    local deferPairs = type(options) == "table" and options.deferPairs == true
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
        hordeAttack = encounter.hordeAttack == true
        local threatCount = countEntries(encounter.threatIDs)
        local durationHours = occurredAt - encounter.startedAt
        local maxPairs = math.max(1, tonumber(Tracker.MAX_SHARED_PAIRS_PER_ENCOUNTER) or 24)
        local pairsProcessed = 0
        local beatState = {
            notified = false,
            encounterID = encounter.id,
            hordeAttack = hordeAttack,
            threatCount = threatCount,
        }
        for left, _ in pairs(encounter.participants) do
            if participantAlive(encounter, left)
                and encounter.participants[left].eligibleForShared ~= false
            then
                keys[#keys + 1] = left
            end
        end
        -- Prioritize non-NPC (player) keys first so bounded pair budgets always
        -- preserve every player-companion memory before NPC-NPC pairs.
        table.sort(keys, function(a, b)
            local aNpc = EntityRef.IsNPC(a)
            local bNpc = EntityRef.IsNPC(b)
            if aNpc ~= bNpc then return not aNpc end
            return tostring(a) < tostring(b)
        end)
        for i = 1, #keys do
            if pairsProcessed >= maxPairs then break end
            for j = i + 1, #keys do
                if pairsProcessed >= maxPairs then break end
                left = keys[i]
                right = keys[j]
                if EntityRef.IsNPC(left) or EntityRef.IsNPC(right) then
                    pairsProcessed = pairsProcessed + 1
                    actorKey = left
                    targetKey = right
                    if hordeAttack and EntityRef.IsNPC(right)
                        and not EntityRef.IsNPC(left)
                    then
                        actorKey = right
                        targetKey = left
                    end
                    eventType = hordeAttack
                        and "survived_horde_attack"
                        or "survived_combat_together"
                    local payload = {
                        id = "social:shared_"
                            .. (hordeAttack and "horde_attack" or "combat")
                            .. ":" .. encounter.id
                            .. ":" .. left .. ":" .. right,
                        type = eventType,
                        actorKey = actorKey,
                        targetKey = targetKey,
                        occurredAt = occurredAt,
                        sourceSystem = "combat",
                        x = encounter.x,
                        y = encounter.y,
                        z = encounter.z,
                        context = {
                            encounterID = encounter.id,
                            threatCount = threatCount,
                            durationHours = durationHours,
                            hordeAttack = hordeAttack,
                        },
                    }
                    if deferPairs then
                        Tracker.PendingPairEmits = Tracker.PendingPairEmits or {}
                        local tail = (tonumber(Tracker.PendingPairTail) or 0) + 1
                        Tracker.PendingPairTail = tail
                        if not Tracker.PendingPairHead or Tracker.PendingPairHead < 1 then
                            Tracker.PendingPairHead = 1
                        end
                        Tracker.PendingPairEmits[tail] = {
                            payload = payload,
                            beatState = beatState,
                        }
                    else
                        emitted = emitted + dispatchPairEvent(payload, beatState)
                    end
                end
            end
        end
        if deferPairs and Tracker.DrainPendingPairs then
            emitted = emitted + Tracker.DrainPendingPairs(
                Tracker.MAX_PENDING_EMITS_PER_PUMP or 1
            )
        end
    end
    releaseEncounter(encounter)
    return true, emitted > 0
        and "encounter_socialized" or "encounter_not_qualifying",
        emitted
end
