# Phase 3B — bounded contextual threat reaction

## Gate status

The Phase 3B Semantic Lab slice is accepted on Project Hoomans branch `feat/contextual-semantic-harness-phase0a`. It extends the broader Phase 3 social-reaction work without claiming that offers, reassurance or disputes are complete.

Implementation revision: `c7d2124f` (`feat(semantic): add guarded threat reactions`).

## Scope and design

The existing deterministic parser recognizes the authored threat input as `THREATEN/THREATEN`, and the existing policy selects `THREAT_RECEIVED`. Phase 3B keeps that route and extends only the existing `semantic.threat` catalog:

1. stressed/panicked emotion with urgency at least moderate, priority 5;
2. busy activity, existing behavior retained at priority 3;
3. withdrawn social style, priority 2;
4. trusted relationship state, priority 1;
5. existing default and firm fallbacks.

This precedence keeps an urgent emotional boundary above immediate workload, withdrawal and relationship tone. It also preserves the existing default reserved/busy worker behavior: busy still wins when no urgent emotion is present. No parser, policy branch, reaction arbiter, task, obligation or relationship mutation was added.

The new presentation identifiers have EN/TL translation keys. The directed-hostility path currently returns no UI message in the Semantic Lab worker; the decision response remains present and deterministic, so the new keys are registered for the existing presentation boundary without claiming live delivery.

## Evidence

- `python3 -m unittest tools.semantic_harness.tests.test_contextual_social_reactions -q`: **PASS 4/4**.
- `python3 -m unittest discover -s tools/semantic_harness/tests -q`: **PASS 63/63**.
- `tools/semantic_harness/run_harness.sh --doctor --doctor-json`: **PASS**.
- `tools/semantic_harness/run_harness.sh --test pnc_semantic`: **PASS 66/66**.
- `python3 tests/run_tests.py pnc_semantic --harness-report /tmp/contextual-semantic-suite-phase3b.json`: **PASS 66/66**; 198 events, `conflicts=[]`, `audit_truncated=null`. These are protocol/replay observations and are not semantic proof.
- EN/TL conversation JSON parsed with 512 keys each; all three new threat keys are present. Changed Lua files passed `luac5.3 -p`.
- `pz-verify` over `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics`: Kahlua **0 errors**. Existing hardcoded-string findings in 12 files and token-size warnings in 26 files remain outside this bounded gate.

The focused cases cover trusted, withdrawn, stressed, and stress-over-withdrawn-plus-busy selection. All remain deterministic (`llmCalls=0`), with empty transport/tool traces and equal relationship snapshots. The authorized existing social-dispatch result is `accepted=false` with `reason=semantic_social_transport_unavailable` in the harness; this records the unavailable harness boundary and is not a semantic proof of native hostility delivery.

## Limitations and next chunk

The broader Phase 3 gate remains open for the remaining offer/reassurance/dispute audit. Phase 3C is the next bounded chunk; it must select one smallest authored gap and re-run the same context, precedence, authority and no-mutation checks.

Native single-player: **NOT TESTED**. Native multiplayer: **NOT TESTED**. No Semantic Lab result, empty harness transport, or running Project Zomboid process is promoted as native SP/MP acceptance evidence. The codebase graph is complete for indexed source paths at generation `2026-10-08T03:19:15Z`; changed harness tests are not indexed, and changed source paths carry `metadata_changed`, so source/test execution is the final authority for this slice.
