# Pre-change replication baseline

Run `lua tests/benchmarks/npc_replication.lua 3` from Project Hoomans. The captured source vector was Project Hoomans `48e3c83307d05050fa0eff4767e5aa27c27dcdfa`, Core `7eeaf03d5a80ab8cfa7ae7ab9b28defd146066b5`, with pre-existing appearance authoring and item-visual work preserved. The harness supplies fixed resolved fixture records and no game engine. It runs the production request router, snapshot builders, portrait normalization/cache, and budget/splitting, and intercepts the engine send call.

[Full matrix](P1_BASELINE.csv) records 180 cases, each run three times under Lua 5.3.6. The scenarios combine 100, 300, and 600 NPCs with 1, 8, and 16 synthetic clients. Sparse interest puts five NPCs in range of every client. Dense interest puts all NPCs in range of every client. Joins in a burst are back-to-back requests on the Lua thread. In the cold burst, the first request warms the cache for the others. Movement advances one production roster window and invokes both periodic roster scheduling and the interested tick broadcast. Reconnect exercises roster resync and interest re-entry. Equipment and inventory fixtures distinguish visible mutations and nonvisual revisions.

CPU is process CPU for each scenario, including the production budget guard and counting hooks. The CSV includes the median and observed range across three runs. A separate pass estimates bytes from submitted packet tables with the production size model, including chunk envelopes. The portrait estimate measures nested portrait tables separately. It excludes their framing keys and headers. Sends count submitted envelopes, recipients count distinct fake players, and roster rows count delivered rows including split slices. Cache entries count retained portraits on records. Detailed snapshots count sent promotions and updates carrying the detail flag. These counts represent server emission, with client convergence covered separately by smoke tests. No compatibility groups, negotiated cache, or application-level repair commands existed on the profiled roster path.

Representative 600 NPC, 16 client results

| Scenario | Sends | Estimated bytes | Portrait bytes | Portrait lookups | Cache misses | Median CPU |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Sparse cold join, one recipient | 14 | 968,146 | 542,100 | 600 | 600 | 38.3 ms |
| Sparse cold join burst | 224 | 15,490,434 | 8,673,600 | 9,600 | 600 | 444.4 ms |
| Sparse warm join burst | 224 | 15,490,448 | 8,673,600 | 9,600 | 0 | 448.2 ms |
| Sparse steady movement | 112 | 17,317,278 | 8,673,600 | 600 | 0 | 433.7 ms |
| Dense steady movement | 9,632 | 45,807,502 | 8,673,600 | 600 | 0 | 584.6 ms |
| Dense interest entry | 9,600 | 55,967,616 | 8,673,600 | 9,600 | 0 | 1,409.9 ms |
| Sparse inspection | 16 | 105,008 | 14,224 | 16 | 0 | 2.4 ms |
| Sparse visible mutation | 32 | 122,672 | 28,448 | 2 | 1 | 1.3 ms |
| Sparse nonvisible mutation | 32 | 122,672 | 28,448 | 2 | 0 | 1.1 ms |
| Sparse remove and rejoin | 64 | 127,360 | 28,448 | 17 | 1 | 3.6 ms |
| Sparse reconnect | 19 | 1,018,443 | 546,603 | 605 | 0 | 56.4 ms |

All 540 samples recorded zero refusals. At 600 NPCs and 16 clients, the same sparse movement roster batch split once per recipient into two envelopes. Dense interest entry repeats full builds per player. Warm portrait hits still walk appearance and equipment to compute the cache key. The synthetic inventory and appearance fixtures exclude native item construction, asset matching, Lua-to-Java marshaling, compression, transport, and network RTT. Native capacity and network bytes remain unmeasured.

## Consumer and routing findings

- Full sync builds a roster per requesting player, includes persisted death markers and travel routes, chunks at 50 rows, and clears that player's nearby interest for the next refresh. Periodic roster work coalesces per NPC and builds once at flush. The batch goes to every player independently of nearby interest.
- Nearby interest has enter and leave hysteresis. Entry builds a full snapshot per interested player. Steady movement builds one presence delta per interested NPC and fans it out. Exit supplies a roster snapshot. Detailed inspection uses its own authorization, full character payload, and independently revisioned inventory detail. Keep those request and revision paths intact.
- Roster, selectors, nameplates, and map consume IDs, identity/display fields, location, ownership, faction, life/presence/body, travel and map visibility, and health or stamina where shown. The portrait is mostly needed for hovered actors and open inspection. Project Hoomans supplies the actor-map knowledge adapter. Core's current map feature renders the hover portrait. Learned name and knowledge requests have separate gates. Keep persisted death-marker portrait and native/detailed inspection fallbacks.
- Full sync replaces roster state and clears detailed caches. Presence updates merge into current snapshots under replica sequencing. A presentation cache needs independent lifetime/revisions and must respect full-sync replacement, terminal removal, and late packets.

## First optimization

Send lean roster rows to clients that negotiate support and resolve full portraits on demand. In sparse movement, nearly half the payload estimate is repeated portrait data. All lookups hit the cache and still evaluate the cache signature. Scope the first change to portrait omission while preserving roster fields, and preserve the existing resolved path for legacy recipients. Measure detailed interest and nonvisible updates separately during P2. Shared preparation of transport chunks is a secondary opportunity.

Focused smoke tests passed with `python3 tests/run_tests.py --jobs 2 network_scale network_payload_budget portrait_summary inventory_replication server_character_replication_command_handler`. Native Project Zomboid was not run.
