# Contextual Dialogue & Quest Framework — Grounded NPC Conversation

**Current goal (2026-10-20): close the remaining Semantic Lab authoring, localization, Knowledge-disclosure and acceptance gaps. PARENT: IN PROGRESS; one current chunk F1, then automatically F2–F4.** Previous B0–B6 and H0–H4 Lua/CodeBuilder/Knowledge implementation is already on published ProjectHoomans `main`; keep and extend, do NOT recreate.

Existing Semantic Lab Studio+Simulation and embedded CodeBuilder must be a REAL visual interaction composer, not just a selector validating blocks while generating a fixed dataset. Author connected parameterized CodeBlocks → produce reviewed canonical InteractionSpec/dialogue source → preview exact Lua/EN/TL file diffs, no side effects → explicitly approve → generate to correct Project Zomboid mod media folders → restart real Core+Hoomans Lua worker → see actual final NPC text, translation lookups, Knowledge decisions, dossier changes and side effects → refine and regenerate.

**Four remaining acceptance obligations:** (F1) selected blocks materially change generated dialogue; (F2) properly localize the factual content inside TL sentences using existing Core-backed translation, not simply the sentence template; (F3) differentiate commonplace and sensitive backstory disclosure with server authority and no automatic unlock; (F4) complete genuine GUI-driven real-worker acceptance, regressions and comparable ModData footprint measurements. All four must pass before the parent can be marked READY FOR USER LIVE TEST.

## Read order

Root `AGENTS.md` → job `README.md` → `AGENT_RUNBOOK.md` → `ARCHITECTURE.md` → **`FINAL_ACCEPTANCE_CLOSEOUT.md`** → `CONVERSATION_ACCEPTANCE.md` → `ROADMAP.md` → historic `HISTORY_H0_H4_ACCEPTANCE_20261020.md` only for prior evidence → **`PROGRESS.md` LAST** for the ONE current execution chunk. Older `HARNESS_FIRST_CODEBUILDER_TRANSLATION_RECOVERY.md` is historical H-phase design, not the current next-chunk authority.

Never create a Git branch. Target existing `main` only after checking actual local/head/upstream. Preserve other agents' files. No second parser/compiler, Knowledge store, translation manager or GUI. Only the user runs native Project Zomboid SP/MP and Workshop tasks.

**No checked-in prompt:** Don't create/update `GOAL_PROMPT.md`. The executable `/goal` appears in ChatGPT chat only.
