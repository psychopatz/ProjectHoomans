-- Read-only semantic fact providers for dialogue questions.
--
-- Facts are observations supplied by an owning subsystem. This registry never
-- searches the world, mutates simulation state, or chooses a gameplay action.
-- It gives deterministic dialogue a stable seam for roster, knowledge,
-- perception, and future NPC-cognition providers.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Facts = PNC.Semantics.DialogueFacts or {}
PNC.Semantics.DialogueFacts = Facts

Facts.VERSION = 1
Facts.MAX_PROVIDERS = 32
Facts.MAX_FACT_DEPTH = 4
Facts.MAX_FACT_FIELDS = 32
Facts.PROVIDERS = Facts.PROVIDERS or {}
Facts.PROVIDERS_BY_ID = Facts.PROVIDERS_BY_ID or {}

local VALID_STATUS = {
    known = true,
    unknown = true,
    ambiguous = true,
}

local function finite(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return nil
    end
    return value
end

local function clamp(value)
    value = finite(value) or 0
    return math.max(0, math.min(1, value))
end

-- Facts may be handed to response generation or optional LLM context. Keep
-- provider failures from leaking engine objects, functions, or unbounded data.
local function safeCopy(value, depth, budget)
    local valueType = type(value)
    local output
    local key
    local item
    local copied
    local valid
    if value == nil then return nil, true end
    if valueType == "string" then
        if #value > 128 or string.find(value, "%c") then
            return nil, false
        end
        return value, true
    end
    if valueType == "boolean" then return value, true end
    if valueType == "number" then
        value = finite(value)
        return value, value ~= nil
    end
    if valueType ~= "table" or getmetatable(value) ~= nil then
        return nil, false
    end
    depth = tonumber(depth) or 0
    budget = budget or { count = 0, seen = {} }
    if depth >= Facts.MAX_FACT_DEPTH or budget.seen[value] then
        return nil, false
    end
    budget.seen[value] = true
    output = {}
    for key, item in pairs(value) do
        budget.count = budget.count + 1
        if budget.count > Facts.MAX_FACT_FIELDS
            or (type(key) ~= "string" and type(key) ~= "number")
        then
            budget.seen[value] = nil
            return nil, false
        end
        copied, valid = safeCopy(key, depth + 1, budget)
        if not valid then
            budget.seen[value] = nil
            return nil, false
        end
        local safeItem, itemValid = safeCopy(item, depth + 1, budget)
        if not itemValid then
            budget.seen[value] = nil
            return nil, false
        end
        output[copied] = safeItem
    end
    budget.seen[value] = nil
    return output, true
end

local function providerSupports(provider, subject)
    local subjects = provider and provider.subjects
    if type(subjects) ~= "table" then return true end
    return subjects[subject] == true
end

local function sortProviders()
    table.sort(Facts.PROVIDERS, function(left, right)
        local leftPriority = tonumber(left.priority) or 0
        local rightPriority = tonumber(right.priority) or 0
        if leftPriority == rightPriority then return left.id < right.id end
        return leftPriority > rightPriority
    end)
end

local function normalizeFact(result, subject, providerID)
    local output
    local key
    local value
    local status
    if type(result) ~= "table" then return nil end
    status = tostring(result.status or "")
    if status == "" then
        status = result.known == true and "known" or "unknown"
    end
    if not VALID_STATUS[status] then return nil end
    output = {
        schemaVersion = Facts.VERSION,
        subject = subject,
        status = status,
        provider = providerID,
        confidence = status == "known" and .90 or 0,
    }
    for key, value in pairs(result) do
        if key ~= "provider" and key ~= "schemaVersion"
            and key ~= "subject" and key ~= "status"
        then
            local safeValue, valid = safeCopy(value)
            if valid then output[key] = safeValue end
        end
    end
    output.confidence = clamp(output.confidence)
    return output
end

function Facts.RegisterProvider(id, provider, priority)
    local existing
    local entry
    local index
    id = tostring(id or "")
    if id == "" or #id > 96 or string.find(id, "[^%w_%.%-]")
        or type(provider) ~= "table"
        or type(provider.Resolve) ~= "function"
    then
        return false, "invalid_fact_provider"
    end
    existing = Facts.PROVIDERS_BY_ID[id]
    entry = {
        id = id,
        provider = provider,
        priority = tonumber(priority or provider.priority) or 0,
        subjects = provider.subjects,
    }
    Facts.PROVIDERS_BY_ID[id] = entry
    if existing then
        for index = 1, #Facts.PROVIDERS do
            if Facts.PROVIDERS[index] == existing then
                Facts.PROVIDERS[index] = entry
                sortProviders()
                return true, entry
            end
        end
    end
    if #Facts.PROVIDERS >= Facts.MAX_PROVIDERS then
        Facts.PROVIDERS_BY_ID[id] = existing
        return false, "fact_provider_limit"
    end
    Facts.PROVIDERS[#Facts.PROVIDERS + 1] = entry
    sortProviders()
    return true, entry
end

function Facts.GetProvider(id)
    local entry = Facts.PROVIDERS_BY_ID[tostring(id or "")]
    return entry and entry.provider or nil
end

function Facts.ListProviders()
    local output = {}
    for index = 1, #Facts.PROVIDERS do
        local entry = Facts.PROVIDERS[index]
        output[index] = {
            id = entry.id,
            priority = entry.priority,
            subjects = entry.subjects,
        }
    end
    return output
end

function Facts.Resolve(ir, state, context, options)
    local subject
    local lastReason
    local index
    local entry
    local ok
    local result
    local reason
    if type(ir) ~= "table" then return nil, "invalid_ir" end
    subject = tostring(ir.subject or "")
    if subject == "" then return nil, "subject_required" end
    for index = 1, #Facts.PROVIDERS do
        entry = Facts.PROVIDERS[index]
        if providerSupports(entry, subject) then
            ok, result, reason = pcall(
                entry.provider.Resolve,
                ir,
                state,
                context,
                options
            )
            if ok and type(result) == "table" then
                local normalized = normalizeFact(result, subject, entry.id)
                if normalized then return normalized end
                lastReason = "invalid_fact"
            elseif not ok then
                lastReason = "fact_provider_failed"
            elseif reason then
                lastReason = tostring(reason)
            end
        end
    end
    return {
        schemaVersion = Facts.VERSION,
        subject = subject,
        status = "unknown",
        provider = nil,
        confidence = 0,
        reason = lastReason or "fact_unavailable",
    }, lastReason or "fact_unavailable"
end

function Facts.Annotate(ir, state, context, options)
    local fact
    local reason
    local subject
    local diagnostics
    if type(ir) ~= "table"
        or (ir.intent ~= "QUESTION" and ir.speechAct ~= "QUESTION")
    then
        return ir, nil
    end
    subject = tostring(ir.subject or "")
    if subject == "" then return ir, "subject_required" end
    fact, reason = Facts.Resolve(ir, state, context, options)
    if not fact then return ir, reason end
    ir.extensions = type(ir.extensions) == "table" and ir.extensions or {}
    ir.extensions.facts = type(ir.extensions.facts) == "table"
        and ir.extensions.facts or {}
    ir.extensions.facts[subject] = fact
    diagnostics = type(ir.diagnostics) == "table" and ir.diagnostics or {}
    diagnostics.factSubject = subject
    diagnostics.factStatus = fact.status
    diagnostics.factProvider = fact.provider
    diagnostics.factReason = fact.reason or reason
    ir.diagnostics = diagnostics
    ir.provenance = type(ir.provenance) == "table" and ir.provenance or {}
    ir.provenance.factResolver = fact.provider or "none"
    return ir, fact
end

-- A cognition or test harness can supply a compact fact projection without
-- coupling the generic registry to a particular memory implementation.
Facts.RegisterProvider("context_projection", {
    priority = 200,
    Resolve = function(ir, state, context)
        local values = type(context) == "table"
            and context.semanticFactValues or nil
        local subject = ir and tostring(ir.subject or "") or ""
        local value
        local target
        local targetID
        if type(values) ~= "table" then return nil end
        value = values[subject]
        target = ir and ir.target or nil
        targetID = type(target) == "table" and target.id or nil
        if type(value) == "table"
            and value.targetID ~= nil
            and tostring(value.targetID) ~= tostring(targetID or "")
        then
            return nil, "fact_target_mismatch"
        end
        return type(value) == "table" and value or nil
    end,
})

return Facts
