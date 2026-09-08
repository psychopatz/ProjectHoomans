-- Shared initialization for debug-spawned companions.
--
-- The debug menu has two execution paths: the server command in multiplayer
-- and the in-process client action in single-player. Keep the companion
-- contract in one place so both paths match the Has-a-friend starter grant.

PNC = PNC or {}
PNC.DebugCompanionInitialization =
    PNC.DebugCompanionInitialization or {}

local Initialization = PNC.DebugCompanionInitialization

local FRIEND_STANDING = {
    approval = 75,
    respect = 65,
    familiarity = 90,
}

function Initialization.ApplyKnownCompanion(player, npcID, worldAgeHours)
    local playerCharacters = PNC.PlayerCharacters
    local relationships = PNC.Relationships
    local knowledge = PNC.NPCKnowledge
    local targetKey
    local relationship
    local disclosure
    local snapshot
    local reason
    local relationshipApplied = false
    local knowledgeApplied = false
    local relationshipReason

    if not player or not npcID then
        return false, "companion_identity_unavailable"
    end
    if not playerCharacters or not playerCharacters.GetEntityKey then
        return false, "player_identity_service_unavailable"
    end

    targetKey, reason = playerCharacters.GetEntityKey(player, {
        callback = "debug_companion_spawn",
        worldAgeHours = worldAgeHours,
    })
    if not targetKey then return false, reason end

    if relationships and relationships.SetInitialBaseline then
        relationship = relationships.SetInitialBaseline(
            npcID,
            targetKey,
            FRIEND_STANDING,
            worldAgeHours
        )
        relationshipApplied = true
    else
        relationshipReason = "relationship_service_unavailable"
    end

    -- This is intentionally the same disclosure source and deferred commit
    -- contract used by StartingCompanionService.ApplyLifelongKnowledge.
    if knowledge and knowledge.DiscoverAllForPlayer then
        disclosure = knowledge.DiscoverAllForPlayer(
            player, npcID, worldAgeHours, "lifelong_relationship", true
        )
    elseif knowledge and knowledge.DiscoverTopicForPlayer then
        disclosure = knowledge.DiscoverTopicForPlayer(
            player,
            npcID,
            "identity_name",
            worldAgeHours,
            "direct_disclosure",
            true
        )
    end
    knowledgeApplied = disclosure ~= nil

    if knowledge and knowledge.BuildPlayerSnapshotForPlayer
        and PNC.Network and PNC.Network.SendNPCKnowledge
    then
        snapshot = knowledge.BuildPlayerSnapshotForPlayer(player, npcID)
        if snapshot then
            PNC.Network.SendNPCKnowledge(
                player,
                snapshot,
                "lifelong_relationship"
            )
        end
    end

    if not relationshipApplied and not knowledgeApplied and not snapshot then
        return false, relationshipReason or "knowledge_service_unavailable"
    end
    return true, {
        targetKey = targetKey,
        relationship = relationship,
        relationshipApplied = relationshipApplied,
        relationshipReason = relationshipReason,
        knowledgeApplied = knowledgeApplied,
        disclosure = disclosure,
        snapshot = snapshot,
    }
end

return Initialization
