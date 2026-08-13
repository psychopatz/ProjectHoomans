-- Diagnostic query adapters. Domain services retain snapshot policy.

local Router = PNC.ServerCommandRouter
local Const = PNC.Const
local Core = PNC.Core
local Network = PNC.Network
local BodyLifecycle = PNC.BodyLifecycle

Router.Register(Const.CMD_DEBUG_ROSTER_REQUEST, function(player, args, rawArgs)
    if not Router.CanUseDebug(player) then
        Network.SendDebugRoster(
            player,
            {},
            false,
            BodyLifecycle and BodyLifecycle.LastAudit or {}
        )
        return
    end
    if rawArgs and rawArgs.audit == true
        and BodyLifecycle and BodyLifecycle.AuditLoadedBodies
    then
        BodyLifecycle.AuditLoadedBodies(Core.Now(), true)
    end
    Network.SendDebugRoster(
        player,
        BodyLifecycle and BodyLifecycle.BuildDebugRoster
            and BodyLifecycle.BuildDebugRoster() or {},
        true,
        BodyLifecycle and BodyLifecycle.LastAudit or {}
    )
end)

Router.Register(Const.CMD_RELATIONSHIP_DEBUG_REQUEST, function(player, args)
    local snapshot
    local reason
    if not Router.CanUseDebug(player) then
        Network.SendRelationshipDebug(player, nil, false, "not_authorized")
        return
    end
    snapshot, reason = PNC.RelationshipDebug.BuildSnapshotForRequest(
        player,
        args
    )
    Network.SendRelationshipDebug(player, snapshot, true, reason)
end)

Router.Register(Const.CMD_CONVERSATION_RELATIONSHIP_REQUEST,
    function(player, args, rawArgs)
        local summary
        local reason
        local presentation = PNC.RelationshipPresentation
        if presentation and presentation.BuildForConversation then
            summary, reason = presentation.BuildForConversation(
                player,
                rawArgs and rawArgs.npcID
            )
        else
            reason = "presentation_unavailable"
        end
        Network.SendConversationRelationship(player, summary, reason)
    end
)

Router.Register(Const.CMD_NPC_KNOWLEDGE_REQUEST,
    function(player, args, rawArgs)
        local snapshot
        local reason
        local disclosureReason
        local knowledge = PNC.NPCKnowledge
        if knowledge and rawArgs and rawArgs.allKnown == true
            and knowledge.BuildKnownSnapshotsForPlayer
        then
            local knowledgeSnapshots
            knowledgeSnapshots, reason =
                knowledge.BuildKnownSnapshotsForPlayer(player)
            for _, knowledgeSnapshot in ipairs(knowledgeSnapshots or {}) do
                Network.SendNPCKnowledge(player, knowledgeSnapshot)
            end
            return
        end
        if knowledge and rawArgs and rawArgs.topicID
            and knowledge.DiscoverTopicForPlayer
        then
            _, disclosureReason = knowledge.DiscoverTopicForPlayer(
                player,
                rawArgs.npcID,
                rawArgs.topicID,
                nil,
                "direct_disclosure"
            )
        end
        if knowledge and knowledge.BuildPlayerSnapshotForPlayer then
            snapshot, reason = knowledge.BuildPlayerSnapshotForPlayer(
                player,
                rawArgs and rawArgs.npcID
            )
        else
            reason = "knowledge_service_unavailable"
        end
        Network.SendNPCKnowledge(player, snapshot, disclosureReason or reason)
    end
)

Router.Register(Const.CMD_KNOWLEDGE_DEBUG_REQUEST,
    function(player, args, rawArgs)
        if not Router.CanUseDebug(player) then
            Network.SendKnowledgeDebug(player, nil, false, "not_authorized")
            return
        end
        local snapshot
        local reason
        local knowledge = PNC.NPCKnowledge
        if knowledge and knowledge.BuildDebugSnapshotForPlayer then
            snapshot, reason = knowledge.BuildDebugSnapshotForPlayer(
                player,
                rawArgs and rawArgs.npcID,
                rawArgs and rawArgs.showTruth ~= false,
                rawArgs and rawArgs.descriptorID
            )
        else
            reason = "knowledge_service_unavailable"
        end
        Network.SendKnowledgeDebug(player, snapshot, true, reason)
    end
)
