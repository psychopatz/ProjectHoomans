# Semantic Interaction Lifecycle — Current Progress

**Updated:** 2026-10-24

**Developer status:** P0A–P9 implementation and all developer-side acceptance gates are complete. Final native Project Zomboid SP/MP acceptance remains user-owned and was not run by Codex.

**Accepted predecessor foundation:** Contextual Dialogue Persona & Choices P14. Its save-backed production rehydration architecture remains intact.

**Audit baseline:** `e8c04b4fb2139be315253f12e0f06a5dfa3fc70f5`

**Checkout:** existing `main` only. No branch, source-save mutation, Workshop upload, or native game launch was performed.

## P0A — source-level migration and state-ownership inventory

Complete. `SOURCE_INVENTORY.md` and `MIGRATION_MATRIX.md` enumerate production flavor families, real source owners and IDs, trigger/context/resolver paths, presentation/TTS sinks, cooldown/chance/dedupe behavior, authority, gameplay effects, persistence dependencies, duplicate paths, and characterization coverage. The inventory distinguishes authoritative gameplay/domain state from presentation-only flavor state. No legacy authored line was deleted; migrated lines remain available as bounded realization variants where applicable.

## P1 — common semantic envelope and lifecycle owner

Complete. Production Lua owns `semantic.interaction.envelope.v1` and `semantic.interaction.lifecycle.v1`. Typed/headless input remains NLU-driven; semantic choices, emotes, lifecycle events, grounded events, and NPC speech enter through the same bounded envelope contract. The envelope stores meaning provenance, never rendered prose or gameplay permission.

Server-only `PNC_InteractionLifecyclePersistence` owns the sparse ModData boundary through the existing persistence coordinator. Pair capsules are created only for meaningful state, shared events use canonical references, imports/exports are bounded, and no lifecycle `OnTick` scan was added.

## P2/P3 — greeting, farewell, emote, and companion/social-reply parity

Complete. Greeting, farewell, registered vanilla emote, companion command reply, and social reply adapters retain act/topic/beat/flow/response-plan/pool/fact/event provenance while preserving existing eligibility, cooldown, chance, delay, TTL, and presentation/TTS policy. Accepted no-op emotes remain presentation-only and do not materialize a durable pair.

## P4 — grounded combat, medical, corpse, and world-event routes

Complete. Grounded event transactions bridge validated combat, treatment, incapacitation, abandonment, horde, corpse-awareness, leader-loss, faction-compatibility, and Project A-Life events into canonical world-event references and NPC-speech provenance. Existing domain owners retain gameplay effects. Client-only ambient routes remain presentation-only and do not fabricate durable gameplay state.

## P5 — bounded thread and beat continuity

Complete. Active beats, suspended topic stacks, response windows, open questions, commitments, recent semantic turns, event references, and NPC speech provenance are bounded. Topic interruption/resume works independently of visible transcript rows. Closing the UI suspends meaningful context without destroying it.

## P6 — compaction, expiry, and promotion

Complete. Resolved trivial interactions remove the pair capsule. Long conversations retain only bounded semantic residue; realization history expires lazily; significant facts, commitments, memories, and event references promote as compact durable references. Anti-repetition history is bounded and is not autobiographical transcript memory.

## P7 — sparse multiplayer persistence and isolation

Complete. Lifecycle state does not pre-create Player × NPC records, keeps pair/shared-event budgets bounded, keeps private projections isolated, and leaves dormant actors at zero lifecycle tick work. Shared event payloads are registered once and referenced by ID. Server-authority guards reject non-authoritative lifecycle mutation.

## P8 — production Semantic Lab acceptance worker

Complete. The existing production Lua worker exposes envelope, apply, NPC speech, close/resume, compaction, time, event, projection, response-window, metrics, export, and import operations. Python only transports, isolates, drives, and presents production-Lua state. Save-backed P14 rehydration tests confirm source snapshot immutability.

## P9 — legacy authority retirement boundary

Complete for the audited families. Legacy registries, EN/TL lines, timing gates, and compatibility shims remain only where they are still the correct realization/provider or external-domain boundary. Duplicate lifecycle/state authority and prose-reparse paths are retired; ConversationBlocks, gameplay domains, network authority, and existing presentation/TTS ownership remain authoritative in their existing locations.

## Developer-side evidence

See `DEVELOPER_ACCEPTANCE.md` for the exact command log and scenario mapping. Verified results are: focused lifecycle tests 10/10; full Python semantic-harness suite 517 tests with 0 failures and 0 errors; full Lua suite 873/873; Lua syntax validation passed; full-mod Kahlua verification reported zero errors and zero warnings across 3,094 scanned files; and `git diff --check` passed.

## Exact Next Chunk

No further developer-implementable P0–P9 chunk remains. The next action is the user-owned native Project Zomboid SP/MP acceptance pass described in `HARNESS_ACCEPTANCE.md`; Codex did not launch or mutate a native game or source save.
