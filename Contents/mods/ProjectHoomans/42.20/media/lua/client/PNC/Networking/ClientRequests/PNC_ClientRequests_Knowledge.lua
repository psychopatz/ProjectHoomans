-- NPC presentation and player-knowledge request transport.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

function Client.RequestNPCKnowledge(npcID)
    npcID = tostring(npcID or "")
    if npcID == "" then return false, "invalid_npc_id" end
    local player = Internal.GetPlayer()
    ClientState.lastNPCKnowledgeRequestAt = Core.Now()
    ClientState.npcPresentations = ClientState.npcPresentations or {}
    local existing = ClientState.npcPresentations[npcID]
    local args = type(existing) == "table"
        and Core.DeepCopy(existing) or {
            npcID = npcID,
            state = "unknown",
            canAskName = true,
        }
    args.npcID = npcID
    args.requestID = Internal.RequestID("presentation")
    if args.state ~= "known" then
        args.state = "unknown"
        if args.canAskName == nil then args.canAskName = true end
    end
    args.requestState = "loading"
    args.knowledgePending = true
    ClientState.npcPresentations[npcID] = args
    return Internal.DispatchIdentity(player,
        Const.CMD_NPC_PRESENTATION_REQUEST,
        { npcID = npcID, requestID = args.requestID },
        "HandlePresentation")
end

-- Requests only the fact needed for a current conversation turn. This keeps
-- private NPC memory out of broad client snapshots and lets the local parser
-- remain responsive while a projection arrives for the next turn.
function Client.RequestKnownNPCKnowledge()
    return Client.RequestPlayerBootstrap()
end

function Client.RequestNPCKnowledgeTopic(npcID, topicID, options)
    npcID = tostring(npcID or "")
    topicID = tostring(topicID or "")
    if npcID == "" or topicID == "" then
        return false, "invalid_knowledge_topic"
    end
    local player = Internal.GetPlayer()
    options = type(options) == "table" and options or {}
    local args = {
        requestID = Internal.RequestID("disclosure"),
        npcID = npcID,
        topicID = topicID,
        conversationToken = options.conversationToken or options.token,
        origin = options.origin,
    }
    ClientState.pendingDisclosure = ClientState.pendingDisclosure or {}
    ClientState.pendingDisclosure[npcID] = args.requestID
    local accepted, reason = Internal.DispatchIdentity(player,
        Const.CMD_KNOWLEDGE_DISCLOSURE_REQUEST, args, "HandleDisclosure")
    if accepted ~= true then ClientState.pendingDisclosure[npcID] = nil end
    return accepted, reason, args.requestID
end

return Client
