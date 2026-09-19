-- Semantic identity exchange request transport.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Const = PNC.Const
local ClientState = PNC.Network.ClientState

function Client.SubmitSemanticIdentity(npcID, options)
    npcID = tostring(npcID or "")
    options = type(options) == "table" and options or {}
    if npcID == "" then return false, "invalid_npc_id" end
    local kind = tostring(options.kind or "")
    if kind ~= "identity_claim" and kind ~= "identity_evasion" then
        return false, "invalid_identity_event"
    end
    local args = {
        requestID = Internal.RequestID("identity_exchange"),
        npcID = npcID,
        kind = kind,
        claimedName = options.claimedName,
        conversationToken = options.conversationToken or options.token,
        origin = options.origin or "semantic_dialogue",
    }
    ClientState.pendingSemanticIdentity =
        ClientState.pendingSemanticIdentity or {}
    ClientState.pendingSemanticIdentity[npcID] = args.requestID
    local player = Internal.GetPlayer()
    local accepted, reason = Internal.DispatchIdentity(
        player,
        Const.CMD_SEMANTIC_IDENTITY_REQUEST,
        args,
        "HandleSemanticIdentity"
    )
    if accepted ~= true then
        ClientState.pendingSemanticIdentity[npcID] = nil
    end
    return accepted, reason, args.requestID
end

return Client
