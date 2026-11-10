-- Client knowledge and identity projection state.

local Internal = PNC.Client.Internal
local Core = PNC.Core
local ClientState = PNC.Network.ClientState
local Memory = Internal.KnowledgeMemory
local State = Internal.KnowledgeState or {}
Internal.KnowledgeState = State

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
            if (descriptor.descriptorID == "identity.name"
                or descriptor.descriptorID == "identity.full_name"
                or descriptor.descriptorID == "identity.nickname"
                or descriptor.descriptorID == "identity.forename")
                and descriptor.value ~= nil
            then
                return descriptor
            end
        end
    end
    return nil
end

local function identityDisplayName(snapshot)
    local identity = snapshot and snapshot.identity or {}
    local fullName = identity and identity.displayName
    local nickname = identity and identity.nickname
    local fact = identityNameFact(snapshot)
    if fullName and tostring(fullName) ~= ""
        and nickname and tostring(nickname) ~= ""
    then
        return tostring(fullName) .. " (" .. tostring(nickname) .. ")"
    end
    return fullName and tostring(fullName)
        or nickname and tostring(nickname)
        or fact and tostring(fact.value or "")
        or nil
end

local function projectionIsCurrent(payload)
    local context = ClientState.playerContext
    if not context or not payload then return true end
    if payload.characterUUID
        and payload.characterUUID ~= context.characterUUID
    then
        return false
    end
    if payload.bindingRevision
        and tonumber(payload.bindingRevision)
            < tonumber(context.bindingRevision or 0)
    then
        return false
    end
    return true
end

local function auditIdentityKnowledgeMirror(npcID, snapshot)
    local pending = ClientState.identityDisclosurePending
        and ClientState.identityDisclosurePending[npcID] or nil
    if not pending then return false end
    ClientState.identityDisclosurePending[npcID] = nil
    local at = Core.Now and Core.Now() or 0
    local elapsed = at - (tonumber(pending.at) or at)
    if PNC.Semantics and PNC.Semantics.SemanticDiagnostics
        and type(PNC.Semantics.SemanticDiagnostics.Record) == "function"
    then
        PNC.Semantics.SemanticDiagnostics.Record(
            "semantic.knowledge.identity_mirrored",
            {
                requestID = pending.requestID,
                npcID = npcID,
                disclosedName = pending.name,
                mirroredName = tostring(
                    (snapshot and snapshot.identity
                        and snapshot.identity.displayName) or ""
                ),
                elapsedMs = elapsed,
            },
            { requestID = pending.requestID }
        )
    end
    return true
end

State.IsStaleKnowledge = isStaleKnowledge
State.ProjectionIsCurrent = projectionIsCurrent

-- Multiplayer replies and direct in-process calls share this cache receiver.
function Internal.ApplyNPCKnowledgeSnapshot(snapshot, reason)
    Memory.QueueSnapshotMemoryPrimitives(snapshot)
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
        local displayName = identityDisplayName(snapshot)
        if nameFact and displayName then
            local fullNameKnown = snapshot.identity
                and snapshot.identity.displayName ~= nil
            auditIdentityKnowledgeMirror(npcID, snapshot)
            ClientState.npcPresentations = ClientState.npcPresentations or {}
            local presentation = ClientState.npcPresentations[npcID] or {}
            presentation.npcID = npcID
            presentation.state = "known"
            presentation.identityLevel = fullNameKnown
                and "full_name" or "nickname"
            presentation.canAskName = not fullNameKnown
            presentation.displayName = displayName
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

-- Public lifecycle/delivery contract; the owner retains its internal reference.
PNC.Client.ApplyNPCKnowledgeSnapshot = Internal.ApplyNPCKnowledgeSnapshot

return State
