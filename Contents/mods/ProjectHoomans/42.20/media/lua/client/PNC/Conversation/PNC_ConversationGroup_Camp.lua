local Group = PNC.Conversation.Group
local Internal = Group.Internal
local runtimeNow = Internal.RuntimeNow
local audit = Internal.Audit

local function cloneIR(value)
    local semantics = PsychopatzCore and PsychopatzCore.Semantics
    local ir = semantics and semantics.IR or nil
    if ir and type(ir.Clone) == "function" then return ir.Clone(value) end
    return value
end

local function actionName(result)
    local decision = result and result.decision or nil
    local ir = result and result.ir or nil
    local intent = decision and decision.actionIntent or nil
    return decision and decision.action
        or ir and ir.action
        or type(intent) == "table" and intent.action
        or ""
end

local function isBroadcastCamp(self, result, value)
    local addressed
    if string.upper(tostring(actionName(result))) ~= "CAMP" then
        return false
    end
    if type(self.AddressedIDs) ~= "function" then return true end
    local ok
    ok, addressed = pcall(self.AddressedIDs, self, result, value)
    if not ok or type(addressed) ~= "table" then return true end
    for _ in pairs(addressed) do return false end
    return true
end

-- CAMP is a group-wide world action, but its acknowledgement remains a
-- multi-speaker conversation. Reuse the primary semantic result and action
-- transport result; only enqueue the other speakers. This keeps one server
-- command and one semantic interpretation while preserving group dialogue.
function Group:QueueGroupCampResponses(value, primaryResult, actionResult)
    local input = self.dialogueInput
    local internal = input and input.Internal or nil
    local primary = self.primaryHost
    local queued = 0
    if not internal or not primary or not primaryResult then
        return 0, "group_camp_response_unavailable"
    end
    local primaryMember = self:MemberForHost(primary)
    if primaryMember and self:ShouldRespond(primaryMember, primaryResult, value)
    then
        queued = 1
    end
    for index = 1, #self.members do
        local member = self.members[index]
        local host = member.host
        if host ~= primary and self:ShouldRespond(member, primaryResult, value)
            and type(internal.QueueDeterministicResponse) == "function"
        then
            local responseQueued = internal.QueueDeterministicResponse(
                host,
                value,
                primaryResult,
                actionResult,
                {
                    groupConversation = self,
                    session = self:PrimarySession(),
                    speakerID = member.id,
                    speakerName = member.name,
                    participants = self.participantIDs,
                    groupID = self.id,
                    groupTurnID = self.activeTurn and self.activeTurn.id,
                }
            )
            if responseQueued == true then queued = queued + 1 end
        end
    end
    if self.activeTurn then self.activeTurn.responseCount = queued end
    audit(self, "semantic.group.camp_responses_queued", {
        groupID = self.id,
        turnID = self.activeTurn and self.activeTurn.id,
        responseCount = queued,
        actionDispatchCount = 1,
    })
    return queued, "group_camp_responses_queued"
end



Internal.CloneIR = cloneIR
Internal.ActionName = actionName
Internal.IsBroadcastCamp = isBroadcastCamp

require "PNC/Conversation/PNC_ConversationGroup_Fanout_MemberDispatch"
require "PNC/Conversation/PNC_ConversationGroup_Fanout"
