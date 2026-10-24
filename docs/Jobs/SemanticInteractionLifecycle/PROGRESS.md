# Semantic Interaction Lifecycle — Current Progress

**Updated:** 2026-10-25

**Developer status:** P0A–P9 implementation is retained foundation, but developer acceptance is REOPENED. User-supplied native/harness evidence on 2026-10-25 proves the Semantic Lab primary Conversation surface is not yet faithful to native production presentation. P10 is mandatory before READY FOR USER LIVE TEST.

**Accepted predecessor foundation:** Contextual Dialogue Persona & Choices P14. Its save-backed production rehydration architecture remains intact.

**Current parity-audit baseline:** `7833214e0eb0f52467caa8749b6bc8c5333d1f64`

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

## P10 — native Conversation parity correction

**Status:** ACTIVE.

The first user native/harness comparison supersedes the previous final handoff.

Verified mismatches:

- native production showed the staged Pete Patz opening and a three-row Response Channel for the captured state;
- Semantic Lab exposed a much broader candidate surface;
- production \`buildCoreChoices\` selects the current semantic group, while current Tk suggestion rendering can use the global candidate projection when no explicit group override exists;
- harness clickability is gated by worker response type instead of the production presented-choice/session validity contract;
- normal control re-enable paths call splitter restoration and can overwrite a user's current drag with persisted sash state;
- hiding workbench contents can leave the bottom PanedWindow allocation in place, producing large wasted space;
- World Browser relationship/role classification still exists in code but can appear absent because the persisted "Saved affiliations" lens replaces the visible hierarchy.

Detailed corrective architecture and acceptance are in \`NATIVE_CONVERSATION_PARITY_CORRECTION.md\`.

P10A (reopen acceptance + freeze parity evidence) is complete as audit/documentation.

### Exact Next Chunk — P10B

Implement the smallest **production-Lua headless Conversation presentation projection** that answers what native Core would present for the current conversation state.

It must expose, without Python reconstruction:

- production Talk/opening state;
- staged/opening NPC messages;
- relation presentation;
- lifecycle/busy state;
- current semantic group/revision;
- exact production-presented choice rows generated from the same \`PresentSemanticChoices\` / \`buildCoreChoices\` policy;
- enabled/disabled state and semantic frames;
- typed semantic input availability.

Do not redesign the Tk layout in P10B yet.

Do not remove global candidate diagnostics; move/keep them as diagnostics in later P10C/P10F work.

P10B gate: the real worker can answer "what would the native Conversation session present now?" from production Lua state, and tests prove the result uses the production presentation path rather than a Python duplicate.

## Developer-side evidence

See `DEVELOPER_ACCEPTANCE.md` for the exact command log and scenario mapping. Verified results are: focused lifecycle tests 10/10; full Python semantic-harness suite 517 tests with 0 failures and 0 errors; full Lua suite 873/873; Lua syntax validation passed; full-mod Kahlua verification reported zero errors and zero warnings across 3,094 scanned files; and `git diff --check` passed.

## Previous P0–P9 handoff status

The former "no further developer-implementable chunk remains" conclusion is superseded by P10. Preserve the recorded P0–P9 verification as historical implementation evidence; do not use it to skip the active native-parity correction.
