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
function Internal.convertPlayerFactionToRefugees(
    faction,
    formerOwnerKey,
    at
)
    local previousArchetypeID = faction.archetypeID
    local livingMembers = {}
    for npcID, _ in pairs(faction.memberIDs or {}) do
        local record = PNC.Registry.Get(npcID)
        if record and record.alive ~= false then
            livingMembers[#livingMembers + 1] = npcID
        end
    end
    table.sort(livingMembers)

    Factions.Registry.byArchetype[previousArchetypeID] =
        Factions.Registry.byArchetype[previousArchetypeID]
        or {}
    Factions.Registry.byArchetype[previousArchetypeID][
        faction.id
    ] = nil
    Factions.Registry.byArchetype.refugee =
        Factions.Registry.byArchetype.refugee or {}
    Factions.Registry.byArchetype.refugee[faction.id] = true

    faction.name = Internal.refugeeFactionName(faction)
    faction.archetypeID = "refugee"
    faction.policy = Types.NormalizePolicy(
        {},
        "refugee",
        faction.id
    )
    for playerKey, _ in pairs(
        faction.playerMemberKeys or {}
    ) do
        if Factions.Registry.byPlayerKey[playerKey]
            == faction.id
        then
            Factions.Registry.byPlayerKey[playerKey] = nil
        end
    end
    faction.ownerPlayerKey = nil
    faction.playerMemberKeys = {}
    faction.leaderNPCID = livingMembers[1]
    faction.tags = faction.tags or {}
    faction.tags.formerPlayerFaction = true
    faction.tags.disbandReason = "player_leadership_ended"
    if EntityRef.IsPlayer(formerOwnerKey) then
        faction.tags.formerOwnerKey = formerOwnerKey
    end
    Internal.endFactionTreaties(faction, at)

    for _, npcID in ipairs(livingMembers) do
        local record = PNC.Registry.Get(npcID)
        local affiliation = Internal.affiliationFor(record, faction)
        if npcID == faction.leaderNPCID then
            affiliation.role = "leader"
            affiliation.rank = "leader"
        else
            if not Archetypes.IsRoleAllowed(
                "refugee",
                affiliation.role
            ) then
                affiliation.role =
                    Archetypes.GetDefaultRole("refugee")
            end
            if affiliation.rank == "leader" then
                affiliation.rank = "member"
            end
        end
        Internal.commitAffiliation(
            record,
            Types.NormalizeAffiliation(affiliation, faction)
        )
    end

    Internal.touchFaction(faction)
    Internal.touchRegistry()
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ReconcileFaction
    then
        PNC.FactionBehavior.ReconcileFaction(
            faction.id,
            "player_faction_became_refugees"
        )
    end
    return true, "converted_to_refugees", Internal.copy(faction)
end

function Factions.HandlePlayerCharacterDeath(
    playerKey,
    worldAgeHours
)
    local factionID
    local faction
    local wasOwner
    local successors
    local at
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    if not EntityRef.IsPlayer(playerKey) then
        return false, "invalid_player_key"
    end
    factionID = Factions.Registry.byPlayerKey[playerKey]
    faction = factionID and Internal.registryRecord(factionID) or nil
    if not faction
        or faction.playerMemberKeys[playerKey] ~= true
    then
        return false, "player_not_affiliated"
    end
    at = Internal.finiteTimestamp(worldAgeHours, faction.createdAt)
    if Internal.isProvisionalFaction(faction) then
        return Internal.retireProvisionalFaction(
            faction,
            playerKey,
            at
        )
    end
    wasOwner = faction.ownerPlayerKey == playerKey
    faction.playerMemberKeys[playerKey] = nil
    Factions.Registry.byPlayerKey[playerKey] = nil

    if not wasOwner then
        Internal.touchFaction(faction)
        Internal.touchRegistry()
        return true, "dead_member_removed", Internal.copy(faction)
    end

    faction.ownerPlayerKey = nil
    successors = Internal.activePlayerMemberKeys(faction)
    if #successors > 0 then
        faction.ownerPlayerKey = successors[1]
        Internal.touchFaction(faction)
        Internal.touchRegistry()
        if PNC.FactionBehavior
            and PNC.FactionBehavior.ReconcileFaction
        then
            PNC.FactionBehavior.ReconcileFaction(
                faction.id,
                "player_leadership_succeeded"
            )
        end
        return true, "leadership_succeeded", Internal.copy(faction)
    end
    return Internal.convertPlayerFactionToRefugees(
        faction,
        playerKey,
        at
    )
end

function Factions.ReconcilePlayerMemberships(worldAgeHours)
    if not Internal.authority() then return 0, "not_authority" end
    if not Factions.Loaded then Factions.EnsureLoaded() end
    local removals = {}
    for factionID, faction in pairs(
        Factions.Registry.byID or {}
    ) do
        for playerKey, enabled in pairs(
            faction.playerMemberKeys or {}
        ) do
            local character = enabled == true
                and Internal.playerCharacterRecord(playerKey) or nil
            if character and (
                character.status == "dead"
                or character.status == "retired"
            ) then
                removals[#removals + 1] = {
                    factionID = factionID,
                    playerKey = playerKey,
                }
            end
        end
    end
    table.sort(removals, function(left, right)
        if left.factionID ~= right.factionID then
            return left.factionID < right.factionID
        end
        return left.playerKey < right.playerKey
    end)
    local changed = 0
    for _, item in ipairs(removals) do
        local ok = Factions.HandlePlayerCharacterDeath(
            item.playerKey,
            worldAgeHours
        )
        if ok then changed = changed + 1 end
    end
    for _, faction in pairs(
        Factions.Registry.byID or {}
    ) do
        if faction.status == "active"
            and faction.ownerPlayerKey == nil
        then
            local successors = Internal.activePlayerMemberKeys(faction)
            if #successors > 0 then
                faction.ownerPlayerKey = successors[1]
                Internal.touchFaction(faction)
                Internal.touchRegistry()
                changed = changed + 1
                if PNC.FactionBehavior
                    and PNC.FactionBehavior.ReconcileFaction
                then
                    PNC.FactionBehavior.ReconcileFaction(
                        faction.id,
                        "player_leadership_repaired"
                    )
                end
            end
        end
    end
    return changed, changed > 0 and "reconciled" or "unchanged"
end

return Factions
