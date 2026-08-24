if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionBehavior = PNC.FactionBehavior or {}
PNC.FactionBehavior.Internal = PNC.FactionBehavior.Internal or {}

local Behavior = PNC.FactionBehavior
local Internal = Behavior.Internal
local Balance = PNC.FactionBalance
local Core = PNC.Core
local currentWorldAgeHours = Internal.currentWorldAgeHours
local clearCombatRuntime = Internal.clearCombatRuntime

local function runtimeTargetValue(target)
    if not target then return nil end
    if target.kind == "npc" then
        return target.id and PNC.Registry.Get(target.id) or nil
    end
    if target.kind == "player" then
        return target.player
    end
    return nil
end

function Behavior.PumpReconciliation(maximum)
    maximum = math.max(
        1,
        math.floor(tonumber(maximum)
            or (
                Balance
                and Balance.Get("reconciliationBatchSize")
                or 16
            ))
    )
    local processed = 0
    while processed < maximum
        and #Behavior.ReconciliationQueue > 0
    do
        local job = Behavior.ReconciliationQueue[1]
        local npcID = job.memberIDs[job.cursor]
        if not npcID then
            Behavior.ReconciliationKeys[job.key] = nil
            table.remove(Behavior.ReconciliationQueue, 1)
            if PNC.FactionTelemetry then
                PNC.FactionTelemetry.RecordTreatyReconciliation({
                    operation = job.operation,
                    worldAgeHours = currentWorldAgeHours(),
                    sourceFactionID = job.sourceFactionID,
                    targetFactionID = job.targetFactionID,
                    encounterKey = job.key,
                    result = "completed",
                    memberCount = job.memberCount,
                    processedCount = job.processedCount,
                    staleTargetsCleared =
                        job.staleTargetsCleared,
                    intentsChanged = job.intentsChanged,
                })
            end
        else
            job.cursor = job.cursor + 1
            job.processedCount = job.processedCount + 1
            processed = processed + 1
            local record = PNC.Registry.Get(npcID)
            if record then
                local memberIntentChanged = false
                local beforeTarget = record.runtime
                    and record.runtime.target or nil
                local beforeReason = record.runtime
                    and record.runtime.factionBehaviorReason
                Behavior.ApplyNPC(record, job.operation)
                local target = record.runtime
                    and record.runtime.target or beforeTarget
                if target and target.kind ~= "zombie" then
                    local value = runtimeTargetValue(target)
                    local selfDefense = target.targetAggression == true
                        or target.immediateSelfDefense == true
                        or (
                            tonumber(record.runtime
                                .factionSelfDefenseUntil) or 0
                        ) > Core.Now()
                    local intent = value and Behavior.ResolveIntent(
                        record,
                        value,
                        {
                            worldAgeHours =
                                currentWorldAgeHours(),
                            immediateSelfDefense = selfDefense,
                            targetAggression = selfDefense,
                        }
                    ) or nil
                    if intent and intent.attackAllowed ~= true then
                        clearCombatRuntime(record)
                        job.staleTargetsCleared =
                            job.staleTargetsCleared + 1
                        memberIntentChanged = true
                    elseif intent and selfDefense
                        and record.runtime.target == nil
                    then
                        record.runtime.target = target
                    end
                end
                local afterReason = record.runtime
                    and record.runtime.factionBehaviorReason
                if beforeReason ~= afterReason then
                    memberIntentChanged = true
                end
                if memberIntentChanged then
                    job.intentsChanged =
                        job.intentsChanged + 1
                end
            end
        end
    end
    return processed
end

function Behavior.GetReconciliationSnapshot()
    local output = {}
    for _, job in ipairs(Behavior.ReconciliationQueue) do
        output[#output + 1] = {
            key = job.key,
            sourceFactionID = job.sourceFactionID,
            targetFactionID = job.targetFactionID,
            operation = job.operation,
            createdAt = job.createdAt,
            memberCount = job.memberCount,
            processedCount = job.processedCount,
            staleTargetsCleared = job.staleTargetsCleared,
            intentsChanged = job.intentsChanged,
        }
    end
    return output
end
