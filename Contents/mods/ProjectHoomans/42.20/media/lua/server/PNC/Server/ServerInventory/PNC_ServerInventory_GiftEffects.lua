if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ServerInventory = PNC.ServerInventory or {}
PNC.ServerInventory.Internal = PNC.ServerInventory.Internal or {}

local Service = PNC.ServerInventory
local Internal = Service.Internal
local Registry = PNC.Registry
local relationshipSnapshot = Internal.relationshipSnapshot

PNC.Gifts = PNC.Gifts or {}
local giftEffect = PNC.Gifts.EvaluateEffect

local function applyGiftEffect(player, record, args, details)
    local gift = giftEffect(details and details.itemTypes or {})
    details = details or {}
    -- The acknowledgement is part of the conversation contract even if
    -- the relationship service is temporarily unavailable. The transfer
    -- remains authoritative; in that degraded case the axes simply do
    -- not change and the client still receives an honest flavour reply.
    details.giftEffect = gift
    details.giftReplyKey = "gift.received."
        .. tostring(gift and gift.kind or "general")
    local playerKey = PNC.PlayerCharacters
        and PNC.PlayerCharacters.GetEntityKey
        and PNC.PlayerCharacters.GetEntityKey(player, {
            callback = "conversation_gift",
            worldAgeHours = getGameTime and getGameTime()
                and getGameTime():getWorldAgeHours() or 0,
        }) or nil
    local applied
    local applyReason
    local result
    local relationshipBefore = PNC.Relationships
        and PNC.Relationships.Get
        and relationshipSnapshot(PNC.Relationships.Get(record.id, playerKey))
        or relationshipSnapshot(nil)
    if playerKey and PNC.Relationships
        and PNC.Relationships.ApplyConversationEffect
    then
        applied, applyReason, result = PNC.Relationships.ApplyConversationEffect(
            record.id,
            playerKey,
            gift,
            {
                blockID = "projecthoomans:needs_gift",
                choiceID = "gift",
                outcomeID = args.requestId or details and details.itemTypes
                    and details.itemTypes[1] or "gift",
                worldAgeHours = getGameTime and getGameTime()
                    and getGameTime():getWorldAgeHours() or 0,
            }
        )
    end
    if applied == true and result and result.relationship then
        local relationshipAfter = relationshipSnapshot(result.relationship)
        details.relationshipBefore = relationshipBefore
        details.relationshipAfter = relationshipAfter
        details.relationshipDelta = {
            approval = relationshipAfter.approval - relationshipBefore.approval,
            respect = relationshipAfter.respect - relationshipBefore.respect,
            familiarity = relationshipAfter.familiarity - relationshipBefore.familiarity,
        }
    else
        details.giftEffectError = applyReason or "relationship_unavailable"
        details.relationshipBefore = relationshipBefore
        details.relationshipAfter = relationshipBefore
        details.relationshipDelta = {
            approval = 0,
            respect = 0,
            familiarity = 0,
        }
    end
    if Registry.Save then Registry.Save() end
    return details
end

Internal.applyGiftEffect = applyGiftEffect
