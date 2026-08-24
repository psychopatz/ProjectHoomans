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
function Internal.playerCharacterRecord(playerKey)
    local parsed = EntityRef.Parse(playerKey)
    if not parsed or parsed.kind ~= "player"
        or not PNC.PlayerCharacters
    then
        return nil
    end
    if PNC.PlayerCharacters.EnsureLoaded then
        PNC.PlayerCharacters.EnsureLoaded()
    end
    return PNC.PlayerCharacters.Registry
        and PNC.PlayerCharacters.Registry.byUUID
        and PNC.PlayerCharacters.Registry.byUUID[
            parsed.characterUUID
        ] or nil
end

function Internal.activePlayerMemberKeys(faction)
    local output = {}
    for playerKey, enabled in pairs(
        faction and faction.playerMemberKeys or {}
    ) do
        local record = enabled == true
            and Internal.playerCharacterRecord(playerKey) or nil
        if record and record.status == "active" then
            output[#output + 1] = playerKey
        end
    end
    table.sort(output)
    return output
end

function Internal.membershipActorAllowed(faction, options)
    options = type(options) == "table" and options or {}
    if options.system == true then return true end
    return EntityRef.IsPlayer(options.actorKey)
        and faction.ownerPlayerKey == options.actorKey
end

function Factions.AddPlayerMember(
    factionID,
    playerKey,
    options
)
    local faction
    local character
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    options = type(options) == "table" and options or {}
    faction = Internal.registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if faction.status ~= "active" then
        return false, "faction_not_active"
    end
    if not Internal.membershipActorAllowed(faction, options) then
        return false, "not_faction_owner"
    end
    if not EntityRef.IsPlayer(playerKey) then
        return false, "invalid_player_key"
    end
    character = Internal.playerCharacterRecord(playerKey)
    if not character then
        return false, "player_character_not_found"
    end
    if character.status ~= "active" then
        return false, "player_character_not_active"
    end
    if faction.playerMemberKeys[playerKey] == true then
        return false, "already_member"
    end
    local existingID = Factions.Registry.byPlayerKey[playerKey]
    if existingID then
        local existing = Internal.registryRecord(existingID)
        if not Internal.isProvisionalFaction(existing) then
            return false, "player_already_affiliated"
        end
        Internal.retireProvisionalFaction(
            existing,
            playerKey,
            options.worldAgeHours,
            "joined_player_faction"
        )
    end
    faction.playerMemberKeys[playerKey] = true
    Factions.Registry.byPlayerKey[playerKey] = faction.id
    Internal.touchFaction(faction)
    Internal.touchRegistry()
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ReconcileFaction
    then
        PNC.FactionBehavior.ReconcileFaction(
            faction.id,
            "player_member_added"
        )
    end
    return true, "player_member_added", Internal.copy(faction)
end

function Factions.RemovePlayerMember(
    factionID,
    playerKey,
    options
)
    local faction
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    options = type(options) == "table" and options or {}
    faction = Internal.registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if not Internal.membershipActorAllowed(faction, options) then
        return false, "not_faction_owner"
    end
    if faction.playerMemberKeys[playerKey] ~= true then
        return false, "not_member"
    end
    if faction.ownerPlayerKey == playerKey
        and options.system ~= true
    then
        return false, "cannot_banish_faction_owner"
    end
    faction.playerMemberKeys[playerKey] = nil
    if Factions.Registry.byPlayerKey[playerKey] == faction.id then
        Factions.Registry.byPlayerKey[playerKey] = nil
    end
    if faction.ownerPlayerKey == playerKey then
        faction.ownerPlayerKey = nil
    end
    Internal.touchFaction(faction)
    Internal.touchRegistry()
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ReconcileFaction
    then
        PNC.FactionBehavior.ReconcileFaction(
            faction.id,
            tostring(options.reason or "player_member_removed")
        )
    end
    return true, "player_member_removed", Internal.copy(faction)
end

function Factions.TransferPlayerLeadership(
    factionID,
    playerKey,
    options
)
    local faction
    local character
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    options = type(options) == "table" and options or {}
    faction = Internal.registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if not Internal.membershipActorAllowed(faction, options) then
        return false, "not_faction_owner"
    end
    if faction.playerMemberKeys[playerKey] ~= true then
        return false, "target_not_member"
    end
    character = Internal.playerCharacterRecord(playerKey)
    if not character or character.status ~= "active" then
        return false, "player_character_not_active"
    end
    if faction.ownerPlayerKey == playerKey then
        return false, "unchanged"
    end
    faction.ownerPlayerKey = playerKey
    Internal.touchFaction(faction)
    Internal.touchRegistry()
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ReconcileFaction
    then
        PNC.FactionBehavior.ReconcileFaction(
            faction.id,
            tostring(options.reason or "leadership_transferred")
        )
    end
    return true, "leadership_transferred", Internal.copy(faction)
end

function Internal.actorFaction(player, callback)
    local actorKey
    local reason
    local faction
    actorKey, reason = Internal.playerKeyFor(
        player,
        callback,
        true
    )
    if not actorKey then return nil, nil, reason end
    faction, reason = Factions.GetFactionForPlayerKey(actorKey)
    if not faction then return nil, actorKey, reason end
    return faction, actorKey
end

function Factions.AddPlayerToCurrentFaction(
    player,
    targetPlayerKey
)
    local faction, actorKey, reason = Internal.actorFaction(
        player,
        "add_player_faction_member"
    )
    if not faction then return false, reason end
    return Factions.AddPlayerMember(
        faction.id,
        targetPlayerKey,
        { actorKey = actorKey }
    )
end

function Factions.BanishPlayerFromCurrentFaction(
    player,
    targetPlayerKey,
    worldAgeHours
)
    local faction, actorKey, reason = Internal.actorFaction(
        player,
        "banish_player_faction_member"
    )
    if not faction then return false, reason end
    return Factions.RemovePlayerMember(
        faction.id,
        targetPlayerKey,
        {
            actorKey = actorKey,
            reason = "banished",
            worldAgeHours = worldAgeHours,
        }
    )
end

function Factions.TransferCurrentFactionLeadership(
    player,
    targetPlayerKey
)
    local faction, actorKey, reason = Internal.actorFaction(
        player,
        "transfer_player_faction_leadership"
    )
    if not faction then return false, reason end
    return Factions.TransferPlayerLeadership(
        faction.id,
        targetPlayerKey,
        {
            actorKey = actorKey,
            reason = "leader_transfer",
        }
    )
end

return Factions
