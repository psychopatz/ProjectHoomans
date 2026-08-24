if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.RelationshipDebug = PNC.RelationshipDebug or {}
PNC.RelationshipDebug.Internal = PNC.RelationshipDebug.Internal or {}

local Debug = PNC.RelationshipDebug
local Internal = Debug.Internal
local Relationships = PNC.Relationships
local EntityRef = PNC.EntityRef
local Registry = PNC.Registry
local worldAgeHours = Internal.worldAgeHours
local resolveTarget = Internal.resolveTarget

function Debug.BuildSnapshotForRequest(player, args, actionResult)
    local at = worldAgeHours()
    local observerNPCID = args and args.observerNPCID
    local observer = Registry and Registry.Get
        and Registry.Get(tostring(observerNPCID or "")) or nil
    local targetKey
    local target
    local reason
    if not observer or observer.alive == false then
        return nil, "observer_not_found"
    end
    targetKey, target, reason = resolveTarget(player, args, at)
    if not targetKey then
        return nil, reason
    end
    if targetKey == EntityRef.ForNPC(observer.id) then
        return nil, "identical_observer_target"
    end
    return Debug.BuildSnapshot(
        observer.id,
        targetKey,
        target,
        at,
        actionResult
    )
end

function Debug.SetDebugBaseline(player, args)
    local at = worldAgeHours()
    local observerNPCID = tostring(args and args.observerNPCID or "")
    local observer = Registry and Registry.Get
        and Registry.Get(observerNPCID) or nil
    local targetKey
    local target
    local reason
    local preset = PNC.RelationshipPresentation
        and PNC.RelationshipPresentation.GetDebugStandingPreset
        and PNC.RelationshipPresentation.GetDebugStandingPreset(
            args and args.standingID
        ) or nil
    if not observer or observer.alive == false then
        return nil, "observer_not_found"
    end
    if not preset then
        preset = {
            approval = args and args.approval,
            respect = args and args.respect,
        }
    end
    if tonumber(preset.approval) == nil
        or tonumber(preset.respect) == nil
    then
        return nil, "invalid_standing"
    end
    targetKey, target, reason = resolveTarget(player, {
        targetKind = args and args.targetKind or "current_player",
        targetNPCID = args and args.targetNPCID,
    }, at)
    if not targetKey then return nil, reason end
    local relationship
    relationship, reason = Relationships.SetDebugBaseline(
        observer.id,
        targetKey,
        preset,
        at
    )
    if not relationship then return nil, reason end
    local summary = PNC.RelationshipPresentation.Summarize(
        relationship,
        true
    )
    summary.npcID = tostring(observer.id)
    return summary
end

function Debug.ApplyDebugBaseline(player, args)
    local summary
    local reason
    summary, reason = Debug.SetDebugBaseline(player, args)
    if not summary then return nil, reason end
    return Debug.BuildSnapshotForRequest(player, {
        observerNPCID = args and args.observerNPCID,
        targetKind = args and args.targetKind or "current_player",
        targetNPCID = args and args.targetNPCID,
    })
end

-- Retained for the temporary conversation debug option. The inspector uses
-- SetDebugBaseline directly and always receives its full debug snapshot.
Debug.SetConversationStanding = Debug.SetDebugBaseline
