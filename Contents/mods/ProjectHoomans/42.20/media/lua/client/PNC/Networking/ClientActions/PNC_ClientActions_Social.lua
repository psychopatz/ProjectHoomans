-- Social reaction and vanilla-emote interaction transport.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Const = PNC.Const
local Core = PNC.Core
local Internal = Client.Internal

function Client.ExecuteLLMSocialReaction(npcID, kind, intensity, context)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local tools = PNC.ConversationLLMTools
    local reaction = tools and tools.NormalizeReaction
        and tools.NormalizeReaction(kind) or nil
    local normalizedIntensity = tools and tools.NormalizeIntensity
        and tools.NormalizeIntensity(intensity) or "normal"
    local subtype
    local args
    local result
    if not player or not reaction then
        return false, "invalid_social_reaction"
    end
    context = type(context) == "table" and context or {}
    subtype = tools and tools.NormalizeSubtypeForReaction
        and tools.NormalizeSubtypeForReaction(context.subtype, reaction) or nil
    args = {
        npcID = tostring(npcID or ""),
        token = tostring(context.token or ""),
        requestID = tostring(context.requestID or ""),
        callID = tostring(context.callID or ""),
        kind = reaction,
        intensity = normalizedIntensity,
        subtype = subtype,
    }
    if args.npcID == "" or args.requestID == "" or args.callID == "" then
        return false, "social_reaction_identity_missing"
    end
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then
            return false, "network_api_unavailable"
        end
        sendClientCommand(
            player,
            Const.MODULE,
            Const.CMD_LLM_SOCIAL_REACTION,
            args
        )
        Internal.TraceCompanionCommand("social_react", npcID, "conversation", context, {
            status = "network_queued",
            reaction = reaction,
            intensity = normalizedIntensity,
            callID = args.callID,
        })
        return true, "network_queued"
    end
    local authority = PNC.Conversation and PNC.Conversation.Authority
    if not authority or not authority.HandleLLMSocialReaction then
        return false, "social_reaction_authority_unavailable"
    end
    result = authority.HandleLLMSocialReaction(player, args)
    Internal.TraceCompanionCommand("social_react", npcID, "conversation", context, result)
    if type(result) == "table" then
        return result.accepted == true, result.reason, result
    end
    return result == true, result and "applied" or "rejected"
end

function Client.ExecutePlayerEmoteInteraction(emote, context)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local interactions = PNC.VanillaEmoteInteractions
    local definition = interactions and interactions.Get(emote) or nil
    local requestID
    local args
    local result
    local authority
    if not player or not definition then
        return false, "unsupported_emote"
    end
    context = type(context) == "table" and context or {}
    requestID = tostring(context.requestID or "")
    if requestID == "" then
        requestID = Core.GenerateID and Core.GenerateID("emote")
            or tostring(Core.Now())
    end
    args = {
        requestID = requestID,
        emote = definition.id,
    }
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then
            return false, "network_api_unavailable"
        end
        sendClientCommand(
            player,
            Const.MODULE,
            Const.CMD_PLAYER_EMOTE_INTERACTION,
            args
        )
        Internal.TraceCompanionCommand("vanilla_emote", definition.id, "social", {
            requestID = requestID,
            origin = context.origin or "vanilla_emote_radial",
        }, { status = "network_queued" })
        return true, "network_queued", args
    end
    authority = PNC.PlayerEmoteInteractionAuthority
    if not authority or not authority.Handle then
        return false, "emote_interaction_authority_unavailable"
    end
    result = authority.Handle(player, args)
    if PNC.CompanionCommandPresentation
        and PNC.CompanionCommandPresentation.HandlePlayerEmoteInteractionResult
    then
        PNC.CompanionCommandPresentation.HandlePlayerEmoteInteractionResult(
            result
        )
    end
    Internal.TraceCompanionCommand("vanilla_emote", definition.id, "social", {
        requestID = requestID,
        origin = context.origin or "vanilla_emote_radial",
    }, result)
    if type(result) == "table" then
        return result.accepted == true, result.reason, result
    end
    return result == true, result and "applied" or "rejected", result
end

return Client

