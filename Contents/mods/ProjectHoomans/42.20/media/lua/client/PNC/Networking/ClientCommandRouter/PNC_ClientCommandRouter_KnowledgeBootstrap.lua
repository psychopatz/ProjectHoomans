-- Client bootstrap stream assembly for authoritative knowledge snapshots.

local Internal = PNC.Client.Internal
local ClientState = PNC.Network.ClientState

local function resolveBootstrapRequest(args, dependencies)
    local streamID
    local chunkIndex
    local chunkCount
    local incomingRevision
    local pending
    local previousCharacterUUID
    local incomingCharacterUUID
    local characterChanged
    local scope

    if ClientState.activeBootstrapRequestID and args.requestID
        and args.requestID ~= ClientState.activeBootstrapRequestID
    then
        return nil
    end
    local currentRevision = tonumber(ClientState.bootstrapKnowledgeRevision) or -1
    incomingRevision = tonumber(args.knowledgeRevision) or 0
    if incomingRevision < currentRevision then return nil end
    if args.state == "error" then
        dependencies.reject(args.reason or "bootstrap_failed")
        return nil
    end
    streamID = args.requestID and tostring(args.requestID) or "legacy"
    if ClientState.completedBootstrapRequestID
        and ClientState.completedBootstrapRequestID == streamID
    then
        return nil
    end
    chunkIndex = tonumber(args.chunkIndex) or 1
    chunkCount = tonumber(args.chunkCount) or 1
    if chunkCount < 1 or chunkCount ~= math.floor(chunkCount)
        or chunkIndex < 1 or chunkIndex > chunkCount
        or chunkIndex ~= math.floor(chunkIndex)
        or type(args.snapshots) ~= "table"
    then
        dependencies.reject("invalid_bootstrap_chunk")
        return nil
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
    if not dependencies.projectionIsCurrent(args) then
        return nil
    end
    pending = ClientState.pendingBootstrap
    if pending and (
        pending.requestID ~= streamID
            or pending.chunkCount ~= chunkCount
            or pending.knowledgeRevision ~= incomingRevision
            or pending.scope ~= scope
    ) then
        if chunkIndex == 1 then
            dependencies.clearPending()
            pending = nil
        else
            return nil
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

    return {
        pending = pending,
        streamID = streamID,
        incomingRevision = incomingRevision,
        chunkIndex = chunkIndex,
        chunkCount = chunkCount,
    }
end

local function appendBootstrapChunk(args, context, dependencies)
    local pending = context.pending
    local chunkIndex = context.chunkIndex
    local snapshot
    local snapshotID

    if pending.chunks[chunkIndex] ~= nil then
        return false
    end
    if args.state and args.state ~= "loading"
        and args.state ~= "known"
    then
        dependencies.reject("invalid_bootstrap_state")
        return false
    end
    if args.state == "known" and chunkIndex ~= context.chunkCount then
        dependencies.reject("early_bootstrap_completion")
        return false
    end
    if args.state == "loading" and chunkIndex == context.chunkCount then
        dependencies.reject("incomplete_bootstrap_completion")
        return false
    end
    for i = 1, #args.snapshots do
        snapshot = args.snapshots[i]
        snapshotID = snapshot and snapshot.npcID
            and tostring(snapshot.npcID) or nil
        if not snapshotID or pending.seenNPCIDs[snapshotID] then
            dependencies.reject("duplicate_bootstrap_snapshot")
            return false
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
        return false
    end
    for i = 1, pending.chunkCount do
        if pending.chunks[i] == nil then
            return false
        end
    end
    return true
end

local function completeBootstrap(context, dependencies)
    local pending = context.pending
    local snapshot

    if pending.replace then
        local previousKnowledge = ClientState.npcKnowledge or {}
        local previousPresentations = ClientState.npcPresentations or {}
        local protectedKnowledge = {}
        local protectedPresentations = {}
        if not pending.characterChanged then
            for snapshotID, previous in pairs(previousKnowledge) do
                snapshot = pending.snapshotsByID[snapshotID]
                if snapshot and dependencies.isStale(snapshot and previous, snapshot) then
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
    ClientState.bootstrapKnowledgeRevision = context.incomingRevision
    ClientState.bootstrapState = "known"
    ClientState.bootstrapRetryAttempt = 0
    ClientState.completedBootstrapRequestID = context.streamID
    dependencies.clearPending()
end

function Internal.HandlePlayerBootstrap(args, dependencies)
    local context = resolveBootstrapRequest(args, dependencies)
    if not context then return end
    if not appendBootstrapChunk(args, context, dependencies) then return end
    completeBootstrap(context, dependencies)
end

return Internal
