-- Per-faction ownership, membership, and persistence checks.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionValidation = PNC.FactionValidation or {}
local Validation = PNC.FactionValidation
local Internal = Validation.Internal
local Factions = PNC.Factions
local EntityRef = PNC.EntityRef
local addIssue = Internal.AddIssue
local newResult = Internal.NewResult
local safePersistent = Internal.SafePersistent
local checkRelationInto = Internal.CheckRelationInto

function Validation.CheckFaction(factionID)
    local result = newResult("faction:" .. tostring(factionID))
    local faction = Factions.Registry.byID[factionID]
    if not faction then
        addIssue(result, "error", "faction_missing", factionID)
        return result
    end
    if faction.ownerPlayerKey then
        local parsed = EntityRef.Parse(faction.ownerPlayerKey)
        if not parsed or parsed.kind ~= "player"
            or not parsed.characterUUID
        then
            addIssue(result, "error", "invalid_player_owner_key",
                faction.ownerPlayerKey)
        end
        if Factions.Registry.byPlayerKey[
            faction.ownerPlayerKey
        ] ~= factionID
        then
            addIssue(result, "error",
                "player_owner_index_mismatch",
                faction.ownerPlayerKey)
        end
    end
    for playerKey, enabled in pairs(
        faction.playerMemberKeys or {}
    ) do
        if enabled == true then
            local parsed = EntityRef.Parse(playerKey)
            if not parsed or parsed.kind ~= "player"
                or not parsed.characterUUID
            then
                addIssue(result, "error",
                    "invalid_player_member_key", playerKey)
            elseif Factions.Registry.byPlayerKey[playerKey]
                ~= factionID
            then
                addIssue(result, "error",
                    "player_member_index_mismatch", playerKey)
            end
        end
    end
    if faction.status ~= "active"
        and faction.leaderNPCID ~= nil
    then
        addIssue(result, "error", "archived_active_leader",
            faction.leaderNPCID)
    end
    if faction.leaderNPCID then
        local leader = PNC.Registry.Get(faction.leaderNPCID)
        if not leader or leader.alive == false then
            addIssue(result, "error", "dead_or_missing_leader",
                faction.leaderNPCID)
        end
    end
    for npcID, _ in pairs(faction.memberIDs or {}) do
        local record = PNC.Registry.Get(npcID)
        if not record or not record.affiliation
            or record.affiliation.factionID ~= factionID
        then
            addIssue(result, "error", "member_index_mismatch",
                npcID)
        end
    end
    for targetID, relation in pairs(faction.relations or {}) do
        if not Factions.Registry.byID[targetID] then
            addIssue(result, "warning", "relation_target_missing",
                targetID)
        else
            checkRelationInto(
                result, factionID, targetID, relation
            )
        end
    end
    safePersistent(faction, "faction", result, {})
    return result
end

return Validation
