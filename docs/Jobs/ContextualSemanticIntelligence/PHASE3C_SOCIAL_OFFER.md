# Phase 3C — bounded contextual offer reaction

## Gate status

The Phase 3C Semantic Lab slice is accepted on Project Hoomans branch `feat/contextual-semantic-harness-phase0a`. It extends the broader Phase 3 social-reaction work without claiming that reassurance or disputes are complete.

Implementation revision: `c74f5966` (`feat(semantic): add contextual offer reactions`).

## Scope and design

The existing deterministic parser recognizes `want some food` as `OFFER/OFFER`, and the existing policy selects `OFFER_RECEIVED`. Phase 3C keeps that route and extends only the existing `semantic.offer` response pool:

1. stressed/panicked emotion with urgency at least moderate, priority 4;
2. existing hunger response pool, priority 2, including the generated dataset variants;
3. friendly/protective social style, priority 1;
4. trusted relationship state, priority 1;
5. withdrawn social style, priority 1;
6. existing neutral default decline.

The explicit overlap case is hungry plus highly stressed: the stressed response wins over hunger. Non-hungry friendly, trusted and withdrawn NPCs now produce distinct guarded social responses instead of the same hunger-only decline. No parser, policy branch, reaction arbiter, inventory transfer, task, obligation or relationship mutation was added.

Presentation maps the four new response identifiers to translation keys. EN and TL contain all four keys, and the real worker emitted the localized payload keys for the contextual responses.

## Evidence

- `python3 -m unittest tools.semantic_harness.tests.test_contextual_social_reactions -q`: **PASS 5/5**.
- `python3 -m unittest discover -s tools/semantic_harness/tests -q`: **PASS 64/64**.
- `tools/semantic_harness/run_harness.sh --doctor --doctor-json`: **PASS**.
- `tools/semantic_harness/run_harness.sh --test pnc_semantic`: **PASS 66/66**.
- `python3 tests/run_tests.py pnc_semantic --harness-report /tmp/contextual-semantic-suite-phase3c.json`: **PASS 66/66**; 198 events, `conflicts=[]`, `audit_truncated=null`. These are protocol/replay observations and are not semantic proof.
- EN/TL conversation JSON parsed with 516 keys each; all four new offer keys are present. Changed Lua files passed `luac5.3 -p`.
- `pz-verify` over `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics`: Kahlua **0 errors**. Existing hardcoded-string findings in 12 files and token-size warnings in 26 files remain outside this bounded gate.

The focused cases cover friendly, trusted, withdrawn, hungry existing behavior, and stress-over-hunger precedence. Every case is deterministic (`llmCalls=0`), emits one NPC message, has empty transport/tool traces and no action result, and leaves relationship snapshots equal. The offer object is carried as response arguments only; no inventory or gameplay action is executed.

## Limitations and next chunk

The broader Phase 3 gate remains open for the remaining reassurance/dispute audit. Phase 3D is the next bounded chunk; it must select one smallest authored gap and re-run the same context, precedence, authority and no-mutation checks.

Native single-player: **NOT TESTED**. Native multiplayer: **NOT TESTED**. No Semantic Lab result, empty harness transport, or running Project Zomboid process is promoted as native SP/MP acceptance evidence. The codebase graph is complete for indexed source paths at generation `2026-10-08T03:19:15Z`; changed harness tests are not indexed, and changed source paths carry `metadata_changed`, so source/test execution is the final authority for this slice.
