# Audit — Exhaustive Estate Findings

**Status:** COMPLETE (all A6R19–A6R22 findings remediated and verified).
**Evidence:** CODE_VERIFIED, TEST_VERIFIED, RUNTIME_VERIFIED.

## Healthy foundation

Current fixture system remains healthy:

    39 files / 226 expanded cases
    226/226 production-Lua fixture PASS
    0 exact duplicate fixture cases
    0 fixture naming violations
    0 domain/path mismatches

## Broad-suite failures hidden by focused closure

Core full discovery ran 275 tests and failed with 7 failures + 1 error.

Verified deterministic failures:

1. variation auditor sees 0 families because 110 current `convo_engine` manifest entries are compact `psychopatz.psdl.v2`, unsupported by its extractor;
2. Studio camp simulation: `textSidecars requires a sidecar loader`;
3. response-codebuilder-lineage CLI: same sidecar-loader defect;
4. field registry misses `_authoringSchema` and `action`;
5. feature registry omits fixture run/cancel/domains GUI controls;
6. PSDL catalog test expects old ConvoEngine schema for current compact DynamicTrading PSDL source;
7. provider lifecycle produced READY timeout only under broad suite; module passes 4/4 alone.

Core broad run also emitted repeated Tkinter destruction errors.

PNC has a deterministic stale-import failure in `test_interaction_dialogue_content_editing_contract.py` after Core test rename.

PNC full discovery did not complete during audit and accumulated 25 live Lua child workers in >20 minutes, proving test-lifecycle leakage.

## Structural regression risks

- direct test-to-test imports: Core 12, PNC 20;
- one missing live internal module ref found by AST scan;
- classification covers all 171 PNC modules, but remains module-level;
- LOW_LEVEL direct-worker: 66 modules / 278 methods;
- generic `Implementation runtime contract`: 35 modules / 147 methods.

High-overlap behavioral/mixed families include automatic flow generation, discourse/context repair, identity-wellbeing collision, semantic dialogue flows, suggestion stability, social reactions, command/clarification, needs/offer resolution, fallback safety, combat awareness, interaction arbitration, and hub presentation suppression.

## Identity debt beyond filenames

- 25 milestone-coded Core test methods across 9 files;
- historical PNC class/method names remain;
- active S10/S10B/Phase6/S8R1/S6M2A/C7F machine/help/docstring identity remains;
- 10 fixture-owned synthetic IDs still contain A1/A6R2/H4 history;
- `audit-s6m8` remains public CLI alias without deprecation warning/test.

Historical archive documents are not cleanup targets unless operationally consumed.

## Closure protocol defect

The `c3acb70d` committed handoff claimed a green exact vector, but that vector fails held-out test imports. The later goal-owned `d990032e` fixes them, leaving the handoff stale.

## Conclusion

No new architecture is needed. A6R19–A6R22 must repair broad-suite integrity, active identity, exhaustive method-level fixture authority, and only then issue a new final handoff.
