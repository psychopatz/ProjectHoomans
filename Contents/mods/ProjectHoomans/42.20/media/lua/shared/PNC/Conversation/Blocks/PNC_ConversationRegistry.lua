-- Build 42.20 conversation category/block registry.
-- Conversation content is data-only so the same definitions can be loaded by
-- clients, dedicated servers, and other mods without trusting client state.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Registry = PNC.Conversation.Registry or {}
PNC.Conversation.Registry = Registry

Registry.API_VERSION = 1
Registry.SCHEMA_VERSION = 1
Registry.categories = Registry.categories or {}
Registry.blocks = Registry.blocks or {}
Registry.invalidCategories = Registry.invalidCategories or {}
Registry.invalidBlocks = Registry.invalidBlocks or {}
Registry.conditionHandlers = Registry.conditionHandlers or {}
Registry.effectHandlers = Registry.effectHandlers or {}
Registry.revision = tonumber(Registry.revision) or 0

local function copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local output = {}
    seen[value] = output
    for key, child in pairs(value) do
        output[copy(key, seen)] = copy(child, seen)
    end
    return output
end

local function validID(value)
    return type(value) == "string"
        and #value >= 3
        and #value <= 128
        and string.match(value, "^[%w_.-]+:[%w_.-]+$") ~= nil
end

local VALID_AUDIENCES = {
    hostile = true,
    neutral = true,
    member = true,
    special = true,
    shared = true,
}

local function serializable(value, seen, path)
    local kind = type(value)
    if kind == "nil" or kind == "string" or kind == "boolean" then
        return true
    end
    if kind == "number" then
        if value ~= value or value == math.huge or value == -math.huge then
            return false, tostring(path) .. " contains a non-finite number"
        end
        return true
    end
    if kind ~= "table" then
        return false, tostring(path) .. " contains " .. kind
    end
    seen = seen or {}
    if seen[value] then return false, tostring(path) .. " contains a cycle" end
    seen[value] = true
    for key, child in pairs(value) do
        local keyType = type(key)
        if keyType ~= "string" and keyType ~= "number" then
            seen[value] = nil
            return false, tostring(path) .. " contains an unsafe key"
        end
        local ok, reason = serializable(
            child,
            seen,
            tostring(path) .. "." .. tostring(key)
        )
        if not ok then
            seen[value] = nil
            return false, reason
        end
    end
    seen[value] = nil
    return true
end

local function addError(errors, message)
    errors[#errors + 1] = tostring(message)
end

local function validateTextSource(source, errors, path)
    path = path or "textSource"
    if type(source) ~= "table" then
        addError(errors, path .. " is required")
        return
    end
    if type(source.modID) ~= "string" or source.modID == "" then
        addError(errors, path .. ".modID is required")
    end
    if type(source.pathPattern) ~= "string"
        or not string.find(source.pathPattern, "{language}", 1, true)
        or string.find(source.pathPattern, "..", 1, true)
        or string.sub(source.pathPattern or "", 1, 1) == "/"
        or string.find(source.pathPattern or "", "\\", 1, true)
    then
        addError(errors, path .. ".pathPattern must be relative and contain {language}")
    end
    if type(source.domain) ~= "string" or source.domain == "" then
        addError(errors, path .. ".domain is required")
    end
end

local function validateRepeat(policy, errors, path)
    if policy == nil then return end
    if type(policy) ~= "table" then
        addError(errors, path .. " must be a table")
        return
    end
    local scope = policy.scope or "pair"
    if scope ~= "pair" and scope ~= "character"
        and scope ~= "npc" and scope ~= "world"
    then addError(errors, path .. ".scope is invalid") end
    if policy.cooldownHours ~= nil
        and (tonumber(policy.cooldownHours) or -1) < 0
    then addError(errors, path .. ".cooldownHours must be non-negative") end
    if policy.maxUses ~= nil
        and (tonumber(policy.maxUses) or 0) < 1
    then addError(errors, path .. ".maxUses must be positive") end
end

local function validateGates(gates, errors, path)
    if gates == nil then return end
    if type(gates) ~= "table" then
        addError(errors, path .. " must be a table")
        return
    end
    for index, gate in ipairs(gates) do
        local gatePath = path .. "[" .. tostring(index) .. "]"
        if type(gate) ~= "table" or type(gate.type) ~= "string" then
            addError(errors, gatePath .. " requires a type")
        elseif gate.type == "all" or gate.type == "any" then
            if type(gate.gates) ~= "table" or #gate.gates == 0 then
                addError(errors, gatePath .. ".gates must contain conditions")
            else
                validateGates(gate.gates, errors, gatePath .. ".gates")
            end
        elseif gate.type == "not" then
            if type(gate.gate) ~= "table" then
                addError(errors, gatePath .. ".gate is required")
            else
                validateGates({ gate.gate }, errors, gatePath .. ".gate")
            end
        elseif not Registry.conditionHandlers[gate.type] then
            addError(errors, gatePath .. " uses unknown condition " .. gate.type)
        end
    end
end

local function validateEffects(effects, errors, path)
    if effects == nil then return end
    if type(effects) ~= "table" then
        addError(errors, path .. " must be a table")
        return
    end
    for index, effect in ipairs(effects) do
        local effectPath = path .. "[" .. tostring(index) .. "]"
        if type(effect) ~= "table" or type(effect.type) ~= "string" then
            addError(errors, effectPath .. " requires a type")
        elseif not Registry.effectHandlers[effect.type] then
            addError(errors, effectPath .. " uses unknown effect " .. effect.type)
        end
    end
end

function Registry.ValidateCategory(id, definition)
    local errors = {}
    local ok, reason = serializable(definition, {}, "category")
    if not validID(id) then addError(errors, "category id must be namespaced") end
    if not ok then addError(errors, reason) end
    if type(definition) ~= "table" then
        addError(errors, "category definition is required")
        return false, errors
    end
    if type(definition.ownerModID) ~= "string"
        or definition.ownerModID == ""
    then addError(errors, "ownerModID is required") end
    validateTextSource(definition.textSource, errors)
    if type(definition.labelKey) ~= "string" or definition.labelKey == "" then
        addError(errors, "labelKey is required")
    end
    validateGates(definition.gates, errors, "gates")
    return #errors == 0, errors
end

function Registry.ValidateBlock(id, definition)
    if definition == nil and type(id) == "table" then
        definition = id
        id = definition.id
    end
    local errors = {}
    local ok, reason = serializable(definition, {}, "block")
    if not validID(id) then addError(errors, "block id must be namespaced") end
    if not ok then addError(errors, reason) end
    if type(definition) ~= "table" then
        addError(errors, "block definition is required")
        return false, errors
    end
    if tonumber(definition.schemaVersion) ~= Registry.SCHEMA_VERSION then
        addError(errors, "unsupported schemaVersion")
    end
    if type(definition.ownerModID) ~= "string"
        or definition.ownerModID == ""
    then addError(errors, "ownerModID is required") end
    if not validID(definition.category)
        or not Registry.categories[definition.category]
    then addError(errors, "registered category is required") end
    validateTextSource(definition.textSource, errors)
    validateGates(definition.gates, errors, "gates")
    validateRepeat(definition["repeat"], errors, "repeat")
    if type(definition.audiences) ~= "table" or #definition.audiences == 0 then
        addError(errors, "audiences must contain at least one audience")
    else
        local audienceIDs = {}
        for index, audience in ipairs(definition.audiences) do
            if not VALID_AUDIENCES[audience] then
                addError(errors, "audiences[" .. tostring(index) .. "] is invalid")
            elseif audienceIDs[audience] then
                addError(errors, "audiences contains duplicate " .. audience)
            end
            audienceIDs[audience] = true
        end
    end
    if type(definition.entryNode) ~= "string" or definition.entryNode == "" then
        addError(errors, "entryNode is required")
    end
    if type(definition.nodes) ~= "table" then
        addError(errors, "nodes are required")
    elseif not definition.nodes[definition.entryNode] then
        addError(errors, "entryNode does not exist")
    else
        local nodeIDs = {}
        for nodeID, node in pairs(definition.nodes) do
            local nodePath = "nodes." .. tostring(nodeID)
            if type(nodeID) ~= "string" or nodeID == "" then
                addError(errors, nodePath .. " has an invalid id")
            elseif nodeIDs[nodeID] then
                addError(errors, nodePath .. " is duplicated")
            else
                nodeIDs[nodeID] = true
            end
            if type(node) ~= "table" then
                addError(errors, nodePath .. " must be a table")
            else
                if node.textKey ~= nil and type(node.textKey) ~= "string" then
                    addError(errors, nodePath .. ".textKey must be a string")
                end
                if node.textKeys ~= nil then
                    if type(node.textKeys) ~= "table" or #node.textKeys == 0 then
                        addError(errors, nodePath .. ".textKeys must contain keys")
                    else
                        for textIndex, textKey in ipairs(node.textKeys) do
                            if type(textKey) ~= "string" or textKey == "" then
                                addError(errors, nodePath .. ".textKeys["
                                    .. tostring(textIndex) .. "] is invalid")
                            end
                        end
                    end
                end
                if node.textKey == nil and node.textKeys == nil then
                    addError(errors, nodePath .. " requires textKey or textKeys")
                end
                validateGates(node.gates, errors, nodePath .. ".gates")
                local choiceIDs = {}
                local choices = {}
                if node.choices ~= nil and type(node.choices) ~= "table" then
                    addError(errors, nodePath .. ".choices must be a table")
                elseif type(node.choices) == "table" then
                    choices = node.choices
                end
                for choiceIndex, choice in ipairs(choices) do
                    local choicePath = nodePath .. ".choices["
                        .. tostring(choiceIndex) .. "]"
                    if type(choice) ~= "table"
                        or type(choice.id) ~= "string"
                        or choice.id == ""
                    then
                        addError(errors, choicePath .. " requires an id")
                    else
                        if choiceIDs[choice.id] then
                            addError(errors, choicePath .. ".id is duplicated")
                        end
                        choiceIDs[choice.id] = true
                        if type(choice.textKey) ~= "string"
                            or choice.textKey == ""
                        then addError(errors, choicePath .. ".textKey is required") end
                        if choice.lockedMode ~= nil
                            and choice.lockedMode ~= "hidden"
                            and choice.lockedMode ~= "disabled"
                        then addError(errors, choicePath .. ".lockedMode is invalid") end
                        if choice.lockedMode == "disabled"
                            and (type(choice.lockedReasonKey) ~= "string"
                                or choice.lockedReasonKey == "")
                        then
                            addError(errors,
                                choicePath
                                    .. ".lockedReasonKey is required when disabled")
                        end
                        validateGates(choice.gates, errors, choicePath .. ".gates")
                        validateRepeat(choice["repeat"], errors, choicePath .. ".repeat")
                        if type(choice.outcomes) ~= "table"
                            or #choice.outcomes == 0
                        then addError(errors, choicePath .. ".outcomes are required") end
                        local outcomeIDs = {}
                        local outcomes = type(choice.outcomes) == "table"
                            and choice.outcomes or {}
                        for outcomeIndex, outcome in ipairs(outcomes) do
                            local outcomePath = choicePath .. ".outcomes["
                                .. tostring(outcomeIndex) .. "]"
                            if type(outcome) ~= "table"
                                or type(outcome.id) ~= "string"
                                or outcome.id == ""
                            then addError(errors, outcomePath .. " requires an id") end
                            if type(outcome) == "table"
                                and type(outcome.id) == "string"
                            then
                                if outcomeIDs[outcome.id] then
                                    addError(errors, outcomePath .. ".id is duplicated")
                                end
                                outcomeIDs[outcome.id] = true
                            end
                            if (tonumber(outcome.weight) or 0) <= 0 then
                                addError(errors, outcomePath .. ".weight must be positive")
                            end
                            if type(outcome.responseKey) ~= "string"
                                or outcome.responseKey == ""
                            then
                                addError(errors,
                                    outcomePath .. ".responseKey is required")
                            end
                            if outcome.next == nil and outcome.close ~= true then
                                addError(errors,
                                    outcomePath .. " requires next or close")
                            end
                            if outcome.next ~= nil
                                and outcome.next ~= "$root"
                                and not definition.nodes[outcome.next]
                            then addError(errors, outcomePath .. ".next is dangling") end
                            if outcome.next ~= nil and outcome.close == true then
                                addError(errors, outcomePath .. " cannot both next and close")
                            end
                            validateGates(outcome.gates, errors, outcomePath .. ".gates")
                            validateEffects(outcome.effects, errors, outcomePath .. ".effects")
                        end
                    end
                end
            end
        end
    end
    return #errors == 0, errors
end

local function bumpRevision()
    Registry.revision = Registry.revision + 1
end

function Registry.RegisterCategory(id, definition)
    id = tostring(id or "")
    if Registry.categories[id] or Registry.invalidCategories[id] then
        return false, { "duplicate category id" }
    end
    local valid, errors = Registry.ValidateCategory(id, definition)
    if not valid then
        Registry.invalidCategories[id] = {
            id = id,
            definition = type(definition) == "table" and copy(definition) or nil,
            errors = copy(errors),
        }
        bumpRevision()
        return false, copy(errors)
    end
    local normalized = copy(definition)
    normalized.id = id
    normalized.order = tonumber(normalized.order) or 1000
    Registry.categories[id] = normalized
    bumpRevision()
    return true, copy(normalized)
end

function Registry.UnregisterCategory(id)
    id = tostring(id or "")
    if not Registry.categories[id] and not Registry.invalidCategories[id] then
        return false
    end
    for _, block in pairs(Registry.blocks) do
        if block.category == id then return false, "category_in_use" end
    end
    Registry.categories[id] = nil
    Registry.invalidCategories[id] = nil
    bumpRevision()
    return true
end

function Registry.RegisterBlock(id, definition)
    id = tostring(id or "")
    if Registry.blocks[id] or Registry.invalidBlocks[id] then
        return false, { "duplicate block id" }
    end
    local valid, errors = Registry.ValidateBlock(id, definition)
    if not valid then
        Registry.invalidBlocks[id] = {
            id = id,
            definition = type(definition) == "table" and copy(definition) or nil,
            errors = copy(errors),
        }
        bumpRevision()
        return false, copy(errors)
    end
    local normalized = copy(definition)
    normalized.id = id
    normalized.priority = tonumber(normalized.priority) or 0
    normalized.weight = math.max(1, tonumber(normalized.weight) or 1)
    Registry.blocks[id] = normalized
    bumpRevision()
    return true, copy(normalized)
end

function Registry.UnregisterBlock(id)
    id = tostring(id or "")
    if not Registry.blocks[id] and not Registry.invalidBlocks[id] then return false end
    Registry.blocks[id] = nil
    Registry.invalidBlocks[id] = nil
    bumpRevision()
    return true
end

function Registry.GetCategory(id)
    local value = Registry.categories[tostring(id or "")]
    return value and copy(value) or nil
end

function Registry.GetBlock(id)
    local value = Registry.blocks[tostring(id or "")]
    return value and copy(value) or nil
end

local function matchesFilter(value, filters)
    filters = type(filters) == "table" and filters or {}
    if filters.ownerModID and value.ownerModID ~= filters.ownerModID then return false end
    if filters.category and value.category ~= filters.category then return false end
    if filters.audience then
        local found = false
        for _, audience in ipairs(value.audiences or {}) do
            if audience == filters.audience then found = true break end
        end
        if not found then return false end
    end
    return true
end

function Registry.ListCategories(options)
    options = type(options) == "table" and options or {}
    local output = {}
    for _, category in pairs(Registry.categories) do
        if matchesFilter(category, options) then output[#output + 1] = copy(category) end
    end
    if options.includeInvalid == true then
        for _, entry in pairs(Registry.invalidCategories) do
            output[#output + 1] = copy(entry)
        end
    end
    table.sort(output, function(first, second)
        local firstOrder = tonumber(first.order) or 1000
        local secondOrder = tonumber(second.order) or 1000
        if firstOrder ~= secondOrder then return firstOrder < secondOrder end
        return tostring(first.id) < tostring(second.id)
    end)
    return output
end

function Registry.ListBlocks(options)
    options = type(options) == "table" and options or {}
    local output = {}
    for _, block in pairs(Registry.blocks) do
        if matchesFilter(block, options) then output[#output + 1] = copy(block) end
    end
    if options.includeInvalid == true then
        for _, entry in pairs(Registry.invalidBlocks) do
            output[#output + 1] = copy(entry)
        end
    end
    table.sort(output, function(first, second)
        local firstPriority = tonumber(first.priority) or 0
        local secondPriority = tonumber(second.priority) or 0
        if firstPriority ~= secondPriority then return firstPriority > secondPriority end
        return tostring(first.id) < tostring(second.id)
    end)
    return output
end

function Registry.RegisterConditionHandler(id, handler)
    id = tostring(id or "")
    if not validID(id) or type(handler) ~= "table"
        or type(handler.evaluate) ~= "function"
        or Registry.conditionHandlers[id]
    then return false end
    Registry.conditionHandlers[id] = copy(handler)
    bumpRevision()
    return true
end

function Registry.UnregisterConditionHandler(id)
    id = tostring(id or "")
    if not Registry.conditionHandlers[id] then return false end
    Registry.conditionHandlers[id] = nil
    bumpRevision()
    return true
end

function Registry.RegisterEffectHandler(id, handler)
    id = tostring(id or "")
    if not validID(id) or type(handler) ~= "table"
        or type(handler.validate) ~= "function"
        or type(handler.apply) ~= "function"
        or type(handler.simulate) ~= "function"
        or Registry.effectHandlers[id]
    then return false end
    Registry.effectHandlers[id] = copy(handler)
    bumpRevision()
    return true
end

function Registry.UnregisterEffectHandler(id)
    id = tostring(id or "")
    if not Registry.effectHandlers[id] then return false end
    Registry.effectHandlers[id] = nil
    bumpRevision()
    return true
end

local function hashText(value, seed)
    local total = tonumber(seed) or 5381
    value = tostring(value or "")
    for index = 1, #value do
        total = (total * 33 + string.byte(value, index)) % 2147483647
    end
    return total
end

function Registry.GetFingerprint()
    local ids = {}
    local function appendValue(parts, value)
        local kind = type(value)
        if kind ~= "table" then
            parts[#parts + 1] = kind .. ":" .. tostring(value)
            return
        end
        local keys = {}
        for key in pairs(value) do keys[#keys + 1] = key end
        table.sort(keys, function(a, b)
            return type(a) .. ":" .. tostring(a) < type(b) .. ":" .. tostring(b)
        end)
        parts[#parts + 1] = "{"
        for _, key in ipairs(keys) do
            appendValue(parts, key)
            appendValue(parts, value[key])
        end
        parts[#parts + 1] = "}"
    end
    for id, category in pairs(Registry.categories) do
        local parts = { "c:", id }
        appendValue(parts, category)
        ids[#ids + 1] = table.concat(parts, "|")
    end
    for id, block in pairs(Registry.blocks) do
        local parts = { "b:", id }
        appendValue(parts, block)
        ids[#ids + 1] = table.concat(parts, "|")
    end
    for id in pairs(Registry.conditionHandlers) do ids[#ids + 1] = "g:" .. id end
    for id in pairs(Registry.effectHandlers) do ids[#ids + 1] = "e:" .. id end
    table.sort(ids)
    local value = Registry.API_VERSION
    for _, id in ipairs(ids) do value = hashText(id, value) end
    return tostring(value)
end

function Registry.CollectTextKeys(block)
    local keys = {}
    local seen = {}
    local function add(value)
        if type(value) == "string" and value ~= "" and not seen[value] then
            seen[value] = true
            keys[#keys + 1] = value
        end
    end
    for _, node in pairs(block and block.nodes or {}) do
        add(node.textKey)
        for _, textKey in ipairs(node.textKeys or {}) do add(textKey) end
        for _, choice in ipairs(node.choices or {}) do
            add(choice.textKey)
            add(choice.lockedReasonKey)
            for _, outcome in ipairs(choice.outcomes or {}) do
                add(outcome.responseKey)
            end
        end
    end
    table.sort(keys)
    return keys
end

Registry.Copy = copy
Registry.IsSerializable = serializable

return Registry
