if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionBehavior = PNC.FactionBehavior or {}
PNC.FactionBehavior.Internal = PNC.FactionBehavior.Internal or {}

local Behavior = PNC.FactionBehavior
local Internal = Behavior.Internal
local Factions = PNC.Factions
local Balance = PNC.FactionBalance
local currentWorldAgeHours = Internal.currentWorldAgeHours

function Behavior.ReconcileFaction(factionID, reason)
    local faction = Factions.Registry.byID[factionID]
    local changed = 0
    if not faction then return 0 end
    for npcID, _ in pairs(faction.memberIDs or {}) do
        local record = PNC.Registry.Get(npcID)
        if record and Behavior.ApplyNPC(record, reason) then
            changed = changed + 1
        end
    end
    return changed
end

function Behavior.ReconcileAll(reason)
    local changed = 0
    for factionID, _ in pairs(Factions.Registry.byID or {}) do
        changed = changed
            + Behavior.ReconcileFaction(factionID, reason)
    end
    return changed
end

local function reconciliationKey(firstFactionID, secondFactionID)
    if tostring(firstFactionID) > tostring(secondFactionID) then
        firstFactionID, secondFactionID =
            secondFactionID, firstFactionID
    end
    return tostring(firstFactionID) .. "|"
        .. tostring(secondFactionID)
end

local function collectMembers(firstFactionID, secondFactionID)
    local found = {}
    local output = {}
    for _, factionID in ipairs({
        firstFactionID,
        secondFactionID,
    }) do
        local faction = Factions.Registry.byID[factionID]
        for npcID, _ in pairs(
            faction and faction.memberIDs or {}
        ) do
            if not found[npcID] then
                found[npcID] = true
                output[#output + 1] = npcID
            end
        end
    end
    table.sort(output)
    return output
end

function Behavior.QueueTreatyReconciliation(
    firstFactionID,
    secondFactionID,
    operation,
    worldAgeHours
)
    local key = reconciliationKey(
        firstFactionID, secondFactionID
    )
    if Behavior.ReconciliationKeys[key] then
        for _, job in ipairs(Behavior.ReconciliationQueue) do
            if job.key == key then
                job.operation = tostring(
                    operation or job.operation
                )
                job.createdAt = math.max(
                    0,
                    tonumber(worldAgeHours)
                        or currentWorldAgeHours()
                )
                break
            end
        end
        if PNC.FactionTelemetry then
            PNC.FactionTelemetry.RecordTreatyReconciliation({
                operation = tostring(
                    operation or "treaty_changed"
                ),
                worldAgeHours = tonumber(worldAgeHours)
                    or currentWorldAgeHours(),
                sourceFactionID = firstFactionID,
                targetFactionID = secondFactionID,
                encounterKey = key,
                result = "deduplicated",
                reason = "already_queued",
            })
        end
        return false, "already_queued"
    end
    local maximum = math.floor(
        Balance and Balance.Get("reconciliationQueueLimit")
            or 64
    )
    if #Behavior.ReconciliationQueue >= maximum then
        return false, "queue_full"
    end
    local members = collectMembers(
        firstFactionID, secondFactionID
    )
    local job = {
        key = key,
        sourceFactionID = firstFactionID,
        targetFactionID = secondFactionID,
        operation = tostring(operation or "treaty_changed"),
        createdAt = math.max(
            0, tonumber(worldAgeHours)
                or currentWorldAgeHours()
        ),
        cursor = 1,
        memberIDs = members,
        memberCount = #members,
        processedCount = 0,
        staleTargetsCleared = 0,
        intentsChanged = 0,
    }
    Behavior.ReconciliationKeys[key] = true
    Behavior.ReconciliationQueue[
        #Behavior.ReconciliationQueue + 1
    ] = job
    if PNC.FactionTelemetry then
        PNC.FactionTelemetry.RecordTreatyReconciliation({
            operation = job.operation,
            worldAgeHours = job.createdAt,
            sourceFactionID = firstFactionID,
            targetFactionID = secondFactionID,
            encounterKey = key,
            result = "queued",
            memberCount = job.memberCount,
        })
    end
    return true, "queued", job
end
