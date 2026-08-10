--[[
    PNC Client Command Router
    Dispatches inbound server commands to domain-owned handlers.
]]

PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState
local Handlers = Internal.ServerCommandHandlers or {}

Internal.ServerCommandHandlers = Handlers

function Internal.RegisterServerCommand(command, handler)
    if command == nil or type(handler) ~= "function" then
        return false
    end
    Handlers[command] = handler
    return true
end

Internal.RegisterServerCommand(Const.CMD_DEBUG_ROSTER, function(args)
    ClientState.debugAuthorized = args.authorized == true
    ClientState.debugRoster = args.diagnostics or {}
    ClientState.debugAudit = args.audit or {}
    ClientState.lastDebugRosterReceiveAt = Core.Now()
end)

Internal.RegisterServerCommand(
    Const.CMD_RELATIONSHIP_DEBUG,
    function(args)
        ClientState.relationshipDebugAuthorized =
            args.authorized == true
        ClientState.relationshipDebug = args.snapshot
        ClientState.relationshipDebugReason = args.reason
        ClientState.lastRelationshipDebugReceiveAt = Core.Now()
        local relationship = PNC.Conversation
            and PNC.Conversation.Relationship
        if relationship and relationship.ReceiveDebugSnapshot then
            relationship.ReceiveDebugSnapshot(args.snapshot)
        end
    end
)

Internal.RegisterServerCommand(
    Const.CMD_CONVERSATION_RELATIONSHIP,
    function(args)
        local summary = args.summary
        if type(summary) ~= "table" or not summary.npcID then return end
        ClientState.conversationRelationships =
            ClientState.conversationRelationships or {}
        ClientState.conversationRelationships[tostring(summary.npcID)] =
            summary
        ClientState.lastConversationRelationshipReceiveAt = Core.Now()
        local relationship = PNC.Conversation
            and PNC.Conversation.Relationship
        if relationship and relationship.ReceivePresentation then
            relationship.ReceivePresentation(summary)
        end
    end
)

-- Both network replies (multiplayer) and direct in-process service calls
-- (single-player) enter through this receiver.  Keeping cache mutation and UI
-- invalidation here prevents the two topologies from drifting apart.
local function identityNameFact(snapshot)
    for _, category in ipairs(snapshot and snapshot.categories or {}) do
        for _, descriptor in ipairs(category.descriptors or {}) do
            if descriptor.descriptorID == "identity.name"
                and descriptor.value ~= nil
            then return descriptor end
        end
    end
    return nil
end

function Internal.ApplyNPCKnowledgeSnapshot(snapshot, reason)
    if type(snapshot) == "table" and snapshot.npcID then
        local npcID = tostring(snapshot.npcID)
        ClientState.npcKnowledge = ClientState.npcKnowledge or {}
        ClientState.npcKnowledge[npcID] = snapshot
        if PNC.KnowledgeInterest and PNC.KnowledgeInterest.Acknowledge then
            PNC.KnowledgeInterest.Acknowledge(npcID)
        end
        local nameFact = identityNameFact(snapshot)
        if nameFact then
            ClientState.npcPresentations = ClientState.npcPresentations or {}
            local presentation = ClientState.npcPresentations[npcID] or {}
            presentation.npcID = npcID
            presentation.state = "known"
            presentation.canAskName = false
            presentation.displayName = tostring(nameFact.value)
            presentation.snapshot = snapshot
            presentation.characterUUID = snapshot.characterUUID
                or ClientState.playerContext
                    and ClientState.playerContext.characterUUID
            presentation.knowledgeRevision = tonumber(snapshot.revision) or 0
            ClientState.npcPresentations[npcID] = presentation
        end
    end
    ClientState.npcKnowledgeReason = reason
    ClientState.lastNPCKnowledgeReceiveAt = Core.Now()
    if PNC.NPCDossierUI and PNC.NPCDossierUI.ReceiveSnapshot then
        PNC.NPCDossierUI.ReceiveSnapshot(snapshot)
    end
    if PNC.Conversation and PNC.Conversation.ReceiveKnowledgeSnapshot then
        PNC.Conversation.ReceiveKnowledgeSnapshot(snapshot)
    end
    return type(snapshot) == "table" and snapshot.npcID ~= nil
end

Internal.RegisterServerCommand(Const.CMD_NPC_KNOWLEDGE, function(args)
    Internal.ApplyNPCKnowledgeSnapshot(args.snapshot, args.reason)
end)

function Internal.ApplyWorldDiscoverySnapshot(payload)
    if type(payload) ~= "table" then return false end
    local current = ClientState.worldDiscovery
    if current and current.characterUUID and payload.characterUUID
        and tostring(current.characterUUID)
            ~= tostring(payload.characterUUID)
    then
        current = nil
    end
    if current and tonumber(payload.revision)
        < (tonumber(current.revision) or 0)
    then return false end
    ClientState.worldDiscovery = payload
    ClientState.lastWorldDiscoveryReceiveAt = Core.Now()
    local contactsUI = PNC.ContactsUI or PNC.WorldDiscoveryUI
    if contactsUI and contactsUI.ReceiveSnapshot then
        contactsUI.ReceiveSnapshot(payload)
    end
    if PNC.RadioDiscoveryPresentation
        and PNC.RadioDiscoveryPresentation.ShowResult
    then
        PNC.RadioDiscoveryPresentation.ShowResult(payload)
    end
    return true
end

Internal.RegisterServerCommand(
    Const.CMD_WORLD_DISCOVERY_STATE,
    Internal.ApplyWorldDiscoverySnapshot
)

local function projectionIsCurrent(payload)
    local context = ClientState.playerContext
    if not context or not payload then return true end
    if payload.characterUUID
        and payload.characterUUID ~= context.characterUUID
    then return false end
    if payload.bindingRevision
        and tonumber(payload.bindingRevision)
            < tonumber(context.bindingRevision or 0)
    then return false end
    return true
end

function Internal.ApplyNPCPresentation(payload)
    if type(payload) ~= "table" or not payload.npcID
        or not projectionIsCurrent(payload)
    then return false end
    local npcID = tostring(payload.npcID)
    ClientState.npcPresentations = ClientState.npcPresentations or {}
    local current = ClientState.npcPresentations[npcID]
    if current and tonumber(payload.knowledgeRevision)
        and tonumber(payload.knowledgeRevision)
            < (tonumber(current.knowledgeRevision) or 0)
    then return false end
    ClientState.npcPresentations[npcID] = payload
    if payload.snapshot then
        Internal.ApplyNPCKnowledgeSnapshot(payload.snapshot, payload.reason)
    end
    if PNC.Conversation and PNC.Conversation.ReceiveIdentityPresentation then
        PNC.Conversation.ReceiveIdentityPresentation(payload)
    end
    return true
end

Internal.RegisterServerCommand(Const.CMD_PLAYER_BOOTSTRAP, function(args)
    if ClientState.activeBootstrapRequestID and args.requestID
        and args.requestID ~= ClientState.activeBootstrapRequestID
    then return end
    local currentRevision = tonumber(ClientState.bootstrapKnowledgeRevision) or -1
    local incomingRevision = tonumber(args.knowledgeRevision) or 0
    if incomingRevision < currentRevision then return end
    local previousCharacterUUID = ClientState.playerContext
        and ClientState.playerContext.characterUUID or nil
    ClientState.bootstrapState = args.state or "error"
    ClientState.bootstrapReason = args.reason
    if args.context then ClientState.playerContext = args.context end
    local incomingCharacterUUID = ClientState.playerContext
        and ClientState.playerContext.characterUUID or nil
    local characterChanged = previousCharacterUUID ~= nil
        and tostring(previousCharacterUUID)
            ~= tostring(incomingCharacterUUID or "")
    if tonumber(args.chunkIndex) == 1 and projectionIsCurrent(args)
        and (args.scope ~= "live"
            and args.scope ~= "interest" or characterChanged)
    then
        ClientState.npcKnowledge = {}
        ClientState.npcPresentations = {}
        ClientState.conversationHistory = {}
        ClientState.conversationDiary = {}
        ClientState.conversationDiaryRevision = 0
        ClientState.lastConversationDelta = nil
        ClientState.bootstrapKnowledgeRevision = incomingRevision
    end
    if projectionIsCurrent(args) then
        for _, snapshot in ipairs(args.snapshots or {}) do
            Internal.ApplyNPCKnowledgeSnapshot(snapshot)
        end
    end
    if args.state == "known" then
        ClientState.bootstrapRetryAttempt = 0
    end
end)

Internal.RegisterServerCommand(Const.CMD_NPC_PRESENTATION, function(args)
    Internal.ApplyNPCPresentation(args)
end)

Internal.RegisterServerCommand(Const.CMD_KNOWLEDGE_DISCLOSURE, function(args)
    local npcID = args.npcID and tostring(args.npcID) or nil
    local pending = npcID and ClientState.pendingDisclosure
        and ClientState.pendingDisclosure[npcID] or nil
    if pending and args.requestID and pending ~= args.requestID then return end
    if pending and npcID then ClientState.pendingDisclosure[npcID] = nil end
    if args.success and args.presentation then
        Internal.ApplyNPCPresentation(args.presentation)
    elseif args.npcID then
        Internal.ApplyNPCPresentation(args.presentation or {
            npcID = args.npcID, state = "error", reason = args.reason,
        })
    end
    if PNC.Conversation and PNC.Conversation.ReceiveDisclosureResult then
        PNC.Conversation.ReceiveDisclosureResult(args)
    end
end)

Internal.RegisterServerCommand(Const.CMD_KNOWLEDGE_DEBUG, function(args)
    ClientState.knowledgeDebugAuthorized = args.authorized == true
    ClientState.knowledgeDebug = args.snapshot
    ClientState.knowledgeDebugReason = args.reason
    ClientState.lastKnowledgeDebugReceiveAt = Core.Now()
    if PNC.KnowledgeDebugUI and PNC.KnowledgeDebugUI.ReceiveSnapshot then
        PNC.KnowledgeDebugUI.ReceiveSnapshot(args.snapshot)
    end
    if PNC.NPCDossierUI and PNC.NPCDossierUI.ReceiveDebugSnapshot then
        PNC.NPCDossierUI.ReceiveDebugSnapshot(args.snapshot)
    end
end)

Internal.RegisterServerCommand(
    Const.CMD_FACTION_DEBUG,
    function(args)
        ClientState.factionDebugAuthorized =
            args.authorized == true
        ClientState.factionDebug = args.snapshot
        ClientState.factionDebugReason = args.reason
        ClientState.lastFactionDebugReceiveAt = Core.Now()
    end
)

Internal.RegisterServerCommand(
    Const.CMD_FACTION_MEMBERS,
    function(args)
        ClientState.factionMembers = args.snapshot
        ClientState.factionMembersReason = args.reason
        ClientState.lastFactionMembersReceiveAt = Core.Now()
    end
)

Internal.RegisterServerCommand(
    Const.CMD_COMMUNITY_DEBUG,
    function(args)
        ClientState.communityDebugAuthorized =
            args.authorized == true
        ClientState.communityDebug = args.snapshot
        ClientState.communityDebugReason = args.reason
        ClientState.lastCommunityDebugReceiveAt = Core.Now()
    end
)

Internal.RegisterServerCommand(Const.CMD_NEEDS_DEBUG, function(args)
    ClientState.needsDebugAuthorized = args.authorized == true
    ClientState.needsDebug = args.snapshot
    ClientState.needsDebugReason = args.reason
    ClientState.lastNeedsDebugReceiveAt = Core.Now()
end)
Internal.RegisterServerCommand(Const.CMD_DIRECTOR_DEBUG, function(args)
    ClientState.directorDebugAuthorized = args.authorized == true
    ClientState.directorDebug = args.snapshot
    ClientState.directorDebugReason = args.reason
    ClientState.lastDirectorDebugReceiveAt = Core.Now()
end)
Internal.RegisterServerCommand(Const.CMD_COLONY_MANAGEMENT, function(args)
    ClientState.colonyManagement = args.snapshot
    ClientState.lastColonyManagementReceiveAt = Core.Now()
    if PNC.ColonyNamePrompt and PNC.ColonyNamePrompt.OpenIfNeeded then
        PNC.ColonyNamePrompt.OpenIfNeeded(args.snapshot)
    end
end)

Internal.RegisterServerCommand(Const.CMD_MAP_COMMAND_RESULT, function(args)
    if PNC.MapCommands and PNC.MapCommands.HandleResult then
        PNC.MapCommands.HandleResult(args)
    end
end)

Internal.RegisterServerCommand(Const.CMD_FACTION_TOLL, function(args)
    if not PNC.FactionTollUI then
        require "PNC/UI/Factions/PNC_FactionTollWindow"
    end
    if PNC.FactionTollUI
        and PNC.FactionTollUI.HandleServerMessage
    then
        PNC.FactionTollUI.HandleServerMessage(args or {})
    end
end)

Internal.RegisterServerCommand(
    Const.CMD_CONVERSATION_CEASEFIRE_RESULT,
    function(args)
        if PNC.Conversation
            and PNC.Conversation.HandleCeasefireResult
        then
            PNC.Conversation.HandleCeasefireResult(args or {})
        end
    end
)

Internal.RegisterServerCommand(Const.CMD_CONVERSATION_BLOCK, function(args)
    if PNC.Conversation and PNC.Conversation.Composer then
        PNC.Conversation.Composer.ReceiveBlock(args or {})
    end
end)

Internal.RegisterServerCommand(Const.CMD_CONVERSATION_OUTCOME, function(args)
    if PNC.Conversation and PNC.Conversation.Composer then
        PNC.Conversation.Composer.ReceiveOutcome(args or {})
    end
end)

Internal.RegisterServerCommand(Const.CMD_CONVERSATION_RECRUIT_RESULT, function(args)
    if PNC.Conversation and PNC.Conversation.Composer then
        PNC.Conversation.Composer.ReceiveRecruitOutcome(args or {})
    end
end)

function Client.HandleServerCommand(command, args)
    local handler
    ClientState.lastSyncReceiveAt = Core.Now()
    handler = Handlers[command]
    if handler then
        handler(args or {})
    end
end
