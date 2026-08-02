--[[
    PNC Client Requests
    Owns full-sync, debug-roster, and character-detail requests.
]]

PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState
local isWorldReady = Internal.IsWorldReady

local function requestFullSync()
    local player = getSpecificPlayer(0)
    if not isWorldReady() then
        return
    end
    ClientState.lastFullSyncRequestAt = Core.Now()
    if player and sendClientCommand then
        sendClientCommand(player, Const.MODULE, Const.CMD_FULL_SYNC_REQUEST, {})
        return
    end
    if PNC.Registry and PNC.Network and PNC.Network.BuildSnapshot then
        ClientState.snapshots = {}
        PNC.Registry.ForEach(function(record)
            local snapshot = PNC.Network.BuildSnapshot(record)
            ClientState.snapshots[snapshot.id] = snapshot
        end)
        ClientState.lastSyncReceiveAt = Core.Now()
        if Client.RequestKnownNPCKnowledge then
            Client.RequestKnownNPCKnowledge()
        end
    end
end

Client.RequestFullSync = requestFullSync

function Client.CanUseDebug()
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local access
    access = player and player.getAccessLevel and tostring(player:getAccessLevel() or "") or ""
    if string.lower(access) == "admin" then
        return true
    end
    if Core.IsClientOnly and Core.IsClientOnly() then
        return false
    end
    if isDebugEnabled then
        return isDebugEnabled() == true
    end
    return getCore and getCore() and getCore():getDebug() == true or false
end

function Client.RequestDebugRoster(forceAudit)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local diagnostics = {}
    if not Client.CanUseDebug() then
        ClientState.debugAuthorized = false
        ClientState.debugRoster = {}
        return false
    end
    ClientState.lastDebugRosterRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then
            sendClientCommand(player, Const.MODULE, Const.CMD_DEBUG_ROSTER_REQUEST, { audit = forceAudit == true })
            return true
        end
        return false
    end
    if PNC.BodyLifecycle and PNC.BodyLifecycle.AuditLoadedBodies then
        -- The monitor is also available in single-player, where there may be
        -- no remote server request to drive corpse cleanup. The audit owns its
        -- own throttling, so ordinary refreshes safely keep markers current.
        PNC.BodyLifecycle.AuditLoadedBodies(Core.Now(), forceAudit == true)
    end
    if PNC.BodyLifecycle and PNC.BodyLifecycle.BuildDebugRoster then
        diagnostics = PNC.BodyLifecycle.BuildDebugRoster()
    end
    ClientState.debugRoster = diagnostics
    ClientState.debugAuthorized = true
    ClientState.debugAudit = PNC.BodyLifecycle and PNC.BodyLifecycle.LastAudit or {}
    return true
end

function Client.RequestRelationshipDebug(
    observerNPCID,
    targetKind,
    targetNPCID
)
    local player = getSpecificPlayer
        and getSpecificPlayer(0) or nil
    local args = {
        observerNPCID = observerNPCID,
        targetKind = targetKind,
        targetNPCID = targetNPCID,
    }
    local snapshot
    local reason
    if not Client.CanUseDebug() then
        ClientState.relationshipDebugAuthorized = false
        ClientState.relationshipDebug = nil
        ClientState.relationshipDebugReason = "not_authorized"
        return false
    end
    ClientState.lastRelationshipDebugRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then
            sendClientCommand(
                player,
                Const.MODULE,
                Const.CMD_RELATIONSHIP_DEBUG_REQUEST,
                args
            )
            return true
        end
        return false
    end
    if not PNC.RelationshipDebug
        or not PNC.RelationshipDebug.BuildSnapshotForRequest
    then
        return false
    end
    snapshot, reason =
        PNC.RelationshipDebug.BuildSnapshotForRequest(
            player,
            args
        )
    ClientState.relationshipDebugAuthorized = true
    ClientState.relationshipDebug = snapshot
    ClientState.relationshipDebugReason = reason
    ClientState.lastRelationshipDebugReceiveAt = Core.Now()
    return snapshot ~= nil
end

function Client.RequestConversationRelationship(npcID)
    npcID = tostring(npcID or "")
    if npcID == "" then return false, "invalid_npc_id" end
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    ClientState.lastConversationRelationshipRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then
            sendClientCommand(player, Const.MODULE,
                Const.CMD_CONVERSATION_RELATIONSHIP_REQUEST,
                { npcID = npcID })
            return true
        end
        return false, "player_unavailable"
    end
    if not PNC.RelationshipPresentation
        or not PNC.RelationshipPresentation.BuildForConversation
    then
        return false, "presentation_unavailable"
    end
    local presentation = PNC.RelationshipPresentation
    local summary, reason = presentation.BuildForConversation(player, npcID)
    if summary then
        ClientState.conversationRelationships =
            ClientState.conversationRelationships or {}
        ClientState.conversationRelationships[npcID] = summary
        ClientState.lastConversationRelationshipReceiveAt = Core.Now()
        local relationship = PNC.Conversation
            and PNC.Conversation.Relationship
        if relationship and relationship.ReceivePresentation then
            relationship.ReceivePresentation(summary)
        end
    end
    return summary ~= nil, reason
end

function Client.RequestNPCKnowledge(npcID)
    npcID = tostring(npcID or "")
    if npcID == "" then return false, "invalid_npc_id" end
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    ClientState.lastNPCKnowledgeRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then
            sendClientCommand(player, Const.MODULE, Const.CMD_NPC_KNOWLEDGE_REQUEST, { npcID = npcID })
            return true
        end
        return false, "player_unavailable"
    end
    if not PNC.NPCKnowledge or not PNC.NPCKnowledge.BuildPlayerSnapshotForPlayer then
        return false, "knowledge_service_unavailable"
    end
    local snapshot, reason = PNC.NPCKnowledge.BuildPlayerSnapshotForPlayer(player, npcID)
    if snapshot then
        ClientState.npcKnowledge = ClientState.npcKnowledge or {}
        ClientState.npcKnowledge[npcID] = snapshot
        if PNC.NPCDossierUI and PNC.NPCDossierUI.ReceiveSnapshot then PNC.NPCDossierUI.ReceiveSnapshot(snapshot) end
    end
    return snapshot ~= nil, reason
end

-- Restores only this player's sparse, previously learned NPC facts. The
-- server uses the same path for multiplayer full sync; this local branch
-- covers single-player where the client calls services in-process.
function Client.RequestKnownNPCKnowledge()
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then
            sendClientCommand(player, Const.MODULE, Const.CMD_NPC_KNOWLEDGE_REQUEST, {
                allKnown = true,
            })
            return true
        end
        return false, "player_unavailable"
    end
    if not PNC.NPCKnowledge
        or not PNC.NPCKnowledge.BuildKnownSnapshotsForPlayer
    then
        return false, "knowledge_service_unavailable"
    end
    local snapshots, reason = PNC.NPCKnowledge.BuildKnownSnapshotsForPlayer(player)
    if not snapshots then return false, reason end
    ClientState.npcKnowledge = {}
    for _, snapshot in ipairs(snapshots) do
        ClientState.npcKnowledge[tostring(snapshot.npcID)] = snapshot
    end
    ClientState.lastNPCKnowledgeReceiveAt = Core.Now()
    return true
end

function Client.RequestNPCKnowledgeTopic(npcID, topicID)
    npcID = tostring(npcID or "")
    topicID = tostring(topicID or "")
    if npcID == "" or topicID == "" then return false, "invalid_knowledge_topic" end
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local args = { npcID = npcID, topicID = topicID }
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then
            sendClientCommand(player, Const.MODULE, Const.CMD_NPC_KNOWLEDGE_REQUEST, args)
            return true
        end
        return false, "player_unavailable"
    end
    if not PNC.NPCKnowledge or not PNC.NPCKnowledge.DiscoverTopicForPlayer then
        return false, "knowledge_service_unavailable"
    end
    local _, reason = PNC.NPCKnowledge.DiscoverTopicForPlayer(player, npcID, topicID, nil, "direct_disclosure")
    local snapshot, snapshotReason = PNC.NPCKnowledge.BuildPlayerSnapshotForPlayer(player, npcID)
    if snapshot then
        ClientState.npcKnowledge = ClientState.npcKnowledge or {}
        ClientState.npcKnowledge[npcID] = snapshot
        if PNC.NPCDossierUI and PNC.NPCDossierUI.ReceiveSnapshot then PNC.NPCDossierUI.ReceiveSnapshot(snapshot) end
    end
    return snapshot ~= nil, reason or snapshotReason
end

function Client.RequestKnowledgeDebug(npcID, showTruth, descriptorID)
    if not Client.CanUseDebug() then return false, "not_authorized" end
    npcID = tostring(npcID or "")
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local args = { npcID = npcID, showTruth = showTruth ~= false, descriptorID = descriptorID }
    ClientState.lastKnowledgeDebugRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then
            sendClientCommand(player, Const.MODULE, Const.CMD_KNOWLEDGE_DEBUG_REQUEST, args)
            return true
        end
        return false, "player_unavailable"
    end
    if not PNC.NPCKnowledge or not PNC.NPCKnowledge.BuildDebugSnapshotForPlayer then return false, "knowledge_service_unavailable" end
    local snapshot, reason = PNC.NPCKnowledge.BuildDebugSnapshotForPlayer(player, npcID, args.showTruth, descriptorID)
    ClientState.knowledgeDebugAuthorized = true
    ClientState.knowledgeDebug, ClientState.knowledgeDebugReason = snapshot, reason
    if PNC.KnowledgeDebugUI and PNC.KnowledgeDebugUI.ReceiveSnapshot then PNC.KnowledgeDebugUI.ReceiveSnapshot(snapshot) end
    return snapshot ~= nil, reason
end

function Client.RequestFactionDebug(
    factionID,
    npcID,
    targetFactionID
)
    local player = getSpecificPlayer
        and getSpecificPlayer(0) or nil
    local args = {
        factionID = factionID,
        npcID = npcID,
        targetFactionID = targetFactionID,
    }
    local snapshot
    if not Client.CanUseDebug() then
        ClientState.factionDebugAuthorized = false
        ClientState.factionDebug = nil
        ClientState.factionDebugReason = "not_authorized"
        return false
    end
    ClientState.lastFactionDebugRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then
            sendClientCommand(
                player,
                Const.MODULE,
                Const.CMD_FACTION_DEBUG_REQUEST,
                args
            )
            return true
        end
        return false
    end
    if not PNC.FactionDebug
        or not PNC.FactionDebug.BuildSnapshot
    then
        return false
    end
    snapshot = PNC.FactionDebug.BuildSnapshot(
        factionID,
        npcID,
        nil,
        player,
        targetFactionID
    )
    ClientState.factionDebugAuthorized = true
    ClientState.factionDebug = snapshot
    ClientState.factionDebugReason = nil
    ClientState.lastFactionDebugReceiveAt = Core.Now()
    return snapshot ~= nil
end

function Client.RequestFactionMembers()
    local player = getSpecificPlayer
        and getSpecificPlayer(0) or nil
    if not player then return false end
    ClientState.lastFactionMembersRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then return false end
        sendClientCommand(
            player,
            Const.MODULE,
            Const.CMD_FACTION_MEMBERS_REQUEST,
            {}
        )
        return true
    end
    if not PNC.FactionMembership
        or not PNC.FactionMembership.BuildSnapshot
    then
        return false
    end
    local snapshot
    local reason
    snapshot, reason =
        PNC.FactionMembership.BuildSnapshot(player)
    ClientState.factionMembers = snapshot
    ClientState.factionMembersReason = reason
    ClientState.lastFactionMembersReceiveAt = Core.Now()
    return snapshot ~= nil
end

function Client.RequestCommunityDebug(
    communityID,
    factionID,
    npcID
)
    local player = getSpecificPlayer
        and getSpecificPlayer(0) or nil
    local args = {
        communityID = communityID,
        factionID = factionID,
        npcID = npcID,
    }
    local snapshot
    if not Client.CanUseDebug() then
        ClientState.communityDebugAuthorized = false
        ClientState.communityDebug = nil
        ClientState.communityDebugReason = "not_authorized"
        return false
    end
    ClientState.lastCommunityDebugRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then
            sendClientCommand(
                player,
                Const.MODULE,
                Const.CMD_COMMUNITY_DEBUG_REQUEST,
                args
            )
            return true
        end
        return false
    end
    if not PNC.CommunityDebug
        or not PNC.CommunityDebug.BuildSnapshot
    then
        return false
    end
    snapshot = PNC.CommunityDebug.BuildSnapshot(
        communityID,
        factionID,
        npcID,
        nil,
        player
    )
    ClientState.communityDebugAuthorized = true
    ClientState.communityDebug = snapshot
    ClientState.communityDebugReason = nil
    ClientState.lastCommunityDebugReceiveAt = Core.Now()
    return snapshot ~= nil
end

function Client.RequestNeedsDebug(groupID, npcID)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not Client.CanUseDebug() then
        ClientState.needsDebugAuthorized, ClientState.needsDebug = false, nil
        ClientState.needsDebugReason = "not_authorized"
        return false
    end
    ClientState.lastNeedsDebugRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then
            sendClientCommand(player, Const.MODULE, Const.CMD_NEEDS_DEBUG_REQUEST, { groupID = groupID, npcID = npcID })
            return true
        end
        return false
    end
    if not PNC.NeedsDebug or not PNC.NeedsDebug.BuildSnapshot then return false end
    ClientState.needsDebugAuthorized = true
    ClientState.needsDebug = PNC.NeedsDebug.BuildSnapshot(groupID, npcID, nil)
    ClientState.needsDebugReason = nil
    ClientState.lastNeedsDebugReceiveAt = Core.Now()
    return true
end

function Client.RequestCharacterPayload(npcId)
    local player = getSpecificPlayer(0)
    local payload
    local cached
    local inventoryRevision
    if not npcId then
        return false
    end
    if not sendClientCommand and PNC.API and PNC.API.GetCharacterPayload then
        payload = PNC.API.GetCharacterPayload(npcId)
        if payload then
            ClientState.characterPayloads = ClientState.characterPayloads or {}
            ClientState.characterPayloads[npcId] = payload
            if payload.snapshot and payload.snapshot.id then
                ClientState.snapshots[payload.snapshot.id] = payload.snapshot
            end
            return true
        end
        return false
    end
    if not player or not sendClientCommand then
        return false
    end
    cached = ClientState.characterPayloads and ClientState.characterPayloads[npcId] or nil
    inventoryRevision = cached and cached.inventory and cached.inventory.summary
        and tonumber(cached.inventory.summary.revision) or nil
    sendClientCommand(player, Const.MODULE, Const.CMD_REQUEST_CHARACTER, {
        id = npcId,
        inventoryRevision = inventoryRevision,
    })
    return true
end
