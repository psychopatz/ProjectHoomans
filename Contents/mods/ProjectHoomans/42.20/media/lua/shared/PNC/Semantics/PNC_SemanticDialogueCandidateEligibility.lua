-- Bounded, side-effect-free arbitration for Core parser candidates.
--
-- Core owns normalization, matching, confidence, and typed captures.  This
-- spoke owns the Hoomans decision about whether a candidate is valid for the
-- current speaker/context.  It never records turns, queues messages, sends
-- commands, or changes relationship state.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Semantic = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local IR = Semantic.IR
local ActionRisk = require "PNC/Semantics/PNC_SemanticActionRiskCatalog"

local Eligibility = PNC.Semantics.DialogueCandidateEligibility or {}
PNC.Semantics.DialogueCandidateEligibility = Eligibility

Eligibility.VERSION = 1
Eligibility.MAX_REJECTIONS = 8

local function copyValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 10 then return nil end
    local output = {}
    local key
    local item
    for key, item in pairs(value) do
        output[key] = copyValue(item, depth + 1)
    end
    return output
end

local function textValue(value)
    if type(value) == "table" then
        value = value.text or value.value or value.name
    end
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function captureValue(candidate, captureName)
    local captures = candidate and candidate.typedCaptures
        or candidate and candidate.captures or nil
    return type(captures) == "table" and captures[captureName] or nil
end

local function contextValue(context, key)
    if type(context) ~= "table" then return nil end
    if context[key] ~= nil then return context[key] end
    local situation = context.dialogueSituation
    if type(situation) == "table" then return situation[key] end
    return nil
end

local function requiredContextMatches(metadata, context)
    local required = metadata and metadata.requiredContext
    if type(required) ~= "table" then return true, nil end
    local key
    local expected
    local actual
    for key, expected in pairs(required) do
        actual = contextValue(context, key)
        if tostring(actual or "") ~= tostring(expected or "") then
            return false, "required_context_mismatch:" .. tostring(key)
        end
    end
    return true, nil
end

local function requiredCapturesMatch(metadata, candidate)
    local required = metadata and metadata.requiredCaptures
    if type(required) ~= "table" then return true, nil end
    local index
    local name
    local capture
    for index = 1, #required do
        name = required[index]
        capture = captureValue(candidate, name)
        if type(capture) ~= "table" then
            return false, "required_capture_missing:" .. tostring(name)
        end
        if capture.unresolved == true
            and textValue(capture) == nil
        then
            return false, "required_capture_empty:" .. tostring(name)
        end
    end
    return true, nil
end

local function eventFollowUpMatches(metadata, context)
    if type(metadata) ~= "table"
        or metadata.requiresEventFollowUp ~= true
    then
        return true, nil
    end

    local lifecycle = type(context) == "table"
        and context.interactionLifecycle or nil
    local beat = type(lifecycle) == "table" and lifecycle.activeBeat or nil
    if type(beat) ~= "table"
        or tostring(beat.eventRef or "") == ""
    then
        return false, "event_follow_up_window_unavailable"
    end

    -- An event beat with no disclosed facts must still classify a typed
    -- question so the response layer can answer explicitly that it does not
    -- know. Suggestions remain suppressed by their existing fact/offer
    -- checks; this branch only preserves the typed-input unknown path.
    if type(beat.factRefs) ~= "table"
        or #beat.factRefs == 0
        or type(beat.offerIDs) ~= "table"
        or #beat.offerIDs == 0
    then
        return true, nil
    end

    local expected = tostring(metadata.eventOfferID or "")
    if expected == "" then
        return false, "event_follow_up_offer_undefined"
    end
    for index = 1, math.min(#beat.offerIDs, 8) do
        if tostring(beat.offerIDs[index] or "") == expected then
            return true, nil
        end
    end
    return false, "event_follow_up_offer_missing"
end

local function contextResolutionReason(ir)
    local diagnostics = ir and ir.diagnostics or {}
    local unresolved = diagnostics.contextUnresolvedReferences
    if type(unresolved) == "table" and #unresolved > 0 then
        return unresolved[1].reason or "context_reference_unresolved"
    end
    if diagnostics.unresolvedEntity == true
        and diagnostics.contextResolver == "dialogue_state_and_entity_index"
    then
        return "context_entity_unresolved"
    end
    return nil
end

function Eligibility.Evaluate(candidate, state, context, options,
    contextResolver)
    options = type(options) == "table" and options or {}
    if type(candidate) ~= "table" or type(candidate.ir) ~= "table" then
        return false, "candidate_ir_missing", {}
    end

    local ir = candidate.ir
    local valid, validationReason = IR.Validate(ir)
    if valid ~= true then
        return false, validationReason or "candidate_ir_invalid", {}
    end
    if ir.diagnostics and ir.diagnostics.noMatch == true then
        return false, "candidate_no_match", {}
    end

    local metadata = type(candidate.metadata) == "table"
        and candidate.metadata or {}
    local matches, reason = requiredContextMatches(metadata, context)
    if not matches then return false, reason, {} end
    matches, reason = eventFollowUpMatches(metadata, context)
    if not matches then return false, reason, {} end
    matches, reason = requiredCapturesMatch(metadata, candidate)
    if not matches then return false, reason, {} end

    -- A fuzzy interpretation may still be useful for conversation, but a
    -- mutating action must wait for an exact candidate or explicit
    -- confirmation. The ordinary policy remains the final safety gate.
    if ir.action ~= nil then
        local fuzzyUsed = candidate.fuzzy == true
            and type(candidate.match) == "table"
            and (tonumber(candidate.match.fuzzyCount) or 0) > 0
        if fuzzyUsed
            and options.allowFuzzyCandidates ~= true
            and not ActionRisk.IsFuzzySafe(ir.action)
        then
            return false, "fuzzy_mutating_action", {
                action = ir.action,
                fuzzyCount = candidate.match.fuzzyCount,
            }
        end
        if candidate.recovered == true
            and options.allowRecoveredCandidates ~= true
        then
            return false, "recovered_mutating_action", {
                action = ir.action,
                recovery = copyValue(candidate.surfaceRecovery),
            }
        end
    end

    if metadata.requiresResolvedReferences == true then
        local resolved = ir
        if type(contextResolver) == "function" then
            resolved = contextResolver(ir, state, context, options) or ir
        end
        local unresolvedReason = contextResolutionReason(resolved)
        if unresolvedReason then
            return false, unresolvedReason, {
                resolver = resolved.diagnostics
                    and resolved.diagnostics.contextResolver,
            }
        end
    end

    return true, "eligible", {
        exact = candidate.exact == true,
        fuzzy = candidate.fuzzy == true,
        score = candidate.score,
    }
end

local function noMatchIR(bundle, diagnostics)
    return IR.New({
        rawText = bundle.rawText,
        normalizedText = bundle.normalizedText,
        confidence = 0,
        diagnostics = {
            parser = "lua_candidate_eligibility",
            noMatch = true,
            candidateSelection = diagnostics,
            recommendedRoute = "clarify_or_llm",
        },
        provenance = {
            provider = "lua",
            parser = "candidate_eligibility",
        },
    })
end

function Eligibility.Select(bundle, state, context, options, contextResolver)
    options = type(options) == "table" and options or {}
    if type(bundle) ~= "table" or type(bundle.candidates) ~= "table" then
        return nil, {
            version = Eligibility.VERSION,
            reason = "candidate_bundle_invalid",
            candidateCount = 0,
            eligibleCount = 0,
            rejectedCount = 0,
            rejections = {},
        }
    end

    local diagnostics = {
        version = Eligibility.VERSION,
        candidateCount = #bundle.candidates,
        eligibleCount = 0,
        rejectedCount = 0,
        rejections = {},
        reason = "no_eligible_candidate",
    }
    local eligible = {}
    local index
    local candidate
    local accepted
    local reason
    local details
    for index = 1, #bundle.candidates do
        candidate = bundle.candidates[index]
        accepted, reason, details = Eligibility.Evaluate(
            candidate, state, context, options, contextResolver
        )
        candidate.eligibility = {
            eligible = accepted == true,
            reason = reason,
            details = copyValue(details),
        }
        if accepted then
            eligible[#eligible + 1] = candidate
            diagnostics.eligibleCount = diagnostics.eligibleCount + 1
        else
            diagnostics.rejectedCount = diagnostics.rejectedCount + 1
            if #diagnostics.rejections < Eligibility.MAX_REJECTIONS then
                diagnostics.rejections[#diagnostics.rejections + 1] = {
                    patternID = candidate.patternID,
                    pass = candidate.pass,
                    score = candidate.score,
                    reason = reason,
                    details = copyValue(details),
                }
            end
        end
    end

    local selected = nil
    if type(bundle.selected) == "table"
        and bundle.selected.eligibility
        and bundle.selected.eligibility.eligible == true
    then
        -- Core's selected candidate is the authoritative parse winner (and can
        -- intentionally be the fuzzy pass for one pattern). Prefer it over a
        -- separately exposed exact/fuzzy inspection row.
        selected = bundle.selected
    else
        selected = eligible[1]
    end
    local topScore = selected and tonumber(selected.score) or nil
    local topPriority = selected and tonumber(selected.priority) or 0
    local tiedEligible = 0
    local tiedPatterns = {}
    if topScore then
        for index = 1, #eligible do
            if math.abs((tonumber(eligible[index].score) or 0) - topScore)
                    <= 0.0001
                and (tonumber(eligible[index].priority) or 0)
                    == topPriority
            then
                local patternID = tostring(eligible[index].patternID or "")
                if not tiedPatterns[patternID] then
                    tiedPatterns[patternID] = true
                    tiedEligible = tiedEligible + 1
                end
            end
        end
    end
    diagnostics.tiedEligibleCount = tiedEligible

    if tiedEligible > 1 then
        selected = nil
        diagnostics.reason = "ambiguous_candidate"
    elseif selected then
        diagnostics.reason = "eligible_candidate"
        diagnostics.selectedPattern = selected.patternID
        diagnostics.selectedPass = selected.pass
        diagnostics.selectedConfidence = selected.confidence
    end

    if not selected then
        return noMatchIR(bundle, diagnostics), diagnostics
    end

    local output = IR.Clone(selected.ir)
    output.diagnostics = output.diagnostics or {}
    output.diagnostics.candidateSelection = diagnostics
    output.provenance = output.provenance or {}
    output.provenance.candidateEligibility = "contextual"
    return output, diagnostics
end

return Eligibility
