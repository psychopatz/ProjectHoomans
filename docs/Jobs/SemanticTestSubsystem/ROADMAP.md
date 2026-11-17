# Roadmap — A6R19–A6R22 Estate-Wide Final Remediation

**Parent status:** COMPLETE.
**Active phase:** A6R22 (closed).
**Completion boundary:** A6R19–A6R22 accepted.

## A6R19 — broad-suite integrity, hermeticity, and dependency repair

Focused tests are insufficient. Current full Core discovery:

    275 tests
    7 failures
    1 error

Deterministic failures/root causes already verified:

- variation auditor reports 0 families because current manifest `convo_engine` entries are compact `psychopatz.psdl.v2`, while the auditor only extracts direct dialogue/realization documents;
- ConvoEngine Studio camp simulation and `--response-codebuilder-lineage` fail with `textSidecars requires a sidecar loader`;
- field registry is missing `_authoringSchema` and `action`;
- feature registry misses `app.fixture_run_button`, `app.fixture_cancel_button`, `app.fixture_domains_button`;
- PSDL studio/catalog test expects old `psychopatz.convo-engine.v1` while current DynamicTrading source is compact `psychopatz.psdl.v2`; resolve against current architecture rather than forcing the old schema;
- provider-lifecycle suite passes 4/4 alone but produced a READY timeout in full discovery, indicating order/resource isolation debt;
- full Core discovery emits Tkinter `Variable.__del__` / `main thread is not in main loop` cleanup errors.

ProjectHoomans also has a current broken test:
`test_interaction_dialogue_content_editing_contract.py` imports removed `test_convo_engine_s9_regressions`; that module runs 2 PASS / 1 ERROR.

Structural prevention:

- Core has 12 direct test-to-test imports;
- PNC has 20 direct test-to-test imports.

Extract reusable helpers into descriptive support modules and add a static gate forbidding imports from `.tests.test_*`. This is the root fix for rename fragility.

The exhaustive PNC discovery audit was terminated after >20 minutes because it accumulated **25 live Lua worker children**. Full-suite worker/Tk lifecycle must be hermetic: no leaked worker descendants/orphans at completion.

**Gate:** full Core discovery and full PNC discovery both terminate cleanly, pass, and leave zero test-owned Lua/Tk resources; live internal imports resolve; no direct test-to-test helper imports remain.

## A6R20 — active identity and compatibility cleanup

Filename cleanup alone was too narrow.

Clean current agent/user-facing identity across Core + PNC:

- 25 milestone-coded Core test method names across 9 files;
- PNC historical class/method names such as R2/B2/H3/H4/R6/R9;
- public CLI/help strings still saying S10/S10B;
- canonical milestone IDs such as `contextual-semantic-phase6-performance`, `psychopatz.convo-engine.s8r1-psdl-inventory.v1`, and phase values `S0` / `S6M2A`;
- C7F/S6M/S8R/G8/G9 labels in active module/API descriptions where they are current identity rather than historical commentary;
- `audit-s6m8`: remove unless real compatibility is demonstrated, otherwise keep only as an explicitly deprecated, warning-emitting, tested alias.

Rename the 10 fixture-owned synthetic IDs still carrying A1/A6R2/H4 history (beat/behavior/flow IDs, bootstrap request/NPC/player IDs).

Do **not** rewrite historical archive docs merely to erase provenance. Update current normative docs or live machine-readable inventories only when stale paths/identities are operationally consumed.

Extend guards beyond filenames to active test symbols and canonical user/machine identities, with allowlists only for real protocol/version IDs.

**Gate:** active test symbols, UI/CLI help, canonical schemas/kinds/operation identities, fixture-authored synthetic IDs, and live references are descriptive; compatibility aliases are explicit and tested.

## A6R21 — exhaustive behavioral-authority sweep

Do not use another shortlist.

Current ledger is module-level and masks mixed suites:

- 171 modules / 702 methods;
- 66 LOW_LEVEL direct-worker modules / 278 methods;
- 35 generic `Implementation runtime contract` entries / 147 methods.

Upgrade classification to record **method responsibility** for every direct-worker LOW_LEVEL method:

    behavioral semantic scenario/outcome → fixture authority
    implementation mechanism/protocol/algorithm → imperative authority

Review all 66 modules, prioritizing high-overlap families already identified:
automatic flow generation; discourse/context repair; identity/wellbeing collision; semantic dialogue flows; suggestion ranking/stability; social reactions; command/clarification; needs/offer resolution; localization/fallback; combat awareness; interaction preview/arbitration; hub presentation suppression; companion/order/social/interaction lifecycle suites.

Mandatory remaining hub behavior:
accepted choice hidden for NPC/day, next-day restore, NPC scoping, and rejected stale click not suppressing behavior. Keep reset/cache/stale-frame implementation mechanics in Python where appropriate.

Add the smallest generic typed fixture/session operations only when needed; never arbitrary worker dispatch.

Regenerate `TEST_CLASSIFICATION.json` with method-level reasons. Generic file-level prose is not sufficient for mixed suites.

**Gate:** every remaining direct-worker LOW_LEVEL method has a specific mechanism reason; all semantic behavior has fixture parity before imperative duplication is removed.

## A6R22 — exhaustive exact-vector closure

Closure requires broad evidence, not a hand-picked vector.

From clean reconstructed commits run:

- full Core unittest discovery;
- full PNC unittest discovery;
- Core + PNC naming/static/import guards;
- fixture lint + overlap report;
- full canonical fixture corpus;
- held-out evaluator suite;
- retained mechanism suites affected by migration;
- worker/Tk leak check before and after suites.

Require zero live broken renamed-path/module references and zero test-owned descendants after completion.

The final Hoomans handoff must be written **after** the last goal-owned fix. The previous handoff commit `c3acb70d` is invalid as a final baton because its exact vector fails the held-out import and current HEAD is the later `d990032e`.

Commit Core participant first, ProjectHoomans primary/job repo last. Reconstruct that exact vector and rerun acceptance. No goal-owned commit may follow the final `committed_handoff`.

## Non-goals

- no new tester/schema;
- no mass deletion based on counts;
- no rewriting historical archives merely for cosmetic naming;
- no DynamicTrading edits unless an exact failing cross-repo contract requires them;
- no push/publication.
