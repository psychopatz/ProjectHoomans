# Contextual Dialogue & Quest Framework — Semantic Lab

**CURRENT APPROVED PRODUCT OBJECTIVE (2026-10-20): V1–V5 — turn the existing structured grounded-NPC-dialogue CodeBuilder into a reusable VISUAL typed CodeBlocks authoring environment, consolidate registered semantic fact localization, personalize gradual disclosure, measure complete storage and verify through the real Semantic Lab GUI and Core+Hoomans worker. PARENT GOAL IN PROGRESS.**

**Preserve working code:** B0–B6, H0–H4 and F1–F4 have substantive implemented and agent-reported developer-tested Lua, Knowledge/Dossier/PBrainZ, CodeBuilder, EN/TL and GUI. F4 baseline is `5fa019e072893fe0c9c37ae98f8db8363b5fb2a1` on existing `main`. Do **not** rebuild the parser, translator, NPC backstory generator, Knowledge service, Dossier, GUI, CodeBuilder compiler or worker. The new V phase is an approved broader capability, not proof that F1–F4 code failed.

**Architectural principle:** ONE Semantic Lab Studio+Simulation, one canonical typed InteractionSpec and existing CodeBuilder/writer; visually configure nodes/ports/edges and produce actual mod Lua/EN/TL files after effect-free preview and explicit approval, test final replies and server-permitted knowledge in the actual worker, then iterate. The current four-block fixed backstory form is a good baseline, not the final generic composer. Preserve older `semantic.codeblocks.v1` action-flow support via compatibility.

## Read order

Root `AGENTS.md` → this `README.md` → `AGENT_RUNBOOK.md` → `ARCHITECTURE.md` → **`V1_V5_VISUAL_AUTHORING_AND_RUNTIME_CONSOLIDATION.md`** → `AUTHORING_WORKBENCH.md` for existing GUI context → `ROADMAP.md` → `CONVERSATION_ACCEPTANCE.md` → `PROGRESS.md` **LAST** for exactly one CURRENT implementation chunk (V1). Former full F1–F4 progress is verbatim in `HISTORY_F1_F4_20261020.md`; the prior `FINAL_ACCEPTANCE_CLOSEOUT.md` is historical, not active next-chunk instructions.

**Execution:** ONE safe bounded chunk at a time, but FULL autonomous V1→V5 goal completion required. No new Git branches; existing `main` only, verify actual local concurrency first. All native Project Zomboid SP/MP and Workshop activities are user-owned. **No `GOAL_PROMPT.md` in repo:** ChatGPT provides executable `/goal` text in chat only.
