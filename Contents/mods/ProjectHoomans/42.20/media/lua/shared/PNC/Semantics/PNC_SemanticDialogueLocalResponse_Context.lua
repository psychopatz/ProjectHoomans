-- Semantic response conversation-context and question resolver provider.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Response = PNC.Semantics.LocalResponse
local Internal = Response.Internal or {}
Response.Internal = Internal

local function recentTurnsFrom(context, limit)
    context = type(context) == "table" and context or {}
    local dialogue = type(context.semanticDialogueContext) == "table"
        and context.semanticDialogueContext
        or type(context.semanticContextState) == "table"
        and context.semanticContextState or nil
    if not dialogue then return {} end

    local recentTurns = dialogue.recentTurns
    if type(recentTurns) ~= "table"
        and type(dialogue.RecentTurns) == "function"
    then
        recentTurns = dialogue:RecentTurns(limit or 6, true)
    end
    return type(recentTurns) == "table" and recentTurns or {}
end

Internal.RecentTurns = recentTurnsFrom

local function followsRelationshipStatusAnswer(context)
    local recentTurns = recentTurnsFrom(context, 2)
    if #recentTurns == 0 then return false end

    local responseTurn = recentTurns[1]
    -- Some callers snapshot context before recording the player's input;
    -- others record it before resolving the response. Support both orders.
    if type(responseTurn) == "table"
        and responseTurn.speaker == "player"
        and responseTurn.intent == "ACKNOWLEDGE"
    then
        responseTurn = recentTurns[2]
    end

    return type(responseTurn) == "table"
        and responseTurn.speaker == "npc"
        and responseTurn.speechAct == "ANSWER"
        and responseTurn.branch == "QUESTION_RECEIVED"
        and (responseTurn.subject == "RELATIONSHIP_STATUS"
            or responseTurn.topic == "RELATIONSHIP_STATUS")
end

local resolveQuestion = require
    "PNC/Semantics/PNC_SemanticDialogueLocalResponse_Questions"


Internal.FollowsRelationshipStatusAnswer = followsRelationshipStatusAnswer
Internal.ResolveQuestion = resolveQuestion

return Response
