local Internal = PNC.Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

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

-- Multiplayer replies and direct in-process calls share this cache receiver.
function Internal.ApplyNPCKnowledgeSnapshot(snapshot, reason)
    if type(snapshot) == "table" and snapshot.npcID then
        local npcID = tostring(snapshot.npcID)
        ClientState.npcKnowledge = ClientState.npcKnowledge or {}
        local previous = ClientState.npcKnowledge[npcID]
        ClientState.npcKnowledge[npcID] = snapshot
        if PNC.KnowledgePresentation
            and PNC.KnowledgePresentation.ShowLearnedFacts
        then
            PNC.KnowledgePresentation.ShowLearnedFacts(previous, snapshot)
        end
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

Internal.RegisterServerCommand(Const.CMD_NPC_KNOWLEDGE, function(args)
    Internal.ApplyNPCKnowledgeSnapshot(args.snapshot, args.reason)
end)

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
        ClientState.lastConversationDeltas = {}
        ClientState.bootstrapKnowledgeRevision = incomingRevision
    end
    if projectionIsCurrent(args) then
        for _, snapshot in ipairs(args.snapshots or {}) do
            Internal.ApplyNPCKnowledgeSnapshot(snapshot)
        end
    end
    if args.state == "known" then ClientState.bootstrapRetryAttempt = 0 end
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

return PNC.Client
