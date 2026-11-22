# Progress — Thematic Semantic Dialogue Expansion

**Status:** D0–D8 COMPLETE (ALL DEVELOPER ACCEPTANCE GATES PASSED, 0 MANDATORY FINDINGS); READY FOR D9 USER NATIVE SP/MP ACCEPTANCE.
**Primary repository:** /home/psychopatz/Zomboid/Workshop/ProjectHoomans
**Participants:** /home/psychopatz/Zomboid/Workshop/psychopatzCore (`cf8a1d4`), /home/psychopatz/Zomboid/Workshop/DynamicTrading (`c176e171`).
**Branch policy:** existing main only; no new branch.
**Current ProjectHoomans HEAD:** 765345614 (pre-D8 commit)
**Current psychopatzCore HEAD:** cf8a1d4
**Current DynamicTrading HEAD:** c176e171
**Current phase:** D9 — User-owned native Project Zomboid SP/MP acceptance.
**Next Chunk:** User native SP/MP verification checklist (no further autonomous developer edits until user feedback).

## Completed phases

- **D0 (CODE_VERIFIED, TEST_VERIFIED):** Built and froze exhaustive machine-readable manifest at `docs/Jobs/ThematicSemanticDialogueExpansion/D0_MANIFEST.json` against live heads (`PH:2b9d579d`, `Core:89f7b85a`, `DT:976e240e`). Verified clean CodeBuilder baseline (`reconcile.py --check`: `ok=true, clean=true`, 468 desired artifacts, 0 drift). Audited 494 canonical definitions (369 PH, 125 Core), 107 actor-encoded IDs, 40 style-encoded IDs, 48 overpacked pools, 7 empty style dirs, disposition projection double-counting across 8 seams, `DialogueBeats`->`CombatTargetCallouts` transport leakage, `SocialFlavorClient` scene/thread collision, and D5A chronology/world-event/DT projection seams.
- **D1 (CODE_VERIFIED, TEST_VERIFIED):** Normalized `event_reactions_farewell` (15 `flow.farewell.*` -> 1 `social.farewell.depart`), `combat_player_assault_reactions` (8 `combat.player_assaulted.*` -> 4 actor-agnostic `combat.assault.{friendly_fire,betrayal,hostile_taunt,react}`), `world_event_beats` (2 multi-meaning packs -> 4 `world.{alarm.react,utility.outage,object.notice,media.broadcast}`), `combat_ally_warning` (2 overpacked pools 18+32 -> 14 cohesive families), and `combat_kill` (26-variant `combat.kill.killer` -> 4 weapon-domain families); removed 7 empty `combat_banter_weapon_kill_*` dirs; added `convo_engine_hygiene_audit.py` (`hygiene-audit` CLI + 14 unit tests OK) in `psychopatzCore`; ran CodeBuilder `reconcile.py --apply` + `--check` (`ok=true, clean=true`, 470 desired artifacts, 0 drift); verified 7 targeted Lua smoke suites + 19 Python authority/reachability tests passing.
- **D2 (CODE_VERIFIED, TEST_VERIFIED):** Implemented `PNC.ConvoEngine.DispositionProjection` (`baseDisposition`, 6-axis transient `temporaryDemeanor`, `effectiveDisposition`, unified `ResolveStyle`) and converged `ActorAdapter_ProjectHoomans`, `ChoicePolicy`, `GeneratedAffordanceProvider`, `AffordanceResponder`, `PNC_SemanticCombatReactionProfile`, `PNC_SemanticBeatContext`, `SpeechStyleContext`, and `PNC_ConversationRules_Conditions` onto the single resolved numeric disposition projection (eliminating trait double-counting and divergent classifiers, retaining capability-only trait checks with documented rationale). Verified 0 Kahlua errors/warnings and 20+ Lua smoke suites including `pnc_unified_disposition_projection_smoke.lua` and `pnc_semantic_combat_reaction_profile_smoke.lua`.
- **D3 (CODE_VERIFIED, TEST_VERIFIED):** Isolated `lane="scene"` (`sceneID`, `SCENE_PRIORITY_FLOOR=80`) from transient `lane="beat"` (`threadID`, bounded `MAX_ACTIVE_THREADS=24`, TTL expiry) in Core `PsychopatzSocialFlavorClient.lua` (`3d0292a`, single queue + TTS preserved); extracted domain-neutral `PNC_SemanticSpeechTransport.lua` in ProjectHoomans; refactored `CombatTargetCallouts_Delivery` into a combat adopter; decoupled `DialogueBeats` and `environment.weather_rain` from combat delivery/event IDs; added bounded thread cleanup (`MAX_THREADS=32`), actor-unavailable cancellation, and `HandoffToScene` without ID collision; fixed interactive Scene priority floor in `ScenePresentation`/`VoiceGateway`. Verified 0 Kahlua errors/warnings and 12 Core + PH smoke suites passing.
- **D4 (CODE_VERIFIED, TEST_VERIFIED):** Authored 8 actor-agnostic thematic interactive dialogue families under `dialogue/thematic_interactive/` (`social.greeting.first_contact`, `wellbeing.needs.checkin`, `social.identity.personal_history`, `knowledge.gossip.exchange`, `colony.work.status_exchange`, `travel.excursion.plan_exchange`, `combat.aftermath.debrief_exchange`, `social.conflict.mediate_exchange`) with bounded 4–6 node `metadata.flow` graphs, `branchOffers`, `onUnrelated="suspend"`, typed slots, separated `stance` vs `outcome`, fail-closed `statePolicy`, and 100% EN/TL translation parity in grounded 1990s Kentucky survivor voice. Reconciled CodeBuilder (`ok=true, clean=true`, 483 desired artifacts, 0 drift) and verified `tests/pnc_thematic_interactive_branching_smoke.lua` passing.
- **D5 & D5A (CODE_VERIFIED, TEST_VERIFIED):**
  - `psychopatzCore` (`b7b5e59`): Added bounded `PsychopatzScopedWorldEvents` registry (`MAX_ACTIVE_EVENTS=32`, `MAX_HISTORY=64`, scope-indexed `QueryActive`/`AggregateEffects`/`PruneExpired`, `OnEventRegistered`/`OnEventExpired` with loop-guard `excludeSource`), `regionID` on `SurvivorWorldTypesCommunity`, and `ResolveEpistemicStatus` (`known`/`uncertain`/`unknown`) across `WorldKnowledge` (10 Core smoke suites + 0 Kahlua warnings).
  - `DynamicTrading` (`b02ff50b`, `44bc24ef`): Added `regionID` bridge in `DTCommon_CoreSettlementDirectoryProvider`, loop-free one-way `DTHoomans_WorldEventProjection` (`hoomans-world-event:` prefix into `DTCommon.MarketEvents`), and bounded `caravanRisk` penalty in `DTHoomans_CommercialMobility` (24/24 DT tests + `dt_world_event_projection_smoke.lua` + 0 Kahlua warnings).
  - `ProjectHoomans`: Added data-driven `PNC_ChronologyMilestones` (scalar watermarks, coarse bounded pump, `experienced` facts, Beat delivery), deterministic `PNC_ScopedWorldEventDirector` (`worldSeed+scope+timeBucket`, `food_crisis`/`agricultural_surplus`/`bandit_bonanza`/`severe_weather`/`epidemic`/`trade_disruption`, transient demeanor projection without mutating `social.personality`), causal simulation hooks (`PNC_GroupNeeds_Update`, `PNC_AbstractScavengeResolver`, `PNC_GroupGenerator_Selection`), and `WorldKnowledge` epistemic gating (14 PH smoke suites + 0 Kahlua warnings).
- **D6 & D7 (CODE_VERIFIED, TEST_VERIFIED):**
  - Authored canonical declarative Beat families `chronology.milestone.react`, `world.event.food_crisis`, `world.event.raider_surge`, and `world.event.surplus` with grounded 1990s Kentucky EN/TL translations; wired into `PNC_ChronologyMilestones`, `ResponseCatalog`, and `Social/Reaction`; cleaned immersion-breaking `"Charm cooldown"` jargon; raised `DialogueFlowRegistry.DEFAULT_MAX_FLOWS` (32->64) to accommodate the 8 thematic flows cleanly; reconciled CodeBuilder (`ok=true, clean=true`).
  - Extended Core Semantic Lab / Observatory (`cf8a1d4`) with D7 lane ownership (`sceneID`/`threadID`), inline hygiene badges, disposition/demeanor breakdown, grounding/provenance/epistemic status, and N-actor role bindings (16/16 Core Python tests OK).
  - Verified full D7 input/presentation parity (`pnc_input_presentation_parity_smoke.lua` + InlineChat/Group/Farewell/VoiceGateway/PBrainZ/declarative beats smoke suites passing).
- **D8 (CODE_VERIFIED, TEST_VERIFIED):** Independent adversarial functional + performance verification passed across all 3 repos: CodeBuilder `reconcile.py --check` (`ok=true, clean=true`, 485 desired, 0 drift), 18/18 PH Lua suites, 3/3 Core Lua + 7/7 Core Python + `audit-integrity` (`violationCount=0`), 24/24 DT suites, 3 PH performance benchmarks (`dialogue_and_combat_flow`, `combat_and_firearms_flow`, `data_mutation_and_mobile_groups_flow`), 83/83 touched mod `.lua` files passing `pz_verify.py --kahlua --severity WARNING` with 0 errors/warnings, static zero-new-`OnTick`/zero-`math.random()`/zero-global-scan/bounded-ModData guards, and Stage 6 repair removing all 6 `pcall(require, ...)` calls flagged by adversarial verification.

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
