# Appearance patch convergence

A patch is negotiated independently of fixed-field packing and is eligible only for the exact previous revision of the current incarnation. The sender retains one predecessor, validates supported normalized shapes, and compares total patch fields with the smaller eligible complete response. The receiver validates the pending request ID, roster incarnation, requested revision, exact adjacent base and target, unique changes, and complete resulting shape before committing. Missing bases, revision gaps, or incompatible capabilities receive a current baseline. Invalid replies use the same coalesced request path to request a resolved repair. One patch carries at most 32 operations. Supported operations are set, clear optional values or slots, and restore known schema defaults.

## Developer evidence

- The production-seam tests cover mixed clients, hydration and negotiated fallback, delayed nearby messages, unchanged normalized equipment, exact visible revisions, malformed resolved/alias/patch types, explicit clear and default, duplicate and stale responses, revision gaps, burst edits, capability changes, same-ID recreation, bounded retention, and reconnect with a lower directory revision.
- The final Hoomans full Lua suite passed **1,070 of 1,074**. The four pre-P2 failures reproduced with extracted source at `df7c49eb4`. They concern two scene-lab menu assertions, initial settlement generation, and the translated debug title. Three Core actor-map, hover and presentation smokes passed. The Kahlua error scan reported zero errors on the P4 runtime diff.
- `lua tests/benchmarks/npc_replication.lua 3 patch` ran **702 headless samples** across the P1 combinations plus adjacent-revision hover and forced resolved repair. The [matrix](P4_CONVERGENCE.csv) records three trials for each case, with zero payload refusals. All sizes are serialized table estimates and CPU is synthetic Lua process CPU.

| Scenario at 600 NPCs and 16 synthetic clients | Baseline estimate | Final estimate | Baseline median CPU | Final median CPU |
| --- | ---: | ---: | ---: | ---: |
| Sparse cold join, one recipient | 968,146 B | 472,318 B | 38.3 ms | 7.7 ms |
| Sparse warm join burst | 15,490,448 B | 7,557,200 B | 448.2 ms | 117.1 ms |
| Sparse steady movement | 17,317,278 B | 9,374,224 B | 433.7 ms | 68.5 ms |
| Dense steady movement | 45,807,502 B | 37,864,448 B | 584.6 ms | 407.7 ms |
| Dense interest entry | 55,967,616 B | 48,033,216 B | 1,409.9 ms | 1,189.7 ms |
| Sparse reconnect | 1,018,443 B | 518,497 B | 56.4 ms | 7.7 ms |
| Adjacent-revision hover vs forced resolved repair | 17,520 B | 12,016 B | 0.261 ms | 0.305 ms |

The adjacent-revision hover used one shared patch compile for 16 recipients. Estimated response bytes fell by 31% relative to the forced full repair, at about 0.04 ms of additional server CPU in the fixture. Sparse movement avoided all portrait builds and saved 16 submitted chunk envelopes. The fixture excludes native transport, client rendering cost, Java item operations, and Core’s independent canonical actor-map feed.

## User-owned native acceptance

On Project Zomboid Build 42, validate dedicated and hosted multiplayer with mixed negotiated clients and an independently connected client with a matching mod catalog. Check cold join, dense and sparse movement, close and reopen hover and inspection, explicit worn slot clearing and re-defaulting, precise tint and variant edits, remove/rejoin, and disconnect/reconnect. Compare authoritative and client item visuals using real installed clothing and metadata. Repeat with a changed catalog order and missing mod assets to check the existing resolved renderer behavior. A missing or mismatched local asset can prevent exact rendering even with an exact Lua projection. Record actual packet bytes, client render behavior, and supported capacity separately from these headless estimates.

Shared-definition and seeded reconstruction remain inactive pending authoritative generator and catalog equivalence evidence. Inventory persistence remains outside the measured scope of this job.
