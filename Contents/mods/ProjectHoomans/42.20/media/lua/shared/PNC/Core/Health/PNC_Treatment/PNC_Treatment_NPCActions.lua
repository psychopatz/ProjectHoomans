PNC = PNC or {}
PNC.Treatment = PNC.Treatment or {}
PNC.Treatment.Internal = PNC.Treatment.Internal or {}

local Treatment = PNC.Treatment
local Internal = Treatment.Internal
local Skills = PNC.Skills

local function audit(record, eventName, route, status, reason, actorId,
    targetId, partId, itemType, mode, firstAidLevel)
    if Internal.LogDebug then
        Internal.LogDebug(record, eventName, route, status, reason,
            actorId, targetId, partId, itemType, mode, firstAidLevel)
    end
end

function Treatment.TryNPCMedicalTreatment(actorRecord, targetRecord,
    partId, options)
    local policy
    local supply
    local applied
    local reason
    local consumed
    local undo
    local firstAid
    local resultLabel
    options = type(options) == "table" and options or {}
    local route = actorRecord == targetRecord and "npc_self" or "npc_assist"
    local debugRecord = targetRecord or actorRecord
    if not Internal.IsAuthority() then
        audit(debugRecord, "complete", route, "rejected", "not_authority",
            actorRecord and actorRecord.id,
            targetRecord and targetRecord.id, partId)
        return false, "not_authority"
    end
    if not actorRecord or actorRecord.alive == false then
        audit(debugRecord, "complete", route, "rejected", "actor_missing",
            actorRecord and actorRecord.id,
            targetRecord and targetRecord.id, partId)
        return false, "actor_missing"
    end
    if not targetRecord or targetRecord.alive == false then
        audit(debugRecord, "complete", route, "rejected", "target_missing",
            actorRecord.id, targetRecord and targetRecord.id, partId)
        return false, "target_missing"
    end
    policy = Treatment.GetNPCMedicalPolicy(actorRecord, options)
    if policy.requiresItem then
        supply = Internal.FindNPCBandage(actorRecord, options.bandageType)
        if not supply then
            audit(targetRecord, "complete", route, "rejected",
                "missing_bandage", actorRecord.id, targetRecord.id, partId)
            return false, "missing_bandage"
        end
        consumed, undo = Internal.ConsumeNPCBandage(
            actorRecord,
            supply,
            options.consumeReason or "npc_medical_treatment")
        if not consumed then
            audit(targetRecord, "complete", route, "rejected",
                "bandage_consumption_failed", actorRecord.id,
                targetRecord.id, partId, supply.fullType)
            return false, "bandage_consumption_failed"
        end
    end
    firstAid = Treatment.GetNPCFirstAidLevel(actorRecord)
    applied, reason = Treatment.ApplyBandage(targetRecord, partId, {
        bandageType = supply and supply.fullType or policy.bandageType,
        bandageName = supply and supply.displayName or policy.bandageName,
        firstAidLevel = firstAid,
        diagnosticRoute = route,
        diagnosticActorId = actorRecord.id,
        syncEvent = options.syncEvent
            or (actorRecord == targetRecord and "self_bandaged"
                or "npc_treated"),
        broadcast = false,
    })
    if not applied then
        if undo then undo() end
        audit(targetRecord, "complete", route, "rejected", reason,
            actorRecord.id, targetRecord.id, partId,
            supply and supply.fullType or policy.bandageType,
            policy.mode, firstAid)
        return false, reason
    end
    if Skills and Skills.AddXP then
        Skills.AddXP(actorRecord, "FirstAid", 1)
    end
    if PNC.Network and PNC.Network.BroadcastRecord then
        PNC.Network.BroadcastRecord(targetRecord, options.syncEvent
            or (actorRecord == targetRecord and "self_bandaged"
                or "npc_treated"))
    end
    resultLabel = supply and supply.displayName or policy.bandageName
    audit(targetRecord, "complete", route, "applied", "bandaged",
        actorRecord.id, targetRecord.id, partId,
        supply and supply.fullType or policy.bandageType,
        policy.mode, firstAid)
    return true, resultLabel
end

function Treatment.TryNPCBandage(record, partId, options)
    return Treatment.TryNPCMedicalTreatment(record, record, partId, options)
end

return Treatment
