-- Client presentation projection state for knowledge results.

local Internal = PNC.Client.Internal
local Core = PNC.Core
local ClientState = PNC.Network.ClientState
local KnowledgeState = Internal.KnowledgeState

function Internal.ApplyNPCPresentation(payload)
    if type(payload) ~= "table" or not payload.npcID
        or not KnowledgeState.ProjectionIsCurrent(payload)
    then
        return false
    end
    local npcID = tostring(payload.npcID)
    ClientState.npcPresentations = ClientState.npcPresentations or {}
    local current = ClientState.npcPresentations[npcID]
    if current and tonumber(payload.knowledgeRevision)
        and tonumber(payload.knowledgeRevision)
            < (tonumber(current.knowledgeRevision) or 0)
    then
        return false
    end
    -- A generic presentation can arrive after a known-at-creation snapshot
    -- during spawn/roster synchronization. It has no identity authority and
    -- must not regress a companion to loading/stranger.
    if current and current.state == "known"
        and payload.snapshot == nil
        and payload.knowledgeRevision == nil
    then
        local preserved = Core.DeepCopy and Core.DeepCopy(current) or {}
        if not Core.DeepCopy then
            for key, value in pairs(current) do
                preserved[key] = value
            end
        end
        for key, value in pairs(payload) do
            if key ~= "state" and key ~= "displayName"
                and key ~= "canAskName" and key ~= "snapshot"
                and key ~= "knowledgeRevision"
            then
                preserved[key] = value
            end
        end
        preserved.npcID = npcID
        preserved.state = "known"
        preserved.canAskName = false
        preserved.displayName = current.displayName
        preserved.snapshot = current.snapshot
        preserved.knowledgeRevision = current.knowledgeRevision
        ClientState.npcPresentations[npcID] = preserved
        if PNC.Conversation
            and PNC.Conversation.ReceiveIdentityPresentation
        then
            PNC.Conversation.ReceiveIdentityPresentation(preserved)
        end
        return true
    end
    if payload.snapshot then
        if not Internal.ApplyNPCKnowledgeSnapshot(
            payload.snapshot,
            payload.reason
        ) then
            return false
        end
    end
    -- `state` is the player-facing identity projection. Loading and error
    -- belong to the request lifecycle; neither should collapse the social
    -- conversation into a disabled placeholder menu.
    if payload.state == "loading" or payload.state == "error" then
        local normalized = Core.DeepCopy and Core.DeepCopy(payload) or {}
        if not Core.DeepCopy then
            for key, value in pairs(payload) do normalized[key] = value end
        end
        normalized.state = "unknown"
        normalized.requestState = payload.state
        normalized.knowledgePending = payload.state == "loading"
        if normalized.canAskName == nil then
            normalized.canAskName = payload.state == "loading"
        end
        payload = normalized
    else
        payload.requestState = nil
        payload.knowledgePending = false
    end
    ClientState.npcPresentations[npcID] = payload
    if PNC.Conversation and PNC.Conversation.ReceiveIdentityPresentation then
        PNC.Conversation.ReceiveIdentityPresentation(payload)
    end
    return true
end

return Internal
