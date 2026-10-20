# Roadmap — Semantic Lab reusable visual authoring & NPC conversation

**ACTIVE PARENT: V1–V5 IN PROGRESS.** Opened 2026-10-20 from published existing ProjectHoomans `main` `5fa019e072893fe0c9c37ae98f8db8363b5fb2a1`. Previous B0–B6, H0–H4 and F1–F4 modules are implemented; agent-reported F4 developer regression evidence includes 268 Python, 33 focused, 853 Lua, zero Kahlua errors and a Tk/X11 GUI probe. Those were not rerun by this docs-only update. They are **preserved accepted foundation for the previous bounded implementation**, not proof that the expanded reusable visual graph composer, unified semantic fact-value localization, personality-aware disclosure and complete record measurements already exist.

| Phase | Status | Required developer result |
| --- | --- | --- |
| B0–B6 / H0–H4 / F1–F4 | HISTORICAL IMPLEMENTATION + AGENT-REPORTED ACCEPTANCE, preserved | Seeded backstory, Knowledge/Dossier, existing CodeBuilder and typed InteractionSpec, 4-block structured backstory composer, Core-backed full-sentence EN/TL responses, distinct familiarity tiers, real worker/harness |
| **V1 — reusable typed visual composer** | **CURRENT / NOT ACCEPTED** | Editable/reconnectable typed nodes and edges through existing Studio, canonical InteractionSpec, generated real Lua/EN/TL, altered NPC behavior; at least backstory + another registered semantic interaction |
| V2 — Core-backed semantic fact values | PLANNED | Newly authored fact-content translations resolve via existing registered `PNC.Translation`/Core manager, keeping older legacy consumers and player privacy intact |
| V3 — individual willingness to disclose | PLANNED | Existing familiarity tiers enhanced with properly owned approval/personality/context, legitimate disclosure/evidence/refusal and two-player isolation, no extra large ModData |
| V4 — complete footprint and inspector | PLANNED | Same-codec actor and sparse Knowledge footprint for 0/1/10 learned facts, synthetic scale, legible inspector linking CodeBlocks→actual spoken text/dossier/effects |
| V5 — full real tool acceptance | PLANNED | Real Tk Studio composition→approved correct mod files→fresh Core+Hoomans worker→EN/TL and scoped Knowledge/Dossier, changed graph changes final response, full regressions, true developer handoff |

**CONTINUOUS /goal:** one coherent implementation chunk at a time; after acceptance immediately continue through all V1–V5. The parent cannot finish at V1 or because tests/commit passed. **No new Git branches, use existing main only; never create/update `GOAL_PROMPT.md`**. Native Project Zomboid SP/MP and Workshop work remain user-owned.

Canonical detailed phase design: `V1_V5_VISUAL_AUTHORING_AND_RUNTIME_CONSOLIDATION.md`. Exact one CURRENT execution chunk: `PROGRESS.md`. Former ledger archived in `HISTORY_F1_F4_20261020.md`.
