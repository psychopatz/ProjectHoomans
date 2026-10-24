# Semantic Interaction Lifecycle — Current Progress

**Updated:** 2026-10-24

**Parent status:** ACTIVE — P0A is complete; P1 is complete; P2/P3 implementation is in progress.

**Accepted predecessor foundation:** Contextual Dialogue Persona & Choices P14 complete. Preserve its save-backed production rehydration architecture.

**Audit baseline:** `e8c04b4fb2139be315253f12e0f06a5dfa3fc70f5`

**Checkout:** existing `main` only; no branch or source-save mutation.

**Native Project Zomboid:** user-owned final acceptance only; not a developer-side blocker.

## P0A — complete

`SOURCE_INVENTORY.md` records the production flavor/spontaneous-speech families, real source files and IDs, trigger/context/resolver/presentation ownership, cooldown/chance/dedupe behavior, multiplayer authority, gameplay effects, persistence dependencies, duplicate greeting/emote paths, and migration gates.

`MIGRATION_MATRIX.md` now cites actual production source owners and IDs rather than broad family descriptions. Existing characterization coverage is recorded for farewell, greeting/emote, social-event transport, incapacitated/leader-loss flavor, and typed/headless production-worker paths. No legacy flavor authority was deleted during P0A.

## P1 — complete

Production Lua now owns a bounded `semantic.interaction.envelope.v1` and `semantic.interaction.lifecycle.v1` contract. The envelope carries source, actor/target/player identity, canonical act/topic, gesture or grounded event reference, bounded fact references/modifiers, world hour, and NPC semantic provenance. It never stores rendered prose and never grants gameplay authority.

The existing typed NLU result and semantic-frame path attach the envelope after parsing/IR conversion. Existing parser, candidate, router, semantic-suggestion, ConversationBlocks, response-plan, and authoritative-domain contracts remain in place. Server emote, social greeting, ConversationBlocks choice, NPC response, and farewell adapters now expose the same bounded meaning without reparsing presentation text.

`PNC_InteractionLifecyclePersistence` is a server-only sparse ModData owner coordinated by the existing persistence commit boundary. Import is bounded and version-checked; pair state is created only for meaningful durable deltas; shared event references are canonicalized; expiry is lazy or explicitly bounded; no lifecycle OnTick scan was added.

The production Semantic Lab worker exposes envelope, apply, NPC speech, close/resume, compaction, time, event, projection, metrics, export, and import commands. Python remains transport/presentation only.

Verified developer-side evidence:

- `lua tests/pnc_semantic_interaction_lifecycle_smoke.lua`
- `lua tests/pnc_semantic_interaction_persistence_smoke.lua`
- `python3 -m unittest tools.semantic_harness.tests.test_semantic_interaction_lifecycle_p1 -v` — 5 tests pass, including a 200-turn bounded conversation, two isolated players sharing one NPC, one canonical shared event reference, 400 trivial NPC identities, and 2,000 trivial turns.
- `luac -p` and `pz_verify --kahlua --severity ERROR` pass for changed lifecycle, adapter, persistence, and authority files.
- `git diff --check` passes.

P1 does not retire duplicate legacy flavor authority and does not claim full P2–P9 completion. General UI-close transport, all grounded combat/medical/world-event adapters, full durable memory promotion policy, network projection audits, and the remaining legacy parity matrix are still open.

## Exact Next Chunk

**P2/P3A — production greeting/farewell/emote parity and lifecycle provenance.**

- complete parity coverage for every accepted greeting, farewell, vanilla emote, companion/social reply, and NPC reply variant;
- ensure NPC speech retains act/topic/beat/response-plan/fact/event provenance and later typed/button/emote replies resolve against that beat;
- preserve existing greeting/day/cooldown/chance/dedupe, relationship, ConversationBlocks, animation, TTS, and gameplay-effect ownership;
- add focused production-Lua worker and source-level characterization tests for equivalent typed/button/emote meaning, interruption/resume, and UI-close suspension;
- do not delete or disable legacy flavor authority until semantic parity and regression evidence are recorded.

After P2/P3A passes, continue automatically to grounded event migration, bounded thread/beat continuity, compaction and durable memory promotion, multiplayer/network sparsity, worker stress/diagnostics, and final legacy retirement gates. Do not request another `/goal`.
