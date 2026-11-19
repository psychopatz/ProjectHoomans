# Negotiated portrait hydration

`lua tests/benchmarks/npc_replication.lua 3 lean` repeats P1 with the production lean negotiation and adds one hover per client. The [matrix](P2_HYDRATION.csv) has 594 samples with zero payload refusals. CPU is process CPU and bytes are estimates from submitted tables. Inspect still uses the existing authorized full character payload. The original resolved roster remains available for clients with no matching protocol and the hosted-local fallback.

| Scenario, 600 NPCs and 16 synthetic clients | P1 bytes | P2 bytes | P1 median CPU | P2 median CPU |
| --- | ---: | ---: | ---: | ---: |
| Sparse cold join, one recipient | 968,146 | 472,318 | 38.3 ms | 8.4 ms |
| Sparse warm join burst | 15,490,448 | 7,557,200 | 448.2 ms | 146.6 ms |
| Sparse movement | 17,317,278 | 9,374,224 | 433.7 ms | 80.4 ms |
| Dense movement | 45,807,502 | 37,864,448 | 584.6 ms | 510.0 ms |
| Dense interest entry | 55,967,616 | 48,033,216 | 1,409.9 ms | 1,036.4 ms |
| Sparse nonvisible mutation | 122,672 | 96,688 | 1.1 ms | 1.1 ms |
| Sparse reconnect | 1,018,443 | 518,497 | 56.4 ms | 15.0 ms |

Negotiated cold join, movement, and interest entry performed zero portrait lookups. The new 16-recipient hover case made 16 resolved responses with one normalized projection build, 17,408 estimated bytes total and 0.34 ms median CPU. Sparse movement saved 16 split envelopes. Fixture CPU variance is recorded per row in the matrix. Nearby authoritative body descriptors remain in detailed gameplay payloads. Core's canonical actor-map feed is an independent provider and retains its current representation.

The production-seam smoke exercises modern and legacy recipients, request coalescing, visible and nonvisible equipment changes, delay between nearby and roster updates, stale replies, ID reuse, removal, disconnect with directory revision reset, and retention overflow. Server retains up to 128 demand projections and responds with a short-lived resolved view at capacity. Clients retain at most 64 entries. Visible capture and inventory synchronization mark candidate changes, with normalized equality checked after synchronous mutations have settled.

Hoomans focused replication tests and the two Core hover tests passed. The Hoomans full smoke suite passed 1,068 of 1,072. An extracted pre-P2 source baseline reproduced the same scene-lab menu assertions, initial settlement assertion, and debug title translation assertion. PZ verification reported no Kahlua errors on the scanned networking paths. Native network and asset fidelity remain user-owned.
