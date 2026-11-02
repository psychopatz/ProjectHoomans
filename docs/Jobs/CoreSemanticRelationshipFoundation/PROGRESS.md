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
- **P0B:** partial; extension/action-provider foundation exists, but semantic pack lifecycle/capability contract is addressed in P9.
- **P1:** accepted via P8; canonical player target identity and non-destructive Core authority achieved.
- **P2:** reusable dialogue-flow foundation exists and focused tests pass.
- **P3:** partial; standalone DT works for a useful subset; mandatory role/whereabouts/story coverage addressed in P11.
- **P4:** addressed in P10; Hoomans pack schema and production integration.
- **P5:** partial; pack lifecycle/capability isolation addressed in P9.
- **P6:** addressed in P12; real adopter hot-plug matrix.
- **P7:** addressed in P12.
- **P8 (P8A + P8B):** ACCEPTED. Canonical player social identity resolved across Core, DT, and Hoomans. Whole-snapshot overwrites eliminated; merge-safe Core-first mutations preserve foreign extensions (DT extensions and trade memories survive Hoomans writes, and Hoomans extensions/bonds survive DT trades). Proven by `psychopatz_player_identity_smoke.lua`, `dt_trade_relationship_event_smoke.lua`, and `pnc_non_destructive_social_mutation_smoke.lua`.

## Current phase

**P9 — Core Semantic Pack Ownership, Complete Unregister Lifecycle & Capability Enforcement.**

### Next Chunk — P9: Semantic pack ownership and complete lifecycle isolation

Requirements:
1. In `psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Semantics/PsychopatzSemanticPackRegistry.lua`:
   - Explicitly index all registered items (concepts, speech acts, patterns, dialogue blocks, action providers) by `packID`.
   - Implement complete, residue-free `UnregisterPack(packID)`: remove all owned concepts, speech acts, and patterns from `PsychopatzSemanticRegistry` so uninstalled/disabled packs leave no parsing residue (e.g. DT trade tokens or Hoomans commands cease to parse when their pack is unregistered).
   - Enforce pack-level `capabilitiesRequired` for dialogue block selection and parser arbitration.
2. Add adversarial lifecycle test `tests/psychopatz_semantic_pack_lifecycle_smoke.lua` in `psychopatzCore` proving:
   - Registering a pack adds its concepts/speech acts/dialogue blocks.
   - Unregistering the pack completely purges them from the parsing and dialogue systems with 0 residual side effects.
   - Missing required capabilities prevents dialogue blocks and action execution.
3. Validate all Core tests and run syntax checks.
4. Continue automatically to P10.

## Remaining mandatory phases

- **P9:** repair Core semantic pack ownership/lifecycle/capability enforcement.
- **P10:** repair Project Hoomans semantic adopter schema and connect it to real production paths.
- **P11:** finish standalone Dynamic Trading identity/whereabouts/story semantics using real DT world knowledge.
- **P12:** replace synthetic hot-plug acceptance with real adopter integration, rerun broad regressions, reconcile docs, and only then hand off for native SP/MP testing.

## Parent goal status

**IN PROGRESS.**

Do not return to READY FOR USER LIVE TEST until P8-P12 pass and the acceptance document is reconciled with actual evidence.
