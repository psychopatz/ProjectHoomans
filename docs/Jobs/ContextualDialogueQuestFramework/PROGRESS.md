# Contextual Dialogue & Quest Framework — CURRENT Progress

**Updated:** 2026-10-20. **Documentation-only phase expansion to V1–V5; NO production source, Lua worker, Tk GUI or test execution by this docs update.**
**Audited remote main before transition:** ProjectHoomans `5fa019e072893fe0c9c37ae98f8db8363b5fb2a1`. Core snapshot `2179ee19307a993e186e6da661ad4212e984e0b4`; DynamicTrading snapshot `950b4f887e6f3cb3e311c659b852cbf3ec6f3883`. Actual local state and subsequent remotes must be checked by agent before implementation.
**PARENT GOAL: IN PROGRESS — FULL V1→V5 IMPLEMENTATION REQUIRED.**
**EXACTLY ONE CURRENT EXECUTION CHUNK: V1 — reusable freely editable typed CodeBlocks graph in EXISTING Semantic Lab Studio.** Once accepted, automatically proceed to V2, V3, V4, V5 within the SAME goal, without asking user to restart. Final developer handoff only when all gates pass.

## Preserved developer-complete foundation

B0–B6 + H0–H4 + F1–F4 previous objectives have real implementation on published `main`: NPC identity-seeded backgrounds and sparse deltas; Knowledge/Dossier/optional PBrainZ privacy owners; CodeBuilder typed `semantic.interaction_spec.v1` and deterministic compiler/writer; generated EN/TL catalogs and real production Lua worker; fixed four-block backstory composer; graded minimum familiarity 25/50/75; previously repaired `farmer`→`magsasaka` TL display. User native PZ remains untested by developer. Agent-reported final old acceptance: Python Semantic Lab **268 passed**, focused F4 **33 passed**, Lua **853/853**, Kahlua **0 errors**, doctor PASS, real Tk/X11 probe. Previous per-player Knowledge JSON payload reported 0 B/753 B/3297 B for 0/1/10 facts, NOT full NPC save size. These were **not independently rerun in this update**. The entire former progress ledger is archived verbatim as `HISTORY_F1_F4_20261020.md`.

## New product requirements (not yet implemented/verified as of this document update)

- Visual composer is presently `SemanticLabWorkflowPane._compose_spec`, a **prewired 4-block backstory** workflow with editable text fields. `codebuilder/codeblocks.py` mainly represents flow-node transitions; `interaction_spec.py` validates typed connections. Need one reusable editable node/edge authoring surface, backward-compatible graph conversion, two registered interaction families and real change propagation.
- Backstory `Memory.GetBackstoryText` remains backed by legacy `PNC.Conversation.TextLoader` for some fact values, while full reply templates resolve via existing Core-backed translation. Need compatible migration of **new semantic fact values** into registered `PNC.Translation`/Core system, preserving old consumers, identity and observed/suspected knowledge.
- Descriptor tiers 25/50/75 exist; additional personality/approval/context willingness must be integrated in the existing server relationship/Knowledge policy owner, without automatic discovery, unauthorized client/LLM leaks or an extra saved profile.
- Previous Knowledge byte metrics lack comparable SAME full actor record + sparse per-character Knowledge + combined totals under one serializer and consistent 0/1/10-authorized-disclosure setup. Inspector doesn't yet present a unified readable graph-node→fact→authority→localization→spoken reply→Dossier/side effects story.

## V1 — ONE current bounded chunk

1. Verify root `AGENTS.md`, fresh local `main`/upstream HEAD, other-agent changes and media watcher safety. Read `README.md`, `AGENT_RUNBOOK.md`, `ARCHITECTURE.md`, phase `V1_V5_VISUAL_AUTHORING_AND_RUNTIME_CONSOLIDATION.md`, `ROADMAP.md`, `CONVERSATION_ACCEPTANCE.md`, then **PROGRESS LAST**.
2. Audit actual Studio workflow, CodeBuilder block registry, `semantic.codeblocks.v1`, typed `semantic.interaction_spec.v1`, graph/Flow Editor and authoring service. Implement minimal **one shared editable typed graph→existing InteractionSpec** pipeline with add/edit/remove/reconnect operations and validation; maintain legacy flow behavior and declarative effect boundaries. No new GUI app/tab/compiler, no raw Lua executors.
3. In existing Tk/X11 Studio if available, visually author and EDIT two scenarios (one NPC backstory and one existing registered non-backstory interaction) with distinct graph connections/response pools. Preview must show **changed canonical spec and differing generated real PZ Lua/EN/TL assets**, with ZERO writes/effects. Approve and generate to correct mod media, repeat generate byte-stable, restart real worker and inspect differing final replies and side effects. Invalid ports/unsafe capability wiring fail closed. Protect unrelated generated files.
4. Run real service+GUI+Core/Hoomans worker regression focused on graph validation, generated outputs, no preview writes, EN/TL and action authority; record command/exit SHA and GUI evidence. Commit coherent code/tests/progress to existing `main` safely. Then IMMEDIATELY proceed to V2. No native PZ or Workshop.

**Remaining mandatory phases:** V2 registered fact translations / legacy compatibility; V3 personality-aware server disclosure; V4 complete actor+Knowledge byte profiling and readable inspector; V5 GUI/worker full acceptance and docs reconciliation. Do not stop at V1. Source of details `V1_V5_VISUAL_AUTHORING_AND_RUNTIME_CONSOLIDATION.md`. Never create `GOAL_PROMPT.md` or new Git branches.

**Status rule:** previous F4 READY was valid only for its earlier bounded structured-backstory product; this new wider V goal remains IN PROGRESS until all developer-owned V1–V5 tests pass. Native PZ gameplay and Workshop testing are user-owned.
