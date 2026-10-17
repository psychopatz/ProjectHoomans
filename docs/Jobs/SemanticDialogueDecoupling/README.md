# Semantic Dialogue Decoupling — one unified /goal

**Status:** documentation adopted as new implementation goal. **Runtime gameplay refactor:** NOT STARTED. **Target:** Project Hoomans B42.20 with reusable PsychopatzCore. This one job governs typed NLU arbitration, independent dialogue flows, response planning, Semantic Lab authoring, and subsystem-sharded custom translation. These are chapters/phases of ONE ROADMAP and ONE PROGRESS ledger, not separate goal agents.

## Start here
Read `AGENTS.md` and then:
1. `AGENT_RUNBOOK.md` — safe existing-checkout/main policy and one-chunk loop.
2. `AUDIT.md` — verified current code/claims and remaining risks.
3. `ARCHITECTURE.md` and `FLOW_CONTRACT.md` — stable ownership and future module API.
4. `TRANSLATION_MIGRATION.md` — internal custom-translation redesign.
5. `ROADMAP.md` and `HARNESS_ACCEPTANCE.md` — phases and real Lua gates.
6. `PROGRESS.md` — exactly one active Next Chunk.
7. `GOAL_PROMPT.md` — copyable bootstrap for a new Codex session.

Additional references: `docs/Systems/Semantics.md`, `docs/Systems/TranslationAudit.md`, `docs/architecture/PROJECT_HOOMANS_DOMAIN_CONTRACT.md`, `tools/semantic_harness/README.md`.

## Outcome
Adding a new conversation type should generally involve a small registered Lua flow (triggers, typed slots, states/transitions), references to existing contextual response planning, localized EN/TL shard(s), and executable Semantic Lab scenarios/assertions—without adding global parser-priority exceptions, giant policy switches or an ever-growing Conversation.json.

## Baseline ownership
- Current code includes the 2026-10-17 regression fix at Hoomans main `105dadedd31c57be64a3622c4a1f6d2d6f402d35`. This is a SOURCE-VERIFIED baseline; 90/90 Python and 66/66 Lua passes are AGENT-REPORTED (not independently rerun here). Native SP/MP remain NOT TESTED.
- Historical `docs/Jobs/ContextualSemanticIntelligence/` is **reference evidence**, not a second active driver of this refactor. Its native acceptance remains open and must not be declared complete.
- Earlier `docs/Jobs/SemanticDialogueOrchestrator/` planning was superseded by this unified namespace at documentation adoption. Do not recreate it or a standalone translation goal.
