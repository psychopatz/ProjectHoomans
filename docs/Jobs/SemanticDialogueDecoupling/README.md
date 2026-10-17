# Semantic Dialogue Decoupling — one unified /goal

**Current mode:** corrective integration and real-game acceptance. **Not maintenance-ready.** The original implementation phases 0A–8 have substantial production Lua and supporting worker-test evidence. This goal is **not** completed as an end-to-end extensible in-game dialogue authoring system.

One job: `docs/Jobs/SemanticDialogueDecoupling/`. Dialogue flow ownership, Core compatibility, translation catalogs, response composition, the Semantic Lab UI and native Build 42 validation are **phases of the same goal**, never separately managed jobs.

## Read order

1. Repository `AGENTS.md`, then `AGENT_RUNBOOK.md` (safe current-checkout/main policy).
2. `AUDIT.md` (2026-10-17 source verification and claimed vs proven behavior).
3. `ARCHITECTURE.md`, `FLOW_CONTRACT.md` and `TRANSLATION_MIGRATION.md` (existing/desired contracts).
4. `DEPLOYMENT_ACCEPTANCE.md` (Hoomans/Core installed dependency and native verification).
5. `ROADMAP.md` and `HARNESS_ACCEPTANCE.md` (corrective phases and real-game gates).
6. `PROGRESS.md` (ONE active Next Chunk); `GOAL_PROMPT.md` (new Codex bootstrap).
7. `IMPLEMENTATION_EVIDENCE.md` (archived previous progress/test claims; read for provenance, **not** current marching orders).

Canonical background: `docs/Systems/Semantics.md`, `docs/Systems/TranslationAudit.md`, `docs/architecture/PROJECT_HOOMANS_DOMAIN_CONTRACT.md`, `tools/semantic_harness/README.md`.

## Product acceptance

A registered new conversation type must choose its **real in-game** response and transitions through production Lua without requiring a new branch in a central intent switch. Both EN/TL translations resolve using the **installed** Core dependency; commands and relationships remain server authoritative. A usable visual flow inspector/editor must operate on the production registry, not a mock graph. Live SP and hosted MP evidence ultimately close the goal.

The existing identity/wellbeing regression fix at `105dadedd31c` and implemented translation shards/flow modules are protected foundations. Do not recreate them.

The user explicitly rejected adding more headless-only fixture churn as proof of success. The real Lua worker is useful supporting evidence, while live game behavior and installed-dependency parity determine product acceptance.
