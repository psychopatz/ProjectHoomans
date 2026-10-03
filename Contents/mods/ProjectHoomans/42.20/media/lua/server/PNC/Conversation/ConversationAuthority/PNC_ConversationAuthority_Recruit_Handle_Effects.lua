-- Server-side recruitment relationship and history effect boundary.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.Authority = PNC.Conversation.Authority or {}
local Authority = PNC.Conversation.Authority
local Internal = Authority.Internal
local History = PNC.Conversation.History
local RecruitmentEffects = {}

local relationshipCopy = Internal.RelationshipCopy
local relationshipDelta = Internal.RelationshipDelta

function RecruitmentEffects.Commit(state)
    local context = state.context
    if state.accepted then
        History.Commit(
            state.attemptID,
            state.attemptPolicy,
            context,
            state.result and state.result.route
        )
        local commands = state.relationshipCommands
        if commands and commands.RecordInteraction then
            commands.RecordInteraction(
                state.record.id,
                context.playerEntityKey,
                {
                    eventID = "conversation:recruitment:"
                        .. tostring(state.record.id) .. ":"
                        .. state.requestID,
                    kind = "recruitment",
                    source = "recruitment",
                    interactionType = "recruitment_accepted",
                    choiceID = "recruit",
                    npcTextKey = Internal.RecruitReplyKey(
                        state.args.npcID,
                        nil,
                        state.result and state.result.route,
                        context.worldAgeHours
                    ),
                    applied = true,
                    at = context.worldAgeHours,
                    worldAgeHours = context.worldAgeHours,
                }
            )
        end
        return true
    end

    local before = relationshipCopy(context.relationship)
    local after = before
    local delta = { approval = -2, respect = -1, familiarity = 0 }
    local appliedResult
    local commands = state.relationshipCommands
    if commands and commands.ApplyConversationEffect then
        local applied
        applied, _, appliedResult = commands.ApplyConversationEffect(
            state.record.id,
            context.playerEntityKey,
            { approval = -2, respect = -1 },
            {
                blockID = "projecthoomans:recruitment",
                choiceID = "recruit",
                outcomeID = "rejected",
                worldAgeHours = context.worldAgeHours,
                sourceSystem = "recruitment",
                interaction = {
                    kind = "recruitment",
                    source = "recruitment",
                    interactionType = "recruitment_rejected",
                    choiceID = "recruit",
                    applied = true,
                },
            }
        )
        if applied == true and appliedResult
            and appliedResult.relationship
        then
            after = relationshipCopy(appliedResult.relationship)
            delta = relationshipDelta(before, after)
        end
    end
    History.Commit(
        state.attemptID,
        state.attemptPolicy,
        context,
        "rejected"
    )
    state.details = {
        relationshipBefore = before,
        relationshipAfter = after,
        relationshipDelta = delta,
        recruitment = state.result,
        npcReaction = type(state.result) == "table"
            and state.result.eligible == false and "declined" or nil,
    }
    return true
end

Internal.RecruitHandleEffects = RecruitmentEffects

return RecruitmentEffects
