require "PNC/Conversation/Blocks/PNC_ConversationRules"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Registry = PNC.Conversation.Registry
local Rules = PNC.Conversation.Rules
local Selector = PNC.Conversation.Selector or {}
PNC.Conversation.Selector = Selector

function Selector.Hash(value, seed)
    local total = tonumber(seed) or 5381
    value = tostring(value or "")
    for index = 1, #value do
        total = (total * 33 + string.byte(value, index)) % 2147483647
    end
    return total
end

function Selector.Seed(context, channel)
    context = type(context) == "table" and context or {}
    local parts = {
        Registry.SCHEMA_VERSION,
        context.worldID or "world",
        context.characterUUID or "unbound",
        context.npcID or "unknown",
        math.floor((tonumber(context.worldAgeHours) or 0) / 24),
        context.historySlot or 0,
        channel or "default",
    }
    local seed = 5381
    for _, part in ipairs(parts) do seed = Selector.Hash(part, seed) end
    return seed
end

local function historyEntry(context, subjectID, policy)
    if type(context.historyLookup) == "function" then
        return context.historyLookup(subjectID, policy and policy.scope)
    end
    return context.historyEntry
end

function Selector.IsBlockEligible(block, context)
    if not block or not Rules.MatchesAudience(block, context) then
        return false, "audience_mismatch"
    end
    local repeatOK, repeatReason = Rules.CheckRepeat(
        block["repeat"],
        historyEntry(context, block.id, block["repeat"]),
        context.worldAgeHours
    )
    if not repeatOK then return false, repeatReason end
    return Rules.EvaluateAll(block.gates, context)
end

function Selector.IsCategoryEligible(categoryID, context, allowSystem)
    local category = Registry.GetCategory(categoryID)
    if not category then return false, "category_not_found" end
    if category.system == true and allowSystem ~= true then
        return false, "system_category"
    end
    local eligible, reason = Rules.EvaluateAll(category.gates, context)
    if not eligible then return false, reason end
    if context and type(context.categoryValidator) == "function" then
        return context.categoryValidator(category)
    end
    return true
end

local function weighted(values, seed)
    if #values == 0 then return nil end
    local total = 0
    for _, value in ipairs(values) do
        total = total + math.max(1, tonumber(value.weight) or 1)
    end
    local roll = seed % total
    local cursor = 0
    for _, value in ipairs(values) do
        cursor = cursor + math.max(1, tonumber(value.weight) or 1)
        if roll < cursor then return value, roll, total end
    end
    return values[#values], roll, total
end

function Selector.SelectBlock(categoryID, context)
    local eligible = {}
    local diagnostics = {}
    local maximumPriority
    for _, block in ipairs(Registry.ListBlocks({ category = categoryID })) do
        local ok, reason = Selector.IsBlockEligible(block, context)
        if ok and context and type(context.blockValidator) == "function" then
            ok, reason = context.blockValidator(block)
        end
        diagnostics[#diagnostics + 1] = {
            id = block.id, eligible = ok == true, reason = reason,
        }
        if ok then
            local priority = tonumber(block.priority) or 0
            if maximumPriority == nil or priority > maximumPriority then
                maximumPriority = priority
                eligible = { block }
            elseif priority == maximumPriority then
                eligible[#eligible + 1] = block
            end
        end
    end
    table.sort(eligible, function(a, b) return a.id < b.id end)
    local selected, roll, total = weighted(
        eligible,
        Selector.Seed(context, "category:" .. tostring(categoryID))
    )
    return selected, {
        roll = roll,
        totalWeight = total,
        eligibleCount = #eligible,
        candidates = diagnostics,
    }
end

function Selector.GetChoice(block, nodeID, choiceID)
    local node = block and block.nodes and block.nodes[nodeID]
    for _, choice in ipairs(node and node.choices or {}) do
        if choice.id == choiceID then return choice, node end
    end
    return nil, node
end

function Selector.IsChoiceEligible(block, nodeID, choice, context)
    if not choice then return false, "choice_not_found" end
    local subjectID = table.concat({ block.id, nodeID, choice.id }, "/")
    local repeatOK, repeatReason = Rules.CheckRepeat(
        choice["repeat"],
        historyEntry(context, subjectID, choice["repeat"]),
        context.worldAgeHours
    )
    if not repeatOK then return false, repeatReason end
    return Rules.EvaluateAll(choice.gates, context)
end

function Selector.SelectOutcome(block, nodeID, choice, context)
    local eligible = {}
    for _, outcome in ipairs(choice and choice.outcomes or {}) do
        local passed = Rules.EvaluateAll(outcome.gates, context)
        if passed then eligible[#eligible + 1] = outcome end
    end
    table.sort(eligible, function(a, b) return a.id < b.id end)
    return weighted(eligible, Selector.Seed(
        context,
        table.concat({ "outcome", block.id, nodeID, choice.id }, ":")
    ))
end

return Selector
