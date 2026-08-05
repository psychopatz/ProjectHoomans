PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.ConversationDebugModel = PNC.ConversationDebugModel or {}

local Model = PNC.ConversationDebugModel
local Registry = PNC.Conversation.Registry
local Selector = PNC.Conversation.Selector
local Rules = PNC.Conversation.Rules
local Loader = PNC.Conversation.TextLoader

local function copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local output = {}
    seen[value] = output
    for key, child in pairs(value) do output[copy(key, seen)] = copy(child, seen) end
    return output
end

local function contains(value, query)
    if query == "" then return true end
    return string.find(string.lower(tostring(value or "")), query, 1, true) ~= nil
end

function Model.DefaultContext()
    return {
        worldID = "debug-world",
        characterUUID = "debug-character",
        npcID = "debug-npc",
        worldAgeHours = 12 * 24 + 12,
        hour = 12,
        historySlot = 0,
        audiences = {
            hostile = false, neutral = true, member = false,
            special = false, shared = true,
        },
        relationshipState = "Acquaintance",
        relationship = {
            approval = 25, respect = 20,
            familiarity = 20, morale = 0,
        },
        playerSkills = {},
        npcSkills = {},
        playerTraits = {},
        npcTraits = {},
        npcPersonality = {},
        playerPersonality = {},
    }
end

function Model.NormalizeContext(context)
    local output = Model.DefaultContext()
    for key, value in pairs(type(context) == "table" and context or {}) do
        output[key] = copy(value)
    end
    return output
end

local function appendGateSearch(parts, gates)
    for _, gate in ipairs(gates or {}) do
        parts[#parts + 1] = gate.type
        appendGateSearch(parts, gate.gates)
        if gate.gate then appendGateSearch(parts, { gate.gate }) end
    end
end

local function blockSearchText(block, valid, errors)
    local parts = {
        block.id, block.ownerModID, block.category,
        valid and "valid" or "invalid",
        block.textSource and block.textSource.pathPattern,
        table.concat(block.audiences or {}, " "),
        table.concat(errors or {}, " "),
    }
    appendGateSearch(parts, block.gates)
    for _, node in pairs(block.nodes or {}) do
        appendGateSearch(parts, node.gates)
        for _, choice in ipairs(node.choices or {}) do
            parts[#parts + 1] = choice.id
            appendGateSearch(parts, choice.gates)
            for _, outcome in ipairs(choice.outcomes or {}) do
                parts[#parts + 1] = outcome.id
                appendGateSearch(parts, outcome.gates)
                for _, effect in ipairs(outcome.effects or {}) do
                    parts[#parts + 1] = effect.type
                end
            end
        end
    end
    return table.concat(parts, " ")
end

local function gateListContains(gates, wanted)
    for _, gate in ipairs(gates or {}) do
        if gate.type == wanted then return true end
        if gateListContains(gate.gates, wanted)
            or gateListContains(gate.gate and { gate.gate }, wanted)
        then return true end
    end
    return false
end

local function blockUsesGate(block, wanted)
    if gateListContains(block.gates, wanted) then return true end
    for _, node in pairs(block.nodes or {}) do
        if gateListContains(node.gates, wanted) then return true end
        for _, choice in ipairs(node.choices or {}) do
            if gateListContains(choice.gates, wanted) then return true end
            for _, outcome in ipairs(choice.outcomes or {}) do
                if gateListContains(outcome.gates, wanted) then return true end
            end
        end
    end
    return false
end

function Model.List(filters, context)
    filters = type(filters) == "table" and filters or {}
    context = Model.NormalizeContext(context)
    local query = string.lower(tostring(filters.query or ""))
    local output = {}
    for _, value in ipairs(Registry.ListBlocks({ includeInvalid = true })) do
        local block = value.definition or value
        local valid, errors = Registry.ValidateBlock(value.id, block)
        local translationValid = false
        local translationFallback = false
        local translationErrors = {}
        if valid then
            local translationResult
            translationValid, translationResult = Loader.EnsureSource(
                block.textSource,
                Registry.CollectTextKeys(block)
            )
            if translationValid then
                local diagnostic = Loader.diagnostics[block.textSource.domain]
                    or {}
                translationFallback = diagnostic.usedFallback == true
                translationErrors = copy(diagnostic.missingLocalizedKeys or {})
                if diagnostic.localizedError then
                    translationErrors[#translationErrors + 1] =
                        tostring(diagnostic.localizedError)
                end
            else
                translationErrors = translationResult or {}
            end
        end
        local eligible = false
        local reason = "invalid_block"
        if valid then
            eligible, reason = Selector.IsBlockEligible(block, context)
        end
        local matches = contains(
            blockSearchText(block, valid, errors), query
        )
        if filters.validity == "valid" and not valid then matches = false end
        if filters.validity == "invalid" and valid then matches = false end
        if filters.translation == "missing" and translationValid then matches = false end
        if filters.translation == "available" and not translationValid then matches = false end
        if filters.translation == "fallback" and not translationFallback then
            matches = false
        end
        if filters.ownerModID and block.ownerModID ~= filters.ownerModID then matches = false end
        if filters.category and block.category ~= filters.category then matches = false end
        if filters.source and not contains(
            block.textSource and block.textSource.pathPattern,
            string.lower(tostring(filters.source))
        ) then matches = false end
        if filters.gate and not blockUsesGate(block, filters.gate) then
            matches = false
        end
        if filters.eligibility == "eligible" and not eligible then matches = false end
        if filters.eligibility == "gated" and eligible then matches = false end
        if filters.audience then
            local audienceFound = false
            for _, audience in ipairs(block.audiences or {}) do
                if audience == filters.audience then audienceFound = true end
            end
            if not audienceFound then matches = false end
        end
        if matches then
            output[#output + 1] = {
                id = value.id,
                block = copy(block),
                valid = valid,
                errors = copy(errors),
                translationValid = translationValid,
                translationFallback = translationFallback,
                translationErrors = copy(translationErrors),
                eligible = eligible == true,
                eligibilityReason = reason,
                seed = Selector.Seed(context, "category:" .. tostring(block.category)),
            }
        end
    end
    table.sort(output, function(a, b) return a.id < b.id end)
    return output
end

function Model.Inspect(blockID, context)
    local block = Registry.GetBlock(blockID)
    if not block then return nil, "block_not_found" end
    context = Model.NormalizeContext(context)
    local eligible, reason, failedGate = Selector.IsBlockEligible(block, context)
    local nodes = {}
    for nodeID, node in pairs(block.nodes or {}) do
        local nodeValue = { id = nodeID, textKey = node.textKey,
            textKeys = copy(node.textKeys), choices = {} }
        for _, choice in ipairs(node.choices or {}) do
            local choiceEligible, choiceReason = Selector.IsChoiceEligible(
                block, nodeID, choice, context
            )
            local outcomes = {}
            for _, outcome in ipairs(choice.outcomes or {}) do
                local outcomeEligible, outcomeReason = Rules.EvaluateAll(
                    outcome.gates,
                    context
                )
                outcomes[#outcomes + 1] = {
                    id = outcome.id,
                    weight = outcome.weight,
                    responseKey = outcome.responseKey,
                    next = outcome.next,
                    close = outcome.close == true,
                    eligible = outcomeEligible == true,
                    reason = outcomeReason,
                    gates = copy(outcome.gates),
                    effects = copy(outcome.effects),
                    effectPreview = Rules.SimulateEffects(outcome.effects, context),
                }
            end
            nodeValue.choices[#nodeValue.choices + 1] = {
                id = choice.id,
                textKey = choice.textKey,
                eligible = choiceEligible == true,
                reason = choiceReason,
                lockedMode = choice.lockedMode or "hidden",
                gates = copy(choice.gates),
                outcomes = outcomes,
            }
        end
        nodes[#nodes + 1] = nodeValue
    end
    table.sort(nodes, function(a, b) return a.id < b.id end)
    return {
        block = block,
        eligible = eligible == true,
        reason = reason,
        failedGate = copy(failedGate),
        seed = Selector.Seed(context, "category:" .. tostring(block.category)),
        nodes = nodes,
        context = context,
    }
end

function Model.ExecuteSandbox(blockID, nodeID, choiceID, context)
    local block = Registry.GetBlock(blockID)
    if not block then return nil, "block_not_found" end
    context = Model.NormalizeContext(context)
    local choice = Selector.GetChoice(block, nodeID, choiceID)
    local eligible, reason = Selector.IsChoiceEligible(
        block, nodeID, choice, context
    )
    if not eligible then return nil, reason end
    local outcome, roll, total = Selector.SelectOutcome(
        block, nodeID, choice, context
    )
    if not outcome then return nil, "no_eligible_outcome" end
    local before = copy(context)
    local previews = Rules.SimulateEffects(outcome.effects, context)
    local after = copy(context)
    for _, preview in ipairs(previews) do
        for key, delta in pairs(preview.relationship or {}) do
            after.relationship[key] = (tonumber(after.relationship[key]) or 0)
                + (tonumber(delta) or 0)
        end
    end
    return {
        blockID = blockID,
        nodeID = nodeID,
        choiceID = choiceID,
        outcomeID = outcome.id,
        roll = roll,
        totalWeight = total,
        responseKey = outcome.responseKey,
        before = before,
        after = after,
        effects = previews,
        persisted = false,
        networked = false,
    }
end

return Model
