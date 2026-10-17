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
        local ok, value = pcall(
            resolver,
            segment.templateID,
            segment.fallback,
            segment.args,
            segment
        )
        if ok and value ~= nil and tostring(value) ~= "" then
            return boundedText(value)
        end
    end
    return segment.fallback
end

function Plan.Render(plan, resolver, turnIndex)
    local valid, reason = Plan.Validate(plan)
    if not valid then return nil, reason end
    turnIndex = math.floor(tonumber(turnIndex) or 1)
    if turnIndex < 1 or turnIndex > #plan.turns then
        return nil, "response_plan_turn_unavailable"
    end
    local turn = plan.turns[turnIndex]
    local parts = {}
    local index
    local value
    for index = 1, #turn.segments do
        value = renderSegment(turn.segments[index], resolver)
        if value ~= "" then parts[#parts + 1] = value end
    end
    return boundedText(table.concat(parts, turn.separator), Plan.MAX_RENDER_LENGTH)
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
