if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.RelationshipDebug = PNC.RelationshipDebug or {}
PNC.RelationshipDebug.Internal = PNC.RelationshipDebug.Internal or {}

local Debug = PNC.RelationshipDebug
local Internal = Debug.Internal
local Registry = PNC.Registry
local copy = Internal.copy
local worldAgeHours = Internal.worldAgeHours
local resolveTarget = Internal.resolveTarget

function Debug.SetPlayerPacification(player, args)
    local at = worldAgeHours()
    local observerNPCID = tostring(
        args and args.observerNPCID or ""
    )
    local observer = Registry and Registry.Get
        and Registry.Get(observerNPCID) or nil
    local targetKey
    local target
    local reason
    local ok
    local value
    if not observer or observer.alive == false then
        return nil, "observer_not_found"
    end
    targetKey, target, reason = resolveTarget(player, {
        targetKind = "current_player",
    }, at)
    if not targetKey then return nil, reason end
    local factionID = PNC.Factions
        and PNC.Factions.GetOrganizationalFactionID
        and PNC.Factions.GetOrganizationalFactionID(observer)
        or nil
    if not factionID then
        return nil, "observer_has_no_faction"
    end
    local mode = tostring(args and args.mode or "pacify")
    if mode == "clear" then
        ok, reason, value =
            PNC.Factions.ClearPlayerPacification(
                factionID,
                targetKey
            )
    else
        ok, reason, value = PNC.Factions.PacifyForPlayer(
            factionID,
            targetKey,
            {
                worldAgeHours = at,
                durationHours = tonumber(
                    args and args.durationHours
                ) or 24,
                reason = "debug_bribe_preview",
                sourceNPCID = observer.id,
            }
        )
    end
    local snapshot, snapshotReason = Debug.BuildSnapshot(
        observer.id,
        targetKey,
        target,
        at,
        nil
    )
    if snapshot then
        snapshot.pacificationAction = {
            ok = ok == true,
            reason = reason,
            value = copy(value),
        }
    end
    return snapshot, snapshotReason or reason
end
