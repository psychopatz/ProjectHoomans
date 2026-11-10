-- Worker projection for the production NPC Knowledge commitment seam.

local Commitments = {}

local function knowledgeAPI()
    return PNC and PNC.NPCKnowledgeAPI or nil
end

local function knowledgeService()
    return PNC and PNC.NPCKnowledge or nil
end

function Commitments.record(context, payload)
    local API = knowledgeAPI()
    if not API or type(API.RecordConversationCommitmentForPlayer)
        ~= "function"
    then
        return nil, "commitment_api_unavailable"
    end
    payload = type(payload) == "table" and context.Values.copy(payload) or {}
    payload.origin = payload.origin or "semantic_dialogue"
    payload.conversationToken = payload.conversationToken
        or context.scenario.conversation.token
    local result, reason = API.RecordConversationCommitmentForPlayer(
        context.player, payload.npcID, payload
    )
    if not result then return nil, reason end
    return {
        ok = true,
        type = "conversation_commitment",
        owner = "PNC.NPCKnowledge",
        result = result,
        persistenceCommits = context.Values.copy(
            context.Runtime.persistenceCommits or {}
        ),
    }
end

function Commitments.list(context, payload)
    local API = knowledgeAPI()
    payload = type(payload) == "table" and payload or {}
    if not API or type(API.GetConversationCommitmentsForPlayer)
        ~= "function"
    then
        return nil, "commitment_api_unavailable"
    end
    local result, reason = API.GetConversationCommitmentsForPlayer(
        context.player, payload.npcID, payload.limit
    )
    if not result then return nil, reason end
    return {
        ok = true,
        type = "conversation_commitments",
        owner = "PNC.NPCKnowledge",
        commitments = result,
    }
end

function Commitments.saveReload(context, payload)
    local service = knowledgeService()
    payload = type(payload) == "table" and payload or {}
    if not service or type(service.Save) ~= "function"
        or type(service.Load) ~= "function"
    then
        return nil, "commitment_service_unavailable"
    end
    local saved, saveReason = service.Save(false)
    if saved == false and saveReason ~= "not_dirty" then
        return nil, saveReason or "commitment_save_failed"
    end
    -- This is the same service reload boundary used by the server module;
    -- only the worker's in-memory reference is discarded for the fixture.
    service.Registry = nil
    service.Loaded = false
    service.Dirty = false
    service.Load()
    return Commitments.list(context, payload)
end

function Commitments.dispatch(context, payload)
    payload = type(payload) == "table" and payload or {}
    local operation = tostring(payload.operation or "record")
    if operation == "record" then return Commitments.record(context, payload) end
    if operation == "list" then return Commitments.list(context, payload) end
    if operation == "save_reload" then
        return Commitments.saveReload(context, payload)
    end
    return nil, "unknown_commitment_operation"
end

return Commitments
