-- Client presentation for authoritative identity-claim outcomes.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Internal = PNC.Client.Internal
local Const = PNC.Const
local ClientState = PNC.Network.ClientState

local function activeViewFor(npcID)
    local conversation = PsychopatzCore and PsychopatzCore.Conversation
    local view = conversation and conversation.instance or nil
    if not view or tostring(view.spec and view.spec.npcID or "")
        ~= tostring(npcID or "")
    then
        return nil
    end
    return view
end

Internal.RegisterServerCommand(Const.CMD_SEMANTIC_IDENTITY_RESULT,
    function(args)
        args = type(args) == "table" and args or {}
        local npcID = tostring(args.npcID or "")
        local pending = ClientState.pendingSemanticIdentity
            and ClientState.pendingSemanticIdentity[npcID]
        if pending and args.requestID and pending ~= args.requestID then return end
        if npcID ~= "" and ClientState.pendingSemanticIdentity then
            ClientState.pendingSemanticIdentity[npcID] = nil
        end

        ClientState.semanticIdentityResults =
            ClientState.semanticIdentityResults or {}
        ClientState.semanticIdentityResults[npcID] = args
        if args.trustLabel then
            ClientState.identityTrust = ClientState.identityTrust or {}
            ClientState.identityTrust[npcID] = args.trustLabel
        end

        if args.relationship then
            ClientState.conversationRelationships =
                ClientState.conversationRelationships or {}
            ClientState.conversationRelationships[npcID] = args.relationship
            local relationship = PNC.Conversation
                and PNC.Conversation.Relationship
            if relationship and relationship.ReceivePresentation then
                relationship.ReceivePresentation(
                    args.relationship,
                    args.accepted == true and args.relationshipDelta or nil,
                    {
                        source = "semantic_identity",
                        eventID = args.eventID,
                        revision = args.relationshipRevision
                            or args.relationship.revision,
                    }
                )
            end
        end

        local view = activeViewFor(npcID)
        if view and view.session and args.responseText then
            view.session:append("npc", {
                fallback = tostring(args.responseText),
            })
        end

    end)

return PNC.Client
