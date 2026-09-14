-- Authoritative handler for transient NPC presentation reactions.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
local Router = PNC.ServerCommandRouter
local Const = PNC.Const
local Registry = PNC.Registry
local Presentation = PNC.PresentationAnimations

local function text(value, maximum)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    if string.find(value, "%c") then return "" end
    return string.sub(value, 1, maximum or 128)
end

local function validateConversation(player, record, token)
    local authority = PNC.Conversation and PNC.Conversation.Authority
    local internal = authority and authority.Internal or nil
    if token == "" then return false, "conversation_token_required" end
    if not internal or not internal.ValidateLease then
        return false, "conversation_authority_unavailable"
    end
    return internal.ValidateLease(player, record, token)
end

local function handle(player, args)
    local npcID = text(args and (args.id or args.npcID))
    local animationID = text(args and (args.animationID or args.animation))
    local eventID = text(args and args.eventID)
    local token = text(args and args.token)
    local definition
    local record
    local body
    local valid
    local reason
    if npcID == "" then return false, "npc_id_required" end
    if eventID == "" then return false, "event_id_required" end
    definition = Presentation and Presentation.Get
        and Presentation.Get(animationID) or nil
    if not definition then return false, "animation_not_registered" end
    record = Registry and Registry.Get and Registry.Get(npcID) or nil
    body = Registry and Registry.GetLiveZombie
        and Registry.GetLiveZombie(npcID) or nil
    if not record or not body then return false, "npc_unavailable" end
    valid, reason = validateConversation(player, record, token)
    if valid ~= true then return false, reason end
    return Presentation.Request(
        record,
        body,
        definition.id,
        {
            eventID = eventID,
            reason = "conversation_delivery",
        }
    )
end

Router.Register(Const.CMD_NPC_PRESENTATION_ANIMATION, handle)

return handle
