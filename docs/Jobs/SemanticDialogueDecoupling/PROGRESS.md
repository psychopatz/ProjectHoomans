# Semantic Dialogue Decoupling — current evidence and Next Chunk

**As of 2026-10-17:** Phase **0** (baseline adoption) ACTIVE. **Code status:** identity/wellbeing regression fix is committed on Project Hoomans main at `105dadedd31c57be64a3622c4a1f6d2d6f402d35`; new modular flow/manifest architecture is only PLANNED. **Docs:** this unified goal replaces the older independent SemanticDialogueOrchestrator plan. **Native SP/MP:** NOT TESTED.

## Code-verified foundation
- GitHub main latest `105dadedd31c57be64a3622c4a1f6d2d6f402d35`, parent `1460b6cc9f79c94559b6010feedc8cd10d7fb44f`.
- Source includes identity stop words, `thanks` wellbeing rules, explicit refusal/disagreement-only evasion, pending-identity interruption handling, and `test_semantic_identity_wellbeing_collision.py`.
- Main `Conversation.json` now 521 EN keys and 521 TL keys; content set parity observed. Core main inspected at `0212491d2af3597cceaa7353e62f01ef54adca44` and still uses one-file custom catalogs.
- Existing contextual responses, real-Lua worker, authored conversation and optional PBrainZ remain in existing code.
- Agent-reported passes: 90/90 Python and 66/66 Lua, `git diff --check`, PZ verifier (not independently rerun here). GitHub Actions displayed no runs; no CI pass claimed. Native game acceptance not established.

## One Next Chunk: 0A — lock exact committed baseline and one full interaction trace
1. Safely inspect **actual local** Hoomans/Core HEAD, status, dependencies and in-flight edits. Do not assume remote SHA equals a clean local checkout; do not discard uncommitted data or create another branch.
2. Rerun the focused committed test, doctor, full Python Semantic Lab and Lua semantic smoke suites using exact current checkouts; record real results. Verify the dedicated collision test includes true/false names, interrupted pending identity, refusal, and preview idempotence.
3. Add a small **complete transcript** production-worker case: pending name request -> player `are you okay` -> NPC reciprocal response -> player `im fine thanks` -> (later) `My name is Patrick`. Capture per-turn IR/branch/message, pending state, translation, transport, relationship before/after and distinct NPC where possible. Do not silently patch semantics to satisfy a fixture.
4. Save baseline for 521 EN/TL keys/values/placeholders, current Core catalog API, existing 15 registered custom systems and Trading lookup trace. These are **read-only** snapshots; do not relocate translations in Phase 0.
5. Record tested Hoomans/Core SHAs, commands, pass/fail, example trace and native SP/MP **NOT TESTED**. After gate acceptance, set Phase 1's smallest typed-candidate/eligibility Next Chunk.

**Exit 0A:** production-Lua trace matches protected identity semantics, no false relationship/identity action, real suites pass without hiding failures, and catalog snapshot exists. If any gate fails, fix the smallest demonstrated issue before refactoring.

## Then
1 typed candidates -> 2 bounded flow kernel -> 3 registered identity/wellbeing -> 4 Semantic Lab inspector -> 5 optional Core multi-file loader -> 6 custom EN/TL shards -> 7 response composition -> 8 integrations -> 9 native acceptance. Update this ONE ledger only.
