if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.StartingCompanions = PNC.StartingCompanions or {}
PNC.StartingCompanionServiceInternal =
    PNC.StartingCompanionServiceInternal or {}

local Starting = PNC.StartingCompanions
local H = PNC.StartingCompanionServiceInternal
local Traits = PNC.StartingCompanionTraits
local Identity = PNC.Identity
local Registry = PNC.Registry
local EntityRef = PNC.EntityRef

function H.ResolvePlayerTargetKey(player, character, context)
    local targetKey
    local accountKey
    if PNC.PlayerCharacters
        and PNC.PlayerCharacters.GetEntityKey
    then
        targetKey = PNC.PlayerCharacters.GetEntityKey(player, context)
        if targetKey then return targetKey, "canonical" end
    end
    accountKey = character
        and (character.accountKey or character.accountIdentity)
    if not accountKey or not character or not character.uuid then
        return nil, "player_entity_key_unavailable"
    end
    targetKey = EntityRef.ForPlayerIdentity(accountKey, character.uuid)
    return targetKey, targetKey and "fallback" or "player_entity_key_invalid"
end

function H.LegacyPlayerTargetKey(character)
    if not character or not character.accountIdentity
        or not character.uuid
    then
        return nil
    end
    return EntityRef.ForPlayerIdentity(
        character.accountIdentity,
        character.uuid
    )
end

function H.RepairRelationshipKey(player, character, grant, at)
    local targetKey
    local legacyTargetKey
    local reason
    local migrated
    if type(grant) ~= "table" then
        return false, "starting_companion_grant_missing"
    end
    if (tonumber(grant.relationshipKeyVersion) or 0)
        >= Starting.RELATIONSHIP_KEY_VERSION
    then
        return false, "already_repaired"
    end
    targetKey, reason = H.ResolvePlayerTargetKey(player, character, {
        callback = "starting_companion_relationship_key_repair",
        worldAgeHours = at,
    })
    if not targetKey then return false, reason end
    legacyTargetKey = H.LegacyPlayerTargetKey(character)
    if not legacyTargetKey or legacyTargetKey == targetKey then
        grant.relationshipKeyVersion = Starting.RELATIONSHIP_KEY_VERSION
        return true, "same_target_key"
    end
    if not PNC.Relationships
        or not PNC.Relationships.MigrateTargetKey
    then
        return false, "relationship_service_unavailable"
    end
    migrated, reason = PNC.Relationships.MigrateTargetKey(
        grant.npcID,
        legacyTargetKey,
        targetKey,
        at
    )
    if not migrated and reason ~= "source_not_found"
        and reason ~= "target_exists"
    then
        return false, reason
    end
    grant.relationshipKeyVersion = Starting.RELATIONSHIP_KEY_VERSION
    return true, reason or "migrated"
end

function H.HasCanonicalAssignment(player, record)
    if not H.OwnerMatches(record, player)
        or not PNC.Factions or not PNC.Factions.GetPlayerFaction
        or not PNC.Factions.GetNPCAffiliation
        or not PNC.Communities or not PNC.Communities.GetNPCCommunity
    then return false end
    local playerFaction = PNC.Factions.GetPlayerFaction(player)
    local affiliation = PNC.Factions.GetNPCAffiliation(record.id)
    if not playerFaction or not affiliation
        or affiliation.factionID ~= playerFaction.id
    then return false end
    local community = PNC.Communities.GetNPCCommunity(record.id)
    return community ~= nil
        and community.status == "active"
        and community.factionID == playerFaction.id
end

function H.ApplyLifelongKnowledge(player, character, npcID, spec, at)
    local targetKey = H.ResolvePlayerTargetKey(player, character, {
        callback = "starting_companion_relationship",
        worldAgeHours = at,
    })
    local legacyTargetKey = H.LegacyPlayerTargetKey(character)
    if targetKey and legacyTargetKey
        and targetKey ~= legacyTargetKey
        and PNC.Relationships
        and PNC.Relationships.MigrateTargetKey
    then
        PNC.Relationships.MigrateTargetKey(
            npcID, legacyTargetKey, targetKey, at
        )
    end
    if targetKey and PNC.Relationships
        and PNC.Relationships.SetInitialBaseline
    then
        local lover = spec.relationshipKind == "lover"
        local friend = spec.relationshipKind == "friend"
        PNC.Relationships.SetInitialBaseline(npcID, targetKey, {
            approval = lover and 90 or friend and 75 or 85,
            respect = lover and 75 or friend and 65 or 70,
            familiarity = friend and 90 or 100,
        }, at)
    end
    if PNC.NPCKnowledge and PNC.NPCKnowledge.DiscoverAllForPlayer then
        PNC.NPCKnowledge.DiscoverAllForPlayer(
            player, npcID, at, "lifelong_relationship", true
        )
    end
    -- Identity is required for the starter companion UI. Keep this explicit
    -- even when broad dossier discovery partially fails on an older save.
    if PNC.NPCKnowledge and PNC.NPCKnowledge.DiscoverTopicForPlayer then
        PNC.NPCKnowledge.DiscoverTopicForPlayer(
            player, npcID, "identity_name", at,
            "lifelong_relationship", true
        )
    end
    if PNC.NPCKnowledge
        and PNC.NPCKnowledge.BuildPlayerSnapshotForPlayer
        and PNC.Network and PNC.Network.SendNPCKnowledge
    then
        local snapshot = PNC.NPCKnowledge.BuildPlayerSnapshotForPlayer(
            player, npcID
        )
        if snapshot then
            local record = PNC.Registry and PNC.Registry.Get
                and PNC.Registry.Get(npcID) or nil
            local identity = record and PNC.Identity
                and PNC.Identity.GetCharacterSummary
                and PNC.Identity.GetCharacterSummary(record) or {}
            snapshot.memory_primitives = {
                {
                    primitive_type = "pre_outbreak_relationship",
                    memory_type = "PERSONAL_EVENT",
                    player_uuid = character.uuid,
                    npc_uuid = npcID,
                    npc_name = identity.displayName or record and record.name,
                    relationship_kind = spec.relationshipKind,
                    variant_key = spec.id,
                    event_time = {
                        kind = "pre_outbreak",
                        phase = "before_outbreak",
                        label = "Before the outbreak",
                    },
                    source = "lifelong_relationship",
                    authoritative = true,
                },
            }
            PNC.Network.SendNPCKnowledge(
                player, snapshot, "lifelong_relationship"
            )
        end
    end
end

return Starting
