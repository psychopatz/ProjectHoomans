# Semantic Dialogue Decoupling — one unified implementation goal

**Active state:** implementation and Semantic Lab repair; **not blocked by native game availability**. One roadmap, one progress ledger and one /goal, all under `docs/Jobs/SemanticDialogueDecoupling/`.

## Product goal

Extend Project Hoomans' offline Lua NPC conversation system so an agent can register a small, bounded dialogue flow, inspect its branch/state/response in the actual **Semantic Lab interface**, and add localized EN/TL variations without expanding a monolithic intent switch. Preserve server-authoritative actions, optional PBrainZ, existing responses and the identity/wellbeing regression fix.

## Work split (NOT separate goals)
- **Implementation and developer acceptance:** Codex owns Lua/Core integration, dialogue behavior, Semantic Lab GUI/worker repair, localized catalogs, direct regression tests and reproducible evidence.
- **Final native Project Zomboid testing:** **USER-OWNED AFTER IMPLEMENTATION HANDOFF**. The user launches PZ, decides when/where to test, and reports observed problems. No Codex PZ-process polling, forced launches, dedicated-server setup, Workshop uploads or Steam publishing steps.
- **Git commits to source repositories** are distinct from **Steam Workshop publishing**. Only the former may be performed in the already authorized Git workflow. The latter is never authorized by this goal.

## Read order
1. Root `AGENTS.md`, then `AGENT_RUNBOOK.md`.
2. `AUDIT.md` and `CORE_COMPATIBILITY.md` (latest source evidence).
3. `ARCHITECTURE.md`, `FLOW_CONTRACT.md`, `TRANSLATION_MIGRATION.md`.
4. `ROADMAP.md`, `HARNESS_ACCEPTANCE.md`, `USER_LIVE_TEST_HANDOFF.md`.
5. **`PROGRESS.md`** (the sole current Next Chunk), then `GOAL_PROMPT.md`.
6. `IMPLEMENTATION_EVIDENCE.md` holds older implementation history and test claims, not marching orders.

Supporting source: `docs/Systems/Semantics.md`, `docs/Systems/TranslationAudit.md`, `docs/architecture/PROJECT_HOOMANS_DOMAIN_CONTRACT.md`, `tools/semantic_harness/README.md`.

## Completion states
- **Ready for user live test:** Codex implementation and meaningful Semantic Lab checks complete; hand off concise scenarios and known limitations. Codex stops instead of waiting for PZ.
- **User-accepted:** after the user independently tests and accepts or requests fixes.
- **Blocked:** real code/tool/Git obstacle that prevents further implementation, not absent native app, missing Workshop publication, or an unanswered live-test request.

Do not create another goal namespace, branch/PR or TXT deliverable.
