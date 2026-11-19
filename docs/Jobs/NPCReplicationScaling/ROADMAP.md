# Roadmap for NPC Replication Scaling

## Objective and non-negotiable invariants

Reduce server work and network traffic for NPC roster/presentation replication while preserving exact supported visual identity, equipped variants, roster functionality, and authoritative gameplay state. The **full P1–P4 objective** remains open until developer-side gates pass; native multiplayer acceptance is reported separately.

- Preserve the canonical runtime `identitySeed` and saved authored `generationSeed` as distinct concepts. Neither is mutated or searched for a cheaper seed. Record the actual resolution inputs when they differ.
- The server's resolved or persisted NPC is truth. Client reconstruction is presentation only; inventory, health, traits, mutable attributes, permissions, and persistence remain on their existing authoritative paths.
- Never silently approximate a requested native visual variant or claim parity when required metadata or assets are unavailable. A missing asset cannot be restored by transmitting additional bytes.
- Prefer reuse of Project Hoomans' existing roster/portrait contracts and PsychopatzCore's deterministic functions and item-visual primitives over parallel systems.

## P1 Measure the current pipeline

- Trace full roster, roster delta, presence, and character-detail messages from server builder to client consumers. Determine which UI paths require portraits, when, and which existing interest/request paths suffice.
- Record baseline workloads: cold join, steady movement, inspect, appearance/equipment edit, remove/rejoin, with sparse/dense interest. Use the [runbook](AGENT_RUNBOOK.md) workload matrix.
- Measure sends, recipients, bytes or clearly labeled serialized-size estimates, portrait rebuilds, server build/flush CPU, cache occupancy, hydration-level counts, no-op presentation invalidations, and recipient compatibility-group fan-out. Keep native wire capture separate from headless estimates. Select the next payload/work-elimination change based on measured cost.
- **Gate:** reproducible baseline, explicit comparison methodology and limitations, consumer requirements traced, and a justified initial optimization; do not change wire semantics before this gate.

P1 developer baseline accepted. See the [measurement and consumer audit](P1_BASELINE.md).

## P2 Separate roster rows from portraits

- Reuse the existing roster, presence-interest, and character-detail boundaries. Under negotiated capability, keep roster rows minimal for consumers and send portrait references/revisions rather than repeated resolved portraits.
- Introduce progressive hydration through existing boundaries: abstract/world state stays minimal; roster rows carry only roster/map/access needs; portrait/presentation state is requested on demand; full gameplay detail remains on its current nearby/detail path. Do not materialize rich presentation merely because an NPC exists.
- Deliver a resolved appearance on demand/first relevant presence. Use an explicit NPC incarnation plus appearance revision/reference, coalesce requests, and invalidate presentation only from events that can change the normalized visible projection. Compute a deterministic projection hash (or equivalent equality key) so inventory/task/state mutations that do not alter visuals cannot bump appearance revision or resend portraits. Preserve the existing compatible full-payload path.
- **Gate:** roster/map/tooltips/inspection retain required fields; hydration is demand-driven and bounded; unrelated movement, needs, tasks, non-visible inventory changes and orders do not rebuild or resend unchanged portrait data; incarnation/revision handling prevents stale revival; requests/reconnect/removal/fallback converge. Repeat P1 workloads and report traffic, build cost, cache occupancy and no-op suppression.

P2 developer gate accepted. See the [hydration evidence](P2_HYDRATION.md).

## P3 Evaluate hybrid seeded / compact reconstruction (opt-in until proven)

- Trace the actual source-to-runtime seed lineage for regular NPCs, starting-companion presets, and unique NPCs: saved `generationSeed`, runtime `identitySeed`, context/definition overrides, generator version, and resolved authoritative appearance. Include the unique-NPC reservation path that can derive a runtime seed separately; never assume the two values always equal. Formalize stable versioned domain namespaces/sub-seeds (for example identity, appearance, loadout and supplies) so changing one generator cannot reroll unrelated domains.
- Compare candidate wire encodings against P2's resolved portrait: (A) matching shared definition ID + version/content fingerprint + required generation inputs; (B) canonical runtime seed + deterministic baseline + sparse set/clear/default operations; (C) negotiated dictionary or reversible compact fields for exact authored/native variants. Compose candidates where beneficial; do not brute-force seed search or encode arbitrary data into a pretend fixed-size seed.
- Use dynamically discovered loaded item/asset definitions. Match actual generator inputs (rules, catalogs, resolved variant maps, relevant game/mod asset definitions) rather than relying on enabled-mod names alone. Reconcile modded full types, worn slots, texture/base-texture choices, model index, decal, hue, tint, custom RGB, and relevant item-state metadata; distinguish stored exact values from actual visual reproducibility.
- Prefer stable full-type/asset identifiers, and stable semantic variant identifiers when available. Positional indices are only valid against an acknowledged exact catalog mapping. An optional session dictionary must have version/fingerprint, acknowledgement, invalidation, and bounded size; compare dictionary overhead against savings.
- Negotiate **compatibility classes** from the actual reconstruction inputs, not one encoder instance per recipient. Cache a proven encoded projection by NPC incarnation + appearance revision + compatibility class and reuse it for all clients in that class. Bound classes/caches and fall back rather than allowing adversarial catalog diversity to create unbounded server work.
- Implement a size/cost-aware representation selector: for each compatible class compare resolved projection, shared-definition reference, seed+sparse patch, and optional dictionary-packed representation including handshake/amortized overhead. Choose the smallest valid representation rather than forcing seed encoding when its overrides cost more.
- Explicit fallback covers unsupported/mismatched encodings, unknown or unrepresentable appearance fields, mismatched variants, and unsupported native values. Full resolved projection is a data fallback **only when the receiving client has the necessary assets**; missing resources use a documented safe placeholder/error path, never a false claim of exact parity.
- **Gate:** exact supported-field round-trips against server projections for saved presets, unique NPCs, randomized NPCs, explicit empty slots and real modded variant/tint/metadata cases; mismatch, reorder, missing-asset, changed-generator, altered-defaults and reconnect tests; prove one compile can serve same-class recipients; prove class/cache bounds; compare candidate sizes including dictionary setup; report per-scenario CPU, bytes, cache, no-op suppression and fallback rates vs P2. Enable hybrid only when parity, robustness and net savings pass, otherwise retain P2.

## P4 Revisioned appearance updates and convergence

- Send only visual field/slot changes against `baseRevision` -> `targetRevision`. Preserve `set`, `clear`, and `default` meanings. Do not mutate `identitySeed` or treat initial loadout as current inventory state. Use the normalized presentation hash/equality key to suppress revisions whose resulting projection is unchanged.
- Reject stale, duplicate, reordered, wrong-incarnation, or catalog-incompatible updates. On a revision gap request one current validated baseline, coalescing and rate-limiting repair. Invalidate when required catalog/generation inputs change, not on unrelated NPC state mutations.
- **Gate:** late join, reordered/duplicated/gapped patches, burst edits, reconnect, mod-catalog invalidation, NPC removal/recreation, and mixed-capability clients converge exactly where assets permit. Rerun P1 workloads and report network bytes, CPU, cache bounds and fallback rates. Native multiplayer acceptance remains distinct from headless tests.

Compact numeric IDs, more granular per-asset compatibility fingerprints, and further roster-recipient filtering are **measurement-driven options**, not assumptions or independent systems to build automatically. The existing generated-inventory `SEED_ONLY` baseline and namespaced equipment rolls are evidence for a possible future **baseline + authoritative mutation + bounded rebase** optimization; do not pull inventory persistence into this job unless measurement shows it is a material bottleneck and a separate ownership/gate is added. General-purpose compression/Base64 and brute-force seed fitting are not goals. Changes in roster visibility require an explicit gameplay decision.
