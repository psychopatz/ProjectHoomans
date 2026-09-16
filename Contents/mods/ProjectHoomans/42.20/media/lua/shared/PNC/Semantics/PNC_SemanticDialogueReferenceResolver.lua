-- Conversation-local reference resolution for the hybrid semantic layer.
--
-- This module resolves discourse references such as "this", "it", and
-- "him" against bounded semantic dialogue state. It deliberately does not
-- search the world, inspect inventories, or execute gameplay actions. A
-- future entity resolver can enrich the same IR after this small step.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Semantic = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local IR = Semantic.IR
local EntityResolver = PNC.Semantics.EntityResolver
if type(EntityResolver) ~= "table" then
    local loaded = require "PNC/Semantics/PNC_SemanticEntityResolver"
    EntityResolver = type(loaded) == "table" and loaded or nil
end
local Resolver = PNC.Semantics.DialogueReferenceResolver or {}
PNC.Semantics.DialogueReferenceResolver = Resolver

Resolver.VERSION = 1
Resolver.MAX_DIAGNOSTIC_REFERENCES = 8

local ENTITY_FIELDS = {
    "actor",
    "recipient",
    "target",
    "object",
    "source",
    "destination",
}

local function isReference(value)
    return type(value) == "table"
        and type(value.reference) == "string"
        and value.reference ~= ""
end

local function appendBounded(list, value)
    if type(list) ~= "table" or type(value) ~= "table" then return end
    if #list < Resolver.MAX_DIAGNOSTIC_REFERENCES then
        list[#list + 1] = value
    end
end

local function hasUnresolved(value, depth)
    if type(value) ~= "table" then return false end
    depth = tonumber(depth) or 0
    if depth >= 8 then return false end
    if value.unresolved == true then return true end
    for _, child in pairs(value) do
        if type(child) == "table" and hasUnresolved(child, depth + 1) then
            return true
        end
    end
    return false
end

local function unresolvedEntity(output)
    local index
    local field
    for index = 1, #ENTITY_FIELDS do
        field = ENTITY_FIELDS[index]
        if hasUnresolved(output[field]) then return true end
    end
    return false
end

local function resolveField(output, field, state, diagnostics)
    local value = output[field]
    if not isReference(value) then return false end

    diagnostics.contextResolutionAttempted = true
    local resolved
    local reason
    local ok = false
    if state and type(state.ResolveReference) == "function" then
        ok, resolved, reason = pcall(
            state.ResolveReference,
            state,
            value
        )
    else
        reason = "state_unavailable"
    end

    if ok and type(resolved) == "table" then
        output[field] = resolved
        diagnostics.contextResolved = true
        appendBounded(diagnostics.contextResolvedReferences, {
            field = field,
            reference = value.reference,
            reason = reason,
        })
        return true
    end

    appendBounded(diagnostics.contextUnresolvedReferences, {
        field = field,
        reference = value.reference,
        reason = reason or "unresolved_reference",
    })
    return false
end

local function resolveEntityField(output, field, index, diagnostics)
    local value = output[field]
    if type(value) ~= "table"
        or value.unresolved ~= true
        or value.reference ~= nil
    then
        return false
    end

    diagnostics.entityResolutionAttempted = true
    if not EntityResolver
        or type(EntityResolver.Resolve) ~= "function"
    then
        appendBounded(diagnostics.entityResolutionFailures, {
            field = field,
            value = value.value or value.text,
            reason = "entity_resolver_unavailable",
        })
        return false
    end

    local resolved, reason, candidates = EntityResolver.Resolve(value, index)
    if type(resolved) == "table" then
        output[field] = resolved
        diagnostics.entityResolved = true
        appendBounded(diagnostics.entityResolvedReferences, {
            field = field,
            value = value.value or value.text,
            id = resolved.id,
            reason = reason,
        })
        return true
    end

    local failure = {
        field = field,
        value = value.value or value.text,
        reason = reason or "entity_unresolved",
    }
    if type(candidates) == "table" then
        failure.candidates = candidates
    end
    appendBounded(diagnostics.entityResolutionFailures, failure)
    return false
end

local function entityIndexFor(context)
    if type(context) ~= "table" then return nil end
    if type(context.semanticEntityIndex) == "table" then
        return context.semanticEntityIndex
    end
    if EntityResolver
        and type(EntityResolver.BuildIndex) == "function"
        and type(context.semanticEntityCandidates) == "table"
    then
        return EntityResolver.BuildIndex(context.semanticEntityCandidates)
    end
    return nil
end

local function refreshConfidence(output, diagnostics, resolvedCount)
    local details = diagnostics.confidenceDetails
    if type(details) ~= "table" then return end
    local penalty = tonumber(details.unresolvedPenalty) or 0
    if penalty <= 0 or resolvedCount <= 0 then return end
    local recovery = math.min(penalty, resolvedCount * 0.08)
    output.confidence = math.max(0, math.min(
        1,
        (tonumber(output.confidence) or 0) + recovery
    ))
    details.contextResolutionRecovery = recovery
    details.unresolvedPenalty = math.max(0, penalty - recovery)
    if output.confidence >= 0.85 then
        output.confidenceBand = "high"
    elseif output.confidence >= 0.60 then
        output.confidenceBand = "medium"
    else
        output.confidenceBand = "low"
    end
    diagnostics.confidenceDetails = details
end

function Resolver.Resolve(ir, state, context, options)
    local valid = IR.Validate(ir)
    if valid ~= true then return ir end

    local output = IR.Clone(ir)
    local diagnostics = output.diagnostics or {}
    diagnostics.contextResolvedReferences = {}
    diagnostics.contextUnresolvedReferences = {}
    diagnostics.entityResolvedReferences = {}
    diagnostics.entityResolutionFailures = {}

    local entityIndex
    local resolvedCount = 0
    local entityResolvedCount = 0
    entityIndex = entityIndexFor(context)
    local index
    for index = 1, #ENTITY_FIELDS do
        if resolveField(
            output,
            ENTITY_FIELDS[index],
            state,
            diagnostics
        ) then
            resolvedCount = resolvedCount + 1
        end
        if resolveEntityField(
            output,
            ENTITY_FIELDS[index],
            entityIndex,
            diagnostics
        ) then
            entityResolvedCount = entityResolvedCount + 1
        end
    end

    if diagnostics.contextResolutionAttempted == true
        or diagnostics.entityResolutionAttempted == true
    then
        if diagnostics.contextResolutionAttempted == true
            and diagnostics.entityResolutionAttempted == true
        then
            diagnostics.contextResolver = "dialogue_state_and_entity_index"
        elseif diagnostics.entityResolutionAttempted == true then
            diagnostics.contextResolver = "entity_index"
        else
            diagnostics.contextResolver = "dialogue_state"
        end
        diagnostics.contextResolutionCount = resolvedCount
        diagnostics.entityResolutionCount = entityResolvedCount
        diagnostics.unresolvedEntity = unresolvedEntity(output)
        refreshConfidence(
            output,
            diagnostics,
            resolvedCount + entityResolvedCount
        )
        output.diagnostics = diagnostics
        output.provenance = output.provenance or {}
        output.provenance.contextResolver = diagnostics.contextResolver
    end

    return output
end

Resolver.ResolveReferences = Resolver.Resolve

return Resolver
