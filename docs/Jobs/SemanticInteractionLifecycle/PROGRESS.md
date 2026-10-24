# Semantic Interaction Lifecycle — Current Progress

**Updated:** 2026-10-24

**Developer status:** P0A–P9 implementation and developer-side acceptance gates are complete. Final native Project Zomboid SP/MP acceptance remains user-owned and was not run by Codex.

**Accepted predecessor foundation:** Contextual Dialogue Persona & Choices P14. Its save-backed production rehydration architecture remains intact.

**Audit baseline:** `e8c04b4fb2139be315253f12e0f06a5dfa3fc70f5`

**Checkout:** existing `main` only. No branch, source-save mutation, Workshop upload, or native game launch was performed.

## P0A — source-level inventory

Complete. `SOURCE_INVENTORY.md` and `MIGRATION_MATRIX.md` enumerate the production flavor families, real source owners and IDs, trigger/context/resolver paths, presentation/TTS sinks, cooldown/chance/dedupe behavior, authority, effects, persistence dependencies, duplicate paths, and characterization coverage.

The inventory distinguishes authoritative gameplay/domain state from presentation-only flavor state. No legacy authored line was deleted; migrated lines remain available as bounded realization variants where applicable.

## P1 — common semantic envelope and lifecycle owner

Complete. Production Lua owns `semantic.interaction.envelope.v1` and `semantic.interaction.lifecycle.v1`. Typed/headless input remains NLU-driven; semantic choices, emotes, lifecycle events, grounded events, and NPC speech enter through the same bounded envelope contract. The envelope stores meaning and provenance, never rendered prose or gameplay permission.

Server-only `PNC_InteractionLifecyclePersistence` owns the sparse ModData boundary and uses the existing persistence coordinator. Pair capsules are created only for meaningful state, shared events are canonical references, imports/exports are bounded, and no lifecycle OnTick scan was added.

## P2/P3 — greeting, farewell, emote, companion and social-reply parity

Complete. Greeting and NPC-reply adapters retain beat, flow, response-plan, pool, act, topic, fact and event provenance. Farewell retains its existing eligibility, chance, delay, TTL and cooldown policy while conversation close is persisted through the server lease boundary. Registered vanilla emotes, companion command replies, social replies and their presentation/TTS sinks now carry the common semantic interaction envelope.

Legacy flavor definitions remain realization sources. They no longer create a competing lifecycle state or reparse generated prose. Accepted cooldown/no-op emotes remain presentation-only and do not materialize a new durable pair.

## P4 — grounded combat, medical, corpse, compatibility and world-event routes

Complete. The social-event transaction bridges grounded events into canonical world-event and NPC-speech provenance after source-domain validation. Combat witness, treatment, incapacitation, abandonment, horde, leader-loss, faction and compatibility adapters retain their existing domain owners and effects. Corpse-awareness reactions register one shared event and create bounded per-player NPC-speech context only for the player who can receive it.

Project A-Life server events register a canonical shared event reference once; the client uses a speaker-specific transport ID while preserving the canonical `eventRef` for semantic presentation. Client-only ambient routes are explicitly presentation-only and do not fabricate durable gameplay state.

## P5 — bounded thread and beat continuity

Complete. Active beats, suspended topic stacks, response windows, open questions, commitments, recent semantic turns, event references, and NPC speech provenance are bounded. Topic interruption/resume works independently of visible transcript rows. Closing the UI suspends meaningful context; it does not destroy it.

## P6 — compaction, expiry and promotion

Complete. Resolved trivial interactions remove their pair capsule. Long conversations retain at most the configured semantic turn bound; residue and realization history expire lazily; significant facts, commitments, memories and event references are promoted as compact references. Anti-repetition history is bounded and is not autobiographical transcript memory.

## P7 — sparse multiplayer persistence and isolation

Complete. The lifecycle does not pre-create Player × NPC records, has bounded pair/shared-event budgets, keeps pair projections private, and leaves dormant actors at zero lifecycle tick work. Shared event payloads are registered once and referenced by ID. Server authority guards reject non-authoritative lifecycle mutation.

## P8 — production Semantic Lab and acceptance worker

Complete. The existing production Lua worker exposes envelope, apply, NPC speech, close/resume, compaction, time, event, projection, response-window, metrics, export and import operations. Python only transports, isolates, drives and presents production-Lua state. Save-backed P14 rehydration tests confirm the source snapshot remains immutable.

## P9 — legacy authority retirement boundary

Complete for the audited families. Legacy registries, EN/TL lines, timing gates and compatibility shims remain only where they are still the correct realization/provider or external-domain boundary. Duplicate lifecycle/state authority and prose-reparse paths are retired; ConversationBlocks, gameplay domains, network authority and existing presentation/TTS ownership remain authoritative in their existing locations.

## Developer-side evidence

See `DEVELOPER_ACCEPTANCE.md` for the command log and scenario mapping. The final checks include 873/873 Lua tests, the full Python semantic-harness suite, production-Lua lifecycle acceptance, save-backed P14 immutability, full-mod Kahlua verification with zero errors across 3,094 files, syntax validation, and a clean diff check.

## Exact Next Chunk

No further developer-implementable P0–P9 chunk remains. The next action is the user-owned native Project Zomboid SP/MP acceptance pass described in `HARNESS_ACCEPTANCE.md`; Codex did not launch or mutate a native game or source save.
