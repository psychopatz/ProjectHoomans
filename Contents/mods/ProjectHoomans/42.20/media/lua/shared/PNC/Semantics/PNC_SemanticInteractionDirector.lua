-- Explainable generic interaction arbitration.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = require "PNC/Semantics/PNC_SemanticInteractionCatalog"
local InteractionContext = require "PNC/Semantics/PNC_SemanticInteractionContext"
local Arbitration = require "PNC/Semantics/PNC_SemanticInteractionArbitration"
local InteractionPlan = require "PNC/Semantics/PNC_SemanticInteractionPlan"
local PragmaticResolver = require "PNC/Semantics/PNC_SemanticPragmaticResolver"
local Stimulus = require "PNC/Semantics/PNC_SemanticInteractionStimulus"
local ValueBounds = require "PNC/Semantics/PNC_SemanticValueBounds"

local Director = PNC.Semantics.InteractionDirector or {}
PNC.Semantics.InteractionDirector = Director

Director.VERSION = 1
Director.MAX_BEAT_CANDIDATES = 16

local function copy(value)
    return ValueBounds.Copy(value)
end

local function pragmaticFrame(stimulus, state, context, root)
    local frame = PragmaticResolver.Resolve(stimulus, state, context, root)
    frame.hostilityCount = root.history and root.history.hostilityCount or 0
    frame.firstContact = root.scene and root.scene.firstContact == true
    frame.immediateDanger = root.world and root.world.immediateDanger
    frame.providers = copy(root.providers) or {}
    return frame
end

local function selectBeat(snapshot, root, sequence)
    local candidates = {}
    local stimulusType = type(root.stimulus) == "table"
        and root.stimulus.type or nil
    local indexedCandidateIDs = Catalog.Beats.ForStimulus(stimulusType)
    local exited
    local activeBefore = copy(snapshot.active)
    local selectedBeat
    local active = type(snapshot.active) == "table"
        and Catalog.Beats.Get(snapshot.active.id) or nil

    if active then
        local exitTrace = {}
        local exits = Arbitration.EvaluatePredicate(
            active.exit, root, exitTrace, active.id .. ".exit"
        )
        local maxed = tonumber(active.maxTurns) and active.maxTurns > 0
            and (tonumber(snapshot.active.turns) or 0) >= active.maxTurns
        if exits or maxed then
            exited = {
                id = active.id,
                reason = exits and "exit_predicate" or "max_turns",
            }
            candidates[#candidates + 1] = Arbitration.BeatRow(
                active,
                "exited",
                exitTrace,
                active.baseRelevance,
                exited.reason
            )
            snapshot.active = nil
            root.beat.activeBeatID = nil
            root.beat.turnsInBeat = 0
        else
            local maintainTrace = {}
            local maintained = Arbitration.EvaluatePredicate(
                active.maintain,
                root,
                maintainTrace,
                active.id .. ".maintain"
            )
            if maintained then
                selectedBeat = active
                candidates[#candidates + 1] = Arbitration.BeatRow(
                    active,
                    "active",
                    maintainTrace,
                    1000 + (tonumber(active.baseRelevance) or 0),
                    "active_beat_stickiness"
                )
            else
                exited = {
                    id = active.id,
                    reason = "maintain_failed",
                }
                candidates[#candidates + 1] = Arbitration.BeatRow(
                    active,
                    "exited",
                    maintainTrace,
                    active.baseRelevance,
                    exited.reason
                )
                snapshot.active = nil
                root.beat.activeBeatID = nil
                root.beat.turnsInBeat = 0
            end
        end
    end

    if not selectedBeat then
        local beatIDs = indexedCandidateIDs
        for index = 1, math.min(#beatIDs, Director.MAX_BEAT_CANDIDATES) do
            local beat = Catalog.Beats.Get(beatIDs[index])
            if not (activeBefore and beat.id == activeBefore.id) then
                local cooling, untilTurn = Arbitration.CooldownActive(
                    snapshot, beat.id, sequence
                )
                if cooling then
                    candidates[#candidates + 1] = Arbitration.BeatRow(
                        beat,
                        "cooldown",
                        {},
                        beat.baseRelevance,
                        "cooldown_until:" .. tostring(untilTurn)
                    )
                else
                    local trace = {}
                    local eligible = Arbitration.EvaluatePredicate(
                        beat.entry,
                        root,
                        trace,
                        beat.id .. ".entry"
                    )
                    candidates[#candidates + 1] = Arbitration.BeatRow(
                        beat,
                        eligible and "eligible" or "ineligible",
                        trace,
                        beat.baseRelevance,
                        eligible and "entry_matched" or "entry_failed"
                    )
                end
            end
        end
        local eligible = {}
        for index = 1, #candidates do
            local row = candidates[index]
            if row.status == "eligible" then
                eligible[#eligible + 1] = row
            end
        end
        table.sort(eligible, function(left, right)
            if left.score == right.score then return left.id < right.id end
            return left.score > right.score
        end)
        if eligible[1] then
            selectedBeat = Catalog.Beats.Get(eligible[1].id)
        end
    end

    local entered = selectedBeat
        and (not activeBefore or selectedBeat.id ~= activeBefore.id)
        and { id = selectedBeat.id, reason = "highest_eligible_beat" }
        or nil
    local plannedActive
    if selectedBeat then
        plannedActive = {
            id = selectedBeat.id,
            enteredTurn = entered and sequence
                or activeBefore and activeBefore.enteredTurn
                or sequence,
            turns = entered and 1
                or (tonumber(activeBefore and activeBefore.turns) or 0) + 1,
            group = selectedBeat.group,
        }
    end

    return {
        activeBefore = activeBefore,
        activeAfter = plannedActive,
        entered = entered,
        exited = exited,
        candidates = candidates,
        indexedCandidateIDs = copy(indexedCandidateIDs) or {},
        selectedBeat = selectedBeat,
    }
end

local function traceCount(rows)
    local count = 0
    rows = type(rows) == "table" and rows or {}
    for index = 1, #rows do
        local row = rows[index]
        if type(row) == "table" then
            count = count + #(row.predicateTrace or {})
            count = count + #(row.eligibilityTrace or {})
            for modifierIndex = 1, #(row.modifiers or {}) do
                local modifier = row.modifiers[modifierIndex]
                if type(modifier) == "table" then
                    count = count + #(modifier.predicateTrace or {})
                end
            end
        end
    end
    return count
end

local function decisionMetrics(
    normalized, beatSelection, beatBehaviors, oneShotBehaviors
)
    local index = Catalog.IndexSnapshot(normalized.type)
    return {
        schemaVersion = 1,
        stimulusType = normalized.type,
        catalogBeatCount = index.effectiveBeatCount,
        catalogBehaviorCount = index.effectiveBehaviorCount,
        canonicalBeatCount = index.canonicalBeatCount,
        canonicalBehaviorCount = index.canonicalBehaviorCount,
        indexedBeatCandidateCount = index.beatCount,
        indexedBeatCandidateIDs = copy(index.beatIDs) or {},
        indexedOneShotBehaviorCount = index.oneShotBehaviorCount,
        indexedOneShotBehaviorIDs = copy(index.oneShotBehaviorIDs) or {},
        activeBeatWasPresent = beatSelection.activeBefore ~= nil,
        beatCandidatesEvaluated = #(beatSelection.candidates or {}),
        beatBehaviorCandidatesEvaluated = #(beatBehaviors or {}),
        oneShotBehaviorCandidatesEvaluated = #(oneShotBehaviors or {}),
        predicateTraceRows =
            traceCount(beatSelection.candidates)
            + traceCount(beatBehaviors)
            + traceCount(oneShotBehaviors),
    }
end

function Director.PreviewStimulus(stimulus, state, context, options)
    options = type(options) == "table" and options or {}
    context = type(context) == "table" and context or {}
    local normalized, reason = Stimulus.Normalize(stimulus)
    if not normalized then return nil, reason end

    local snapshot = InteractionContext.StateSnapshot(context)
    local root = InteractionContext.Project(
        normalized, state, context, snapshot
    )
    local pragmatic = pragmaticFrame(
        normalized, state, context, root
    )
    root.pragmatic = pragmatic

    local sequence = tonumber(state and state.sequence) or 0
    local beatSelection = selectBeat(snapshot, root, sequence)
    local selectedBeat = beatSelection.selectedBeat

    local beatBehaviorCandidates = selectedBeat
        and Arbitration.BehaviorRows(selectedBeat, root) or {}
    local behavior = Arbitration.SelectedBehavior(beatBehaviorCandidates)
    local behaviorSource = behavior and "beat" or nil

    local oneShotBehaviorCandidates = {}
    if not behavior then
        oneShotBehaviorCandidates = Arbitration.OneShotBehaviorRows(root)
        behavior = Arbitration.SelectedBehavior(oneShotBehaviorCandidates)
        if behavior then behaviorSource = "one_shot" end
    end

    local planBeat = behaviorSource == "beat" and selectedBeat or nil
    local plan = InteractionPlan.Build(
        planBeat, behavior, normalized, state, pragmatic
    )
    local metrics = decisionMetrics(
        normalized,
        beatSelection,
        beatBehaviorCandidates,
        oneShotBehaviorCandidates
    )

    return {
        schemaVersion = Director.VERSION,
        kind = "interaction_director_preview",
        committed = false,
        sequence = sequence,
        stimulus = copy(normalized),
        pragmatic = copy(pragmatic),
        activeBefore = beatSelection.activeBefore,
        activeAfter = beatSelection.activeAfter,
        entered = beatSelection.entered,
        exited = beatSelection.exited,
        beatCandidates = beatSelection.candidates,
        selectedBeat = selectedBeat and {
            id = selectedBeat.id,
            group = selectedBeat.group,
            baseRelevance = selectedBeat.baseRelevance,
        } or nil,
        behaviorCandidates = beatBehaviorCandidates,
        oneShotBehaviorCandidates = oneShotBehaviorCandidates,
        behaviorSource = behaviorSource,
        selectedBehavior = behavior and copy(behavior) or nil,
        interactionPlan = plan,
        metrics = metrics,
        stateRevision = snapshot.revision,
    }
end

function Director.Preview(ir, state, context, options)
    local stimulus = Stimulus.FromIR(ir, context)
    return Director.PreviewStimulus(stimulus, state, context, options)
end

function Director.Commit(preview, context)
    if type(preview) ~= "table" then
        return nil, "director_preview_missing"
    end
    local live = type(context) == "table"
        and context.semanticContextState or nil
    if not live or type(live.StoreDirectorState) ~= "function" then
        return nil, "director_context_unavailable"
    end
    local state = live:GetDirectorState()
    local sequence = tonumber(preview.sequence) or 0
    if preview.exited and preview.exited.id then
        local beat = Catalog.Beats.Get(preview.exited.id)
        if beat and tonumber(beat.cooldownTurns) and beat.cooldownTurns > 0 then
            state.cooldowns[beat.id] = sequence + beat.cooldownTurns
        end
        state.recent[#state.recent + 1] = {
            id = preview.exited.id,
            turn = sequence,
            reason = preview.exited.reason,
        }
    end
    state.active = copy(preview.activeAfter)
    local stored, normalized = live:StoreDirectorState(state)
    if stored ~= true then return nil, normalized end
    local output = copy(preview)
    output.committed = true
    output.stateRevision = normalized.revision
    output.activeAfter = copy(normalized.active)
    return output
end

function Director.PreviewBeatDefinition(
    definition, ir, state, context, options
)
    local valid, beat = Catalog.Beats.Validate(definition)
    if not valid then return nil, beat end

    local stimulus = Stimulus.FromIR(ir, context)
    local snapshot = InteractionContext.StateSnapshot(context)
    local root = InteractionContext.Project(
        stimulus, state, context, snapshot
    )
    local pragmatic = pragmaticFrame(stimulus, state, context, root)
    root.pragmatic = pragmatic
    local trace = {}
    local eligible = Arbitration.EvaluatePredicate(
        beat.entry, root, trace, beat.id .. ".entry"
    )
    local behaviors = eligible
        and Arbitration.BehaviorRows(beat, root) or {}
    local behavior = Arbitration.SelectedBehavior(behaviors)

    return {
        schemaVersion = Director.VERSION,
        kind = "interaction_director_draft_preview",
        committed = false,
        draft = true,
        sequence = tonumber(state and state.sequence) or 0,
        stimulus = copy(stimulus),
        pragmatic = copy(pragmatic),
        beat = {
            id = beat.id,
            group = beat.group,
            baseRelevance = beat.baseRelevance,
        },
        eligible = eligible,
        predicateTrace = trace,
        behaviorCandidates = behaviors,
        selectedBehavior = behavior and copy(behavior) or nil,
        interactionPlan = InteractionPlan.Build(
            beat, behavior, stimulus, state, pragmatic
        ),
        activeProductionBeat = copy(snapshot.active),
    }
end

return Director
