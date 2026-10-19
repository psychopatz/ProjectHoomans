# Roadmap — Grounded NPC Personal Dialogue, Seed/Deltas, Knowledge and Dossier

**PARENT GOAL STATUS: IN PROGRESS until the entire B0–B6 implementation/integration is complete; one chunk at a time is a safety protocol, not a stopping condition. Immediately continue after each accepted chunk without requesting another /goal.**

**Phase opened 2026-10-20 from audited remote `263c132ea87678024cd81f8310bb85608dec28df`.** The previous C7A–C7G implementation is **recorded developer accepted** (244/244 harness, 68/68 Lua smoke, 16/16 compiler, per historic ledger). No new worker/GUI/backend tests were executed by this docs-only commit. User-observed out-of-sample compliment/inventory bug and desired protected personal-knowledge gameplay open a NEW product gate; do NOT rerun C7/earlier work unnecessarily. The ONE active chunk is in `PROGRESS.md`.

| Phase | Status | Meaningful developer result |
| --- | --- | --- |
| R/C7 (earlier) | RECORDED ACCEPTED in `HISTORY_C7_20261020.md` and earlier ledgers | Existing Studio, parser, dialogue plans, social/quest authority, reviewed language, context and real worker acceptance preserved |
| **B0 — Semantic correctness + backstory feasibility** | **CURRENT / NOT ACCEPTED** | Real worker routes short evaluative clothing compliments to social reaction with **zero inventory transport**, while explicit inventory questions still query; source-backed backstory replay feasibility |
| B1 — Identity-seed stability and sparse deltas | PLANNED | Version/epoch-pinned backstory selection, no silent reroll on catalog changes, minimal override IDs only where truly needed; save size measured |
| B2 — Offline personal fact-provider integration | PLANNED | Hometown/former job/hobby from existing backstory APIs answered via existing DialogueFacts/Knowledge owners, distinguish current residence/medical |
| B3 — Graceful Knowledge disclosure | PLANNED | Per-descriptor familiarity/approval/privacy/consent gates, earned evidence; milestone is opportunity not automatic reveal; MP player isolation |
| B4 — Dossier learned-background display | PLANNED | Existing descriptor/snapshot-driven History UI shows confirmed/suspected only for authorized player; no secret leak/client truth |
| B5 — Backstory-aware personal conversation | PLANNED | Multi-turn follow-ups, tone/personality, privacy refusal and optional PBrainZ filtered parity using same truth/knowledge |
| B6 — ModData, scale, EN/TL and acceptance | PLANNED | Compare before/after serialized sizes, zero-added-payload ordinary NPCs, deterministic saves, lazy cache, 100-NPC baseline and synthetic larger load, no all-NPC tick scan; READY FOR USER LIVE TEST only after real developer gates |

**Exact design/acceptance:** `GROUNDED_PERSONAL_DIALOGUE_B.md`; next executable chunk: `PROGRESS.md`. Use existing identitySeed and stable generator epoch, seed-derived fact selection, sparse exceptions, server `PNC_NPCKnowledge` as sole player knowledge store, descriptor-driven Dossier and authoritative game data. No local multiplayer host, native Project Zomboid launch, Workshop operations or repeated CUA polling by Codex.
