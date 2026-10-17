# Phase 5 — bounded PBrainZ and group compatibility audit

## Gate status

The bounded Phase 5 Semantic Lab compatibility slice is accepted on Project
Hoomans branch `feat/contextual-semantic-harness-phase0a`. The audit found the
existing optional-provider and nearby-group seams sufficient for deterministic
parity, fail-closed provider fallback and speaker/participant scoping. No
production runtime behavior was changed. Live provider-success behavior and
native SP/MP acceptance remain open.

Implementation revision: `338f97e7` (`test(semantic): verify provider and group parity`).
The preceding Phase 4 implementation remains `78674253`; PsychopatzCore is
pinned at `0212491d2af3597cceaa7353e62f01ef54adca44`.

## Ownership audit

The real Lua path keeps the boundaries separated:

- `PNC_SemanticDialogueInput_ProviderFallback.SubmitProviderFallback` checks
  `context.llmAvailable` before calling `PNC.PBrainZ.Submit`; provider absence
  or rejection changes the decision back to deterministic
  `ASK_CLARIFICATION`.
- `PNC_SemanticDialogueInput_ContextProjection.Build` creates a bounded
  read-only context containing provider status, dialogue situation, semantic
  state, entity index and current topic. `PNC_PBrainZ_ContextPayload_Build`
  carries the bounded semantic fallback/IR, situation and participant
  projection into the optional payload.
- `PNC_ConversationGroup:Refresh` binds group ID, participant IDs and bounded
  participant projections to each host/session. `Group:Submit` interprets one
  canonical primary turn. Deterministic fan-out clones the primary IR, routes
  each member through its own router/context, and queues responses with the
  actual member speaker and the shared primary queue. Group-wide actions are
  dispatched once.

The codebase-memory graph project was
`home-psychopatz-Zomboid-Workshop-ProjectHoomans`, generation
`2026-10-08T03:19:15Z`, full indexing mode with no recorded parse-partial or
skipped files. Coverage checks for the 15 cited provider/group/source/test
paths returned `no_recorded_issue`; this is a best-effort graph signal, not a
completeness proof. The new Python parity test is not graph-indexed, so its
execution is the source of truth.

## Evidence

- `python3 -m unittest tools.semantic_harness.tests.test_semantic_provider_parity -v`:
  **PASS 2/2** on the real Lua worker.
- Provider disabled/enabled `follow me` produced the same `REQUEST/FOLLOW`,
  `COMMAND_ACCEPTED`, deterministic route, authorized `follow` action result,
  one transport event and one tool trace, with `llmCalls=0` in both cases.
- An unknown sentence stayed deterministic `ASK_CLARIFICATION` with no action,
  transport or tool effect. The disabled case used `llmCalls=0`; the enabled
  harness provider was attempted once (`llmCalls=1`) and rejected by the
  harness adapter, then failed closed to clarification. This is provider
  failure containment, not a successful external-provider response test.
- `python3 tests/run_tests.py pnc_semantic_group pnc_pbrainz_context
  pnc_pbrainz_provider_availability --harness-report
  /tmp/contextual-semantic-suite-phase5-focused.json`: **PASS 3/3**, 9 events,
  empty `conflicts` and no audit truncation. The group smoke preserves one
  canonical parse, per-member router/context isolation, actual speaker names,
  unique secondary request IDs, sequential response count and one group-wide
  action dispatch.
- PBrainZ semantic/integration smoke selection excluding the unrelated native
  button fixture: **PASS 11/11** in
  `/tmp/contextual-semantic-suite-phase5-pbrainz.json`, 33 events.
- `python3 -m unittest discover -s tools/semantic_harness/tests -q`:
  **PASS 69/69**. Compiler tests remain **PASS 7/7**.
- `tools/semantic_harness/run_harness.sh --doctor --doctor-json`:
  **PASS**. `tools/semantic_harness/run_harness.sh --test pnc_semantic`:
  **PASS 66/66**. CLI report
  `/tmp/contextual-semantic-suite-phase5-semantic.json`: **PASS 66/66**, 198
  events, `conflicts=[]`, `audit_truncated=null`. These protocol/replay
  observations are not semantic proof.
- `pz-verify` over the semantic directory: 76 files, **0 Kahlua errors and 0
  warnings**. The broad mod-wide warning/bloat inventory remains pre-existing.

## Known baseline limitation

The broader `pnc_pbrainz semantic_group` selection was `12/13`: the only
failure was `pnc_pbrainz_native_button_smoke.lua`, an unrelated UI fixture
that fails before semantic assertions. Its standalone fallback config still
names Core `42.19`; when the runner supplies the current `42.20` runtime, the
fixture then lacks an `ISUI/ISImage` preload. This Phase 5 semantic/provider
audit did not change unrelated UI test infrastructure.

Native single-player: **NOT TESTED**. Native multiplayer: **NOT TESTED**. The
PBrainZ enabled case uses the deterministic worker adapter, not a live bridge;
no provider-generated response, server session or game UI result is being
promoted as acceptance evidence.

Phase 5 is accepted only for deterministic/provider-failure parity, bounded
provider context and group speaker/participant isolation. Next chunk: Phase 6
native SP/MP and performance acceptance, with live-provider success still an
explicit untested limitation.
