-- Client-side semantic gift result coordinator.

local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Internal = Composer.Internal
local ReceiveContext = Internal.GiftReceiveContext
local ReceivePresentation = Internal.GiftReceivePresentation

if not ReceiveContext or not ReceivePresentation then return Composer end

function Composer.ReceiveGiftResult(args)
    local state, reason, duplicate = ReceiveContext.Build(args)
    if duplicate then return true, reason end
    if not state then return false end

    local values = state.args
    if values.success ~= true then
        ReceiveContext.ClearConversationState(state, true)
        ReceivePresentation.AppendFailure(state)
        if PNC.Core and PNC.Core.LogWarn then
            PNC.Core.LogWarn("Conversation gift rejected npc="
                .. tostring(values.npcId or "unknown") .. " reason="
                .. tostring(values.reason or "unknown"))
        end
        return false, values.reason
    end

    ReceiveContext.ClearConversationState(state)
    ReceiveContext.RecordTransfer(state)
    local result = ReceivePresentation.BuildSuccess(state)
    ReceivePresentation.RefreshRelationship(state)
    ReceivePresentation.AppendSuccess(state, result)
    ReceivePresentation.RecordDiary(state, result)
    if PNC.Core and PNC.Core.LogInfo then
        PNC.Core.LogInfo("Conversation gift result npc="
            .. tostring(values.npcId or "unknown")
            .. " items=" .. tostring(#(values.itemTypes or {}))
            .. " reply=" .. tostring(result.giftReplyKey)
            .. " relationship_refresh="
            .. tostring(values.relationshipAfter ~= nil))
    end
    ReceivePresentation.Finish(state)
    return true
end

return Composer
