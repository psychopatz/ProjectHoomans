# Contextual Dialogue & Quest Framework — Project Hoomans

**CURRENT goal (2026-10-20): B phase — Grounded Personal Dialogue, Sparse Backstory, Knowledge & Dossier.** The previously implemented Semantic Lab R/C7 work remains accepted at its *recorded* developer gates; it is not a substitute for the user's newer real conversation example. User observed `nice dress` → generic misunderstanding and `you got nice dress` → wrong inventory question/query. The immediate objective is to fix that semantic collision, then reuse EXISTING identity-seeded NPC backstory, Knowledge disclosure and dossier systems rather than creating competing modules.

The authoritative new phase design/low-ModData contract is `GROUNDED_PERSONAL_DIALOGUE_B.md`; `ROADMAP.md` has phase order; **`PROGRESS.md` defines exactly ONE current Next Chunk: B0**. Prior C7 ledger is archived verbatim in `HISTORY_C7_20261020.md`, preserving recorded 244/244 harness, 68/68 Lua smoke and 16/16 compiler results. It has NOT been rerun for B. Older ledgers are not active instructions.

**Full-goal execution:** Codex must implement and verify ALL B0–B6 phases autonomously, one safe bounded chunk at a time with immediate continuation, and may not stop after B0 or mark a passing subphase as completed overall. Final handoff only after all developer acceptance, before user-owned native PZ testing.

**Goal:** NPC identity seed + catalog epoch → deterministic personal truth → sparse authored/event deltas → existing read-only fact resolver and server Knowledge disclosure → player-character-scoped discovered evidence → existing descriptor-driven NPC Dossier. NPCs converse about known past, current residence and remembered events with gradual consent/familiarity-based knowledge sharing. PBrainZ must use a filtered permitted subset; native PZ live testing belongs to the user.

## Read order

Root `AGENTS.md` → job `AGENT_RUNBOOK.md`, `README.md`, `ARCHITECTURE.md`, **`GROUNDED_PERSONAL_DIALOGUE_B.md`**, `CONVERSATIONAL_COMPETENCE_C7.md` (historical context), `CONVERSATIONAL_INTELLIGENCE.md`, `DATASET_CONVERSATION_PIPELINE.md`, `ROADMAP.md`, `HARNESS_ACCEPTANCE.md`, `CONVERSATION_ACCEPTANCE.md`, **`PROGRESS.md` LAST**. For exact service contracts read `docs/Systems/NPCKnowledge.md`, `docs/Systems/Persistence.md`, `docs/Systems/Relationships.md`, `docs/Systems/SocialProfiles.md` and current source, not just historical prose.

Do not introduce another NPC profile store, new Knowledge subsystem, second parser/dispatcher, runtime LLM or large ModData chat corpus. Keep game-specific CodeBuilder/Lua in correct module paths. Read actual local Git state before modifying it.
