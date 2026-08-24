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
function Internal.defaultPlayerFactionName(player, playerKey)
    local parsed = EntityRef.Parse(playerKey)
    local descriptor = player and player.getDescriptor
        and player:getDescriptor() or nil
    local surname = descriptor and descriptor.getSurname
        and descriptor:getSurname() or nil
    surname = type(surname) == "string"
        and string.match(surname, "^%s*(.-)%s*$") or nil
    if not surname or surname == "" then
        local playerName = tostring(
            player and player.getDisplayName
                and player:getDisplayName()
                or parsed and parsed.accountIdentity
                or "Player"
        )
        surname = string.match(playerName, "(%S+)%s*$") or "Player"
    end
    local flavors = {
        "Clan", "Group", "Enclave", "Collective",
        "Coalition", "Fellowship", "Company", "Kin",
    }
    local index = ZombRand and (ZombRand(#flavors) + 1) or 1
    return string.sub(surname .. " " .. flavors[index], 1,
        Constants.NAME_MAX_LENGTH)
end

function Factions.EnsurePlayerDiplomacyFaction(player, options)
    local playerKey
    local reason
    local existing
    local parsed
    local ok
    local faction
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    playerKey, reason = Internal.playerKeyFor(
        player,
        "ensure_player_diplomacy_faction",
        true
    )
    if not playerKey then return false, reason end
    existing = Factions.GetDiplomacyFactionForPlayerKey(
        playerKey
    )
    if existing then
        return true,
            Internal.isProvisionalFaction(existing)
                and "existing_provisional" or "existing",
            existing
    end
    options = type(options) == "table" and options or {}
    parsed = EntityRef.Parse(playerKey)
    ok, reason, faction = Factions.Create({
        name = string.sub(
            tostring(
                parsed and parsed.accountIdentity
                    or "Player"
            ) .. " Diplomacy",
            1,
            Constants.NAME_MAX_LENGTH
        ),
        archetypeID = "settler",
        createdAt = options.worldAgeHours,
        tags = {
            provisionalPlayerFaction = true,
            hiddenFromFactionLists = true,
        },
        ownerPlayerKey = playerKey,
        playerMemberKeys = {
            [playerKey] = true,
        },
    })
    if not ok then return false, reason, faction end
    return true, "provisional_created", faction
end

function Internal.promoteProvisionalFaction(
    faction,
    playerKey,
    player,
    spec
)
    local archetypeID = spec.archetypeID or "settler"
    local name = spec.name
        or Internal.defaultPlayerFactionName(player, playerKey)
    local candidate = Types.NewFaction({
        id = faction.id,
        name = name,
        archetypeID = archetypeID,
        status = "active",
        createdAt = faction.createdAt,
        ownerPlayerKey = playerKey,
        playerMemberKeys = {
            [playerKey] = true,
        },
        policy = spec.policy,
        emblem = spec.emblem,
        tags = spec.tags,
    })
    if not candidate then return false, "invalid_name" end
    if faction.archetypeID ~= candidate.archetypeID then
        Factions.Registry.byArchetype[
            faction.archetypeID
        ] = Factions.Registry.byArchetype[
            faction.archetypeID
        ] or {}
        Factions.Registry.byArchetype[
            faction.archetypeID
        ][faction.id] = nil
        Factions.Registry.byArchetype[
            candidate.archetypeID
        ] = Factions.Registry.byArchetype[
            candidate.archetypeID
        ] or {}
        Factions.Registry.byArchetype[
            candidate.archetypeID
        ][faction.id] = true
    end
    faction.name = candidate.name
    faction.archetypeID = candidate.archetypeID
    faction.status = "active"
    faction.archivedAt = 0
    faction.ownerPlayerKey = playerKey
    faction.playerMemberKeys = {
        [playerKey] = true,
    }
    faction.policy = candidate.policy
    faction.emblem = candidate.emblem
    faction.tags = Types.NormalizeTags(spec.tags)
    faction.tags.promotedFromProvisional = true
    Factions.Registry.byPlayerKey[playerKey] = faction.id
    Internal.touchFaction(faction)
    Internal.touchRegistry()
    return true, "promoted_provisional", Internal.copy(faction)
end

function Factions.CreatePlayerFaction(player, spec)
    local playerKey
    local reason
    local name
    local existing
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    playerKey, reason = Internal.playerKeyFor(
        player,
        "create_player_faction",
        true
    )
    if not playerKey then return false, reason end
    spec = type(spec) == "table" and spec or {}
    existing = Factions.GetDiplomacyFactionForPlayerKey(
        playerKey
    )
    if existing and Internal.isProvisionalFaction(existing) then
        return Internal.promoteProvisionalFaction(
            Internal.registryRecord(existing.id),
            playerKey,
            player,
            spec
        )
    end
    if existing then
        return false, "player_already_affiliated",
            existing
    end
    name = spec.name
        or Internal.defaultPlayerFactionName(player, playerKey)
    return Factions.Create({
        name = name,
        archetypeID = spec.archetypeID or "settler",
        createdAt = spec.createdAt,
        tags = spec.tags,
        emblem = spec.emblem,
        ownerPlayerKey = playerKey,
        playerMemberKeys = {
            [playerKey] = true,
        },
    })
end

return Factions
