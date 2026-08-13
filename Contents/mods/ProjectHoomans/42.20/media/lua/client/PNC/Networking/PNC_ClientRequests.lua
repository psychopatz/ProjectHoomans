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
local KnowledgeInterest = PNC.KnowledgeInterest
    or require "PNC/Knowledge/PNC_KnowledgeInterest"
local isWorldReady = Internal.IsWorldReady
ClientState.identityRequestSerial = ClientState.identityRequestSerial or 0
local BOOTSTRAP_RETRY_MS = 4000
local BOOTSTRAP_RETRY_MAX_MS = 30000

local function requestID(prefix)
    ClientState.identityRequestSerial = ClientState.identityRequestSerial + 1
    return tostring(prefix) .. ":" .. tostring(Core.Now()) .. ":"
        .. tostring(ClientState.identityRequestSerial)
end

local function dispatchIdentity(player, command, args, localHandler)
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not player or not sendClientCommand then
            return false, "player_unavailable"
        end
        sendClientCommand(player, Const.MODULE, command, args)
        return true, "sent"
    end
    if not PNC.PlayerKnowledgeCommands
        or not PNC.PlayerKnowledgeCommands[localHandler]
    then return false, "identity_command_handler_unavailable" end
    PNC.PlayerKnowledgeCommands[localHandler](player, args)
    return true, "dispatched"
end

function Client.RequestPlayerBootstrap()
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local args = {
        requestID = requestID("bootstrap"),
        scope = "interest",
        npcIDs = KnowledgeInterest.CollectNPCIDs(true),
    }
    ClientState.lastBootstrapRequestAt = Core.Now()
    ClientState.bootstrapRetryAttempt =
        (tonumber(ClientState.bootstrapRetryAttempt) or 0) + 1
    ClientState.bootstrapState = "loading"
    ClientState.activeBootstrapRequestID = args.requestID
    return dispatchIdentity(player, Const.CMD_PLAYER_BOOTSTRAP_REQUEST,
        args, "HandleBootstrap")
end

function Client.IsPlayerBootstrapCurrent()
    local context = ClientState.playerContext
    return ClientState.bootstrapState == "known"
        and type(context) == "table"
        and tostring(context.characterUUID or "") ~= ""
        and #KnowledgeInterest.CollectNPCIDs(true) == 0
end

-- NPC roster replication and per-player knowledge use different authority
-- paths. A successful roster must never suppress retries for a bootstrap that
-- ran before the persistent player identity was ready during world startup.
function Client.EnsurePlayerBootstrap(now, force)
    now = tonumber(now) or Core.Now()
    if Client.IsPlayerBootstrapCurrent() then
        return true, "current"
    end
    if not isWorldReady() then
        return false, "world_not_ready"
    end
    local last = tonumber(ClientState.lastBootstrapRequestAt) or 0
    local attempt = math.max(
        1,
        tonumber(ClientState.bootstrapRetryAttempt) or 1
    )
    local retryMS = math.min(
        BOOTSTRAP_RETRY_MAX_MS,
        BOOTSTRAP_RETRY_MS * (2 ^ math.min(attempt - 1, 3))
    )
    if force ~= true and last > 0 and now - last < retryMS then
        return false, "throttled"
    end
    return Client.RequestPlayerBootstrap()
end

local function applyKnowledgeSnapshot(snapshot, reason)
    if Internal.ApplyNPCKnowledgeSnapshot then
        return Internal.ApplyNPCKnowledgeSnapshot(snapshot, reason)
    end
    return false
end

local function requestFullSync()
    local player = getSpecificPlayer(0)
    if not isWorldReady() then
        return
    end
    ClientState.lastFullSyncRequestAt = Core.Now()
    if player and sendClientCommand then
        sendClientCommand(player, Const.MODULE, Const.CMD_FULL_SYNC_REQUEST, {})
        Client.EnsurePlayerBootstrap(Core.Now(), false)
        if Client.RequestWorldDiscovery then
            Client.RequestWorldDiscovery("snapshot")
        end
        return
    end
    if PNC.Registry and PNC.Network and PNC.Network.BuildSnapshot then
        ClientState.snapshots = {}
        PNC.Registry.ForEach(function(record)
            local snapshot = PNC.Network.BuildSnapshot(record)
            ClientState.snapshots[snapshot.id] = snapshot
        end)
        ClientState.lastSyncReceiveAt = Core.Now()
        if Client.EnsurePlayerBootstrap then
            Client.EnsurePlayerBootstrap(Core.Now(), false)
        end
        if Client.RequestWorldDiscovery then
            Client.RequestWorldDiscovery("snapshot")
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
    ClientState.npcPresentations = ClientState.npcPresentations or {}
    local existing = ClientState.npcPresentations[npcID]
    local args = type(existing) == "table"
        and Core.DeepCopy(existing) or { npcID = npcID, state = "loading" }
    args.npcID = npcID
    args.requestID = requestID("presentation")
    if args.state ~= "known" then args.state = "loading" end
    ClientState.npcPresentations[npcID] = args
    return dispatchIdentity(player, Const.CMD_NPC_PRESENTATION_REQUEST,
        { npcID = npcID, requestID = args.requestID }, "HandlePresentation")
end

-- Restores only this player's sparse, previously learned NPC facts. The
-- server uses the same path for multiplayer full sync; this local branch
-- covers single-player where the client calls services in-process.
function Client.RequestKnownNPCKnowledge()
    return Client.RequestPlayerBootstrap()
end

function Client.RequestNPCKnowledgeTopic(npcID, topicID)
    npcID = tostring(npcID or "")
    topicID = tostring(topicID or "")
    if npcID == "" or topicID == "" then return false, "invalid_knowledge_topic" end
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local args = {
        requestID = requestID("disclosure"),
        npcID = npcID,
        topicID = topicID,
    }
    ClientState.pendingDisclosure = ClientState.pendingDisclosure or {}
    ClientState.pendingDisclosure[npcID] = args.requestID
    return dispatchIdentity(player, Const.CMD_KNOWLEDGE_DISCLOSURE_REQUEST,
        args, "HandleDisclosure")
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

function Client.RequestDirectorDebug(groupID, locationID, populationSectorID)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local args = { groupID = groupID, locationID = locationID,
        populationSectorID = populationSectorID }
    if not Client.CanUseDebug() then
        ClientState.directorDebugAuthorized = false
        ClientState.directorDebug = nil
        ClientState.directorDebugReason = "not_authorized"
        return false
    end
    ClientState.lastDirectorDebugRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then
            sendClientCommand(player, Const.MODULE,
                Const.CMD_DIRECTOR_DEBUG_REQUEST, args)
            return true
        end
        return false
    end
    if not PNC.AbstractDirectorDebug then return false end
    ClientState.directorDebugAuthorized = true
    ClientState.directorDebug = PNC.AbstractDirectorDebug.BuildSnapshot(
        groupID, locationID, nil, populationSectorID)
    ClientState.directorDebugReason = nil
    ClientState.lastDirectorDebugReceiveAt = Core.Now()
    return true
end

function Client.RequestColonyManagement()
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then sendClientCommand(player, Const.MODULE, Const.CMD_COLONY_MANAGEMENT_REQUEST, {}); return true end
        return false
    end
    if not PNC.ColonyManagement or not PNC.ColonyManagement.BuildSnapshot then return false end
    ClientState.colonyManagement = PNC.ColonyManagement.BuildSnapshot(player)
    ClientState.colonyManagementRevision =
        (tonumber(ClientState.colonyManagementRevision) or 0) + 1
    ClientState.lastColonyManagementReceiveAt = Core.Now()
    if PNC.ColonyNamePrompt and PNC.ColonyNamePrompt.OpenIfNeeded then
        PNC.ColonyNamePrompt.OpenIfNeeded(ClientState.colonyManagement)
    end
    return true
end

function Client.RequestColonyAction(action, options)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local args = type(options) == "table" and Core.DeepCopy(options) or {}
    args.action = tostring(action or "")
    args.requestId = args.requestId or requestID("colony")
    if PNC.Nameplates and PNC.Nameplates.Settings
        and PNC.Nameplates.Settings.storageTransactionLogging == true
    then
        args.transactionLogging = true
    end
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not player or not sendClientCommand then
            return false, "player_unavailable"
        end
        sendClientCommand(
            player, Const.MODULE, Const.CMD_COLONY_MANAGEMENT_ACTION, args
        )
        return true, "sent"
    end
    if not PNC.ColonyManagement or not PNC.ColonyManagement.HandleAction then
        return false, "colony_management_unavailable"
    end
    local snapshot, result = PNC.ColonyManagement.HandleAction(player, args)
    snapshot.actionResult = result
    ClientState.colonyManagement = snapshot
    ClientState.colonyManagementRevision =
        (tonumber(ClientState.colonyManagementRevision) or 0) + 1
    ClientState.lastColonyManagementReceiveAt = Core.Now()
    if (result.action == "storage_player_deposit"
            or result.action == "storage_player_withdraw"
            or result.action == "storage_npc_deposit")
        and PNC.InventoryWindow
        and PNC.InventoryWindow.OnColonyStorageResult
    then
        PNC.InventoryWindow.OnColonyStorageResult(result)
    end
    return result and result.ok == true, result and result.reason
end

function Client.RequestCreateBase(options)
    return Client.RequestColonyAction("base_create", options)
end

function Client.RequestExpandBase(options)
    return Client.RequestColonyAction("base_expand", options)
end

function Client.RequestShrinkBase(options)
    return Client.RequestColonyAction("base_shrink", options)
end

function Client.RequestBuildBarricade(options)
    return Client.RequestColonyAction("barricade_build", options)
end

function Client.RequestUpgradeHQ(options)
    return Client.RequestColonyAction("hq_upgrade", options)
end

function Client.RequestCreateFacility(options)
    return Client.RequestColonyAction("facility_create", options)
end

function Client.RequestUpgradeFacility(options)
    return Client.RequestColonyAction("facility_upgrade", options)
end

function Client.RequestSetFacilityComponent(options)
    return Client.RequestColonyAction("facility_component_set", options)
end

function Client.RequestRemoveFacilityComponent(options)
    return Client.RequestColonyAction("facility_component_remove", options)
end

function Client.RequestDestroyFacility(options)
    return Client.RequestColonyAction("facility_destroy", options)
end

function Client.RequestCreateStockpileAccessNode(options)
    return Client.RequestColonyAction("stockpile_node_create", options)
end

function Client.DepositPlayerItemsToColony(itemIDs, storageId)
    return Client.RequestColonyAction("storage_player_deposit", {
        itemIDs = itemIDs,
        storageId = storageId,
    })
end

function Client.TransferPlayerStorage(options)
    options = type(options) == "table" and options or {}
    if options.direction == "player_to_storage" then
        return Client.RequestColonyAction("storage_player_deposit", options)
    end
    if options.direction == "storage_to_player" then
        return Client.RequestColonyAction("storage_player_withdraw", options)
    end
    return false, "invalid_direction"
end

function Client.DepositNPCItemToColony(npcId, itemID, quantity, revision, storageId)
    return Client.RequestColonyAction("storage_npc_deposit", {
        npcId = npcId,
        itemID = itemID,
        quantity = quantity,
        inventoryRevision = revision,
        storageId = storageId,
    })
end

function Client.RequestWorldDiscovery(action, options)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local args = type(options) == "table"
        and Core.DeepCopy(options) or {}
    args.action = tostring(action or "snapshot")
    local command = args.action == "snapshot"
        and Const.CMD_WORLD_DISCOVERY_REQUEST
        or Const.CMD_WORLD_DISCOVERY_ACTION
    ClientState.lastWorldDiscoveryRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not player or not sendClientCommand then
            return false, "player_unavailable"
        end
        sendClientCommand(player, Const.MODULE, command, args)
        return true, "sent"
    end
    if not PNC.WorldDiscovery or not PNC.WorldDiscovery.HandleAction then
        return false, "discovery_service_unavailable"
    end
    local payload = PNC.WorldDiscovery.HandleAction(player, args)
    if Internal.ApplyWorldDiscoverySnapshot then
        Internal.ApplyWorldDiscoverySnapshot(payload)
    end
    return payload and payload.state == "known", payload
end

function Client.IsWorldDiscoveryCurrent()
    local snapshot = ClientState.worldDiscovery
    local context = ClientState.playerContext
    if type(snapshot) ~= "table" or snapshot.state ~= "known"
        or tostring(snapshot.characterUUID or "") == ""
    then return false end
    return not context or not context.characterUUID
        or tostring(snapshot.characterUUID)
            == tostring(context.characterUUID)
end

function Client.EnsureWorldDiscovery(now, force)
    now = tonumber(now) or Core.Now()
    if Client.IsWorldDiscoveryCurrent() then return true, "current" end
    if not isWorldReady() then return false, "world_not_ready" end
    local last = tonumber(ClientState.lastWorldDiscoveryRequestAt) or 0
    if force ~= true and last > 0 and now - last < 4000 then
        return false, "throttled"
    end
    return Client.RequestWorldDiscovery("snapshot")
end

function Client.RenameColony(communityID, name)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local args = {
        action = "rename",
        communityID = tostring(communityID or ""),
        name = tostring(name or ""),
    }
    if args.communityID == "" then return false, "invalid_community" end
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not player or not sendClientCommand then
            return false, "player_unavailable"
        end
        sendClientCommand(
            player,
            Const.MODULE,
            Const.CMD_COLONY_MANAGEMENT_ACTION,
            args
        )
        return true
    end
    if not PNC.ColonyManagement
        or not PNC.ColonyManagement.RenameForPlayer
    then
        return false, "colony_management_unavailable"
    end
    local snapshot, result = PNC.ColonyManagement.RenameForPlayer(
        player,
        args
    )
    snapshot.actionResult = result
    ClientState.colonyManagement = snapshot
    ClientState.colonyManagementRevision =
        (tonumber(ClientState.colonyManagementRevision) or 0) + 1
    ClientState.lastColonyManagementReceiveAt = Core.Now()
    return result and result.ok == true, result and result.reason
end

function Client.RenameFaction(name)
    return Client.RequestColonyAction("faction_rename", {
        name = tostring(name or ""),
    })
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
