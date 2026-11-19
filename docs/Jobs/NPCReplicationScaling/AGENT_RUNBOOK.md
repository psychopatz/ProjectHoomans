# Runbook for NPC Replication Scaling

## Resume and authority

Read [Progress](PROGRESS.md) and [Handoff](HANDOFF.md), verify both Git repositories and dirty work against current evidence, then the active gate in [Roadmap](ROADMAP.md). Preserve existing user/agent edits. Source and tests are authoritative where Codebase Memory is behind the worktree. Start at `FlushRosterDeltas`, `BuildRosterSnapshot`, `BuildPresenceDelta`, their actual client consumers, and the current item-visual support seams. Native Project Zomboid tests remain user-owned unless separately authorized.

## Baseline measurement (P1, before wire changes)

- Propose deterministic cases at 100, 300, and 600 NPCs and 1, 8, and 16 clients, sparse and dense interest. Record actual supported points and unsupported combinations. Exercise cold joins and separate steady-state movement, inspect, appearance/equipment edit, remove/rejoin, and simultaneous join bursts.
- Fix NPC identity seeds, source generation seeds, catalogs/versions, tick windows, subscriber distribution, and scenario definitions across comparisons. Record both initial and effective runtime seeds in fixtures where they differ.
- Count sends, recipients, entries, portrait-full/compact bytes, portrait builds, normalized-projection builds, no-op visual invalidations suppressed, hydration-level transitions/counts, compatibility-class count, compile count per class/recipient, cache hits/misses/evictions, resyncs, maximum batches, mean/tail server build/flush cost, and retained cache entries. Include capability/dictionary setup bytes and native wire size when actually captured; otherwise label size estimates as estimates, not wire throughput.
- Reuse tests, profiler hooks, and Core diagnostics. Batch counters at send/build boundaries; keep instrumentation off the ordinary per-NPC hot path when disabled. Record exact revision, commands, scenarios, method, results, and run-to-run variance.
- **P1 gate:** no schema or packet optimization until a reproducible baseline identifies a meaningful cost center and a justified next change.

## Deterministic/parity fixture matrix (P3)

- Use actual saved unique NPC/starting-companion definitions as read-only fixtures, including `Harvey_Gordon`, `Sonny_Lorenz`, and `Thaddeus_Orr` when present. These are local optional fixtures, not hard-coded runtime dependencies. Add randomized regular NPC and multiple distinct runtime seeds with one shared authored definition.
- Test `generationSeed == identitySeed` and `generationSeed != identitySeed`, explicit identity overrides, inherited companion values, generator-version changes, preset editing/reload, and old save resumption without reroll.
- Test same item type with different base textures, ordered texture choices, model indices, decals, hue, custom color flags, RGB/tint values including high-precision floats, explicit empty wearable slot and return-to-default operation.
- Test real native/modded clothing, reordered/added/removed variants, same mod-list but altered catalog content, unknown/custom item-state metadata, mod-defined body locations/exclusivity, unsupported native accessors, and unavailable/missing client assets. Do not equate a copied state table with a rendered/normalized projection equality test.
- For each case compile from server-resolved appearance, decode against the declared compatible client catalog, canonicalize and compare every supported projected field. Assert no unintended mutating writes to inventory, attributes, identity, saves, or authoring definitions. Any lossy match, default-index clamping, or unknown visual field must fail exactness and use the documented fallback.
- Test optional shared-definition reference and negotiated dictionary as **separate candidates**: exact content fingerprint, session setup, IDs, invalidation and reconnect. Test multiple clients sharing one compatibility class and deliberately divergent classes; assert one cached compile serves the shared class, class/cache counts stay bounded, and permissions remain per-recipient. For each valid representation record cold/warm bytes, dictionary amortization, encode/decode CPU, fallback count, peak memory and catalog build cost; assert the cost selector chooses the smallest valid candidate under the configured metric.

## Protocol/scale regressions (P2–P4)

Run focused roster, presence interest, character detail, inventory delta, authored-appearance, and protocol regressions through actual production seams. Cover late join, stale/duplicate/reordered packets, missing baselines and patches, revision gaps, NPC incarnation reuse, burst changes, mixed capability, mismatched catalog/generator, compatibility-class churn, fallback, reconnect and removed NPCs. Exercise hydration promotion/demotion and cache eviction without losing authoritative state. Assert movement, needs, tasks, relationships and non-visible inventory changes cannot regenerate, revise or resend unchanged portrait data; explicit visible equipment/tint/variant changes must invalidate exactly once.

Before each gate compare with P1 and P2 on identical scenarios. Report whether exactness, CPU, bytes, cache bounds, recipient fan-out and fallback rates improve; keep unsupported mod combinations explicit rather than labelling them compatible. Headless assertions are not native SP/MP acceptance. Follow repository local accepted-phase commit rules only after the relevant gate passes; never stage unrelated dirty work or publish without authorization.
