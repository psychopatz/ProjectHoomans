# Progress — Open-Ended Semantic Continuation & Combat Awareness

**Status:** DEVELOPER COMPLETE — READY FOR USER LIVE TEST.
**Base:** `19d0c760`.
**Branch:** existing `main`.
**Native PZ:** not launched; user-owned verification remains.

## Product fixes

### Open-ended semantic frontier

- `DOUBLE_DOWN` no longer immediately reappears after its generated button is clicked.
- hostility now prioritizes repair/de-escalation/escalation/follow-up choices before generic ACCEPT/REFUSE-style relation rows;
- pending wellbeing/identity questions retain their focused answer frontier;
- generated strategy + stance are recorded only in bounded session context;
- typed input is never blocked by generated recurrence policy;
- `I mean it / I meant it / yeah I mean(t) it` are parsed as neutral `REAFFIRM`, then contextualized:
  - active hostile discourse -> `HOSTILE_REMARK` / doubled-down;
  - no hostile antecedent -> `ACKNOWLEDGE`;
- EN/TL DOUBLE_DOWN each have three compiler-owned constructions selected deterministically.

### Zombie/combat awareness

- added `PNC_ZombieObservation` as a read-only consumer of existing Perception frames;
- zero new `getZombieList()` or `getCell()` traversal;
- runtime observation cache: 750 ms, movement/floor-aware;
- descriptive bands: none/few/several/horde/massive_horde;
- tactical thresholds remain independent existing constants;
- live/idle NPC observations run from existing record scheduling/SimulationLOD;
- bounded snapshot reaches semantic conversation context and InteractionProviders.world;
- current pressure is normalized as SESSION evidence with retention salience 0;
- existing SocialEventHooks and WorldKnowledge derive compatibility pressure labels from the same classifier;
- player and NPC kills publish the same `engine:zombie_killed` type with actorKind;
- NPC kill publication occurs at existing CombatResolution authoritative death commit;
- SocialEncounterTracker still owns aggregate kill/encounter meaning;
- normal player-kill witness candidate discovery is spatial-local rather than `ForEachLive`.

## Validation — 2026-10-29

Green:

- full isolated Lua: **912/912**;
- Unified Semantic Evidence E0–E7 worker: **22/22**;
- open-ended + coherent conversation + L3/L4/L5 + grounded world-knowledge worker set: **26/26**;
- focused new/affected Lua combat-perception-semantic matrix: **8/8**;
- focused earlier live-regression matrix after compatibility reconciliation: **16/16**;
- C6/C7 coherent conversation: **8/8**;
- CodeBuilder: two consecutive full Conversation generations byte-identical across 142 generated files;
- changed Python: `py_compile` PASS;
- changed/untracked Lua: installed Project Zomboid Kahlua compiler **31/31 PASS**;
- `git diff --check`: PASS;
- new zombie observation module contains no `getCell()` or `getZombieList()`;
- diff introduces no new `ModData.get/getOrCreate` or semantic-memory root.

Pre-existing broad Python failures were verified against clean base `19d0c760`: provider/transport tests expecting zero SemanticInteractionLifecycle transport already fail on the base revision, and one provider fixture depends on optional DynamicTrading discovery. They are not regressions from this slice.

## Native handoff

Verify in SP/MP:

1. insult -> choose DOUBLE_DOWN -> next buttons should progress rather than reoffer DOUBLE_DOWN immediately;
2. type `I mean it` after a hostile exchange -> hostile reaffirmation; type it in a neutral exchange -> no fabricated hostility;
3. repeat hostile exchanges and confirm wording varies deterministically without becoming random nonsense;
4. stand/talk near several zombies or a horde while the NPC is not already in follower/combat behavior; semantic/world context should reflect pressure;
5. observe player zombie kills and NPC zombie kills; both should enter the same semantic kill event family;
6. with multiple NPCs nearby, only spatially local valid witnesses should react;
7. watch performance/save growth under large hordes and repeated kills; no new persistent per-kill growth is expected.

If native evidence fails, reopen only the owning continuation, observation, kill-event or witness layer.
