# Agent Runbook — Contextual Dialogue & Quest Framework

**Active approved phase (2026-10-20): B — Grounded Personal Dialogue / Identity Seed / Sparse Knowledge.** This runbook replaces stale S0A/R0A/C7A Next Chunk instructions; all previous achievements live in archival ledgers, not as current commands. `PROGRESS.md` is the ONLY authoritative current one Next Chunk, currently B0 at transition.

## Parent goal versus execution chunk (mandatory, 2026-10-20)

**Parent goal is the ENTIRE Grounded Personal Dialogue B0–B6 implementation**, not merely B0. The accepted old C7 evidence is preserved, but does not satisfy new personal history, Knowledge/Dossier/MP privacy and serialized footprint acceptance. Parent status remains **IN PROGRESS** until all developer-implementable B0–B6 gates are verified.

**One Next Chunk is a safe unit of implementation, not an instruction to STOP after it.** After every bounded chunk: implement real Lua → validate Core+Hoomans worker and negative authority → commit coherent code/tests/docs → update PROGRESS with genuine evidence → **immediately start the next unaccepted mandatory phase without another /goal**. Do not stop on a commit, docs update, passing focused suite, archive/phase acceptance, or user-owned native live-game requirement. Parallel independent safe work may continue when a chunk has a real blocker, with evidence recorded.

Only report `READY FOR USER LIVE TEST` once ALL B0–B6 developer deliverables are working together: social-vs-inventory arbitration, version-stable identity-seeded biography, sparse persisted deviations, authoritative fact-provider, privacy-aware earned player Knowledge/disclosure, dossier discovered-only views, substantive multi-turn grounded personal dialogue, PBrainZ disclosure parity and reproducible low-ModData/MP/restart tests. Native PZ SP/MP and Workshop are user-owned; never invent their acceptance. Do not duplicate existing parser, identity or Knowledge owners.

## First checks and reading

1. Inspect local Hoomans checkout HEAD/branch/upstream/working tree and the paired PsychopatzCore revision; preserve parallel-agent changes. Remote `263c132ea87678024cd81f8310bb85608dec28df` is documentary evidence, not a safe overwrite target. Never reset, stash, force push, ambiguous pull or publish to unauthorized remote.
2. Read root AGENTS, job README, ARCHITECTURE, **GROUNDED_PERSONAL_DIALOGUE_B.md**, systems Knowledge/Persistence/Relationships/SocialProfiles, ROADMAP and acceptance; read PROGRESS LAST. Archived C7 evidence is in HISTORY_C7_20261020.md; do not rerun already accepted previous phases merely because a former runbook section says so.
3. Implement ONE bounded NEXT CHUNK at a time and update PROGRESS only on real Lua/worker evidence; **continue immediately to the next mandatory chunk** within the same /goal, until full B0–B6 developer acceptance.

## System authority

- Stable biography is **computed from existing NPC identitySeed and catalog epoch**, with exceptions only for genuinely authored/canonical historical differences. Never materialize full backstory prose per NPC into ModData.
- Truth stays in NPC identity/backstory/game owners. Per-player learned values/evidence exist ONLY in existing server PNC_NPCKnowledge by character UUID and npcID, with descriptor discovery policy, CanDisclose, valid conversation lease and authorized server commit. Familiarity alone is eligibility, not auto-discovery.
- Outgoing NPC text, user dossier snapshot and optional PBrainZ must obey the same disclosure policy; raw private backstory facts are not client/LLM payloads.
- Current home/residence, health, clothing and events come from their existing mutable world owners; never mistake hometown for current location, lack of medical evidence for no bite, or guessed history for facts.
- Keep one existing Semantic Lab+embedded CodeBuilder, existing PsychopatzCore parser/IR, Hoomans ContextState/ResponsePlan/Knowledge/Quest and approved action adapters. No new duplicate systems or per-tick scans.

## Validation & stop rules

Actual Core+Hoomans Lua worker must show input→competing IR→fact/provider/disclosure authorization→final NPC response→side effects, not synthetic JSON only. Use actual Tk/X11 mouse authoring when GUI in scope, doctor, relevant Lua smoke and Kahlua/pz_verify, EN/TL parity and measured bytes/performance when ModData in scope. State skipped tests honestly. Use commits with safe explicit destination and source/artifact ownership. No unauthorised Workshop publication, installation, native Project Zomboid SP/MP launch or hosting; these are user-owned. Absence of native Codex CLI CUA surface is not a blocker. Stop only on actual shared-tree divergence, essential missing dependency/auth, or developer acceptance; never stop solely because an agent completed a documentation step.
