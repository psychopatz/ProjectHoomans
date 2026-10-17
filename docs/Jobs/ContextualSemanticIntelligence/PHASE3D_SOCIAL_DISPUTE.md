# Phase 3D — bounded contextual dispute reaction

## Gate status

The Phase 3D Semantic Lab slice is accepted on Project Hoomans branch `feat/contextual-semantic-harness-phase0a`. Together with Phase 3A apology, Phase 3B threat and Phase 3C offer, it closes the bounded Phase 3 Semantic Lab gate for the authored social families in scope. It does not claim paraphrase, group, PBrainZ or native-game acceptance.

Implementation revision: `864b118f` (`feat(semantic): add contextual dispute reactions`).

## Scope and design

The existing deterministic parser recognizes `I disagree` as `DISAGREE/DISAGREE`, and the existing policy routes it to `SOCIAL_ACKNOWLEDGED`. Phase 3D keeps that route and extends only the existing `semantic.refuse` response pool:

1. pending request, existing authorized response raised to priority 5;
2. stressed/panicked emotion with urgency at least moderate, priority 4;
3. friendly/protective social style, priority 2;
4. trusted relationship state, priority 1;
5. withdrawn social style, priority 1;
6. existing neutral default.

The pending-request precedence is intentional: when a prior `follow me` request is pending, `I disagree` keeps the existing request-specific refusal response instead of replacing an obligation-aware response with social tone. The dispute turn itself emits no new command, tool call or relationship mutation.

The existing self-reflection pool already supplies reassurance variants for friendly, established/trusted, withdrawn, stressed and default contexts. The audit found those conditions active in the real worker and did not duplicate them or add a second reassurance selector.

Presentation maps the four new dispute identifiers plus the request-specific response to EN/TL translation keys. The real worker emitted the new localized keys on ordinary dispute turns and the request-specific key on the pending-request case.

## Evidence

- `python3 -m unittest tools.semantic_harness.tests.test_contextual_social_reactions -q`: **PASS 6/6**.
- `python3 -m unittest discover -s tools/semantic_harness/tests -q`: **PASS 65/65**.
- Existing `test_self_reflection_response_uses_relationship_and_traits`: **PASS** within the full suite, covering friendly and established/reserved reassurance responses.
- `tools/semantic_harness/run_harness.sh --doctor --doctor-json`: **PASS**.
- `tools/semantic_harness/run_harness.sh --test pnc_semantic`: **PASS 66/66**.
- `python3 tests/run_tests.py pnc_semantic --harness-report /tmp/contextual-semantic-suite-phase3d.json`: **PASS 66/66**; 198 events, `conflicts=[]`, `audit_truncated=null`. These are protocol/replay observations and are not semantic proof.
- EN/TL conversation JSON parsed with 521 keys each; all four new dispute keys and `UI_PNC_Conversation_Semantic_RefuseRequest` are present. Changed Lua files passed `luac5.3 -p`.
- `pz-verify` over `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics`: Kahlua **0 errors**. Existing hardcoded-string findings in 12 files and token-size warnings in 26 files remain outside this bounded gate.

The focused cases cover friendly, trusted, withdrawn and stressed disputes, plus pending-request precedence. Ordinary disputes are deterministic (`llmCalls=0`), emit one localized NPC message, have empty transport/tool traces and equal relationship snapshots. The pending setup uses the pre-existing authorized `follow` command; the subsequent dispute emits no additional transport or tool effect.

## Phase 3 closure and limitations

Across Phase 3A–3D, the real worker now exercises contextual apology, existing reassurance/self-reflection, guarded threat, contextual offer and contextual dispute response selection through the production Lua parser/policy/catalog path. No new reaction arbiter, parser family, PBrainZ call or gameplay feature was introduced. Phase 3 evidence remains Semantic Lab evidence; empty protocol conflict ledgers do not prove semantic correctness.

Native single-player: **NOT TESTED**. Native multiplayer: **NOT TESTED**. No Semantic Lab result, empty harness transport, or running Project Zomboid process is promoted as native SP/MP acceptance evidence. The codebase graph is complete for indexed source paths at generation `2026-10-08T03:19:15Z`; changed harness tests are not indexed, and changed source paths carry `metadata_changed`, so source/test execution is the final authority for this slice.

Next chunk: Phase 4 bounded paraphrase baseline, with false-positive task/command rejection and deterministic response-ID preservation.
