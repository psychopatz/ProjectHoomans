-- Bounded contextual recovery for natural conversation input.
--
-- The core fuzzy matcher repairs registered concept typos. It cannot infer a
-- paraphrase such as "what happened?" from the literal pattern "what's
-- wrong?". This spoke only recovers question-shaped, no-match input when the
-- bounded conversation context supplies a single safe topic. It never creates
-- a gameplay action or resolves a world entity.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Semantic = PsychopatzCore.Semantics
local IR = Semantic.IR
local Normalizer = Semantic.Normalizer
local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input

local Internal = Input.Internal or {}
Input.Internal = Internal

local Recovery = PNC.Semantics.DialogueInputRecovery or {}
PNC.Semantics.DialogueInputRecovery = Recovery

Recovery.VERSION = 1
Recovery.MAX_TEXT_LENGTH = 160
Recovery.MAX_TOKENS = 10

local QUESTION_CUES = {
    what = true,
    when = true,
    where = true,
    who = true,
    why = true,
    how = true,
    is = true,
    are = true,
    ["do"] = true,
    did = true,
    can = true,
    could = true,
    have = true,
    tell = true,
}

local TOPIC_HINTS = {
    WELLBEING = {
        alright = true,
        banged = true,
        condition = true,
        feel = true,
        feeling = true,
        happened = true,
        happen = true,
        hurt = true,
        injured = true,
        matter = true,
        okay = true,
        problem = true,
        wrong = true,
    },
    ACTIVITY = {
        busy = true,
        doing = true,
        currently = true,
        work = true,
    },
    IDENTITY = {
        called = true,
        name = true,
    },
    RELATIONSHIP_STATUS = {
        dating = true,
        married = true,
        partner = true,
        relationship = true,
        single = true,
    },
    TIME = {
        clock = true,
        hour = true,
        time = true,
    },
    DATE = {
        date = true,
        day = true,
        today = true,
        tomorrow = true,
        yesterday = true,
    },
    WEATHER = {
        cold = true,
        fog = true,
        raining = true,
        rain = true,
        weather = true,
    },
}

local SAFE_TOPICS = {
    ACTIVITY = true,
    DATE = true,
    IDENTITY = true,
    RELATIONSHIP_STATUS = true,
    TIME = true,
    WEATHER = true,
    WELLBEING = true,
}

local function copyValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 8 then return nil end
    local output = {}
    for key, item in pairs(value) do
        output[key] = copyValue(item, depth + 1)
    end
    return output
end

local function editDistance(left, right, limit)
    if left == right then return 0 end
    if math.abs(#left - #right) > limit then return nil end

    local previousPrevious = {}
    local previous = {}
    local index
    for index = 0, #right do previous[index] = index end

    local row
    local leftByte
    local rightByte
    local current
    local best
    local substitution
    for row = 1, #left do
        current = { [0] = row }
        leftByte = string.byte(left, row)
        for index = 1, #right do
            rightByte = string.byte(right, index)
            substitution = previous[index - 1]
                + (leftByte == rightByte and 0 or 1)
            best = previous[index] + 1
            if current[index - 1] + 1 < best then
                best = current[index - 1] + 1
            end
            if substitution < best then best = substitution end
            if row > 1 and index > 1
                and leftByte == string.byte(right, index - 1)
                and string.byte(left, row - 1) == rightByte
                and previousPrevious[index - 2] ~= nil
            then
                local transposition = previousPrevious[index - 2] + 1
                if transposition < best then best = transposition end
            end
            current[index] = best
        end
        previousPrevious = previous
        previous = current
    end

    return previous[#right] <= limit and previous[#right] or nil
end

local function closeTo(value, candidates)
    if candidates[value] == true then return value, 0 end
    if #value < 3 then return nil end
    local candidate
    local limit
    local distance
    for candidate in pairs(candidates) do
        limit = #candidate >= 8 and 2 or 1
        distance = editDistance(value, candidate, limit)
        if distance ~= nil then return candidate, distance end
    end
    return nil
end

local function normalizedTopic(value)
    value = string.upper(tostring(value or ""))
    return SAFE_TOPICS[value] and value or nil
end

local function topicFromRecentTurns(context)
    local dialogue = context and context.semanticDialogueContext
    local turns = dialogue and dialogue.recentTurns or nil
    if type(turns) ~= "table" then return nil end
    for index = 1, math.min(#turns, 6) do
        local turn = turns[index]
        if type(turn) == "table" and turn.speaker == "npc"
            and turn.branch == "QUESTION_RECEIVED"
        then
            return normalizedTopic(turn.subject or turn.topic)
        end
    end
    return nil
end

local function topicFrom(context)
    local situation = context and context.dialogueSituation
    local conversation = situation and situation.conversation or nil
    local candidates = {
        context and context.currentTopic,
        conversation and conversation.currentTopic,
        context and context.semanticDialogueContext
            and context.semanticDialogueContext.currentTopic,
        context and context.semanticContextState
            and context.semanticContextState.currentTopic,
        topicFromRecentTurns(context),
    }
    for index = 1, #candidates do
        local topic = normalizedTopic(candidates[index])
        if topic then return topic end
    end
    return nil
end

local function normalizedInput(ir)
    local rawText = tostring(ir and ir.rawText or "")
    if #rawText == 0 or #rawText > Recovery.MAX_TEXT_LENGTH then
        return nil, rawText
    end
    local normalized = Normalizer.Normalize(rawText, {
        maxLength = Recovery.MAX_TEXT_LENGTH,
        maxTokens = Recovery.MAX_TOKENS,
    })
    if normalized.truncated or #normalized.tokens == 0
        or #normalized.tokens > Recovery.MAX_TOKENS
    then
        return nil, rawText
    end
    return normalized, rawText
end

local function questionEvidence(normalized, rawText)
    local evidence = {}
    local questionMark = string.find(rawText, "?", 1, true) ~= nil
    local first = normalized.tokens[1]
    local cue
    local distance
    if first then cue, distance = closeTo(first, QUESTION_CUES) end
    if not questionMark and not cue then return nil end
    if cue then
        evidence[#evidence + 1] = {
            text = first,
            matchedAlias = cue,
            editDistance = distance,
        }
    end
    return evidence
end

local function topicEvidence(topic, normalized)
    local hints = TOPIC_HINTS[topic]
    if type(hints) ~= "table" then return nil end
    local evidence = {}
    local token
    local matched
    local distance
    for index = 1, #normalized.tokens do
        token = normalized.tokens[index]
        matched, distance = closeTo(token, hints)
        if matched then
            evidence[#evidence + 1] = {
                text = token,
                matchedAlias = matched,
                editDistance = distance,
            }
        end
    end
    return #evidence > 0 and evidence or nil
end

local function mergeEvidence(first, second)
    local output = {}
    for index = 1, #(first or {}) do output[#output + 1] = first[index] end
    for index = 1, #(second or {}) do output[#output + 1] = second[index] end
    return output
end

local function recoverQuestion(ir, topic, evidence)
    local diagnostics = copyValue(ir.diagnostics) or {}
    diagnostics.noMatch = false
    diagnostics.recoveredMatch = true
    diagnostics.recoveryKind = "contextual_question"
    diagnostics.fuzzyMatch = true
    diagnostics.matchedPattern = "pnc.recovery.contextual_question_"
        .. string.lower(topic)
    diagnostics.correctedTokens = evidence
    diagnostics.unmatchedTokens = {}
    diagnostics.coverage = 1
    diagnostics.recommendedRoute = "deterministic"

    local extensions = {
        recovery = "CONTEXTUAL_FUZZY",
        topic = topic,
    }
    if topic == "WELLBEING" then
        extensions.dialogueFollowUp = "WELLBEING"
    end

    return IR.New({
        rawText = ir.rawText,
        normalizedText = ir.normalizedText,
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = topic,
        confidence = 0.88,
        diagnostics = diagnostics,
        analysis = copyValue(ir.analysis),
        extensions = extensions,
        provenance = {
            provider = "lua",
            parser = "deterministic",
            pattern = diagnostics.matchedPattern,
        },
    })
end

function Recovery.Recover(ir, context)
    local diagnostics = ir and ir.diagnostics or nil
    if type(ir) ~= "table" or type(diagnostics) ~= "table"
        or diagnostics.noMatch ~= true
    then
        return nil, "not_a_no_match"
    end

    local normalized, rawText = normalizedInput(ir)
    if not normalized then return nil, "input_out_of_bounds" end
    local question = questionEvidence(normalized, rawText)
    if not question then return nil, "not_question_shaped" end

    local topic = topicFrom(context)
    if not topic then return nil, "no_safe_context_topic" end
    local hints = topicEvidence(topic, normalized)
    if not hints then return nil, "topic_not_supported_by_input" end

    return recoverQuestion(
        ir,
        topic,
        mergeEvidence(question, hints)
    ), "contextual_question"
end

Internal.Recover = Recovery.Recover

return Recovery
