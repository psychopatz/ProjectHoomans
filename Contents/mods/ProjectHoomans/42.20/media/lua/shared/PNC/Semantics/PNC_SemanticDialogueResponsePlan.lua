PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Plan = PNC.Semantics.ResponsePlan or {}
PNC.Semantics.ResponsePlan = Plan

Plan.VERSION = 1
Plan.MAX_TURNS = 4
Plan.MAX_SEGMENTS = 6
Plan.MAX_ID_LENGTH = 96
Plan.MAX_TEXT_LENGTH = 256
Plan.MAX_RENDER_LENGTH = 768
Plan.MAX_ARGS_FIELDS = 12
Plan.MAX_ARGS_DEPTH = 3

local function boundedText(value, limit)
    value = tostring(value or "")
    limit = tonumber(limit) or Plan.MAX_TEXT_LENGTH
    if #value > limit then return string.sub(value, 1, limit) end
    return value
end

local function validID(value)
    value = tostring(value or "")
    return value ~= ""
        and #value <= Plan.MAX_ID_LENGTH
        and string.find(value, "[^%w_%.%-]") == nil
end

local function copyValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= Plan.MAX_ARGS_DEPTH then return nil end
    local output = {}
    local count = 0
    local key
    local item
    for key, item in pairs(value) do
        if count >= Plan.MAX_ARGS_FIELDS then break end
        if type(key) == "string" or type(key) == "number" then
            output[key] = copyValue(item, depth + 1)
            count = count + 1
        end
    end
    return output
end

local function normalizedArgs(value)
    if type(value) ~= "table" then return {} end
    return copyValue(value, 0) or {}
end

local function normalizedSegment(value)
    if type(value) == "string" then
        value = { kind = "literal", text = value }
    end
    if type(value) ~= "table" then
        return nil, "response_plan_segment_invalid"
    end

    local kind = tostring(value.kind or "")
    if kind == "" and value.templateID ~= nil then
        kind = "translation"
    elseif kind == "" and value.text ~= nil then
        kind = "literal"
    end

    if kind == "translation" then
        local templateID = tostring(value.templateID or value.key or "")
        if not validID(templateID) then
            return nil, "response_plan_translation_id_invalid"
        end
        return {
            kind = kind,
            templateID = templateID,
            fallback = boundedText(value.fallback),
            args = normalizedArgs(value.args),
        }
    end

    if kind == "literal" then
        local text = boundedText(value.text)
        if text == "" then return nil, "response_plan_literal_empty" end
        return { kind = kind, text = text }
    end

    return nil, "response_plan_segment_kind_unsupported:" .. kind
end

local function normalizedTurn(value, index)
    if type(value) ~= "table" then
        return nil, "response_plan_turn_invalid"
    end
    local segments = value.segments or value.parts
    if type(segments) ~= "table" or #segments == 0 then
        return nil, "response_plan_turn_requires_segments"
    end
    if #segments > Plan.MAX_SEGMENTS then
        return nil, "response_plan_segment_limit"
    end

    local output = {
        id = boundedText(value.id or tostring(index), Plan.MAX_ID_LENGTH),
        separator = boundedText(value.separator or " ", 8),
        continuation = boundedText(value.continuation or "end", 32),
        segments = {},
    }
    local segment
    local reason
    local segmentIndex
    for segmentIndex = 1, #segments do
        segment, reason = normalizedSegment(segments[segmentIndex])
        if not segment then return nil, reason end
        output.segments[#output.segments + 1] = segment
    end
    return output
end

local function normalizedAct(value)
    value = tostring(value or "REPLY")
    if not validID(value) then return nil end
    return value
end

function Plan.Validate(value)
    if type(value) ~= "table" then
        return false, "response_plan_invalid"
    end
    if tonumber(value.schemaVersion) ~= Plan.VERSION then
        return false, "response_plan_version_invalid"
    end
    if value.kind ~= "dialogue_act_plan" then
        return false, "response_plan_kind_invalid"
    end
    if not normalizedAct(value.dialogueAct) then
        return false, "response_plan_act_invalid"
    end
    if type(value.turns) ~= "table" or #value.turns == 0 then
        return false, "response_plan_requires_turns"
    end
    if #value.turns > Plan.MAX_TURNS then
        return false, "response_plan_turn_limit"
    end
    local index
    local turn
    local segment
    local normalized
    local reason
    for index = 1, #value.turns do
        turn = value.turns[index]
        if type(turn) ~= "table"
            or type(turn.segments) ~= "table"
            or #turn.segments == 0
            or #turn.segments > Plan.MAX_SEGMENTS
        then
            return false, "response_plan_turn_invalid"
        end
        for segment = 1, #turn.segments do
            normalized, reason = normalizedSegment(turn.segments[segment])
            if reason then return false, reason end
        end
    end
    return true, value
end

function Plan.Build(spec)
    if type(spec) ~= "table" then
        return false, "response_plan_spec_invalid"
    end
    local dialogueAct = normalizedAct(spec.dialogueAct or spec.act)
    if not dialogueAct then return false, "response_plan_act_invalid" end

    local sourcePoolID = spec.sourcePoolID or spec.poolID
    if sourcePoolID ~= nil and not validID(sourcePoolID) then
        return false, "response_plan_pool_id_invalid"
    end

    local sourceTurns = spec.turns
    if sourceTurns == nil then
        sourceTurns = { { segments = spec.segments or spec.parts } }
    end
    if type(sourceTurns) ~= "table" or #sourceTurns == 0 then
        return false, "response_plan_requires_turns"
    end
    if #sourceTurns > Plan.MAX_TURNS then
        return false, "response_plan_turn_limit"
    end

    local output = {
        schemaVersion = Plan.VERSION,
        kind = "dialogue_act_plan",
        dialogueAct = dialogueAct,
        sourcePoolID = sourcePoolID,
        turns = {},
    }
    local index
    local turn
    local reason
    for index = 1, #sourceTurns do
        turn, reason = normalizedTurn(sourceTurns[index], index)
        if not turn then return false, reason end
        output.turns[#output.turns + 1] = turn
    end
    return true, output
end

function Plan.FromResponse(response, dialogueAct, sourcePoolID)
    if type(response) ~= "table" then return nil, "response_invalid" end
    local templateID = tostring(response.templateID or response.key or "")
    local fallback = boundedText(response.fallback)
    if not validID(templateID) or fallback == "" then
        return nil, "response_not_composable"
    end
    local ok, value = Plan.Build({
        dialogueAct = dialogueAct or response.dialogueAct or "REPLY",
        sourcePoolID = sourcePoolID or response.sourcePoolID,
        segments = {
            {
                kind = "translation",
                templateID = templateID,
                fallback = fallback,
                args = response.args,
            },
        },
    })
    if not ok then return nil, value end
    return value
end

function Plan.Attach(response, dialogueAct, sourcePoolID)
    if type(response) ~= "table" then return nil end
    if Plan.Validate(response.plan) then return response end
    local plan = Plan.FromResponse(response, dialogueAct, sourcePoolID)
    if plan then response.plan = plan end
    return response
end

function Plan.Compose(first, second)
    local validFirst, firstReason = Plan.Validate(first)
    if not validFirst then return false, firstReason end
    local validSecond, secondReason = Plan.Validate(second)
    if not validSecond then return false, secondReason end
    if #first.turns + #second.turns > Plan.MAX_TURNS then
        return false, "response_plan_turn_limit"
    end
    local turns = {}
    local index
    for index = 1, #first.turns do turns[#turns + 1] = first.turns[index] end
    for index = 1, #second.turns do turns[#turns + 1] = second.turns[index] end
    return Plan.Build({ dialogueAct = "COMPOSED", turns = turns })
end

require "PNC/Semantics/PNC_SemanticDialogueResponsePlan_Render"
return Plan
