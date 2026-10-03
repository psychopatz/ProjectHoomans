-- Client application of authoritative conversation relationship results.

local Internal = PNC.Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

Internal.RegisterServerCommand(Const.CMD_CONVERSATION_RELATIONSHIP,
    function(args)
        args = type(args) == "table" and args or {}
        local summary = args.summary
        local npcID
        local delta
        local before
        local after
        local source
        local hasChangeMetadata
        if type(summary) ~= "table" or not summary.npcID then return end
        npcID = tostring(summary.npcID)
        delta = args.relationshipDelta or args.delta
        before = args.relationshipBefore or args.before
        after = args.relationshipAfter or args.after or summary
        hasChangeMetadata = delta ~= nil
            or before ~= nil
            or args.source ~= nil
            or args.eventID ~= nil
        ClientState.conversationRelationships =
            ClientState.conversationRelationships or {}
        ClientState.conversationRelationships[npcID] = summary
        ClientState.lastConversationRelationshipReceiveAt = Core.Now()
        source = args.source or "relationship_network"
        local relationship = PNC.Conversation and PNC.Conversation.Relationship
        if relationship and relationship.ReceivePresentation then
            relationship.ReceivePresentation(
                summary,
                delta,
                {
                    source = source,
                    eventID = args.eventID,
                    revision = args.revision or summary.revision,
                }
            )
        end
        local flavorPresentation = PNC.SocialFlavorPresentation
        if args.ambientFlavor and not flavorPresentation then
            pcall(require, "PNC/Conversation/PNC_SocialFlavorPresentation")
            flavorPresentation = PNC.SocialFlavorPresentation
        end
        if args.ambientFlavor and flavorPresentation
            and flavorPresentation.Receive
        then
            flavorPresentation.Receive(args.ambientFlavor, summary, args)
        end
        if hasChangeMetadata then
            ClientState.lastConversationDelta = {
                npcID = npcID,
                source = source,
                delta = delta,
                before = before,
                after = after,
                effects = {
                    eventID = args.eventID,
                },
                at = Core.Now(),
            }
            ClientState.lastConversationDeltas =
                ClientState.lastConversationDeltas or {}
            ClientState.lastConversationDeltas[npcID] =
                ClientState.lastConversationDelta
        end
    end)

return Internal
