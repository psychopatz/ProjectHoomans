# Progress — Open-Ended Semantic Continuation & Combat Awareness

**Status:** DEVELOPER COMPLETE — READY FOR USER LIVE TEST.
**Follow-on base:** `1940bf2a`.
**Branch:** existing `main`.
**Native PZ:** not launched; user-owned verification remains.
**Follow-on owner:** new combat-banter/tactical-intent work is tracked in `docs/Jobs/SemanticCombatBanterTacticalIntent/`; this completed job remains the accepted foundation.

## Current accepted state

### Open-ended semantic frontier

- generated strategy recurrence remains bounded/session-only;
- hostile/pending-question frontiers prioritize contextually relevant continuations;
- typed `I mean it` remains contextual `REAFFIRM`, hostile only with a hostile antecedent;
- EN/TL realization remains compiler-owned and bounded.

### Zombie/combat awareness

- `PNC_ZombieObservation` remains a read-only consumer of the existing Perception frame;
- no new `getZombieList()` / `getCell()` scan was introduced;
- player and NPC kills still publish `engine:zombie_killed`;
- SocialEncounterTracker remains the authority for meaningful encounter/protection aggregation.

### Routine kill path retirement

The old routine player-kill social mutation is retired:

- removed Hoomans client `PNC_ClientZombieKillAudit`;
- removed `PNC_SocialEventHooks_CombatAdapter_Witnesses`;
- removed `witnessed_player_kill` from SocialEventDefinitions, ConductDefinitions, semantic durable registration, profile math and debug surfaces;
- old event submissions are rejected as `unknown_event_type`;
- routine kills create no relationship memory and no conduct evidence;
- PsychopatzCore ZombieKillDetector remains the SP/MP authority/report bridge;
- Core detector hot-path hit/death printing is disabled by default and can be opt-in enabled;
- Hoomans server kill audit logging is gated by `DebugCombatCallbacks`.

Meaningful combat outcomes such as protection/shared survival remain their existing durable SocialEvent/encounter paths.

### Immersive semantic kill reactions

Added `PNC_SemanticCombatReactionProfile` and `PNC_SemanticCombatReactionService`.

Profile inputs reuse existing owners:
- directed relationship state/tier;
- social personality;
- active NPC traits;
- panic/stress and health;
- SpeechStyleContext;
- current ZombieObservation.

Direct trait signals include existing combat/temperament traits such as:
- aggressive: `pnc_berserker`, `pnc_reckless`, `pnc_trigger_happy`, `pnc_brawler`;
- shaken under pressure: `pnc_cowardly`, `pnc_nervous_fighter`, `pnc_frayednerves`;
- brave: `pnc_veteran`, `pnc_ironnerves`, `pnc_disciplined_fighter`;
- supportive: `pnc_friendly`, `pnc_peacemaker`;
- reserved: `pnc_reserved`, `pnc_withdrawn`.

Final styles are `aggressive / supportive / shaken / brave / reserved / cold / practical`.

Canonical CodeBuilder content now contains:
- 21 player-kill witness families;
- 21 NPC-self-kill families;
- 3 variants for each role/style combination;
- all 42 families have authored EN and TL text.

Routine player-kill fanout:
- global 5-second reaction window per killer;
- kills inside the window do zero spatial query and zero presentation work;
- suppressed kill count is folded into the next eligible event fact;
- one local SpatialIndex query on an eligible kill;
- exact floor/distance/visibility gate;
- max two NPC speakers.

NPC self-kill speech uses the same semantic system with per-speaker cooldown and max two local player listeners.

Routine kill speech is `llmEligible=false` and `memoryEligible=false`.

### Grounded follow-ups without save growth

Kill reactions can expose:
- `What happened?`
- `How many are around?`
- `Are you okay?`
- `What now?`

The answers come from the same authoritative semantic event fact. Quantity prefers the natural `quantity` sentence when available rather than a raw pressure label.

A new transient lifecycle overlay keeps the active event beat available for immediate typed/clicked follow-up while excluding it from `Lifecycle.Export` and therefore `PNC_InteractionLifecycle_V1` ModData.

Contract:
- routine kill speech alone -> projectable, `persisted=false`, `Persistence.Dirty=false`;
- close/TTL expiry -> discarded without promotion;
- explicit maintenance expires transient entries under the same bounded work limit;
- only a subsequent real player semantic turn may promote the thread/event into durable conversation state.

## Validation — 2026-10-29

Green so far:

- full isolated ProjectHoomans Lua: **914/914**;
- Unified Semantic Evidence E0–E7 plus real event-follow-up worker: **25/25** (22 evidence + 3 follow-up), including all four kill follow-ups;
- open-ended/coherent/L3/L4/L5/grounded-world worker set: **26/26**;
- focused retirement/persistence/reaction matrix: **11/11**;
- transient lifecycle + persistence focused matrix: **5/5**, then **3/3** persistence/lifecycle confirmation;
- reaction profile/service/catalog focused matrix after direct trait signals: **3/3**;
- reaction library audit: **42/42** families, EN+TL complete;
- CodeBuilder: two consecutive generations byte-identical across **144** generated Conversation files; **415** phrase families, 54 patterns, 10 UI definitions;
- ProjectHoomans union of staged + unstaged changed Lua through installed Project Zomboid Kahlua compiler: **45/45**;
- PsychopatzCore changed detector + two detector tests through the same installed Kahlua compiler using temporary in-repo verifier copies: **3/3**;
- PsychopatzCore mechanism commit: `ea5a1c7` (`perf: silence zombie kill detector audits by default`);
- PsychopatzCore detector client smoke, server smoke, and Core composition smoke: PASS;
- changed Python `py_compile`: PASS;
- `git diff --check`: PASS in both repositories;
- production/common authored/generated trees contain no `witnessed_player_kill`, `ClientZombieKillAudit`, `CombatAdapter_Witnesses` or `RecordPlayerKillWitnesses` references.

The repository-wide `unittest discover` sweep was intentionally stopped after ~19 minutes because it is an unbounded cross-harness/CLI sweep rather than this owner's acceptance gate. It remained actively exercising Lua/CLI workers with no surfaced failure, but no pass claim is made. The bounded owner suites above are the acceptance evidence.

## Native handoff

Verify in SP/MP:

1. kill zombies rapidly near multiple NPCs; normal gameplay should no longer hitch from per-witness SocialEvents/relationship/conduct writes or hot-path logging;
2. during a rapid kill streak, at most one reaction window should fan out every five seconds and at most two nearby NPCs should speak;
3. compare reactions from aggressive/reckless/berserker, nervous/cowardly, veteran/iron-nerves, friendly/peacemaker, reserved/withdrawn, hostile-relationship and neutral NPCs;
4. injure/panic/stress an NPC and verify reaction tone changes appropriately;
5. let an NPC kill a zombie and verify self-kill speech uses the killer-role family;
6. use the generated follow-ups and verify `What happened?`, `How many are around?`, `Are you okay?`, and `What now?` answer the current event;
7. ignore a reaction and continue playing; routine kill reaction context should expire without growing interaction-lifecycle ModData;
8. watch save size and frame pacing during repeated zombie kills/hordes.

If native evidence fails, reopen only the kill authority bridge, semantic reaction profile/service, transient lifecycle, or presentation owner implicated by the trace.
