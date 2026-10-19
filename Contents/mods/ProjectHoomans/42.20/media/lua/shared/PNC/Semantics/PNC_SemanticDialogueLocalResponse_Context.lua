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

local function recentAnswer(context, limit)
    local recentTurns = recentTurnsFrom(context, limit or 4)
    if #recentTurns == 0 then return nil, nil end

    local responseTurn = recentTurns[1]
    local playerTurn
    -- The normal lifecycle resolves before recording the current player turn;
    -- direct callers and preview tooling may record it first.  In both cases
    -- only the immediately preceding NPC answer can continue the topic.
    if type(responseTurn) == "table"
        and responseTurn.speaker == "player"
    then
        playerTurn = responseTurn
        responseTurn = recentTurns[2]
    end
    if type(responseTurn) ~= "table"
        or responseTurn.speaker ~= "npc"
        or responseTurn.speechAct ~= "ANSWER"
    then
        return nil, playerTurn
    end
    return responseTurn, playerTurn
end

Internal.RecentAnswer = recentAnswer

local function followsRelationshipStatusAnswer(context)
    local responseTurn = recentAnswer(context, 3)
    return type(responseTurn) == "table"
        and responseTurn.speaker == "npc"
        and responseTurn.speechAct == "ANSWER"
        and responseTurn.branch == "QUESTION_RECEIVED"
        and (responseTurn.subject == "RELATIONSHIP_STATUS"
            or responseTurn.topic == "RELATIONSHIP_STATUS")
end

local function followsWellbeingAnswer(context)
    local responseTurn = recentAnswer(context, 4)
    return type(responseTurn) == "table"
        and responseTurn.speaker == "npc"
        and responseTurn.speechAct == "ANSWER"
        and responseTurn.branch == "QUESTION_RECEIVED"
        and responseTurn.subject == "WELLBEING"
end

local function followsQuestionAnswer(context)
    local responseTurn = recentAnswer(context, 4)
    local subject = responseTurn and responseTurn.subject
    local topic = responseTurn and responseTurn.topic
    return type(responseTurn) == "table"
        and responseTurn.branch == "QUESTION_RECEIVED"
        and (subject == "WELLBEING"
            or subject == "RELATIONSHIP_STATUS"
            or subject == "NPC_RESIDENCE"
            or subject == "NPC_HEALTH_STATE"
            or subject == "NPC_BITE_STATUS"
            or subject == "NPC_KNOWLEDGE"
            or topic == "medical"
            or topic == "location"
            or topic == "residence"
            or topic == "knowledge")
end

local resolveQuestion = require
    "PNC/Semantics/PNC_SemanticDialogueLocalResponse_Questions"


Internal.FollowsRelationshipStatusAnswer = followsRelationshipStatusAnswer
Internal.FollowsWellbeingAnswer = followsWellbeingAnswer
Internal.FollowsQuestionAnswer = followsQuestionAnswer
Internal.ResolveQuestion = resolveQuestion

return Response
