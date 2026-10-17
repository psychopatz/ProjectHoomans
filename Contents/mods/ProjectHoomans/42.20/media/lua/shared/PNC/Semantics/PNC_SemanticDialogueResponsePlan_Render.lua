PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Plan = PNC.Semantics.ResponsePlan

local function boundedText(value, limit)
    value = tostring(value or "")
    limit = tonumber(limit) or Plan.MAX_TEXT_LENGTH
    if #value > limit then return string.sub(value, 1, limit) end
    return value
end

local function renderSegment(segment, resolver)
    if segment.kind == "literal" then return segment.text end
    if type(resolver) == "function" then
        local ok, value, metadata = pcall(
            resolver,
            segment.templateID,
            segment.fallback,
            segment.args,
            segment
        )
        if ok and value ~= nil and tostring(value) ~= "" then
            return boundedText(value), metadata
        end
    end
    return segment.fallback, nil
end

function Plan.RenderDetailed(plan, resolver, turnIndex)
    local valid, reason = Plan.Validate(plan)
    if not valid then return nil, reason end
    turnIndex = math.floor(tonumber(turnIndex) or 1)
    if turnIndex < 1 or turnIndex > #plan.turns then
        return nil, "response_plan_turn_unavailable"
    end
    local turn = plan.turns[turnIndex]
    local parts = {}
    local segments = {}
    local translationKeys = {}
    local index
    local value
    local metadata
    for index = 1, #turn.segments do
        value, metadata = renderSegment(turn.segments[index], resolver)
        if value ~= "" then
            parts[#parts + 1] = value
            segments[#segments + 1] = {
                kind = turn.segments[index].kind,
                templateID = turn.segments[index].templateID,
                fallback = turn.segments[index].fallback,
                args = turn.segments[index].args,
                text = value,
                translationKey = metadata,
            }
            if metadata ~= nil and tostring(metadata) ~= "" then
                translationKeys[#translationKeys + 1] = tostring(metadata)
            end
        end
    end
    return {
        index = turnIndex,
        id = turn.id,
        continuation = turn.continuation,
        text = boundedText(
            table.concat(parts, turn.separator),
            Plan.MAX_RENDER_LENGTH
        ),
        segments = segments,
        translationKeys = translationKeys,
    }
end

function Plan.Render(plan, resolver, turnIndex)
    local rendered, reason = Plan.RenderDetailed(plan, resolver, turnIndex)
    if not rendered then return nil, reason end
    return rendered.text
end

function Plan.RenderTurns(plan, resolver)
    local valid, reason = Plan.Validate(plan)
    if not valid then return nil, reason end
    local output = {}
    local index
    local rendered
    for index = 1, #plan.turns do
        rendered = Plan.Render(plan, resolver, index)
        if rendered == nil then return nil, "response_plan_render_failed" end
        output[#output + 1] = rendered
    end
    return output
end

return Plan
