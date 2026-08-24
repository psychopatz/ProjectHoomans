if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEventHooks = PNC.SocialEventHooks or {}
PNC.SocialEventHooksInternal = PNC.SocialEventHooksInternal or {}

local Hooks = PNC.SocialEventHooks
local H = PNC.SocialEventHooksInternal
local EntityRef = PNC.EntityRef
local Core = PNC.Core

function Hooks.OnTreatmentCompleted(
    player,
    targetRecord,
    partID,
    context
)
    local actorKey
    local reason
    local targetKey
    local occurredAt
    local actionID
    local event
    if not H.Enabled() or not PNC.SocialEvents then
        return { ok = false, reason = "feature_disabled" }
    end
    actorKey, reason = Hooks.ResolvePlayerKey(player)
    if not actorKey then
        return { ok = false, reason = reason }
    end
    targetKey = Hooks.ResolveNPCKey(targetRecord)
    if not targetKey then
        return { ok = false, reason = "invalid_target_key" }
    end
    occurredAt = tonumber(context and context.occurredAt)
        or H.WorldAgeHours()
    actionID = context and context.actionID
    if actionID == nil then
        actionID = tostring(
            targetRecord.runtime
                and targetRecord.runtime.bandageCompletionAt
                or (Core and Core.Now and Core.Now())
                or 0
        ) .. ":" .. tostring(
            targetRecord.runtime
                and targetRecord.runtime.bandageCompletionRevision
                or 0
        )
    end
    actionID = tostring(actionID)
    if targetRecord.health
        and targetRecord.health.state == "incapacitated"
    then
        Hooks.RecordRescueContribution(
            targetRecord,
            actorKey,
            occurredAt
        )
    end
    event = {
        id = "social:treated_wound:"
            .. tostring(targetRecord.id) .. ":" .. actionID
            .. ":" .. tostring(partID),
        type = "treated_wound",
        actorKey = actorKey,
        targetKey = targetKey,
        occurredAt = occurredAt,
        sourceSystem = "wounds",
        x = tonumber(targetRecord.x),
        y = tonumber(targetRecord.y),
        z = tonumber(targetRecord.z),
        context = {
            bodyPart = tostring(partID or ""),
            woundType = context and context.woundType or nil,
            severity = tonumber(context and context.severity),
        },
    }
    return PNC.SocialEvents.Emit(event)
end

function Hooks.OnIncapacitationRecovered(
    targetRecord,
    episodeID,
    occurredAt
)
    local contributors = Hooks.RescueContributions[episodeID]
    local selected
    local actorKey
    local entry
    local targetKey
    local output
    if not H.Enabled() or not PNC.SocialEvents then
        Hooks.RescueContributions[episodeID] = nil
        return { ok = false, reason = "feature_disabled" }
    end
    for actorKey, entry in pairs(contributors or {}) do
        if not selected
            or entry.lastAt > selected.lastAt
            or (entry.lastAt == selected.lastAt
                and actorKey < selected.actorKey)
        then
            selected = entry
        end
    end
    Hooks.RescueContributions[episodeID] = nil
    if not selected then
        return { ok = false, reason = "unverified_rescuer" }
    end
    targetKey = Hooks.ResolveNPCKey(targetRecord)
    output = PNC.SocialEvents.Emit({
        id = "social:save:" .. tostring(episodeID)
            .. ":" .. tostring(selected.actorKey),
        type = "saved_from_incapacitation",
        actorKey = selected.actorKey,
        targetKey = targetKey,
        occurredAt = tonumber(occurredAt) or H.WorldAgeHours(),
        sourceSystem = "health",
        x = tonumber(targetRecord.x),
        y = tonumber(targetRecord.y),
        z = tonumber(targetRecord.z),
        context = {
            episodeID = episodeID,
            treatmentActions = selected.actionCount,
            attribution = "completed_treatment_contribution",
        },
    })
    return output
end

return Hooks

