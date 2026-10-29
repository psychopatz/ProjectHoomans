-- Shared situation/behavior eligibility and scoring over projected context.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = require "PNC/Semantics/PNC_SemanticInteractionCatalog"
local Predicate = require "PNC/Semantics/PNC_SemanticPredicate"
local ValueBounds = require "PNC/Semantics/PNC_SemanticValueBounds"

local Arbitration = PNC.Semantics.InteractionArbitration or {}
PNC.Semantics.InteractionArbitration = Arbitration

Arbitration.MAX_TRACE_ROWS = 64
Arbitration.MAX_BEHAVIOR_CANDIDATES = 16
Arbitration.MAX_ONE_SHOT_CANDIDATES = 16

local function copy(value)
    return ValueBounds.Copy(value)
end

function Arbitration.EvaluatePredicate(predicate, root, trace, prefix)
    local result = Predicate.Evaluate(predicate, root)
    prefix = tostring(prefix or "predicate")
    local rows = type(result.trace) == "table" and result.trace or {}
    for index = 1, #rows do
        if #trace >= Arbitration.MAX_TRACE_ROWS then break end
        local row = copy(rows[index]) or {}
        row.id = prefix .. "." .. tostring(index)
        trace[#trace + 1] = row
    end
    if #rows == 0 and result.allowed ~= true
        and #trace < Arbitration.MAX_TRACE_ROWS
    then
        trace[#trace + 1] = {
            id = prefix,
            passed = false,
            reason = result.reason,
            status = result.status,
        }
    end
    return result.allowed == true, result
end

function Arbitration.CooldownActive(snapshot, beatID, sequence)
    local untilTurn = type(snapshot.cooldowns) == "table"
        and tonumber(snapshot.cooldowns[beatID]) or nil
    return untilTurn ~= nil and untilTurn > sequence, untilTurn
end

function Arbitration.BeatRow(beat, status, trace, score, reason)
    return {
        id = beat.id,
        group = beat.group,
        status = status,
        eligible = status == "eligible" or status == "active",
        score = tonumber(score) or 0,
        reason = reason,
        predicateTrace = trace,
    }
end

local function contains(values, target)
    if type(values) ~= "table" then return false end
    for index = 1, #values do
        if values[index] == target then return true end
    end
    return false
end

local function behaviorEligibility(behavior, root)
    root = type(root) == "table" and root or {}
    local reasons = {}
    local stimulusType = type(root.stimulus) == "table"
        and root.stimulus.type or nil
    local stimulusMatched = contains(behavior.stimuli, stimulusType)
    if not stimulusMatched then
        reasons[#reasons + 1] = "stimulus_not_supported"
    end

    local capabilityFailures = {}
    local actor = type(root.actor) == "table" and root.actor or {}
    local capabilities = type(actor.capabilities) == "table"
        and actor.capabilities or {}
    for index = 1, #(behavior.requiredCapabilities or {}) do
        local capability = behavior.requiredCapabilities[index]
        if capabilities[capability] ~= true then
            capabilityFailures[#capabilityFailures + 1] = {
                id = capability,
                actual = capabilities[capability],
                reason = capabilities[capability] == false
                    and "capability_unavailable"
                    or "capability_unknown",
            }
        end
    end
    if #capabilityFailures > 0 then
        reasons[#reasons + 1] = "required_capability_unavailable"
    end

    local predicateTrace = {}
    local predicateMatched = behavior.when == nil
    local predicateResult
    if behavior.when ~= nil then
        predicateMatched, predicateResult = Arbitration.EvaluatePredicate(
            behavior.when,
            root,
            predicateTrace,
            behavior.id .. ".when"
        )
        if not predicateMatched then
            reasons[#reasons + 1] = predicateResult
                and predicateResult.reason
                or "behavior_predicate_failed"
        end
    end

    return stimulusMatched
        and #capabilityFailures == 0
        and predicateMatched,
        {
            stimulusType = stimulusType,
            stimulusMatched = stimulusMatched,
            capabilityFailures = capabilityFailures,
            predicateTrace = predicateTrace,
            predicateResult = predicateResult and {
                status = predicateResult.status,
                reason = predicateResult.reason,
            } or nil,
            reasons = reasons,
        }
end

local function scoredBehavior(behavior, root, beatRelevance)
    local eligible, eligibility = behaviorEligibility(behavior, root)
    local base = tonumber(behavior.baseRelevance) or 0
    local score = beatRelevance ~= nil
        and (base + (tonumber(beatRelevance) or 0)) / 2
        or base
    local modifiers = {}
    for modifierIndex = 1, #(behavior.modifiers or {}) do
        local modifier = behavior.modifiers[modifierIndex]
        local trace = {}
        local matched = Arbitration.EvaluatePredicate(
            modifier.when,
            root,
            trace,
            behavior.id .. ".modifier." .. tostring(modifierIndex)
        )
        local delta = matched and (tonumber(modifier.delta) or 0) or 0
        if eligible then score = score + delta end
        modifiers[#modifiers + 1] = {
            matched = matched == true,
            delta = delta,
            configuredDelta = tonumber(modifier.delta) or 0,
            reason = modifier.reason,
            predicateTrace = trace,
        }
    end
    if score < 0 then score = 0 end
    if score > 1.5 then score = 1.5 end

    local outputs = copy(behavior.outputs) or {}
    local speech = type(outputs.speech) == "table"
        and outputs.speech or nil
    return {
        id = behavior.id,
        act = behavior.act,
        mode = behavior.mode,
        eligible = eligible,
        eligibilityTrace = eligibility.predicateTrace,
        eligibility = eligibility,
        stimuli = copy(behavior.stimuli) or {},
        requiredCapabilities = copy(behavior.requiredCapabilities) or {},
        outputs = outputs,
        continuation = copy(behavior.continuation),
        -- Compatibility projection for current response-plan/harness consumers.
        dialogueAct = speech and speech.dialogueAct or nil,
        contentTemplateID = speech and speech.contentTemplateID or nil,
        baseRelevance = behavior.baseRelevance,
        beatRelevance = beatRelevance,
        score = score,
        modifiers = modifiers,
    }
end

local function sortRows(rows)
    table.sort(rows, function(left, right)
        if left.eligible ~= right.eligible then return left.eligible == true end
        if left.score == right.score then return left.id < right.id end
        return left.score > right.score
    end)
    return rows
end

function Arbitration.BehaviorRows(beat, root)
    local rows = {}
    for index = 1, math.min(
        #(beat and beat.candidates or {}),
        Arbitration.MAX_BEHAVIOR_CANDIDATES
    ) do
        local candidate = beat.candidates[index]
        local behavior = Catalog.Behaviors.Get(candidate.behavior)
        if behavior and behavior.mode == "beat" then
            rows[#rows + 1] = scoredBehavior(
                behavior, root, candidate.relevance
            )
        end
    end
    return sortRows(rows)
end

function Arbitration.OneShotBehaviorRows(root)
    local eligibleRows = {}
    local ineligibleRows = {}
    local stimulusType = type(root) == "table"
        and type(root.stimulus) == "table"
        and root.stimulus.type or nil
    local ids = Catalog.Behaviors.OneShotForStimulus(stimulusType)

    -- The output is capped, but eligibility must be evaluated before that
    -- cap is applied. Capping raw registration order lets unrelated
    -- ineligible behaviors starve a valid later provider as the catalog
    -- grows. Keep only the best bounded eligible rows, plus bounded
    -- ineligible diagnostics when space remains.
    for index = 1, #ids do
        local behavior = Catalog.Behaviors.Get(ids[index])
        if behavior and behavior.mode == "one_shot" then
            local row = scoredBehavior(behavior, root, nil)
            if row.eligible == true then
                eligibleRows[#eligibleRows + 1] = row
                sortRows(eligibleRows)
                while #eligibleRows > Arbitration.MAX_ONE_SHOT_CANDIDATES do
                    table.remove(eligibleRows)
                end
            elseif #ineligibleRows < Arbitration.MAX_ONE_SHOT_CANDIDATES then
                ineligibleRows[#ineligibleRows + 1] = row
            end
        end
    end

    local rows = {}
    for index = 1, #eligibleRows do
        rows[#rows + 1] = eligibleRows[index]
    end
    for index = 1, #ineligibleRows do
        if #rows >= Arbitration.MAX_ONE_SHOT_CANDIDATES then break end
        rows[#rows + 1] = ineligibleRows[index]
    end
    return sortRows(rows)
end

function Arbitration.SelectedBehavior(rows)
    if type(rows) ~= "table" then return nil end
    for index = 1, #rows do
        if rows[index].eligible == true then return rows[index] end
    end
    return nil
end

return Arbitration
