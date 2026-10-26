-- Bounded flow browser/editor seam over the production dialogue registry.
-- Draft validation and registration deliberately use the same Registry that
-- the live semantic policy loads; Python/Tk only presents and edits data.

local FlowEditor = {}
local Registry = require
    "PNC/Semantics/PNC_SemanticDialogueFlowCatalog"

local function capabilityCatalog()
    return PNC.Semantics.CapabilityCatalog
        or require "PNC/Semantics/PNC_SemanticCapabilityCatalog"
end

local function automaticGenerator()
    return PNC.Semantics.AutomaticFlowGenerator
        or require "PNC/Semantics/PNC_SemanticAutomaticFlowGenerator"
end

local function policyCatalog(Values, semanticCatalog)
    local Policy = PNC.Semantics.DialoguePolicy
        or require "PNC/Semantics/PNC_SemanticDialoguePolicy"
    local branches = {}
    local byID = {}
    local templates = type(Policy.ResponseTemplates) == "table"
        and Policy.ResponseTemplates or {}
    local branchID
    local definition
    for branchID, definition in pairs(templates) do
        if type(branchID) == "string" and type(definition) == "table" then
            byID[branchID] = {
                id = branchID,
                kind = "policy_branch",
                owner = "PNC.Semantics.DialoguePolicy",
                route = "DialoguePolicy.Internal.ResolveIntentBranch",
                triggerIDs = {},
                responseTemplate = Values.copy(definition),
            }
        end
    end

    local resolver = Policy.Internal
        and Policy.Internal.ResolveIntentBranch or nil
    if type(resolver) == "function" then
        for _, trigger in ipairs(semanticCatalog.triggers or {}) do
            local frame = type(trigger.frame) == "table"
                and Values.copy(trigger.frame) or {}
            local branch, reason = resolver(frame, {}, {}, nil)
            local row = byID[branch]
            if row then
                row.triggerIDs[#row.triggerIDs + 1] = trigger.id
                row.reason = row.reason or reason
            end
        end
    end

    for _, row in pairs(byID) do
        table.sort(row.triggerIDs)
        branches[#branches + 1] = row
    end
    table.sort(branches, function(left, right)
        return tostring(left.id) < tostring(right.id)
    end)
    return {
        schemaVersion = 1,
        owner = "PNC.Semantics.DialoguePolicy",
        branchCount = #branches,
        branches = branches,
    }
end

local function responsePoolCatalog(Values, responseCatalog)
    local output = {}
    local pools = type(responseCatalog) == "table"
        and responseCatalog.POOLS or {}
    for poolID, pool in pairs(pools) do
        if type(pool) == "table" and type(pool.id) == "string" then
            output[#output + 1] = {
                id = pool.id or tostring(poolID),
                variantCount = type(pool.variants) == "table"
                    and #pool.variants or 0,
            }
        end
    end
    table.sort(output, function(left, right)
        return tostring(left.id) < tostring(right.id)
    end)
    return output
end

local function publicGeneration(values, generation)
    local output = {}
    generation = type(generation) == "table" and generation or {}
    -- The top-level `flows` field already carries the normalized production
    -- registry. Exclude the generator's duplicate flow/response-pool payload
    -- from the bounded Lab envelope while retaining coverage and fingerprints.
    for key, value in pairs(generation) do
        if key ~= "flows" and key ~= "responsePools" then
            output[key] = values.copy(value)
        end
    end
    return output
end

local function catalog(context)
    local Values = context.Values
    local flows = {}
    local CapabilityCatalog = capabilityCatalog()
    if type(CapabilityCatalog.EnsureAutomaticGeneration) == "function" then
        CapabilityCatalog.EnsureAutomaticGeneration()
    end
    local semanticCatalog = CapabilityCatalog.Snapshot()
    local generation = CapabilityCatalog.AutomaticFlowGeneration or {}
    local policy = policyCatalog(Values, semanticCatalog)
    local ResponseCatalog = PNC.Semantics.ResponseCatalog
        or require "PNC/Semantics/PNC_SemanticDialogueResponseCatalog"
    local responsePools = responsePoolCatalog(Values, ResponseCatalog)
    local index
    local flowID
    local flow
    for index, flowID in ipairs(Registry.List()) do
        flow = Registry.Get(flowID)
        if type(flow) == "table" then
            flows[#flows + 1] = Values.copy(flow)
        end
    end
    return {
        ok = true,
        type = "flow_catalog",
        schemaVersion = 1,
        registryRevision = Registry.GetRevision(),
        flowCount = #flows,
        flows = flows,
        factCatalog = PNC.Semantics.EngineFacts
            and PNC.Semantics.EngineFacts.List
            and PNC.Semantics.EngineFacts.List() or {},
        eventCatalog = PNC.Semantics.EngineEvents
            and PNC.Semantics.EngineEvents.ListTypes
            and PNC.Semantics.EngineEvents.ListTypes() or {},
        commandCatalog = CapabilityCatalog.ListCommandActions(),
        actionCatalog = semanticCatalog.actions,
        triggerCatalog = semanticCatalog.triggers,
        conceptCatalog = semanticCatalog.concepts,
        speechActCatalog = semanticCatalog.speechActs,
        semanticCatalog = {
            schemaVersion = semanticCatalog.schemaVersion,
            registryRevision = semanticCatalog.registryRevision,
            actionCount = #semanticCatalog.actions,
            triggerCount = #semanticCatalog.triggers,
            conceptCount = #semanticCatalog.concepts,
            speechActCount = #semanticCatalog.speechActs,
        },
        generation = publicGeneration(Values, generation),
        policyCatalog = policy,
        responsePoolCatalog = responsePools,
        capabilityCoverage = Values.copy(generation.coverage or {}),
    }
end

-- Stable, non-cryptographic registry-content change marker. Source Git
-- SHA/provenance is a separate concept and remains UNKNOWN until verified.
local function stableValue(value, depth)
    depth = depth or 0
    if depth > 16 then return "<bounded-depth>" end
    if type(value) ~= "table" then
        return type(value) .. ":" .. tostring(value)
    end
    local keys = {}
    for key in pairs(value) do
        if type(key) == "string" or type(key) == "number" then
            keys[#keys + 1] = key
        end
    end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    local parts = {}
    for index = 1, #keys do
        local key = keys[index]
        parts[#parts + 1] = tostring(key) .. "="
            .. stableValue(value[key], depth + 1)
    end
    return "{" .. table.concat(parts, ";") .. "}"
end

local function poolFingerprint(pool)
    local Core = require
        "PNC/Semantics/PNC_SemanticDialogueResponseCatalog_Core"
    return "catalog-v1:" .. tostring(Core.hash(stableValue(pool)))
end

local function boundedPlanSummary(plan)
    if type(plan) ~= "table" then return {} end
    local turns = type(plan.turns) == "table" and plan.turns or {}
    local offers = 0
    local segments = 0
    for i = 1, #turns do
        local turn = turns[i]
        if type(turn) == "table" then
            offers = offers + #(type(turn.offers) == "table" and turn.offers or {})
            segments = segments + #(type(turn.segments) == "table"
                and turn.segments or {})
        end
    end
    return {
        kind = plan.kind, dialogueAct = plan.dialogueAct,
        topic = plan.topic, turnCount = #turns,
        segmentCount = segments, offerCount = offers,
        firstTurnID = turns[1] and turns[1].id or nil,
    }
end

-- Lazy, read-only detail for an actual loaded production response pool.
-- An owning source path is intentionally UNKNOWN unless registration itself
-- provides trustworthy provenance; scanning Lua text is not provenance.
function FlowEditor.responsePoolList(context, request)
    request = type(request) == "table" and request or {}
    local offset = tonumber(request.offset) or 0
    local limit = tonumber(request.limit) or 32
    if offset < 0 or offset % 1 ~= 0 or limit < 1
        or limit % 1 ~= 0 or limit > 64 then
        return { ok = false, type = "response_pool_list",
            schemaVersion = 1, error = "invalid_page" }
    end
    local filter = tostring(request.filter or "")
    if #filter > 96 then
        return { ok = false, type = "response_pool_list",
            schemaVersion = 1, error = "invalid_filter" }
    end
    local ResponseCatalog = PNC.Semantics.ResponseCatalog
        or require "PNC/Semantics/PNC_SemanticDialogueResponseCatalog"
    local matches = {}
    for id, pool in pairs(ResponseCatalog.POOLS or {}) do
        if filter == "" or string.find(string.lower(id),
            string.lower(filter), 1, true) then
            matches[#matches + 1] = {
                id = id, variantCount = #pool.variants,
            }
        end
    end
    table.sort(matches, function(a, b) return a.id < b.id end)
    local page = {}
    for i = offset + 1, math.min(#matches, offset + limit) do
        page[#page + 1] = matches[i]
    end
    return { ok = true, type = "response_pool_list",
        schemaVersion = 1, total = #matches,
        registryRevision = ResponseCatalog.REVISION or 0, offset = offset,
        limit = limit, hasMore = offset + #page < #matches,
        pools = page }
end

-- This deliberately consumes selection history only inside the disposable
-- developer worker; unlike EXPLAIN, it is not a read-only inspection command.
function FlowEditor.sampleResponseSelection(context, request)
    if type(request) ~= "table" or type(request.poolID) ~= "string"
        or #request.poolID == 0 or #request.poolID > 96
        or type(request.context or {}) ~= "table" then
        return { ok = false, type = "response_selection_sample",
            schemaVersion = 1, error = "invalid_request" }
    end
    local ResponseCatalog = PNC.Semantics.ResponseCatalog
        or require "PNC/Semantics/PNC_SemanticDialogueResponseCatalog"
    local selected, indexOrReason = ResponseCatalog.Select(
        request.poolID, request.context or {}, request.salt
    )
    if not selected then
        return { ok = false, type = "response_selection_sample",
            schemaVersion = 1, error = indexOrReason }
    end
    return {
        ok = true, type = "response_selection_sample", schemaVersion = 1,
        poolID = request.poolID, selectedID = selected.id,
        selectedIndex = indexOrReason, mutatedFixtureHistory = true,
    }
end

function FlowEditor.explainResponseSelection(context, request)
    if type(request) ~= "table" or type(request.poolID) ~= "string"
        or #request.poolID == 0 or #request.poolID > 96 then
        return { ok = false, type = "response_selection_explanation",
            schemaVersion = 1, error = "invalid_pool_id" }
    end
    if type(request.salt) == "string" and #request.salt > 128 then
        return { ok = false, schemaVersion = 1, error = "invalid_salt" }
    end
    local projected = request.context or {}
    if type(projected) ~= "table" then
        return { ok = false, type = "response_selection_explanation",
            schemaVersion = 1, error = "invalid_context" }
    end
    local ResponseCatalog = PNC.Semantics.ResponseCatalog
        or require "PNC/Semantics/PNC_SemanticDialogueResponseCatalog"
    local result, reason = ResponseCatalog.ExplainSelection(
        request.poolID, projected, request.salt
    )
    if not result then
        return { ok = false, type = "response_selection_explanation",
            schemaVersion = 1, error = reason }
    end
    return result
end

function FlowEditor.responsePoolDetail(context, request)
    if type(request) ~= "table" or type(request.poolID) ~= "string"
        or #request.poolID == 0 or #request.poolID > 96
    then
        return { ok = false, type = "response_pool_detail",
            schemaVersion = 1, error = "invalid_pool_id" }
    end
    local ResponseCatalog = PNC.Semantics.ResponseCatalog
        or require "PNC/Semantics/PNC_SemanticDialogueResponseCatalog"
    local pool = ResponseCatalog.Get(request.poolID)
    if not pool then
        return { ok = false, type = "response_pool_detail",
            schemaVersion = 1, error = "response_pool_unavailable" }
    end
    local offset = tonumber(request.offset) or 0
    local limit = tonumber(request.limit) or 8
    if offset < 0 or offset % 1 ~= 0 or limit < 1
        or limit % 1 ~= 0 or limit > 16 then
        return { ok = false, type = "response_pool_detail",
            schemaVersion = 1, error = "invalid_page" }
    end
    local variants = {}
    for i = offset + 1, math.min(#pool.variants, offset + limit) do
        local v = pool.variants[i]
        variants[#variants + 1] = {
            id = v.id, templateID = v.templateID, fallback = v.fallback,
            when = context.Values.copy(v.when or {}), priority = v.priority,
            planSummary = boundedPlanSummary(v.plan),
            translationArgs = context.Values.copy(v.translationArgs or {}),
            dialogueAct = v.dialogueAct, topic = v.topic,
            groundedFactRefs = context.Values.copy(v.groundedFactRefs or {}),
            sourceKind = "UNKNOWN", sourcePath = "UNKNOWN",
        }
    end
    return {
        ok = true, type = "response_pool_detail", schemaVersion = 1,
        poolID = pool.id, variantCount = #pool.variants,
        registryRevision = ResponseCatalog.REVISION or 0,
        contentFingerprint = poolFingerprint(pool),
        offset = offset, limit = limit, hasMore = offset + #variants < #pool.variants,
        variants = variants, sourceKind = "UNKNOWN", sourcePath = "UNKNOWN",
    }
end

function FlowEditor.catalog(context)
    return catalog(context)
end

function FlowEditor.validate(context, definition)
    local Values = context.Values
    local valid, normalized = Registry.Validate(definition)
    if not valid then
        return {
            ok = true,
            type = "flow_validation",
            schemaVersion = 1,
            valid = false,
            reason = tostring(normalized),
        }
    end
    return {
        ok = true,
        type = "flow_validation",
        schemaVersion = 1,
        valid = true,
        definition = Values.copy(normalized),
    }
end

function FlowEditor.register(context, definition)
    local Values = context.Values
    local valid, normalized = Registry.Validate(definition)
    if not valid then
        return {
            ok = true,
            type = "flow_registration",
            schemaVersion = 1,
            registered = false,
            valid = false,
            reason = tostring(normalized),
        }
    end
    local registered, result = Registry.Register(definition)
    if not registered then
        return {
            ok = true,
            type = "flow_registration",
            schemaVersion = 1,
            registered = false,
            valid = true,
            reason = tostring(result),
        }
    end
    local response = catalog(context)
    response.type = "flow_registration"
    response.registered = true
    response.valid = true
    response.definition = Values.copy(result)
    return response
end

function FlowEditor.generate(context)
    local Values = context.Values
    local CapabilityCatalog = capabilityCatalog()
    local artifact = automaticGenerator().Regenerate(CapabilityCatalog)
    CapabilityCatalog.AutomaticFlowGeneration = artifact
    local response = catalog(context)
    response.type = "flow_generation"
    response.generated = true
    response.generation = publicGeneration(Values, artifact)
    response.capabilityCoverage = Values.copy(artifact.coverage or {})
    return response
end

return FlowEditor
