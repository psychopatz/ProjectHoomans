-- Risk-aware semantic admission policy.
--
-- Conversation understanding and gameplay mutation do not share one global
-- confidence threshold. Context may strengthen non-mutating discourse, but it
-- never authorizes an unresolved/fuzzy/recovered gameplay action.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local ActionRisk = require "PNC/Semantics/PNC_SemanticActionRiskCatalog"

local Risk = PNC.Semantics.DialogueRiskPolicy or {}
PNC.Semantics.DialogueRiskPolicy = Risk

Risk.VERSION = 1

local function contextualFrame(ir)
    local extensions = type(ir and ir.extensions) == "table"
        and ir.extensions or {}
    return type(extensions.discourseFrame) == "table"
        and extensions.discourseFrame or {}
end

local function hasRecovery(ir)
    local provenance = type(ir and ir.provenance) == "table"
        and ir.provenance or {}
    local diagnostics = type(ir and ir.diagnostics) == "table"
        and ir.diagnostics or {}
    return type(provenance.surfaceRecovery) == "table"
        or diagnostics.recoveredMatch == true
end

local function hasFuzzy(ir)
    local diagnostics = type(ir and ir.diagnostics) == "table"
        and ir.diagnostics or {}
    return diagnostics.fuzzyMatch == true
        or tostring(ir and ir.provenance
            and ir.provenance.candidatePass or "") == "fuzzy"
end

local function unresolvedField(value)
    return type(value) == "table" and value.unresolved == true
        and tostring(value.text or value.value or value.reference or "") ~= ""
end

local function unresolvedReference(ir)
    if type(ir) ~= "table" then return nil end
    for _, field in ipairs({
        "object", "target", "source", "destination", "recipient",
    }) do
        local value = ir[field]
        if unresolvedField(value) then
            return field, value
        end
    end
    local diagnostics = type(ir.diagnostics) == "table"
        and ir.diagnostics or {}
    if diagnostics.unresolvedEntity == true then
        return "entity", nil
    end
    local unresolved = diagnostics.contextUnresolvedReferences
    if type(unresolved) == "table" and #unresolved > 0 then
        return tostring(unresolved[1].field or "context"), unresolved[1]
    end
    return nil
end

local function uncertainAlternativeRejected(ir)
    local diagnostics = type(ir and ir.diagnostics) == "table"
        and ir.diagnostics or {}
    local selection = type(diagnostics.candidateSelection) == "table"
        and diagnostics.candidateSelection or {}
    local rejections = type(selection.rejections) == "table"
        and selection.rejections or {}
    for _, row in ipairs(rejections) do
        local reason = tostring(row and row.reason or "")
        if reason == "fuzzy_mutating_action"
            or reason == "recovered_mutating_action"
        then
            return true, row
        end
    end
    return false, nil
end

local function deferredResolutionAllowed(ir, field, value)
    if not ActionRisk.AllowsDeferredResolution(ir and ir.action) then
        return false
    end
    if field ~= "object" and field ~= "target" then return false end
    if type(value) ~= "table" or value.reference ~= nil then return false end
    if hasFuzzy(ir) or hasRecovery(ir) then return false end
    local provenance = type(ir.provenance) == "table" and ir.provenance or {}
    if tostring(provenance.candidatePass or "exact") ~= "exact" then
        return false
    end
    local suspicious = uncertainAlternativeRejected(ir)
    if suspicious then return false end
    return tostring(value.text or value.value or "") ~= ""
end

local function riskClass(ir)
    if type(ir) ~= "table" then return "invalid" end
    local social = type(ir.socialContext) == "table"
        and ir.socialContext or {}
    if social.identityClaim == true then return "identity_mutation" end
    if ir.action ~= nil then return "mutating" end
    if ir.intent == "QUESTION" then return "read_only" end
    if ir.intent == "OFFER" then return "transactional_offer" end
    return "conversation"
end

function Risk.Assess(ir, context, options)
    options = type(options) == "table" and options or {}
    local thresholds = type(options.thresholds) == "table"
        and options.thresholds or {}
    local high = tonumber(thresholds.high) or 0.85
    local medium = tonumber(thresholds.medium) or 0.60
    local base = tonumber(ir and ir.confidence) or 0
    local frame = contextualFrame(ir)
    local contextual = tonumber(frame.contextualConfidence) or base
    local class = riskClass(ir)

    local result = {
        schemaVersion = Risk.VERSION,
        kind = "semantic_risk_assessment",
        riskClass = class,
        baseConfidence = base,
        contextualConfidence = contextual,
        highThreshold = high,
        mediumThreshold = medium,
        accepted = false,
        reason = "unassessed",
    }

    if class == "invalid" then
        result.reason = "invalid_ir"
        return result
    end

    if class == "mutating" or class == "identity_mutation" then
        if hasRecovery(ir) and options.allowRecoveredActions ~= true then
            result.reason = "recovered_action_requires_confirmation"
            return result
        end
        if hasFuzzy(ir)
            and options.allowFuzzyActions ~= true
            and not ActionRisk.IsFuzzySafe(ir.action)
        then
            result.reason = "fuzzy_action_requires_confirmation"
            return result
        end
        if base < high then
            result.reason = "action_confidence_below_high_threshold"
            return result
        end

        if class == "mutating" then
            local field, value = unresolvedReference(ir)
            if field then
                if deferredResolutionAllowed(ir, field, value) then
                    result.deferredResolution = true
                    result.deferredField = field
                else
                    result.reason = "unresolved_action_reference"
                    result.unresolvedField = field
                    return result
                end
            end
        end

        result.accepted = true
        result.reason = class == "identity_mutation"
            and "strict_identity_claim_admitted"
            or result.deferredResolution
            and "strict_mutation_deferred_resolution"
            or "strict_mutation_admitted"
        return result
    end

    if class == "read_only" then
        if base >= medium or contextual >= medium then
            result.accepted = true
            result.reason = contextual > base
                and "context_supported_read_only"
                or "read_only_admitted"
        else
            result.reason = "read_only_confidence_below_medium_threshold"
        end
        return result
    end

    if class == "transactional_offer" then
        -- Offers do not mutate until the existing consent/authority path
        -- accepts them, but they should still be confidently understood.
        if hasRecovery(ir) or hasFuzzy(ir) then
            result.reason = "uncertain_offer_requires_clarification"
            return result
        end
        if base < high then
            result.reason = "offer_confidence_below_high_threshold"
            return result
        end
        result.accepted = true
        result.reason = "offer_semantics_admitted"
        return result
    end

    -- Ordinary conversation is intentionally more recall-friendly. Context
    -- may raise a moderate interpretation above the conversational threshold;
    -- this never changes the stored base confidence or action safety.
    if base >= medium or contextual >= medium then
        result.accepted = true
        if contextual > base and base < medium then
            result.reason = "context_supported_conversation"
        elseif contextual > base then
            result.reason = "context_reinforced_conversation"
        else
            result.reason = "conversation_admitted"
        end
    else
        result.reason = "conversation_confidence_below_medium_threshold"
    end
    return result
end

return Risk
