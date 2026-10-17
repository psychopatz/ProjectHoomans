# Dialogue real-worker acceptance contract

## Required path
Use `tools/semantic_harness/` and the real production Lua worker. Validate its module manifest includes Core parser and PNC policy/input modules, and that turns invoke the real `DialogueInput.Submit`. JSON fixtures are allowed as reproducible inputs, **not evidence of behavior by themselves**. Mocked native network/relationship adapters do not prove PZ singleplayer or multiplayer.

From a safely synchronized ProjectHoomans checkout and compatible Core checkout, run:

    tools/semantic_harness/run_harness.sh --doctor --doctor-json
    python3 -m unittest discover -s tools/semantic_harness/tests -v
    tools/semantic_harness/run_harness.sh --test pnc_semantic
    tools/semantic_harness/run_harness.sh --cli --jsonl --case tools/semantic_harness/scenarios/identity_exchange_case.json

Add an isolated new scenario/test based on the user's reported conversation; do not replace existing expected cases. Inspect real worker trace: `ir`, `diagnostics.matchedPattern`, `decision.branch`, candidate eligibility when available, pending identity, active flow/node, message text/translation key, `transport`, `toolCalls`, relationship before/after, `contextBefore/After`, `llmCalls`, and `loadedModules`. If a missing field must be surfaced, expose **production truth**, not separately reimplemented Python logic.

## Mandatory regression matrix
| Transcript/input | Acceptance |
| --- | --- |
| Identity question; wellbeing interruption; `im fine thanks` | Acknowledge wellbeing; **no identity_claim/evasion** transport/relationship penalty; identity may remain suspended |
| Same with `I'm fine, thank you` | Same safe wellbeing intent and effect-free route |
| Identity question; `My name is Alex` | Explicit typed claim can reach existing server-validating request path |
| Identity question; `I'm Alex` | Accept only when unambiguous/eligible; clarify if doubtful |
| Identity question; `I'm fine` / `im hungry` | Must not be validated as a name |
| Identity question; unrelated question | Non-punitive interruption, bounded state |
| Invalid explicit name claim | Server validation/relationship semantics unchanged for genuinely explicit lie |
| Preview twice and submit once | Same preview result; only one accepted state transition/effect |
| Two nearby NPCs, different addressees | No cross-NPC pending-name or topic leakage |
| Fuzzy or low-confidence command | Cannot reach unauthorized inventory/task/relationship operation |
| EN/TL and PBrainZ disabled | Deterministic response routes and stable translation keys |

## Evidence and performance
Record SHA for Hoomans/Core, Lua/Python versions, exact command, scenario ID, actual IR/branch/candidate trace, before/after side effects, module manifest and pass/fail. Run affected Lua smoke tests, broader regressions and Code/translation audits. Native SP/MP, GUI flow inspector and live PBrainZ each have **distinct** gates; never mark unrun checks passed. Measure bounded worker latency/context-size baseline before introducing caches or new global scans.

## Acceptance distinction
Conflict ledger `conflicts=[]` proves only bounded protocol consistency. An attractive displayed sentence proves only presentation; accepted semantic behavior must include correct candidate, flow transition, context and authoritative-effect safety.
