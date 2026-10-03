-- Client-side group fanout member dispatch boundary.

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
local Group = PNC.Conversation.Group
local Internal = Group.Internal or {}
local Dispatch = {}

local cloneIR = Internal.CloneIR
local runtimeNow = Internal.RuntimeNow
local audit = Internal.Audit

if not cloneIR or not runtimeNow or not audit then
    Internal.FanoutMemberDispatch = Dispatch
    return Dispatch
end

function Dispatch.Process(group, value, primaryResult, member)
    local input = group.dialogueInput
    local internal = input and input.Internal or nil
    local host = member.host
    local requestID = group:RequestID(member.id)
    local queued = 0
    host.semanticRequestID = requestID
    local ok, reason = pcall(function()
        local router = internal.RouterFor(host)
        if not router or type(router.ProcessIR) ~= "function" then
            error("group_member_router_unavailable")
        end
        local context = internal.ShallowContext(host)
        local options = {
            timestamp = internal.Now and internal.Now() or runtimeNow(),
            groupID = group.id,
            groupTurnID = group.activeTurn and group.activeTurn.id,
            groupMemberID = member.id,
        }
        local result = router:ProcessIR(
            cloneIR(primaryResult.ir), context, options)
        host.lastSemanticDialogueResult = result
        if result.accepted == true then
            if internal.RecordContextTurn then
                internal.RecordContextTurn(host, result.ir, {
                    timestamp = options.timestamp,
                    speaker = "player",
                    source = "group_player_input",
                })
            end
            local actionResult
            if internal.DispatchAction then
                actionResult = internal.DispatchAction(host, result, value)
            end
            if internal.QueueDeterministicResponse then
                local responseQueued =
                    internal.QueueDeterministicResponse(
                    host, value, result, actionResult, {
                        groupConversation = group,
                        session = group:PrimarySession(),
                        speakerID = member.id,
                        speakerName = member.name,
                        participants = group.participantIDs,
                        groupID = group.id,
                        groupTurnID = group.activeTurn
                            and group.activeTurn.id,
                    }
                )
                if responseQueued == true then queued = queued + 1 end
            end
        end
        audit(group, "semantic.group.member", {
            groupID = group.id,
            turnID = group.activeTurn and group.activeTurn.id,
            npcID = member.id,
            requestID = requestID,
            accepted = result.accepted == true,
            route = result.decision and result.decision.route,
            branch = result.decision and result.decision.branch,
            action = result.ir and result.ir.action,
        }, { requestID = requestID })
    end)
    host.semanticRequestID = nil
    if not ok then
        audit(group, "semantic.group.member_failed", {
            groupID = group.id,
            turnID = group.activeTurn and group.activeTurn.id,
            npcID = member.id,
            requestID = requestID,
            reason = tostring(reason),
        }, { requestID = requestID })
    end
    return queued
end

Internal.FanoutMemberDispatch = Dispatch

return Dispatch
