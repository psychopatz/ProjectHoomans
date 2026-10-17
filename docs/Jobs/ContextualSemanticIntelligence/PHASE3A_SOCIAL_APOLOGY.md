# Phase 3A — bounded contextual apology reaction

## Gate status

The Phase 3A Semantic Lab slice is accepted on Project Hoomans branch `feat/contextual-semantic-harness-phase0a`. This is a bounded vertical slice of the broader Phase 3 social-reaction gate, not a claim that offers, reassurance, threats and disputes are complete.

Implementation revision: `bdb0a68b` (`feat(semantic): add contextual apology reactions`).

## Scope and design

The existing parser already produces `APOLOGIZE/APOLOGIZE` for authored apology input and routes it to `SOCIAL_ACKNOWLEDGED`. Phase 3A keeps that IR and policy path and adds only a `semantic.apology` response catalog:

1. stressed/panicked emotion, priority 4;
2. friendly/protective social style, priority 3;
3. trusted relationship state, priority 2;
4. withdrawn social style, priority 1;
5. neutral default fallback.

The explicit precedence case is stressed plus friendly: the stressed response wins. The change does not add a reaction arbiter, alternate parser, task request, obligation, relationship update or gameplay action. `relationshipBefore` and `relationshipAfter` remain equal in every focused apology case.

Presentation maps each response identifier to a translation key. EN and TL contain all five keys; the real TL worker resolved the friendly apology to `UI_PNC_Conversation_Semantic_ApologyFriendly` and returned the localized text.

## Evidence

- `python3 -m unittest tools.semantic_harness.tests.test_contextual_social_reactions -q`: **PASS 3/3**.
- `python3 -m unittest discover -s tools/semantic_harness/tests -q`: **PASS 62/62**.
- `tools/semantic_harness/run_harness.sh --doctor --doctor-json`: **PASS**; the production worker booted and exposed the real semantic modules.
- `tools/semantic_harness/run_harness.sh --test pnc_semantic`: **PASS 66/66**.
- `python3 tests/run_tests.py pnc_semantic --harness-report /tmp/contextual-semantic-suite-phase3a.json`: **PASS 66/66**; 198 events, `conflicts=[]`, `audit_truncated=null`. These are protocol/replay observations and are not semantic proof.
- Changed Lua files passed `luac5.3 -p`.
- `pz-verify` over `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics`: Kahlua **0 errors**. The scan still reports existing hardcoded-string findings in 12 files and token-size warnings in 26 files; those are bounded maintenance findings, not evidence of a Phase 3A semantic failure.

The focused cases cover neutral, friendly, trusted, stressed and stress-over-friendly apology selection. They also preserve existing friendly compliment, combat threat and stressed self-reflection reactions. All cases are deterministic (`llmCalls=0`), emit no transport or tool calls, return no action result, and leave relationship state unchanged. A `PREVIEW` apology probe is idempotent and leaves the surrounding snapshot unchanged apart from request IDs.

## Limitations and next chunk

The broader Phase 3 gate remains open for the remaining offer/reassurance/threat/dispute audit. Phase 3B is the next bounded chunk; it must select one smallest authored gap and re-run the same context, precedence, authority and no-mutation checks.

Native single-player: **NOT TESTED**. Native multiplayer: **NOT TESTED**. No Semantic Lab result, empty harness transport, or running Project Zomboid process is promoted as native SP/MP acceptance evidence. The codebase graph is complete for indexed source paths at generation `2026-10-08T03:19:15Z`; changed harness tests are not indexed, and changed source paths carry `metadata_changed`, so source/test execution is the final authority for this slice.
