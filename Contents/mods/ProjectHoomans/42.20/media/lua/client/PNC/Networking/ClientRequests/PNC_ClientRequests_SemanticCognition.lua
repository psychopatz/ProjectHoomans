-- Conversation-scoped cognition request transport.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

local function dispatchSemanticCognition(player, args)
    local service
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not player or not sendClientCommand then
            return false, "player_unavailable"
        end
        sendClientCommand(
            player,
            Const.MODULE,
            Const.CMD_SEMANTIC_COGNITION_REQUEST,
            args
        )
        return true, "sent"
    end
    service = PNC.Semantics and PNC.Semantics.CognitionService
    if not service or type(service.HandleRequest) ~= "function" then
        return false, "cognition_service_unavailable"
    end
    local accepted, reason = service.HandleRequest(player, args)
    return accepted == true, reason or "dispatched"
end

function Client.RequestSemanticCognition(npcID, options)
    local subject
    local targetID
    local token
    local key
    local nowAt
    local last
    local args
    local player
    local accepted
    local reason
    npcID = tostring(npcID or "")
    if npcID == "" then return false, "invalid_npc_id" end
    options = type(options) == "table" and options or {}
    subject = tostring(options.subject or "")
    if subject == "" then return false, "invalid_fact_subject" end
    targetID = options.targetID or options.target
    if type(targetID) == "table" then
        targetID = targetID.id or targetID.entityID or targetID.npcID
    end
    targetID = tostring(targetID or "")
    if targetID == "" then targetID = nil end
    token = tostring(options.conversationToken or options.token or "")
    if token == "" then return false, "conversation_token_required" end
    key = npcID .. ":" .. string.upper(subject) .. ":"
        .. tostring(targetID or "*")
    nowAt = Core.Now()
    last = ClientState.lastSemanticCognitionRequestAt
        and tonumber(ClientState.lastSemanticCognitionRequestAt[key]) or 0
    if last > 0 and nowAt - last < 1000 then
        return false, "throttled"
    end
    ClientState.lastSemanticCognitionRequestAt =
        ClientState.lastSemanticCognitionRequestAt or {}
    ClientState.lastSemanticCognitionRequestAt[key] = nowAt
    ClientState.pendingSemanticCognition =
        ClientState.pendingSemanticCognition or {}
    args = {
        requestID = Internal.RequestID("semantic_cognition"),
        npcID = npcID,
        subject = subject,
        targetID = targetID,
        conversationToken = token,
    }
    ClientState.pendingSemanticCognition[npcID] = args
    ClientState.semanticMemoryGossip =
        ClientState.semanticMemoryGossip or {}
    ClientState.semanticMemoryGossip[npcID] = nil
    player = Internal.GetPlayer()
    accepted, reason = dispatchSemanticCognition(player, args)
    if accepted ~= true then
        ClientState.pendingSemanticCognition[npcID] = nil
    end
    return accepted, reason, args.requestID
end

return Client
