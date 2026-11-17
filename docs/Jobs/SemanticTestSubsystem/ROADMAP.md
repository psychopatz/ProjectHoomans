# Roadmap — A6R23–A6R26 Final Evidence Closure

**Parent status:** COMPLETE.
**Active phase:** A6R26 (Closed).
**Completion boundary:** A6R23–A6R26 accepted.

## Rules for this roadmap

This roadmap replaces the false COMPLETE state from A6R19–A6R22.

Do not stop after one file or one passing focused suite. Continue through A6R26 unless blocked by a genuine external dependency.

Do not redesign the fixture engine or create another behavioral authority.

---

## A6R23 — make full PNC discovery bounded and hermetic

### Known evidence

Independent audit command:

    PYTHONPATH=../psychopatzCore:. python3 -m unittest discover       -s tools/providers/pnc/tests -p 'test_*.py' -q

was bounded at 900 seconds and timed out:

    RC=124

During the run, roughly 10–12 Lua workers were simultaneously alive; several remained alive for many minutes. Timeout cleanup removed the audit-owned workers, so the current problem is accumulation/runtime ownership, not proven orphan persistence.

Current full Core discovery independently passes:

    Ran 277 tests in 124.768s
    OK

### Goal

Find why a sequential PNC unittest estate retains many long-lived workers and why total runtime exceeds 15 minutes.

Do not solve this by only increasing timeouts.

Inspect:

- LuaSemanticWorker, LuaProcess, worker context-manager enter/exit, close(), QUIT/wait/terminate behavior;
- helper functions that create workers;
- class/module fixtures that may retain worker/process objects;
- GUI test support and worker restart paths;
- tests that intentionally run more than one worker concurrently;
- subprocess pipes/reader threads that may prevent process reap;
- expensive repeated worker startup where safe bounded reuse could exist without cross-test state leakage.

Add a small lifecycle regression/harness that proves:

1. a representative worker-heavy test/module returns to its starting worker-process count;
2. repeated worker start/close cycles do not accumulate children;
3. full PNC discovery has a bounded runtime and exits normally.

Use deterministic ownership. Do not use blanket pkill as the fix.

### A6R23 gate

Accept only when:

- full PNC discovery exits 0 inside 900 seconds;
- worker population does not monotonically accumulate across unrelated tests;
- after completion, new test-owned Lua worker count is zero;
- no Tkinter unraisable cleanup errors appear;
- full Core discovery still passes;
- no test is weakened or skipped merely to reduce runtime.

Commit accepted Core participant changes first if Core owns the lifecycle fix. Then commit Hoomans phase changes and continue automatically.

---

## A6R24 — finish behavioral authority and method-level classification for real

### Current classification truth

Current ledger:

    171 modules
    702 methods
    66 LOW_LEVEL direct-worker modules
    276 LOW_LEVEL direct-worker methods

The agent added methodDetails, but each row currently contains only:

    name
    category
    usesDirectWorker

There is no method-specific reason.

Across all categories, the audit counted 508 direct-worker method rows without a method-specific reason.

Conservative review candidates:

- 61 behavior-named LOW_LEVEL methods across 28 modules;
- 68 LOW_LEVEL methods whose literal worker input already appears in canonical fixtures.

These candidate counts are not automatic migration counts.

### Decision rule

For every direct-worker method, decide by what it proves.

Fixture authority:

    scenario/context
    + user utterance / semantic choice
    → semantic outcome

Typical behavioral assertions include:

- IR intent, subject, speech act or recognition pattern;
- response branch, template or message outcome;
- grounded known/unknown answers;
- conversation topic/follow-up behavior;
- suggestion availability or semantic action surface;
- relationship, identity or wellbeing semantic outcome;
- semantic action accepted/rejected as user-visible behavior;
- localization preserving semantic identity.

Imperative authority:

- parser/compiler/schema/API validation;
- registry/provider ordering;
- ranking algorithm implementation;
- frame stale/replay protocol itself;
- serialization/save/native/network contract;
- worker envelope/process lifecycle;
- GUI mechanics;
- performance/resource limits;
- observatory/sweep/quality algorithms;
- internal authoring/editing mechanics.

A mixed method must be split when necessary.

### Required representative fixes

The audit directly inspected these currently LOW_LEVEL methods. Treat them as behavioral unless exact source evidence proves a mechanism contract.

1. test_competence_command_and_clarification_bounds.py
   test_continuation_paraphrases_follow_the_previous_topic

   Inputs include tell me more, say more, what else, continue.
   Assertions include QUESTION / CONVERSATION, CONVERSATION_CONTINUATION, grounded response and gossip-topic continuity.

2. test_competence_needs_and_offer_resolution.py
   test_natural_question_variants_answer_unknown_truthfully

   Inputs ask residence, wounds/health and radio-tower knowledge.
   Assertions include semantic subject, unknown fact status, uncertainty and truthful wording.

3. test_competence_social_and_wellbeing_gates.py
   test_required_five_turn_semantic_lab_sequence

   Runs news → wait command → residence question → bite question → apparel compliment.
   Asserts semantic patterns, branches, actions and grounded answers.

4. test_contextual_social_reactions.py
   test_typoed_hostility_keeps_recognized_social_route

   Input fuck ypuuuu.
   Asserts HOSTILE_REMARK, profanity pattern, hostile branch and negative relationship effect.

5. test_semantic_identity_wellbeing_collision.py
   test_wellbeing_and_need_reports_do_not_become_identity_claims

   During a pending player-name exchange, wellbeing/hunger reports must remain WELLBEING/HUNGER instead of identity claims.

Review the remaining candidates using the same rule. Do not simply relabel them LOW_LEVEL again.

### Mandatory hub remainder

This behavioral outcome is still only imperative:

    rejected stale click
    → reopen hub
    → same semantic choice remains available

Keep stale-frame rejection mechanics in Python if appropriate. Move the no-semantic-suppression outcome into fixture authority.

### Classification schema requirement

Regenerate TEST_CLASSIFICATION.json.

Every direct-worker method must have:

    name
    category
    usesDirectWorker
    reason

For behavioral methods temporarily retained during parity, also record the canonical fixture target/reference.

For LOW_LEVEL direct-worker methods, reason must name the exact mechanism, for example:

    stale suggestion-frame replay rejection protocol
    provider registry normalization and ordering
    Lua worker READY/QUIT process lifecycle

Reject generic reasons such as:

    Implementation runtime contract
    real worker test
    worker protocol

unless the exact concrete mechanism follows.

Add a static test that fails if a direct-worker LOW_LEVEL method lacks a non-generic reason.

### A6R24 gate

Accept only when:

- all 66 current LOW_LEVEL direct-worker modules have been reviewed method-by-method;
- every semantic behavior has fixture parity before duplicate Python behavior is removed;
- stale-click no-suppression is fixture-owned;
- every retained direct-worker imperative method has a specific method-level reason;
- classification guard passes;
- fixture lint and full semantic fixture corpus pass.

Continue automatically.

---

## A6R25 — finish active identity cleanup and make the acceptance vector reproducible

### Active naming remainder

File and test-symbol naming is largely clean, but active current module/API/dataset descriptions still contain milestone archaeology.

Examples found in active Core surfaces:

- S6M8 three-repository ConvoEngine integrity...
- Bounded C7F held-out scoring...
- S10C/S10R2 Feature Acceptance Registry...
- current errors saying C7F holdout ...
- held-out dataset title containing C7F.

PNC also still has current docstrings such as:

- Manually reviewed Phase 0B baseline matrix...

Rename current user/agent-facing descriptions by responsibility.

Do not rewrite historical archive documents or migration comments that are only provenance.

### Reproducibility problem

The previous final handoff records Core + Hoomans only, but broad acceptance consumes DynamicTrading directly.

Audit found:

- 20 Core test files reference DynamicTrading;
- 6 PNC test files reference DynamicTrading;
- some tests derive the live sibling repo;
- some tests contain absolute /home/psychopatz/Zomboid/Workshop/... paths.

Therefore a Core+Hoomans git archive is not necessarily an isolated exact vector.

### Required fix

Make broad acceptance reproducible from an explicit sibling workspace containing:

    PsychopatzCore
    ProjectHoomans
    DynamicTrading

Record DynamicTrading's commit even if it remains read-only and unchanged.

Current audited DynamicTrading dependency:

    1fac47cdb1ff5ced7b2951634511859a0d276df3

Tests needing real repository content must derive paths from reconstructed workspace/repository roots or an explicit test-workspace parameter/environment.

Literal absolute paths may remain only when they are pure string fixtures for path-parsing tests and never read/write the filesystem; comment those exceptions.

Add a static/reproducibility guard for live absolute workspace dependencies.

### A6R25 gate

Accept only when:

- current module/API/error/dataset descriptions no longer expose irrelevant milestone codes;
- historical archives remain untouched unless operationally consumed;
- broad acceptance can run from a reconstructed three-repo sibling workspace;
- DynamicTrading read-only commit is recorded as part of the dependency vector;
- tests do not silently read/write a live external sibling outside the reconstructed workspace;
- no unrelated DynamicTrading changes are made.

Continue automatically.

---

## A6R26 — final exact-vector and documentation closure

### Current documentation defect

Previous closure docs disagree:

- HANDOFF says 228 cases and COMPLETE;
- README/AUDIT/RUNBOOK say 226 cases;
- AUDIT says COMPLETE while still listing old 7F+1E, sidecar, registry and 25-worker failures as unresolved.

Do not preserve this contradiction.

### Final validation

After A6R23–A6R25, reconstruct all acceptance repositories at exact recorded commits in one isolated sibling workspace.

Run:

1. full Core unittest discovery;
2. full PNC unittest discovery;
3. Core + PNC naming/static/import/classification guards;
4. fixture lint + overlap report;
5. full canonical semantic fixture corpus;
6. held-out evaluator suite;
7. focused retained mechanism suites affected by A6R24;
8. worker/Tk lifecycle check before and after broad suites.

Record exact counts and runtimes.

Require:

    Core broad discovery PASS
    PNC broad discovery PASS within 900s
    0 new test-owned Lua workers after each broad suite
    0 Tk cleanup errors
    0 direct test-to-test imports
    0 unresolved active rename references
    0 missing direct-worker method reasons
    fixture lint errors = 0
    exact fixture duplicates = 0
    naming violations = 0
    domain/path mismatches = 0
    full fixture corpus PASS
    held-out evaluation PASS

### Final documents

Only after the exact reconstructed vector is green, reconcile:

- README.md
- ROADMAP.md
- PROGRESS.md
- HANDOFF.md
- ARCHITECTURE.md
- AUDIT.md
- HARNESS_ACCEPTANCE.md
- AGENT_RUNBOOK.md
- TEST_CLASSIFICATION.json

All counts and commits must match current evidence.

Final AUDIT must summarize resolved final evidence. It must not retain unresolved pre-fix prose under a COMPLETE heading.

### Final Git order

If Core changed:

1. commit accepted PsychopatzCore participant work;
2. DynamicTrading stays read-only unless an exact required fix was explicitly justified;
3. commit ProjectHoomans implementation/provider/docs last.

Final HANDOFF must be part of the final Hoomans commit.

It must record the exact dependency vector, including DynamicTrading:

    checkpoint_mode: committed_handoff
    state: COMPLETE
    parent_status: COMPLETE
    phase: A6R26
    phase_commit: self
    participant_commits:
      PsychopatzCore: "<exact commit>"
      DynamicTrading: "<read-only dependency commit>"

No goal-owned Hoomans commit may follow that handoff. If final verification requires another fix, reopen the handoff and close again afterward.

---

## Non-goals

- no new semantic tester;
- no parallel behavioral schema;
- no arbitrary worker-method fixture escape hatch;
- no migration of genuine mechanism tests merely for uniformity;
- no mass deletion based on counts;
- no rewriting historical archives to cosmetically remove old phase names;
- no push, PR, tag, release, amend, rebase or force update without authorization.
