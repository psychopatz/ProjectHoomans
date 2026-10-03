-- Client-side group conversation fanout coordinator.

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
local Group = PNC.Conversation.Group
local Internal = Group.Internal or {}
local audit = Internal.Audit
local dispatch = Internal.FanoutMemberDispatch

if not audit or not dispatch then return Group end

function Group:Fanout(value, primaryResult)
    local input = self.dialogueInput
    local internal = input and input.Internal or nil
    local primary = self.primaryHost
    if not internal or not primary or not primaryResult
        or type(primaryResult.ir) ~= "table"
    then
        return 0, "group_fanout_unavailable"
    end

    local decision = primaryResult.decision or {}
    if decision.giftOffer then
        -- A spoken gift has one explicit recipient in the current slice. Do
        -- not duplicate the same item transfer for every nearby participant;
        -- multi-recipient gifting gets its own negotiation round later.
        audit(self, "semantic.group.gift_primary_only", {
            groupID = self.id,
            turnID = self.activeTurn and self.activeTurn.id,
            reason = "gift_recipient_selection_not_implemented",
        })
        return 0, "gift_primary_only"
    end
    if decision.giftConsent then
        audit(self, "semantic.group.gift_consent_primary_only", {
            groupID = self.id,
            turnID = self.activeTurn and self.activeTurn.id,
            recipientID = decision.giftConsent.recipientID,
            status = decision.giftConsent.status,
        })
        return 0, "gift_consent_primary_only"
    end
    if decision.route == "llm_fallback" then
        audit(self, "semantic.group.fallback", {
            groupID = self.id,
            turnID = self.activeTurn and self.activeTurn.id,
            reason = "llm_fallback",
        })
        return 1, "llm_fallback"
    end

    local primaryMember = self:MemberForHost(primary)
    local queued = primaryMember
        and self:ShouldRespond(primaryMember, primaryResult, value) and 1
        or 0
    for index = 1, #self.members do
        local member = self.members[index]
        local host = member.host
        if host ~= primary and self:ShouldRespond(member, primaryResult, value) then
            queued = queued + dispatch.Process(
                self, value, primaryResult, member)
        end
    end
    if self.activeTurn then self.activeTurn.responseCount = queued end
    return queued
end

return Group
