-- Regression & collision test for semantic command parsing, ClausePreParser
-- competitive raw vs coreText evaluation, VerbFrame alias uniqueness, and
-- DiscourseResolver unconsumed action-concept guards.

local T = require "tests/support/test"
T.addPackagePaths()

local Semantic = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local Parser = Semantic.Parser
local VerbFrameParser = Semantic.VerbFrameParser
local ClausePreParser = Semantic.ClausePreParser

require "PNC/Semantics/PNC_SemanticCatalog"
local DiscourseResolver = require "PNC/Semantics/PNC_SemanticDiscourseResolver"

-- 1. VerbFrame alias uniqueness audit (prevents verbs like "camp" or "stand"
--    from silently colliding across incompatible frames).
local collisions = VerbFrameParser.AuditCollisions()
T.equal(#collisions, 0, "VerbFrameParser must have zero verb/concept collisions")

-- 2. Prefix-permutation matrix across BOTH Parser.Parse and Parser.ParseCandidates
--    (Parser.ParseCandidates is the live in-game Input_Context.lua entry point).
local COMMAND_CASES = {
    -- CAMP commands with conversational openers, vocatives, modals, and trailing softeners
    { text = "camp here",                                      action = "CAMP" },
    { text = "okay lets camp here",                            action = "CAMP" },
    { text = "ok let's camp here",                             action = "CAMP" },
    { text = "alright let us camp here",                       action = "CAMP" },
    { text = "alright guys, can we camp here",                 action = "CAMP" },
    { text = "hey everyone, let us set up camp here for a bit", action = "CAMP" },
    { text = "well please camp here right now",                action = "CAMP" },
    { text = "so we should camp here",                         action = "CAMP" },
    -- Unpatterned camping phrasing falling back to VerbFrameParser must still be CAMP, never STAY
    { text = "let's go camping over by the gas station",       action = "CAMP" },

    -- STAY / WAIT commands
    { text = "stay here",                                      action = "STAY" },
    { text = "okay wait here",                                 action = "STAY" },
    { text = "alright guys, stay here for a bit",              action = "STAY" },

    -- FOLLOW commands
    { text = "follow me",                                      action = "FOLLOW" },
    { text = "okay follow me",                                 action = "FOLLOW" },
    { text = "alright everyone, please follow me",             action = "FOLLOW" },

    -- GUARD commands
    { text = "guard here",                                     action = "GUARD" },
    { text = "okay guys, guard here",                          action = "GUARD" },
}

for i = 1, #COMMAND_CASES do
    local tc = COMMAND_CASES[i]
    Parser.ResetCache()

    local ir = Parser.Parse(tc.text, {})
    assert(type(ir) == "table", "Parser.Parse returns IR for: " .. tc.text)
    T.equal(ir.action, tc.action, "Parser.Parse action for: " .. tc.text)

    Parser.ResetCache()
    local bundle = Parser.ParseCandidates(tc.text, {})
    assert(type(bundle) == "table" and type(bundle.selected) == "table",
        "Parser.ParseCandidates selects candidate for: " .. tc.text)
    T.equal(bundle.selected.ir and bundle.selected.ir.action, tc.action,
        "Parser.ParseCandidates action for: " .. tc.text)
end

-- 3. Standalone discourse replies must remain intact (not stripped to empty).
local STANDALONE_CASES = {
    { text = "okay", intent = "ACCEPT" },
    { text = "yes",  intent = "ACCEPT" },
}
for i = 1, #STANDALONE_CASES do
    local tc = STANDALONE_CASES[i]
    Parser.ResetCache()
    local ir = Parser.Parse(tc.text, {})
    T.equal(ir.intent, tc.intent, "Standalone intent preserved for: " .. tc.text)
    T.equal(ir.action, nil, "Standalone reply has no action for: " .. tc.text)
end
T.equal(ClausePreParser.Analyze("alright").coreText, "alright",
    "Standalone opener 'alright' is not stripped to empty")

-- 4. ClausePreParser peels opener + group vocative + modal + trailing softener cleanly.
local frame = ClausePreParser.Analyze("alright guys, can we please camp here for a bit")
T.equal(frame.coreText, "camp here", "ClausePreParser peels multi-layer wrapper cleanly")
T.equal(frame.audienceScope and frame.audienceScope.scope, "GROUP",
    "ClausePreParser detects GROUP scope after leading opener")

-- 5. Negation must not invert into positive FOLLOW.
Parser.ResetCache()
local negIR = Parser.Parse("don't follow me", {})
assert(type(negIR) == "table" and negIR.action ~= "FOLLOW",
    "Negated follow command must not resolve to positive FOLLOW")

-- 6. DiscourseResolver unconsumed action-concept guard:
--    A higher-confidence verb_frame STAY fallback must lose to an exact CAMP
--    candidate when the utterance explicitly contains the CAMP concept.
local syntheticBundle = {
    rawText = "okay lets camp here",
    normalizedText = "okay lets camp here",
    candidates = {
        {
            patternID = "core.verbframe.WAIT",
            pass = "verb_frame",
            exact = false,
            confidence = 0.86,
            score = 0.86,
            priority = 50,
            match = { unmatchedCount = 1, unresolvedCount = 0, ambiguousCount = 0 },
            ir = Semantic.IR.New({
                rawText = "okay lets camp here",
                normalizedText = "okay lets camp here",
                intent = "REQUEST",
                speechAct = "REQUEST",
                action = "STAY",
                confidence = 0.86,
                analysis = { concepts = { { id = "CAMP" } } },
            }),
        },
        {
            patternID = "hoomans.command.camp.here",
            pass = "exact",
            exact = true,
            confidence = 0.78,
            score = 0.78,
            priority = 170,
            match = { unmatchedCount = 0, unresolvedCount = 0, ambiguousCount = 0 },
            ir = Semantic.IR.New({
                rawText = "okay lets camp here",
                normalizedText = "okay lets camp here",
                intent = "REQUEST",
                speechAct = "REQUEST",
                action = "CAMP",
                confidence = 0.78,
                analysis = { concepts = { { id = "CAMP" } } },
            }),
        },
    },
}

local selectedIR, diag = DiscourseResolver.Select(syntheticBundle, {}, {}, {})
assert(type(selectedIR) == "table", "DiscourseResolver returns selected IR")
T.equal(selectedIR.action, "CAMP",
    "Unconsumed CAMP concept penalizes STAY fallback so CAMP wins")
assert(type(diag) == "table" and type(diag.rows) == "table" and #diag.rows == 2,
    "DiscourseResolver diagnostics include both ranked rows")
local sawPenaltyEvidence = false
for i = 1, #diag.rows do
    local row = diag.rows[i]
    if row.action == "STAY" and type(row.evidence) == "table" then
        for j = 1, #row.evidence do
            if row.evidence[j] == "unconsumed_action_concept:CAMP" then
                sawPenaltyEvidence = true
            end
        end
    end
end
T.equal(sawPenaltyEvidence, true,
    "STAY fallback row records unconsumed_action_concept:CAMP penalty evidence")

print("PASS: pnc_semantic_command_collision_smoke")
