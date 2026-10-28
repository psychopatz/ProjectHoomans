-- Contextual discourse arbitration over Core semantic candidates.
--
-- This layer never reparses raw text. Core owns surface understanding and
-- candidate generation; Hoomans uses bounded conversation state to select and
-- annotate the most contextually coherent semantic interpretation.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Semantic = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local IR = Semantic.IR
local Eligibility = require
    "PNC/Semantics/PNC_SemanticDialogueCandidateEligibility"
local ContextResolver = require "PNC/Semantics/PNC_SemanticContextResolver"
local SocialFeatures = require "PNC/Semantics/PNC_SemanticSocialFeatures"

local Resolver = PNC.Semantics.DiscourseResolver or {}
PNC.Semantics.DiscourseResolver = Resolver

Resolver.VERSION = 1
Resolver.MAX_EVIDENCE = 8
Resolver.MAX_CANDIDATES = 12
Resolver.MAX_CONTEXT_BOOST = 0.16
Resolver.MINIMUM_MARGIN = 0.015

local REPLY_ACTS = {
    ACCEPT = true,
    REFUSE = true,
    AGREE = true,
    DISAGREE = true,
    ACKNOWLEDGE = true,
    THANK = true,
    APOLOGIZE = true,
}

local QUESTION_REPLY_ACTS = {
    ACCEPT = true,
    REFUSE = true,
    AGREE = true,
    DISAGREE = true,
    ACKNOWLEDGE = true,
}

local PROPOSAL_REPLY_ACTS = {
    ACCEPT = true,
    REFUSE = true,
    AGREE = true,
    DISAGREE = true,
}

local function copyValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 10 then return nil end
    local output = {}
    for key, item in pairs(value) do
        if type(key) ~= "function" and type(item) ~= "function" then
            output[key] = copyValue(item, depth + 1)
        end
    end
    return output
end

local function appendEvidence(output, value)
    value = tostring(value or "")
    if value == "" or #output >= Resolver.MAX_EVIDENCE then return end
    for _, existing in ipairs(output) do
        if existing == value then return end
    end
    output[#output + 1] = value
end

local function snapshotFor(context)
    context = type(context) == "table" and context or {}
    local live = context.semanticContextState
    if type(live) == "table" and type(live.ToContext) == "function" then
        local ok, value = pcall(live.ToContext, live)
        if ok and type(value) == "table" then return value end
    end
    local snapshot = context.semanticDialogueContext
    return type(snapshot) == "table" and snapshot or {}
end

local function pendingFor(snapshot)
    local pending = type(snapshot.pendingFollowUp) == "table"
        and snapshot.pendingFollowUp or nil
    if pending and tostring(pending.status or "open") ~= "closed" then
        return pending
    end
    local agenda = type(snapshot.agenda) == "table" and snapshot.agenda or {}
    for _, item in ipairs(agenda) do
        if type(item) == "table"
            and tostring(item.status or "") == "open"
        then
            return item
        end
    end
    return nil
end

local function actFor(ir)
    return tostring(ir and (ir.intent or ir.speechAct) or "")
end

local function topicID(value)
    if type(value) == "table" then
        value = value.id or value.topic or value.subject
    end
    value = tostring(value or "")
    if value == "" then return nil end
    return value
end

local function replyLike(ir)
    return REPLY_ACTS[actFor(ir)] == true
        or REPLY_ACTS[tostring(ir and ir.speechAct or "")] == true
end

local function semanticSignature(candidate)
    local ir = candidate and candidate.ir or {}
    return table.concat({
        tostring(ir.intent or ""),
        tostring(ir.speechAct or ""),
        tostring(ir.action or ""),
        tostring(ir.subject or ""),
    }, "|")
end

local function mostRecentNPC(snapshot)
    local recent = type(snapshot.recentTurns) == "table"
        and snapshot.recentTurns or {}
    for index = 1, math.min(#recent, 6) do
        local turn = recent[index]
        if type(turn) == "table"
            and tostring(turn.speaker or "") == "npc"
        then
            return turn
        end
    end
    return nil
end

local function contextualAdjustment(candidate, snapshot)
    local ir = candidate and candidate.ir or {}
    local evidence = {}
    local adjustment = 0

    -- Context can disambiguate conversation, but it never makes a gameplay
    -- mutation safer. Mutation admission remains C4 RiskPolicy authority.
    if ir.action ~= nil then
        return 0, { "mutation_context_not_boosted" }
    end

    local pending = pendingFor(snapshot)
    local act = actFor(ir)
    if pending and replyLike(ir) then
        adjustment = adjustment + 0.07
        appendEvidence(evidence, "pending_interaction:" .. tostring(
            pending.kind or "UNKNOWN"
        ))

        local kind = string.upper(tostring(pending.kind or ""))
        if kind == "QUESTION" and QUESTION_REPLY_ACTS[act] then
            adjustment = adjustment + 0.04
            appendEvidence(evidence, "adjacency:question_reply")
        elseif (kind == "PROPOSAL" or kind == "OFFER"
            or kind == "REQUEST")
            and PROPOSAL_REPLY_ACTS[act]
        then
            adjustment = adjustment + 0.04
            appendEvidence(evidence, "adjacency:proposal_reply")
        end

        if pending.topic and ir.subject
            and string.lower(tostring(pending.topic))
                == string.lower(tostring(ir.subject))
        then
            adjustment = adjustment + 0.03
            appendEvidence(evidence, "subject_matches_pending_topic")
        end
    end

    local currentTopic = topicID(snapshot.currentTopic)
    local extensions = type(ir.extensions) == "table" and ir.extensions or {}
    local irTopic = topicID(extensions.topic) or topicID(ir.subject)
    if currentTopic and irTopic
        and string.lower(currentTopic)
            == string.lower(irTopic)
    then
        adjustment = adjustment + 0.02
        appendEvidence(evidence, "current_topic_match")
    end

    if replyLike(ir) and mostRecentNPC(snapshot) then
        adjustment = adjustment + 0.02
        appendEvidence(evidence, "recent_npc_turn")
    end

    return math.min(Resolver.MAX_CONTEXT_BOOST, adjustment), evidence
end

local function frameFor(ir, snapshot, candidate, adjustment, evidence)
    local pending = pendingFor(snapshot)
    local act = actFor(ir)
    local isReply = replyLike(ir)
    local extensions = type(ir.extensions) == "table" and ir.extensions or {}

    local topic = topicID(extensions.topic) or topicID(ir.subject)
    local topicSource = topic and "semantic" or nil
    if isReply and pending and pending.topic then
        topic = pending.topic
        topicSource = "pending_interaction"
    elseif not topic and snapshot.currentTopic then
        topic = snapshot.currentTopic
        topicSource = "conversation"
    end

    local subject = ir.subject
    local subjectSource = subject and "semantic" or nil
    if not subject and isReply and pending and pending.topic then
        subject = pending.topic
        subjectSource = "pending_interaction"
    end

    local replyTo
    if isReply and pending then
        replyTo = {
            kind = "pending_interaction",
            id = pending.id,
            interactionKind = pending.kind,
            topic = pending.topic,
            owner = pending.owner,
            flowID = pending.flowID,
            nodeID = pending.nodeID,
        }
    elseif isReply then
        local recentNPC = mostRecentNPC(snapshot)
        if recentNPC then
            replyTo = {
                kind = "recent_npc_turn",
                sequence = recentNPC.sequence,
                intent = recentNPC.intent,
                speechAct = recentNPC.speechAct,
                topic = recentNPC.topic,
            }
        end
    end

    return {
        schemaVersion = Resolver.VERSION,
        kind = "discourse_frame",
        semantic = {
            intent = ir.intent,
            speechAct = ir.speechAct,
            action = ir.action,
            confidence = tonumber(ir.confidence) or 0,
        },
        topic = topic,
        topicSource = topicSource,
        subject = subject,
        subjectSource = subjectSource,
        replyTo = replyTo,
        pending = copyValue(pending),
        currentTopic = snapshot.currentTopic,
        previousTopic = snapshot.previousTopic,
        baseConfidence = tonumber(candidate and candidate.confidence) or 0,
        contextualSupport = adjustment,
        contextualConfidence = math.min(
            1,
            (tonumber(candidate and candidate.confidence) or 0) + adjustment
        ),
        evidence = copyValue(evidence) or {},
    }
end

local function noMatchIR(bundle, diagnostics)
    return IR.New({
        rawText = bundle.rawText,
        normalizedText = bundle.normalizedText,
        confidence = 0,
        diagnostics = {
            parser = "projecthoomans_discourse_resolver",
            noMatch = true,
            candidateSelection = diagnostics,
            recommendedRoute = "clarify_or_llm",
        },
        provenance = {
            provider = "lua",
            parser = "contextual_discourse_resolver",
        },
    })
end

local function candidateMetric(candidate, key)
    local match = type(candidate and candidate.match) == "table"
        and candidate.match or {}
    return tonumber(match[key]) or 0
end

local function sortRows(left, right)
    if math.abs(left.contextualScore - right.contextualScore) > 0.0001 then
        return left.contextualScore > right.contextualScore
    end
    for _, key in ipairs({
        "unresolvedCount", "ambiguousCount", "unmatchedCount",
    }) do
        local lm = candidateMetric(left.candidate, key)
        local rm = candidateMetric(right.candidate, key)
        if lm ~= rm then return lm < rm end
    end
    if left.candidate.exact ~= right.candidate.exact then
        return left.candidate.exact == true
    end
    local lp = tonumber(left.candidate.priority) or 0
    local rp = tonumber(right.candidate.priority) or 0
    if lp ~= rp then return lp > rp end
    return tostring(left.candidate.patternID or "")
        < tostring(right.candidate.patternID or "")
end

function Resolver.Select(bundle, state, context, options, contextResolver)
    options = type(options) == "table" and options or {}
    if type(bundle) ~= "table" or type(bundle.candidates) ~= "table" then
        return nil, {
            version = Resolver.VERSION,
            reason = "candidate_bundle_invalid",
            candidateCount = 0,
            eligibleCount = 0,
            rejectedCount = 0,
            rows = {},
            rejections = {},
        }
    end

    local snapshot = snapshotFor(context)
    local rows = {}
    local diagnostics = {
        version = Resolver.VERSION,
        reason = "no_eligible_candidate",
        candidateCount = #bundle.candidates,
        eligibleCount = 0,
        rejectedCount = 0,
        rows = {},
        rejections = {},
    }

    for index = 1, math.min(
        #bundle.candidates, Resolver.MAX_CANDIDATES
    ) do
        local candidate = bundle.candidates[index]
        local accepted, reason, details = Eligibility.Evaluate(
            candidate, state, context, options, contextResolver
        )
        candidate.eligibility = {
            eligible = accepted == true,
            reason = reason,
            details = copyValue(details),
        }
        if accepted then
            local adjustment, evidence = contextualAdjustment(
                candidate, snapshot
            )
            local contextualScore = math.min(
                1,
                (tonumber(candidate.confidence) or 0) + adjustment
            )
            rows[#rows + 1] = {
                candidate = candidate,
                contextualScore = contextualScore,
                adjustment = adjustment,
                evidence = evidence,
                signature = semanticSignature(candidate),
            }
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

    table.sort(rows, sortRows)
    for index = 1, math.min(#rows, Resolver.MAX_CANDIDATES) do
        local row = rows[index]
        diagnostics.rows[#diagnostics.rows + 1] = {
            patternID = row.candidate.patternID,
            intent = row.candidate.ir and row.candidate.ir.intent,
            speechAct = row.candidate.ir and row.candidate.ir.speechAct,
            action = row.candidate.ir and row.candidate.ir.action,
            baseConfidence = row.candidate.confidence,
            contextualSupport = row.adjustment,
            contextualScore = row.contextualScore,
            evidence = copyValue(row.evidence),
        }
    end

    local selected = rows[1]
    local second = rows[2]
    if selected and second
        and selected.signature ~= second.signature
        and selected.contextualScore - second.contextualScore
            < Resolver.MINIMUM_MARGIN
    then
        diagnostics.reason = "ambiguous_discourse_candidate"
        diagnostics.margin =
            selected.contextualScore - second.contextualScore
        return noMatchIR(bundle, diagnostics), diagnostics
    end

    if not selected then
        return noMatchIR(bundle, diagnostics), diagnostics
    end

    local output = IR.Clone(selected.candidate.ir)
    if type(contextResolver) == "function" then
        local ok, resolved = pcall(
            contextResolver, output, state, context, options
        )
        if ok and type(resolved) == "table" then output = resolved end
    end
    if ContextResolver
        and type(ContextResolver.ResolvePendingFollowUp) == "function"
    then
        local store = type(context) == "table"
            and context.semanticContextState or nil
        if type(store) == "table" then
            local resolved = ContextResolver.ResolvePendingFollowUp(
                output, store, options
            )
            if type(resolved) == "table" then output = resolved end
        end
    end

    output.extensions = type(output.extensions) == "table"
        and output.extensions or {}
    local frame = frameFor(
        output,
        snapshot,
        selected.candidate,
        selected.adjustment,
        selected.evidence
    )
    output.extensions.discourseFrame = frame
    if frame.topic
        and (output.extensions.topic == nil
            or frame.topicSource == "pending_interaction")
    then
        output.extensions.topic = frame.topic
    end
    if output.subject == nil and frame.subject ~= nil then
        output.subject = frame.subject
    end
    if SocialFeatures and type(SocialFeatures.Annotate) == "function" then
        SocialFeatures.Annotate(output)
    end

    diagnostics.reason = "contextual_discourse_candidate"
    diagnostics.selectedPattern = selected.candidate.patternID
    diagnostics.selectedPass = selected.candidate.pass
    diagnostics.selectedConfidence = selected.candidate.confidence
    diagnostics.selectedContextualScore = selected.contextualScore
    diagnostics.selectedContextualSupport = selected.adjustment
    diagnostics.margin = second
        and selected.contextualScore - second.contextualScore or 1
    diagnostics.discourseFrame = copyValue(frame)

    output.diagnostics = type(output.diagnostics) == "table"
        and output.diagnostics or {}
    output.diagnostics.candidateSelection = copyValue(diagnostics)
    output.diagnostics.discourseFrame = copyValue(frame)
    output.provenance = type(output.provenance) == "table"
        and output.provenance or {}
    output.provenance.candidateEligibility = "contextual_discourse"
    output.provenance.discourseResolver =
        "projecthoomans.contextual_discourse"

    return output, diagnostics
end

return Resolver
