# NPC Replication Architecture

## Existing boundaries and source evidence

- The Composer already submits compact authored blueprints. The resolver applies server-side validation/inheritance before NPC creation. The recurring roster sends resolved portrait summaries; nearby presence and inventory detail are separate interest/mutation paths.
- NPC authoring blueprints already retain `generationSeed`. The runtime record and roster projection contain `identitySeed`. They are **not guaranteed equal**: the unique-NPC reservation path may derive `identitySeed` from generation context even when a saved definition carries `generationSeed`.
- PsychopatzCore currently has item-state and item-visual primitives (native full type, base texture, texture choice, model index, hue, tint, custom RGB, decal) and an item codec registry. These are current workspace evidence, including uncommitted changes; verify exact source and branch before reuse. They do **not** prove compatibility with every mod's custom fields.

Source entry points: [Composer envelope](../../../Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Identity/PNC_StartingCompanionCustomization.lua), [Authoring blueprint](../../../Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Identity/PNC_NPCAuthoringBlueprint.lua), [Starting companion resolver](../../../Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Companions/StartingCompanionService/PNC_StartingCompanionService_Identity.lua), [Unique-NPC reservation](../../../Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Director/PNC_UniqueNPCRegistry_Lifecycle.lua), [Roster flush](../../../Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Networking/PNC_Network_Server/PNC_Network_Server_RosterInterest.lua), [Roster projection](../../../Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_RosterPayloads.lua), [Presence projection](../../../Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Networking/NetworkSnapshots/PNC_NetworkSnapshots_PresencePayload_Build.lua), and [Inventory replication](../../../Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Server/ServerInventory/PNC_ServerInventory_Replication.lua).

## Authority, identity, and seed provenance

- **`identitySeed` remains the authoritative persistent NPC identity seed.** Do not modify it to improve compression. Reuse it for identity-stable namespaced deterministic draws when that is the real generation contract.
- **`generationSeed` belongs to authored/generation provenance.** Saved unique-NPC definitions and starting-companion blueprints can contain it. Runtime `identitySeed` may be inherited, explicitly supplied, or derived independently. The encoder must inspect the *resolved record* and necessary source/provenance rather than equating two similarly named fields.
- A seeded baseline must reproduce actual initial generation inputs. If runtime `identitySeed` alone cannot regenerate a specific authored appearance, retain the necessary `generationSeed`/source reference as an independent bounded codec input, encode explicit differences, or send resolved fallback. Do not change either source seed or rewrite saves for codec convenience.
- Server owns identity, resolved/persisted appearance, authored slots, inventory, movement and authorization. Client reconstructs a **read-only normalized presentation projection**. A seed is never an instruction to reset gameplay inventory, personality, skill levels, memories, or health.
- Project Hoomans owns roster fields, visibility, negotiation, revisions, projections, and cache invalidation. PsychopatzCore owns genuinely reusable generation/item-visual/transport primitives. Reuse existing portrait-consumer contracts; no second authoritative appearance or inventory model.

## Proposed transport representations

| Representation | Meaning |
| --- | --- |
| Lean roster row | NPC ID, identity/display/access/map fields required by actual consumers, plus portrait reference/revision when needed. |
| Resolved appearance baseline | Server's complete normalized *presentation* projection at a specific incarnation/revision. P2 initial path, mismatch repair, and compatible fallback when assets exist. |
| Shared-definition reference | Stable definition ID + version/content fingerprint; optional only when the client demonstrably has the exact same definition and the required resolution inputs. Local user saves are not assumed shared across multiplayer clients. |
| Seeded baseline | Runtime `identitySeed`, actual generation provenance if distinct, generator version/archetype, compatible input fingerprint, and sparse exact visual overrides. Never substitute a fitted seed. |
| Exact compact visual values | Negotiated asset IDs or bounded reversible encoding of *known* fields and variants, including exact required color/texture/decal/item-state values; not lossy default quantization. |
| Appearance revision patch | NPC ID/incarnation, base and target appearance revisions, changed slot operations `set`, `clear`, `default`, and required protocol/catalog generation identifiers. |

A canonical NPC may use the best proven representation for each receiver: shared-definition+seed, seed+sparse overrides, dictionary-packed fields, or resolved fallback. None becomes authoritative gameplay state.

## Reproducible generator vs reversible encoder

- Use deterministic namespaced field draws (identity seed + field namespace + generator version + actual source inputs). One slot's edit cannot reroll unrelated slots. Preserve the same projection semantics as the authoritative resolver.
- A seed is a key to shared procedural defaults, **not** a lossless encoding of arbitrary modded metadata. Do not brute-force seeds or promise a fixed-size seed can represent every possible NPC/loadout.
- The server computes its normalized resolved appearance once per relevant revision, recreates the appropriate deterministic baseline, and diffs them by stable slot/field semantics. `set` replaces a value, `clear` enforces an explicit absence, and `default` removes an earlier override to restore a generated value.
- Packed indices work only for a finite, agreed field domain. Pack only fields with agreed value ordering/semantics and verified round-trip; unknown/unbounded values remain exact, or trigger the resolved path if the projection cannot be represented.
- Inventory item instances, changing quantities/conditions/ownership, traits, skills and other gameplay state remain on their existing authoritative replication channels. Authored *presentation loadout* may be projected into portrait appearance but never silently substituted for current inventory.

## Stable performance contracts

### Domain-stable deterministic generation

- `identitySeed` is the root persistent identity input, not a monolithic random stream. Derive deterministic domain/field draws with stable versioned namespaces so appearance changes cannot reroll loadout, and loadout generator changes cannot reroll names or unrelated identity. Existing namespaced equipment salts are evidence for this direction; formalize the contract before relying on cross-client reconstruction.
- Generator versioning belongs at the smallest stable compatibility boundary practical for correctness. A changed appearance generator should invalidate appearance reconstruction without unnecessarily invalidating unrelated identity/loadout state. Do not proliferate version numbers without measured value.

### Progressive hydration and presentation projection

Treat NPC richness as demand-driven projections over one authoritative NPC, not four competing NPC models:

| Level | Purpose | Typical data |
| --- | --- | --- |
| Abstract/world | Population simulation with no interested presentation consumer | actor/NPC identity reference, persistent seed/provenance, faction/location and sparse authoritative state |
| Roster/map | Browse/discovery/access | lean identity/display/map/presence fields plus portrait reference/revision |
| Presentation | Portrait/tooltip/inspection visual | normalized appearance projection or validated compact reconstruction |
| Gameplay detail | Nearby/live/authorized detailed consumers | existing authoritative inventory, combat, health, AI/body/detail paths |

Hydration is reversible and cacheable. Dropping a presentation cache never deletes authoritative NPC state. A roster subscription must not force full gameplay detail, and an abstract NPC must not allocate rich portrait/inventory presentation solely because it exists.

### Incarnation, revisions and no-op invalidation

- Address network state by stable NPC ID **and** an incarnation/lifetime token wherever ID reuse or remove/recreate can occur. `identitySeed` answers procedural identity; incarnation answers which lifetime; per-domain revisions answer which state version. A late packet for an old incarnation cannot revive or overwrite a new one.
- Maintain independent appearance/presence/inventory/detail revisions. Derive a deterministic normalized presentation equality key/content hash from fields that actually affect the portrait projection. Mutations that leave that key unchanged do not increment appearance revision and do not enqueue portrait work. Hash collision handling must fail safe (for example equality verification at mutation/compile boundaries) rather than make the hash authoritative truth.
- Invalidation is event-driven from known visual mutations (worn/appearance/variant/tint/etc.), not polling every record or piggybacking on movement, needs, tasks, relationships, or unrelated inventory changes.

### Compatibility classes and compiled-projection cache

- Derive a bounded client compatibility-class key from negotiated protocol plus the exact relevant generator/catalog/variant/dictionary fingerprints. Clients with the same key share the same compiled appearance representation. Do not rebuild or diff the same NPC separately for every recipient.
- Cache keys include NPC incarnation, appearance revision, representation kind and compatibility class. Bound per-NPC and global entries, coalesce concurrent misses, account for class churn, and use the resolved representation instead of allowing pathological client diversity to create unbounded work.
- Compatibility classes optimize work; they never weaken permission/interest filtering. Recipient authorization is evaluated separately.

### Cost-aware representation selection

For each compatibility class, compare only representations that already passed exactness/compatibility checks. Include payload size, dictionary/handshake amortization, compile/decode cost and cache retention. Select the cheapest valid representation; a seed+patch that is larger or costlier than a resolved portrait should lose. Cache the choice for the revision/class rather than recomputing it on each send.

### Inventory baseline boundary

Current generated inventory already records the NPC seed/generator/equipment-pool provenance and uses `SEED_ONLY` persistence mode, while initial equipment rolls use namespaced salts. That is compatible with a future baseline+authoritative-mutation model, but **this appearance/roster job does not redefine current inventory authority or persistence**. If measurement later justifies mutation compaction, it must preserve item-instance identity and current authoritative state, bound mutation logs, rebase only at safe deterministic checkpoints, and have its own acceptance gate.

## Loaded mod assets and variant compatibility

- Build a normalized, bounded, on-demand mapping from loaded Project Zomboid/mod item/visual definitions through existing catalog seams. Support arbitrary full types where native metadata allows; do not hard-code specific mods or scan their assets on each NPC tick.
- For affected visual fields compare full type, worn/body location, texture/base texture variants, native texture index mapping, model, hue/tint/custom-color flags, RGB, decal and necessary item-state metadata. Preserve floating-point values exactly where the normalized contract needs them; do not assume converting to an 8-bit channel is lossless.
- **Numeric texture choice/model index alone is not globally stable.** Reordering choices may change appearance. Prefer stable semantic asset identifiers where obtainable; otherwise require a matching acknowledged ordered mapping/fingerprint. Treat out-of-range index clamping to zero as a **parity failure**, not successful decoding.
- Fingerprint actual reconstruction inputs: generator implementation/version, relevant field distributions, normalized asset maps, variants and resource identity, with schema/projection version. A matching mod list does not prove asset equality. Avoid unnecessary global invalidation when a safely scoped dependency fingerprint is provable; finer-grained scopes are an optimization only after correctness is proven.
- Session asset dictionaries (small numeric IDs) are optional negotiated transport optimizations. Version, fingerprint, acknowledge and invalidate them; never reuse positional IDs after a catalog revision without coordination. Include their setup/reconnect bytes and retained memory in performance comparison.
- Unknown modded `modData` or engine-selected visuals are not automatically reproducible from seed or from generic metadata copying. Carry exact representable projection values in a bounded fallback; if a missing/unsupported semantic changes the visible result, fail closed and report it. Avoid copying unrelated/private/arbitrary item data into portrait packets without a defined purpose/size boundary.
- Full resolved fallback repairs a *codec mismatch*, not missing mod assets. A client without a required model/texture may only show an explicit unavailable/placeholder state; never claim pixel/semantic parity in that case.

## Negotiation, lifecycle, cost and recovery

- Negotiate protocol and validated input/dictionary capabilities per client and relevant catalog generation, then group equivalent clients into bounded compatibility classes. Check authorization independently of content fingerprints. Mixed-capability clients retain original resolved behavior.
- Generate/diff at appearance-creation or visual-mutation boundaries, not every movement, roster flush, UI tick, or recipient. Reuse the normalized projection and proven encoding across same-class recipients. A presentation hash/equality key suppresses revisions and work when the normalized visual result did not change.
- Store bounded cache entries; coalesce concurrent requests and repair; retire stale entries at NPC removal; prevent late packets from reviving an old incarnation. Cache invalidation applies to appearance changes, not every inventory/needs/position change.
- Require matching base revision for patches; ignore duplicate/older results; on gaps or fingerprint mismatches request a single current baseline. Guarantee `set`/`clear`/`default` convergence with mixed clients and catalog changes.
- Measure combined wire payload + dictionary handshake, CPU, cache growth, fallback rate and receiver count. Use P1/P2 measurements to choose the simplest proven improvement. Never pay a brute-force seed-search cost during NPC creation or replication.
- Preserve the existing preset/save formats throughout this job. Do not introduce compatibility shims or a parallel legacy codec just to move data; use the existing resolved fallback as the supported protocol capability path.
