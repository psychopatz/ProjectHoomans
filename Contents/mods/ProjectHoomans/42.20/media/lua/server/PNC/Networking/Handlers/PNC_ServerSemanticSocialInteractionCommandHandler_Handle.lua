if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

if not PNC or not PNC.SemanticDialogueSocialAuthority
then return end

local Authority = PNC.SemanticDialogueSocialAuthority
local H = Authority.Internal and Authority.Internal.SemanticSocial
if not H then return Authority end

local Router = H.Router
local Const = H.Const
local Core = H.Core
local Registry = H.Registry
local PlayerCharacters = H.PlayerCharacters
local EntityRef = H.EntityRef
local Definitions = H.Definitions
local SocialEvents = H.SocialEvents
local Network = H.Network
local RelationshipPresentation = H.RelationshipPresentation
local EVENT_TYPE_BY_SPEECH_ACT = H.EVENT_TYPE_BY_SPEECH_ACT
local text = H.text
local worldAgeHours = H.worldAgeHours
local rejected = H.rejected
if not H.ApplySocialEvent then
    require "PNC/Networking/Handlers/PNC_ServerSemanticSocialInteractionCommandHandler_ApplySocialEvent"
end
local applySocialEvent = H.ApplySocialEvent

function Authority.Handle(player, args)
    args = type(args) == "table" and args or {}
    local requestID = text(args.requestID, 96)
    local npcID = text(args.npcID, 128)
    local speechAct = string.upper(text(args.speechAct, 32))
    local conversationID = text(args.conversationID, 96)
    local conversationToken = text(
        args.conversationToken or args.token,
        128
    )
    local eventType = EVENT_TYPE_BY_SPEECH_ACT[speechAct]
    local record
    local body
    local validateLease
    local valid
    local reason
    local at
    local actorKey
    local targetKey
    local definition

    if not Core or not Core.IsAuthority or Core.IsAuthority() ~= true then
        return rejected(requestID, npcID, speechAct, "not_authority")
    end
    if not player or player.isDead and player:isDead() then
        return rejected(requestID, npcID, speechAct, "player_unavailable")
    end
    if requestID == "" then
        return rejected(requestID, npcID, speechAct, "request_id_required")
    end
    if npcID == "" or conversationID == "" then
        return rejected(requestID, npcID, speechAct,
            "conversation_identity_required")
    end
    if not eventType then
        return rejected(requestID, npcID, speechAct,
            "unsupported_social_speech_act")
    end
    if not Registry or type(Registry.Get) ~= "function"
        or type(Registry.GetLiveZombie) ~= "function"
    then
        return rejected(requestID, npcID, speechAct,
            "npc_registry_unavailable")
    end
    record = Registry.Get(npcID)
    body = Registry.GetLiveZombie(npcID)
    if not record or record.alive == false or not body
        or body.isDead and body:isDead()
    then
        return rejected(requestID, npcID, speechAct, "npc_unavailable")
    end

    local conversationAuthority = PNC.Conversation
        and PNC.Conversation.Authority or nil
    local authorityInternal = conversationAuthority
        and conversationAuthority.Internal or nil
    validateLease = authorityInternal and authorityInternal.ValidateLease
    if type(validateLease) ~= "function" then
        return rejected(requestID, npcID, speechAct,
            "conversation_authority_unavailable")
    end
    valid, reason = validateLease(player, record, conversationToken)
    if valid ~= true then
        return rejected(requestID, npcID, speechAct,
            reason or "invalid_conversation")
    end

    if not PlayerCharacters or type(PlayerCharacters.GetEntityKey)
        ~= "function"
    then
        return rejected(requestID, npcID, speechAct,
            "player_identity_unavailable")
    end
    at = worldAgeHours()
    actorKey = PlayerCharacters.GetEntityKey(player, {
        callback = "semantic_dialogue_social",
        worldAgeHours = at,
    })
    targetKey = EntityRef and type(EntityRef.ForNPC) == "function"
        and EntityRef.ForNPC(npcID) or nil
    if not actorKey or not targetKey then
        return rejected(requestID, npcID, speechAct,
            "social_identity_unavailable")
    end
    definition = Definitions and Definitions[eventType] or nil
    if not definition
        or not definition.allowedSourceSystems
        or definition.allowedSourceSystems.semantic_dialogue ~= true
    then
        return rejected(requestID, npcID, speechAct,
            "social_event_definition_unavailable")
    end
    if not SocialEvents or type(SocialEvents.Emit) ~= "function" then
        return rejected(requestID, npcID, speechAct,
            "social_event_service_unavailable")
    end
    if type(applySocialEvent) ~= "function" then
        return rejected(requestID, npcID, speechAct,
            "social_event_processor_unavailable")
    end
    return applySocialEvent({
        player = player,
        npcID = npcID,
        requestID = requestID,
        speechAct = speechAct,
        conversationID = conversationID,
        actorKey = actorKey,
        targetKey = targetKey,
        eventType = eventType,
        occurredAt = at,
    })
end

return Authority
