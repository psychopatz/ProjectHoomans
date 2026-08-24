if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEncounterTracker = PNC.SocialEncounterTracker or {}
PNC.SocialEncounterTracker.Internal =
    PNC.SocialEncounterTracker.Internal or {}

local Tracker = PNC.SocialEncounterTracker
local Internal = Tracker.Internal
local EntityRef = PNC.EntityRef
local END_GRACE_HOURS = Tracker.END_GRACE_HOURS
local PUMP_INTERVAL_HOURS = Tracker.PUMP_INTERVAL_HOURS
local ABANDON_DISTANCE = Tracker.ABANDON_DISTANCE
local finite = Internal.finite
local npcRecordForKey = Internal.npcRecordForKey
local participantCapable = Internal.participantCapable
local targetInSeriousDanger = Internal.targetInSeriousDanger
local emit = Internal.emit

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
