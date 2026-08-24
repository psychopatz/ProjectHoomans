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
function Internal.rebuildIndexes()
    local byArchetype = {}
    local byPlayerKey = {}
    local membersByFaction = {}
    local changed = false
    for factionID, faction in pairs(Factions.Registry.byID) do
        byArchetype[faction.archetypeID] =
            byArchetype[faction.archetypeID] or {}
        byArchetype[faction.archetypeID][factionID] = true
        membersByFaction[factionID] = {}
        for playerKey, _ in pairs(
            faction.playerMemberKeys or {}
        ) do
            if not byPlayerKey[playerKey] then
                byPlayerKey[playerKey] = factionID
            else
                faction.playerMemberKeys[playerKey] = nil
                if faction.ownerPlayerKey == playerKey then
                    faction.ownerPlayerKey = nil
                end
                changed = true
            end
        end
        if faction.ownerPlayerKey
            and faction.playerMemberKeys[
                faction.ownerPlayerKey
            ] ~= true
        then
            faction.ownerPlayerKey = nil
            changed = true
        end
    end
    local treatyPairs = {}
    for sourceID, faction in pairs(
        Factions.Registry.byID
    ) do
        for targetID, relation in pairs(
            faction.relations or {}
        ) do
            if relation.atWar == true
                or relation.allied == true
                or (tonumber(relation.truceUntil) or 0) > 0
            then
                local pairKey = Types.MakeDiplomacyKey(
                    sourceID,
                    targetID
                )
                if pairKey then treatyPairs[pairKey] = true end
            end
        end
    end
    for pairKey, _ in pairs(treatyPairs) do
        local firstID, secondID =
            string.match(pairKey, "^([^|]+)|([^|]+)$")
        local first = Factions.Registry.byID[firstID]
        local second = Factions.Registry.byID[secondID]
        if first and second then
            local firstRelation = Types.NormalizeRelation(
                first.relations[secondID],
                firstID,
                secondID
            )
            local secondRelation = Types.NormalizeRelation(
                second.relations[firstID],
                secondID,
                firstID
            )
            local active = first.status == "active"
                and second.status == "active"
            local atWar = active and (
                firstRelation.atWar == true
                or secondRelation.atWar == true
            )
            local allied = active and not atWar and (
                firstRelation.allied == true
                or secondRelation.allied == true
            )
            local truceUntil = active and not atWar
                and not allied and math.max(
                    tonumber(firstRelation.truceUntil) or 0,
                    tonumber(secondRelation.truceUntil) or 0
                ) or 0
            firstRelation.atWar = atWar
            secondRelation.atWar = atWar
            firstRelation.allied = allied
            secondRelation.allied = allied
            firstRelation.truceUntil = truceUntil
            secondRelation.truceUntil = truceUntil
            firstRelation.state =
                PNC.FactionDiplomacyMath.ResolveState(
                    firstRelation,
                    firstRelation.lastEvaluatedAt
                )
            secondRelation.state =
                PNC.FactionDiplomacyMath.ResolveState(
                    secondRelation,
                    secondRelation.lastEvaluatedAt
                )
            if not Types.AreEqual(
                first.relations[secondID],
                firstRelation
            ) then
                first.relations[secondID] = firstRelation
                changed = true
            end
            if not Types.AreEqual(
                second.relations[firstID],
                secondRelation
            ) then
                second.relations[firstID] = secondRelation
                changed = true
            end
        end
    end
    for npcID, record in pairs(
        PNC.Registry and PNC.Registry.Data or {}
    ) do
        local affiliation = Types.NormalizeAffiliation(
            record.affiliation
        )
        local faction = affiliation.factionID
            and Factions.Registry.byID[affiliation.factionID]
            or nil
        if affiliation.factionID and (
            not faction
            or faction.status == "archived"
            or faction.status == "destroyed"
        ) then
            local former = Internal.addHistory(
                affiliation,
                affiliation.factionID,
                math.max(
                    tonumber(affiliation.leftAt) or 0,
                    tonumber(affiliation.joinedAt) or 0
                ),
                faction and faction.status == "destroyed"
                    and "faction_destroyed"
                    or faction and "faction_archived"
                    or "unknown"
            )
            affiliation = Types.NewAffiliation({
                leftAt = affiliation.leftAt,
                formerFactionIDs = former,
                revision = affiliation.revision,
            })
        elseif faction then
            affiliation = Types.NormalizeAffiliation(
                affiliation,
                faction
            )
        end
        if not Types.AreEqual(record.affiliation, affiliation) then
            record.affiliation = affiliation
            if PNC.Registry and PNC.Registry.MarkDirty then
                PNC.Registry.MarkDirty(
                    record,
                    "affiliation_repair"
                )
            end
            changed = true
        end
        if affiliation.factionID
            and membersByFaction[affiliation.factionID]
        then
            membersByFaction[affiliation.factionID][npcID] = true
        end
    end
    for factionID, faction in pairs(Factions.Registry.byID) do
        local expected = membersByFaction[factionID] or {}
        if not Types.AreEqual(faction.memberIDs, expected) then
            faction.memberIDs = expected
            changed = true
        end
        if faction.leaderNPCID then
            local leader = PNC.Registry.Data[
                faction.leaderNPCID
            ]
            if not expected[faction.leaderNPCID]
                or not leader
                or leader.alive == false
            then
                faction.leaderNPCID = nil
                changed = true
            end
        end
    end
    if not Types.AreEqual(
        Factions.Registry.byArchetype,
        byArchetype
    ) then
        Factions.Registry.byArchetype = byArchetype
        changed = true
    end
    if not Types.AreEqual(
        Factions.Registry.byPlayerKey,
        byPlayerKey
    ) then
        Factions.Registry.byPlayerKey = byPlayerKey
        changed = true
    end
    if changed then Factions.Dirty = true end
    return changed
end

return Factions
