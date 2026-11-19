# Exact portrait transport selection

The authority projects the resolved NPC once per retained appearance revision. The existing resolved reply remains available for legacy and unknown dialects, unknown fields at the codec boundary, full repair, and retention overflow. Compatible packed clients use the fixed dialect `pnc.roster-portrait.aliases.v1`. It shortens known keys and preserves typed values, dynamic slots, full asset identifiers, positional variants, and authored item-state trees. It has no session dictionary or per-catalog lookup table. The client advertises one bounded dialect string in the existing roster request. The server retains at most one packed representation per each of its 128 retained portraits and shares it across the matching class.

The selector estimates complete differing payload fields, including the dialect tag, and only picks packed when the estimated response is smaller. Authorization, connection capability, incarnation, and request limits remain per recipient. The client falls back to an ordinary resolved reply if decoding fails.

## Candidate results

| Candidate | Result |
| --- | --- |
| Resolved projection | Selected for compatibility, repair, unknown projection fields, overflow, or a smaller response. |
| Shared definition and seed | Ineligible. Local presets and unique definitions lack an agreed multiplayer content identity. A matching ID can still differ in inherited context, native survivor fields, and current equipment. |
| Canonical runtime seed and sparse overrides | Ineligible with current inputs. Native survivor creation contributes actual hair, beard, color and skin inputs without receiving the seed. The runtime seed can differ from authored generation seed, and current worn visuals come from resolved state. A sound version would need proven catalog and rules equivalence plus retained resolved inputs. |
| Fixed field aliases | Admitted for exact table round-trip. A single class depends only on the wire schema, because it decodes to the same resolved table before any native asset lookup. |

Generation remains unchanged. The existing versioned boundaries are Hoomans appearance generator version 4 and Core's separately versioned domain generators. Unique reservation uses its existing `unique_identity:<definition-id>` salt unless a runtime seed is explicitly provided. The starter fallback uses `starting:<character-uuid>:<trait-id>` independently of authored blueprint provenance. Weapon sampling keeps its established `equipment:weapon:<melee-or-ranged>:roll` and `equipment:<pool-id>:<field>` salts. These namespaces remain part of existing generation contracts. No transport uses a new random stream or rewrites either seed, generated inventory provenance, saves, or presets.

## Measurements and evidence

Run `lua tests/benchmarks/npc_replication.lua 3 packed` over the same 594 samples as P2. All samples recorded zero payload refusals. For a sparse 600-NPC hover burst the measurements were:

| Clients | Resolved response bytes | Packed response bytes | Resolved median CPU | Packed median CPU | Compiles |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 1,088 | 979 | 0.082 ms | 0.122 ms | 1 |
| 8 | 8,704 | 7,832 | 0.186 ms | 0.222 ms | 1 |
| 16 | 17,408 | 15,664 | 0.341 ms | 0.410 ms | 1 |

A compatible response saved 109 estimated bytes in this fixture at a small CPU cost. The opt-in advertisement adds the dialect string to the existing client request. At 16 clients it costs less than one fixture response saving per client under the same estimator. No additional setup packets are sent. Compiled tables share ID, color and authored item-state values with the resolved projection, and only allocate known-layout wrapper tables. Native allocator overhead and network bytes remain unmeasured. A five-point isolated sizing experiment on 0, 1, 4, 9 and 12 rich slots found estimated field savings of 12–19% before common response framing.

The exact projection tests include nested mod-owned metadata, 17-digit RGB and hue values, texture and model indices, decal, explicit false, empty clothing, unknown fields, mismatched dialect, forced repair, and one compile shared by compatible recipients. The modded projection fixture uses an installed RadioTraders item ID with synthetic visual values. The installed script and clothing files confirm that asset's namespace and model, while the headless fixture exercises serialized values without loading Java. Three local unique definitions and three local starting-companion presets were reviewed for seed lineage and authored variant examples.

Reordered or missing catalogs leave the decoded values identical to resolved transport. They can still change or prevent native rendering. The fixed-field codec neither remaps asset indices nor claims equivalence between native catalogs. Existing renderer behavior skips unavailable wearable items. Native item-visual round trips, rendering with real mod sets, and cross-catalog asset fidelity remain user-owned. Catalog-dependent codecs remain off.
