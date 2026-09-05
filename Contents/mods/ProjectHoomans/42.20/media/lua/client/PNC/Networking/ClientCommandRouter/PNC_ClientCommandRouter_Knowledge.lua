local Internal = PNC.Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

local function clearPendingBootstrap()
    ClientState.pendingBootstrap = nil
end

local function rejectBootstrapStream(reason)
    clearPendingBootstrap()
    ClientState.bootstrapState = "error"
    ClientState.bootstrapReason = reason or "invalid_bootstrap_stream"
end

local function isStaleKnowledge(current, incoming)
    local currentRevision
    local incomingRevision
    if type(current) ~= "table" or type(incoming) ~= "table" then
        return false
    end
    currentRevision = tonumber(current.revision)
    incomingRevision = tonumber(incoming.revision)
    return currentRevision ~= nil and incomingRevision ~= nil
        and incomingRevision <= currentRevision
end

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
        if isStaleKnowledge(previous, snapshot) then
            return false
        end
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
    if payload.snapshot then
        if not Internal.ApplyNPCKnowledgeSnapshot(
            payload.snapshot,
            payload.reason
        ) then
            return false
        end
    end
    ClientState.npcPresentations[npcID] = payload
    if PNC.Conversation and PNC.Conversation.ReceiveIdentityPresentation then
        PNC.Conversation.ReceiveIdentityPresentation(payload)
    end
    return true
end

Internal.RegisterServerCommand(Const.CMD_NPC_KNOWLEDGE, function(args)
    Internal.ApplyNPCKnowledgeSnapshot(args.snapshot, args.reason)
end)

Internal.RegisterServerCommand(Const.CMD_PLAYER_BOOTSTRAP, function(args)
    local streamID
    local chunkIndex
    local chunkCount
    local incomingRevision
    local pending
    local snapshot
    local snapshotID
    local i
    local previousCharacterUUID
    local incomingCharacterUUID
    local characterChanged
    local scope
    if ClientState.activeBootstrapRequestID and args.requestID
        and args.requestID ~= ClientState.activeBootstrapRequestID
    then return end
    local currentRevision = tonumber(ClientState.bootstrapKnowledgeRevision) or -1
    incomingRevision = tonumber(args.knowledgeRevision) or 0
    if incomingRevision < currentRevision then return end
    if args.state == "error" then
        rejectBootstrapStream(args.reason or "bootstrap_failed")
        return
    end
    streamID = args.requestID and tostring(args.requestID) or "legacy"
    if ClientState.completedBootstrapRequestID
        and ClientState.completedBootstrapRequestID == streamID
    then
        return
    end
    chunkIndex = tonumber(args.chunkIndex) or 1
    chunkCount = tonumber(args.chunkCount) or 1
    if chunkCount < 1 or chunkCount ~= math.floor(chunkCount)
        or chunkIndex < 1 or chunkIndex > chunkCount
        or chunkIndex ~= math.floor(chunkIndex)
        or type(args.snapshots) ~= "table"
    then
        rejectBootstrapStream("invalid_bootstrap_chunk")
        return
    end
    scope = args.scope or "all"
    previousCharacterUUID = ClientState.playerContext
        and ClientState.playerContext.characterUUID or nil
    if args.context then ClientState.playerContext = args.context end
    incomingCharacterUUID = ClientState.playerContext
        and ClientState.playerContext.characterUUID or nil
    characterChanged = previousCharacterUUID ~= nil
        and tostring(previousCharacterUUID)
            ~= tostring(incomingCharacterUUID or "")
    if not projectionIsCurrent(args) then
        return
    end
    pending = ClientState.pendingBootstrap
    if pending and (
        pending.requestID ~= streamID
            or pending.chunkCount ~= chunkCount
            or pending.knowledgeRevision ~= incomingRevision
            or pending.scope ~= scope
    ) then
        if chunkIndex == 1 then
            clearPendingBootstrap()
            pending = nil
        else
            return
        end
    end
    if not pending then
        pending = {
            requestID = streamID,
            chunkCount = chunkCount,
            knowledgeRevision = incomingRevision,
            scope = scope,
            chunks = {},
            chunkStates = {},
            snapshotsByID = {},
            seenNPCIDs = {},
            receivedChunks = 0,
            characterChanged = characterChanged,
            replace = scope ~= "live" and scope ~= "interest"
                or characterChanged,
        }
        ClientState.pendingBootstrap = pending
    end
    if pending.chunks[chunkIndex] ~= nil then
        return
    end
    if args.state and args.state ~= "loading"
        and args.state ~= "known"
    then
        rejectBootstrapStream("invalid_bootstrap_state")
        return
    end
    if args.state == "known" and chunkIndex ~= chunkCount then
        rejectBootstrapStream("early_bootstrap_completion")
        return
    end
    if args.state == "loading" and chunkIndex == chunkCount then
        rejectBootstrapStream("incomplete_bootstrap_completion")
        return
    end
    for i = 1, #args.snapshots do
        snapshot = args.snapshots[i]
        snapshotID = snapshot and snapshot.npcID
            and tostring(snapshot.npcID) or nil
        if not snapshotID or pending.seenNPCIDs[snapshotID] then
            rejectBootstrapStream("duplicate_bootstrap_snapshot")
            return
        end
        pending.seenNPCIDs[snapshotID] = true
        pending.snapshotsByID[snapshotID] = snapshot
    end
    pending.chunks[chunkIndex] = args.snapshots
    pending.chunkStates[chunkIndex] = args.state
    pending.receivedChunks = pending.receivedChunks + 1
    ClientState.bootstrapState = "loading"
    ClientState.bootstrapReason = args.reason
    if pending.receivedChunks < pending.chunkCount then
        return
    end
    for i = 1, pending.chunkCount do
        if pending.chunks[i] == nil then
            return
        end
    end
    if pending.replace then
        local previousKnowledge = ClientState.npcKnowledge or {}
        local previousPresentations = ClientState.npcPresentations or {}
        local protectedKnowledge = {}
        local protectedPresentations = {}
        if not pending.characterChanged then
            for snapshotID, previous in pairs(previousKnowledge) do
                snapshot = pending.snapshotsByID[snapshotID]
                if snapshot and isStaleKnowledge(snapshot and previous, snapshot) then
                    protectedKnowledge[snapshotID] = previous
                    if previousPresentations[snapshotID] then
                        protectedPresentations[snapshotID] = previousPresentations[snapshotID]
                    end
                end
            end
        end
        ClientState.npcKnowledge = protectedKnowledge
        ClientState.npcPresentations = protectedPresentations
        ClientState.conversationHistory = {}
        ClientState.conversationDiary = {}
        ClientState.conversationDiaryRevision = 0
        ClientState.lastConversationDelta = nil
        ClientState.lastConversationDeltas = {}
    end
    for i = 1, pending.chunkCount do
        for _, snapshot in ipairs(pending.chunks[i]) do
            Internal.ApplyNPCKnowledgeSnapshot(snapshot)
        end
    end
    ClientState.bootstrapKnowledgeRevision = incomingRevision
    ClientState.bootstrapState = "known"
    ClientState.bootstrapRetryAttempt = 0
    ClientState.completedBootstrapRequestID = streamID
    clearPendingBootstrap()
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
