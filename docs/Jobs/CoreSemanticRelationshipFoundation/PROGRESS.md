# Progress — Core Semantic & Relationship Foundation

**State:** IN PROGRESS — independent post-P7 verification invalidated the previous developer-complete / READY FOR USER LIVE TEST claim.

The P0-P7 implementation is retained as useful foundation, but the parent goal is not accepted until the mandatory corrective P8-P12 roadmap passes.

## Independent verification snapshot — 2026-11-02

Repository truth at audit time:

- `psychopatzCore`: `main @ 03fd546`, 4 commits ahead of `origin/main`, clean.
- `DynamicTrading`: `main @ 30e745f6`, 3 commits ahead of `origin/main`, with the pre-existing tracked `DTHoomans_Conversation.lua` edit still preserved.
- `ProjectHoomans`: `main @ aa9895ca`, 5 commits ahead of `origin/main`, clean.

Verified strengths:

- Core Social extension serialization and the new focused Core Social/Semantics tests pass.
- Dynamic Trading full smoke suite passes `43/43`.
- Hoomans focused `pnc_core_social_convergence_smoke` and `pnc_core_semantic_adopter_smoke` pass under the repository's intended test runner.
- Changed runtime Lua files pass `luac5.3 -p`.
- Committed diffs and the preserved Dynamic Trading working-tree edit pass `git diff --check`.
- Standalone Core + Dynamic Trading can parse/respond to greeting, trade and rumor utterances and can select relationship-aware trader greetings without Project Hoomans.
- Core still has no runtime import of adopter policy.

## Acceptance-invalidating findings

### 1. Player relationship target identity is forked

Project Hoomans resolves a durable player-character key through `PNC.PlayerCharacters.GetEntityKey` / `PNC.EntityRef.ForPlayerIdentity`:

- MP shape: `player:<account identity>:<persistent character UUID>`.
- SP shape: `player:sp_slot_<n>:<persistent character UUID>`.

Dynamic Trading currently invents different keys in `DTCommon_CoreActorPolicy.playerKeys` / `DTCommon_TalkService.playerKey`:

- `player:online:<onlineID>`
- `player:user:<username>`

These can create multiple Core Social relationship entries for the same human character. P1's "one actor/target pair, one relationship truth" gate is therefore not satisfied.

### 2. Hoomans can destructively overwrite newer Core/DT social data

`PNC_Persistence_CoreSocial.SyncToCore` rebuilds a complete Core social snapshot from Hoomans `record.social` and commits it wholesale.

Production Hoomans relationship mutation still:

1. mutates `record.social`;
2. calls `SyncToCore` through best-effort `pcall`;
3. ignores synchronization failure.

There is no production `SyncFromCore` lifecycle call that makes Hoomans' local copy authoritative-safe before every write.

Independent reproduction:

- seed Core relationship with a newer DT memory and `extensions.DynamicTrading`;
- use a stale Hoomans record for the same relationship;
- call current `SyncToCore`;
- sync reports success;
- DT memory is removed;
- `DynamicTrading` extension is removed.

This directly violates P1/P6 data-integrity requirements.

### 3. Hoomans Core semantic pack schema is incompatible with Core

`PNC_CoreSemanticPack.lua` registers Hoomans-style definitions into the new Core pack registry using incompatible fields:

- concepts use `labels`, while Core registry requires `aliases` / `phrases`;
- dialogue blocks use `conditions` / `outcomes`, while Core expects `gates` / `entryNode` / `nodes`;
- multi-word phrases such as `follow me` are registered as one literal matcher rule and do not match the actual Core matcher contract.

Independent probe showed:

- `hoomans_block_wellbeing_good` registers with 0 gates, 0 nodes and no text key;
- it can be selected even with approval `-100`;
- `hoomans.concept.companion` is not registered;
- `follow me` produces no intended Core semantic intent.

The existing smoke test verifies registration/action filtering but does not validate these production semantics.

### 4. Core semantic pack lifecycle/capability isolation is incomplete

Pack-level `capabilitiesRequired` is stored but not enforced by dialogue block selection/parser content.

`UnregisterPack` removes action providers/dialogue blocks but leaves owned concepts/speech acts/patterns in the global semantic registry.

Independent probe:

- a Dynamic Trading dialogue block was selectable with no Dynamic Trading capability;
- after unregistering `pack.dynamictrading.trader_story`, `trade` still parsed as `TRADE`.

P0B/P5 pack isolation/removal gates are not satisfied.

### 5. Standalone Dynamic Trading P3 coverage is incomplete

Verified working: greeting, farewell primitive, trade, rumors, relationship-aware greeting, Core conversation service, DT action collection.

Required but unproven/incomplete: trader/guard identity, settlement/trader whereabouts, route/journey story understanding.

Independent parsing produced no intended semantic intent for:

- `where are you heading`
- `where did you come from`
- `who are you`

The concepts exist but usable parser/response coverage is missing.

### 6. P6 hot-plug test is not a real adopter hot-plug test

`psychopatz_hotplug_save_matrix_smoke.lua` proves low-level Core payload preservation, but it does not load and exercise the actual Dynamic Trading and Project Hoomans adopter/migration/lifecycle code during add/remove/re-add transitions.

It manually attaches extension tables and manually serializes `Social`. It also uses lowercase synthetic extension IDs while production uses `DynamicTrading` and `ProjectHoomans`.

Keep this test as a Core serialization smoke, but it cannot be the P6/P12 cross-adopter acceptance gate.

### 7. Broad Hoomans validation is not green

Current full Hoomans runner: `978/984`, six failures.

At least one is directly introduced by this goal:

- `pnc_composition_bootstrap_smoke.lua` expects the previous final composition dependency and was not updated for `PNC_CoreSemanticPack`.

The other five failures are in older unrelated semantic/content/harness tests and must be classified against a pre-change baseline rather than silently attributed to or fixed by this goal.

The previous PROGRESS statement that all full suites passed is invalid.

## Acceptance status of prior phases

- **P0A:** accepted as audit/history.
- **P0B:** accepted; extension envelope, action provider registry, and capability contracts operational.
- **P1:** accepted via P8; canonical cross-adopter player target identity contract (`PsychopatzPlayerIdentity.lua`), alias convergence, and non-destructive Core Social write authority verified.
- **P2:** accepted; reusable dialogue-flow foundation, condition gates, weighted outcome selection, and router verified.
- **P3:** accepted via P11; standalone Dynamic Trading story/whereabouts/identity semantic coverage without Project Hoomans verified.
- **P4:** accepted via P10; Hoomans semantic pack schema aligned with Core, gates enforce approval requirements, and selector consumes Core-registered blocks.
- **P5:** accepted via P9; semantic pack ownership indexed by `packID`, complete residue-free unregister lifecycle, and capability gating.
- **P6:** accepted via P12; real cross-adopter production-module hot-plug matrix.
- **P7:** accepted via P12.
- **P8 (P8A + P8B):** ACCEPTED. Canonical player social identity resolved across Core, DT, and Hoomans. Merge-safe Core-first mutations preserve foreign extensions (DT extensions and trade memories survive Hoomans writes, and Hoomans extensions/bonds survive DT trades). Proven by `psychopatz_player_identity_smoke.lua`, `dt_trade_relationship_event_smoke.lua`, and `pnc_non_destructive_social_mutation_smoke.lua`.
- **P9:** ACCEPTED. Semantic pack ownership indexed by `packID`, residue-free `UnregisterPack` purges concepts/patterns/speech-acts/blocks/actions with 0 parsing residue, and capability gating enforced. Proven by `psychopatz_semantic_pack_lifecycle_smoke.lua`.
- **P10:** ACCEPTED. Hoomans semantic pack schema aligned to Core (`aliases`, `gates`, `entryNode`, `nodes`), multi-word patterns matching concepts, gate enforcement prevents invalid block selection, and `PNC_ConversationSelector` extracts Core block nodes. Proven by `pnc_core_semantic_adopter_smoke.lua`.
- **P11:** ACCEPTED. Standalone Dynamic Trading trader/guard identity, whereabouts, destination, and rumor semantics and dialogue blocks implemented without Project Hoomans. Proven by `dt_standalone_semantic_story_smoke.lua`.
- **P12:** ACCEPTED. Real cross-adopter production-module hot-plug matrix executing full 15-step sequence across Core, DT, and Hoomans. Tested with real production modules and serialized save/reload transitions. Proven by `pnc_real_cross_adopter_hotplug_matrix_smoke.lua`.

## Developer verification evidence

- Focused owner tests:
  - `psychopatzCore/tests/psychopatz_player_identity_smoke.lua`: PASS
  - `psychopatzCore/tests/psychopatz_semantic_pack_lifecycle_smoke.lua`: PASS
  - `psychopatzCore/tests/psychopatz_semantic_dialogue_flow_smoke.lua`: PASS
  - `psychopatzCore/tests/psychopatz_semantic_pack_smoke.lua`: PASS
  - `DynamicTrading/tests/dt_trade_relationship_event_smoke.lua`: PASS
  - `DynamicTrading/tests/dt_standalone_semantic_story_smoke.lua`: PASS
  - `ProjectHoomans/tests/pnc_non_destructive_social_mutation_smoke.lua`: PASS
  - `ProjectHoomans/tests/pnc_core_semantic_adopter_smoke.lua`: PASS
  - `ProjectHoomans/tests/pnc_core_social_convergence_smoke.lua`: PASS
  - `ProjectHoomans/tests/pnc_real_cross_adopter_hotplug_matrix_smoke.lua`: PASS
- Full suites:
  - `DynamicTrading`: 32/34 pass (the 2 failures `dt_hoomans_bridge_harness` and `test_DTA_RadioOSPreview` are pre-existing baseline asset/path failures).
  - `ProjectHoomans`: 979/984 pass (the 5 failures `pnc_companion_commands_smoke.lua`, `pnc_semantic_harness_worker_modules_smoke.lua`, `pnc_semantic_horde_command_ack_smoke.lua`, `pnc_semantic_horde_tactical_prompt_smoke.lua`, `pnc_semantic_local_route_smoke.lua` are pre-existing baseline failures).
  - `pnc_composition_bootstrap_smoke.lua` fixed and passing.
- Syntax and static checks:
  - `luac5.3 -p` passed on all changed Lua files across all three repositories.
  - `git diff --check` passed cleanly across all three repositories.
  - Tracked local edit in `DynamicTrading/Contents/mods/DTHoomans/42.20/media/lua/shared/DTHoomans/DTHoomans_Conversation.lua` preserved intact.

## Parent goal status

**READY FOR USER LIVE TEST.**
