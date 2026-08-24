if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Factions = PNC.Factions
local Internal = Factions.Internal
local Core = PNC.Core
local Constants = PNC.FactionConstants
local Types = PNC.FactionTypes
local Archetypes = PNC.FactionArchetypes
local EntityRef = PNC.EntityRef
function Internal.factionForPlayer(player, create, at)
    local faction
    if create then
        local ok
        local reason
        ok, reason, faction =
            Factions.EnsurePlayerDiplomacyFaction(
                player,
                { worldAgeHours = at }
            )
        if PNC.FactionTelemetry then
            PNC.FactionTelemetry.RecordAttribution({
                operation = "player_faction_resolution",
                worldAgeHours = at,
                actorKey = faction and faction.ownerPlayerKey,
                sourceFactionID = faction and faction.id,
                result = ok and "resolved" or "rejected",
                reason = reason or (
                    ok and "resolved"
                        or "actor_faction_missing"
                ),
            })
        end
        return ok and faction or nil
    end
    faction = Factions.GetPlayerDiplomacyFaction(player)
    if PNC.FactionTelemetry then
        PNC.FactionTelemetry.RecordAttribution({
            operation = "player_faction_resolution",
            worldAgeHours = at,
            actorKey = faction and faction.ownerPlayerKey,
            sourceFactionID = faction and faction.id,
            result = faction and "resolved" or "rejected",
            reason = faction and "existing"
                or "actor_faction_missing",
        })
    end
    return faction
end

function Internal.traceFactionCallback(category, fields)
    local telemetry = PNC.FactionTelemetry
    if not telemetry then return end
    if category == "callback" then
        telemetry.RecordCallback(fields)
    else
        telemetry.RecordAttribution(fields)
    end
end

function Factions.OnPlayerAggression(
    player,
    targetRecord,
    worldAgeHours,
    context
)
    local targetFactionID =
        Factions.GetOrganizationalFactionID(targetRecord)
    local playerFaction
    Internal.traceFactionCallback("callback", {
        operation = context and context.callback
            or "player_aggression",
        worldAgeHours = worldAgeHours,
        subjectKey = targetRecord and targetRecord.id
            and EntityRef.ForNPC(targetRecord.id) or nil,
        targetFactionID = targetFactionID,
        result = "received",
        damage = context and context.damage,
        severe = context and context.severe,
        killed = context and context.killed,
    })
    if not targetFactionID then
        Internal.traceFactionCallback("attribution", {
            operation = "resolve_player_attack",
            worldAgeHours = worldAgeHours,
            result = "rejected",
            reason = "victim_faction_missing",
        })
        return false, "target_unaffiliated"
    end
    playerFaction = Internal.factionForPlayer(
        player,
        true,
        worldAgeHours
    )
    if not playerFaction then
        Internal.traceFactionCallback("attribution", {
            operation = "resolve_player_attack",
            worldAgeHours = worldAgeHours,
            targetFactionID = targetFactionID,
            result = "rejected",
            reason = "actor_identity_missing",
        })
        return false, "player_faction_unavailable"
    end
    if playerFaction.id == targetFactionID then
        Internal.traceFactionCallback("attribution", {
            operation = "resolve_player_attack",
            worldAgeHours = worldAgeHours,
            actorKey = playerFaction.ownerPlayerKey,
            sourceFactionID = playerFaction.id,
            targetFactionID = targetFactionID,
            result = "rejected",
            reason = "same_faction",
        })
        return false, "same_faction"
    end
    if not PNC.FactionIncidentService then
        return false, "incident_service_unavailable"
    end
    context = type(context) == "table" and context or {}
    Internal.traceFactionCallback("attribution", {
        operation = "resolve_player_attack",
        worldAgeHours = worldAgeHours,
        actorKey = playerFaction.ownerPlayerKey,
        subjectKey = EntityRef.ForNPC(targetRecord.id),
        sourceFactionID = playerFaction.id,
        targetFactionID = targetFactionID,
        result = "accepted",
        reason = "accepted_cross_faction_attack",
    })
    return PNC.FactionIncidentService.RecordAttack(
        playerFaction.id,
        targetFactionID,
        {
            worldAgeHours = worldAgeHours,
            actorKey = playerFaction.ownerPlayerKey,
            subjectKey = EntityRef.ForNPC(targetRecord.id),
            callbackID = context.callbackID,
            severe = context.severe,
            killed = context.killed,
            damage = context.damage,
            intentionality = context.intentionality,
            targetRecord = targetRecord,
        }
    )
end

return Factions
