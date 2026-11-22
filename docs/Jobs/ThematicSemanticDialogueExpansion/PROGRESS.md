# Progress — Thematic Semantic Dialogue Expansion

**Status:** D1 COMPLETE; proceeding into D2.
**Primary repository:** /home/psychopatz/Zomboid/Workshop/ProjectHoomans
**Participants:** /home/psychopatz/Zomboid/Workshop/psychopatzCore when reusable ConvoEngine/world-event contracts change; /home/psychopatz/Zomboid/Workshop/DynamicTrading when D5A economic world-event projection requires DTCommon/DTHoomans changes.
**Branch policy:** existing main only; no new branch.
**Current ProjectHoomans HEAD:** 962d79f7c (pre-D1 commit)
**Current psychopatzCore HEAD:** 569e169
**Current DynamicTrading HEAD:** 04febebf
**Current phase:** D2 — Unified actor disposition/personality projection.
**Next Chunk:** Converge `ActorAdapter`, `ChoicePolicy`, `GeneratedAffordanceProvider`, `AffordanceResponder`, `SemanticCombatReactionProfile`, `BeatContext`, `SpeechStyleContext`, and condition predicates onto one resolved numeric disposition projection (with temporary demeanor overlay seam).

## Completed phases

- **D0 (CODE_VERIFIED, TEST_VERIFIED):** Built and froze exhaustive machine-readable manifest at `docs/Jobs/ThematicSemanticDialogueExpansion/D0_MANIFEST.json` against live heads (`PH:2b9d579d`, `Core:89f7b85a`, `DT:976e240e`). Verified clean CodeBuilder baseline (`reconcile.py --check`: `ok=true, clean=true`, 468 desired artifacts, 0 drift). Audited 494 canonical definitions (369 PH, 125 Core), 107 actor-encoded IDs, 40 style-encoded IDs, 48 overpacked pools, 7 empty style dirs, disposition projection double-counting across 8 seams, `DialogueBeats`->`CombatTargetCallouts` transport leakage, `SocialFlavorClient` scene/thread collision, and D5A chronology/world-event/DT projection seams.
- **D1 (CODE_VERIFIED, TEST_VERIFIED):** Normalized `event_reactions_farewell` (15 `flow.farewell.*` -> 1 `social.farewell.depart`), `combat_player_assault_reactions` (8 `combat.player_assaulted.*` -> 4 actor-agnostic `combat.assault.{friendly_fire,betrayal,hostile_taunt,react}`), `world_event_beats` (2 multi-meaning packs -> 4 `world.{alarm.react,utility.outage,object.notice,media.broadcast}`), `combat_ally_warning` (2 overpacked pools 18+32 -> 14 cohesive families), and `combat_kill` (26-variant `combat.kill.killer` -> 4 weapon-domain families); removed 7 empty `combat_banter_weapon_kill_*` dirs; added `convo_engine_hygiene_audit.py` (`hygiene-audit` CLI + 14 unit tests OK) in `psychopatzCore`; ran CodeBuilder `reconcile.py --apply` + `--check` (`ok=true, clean=true`, 470 desired artifacts, 0 drift); verified 7 targeted Lua smoke suites + 19 Python authority/reachability tests passing.

## Re-audit findings

CODE_VERIFIED planning findings:
- first-party InlineChat now owns the inline semantic input surface; PBrainZ is no longer the UI owner;
- threadID now crosses transient speech/presentation and Core SocialFlavor arbitration;
- PNC.Semantics.DialogueBeats adds a bounded pending-turn queue and shared-pump environment/event checks;
- BeatContext and new world/combat/stamina/medical/player-assault beat adopters materially expanded the semantic runtime;
- non-combat DialogueBeats currently reuse CombatTargetCallouts delivery/event IDs, creating a domain-neutral transport refactor target;
- current corpus has 353 dialogue JSON files, 5 actual flow structures, 1 branchOffers and 3 onUnrelated occurrences;
- 35 source names/IDs contain player/NPC identity markers and 26 contain personality/style markers;
- 15 farewell definitions split player/non-player and relationship variants while representative flow.farewell.* files have no actual flow graph;
- large variant pools may be overpacked: combat.ally_warn.reply=32 variants, combat.kill.killer=26, combat.ally_warn.callout=18, world.beats.* combine multiple event meanings;
- direct generic temperament checks remain in Social ChoicePolicy and GeneratedAffordanceProvider;
- SemanticCombatReactionProfile mixes direct trait classifiers with numeric thresholds and BeatContext contains fallback style classification, so the old D2 scope was too narrow;
- recent combat/pathing/persistence/data-mutation commits improved lag and are now explicit D8 regression baselines.

## What changed from the original plan

1. Added a formal two-lane contract: interactive Scenes vs transient Beat threads.
2. Added anti-overpacking as well as anti-duplication.
3. Expanded numeric-personality normalization into a shared disposition-projection phase.
4. Added a domain-neutral semantic speech transport phase because world beats currently depend on combat delivery.
5. Added declarative migration of hard-coded beat policy into canonical ConvoEngine Beat/Behavior/Dialogue sources where practical.
6. Added first-party InlineChat/group/farewell/threadID/TTS parity to acceptance.
7. Clarified that this goal does not add per-turn randomness; seeded personality + context is the intended emergence mechanism.

## Parent acceptance

Parent completion requires D0–D8. D9 remains user-owned native SP/MP acceptance. A completed content family, transient beat domain, UI surface, or phase is not parent completion.

## Safety

- Preserve unrelated/concurrent work.
- Do not reset, stash, rebase, force, or change ownership.
- Use scoped Git safe-directory handling only when needed; do not alter global config for this job.
- Do not hand-edit generated Lua/translations.
- Do not push/publish/Workshop-upload without explicit authorization.
- Do not drive native Project Zomboid unless explicitly assigned.

## Additional requested scope — chronology and world-state events

The plan now also requires support for:
- actor survival milestones such as first month/year through a data-driven bounded milestone registry;
- temporary event-driven demeanor/affect changes without mutating base seeded personality;
- future scoped world/random events affecting global/region/faction/settlement/local-area simulation;
- grounded dialogue/Beat reactions to those events;
- cross-mod economic projection into Dynamic Trading's existing MarketEvent/SettlementMarket pipeline.

Verified integration evidence:
- Core already provides bounded WorldKnowledge facts/provenance and generic event buses, but no equivalent persisted scoped long-duration world-event authority was identified in this audit;
- Project Hoomans already owns GroupNeeds, starvation/dehydration health consequences, abstract scavenging, faction/mobile-group behavior, SurvivorWorld adapters and settlement/faction identity;
- Dynamic Trading already owns a bounded generic MarketEvent registry with global/region/faction/settlement scopes and supply/demand/availability/price modifiers, plus pressure-derived food-shortage/agricultural-surplus producers.

The architecture therefore must not make Dynamic Trading the global-event authority. D5A owns the audit and smallest shared scoped-event contract/adapters required for multi-mod consumption.
