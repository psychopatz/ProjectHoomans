PNC = PNC or {}
PNC.Treatment = PNC.Treatment or {}
PNC.Treatment.Internal = PNC.Treatment.Internal or {}

local Treatment = PNC.Treatment
local Internal = Treatment.Internal
local Core = PNC.Core
local Registry = PNC.Registry

local function audit(record, route, status, reason, actorId, partId,
    itemType, firstAidLevel)
    if Internal.LogDebug then
        Internal.LogDebug(
            record,
            "apply_bandage",
            route,
            status,
            reason,
            actorId,
            record and record.id,
            partId,
            itemType,
            nil,
            firstAidLevel
        )
    end
end

function Treatment.ApplyBandage(record, partId, options)
    local applied
    local reason
    options = type(options) == "table" and options or {}
    local route = options.diagnosticRoute or "direct"
    local actorId = options.diagnosticActorId
    local itemType = options.bandageType
    local firstAidLevel = options.firstAidLevel
    if not Internal.IsAuthority() then
        audit(record, route, "rejected", "not_authority", actorId,
            partId, itemType, firstAidLevel)
        return false, "not_authority"
    end
    if not record or record.alive == false then
        audit(record, route, "rejected", "npc_missing", actorId,
            partId, itemType, firstAidLevel)
        return false, "npc_missing"
    end
    if not PNC.NPCWounds or not PNC.NPCWounds.Bandage then
        audit(record, route, "rejected", "wounds_unavailable", actorId,
            partId, itemType, firstAidLevel)
        return false, "wounds_unavailable"
    end
    applied, reason = PNC.NPCWounds.Bandage(record, partId, Core.Now(), {
        bandageType = itemType,
        bandageName = options.bandageName,
        firstAidLevel = firstAidLevel,
    })
    if not applied then
        audit(record, route, "rejected", reason, actorId, partId,
            itemType, firstAidLevel)
        return false, reason
    end
    record.runtime = record.runtime or {}
    record.runtime.forceSyncEvent = options.syncEvent or "bandaged"
    record.runtime.bandageCompletionRevision =
        (tonumber(record.runtime.bandageCompletionRevision) or 0) + 1
    record.runtime.bandageCompletionAt = Core.Now()
    record.runtime.bandageCompletionPartId = tostring(partId)
    if Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "wounds")
    end
    if PNC.MedicalCareService
        and PNC.MedicalCareService.ResolveForPatient
    then
        PNC.MedicalCareService.ResolveForPatient(
            "npc", record.id, "patient_wound_resolved")
    end
    if options.broadcast ~= false
        and PNC.Network and PNC.Network.BroadcastRecord
    then
        PNC.Network.BroadcastRecord(record, options.syncEvent or "bandaged")
    end
    audit(record, route, "applied", "bandaged", actorId,
        partId, itemType, firstAidLevel)
    return true, "bandaged"
end

return Treatment
