-- Server-authoritative player-faction membership presentation and mutations.
-- The service exposes only the requesting character's faction and never
-- accepts client claims about the actor's identity or authority.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then
    return
end

PNC = PNC or {}
PNC.FactionMembership = PNC.FactionMembership or {}

local Membership = PNC.FactionMembership
local Factions = PNC.Factions
local EntityRef = PNC.EntityRef
local Core = PNC.Core

local function copy(value)
    return Core and Core.DeepCopy and Core.DeepCopy(value) or value
end

local function worldAgeHours()
    if getGameTime and getGameTime()
        and getGameTime().getWorldAgeHours
    then
        return math.max(
            0,
            tonumber(getGameTime():getWorldAgeHours()) or 0
        )
    end
    return 0
end

local function actorKey(player)
    if not PNC.PlayerCharacters
        or not PNC.PlayerCharacters.GetEntityKey
    then
        return nil, "player_identity_unavailable"
    end
    return PNC.PlayerCharacters.GetEntityKey(player, {
        callback = "faction_member_management",
        worldAgeHours = worldAgeHours(),
    })
end

local function characterForKey(playerKey)
    local parsed = EntityRef.Parse(playerKey)
    if not parsed or parsed.kind ~= "player" then return nil end
    return PNC.PlayerCharacters
        and PNC.PlayerCharacters.Registry
        and PNC.PlayerCharacters.Registry.byUUID
        and PNC.PlayerCharacters.Registry.byUUID[
            parsed.characterUUID
        ] or nil
end

local function playerSummary(playerKey, ownerKey)
    local parsed = EntityRef.Parse(playerKey)
    local character = characterForKey(playerKey)
    if not parsed then return nil end
    local runtime = PNC.PlayerCharacters
        and PNC.PlayerCharacters.RuntimeByUUID
        and PNC.PlayerCharacters.RuntimeByUUID[
            parsed.characterUUID
        ] or nil
    return {
        key = playerKey,
        accountIdentity = parsed.accountIdentity,
        characterUUID = parsed.characterUUID,
        displayName = character
            and character.displayName
            or parsed.accountIdentity,
        status = character and character.status or "unknown",
        online = runtime ~= nil,
        leader = playerKey == ownerKey,
        lastSeenAt = character
            and character.lastSeenAt or 0,
    }
end

local function npcSummary(member)
    local affiliation = member and member.affiliation or {}
    local record = member and PNC.Registry
        and PNC.Registry.Get(member.npcID) or nil
    return {
        id = member.npcID,
        name = member.name,
        alive = member.alive ~= false,
        presenceState = record
            and record.presenceState or "unknown",
        role = affiliation.role or "civilian",
        rank = affiliation.rank or "member",
        membershipStatus =
            affiliation.membershipStatus or "member",
    }
end

function Membership.BuildSnapshot(player, actionResult)
    local key, reason = actorKey(player)
    if not key then return nil, reason end
    local faction
    faction, reason = Factions.GetFactionForPlayerKey(key)
    if not faction then
        return {
            currentPlayerKey = key,
            faction = nil,
            playerMembers = {},
            npcMembers = {},
            availablePlayers = {},
            canManage = false,
            actionResult = copy(actionResult),
            generatedAt = worldAgeHours(),
        }, reason
    end

    local playerMembers = {}
    for playerKey, enabled in pairs(
        faction.playerMemberKeys or {}
    ) do
        local summary = enabled == true
            and playerSummary(
                playerKey,
                faction.ownerPlayerKey
            ) or nil
        if summary then
            playerMembers[#playerMembers + 1] = summary
        end
    end
    table.sort(playerMembers, function(left, right)
        if left.leader ~= right.leader then
            return left.leader == true
        end
        if left.displayName ~= right.displayName then
            return left.displayName < right.displayName
        end
        return left.key < right.key
    end)

    local availablePlayers = {}
    for uuid, runtime in pairs(
        PNC.PlayerCharacters
            and PNC.PlayerCharacters.RuntimeByUUID or {}
    ) do
        if runtime then
            local character = PNC.PlayerCharacters.Registry
                and PNC.PlayerCharacters.Registry.byUUID
                and PNC.PlayerCharacters.Registry.byUUID[uuid]
                or nil
            local availableKey = character
                and character.status == "active"
                and EntityRef.ForPlayerIdentity(
                    character.accountKey or character.accountIdentity,
                    uuid
                ) or nil
            if availableKey
                and availableKey ~= key
                and not Factions.GetFactionForPlayerKey(
                    availableKey
                )
            then
                availablePlayers[
                    #availablePlayers + 1
                ] = playerSummary(availableKey, nil)
            end
        end
    end
    table.sort(availablePlayers, function(left, right)
        if left.displayName ~= right.displayName then
            return left.displayName < right.displayName
        end
        return left.key < right.key
    end)

    local npcMembers = {}
    for _, member in ipairs(
        Factions.GetMembers(faction.id) or {}
    ) do
        npcMembers[#npcMembers + 1] = npcSummary(member)
    end
    table.sort(npcMembers, function(left, right)
        if left.name ~= right.name then
            return left.name < right.name
        end
        return left.id < right.id
    end)

    return {
        currentPlayerKey = key,
        faction = {
            id = faction.id,
            name = faction.name,
            archetypeID = faction.archetypeID,
            ownerPlayerKey = faction.ownerPlayerKey,
            emblem = copy(faction.emblem),
            revision = faction.revision,
        },
        playerMembers = playerMembers,
        npcMembers = npcMembers,
        availablePlayers = availablePlayers,
        canManage = faction.ownerPlayerKey == key,
        actionResult = copy(actionResult),
        generatedAt = worldAgeHours(),
    }, "resolved"
end

function Membership.PerformAction(player, args)
    args = type(args) == "table" and args or {}
    local action = tostring(args.memberAction or "")
    local targetKey = args.playerKey
    local ok
    local reason
    if action == "add_player" then
        local parsed = EntityRef.Parse(targetKey)
        local online = parsed
            and parsed.kind == "player"
            and PNC.PlayerCharacters
            and PNC.PlayerCharacters.RuntimeByUUID
            and PNC.PlayerCharacters.RuntimeByUUID[
                parsed.characterUUID
            ] or nil
        if not online then
            ok, reason = false, "target_player_not_online"
        else
            ok, reason = Factions.AddPlayerToCurrentFaction(
                player,
                targetKey
            )
        end
    elseif action == "banish_player" then
        ok, reason = Factions.BanishPlayerFromCurrentFaction(
            player,
            targetKey,
            worldAgeHours()
        )
    elseif action == "transfer_leadership" then
        ok, reason =
            Factions.TransferCurrentFactionLeadership(
                player,
                targetKey
            )
    else
        ok, reason = false, "unknown_action"
    end
    return Membership.BuildSnapshot(player, {
        ok = ok == true,
        action = action,
        reason = reason,
        playerKey = targetKey,
    })
end

return Membership
