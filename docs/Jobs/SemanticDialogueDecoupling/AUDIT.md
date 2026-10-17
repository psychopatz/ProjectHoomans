# Final new-commit audit — 2026-10-17

## Revision and evidence
- Verified GitHub `psychopatz/ProjectHoomans` **main HEAD `105dadedd31c57be64a3622c4a1f6d2d6f402d35`**, commit "feat(semantic): enhance identity handling and interruptions in dialogue". Parent `1460b6cc9f79c94559b6010feedc8cd10d7fb44f` committed earlier *non-unified* planning documents.
- Verified GitHub `psychopatz/psychopatzCore` main `0212491d2af3597cceaa7353e62f01ef54adca44` as the **remote** reference. The actual agent must inspect its local dependency checkout and any divergent work before execution.
- Agent previously reported Python Semantic Lab **90/90 PASS**, Lua semantic **66/66 PASS**, `git diff --check` PASS and PZ verifier with no production Kahlua/i18n regressions. Those are **agent-reported**, not rerun by this planning/audit session. Source commit now includes tests that previously appeared uncommitted. GitHub Actions listed 0 workflow runs; no CI pass was independently established. No controlled native Project Zomboid SP/MP replay has been established.

## What the new commit actually changed
- `SemanticCatalog/PNC_SemanticCatalog_Identity.lua`: adds a bounded stop-word list to broad `im`/`i'm`/`i am` + `any_phrase` (1–2 tokens) name capture, excluding common state words (`fine`, `hungry`, `thirsty`, `thanks`, etc.).
- `SemanticCatalog/PNC_SemanticCatalog_ConversationPatterns.lua`: explicitly recognizes `thank you` and `thanks` in authored first-person wellbeing variants.
- `PNC_SemanticDialoguePolicy_Classifiers.lua`: identity evasion only on `REFUSE`/`DISAGREE`, not normal questions, self-state reports or topic changes.
- `PNC_SemanticDialogueContextState_Turns.lua`: retains pending identity across interruptions, retires it on a name claim or explicit refusal/disagreement.
- `PNC_SemanticDialoguePolicy_IntentBranch.lua` and client `PNC_SemanticDialogueInput_Requests.lua`: preserve identity-specific routing with server-side request boundary.
- `tools/semantic_harness/tests/test_semantic_identity_wellbeing_collision.py` (212 lines) and modified `test_harness.py` cover real production Lua parse/decision, safe questions, wellbeing/need reports, explicit truthful/false claims, refusal, delayed answer and preview idempotence. These are *tests present in code*, not independent test execution evidence.

## Still structurally risky (not claimed as a newly reproduced bug)
- Static stop-word exclusions are containment, not a typed semantic name-slot system. Valid unusual names or future new self-state phrases could still cause ambiguity; do not blindly expand exception wordlists.
- Policy remains a centralized intent-to-branch chain. Identity obligation has no general reusable flow-state machine, explicit interrupt stack or lifecycle policy established by this audit. `REFUSE`/`DISAGREE` with a pending identity may still require scoped intention checks when other question/offer flows coexist.
- New real-worker tests begin with `who are you`; a single test spelling out every NPC+player line of the screenshot exchange has not been identified. Phase 0 should add *one* full-conversation parity trace rather than reimplement the completed fix.
- Real game server authority, SP/MP UI, multi-participant state, session expiration and save/rejoin interactions remain native acceptance; the harness's mocked server-adjacent behavior is not proof of native multiplayer.

## Latest translation inventory (main at audited SHA)
- `common/media/translation/EN/Conversation/Conversation.json`: **521 keys, 45,222 bytes**; TL sibling **521 keys, 47,704 bytes**. Keys have set parity in the current inspected revision. Major EN key families: VanillaEmote 144, ToolReply 76, Semantic 62, SocialGreeting 48, Telemetry 40, ProjectALife 20, ZombieHorde/Retreat 26. These are separate authoring owners.
- `PNC_TranslationBootstrap.lua` registers 15 custom systems and `PNC_TranslationBootstrap_Segments.lua` maintains a large first-segment mapping. `Trading/Trading.json` exists (20 EN keys) but was not in the inspected registered 15 systems; caller/routing failure still needs a real lookup test.
- Core `PsychopatzCustomTranslationManager.lua` currently constructs **one catalog per system** path `media/translation/<LANG>/<SYSTEM>/<SYSTEM>.json`, with `getModFileReader`, lazy loading and EN fallback. It does **not** recursively discover shards or manifests.
- `common/media/conversation/**/EN|TL/*.json` is already separately modular authored-dialogue material loaded through the ConversationText subsystem; do not migrate it. Native `common/media/lua/shared/Translate/<LANG>/*.json` is a different PZ-native format; keep it intact.

## Documentation reconciliation
The previously committed `docs/Jobs/SemanticDialogueOrchestrator/PROGRESS.md` still calls Phase 0 "unreproduced" and pre-dates `105dadedd31c57be64a3622c4a1f6d2d6f402d35`; it is superseded by this unified goal. The historical `ContextualSemanticIntelligence` ledger remains important evidence but has an unfinished native acceptance gate. Avoid treating either stale wording as today's implementation truth.

**Audit conclusion:** safe to PLAN a one-goal incremental refactor on top of the fixed parser/policy, not safe to claim the new flow engine, multi-file Core translations or native tests already exist.
