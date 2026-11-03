# Progress — Core Semantic & Relationship Foundation

**State:** READY FOR USER LIVE TEST.

No developer implementation phase remains. P0-P20 are complete; native Project Zomboid SP/MP acceptance is user-owned.

## Final repository snapshot

Reverified before this documentation reconciliation:

- `psychopatzCore`: `main @ c62262c`, 11 commits ahead of `origin/main`, clean.
- `DynamicTrading`: `main @ 89cfe191`, 13 commits ahead of `origin/main`, clean.
- `ProjectHoomans`: `main @ 29be4cfb`, 26 commits ahead of `origin/main`, clean.

Historical Git correction: the former uncommitted `DTHoomans_Conversation.lua` semantic-hub edit was incorporated into Dynamic Trading commit `be9e8e10`; it is not an outstanding working-tree modification.

## Final developer acceptance

Verified developer outcomes:

- Core owns canonical actor/player social identity and authoritative issuance state.
- Unknown Hoomans mirror UUIDs cannot create Core authority by lookup order.
- DT-first and Hoomans-first identity adoption converge on the same canonical UUID/key.
- DT/Hoomans interleaved relationship writes preserve foreign memories/extensions.
- semantic-pack unregister/re-register is residue-free.
- production conversation parsing respects effective adopter capabilities.
- Dynamic Trading supports the required standalone identity/trade/whereabouts/news/story/farewell semantics.
- factual route/news answers use canonical DT/Core state; missing evidence yields bounded uncertainty.
- excursion lifecycle drives canonical home/current/origin/destination state.
- settlement/community machine IDs resolve to human-facing names.
- FAILED excursion handling is correct before departure, after departure, while visiting, while returning, and across retry.
- reconstructed persistence uses a fresh backing table and distinct trader objects while preserving factual state and WorldKnowledge evidence.

## Final validation

- PsychopatzCore focused identity/social/conversation/semantic checks: PASS.
- Dynamic Trading full runner: `43/43` PASS.
- Project Hoomans full runner: `982/987`.
- Changed P20 Lua: PASS under `luac5.3 -p`.
- All three repositories: `git diff --check` PASS.

The five Hoomans failures are unchanged documented baselines:

1. `pnc_companion_commands_smoke.lua`
2. `pnc_semantic_harness_worker_modules_smoke.lua`
3. `pnc_semantic_horde_command_ack_smoke.lua`
4. `pnc_semantic_horde_tactical_prompt_smoke.lua`
5. `pnc_semantic_local_route_smoke.lua`

They are not attributed to this completed parent goal.

## Remaining user-owned acceptance

Run representative native SP/MP saves to validate real engine serialization, add/remove/re-add flows, excursion failure/recovery, settlement naming, conversation/UI quality, and multiplayer lifecycle behavior.

No Workshop publication is implied or authorized by this state.
