# Acceptance requirements

## Baseline and parity
- Before migration enumerate actual assertions/cases and record working invocation commands; retain a reproducible baseline and exact ProjectHoomans + PsychopatzCore revisions.
- For each converted case record legacy source, case ID, original assertions/negative cases, new projections/assertions, result and reason for legacy deletion. Missing or changed behaviour is a failure, not a migration success.
- Execute both old and new against the same production revisions for pilot and representative batches; do not mark equivalent solely because both exit successfully.
- Preserve scenario state, interruption semantics, language, response realization, candidate arbitration, permissions, action/effect/transport outcomes and storage/relationship deltas as relevant.

## Runtime and isolation
- Use actual production Lua through existing LuaSemanticWorker/ScenarioSession and production catalog/translation modules. Never implement a Python semantic decision oracle.
- Prove case isolation in both directions, multi-turn continuity within a case, deterministic expansion, non-mutation of saves and original source, and faithful scenario -> production context projection.
- Assert unknown projection path, invalid schema, duplicate ID, expansion overflow and missing expected values fail loudly.
- Distinguish parser-only, policy, conversation, scene, client/transport and server-authority tests; do not promise unsupported end-to-end execution.
- Diagnostics must show source revision, case ID, turn, expected/actual, selected candidate, flow, response key/phrase, error reason and bounded trace or explicitly mark unavailable.
- Validate EN/TL, unknown/negative permissions, action non-execution in previews and generated-native-choice ownership separately.

## Regression and performance
- Run focused smoke/Lua+Python suites at each migration batch; full applicable test sets and Kahlua before P7, CodeBuilder idempotence where fixture/translation work touches it, and GUI tests only when UI changes.
- Compare baseline counts, coverage mapping, elapsed time and memory/worker startup. Do not claim token/runtime reductions without measurements.
- Result artifacts remain bounded and outside loaded media and source saves; cap/truncation is reported rather than silently accepted.
- Native SP/MP is explicitly user-owned unless separately requested; no Workshop publication.

P7 passes only after all developer-side scope is complete and verified. A phase pass or documentation existence does not pass parent acceptance.
