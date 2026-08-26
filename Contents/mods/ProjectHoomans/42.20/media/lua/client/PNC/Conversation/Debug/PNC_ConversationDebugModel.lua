PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.ConversationDebugModel = PNC.ConversationDebugModel or {}

local Model = PNC.ConversationDebugModel
local Registry = PNC.Conversation.Registry
local Selector = PNC.Conversation.Selector
local Rules = PNC.Conversation.Rules
local Loader = PNC.Conversation.TextLoader

local DEBUG_SOURCE = {
    modID = "ProjectHoomans",
    pathPattern = "media/conversation/system/shared/{language}/debugger.json",
    domain = "pnc.system.shared.debugger",
}

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
        nextNodeID = outcome.next,
        close = outcome.close == true,
        before = before,
        after = after,
        effects = previews,
        persisted = false,
        networked = false,
    }
end

local function sandboxText(block, key, context)
    return Loader.Payload(block.textSource, key, context.textArgs)
end

local function debugText(key, args)
    Loader.EnsureSource(DEBUG_SOURCE, { key })
    return Loader.Payload(DEBUG_SOURCE, key, args)
end

local function sandboxCategoryNodeID(categoryID)
    return "sandbox:category:" .. tostring(categoryID)
end

local function sandboxBlockNodeID(blockID, nodeID)
    return table.concat({ "sandbox:block", blockID, nodeID }, ":")
end

local function sandboxNodeTextKey(block, nodeID, node, context)
    if node.textKey then return node.textKey end
    local keys = node.textKeys or {}
    if #keys == 0 then return nil end
    local seed = Selector.Seed(
        context,
        table.concat({ "sandbox_node", block.id, nodeID }, ":")
    )
    return keys[seed % #keys + 1]
end

local function updateSandboxRelationship(session, context)
    local panel = session and session.view and session.view.extensionParts
        and session.view.extensionParts.relationship or nil
    if panel and panel.setRelationship then
        local summary = copy(context.relationship)
        summary.exists = true
        panel:setRelationship(summary)
    end
end

local function sandboxChoice(block, nodeID, choice, context, categoryNodeID)
    local runtime = {}
    local function eligible()
        return Selector.IsChoiceEligible(block, nodeID, choice, context)
    end
    local function choiceText()
        local passed, reason = eligible()
        if passed then
            return sandboxText(block, choice.textKey, context)
        end
        local label = PsychopatzCore.Conversation.Text.Resolve(
            sandboxText(block, choice.textKey, context)
        )
        local reasonKey = choice.lockedReasonKey or reason
        local explanation = reasonKey and PsychopatzCore.Conversation.Text.Resolve(
            sandboxText(block, reasonKey, context)
        ) or tostring(reason or "gated")
        return { text = label .. " (" .. explanation .. ")" }
    end
    return {
        id = choice.id,
        text = choiceText,
        -- The debugger reveals authored hidden choices as disabled rows so the
        -- cloned context can be adjusted until their gates pass.
        visible = true,
        enabled = function()
            local passed = eligible()
            return passed
        end,
        action = function(_, _, session)
            local result, reason = Model.ExecuteSandbox(
                block.id,
                nodeID,
                choice.id,
                context
            )
            runtime.result = result
            runtime.reason = reason
            if not result then return end
            context.relationship = copy(result.after.relationship)
            context.historyEntry = context.historyEntry or { useCount = 0 }
            context.historyEntry.useCount =
                (tonumber(context.historyEntry.useCount) or 0) + 1
            context.historyEntry.lastUsedWorldHour = context.worldAgeHours
            context.historyEntry.lastOutcomeID = result.outcomeID
            context.historySlot = context.historyEntry.useCount
            Model.lastSandbox = copy(result)
            updateSandboxRelationship(session, context)
        end,
        response = function()
            if runtime.result and runtime.result.responseKey then
                return sandboxText(
                    block,
                    runtime.result.responseKey,
                    context
                )
            end
            if runtime.reason then
                return { text = "Sandbox rejected: " .. tostring(runtime.reason) }
            end
            return nil
        end,
        next = function()
            if not runtime.result then
                return sandboxBlockNodeID(block.id, nodeID)
            end
            local nextNodeID = runtime.result.nextNodeID
            if nextNodeID and nextNodeID ~= "$root" then
                return sandboxBlockNodeID(block.id, nextNodeID)
            end
            -- Terminal outcomes loop back into the browser in a sandbox. This
            -- preserves the cloned graph and lets another block be exercised.
            return categoryNodeID
        end,
        close = false,
    }
end

function Model.BuildSandboxDefinition(blockID, context)
    local selectedBlock = Registry.GetBlock(blockID)
    if not selectedBlock then return nil, "block_not_found" end
    context = Model.NormalizeContext(context)
    context.relationship = type(context.relationship) == "table"
        and context.relationship or {}
    context.relationship.exists = true
    context.playerName = context.playerName or "Sandbox Player"
    context.playerFullName = context.playerFullName or context.playerName
    context.playerFirstName = context.playerFirstName or "Sandbox"
    context.playerLastName = context.playerLastName or "Player"
    context.npcName = context.npcName or "Sandbox NPC"
    context.npcFullName = context.npcFullName or context.npcName
    context.npcFirstName = context.npcFirstName or "Sandbox"
    context.npcLastName = context.npcLastName or "NPC"
    context.textArgs = {
        playerName = context.playerName,
        playerFullName = context.playerFullName,
        playerFirstName = context.playerFirstName,
        playerLastName = context.playerLastName,
        npcName = context.npcName,
        npcFullName = context.npcFullName,
        npcFirstName = context.npcFirstName,
        npcLastName = context.npcLastName,
    }
    context.sandbox = true
    context.sandboxBlockID = selectedBlock.id

    local nodes = {}
    local blocksByCategory = {}
    local runnableBlocks = 0
    for _, block in ipairs(Registry.ListBlocks()) do
        local categoryNodeID = sandboxCategoryNodeID(block.category)
        local textValid = Loader.EnsureSource(
            block.textSource,
            Registry.CollectTextKeys(block)
        )
        local blockEntry = {
            block = block,
            textValid = textValid == true,
        }
        blocksByCategory[block.category] = blocksByCategory[block.category] or {}
        blocksByCategory[block.category][#blocksByCategory[block.category] + 1]
            = blockEntry
        if textValid then
            runnableBlocks = runnableBlocks + 1
            for nodeID, node in pairs(block.nodes or {}) do
                local choices = {}
                for _, choice in ipairs(node.choices or {}) do
                    choices[#choices + 1] = sandboxChoice(
                        block,
                        nodeID,
                        choice,
                        context,
                        categoryNodeID
                    )
                end
                choices[#choices + 1] = {
                    id = "sandbox_back_to_blocks",
                    text = debugText("sandbox.back_to_blocks"),
                    log = false,
                    next = categoryNodeID,
                }
                nodes[sandboxBlockNodeID(block.id, nodeID)] = {
                    npc = sandboxText(
                        block,
                        sandboxNodeTextKey(block, nodeID, node, context),
                        context
                    ),
                    choices = choices,
                }
            end
        end
    end

    local categoryChoices = {}
    for _, category in ipairs(Registry.ListCategories()) do
        local entries = blocksByCategory[category.id] or {}
        if #entries > 0 then
            Loader.EnsureSource(category.textSource, { category.labelKey })
            local categoryLabel = Loader.Payload(
                category.textSource,
                category.labelKey
            )
            categoryChoices[#categoryChoices + 1] = {
                id = category.id,
                text = categoryLabel,
                log = false,
                next = sandboxCategoryNodeID(category.id),
            }
            local blockChoices = {}
            for _, entry in ipairs(entries) do
                local eligible, reason = Selector.IsBlockEligible(
                    entry.block,
                    context
                )
                blockChoices[#blockChoices + 1] = {
                    id = entry.block.id,
                    text = debugText("sandbox.block_choice", {
                        id = entry.block.id,
                        audiences = table.concat(entry.block.audiences or {}, ","),
                        status = not entry.textValid and "missing translation"
                            or eligible and "eligible"
                            or "gated: " .. tostring(reason or "unknown"),
                    }),
                    log = false,
                    enabled = entry.textValid,
                    next = entry.textValid and sandboxBlockNodeID(
                        entry.block.id,
                        entry.block.entryNode
                    ) or nil,
                }
            end
            blockChoices[#blockChoices + 1] = {
                id = "sandbox_back_to_categories",
                text = debugText("sandbox.back_to_categories"),
                log = false,
                next = "sandbox:categories",
            }
            nodes[sandboxCategoryNodeID(category.id)] = {
                npc = debugText("sandbox.category_prompt", {
                    category = PsychopatzCore.Conversation.Text.Resolve(
                        categoryLabel
                    ),
                    count = #entries,
                }),
                choices = blockChoices,
            }
        end
    end
    nodes["sandbox:categories"] = {
        npc = debugText("sandbox.categories_prompt", {
            count = runnableBlocks,
        }),
        choices = categoryChoices,
    }
    context.sandboxBlockCount = runnableBlocks

    local extensions = {}
    if PNC.Conversation.CreateRelationshipPanel then
        extensions[#extensions + 1] = {
            partID = "relationship",
            factory = PNC.Conversation.CreateRelationshipPanel,
            relationship = copy(context.relationship),
            visible = true,
            title = {
                key = "panel.current_relation",
                domain = "pnc.system.shared.categories",
            },
            editLabel = {
                key = "panel.current_relation_edit",
                domain = "pnc.system.shared.categories",
            },
        }
    end
    local fakeEntry = {
        id = context.npcID,
        snapshot = {
            tacticalClass = context.audiences.hostile and "hostile" or "neutral",
        },
    }
    return {
        namespace = "ProjectHoomansConversationSandbox",
        npcID = "sandbox:registry",
        characterUUID = "sandbox-character",
        persistHistory = false,
        portrait = {
            id = "sandbox:registry",
            identitySeed = Selector.Seed(
                context,
                "sandbox_portrait:" .. selectedBlock.id
            ),
            isFemale = false,
            faceOnly = true,
            preferDescriptor = true,
            appearance = {},
            equipment = { worn = {} },
        },
        backgroundID = PNC.Conversation.Backgrounds
            and PNC.Conversation.Backgrounds.Get("twilight") or "twilight",
        theme = PNC.NPCTypePalette
            and PNC.NPCTypePalette.BuildConversationTheme(fakeEntry) or nil,
        context = context,
        extensionParts = extensions,
        start = sandboxCategoryNodeID(selectedBlock.category),
        nodes = nodes,
        lifecycle = {
            begin = function() return {} end,
            finish = function(_, _, _, reason)
                if PNC.Core and PNC.Core.LogInfo then
                    PNC.Core.LogInfo("Conversation sandbox closed reason="
                        .. tostring(reason or "closed"))
                end
            end,
        },
    }
end

function Model.OpenSandbox(blockID, context)
    local definition, reason = Model.BuildSandboxDefinition(blockID, context)
    if not definition then return nil, reason end
    local conversation = PsychopatzCore and PsychopatzCore.Conversation
    if not conversation or not conversation.Open then
        return nil, "conversation_gui_unavailable"
    end
    return conversation.Open(definition), "opened"
end

return Model
