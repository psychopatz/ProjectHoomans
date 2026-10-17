# Contextual Semantic Intelligence — Phase 1A wellbeing reaction pilot

**Updated:** 2026-10-17  
**Status:** Accepted for the deterministic Semantic Lab gate. Native SP/MP remains open.  
**Project revision:** `2a74683a`  
**Core revision:** `0212491d2af3597cceaa7353e62f01ef54adca44`

## Scope

Phase 1A tests whether the existing `QUESTION/WELLBEING` production path reacts to contextual state without inventing facts, calling PBrainZ, or changing gameplay authority. The same utterance, `Are you okay?`, is evaluated against healthy, unknown, injured, urgent-thirst, panic and stress states.

## Boundary decision

The existing production path is sufficient for this pilot:

`QUESTION_RECEIVED` -> local response -> `resolveQuestion` -> `resolveWellbeing` -> response catalog selection.

No second reaction arbiter was added. The response catalog's selector context now treats missing or empty health evidence as selector-only `healthState="unknown"`. The routed situation remains source-faithful: unavailable health is still absent rather than asserted as healthy or injured.

The generated `semantic.question.wellbeing` pool was already at its bounded 16-variant limit. The unknown response therefore uses a separate one-variant catalog pool instead of raising the global limit or perturbing known-state precedence. Existing healthy, injured, urgent-thirst, panic and stress responses continue through the original catalog path.

## Observed real-worker matrix

| State | Routed evidence | Response identifier |
| --- | --- | --- |
| healthy | `healthState=healthy`; normal thirst | `semantic.question.wellbeing.default` |
| unknown | no health, highest need or highest emotion | `semantic.question.wellbeing.unknown` |
| injured | `healthState=injured`; treatment activity | `semantic.question.wellbeing.injured` |
| urgent thirst | healthy; thirst urgency `emergency` | `semantic.question.wellbeing.thirst` |
| panic | healthy; panic urgency `emergency` | `semantic.question.wellbeing.panic` |
| stress | healthy; stress urgency `emergency` | `semantic.question.wellbeing.stress` |

The unknown response resolves through `UI_PNC_Conversation_Semantic_QuestionWellbeingUnknown` in both EN and TL catalogs. It avoids the unsupported healthy claim while preserving the unknown routed state.

## Verification

- `tools/semantic_harness/run_harness.sh --doctor --doctor-json`: **PASS**.
- `python3 -m unittest tools.semantic_harness.tests.test_wellbeing_projection -v`: **PASS 6/6**.
- `python3 -m unittest discover -s tools/semantic_harness/tests -v`: **PASS 56/56**.
- `tools/semantic_harness/run_harness.sh --test pnc_semantic`: **PASS 66/66**.
- `python3 tests/run_tests.py pnc_semantic --harness-report /tmp/contextual-semantic-suite-phase1a.json`: **PASS 66/66**; report contained 198 events, `conflicts=[]`, and no audit truncation. These are protocol/replay observations, not semantic proof.
- Changed Lua passed the relevant Kahlua checks. Translation JSON parsed successfully and the new EN/TL key is present.
- Every matrix turn used `llmCalls=0`, with no transport events or tool calls. No gameplay side effect was introduced.

`pz-verify` also surfaced an existing whole-file token-size warning for the response catalog and two existing hardcoded identity fallback strings in the local-response file. They are outside this bounded reaction pilot and were not refactored here.

## Acceptance limits and next chunk

This gate covers the offline deterministic worker only. Native Project Zomboid single-player and multiplayer sessions were **NOT TESTED**; no UI, server admission, lease or authoritative-task claim is made.

Phase 1B is a bounded reaction-selector boundary audit: confirm that the existing local-response/catalog boundary is the sole owner of precedence, add focused diagnostics if needed, and introduce a pure selector hook only if the audit proves one is required. Phase 2 must wait for that gate.
