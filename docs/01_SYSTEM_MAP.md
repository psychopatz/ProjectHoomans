# System Map

## Shared Core
- `PNC_Core`: environment helpers, time, players, logging, and the canonical managed-NPC-body predicate
- `PNC_Archetypes`: self-registering archetype registry plus preload-safe archetype bundle application
- `PNC_ArchetypeLoader`: imports registered archetype modules, applies pending bundles, and logs bootstrap health
- `PNC_Identity_Factory`: `SurvivorFactory`-first identity resolution
- `PNC_Identity_Profile`: persisted identity and appearance resolution
- `PNC_PlayerCharacterTypes`: pure player-character registry/record
  constructors, UUID/account validation, and deterministic normalization
- `PNC_SocialProfileConstants`, `PNC_SocialProfileTypes`, and
  `PNC_SocialProfileGenerator`: profile schemas, centralized enums, defensive
  normalization, and identity-seeded NPC personality generation
- `PNC_SocialTraits`: idempotent Build 42 character-trait registration,
  engine/server exclusions, canonical trait IDs, and pure profile resolution
- `PNC_SocialProfileMath`: orientation compatibility and pure observer event
  interpretation
- `PNC_Inventory`: compact player-like inventory tree with template-plus-delta persistence
- `PNC_Inventory_EquipmentGeneration`: generic categorized equipment pools and deterministic starting-equipment policy
- `PNC_DeathMarkers`: compact post-death identity/location persistence after full NPC retirement
- `PNC/EquipmentDefinitions/PNC_EquipmentPools`: version-independent built-in equipment catalog
- `PNC_Persistence`: versioned Core-extension / legacy record save schema,
  explicit outcome classification (`WRITTEN`/`TERMINAL_OR_NOT_APPLICABLE`/`RETRYABLE_FAILURE`),
  coalesced `PersistenceCoordinator.Pump` deferred flushing, and compact relog body hints
- `PNC_Registry`: authoritative NPC records, lazy Core promotion/demotion, and live body lookup
- `PNC_Performance`: debug-only runtime counters, gauges, and timings integrated
  with safe Core profiler `OFF`/`coarse`/`deep` modes; no performance telemetry is persisted
- `PNC_WorldCensus`: single canonical 3-tier activity-sensitive (`100`/`250`/`1000 ms`)
  loaded-zombie snapshot (including `BanditBodies`) shared by spatial indexing,
  lifecycle auditing/startup maintenance, Bandits targeting, managed-body scans, and aggro discovery
- `PNC_EntityRef`: stable `npc:` and account-plus-character `player:` keys
- `PNC_RelationshipTypes`, `PNC_RelationshipMath`, and
  `PNC_RelationshipStates`: serialization-safe directed social records,
  deterministic memory decay, cached score calculation, and hysteresis
- `PNC_Relationships`: server-authoritative personal relationship API plus the
  faction-aware intent matrix and disposition transitions; authorized leaders
  may report personal grievances, but personal `enemy` does not force war by
  default
- `PNC_SocialEventDefinitions`: data-only balance, allowed-source, cooldown,
  saturation, and observer rules for the five Phase 2 events
- `PNC_ConductConstants`, `PNC_ConductTypes`, `PNC_ConductMath`, and
  `PNC_ConductDefinitions`: actor-owned behavioral schema, objective score
  derivation/decay, evidence limits, and the five accepted-event mappings
- `PNC_FactionConstants`, `PNC_FactionArchetypes`,
  `PNC_FactionDiplomacyMath`, `PNC_FactionIncidentDefinitions`,
  `PNC_FactionIntent`, and `PNC_FactionTypes`: organizational/diplomacy
  enums, four deterministic policy archetypes, pure directed-state
  math/intent, server-owned incident balance, V3 registry normalization,
  player keys, and primitive NPC affiliation/history
- `PNC_CommunityConstants`, `PNC_CommunityProfiles`,
  `PNC_CommunityMath`, and `PNC_CommunityTypes`: fixed community modes,
  creation-only defaults, pure home-area geometry, V1 registry records, and
  deterministic secondary-index normalization
- `PNC_SpatialIndex`: nested numeric-cell player, NPC, and zombie queries built
  from the shared world census; player identity maps also provide constant-time
  owner lookup
- `PNC_Stealth`: follow-stealth state and stealth-based combat suppression
- `PNC_Perception`: target selection, zombie lookup, and nearby threat counting
- `PNC_Perception_Frame`: short-lived per-NPC zombie candidate, LOS, and
  multi-radius threat-count cache
- `PNC_PerceptionService` and `PNC_PerceptionRuntime`: activity-sensitive
  `100/250/1000 ms` perception cadence, squared-distance + cosine azimuth cone
  pre-filter (`PassesBodyVisionCone` used by `PNC_Perception_Frame`,
  `Visibility`, and `ActorSearch` with `2.5m` peripheral ring + engaged-threat
  bypass), budgeted `<= 8`/tick LOS queue (pumped in `FinishTick` when pending),
  `OnWorldSound` listener/shock bridge, and bounded `ClueMemory`
- `PNC_Stamina`: stamina authority, recovery, attack costs, and visibility timers
- `PNC_NeedsDefinitions` and `PNC_NeedsUtils`: centralized 0–100 Need
  definitions, condition levels, initialization ranges, elapsed-time rate
  inputs, and serialization-safe state normalization
- `PNC_Visuals`: owns appearance application and reusable body-visual operations such as clothing visuals, attached-item cleanup, and model refresh
- `PNC_Animation`: single animation state writer
- `PNC_SecondaryChannel`: orthogonal non-interrupting layer for coincident-guarded
  `faceLocationF` gaze, Build 42 `AnimSet` variables (`PNCAlertLevel`,
  `PNCPosture`, `PNCSecondaryState`) replicated via `BuildPresenceDelta` and
  reset on abstraction/reanimation, and priority-gated barks with lazy
  multiplicative line-exhaustion recovery
- Compiled AI & ConvoEngine Catalogs (`common/media/lua/shared/PNC/`): generated
  by `PsychopatzCore` `CodeBuilder` under `AutonomyAd`, `ReactionPolicy`,
  `WorkScenario`, and `ConvoEngine/Index/Director` (sparse Director inverted index
  with zero duplicate behavior/beat bodies)
- `PNC_Health`: custom HP, incapacitation, death ownership
- `PNC_Combat`: combat entry
- `PNC_Combat_Melee`: melee attack start rules
- `PNC_Combat_Ranged`: ranged attack start rules
- `PNC_Combat_Firearms`: weapon-derived magazine capacity, companion ammunition
  policy, and timed reload actions
- `PNC_Combat_AttackActions`: delayed hit windows and attack pumping
- `PNC_Combat_Tactics`: conservative kiting and repositioning
- `PNC_Combat_Unarmed`: shove and stomp helpers
- `PNC_LiveBodyControl`: reusable suppression of vanilla zombie-only body
  states, replicated `isUseless` drift, and Build 42 zombie voice channels
- `PNC_EnginePathPlanner`: budgeted SP native `PathFindBehavior2` ownership and
  unbudgeted MP goal publication for meaningful local/travel routes,
  coordinated by `PNC_PathService`
- `PNC_PathService`: live stepping and abstract travel
- `PNC_CompanionVehicle`: authority-owned companion boarding, abstract vehicle
  travel, engine-visible seat reservations, disembarkation, and stale-token
  repair
- `PNC_CompanionCommandRegistry`: companion-only movement/attack-type command
  registration, ownership validation, authority execution, and replicated
  feedback revisions.
- `PNC_CompanionCommandFlavor`: expandable translated player/NPC command
  flavor registry; client presentation consumes each acknowledgement once.
- `PNC_CompanionCommandEmotes` and `PNC_ContextProvider_Commands`: registry-
  driven radial/context adapters with private nested command groups, separate
  closest/group radial scopes, and target-aware command presentation.
- `PNC_OrderSystem`: order normalization and ownership
- `PNC_JobSystem`: selects active job from order and state and accepts registered order-to-job mappings
- `PNC_BehaviorSystem`: thin coordinator that executes the active job
- `PNC_BehaviorRegistry`: extensible job-to-handler dispatch used by self-contained behavior modules
- `PNC_Behavior_MoveIntent`: single behavior-side move intent writer consumed by pathing
- `PNC_Behavior_Common`: shared owner, movement, and combat-debug helpers
- `PNC_Behavior_Targeting`: target refresh and facing helpers
- `PNC_Behavior_Combat`: combat engage sequencing
- `PNC_Behavior_Companion`: colonist follow, guard, and patrol job handlers
- `PNC_Behavior_Roaming`: faction-neutral, enemy-aware roaming with registered roam modes
- `PNC_Behavior_Hostile`: hunt and direct engage job handlers
- `PNC_Behavior_Incapacitated`: crawl and downed shove handling
- `PNC_BodyLifecycle`: stable facade for live-body leases, corpse conversion,
  keyed identity-card injection through `PsychopatzCore.CorpseItems`,
  authority-owned infected-corpse reanimation, persisted naked-shell startup
  cleanup, loaded-world audits, and diagnostics; implementation ownership is split under
  `Presence/PNC_BodyLifecycle/`
- `PNC_Presence`: live and abstract transitions, naked engine-shell
  materialization, and pre-spawn stale-shell cleanup
- `PNC_SimulationClock`: independent runtime deadlines for presence, vitals,
  pathing, and other simulation domains
- `PNC_SimulationLOD`: combat, moving, live-idle, abstract-near,
  abstract-far, and dormant cadence policy
- `PNC_Scheduler`: identity-seeded LOD scheduling and a hard 24-record
  server-tick budget with overflow deferred to later slots
- `PNC_Network`: roster snapshots (with `NPCReplicationScaling` P1-P4 negotiation),
  narrow authoritative domain deltas (`presence`, `combat_damage`, `combat_state`,
  `health_wounds`, `equipment`), full repair/fallback snapshots, and stale-body removals
- `PNC_ZombieAggro`: zombie-to-NPC aggro bridge and bite flow
- `PNC_ZombieAggro_ActiveSet`: deduplicated expiring zombie work set with
  per-entry pursuit/idle cadence, immediate urgent wakes, and per-tick update/path budgets
- `PNC_API`: external entry points

## Layout Rule
- reusable definitions, translation catalogs, clothing XML, animations, and
  other version-agnostic content belong in `common/media/...`
- `42.20/media/...` owns executable Lua and assets coupled to the current
  Project Zomboid runtime/API
- common definition files must remain declarative; runtime registries,
  lifecycle services, UI integrations, and engine adapters stay in `42.20`

## Composition and Bootstrap

- `shared/PNC/00_PNC_Init.lua`, `server/PNC/00_PNC_Server_Init.lua`, and
  `client/PNC/00_PNC_Client_Init.lua` are deliberate PZ/Kahlua early-loading
  anchors and must remain thin.
- The anchors delegate respectively to `PNC_SharedComposition`,
  `PNC_ServerComposition`, and `PNC_ClientComposition` under each runtime
  layer's `PNC/Composition/` directory.
- Composition roots own deterministic ordered `require(...)` calls. Ordinary
  implementation modules must not depend on alphabetical filename order.
- Server and client composition both begin through the shared anchor. The
  server profiler installation and client EventMarkers binding retain their
  established positions in their respective ordered manifests.
- A bootstrap/load-order change requires SP, hosted-MP, and dedicated-server
  startup validation before it is considered runtime-validated.

## Ownership and Load-Order Rules
- use `PNC.Core.IsManagedNPCBody` instead of defining subsystem-local checks for the `PNC_NPC` body marker
- equipment describes and applies loadout state, but reusable model and clothing-visual mutations belong to `PNC_Visuals`
- weapon-only changes use `PNC.Equipment.ApplyHands`; full equipment application is reserved for worn or attached-item changes so existing clothing tints are preserved
- starting equipment is independent of archetypes; combat consumes generated
  capability and does not choose or spawn inventory items
- modules required before one of their collaborators must resolve that collaborator from `PNC` at call time; do not capture a not-yet-loaded table in a file-local variable
- population-wide engine enumeration belongs in `PNC_WorldCensus`; consumers
  must not add an independent per-tick `getZombieList()` scan
- cadence decisions belong in `PNC_SimulationLOD`, while independent subsystem
  deadlines belong in `PNC_SimulationClock`
- multi-job behavior entry points dispatch to one handler per job so follow, guard, and patrol control flow remains independently testable
- body-lifecycle callers use the public `PNC.BodyLifecycle` methods; new engine operations, corpse policies, and audit rules belong in their focused internal module instead of the facade

## Server
- `PNC_Server`: authority tick, full sync, debug commands
- `PNC_PlayerCharacterService`: authoritative UUID registry, claim validation,
  entity-key resolution, death state, and runtime bindings
- `PNC_PlayerCharacterLifecycle`: guarded Build 42 callbacks plus a throttled
  authoritative player availability/death/disconnect sweep
- `PNC_PlayerCharacterDebug`: opt-in identity and combat callback diagnostics
  plus read-only character-record formatting
- `PNC_SocialProfileService`: authoritative live-trait resolution, UUID-owned
  player profile commits, NPC profile access, and pure-helper facade
- `PNC_SocialProfileDebug`: disabled-by-default profile diagnostics and
  read-only player/NPC formatters
- `PNC_ConductService` and `PNC_ConductDebug`: authority-only evidence
  mutation, UUID/NPC ownership, copied reads, and sanitized formatting
- `PNC_FactionService`, `PNC_FactionIncidentService`, and
  `PNC_FactionDebug`: separate `PNC_Factions` ModData ownership, generated
  identity, copied directed queries, atomic membership/treaties, attack
  aggregation, policy-aware escalation, player factions,
  leadership/archive operations, index repair, and sanitized inspection
- `PNC_FactionBehavior`: centralized derivation of companion ownership,
  tactical class, order, and hostility fields from canonical faction state
- `PNC_CommunityService`, `PNC_CommunitySiteResolver`,
  `PNC_CommunityDirector`, `PNC_CommunityValidation`, and
  `PNC_CommunityDebug`: separate `PNC_Communities` ModData authority,
  reusable primitive hideout sites, loaded/meta-building discovery, random
  residential debug allocation, abstract-first group generation,
  faction-owned settlements/camps, affiliation-V2 placement, atomic
  membership and summary mutations, invariant checks, and sanitized snapshots
- `PNC_IndividualNeeds`, `PNC_GroupNeeds`, `PNC_NeedsScheduler`, and
  `PNC_NeedsDebug`: server-authoritative companion Need records, one aggregate
  Need state per mobile faction, elapsed-time-only simulation, guarded future
  AI listener hooks, and debug snapshots/actions
- `PNC_ColonyManagement`: server-built player-companion/Community presentation
  snapshot; it derives warnings and condition summaries without duplicate Need
  storage
- `PNC_RelationshipService`: authoritative directed relationship mutations
- `PNC_RelationshipDebug`: read-only selected-pair snapshots/formatting plus
  admin/debug-only named-event test dispatch through the real event service
- `PNC_SocialEventService`: validation, dedupe, cooldown/saturation, memory
  construction, and atomic event processing
- `PNC_SocialEventHooks`: stable-identity milestone adapters and verified
  incapacitation rescue attribution
- `PNC_SocialEncounterTracker`: non-persistent, stable-key combat aggregation
  for protection, shared survival, and conservative abandonment
- `PNC_SocialWitnessService`: server-authoritative witness-bounded `PsychopatzSocial`
  memory recording and deduplicated 1-hop hearsay propagation
- `PNC_SocialEventDebug`: opt-in read-only processed-event diagnostics
- `PNC.Tasking` (`PNC_TaskPriority`, `PNC_TaskLeaseService`, `PNC_Tasking_Claims`):
  unified 8-band priority arbiter (`SAME_BAND_MARGIN = 0.08`, cap `64`), dirty
  reevaluation queue, and atomic lease-bound resource claims
- `PNC_WorkService` & `PNC_WorkToilRunner`: `O(dirty)` colony work reconciler
  and 5-step dual executor unifying `FARMING`, `FISHING`, `LUMBER`, and
  `CORPSE_HAUL` adapters with `AbortOrder` claim/input/tool cleanup
- `PNC_AutonomyScorer`, `PNC_AutonomyTaskProvider`, `PNC.AutonomyExecutors`
  (`server/PNC/Tasking/Autonomy/Executors/`, 16 modular files folding retired
  `Settlement/FacilityJobs` ambient/seat loops into `PNC.Tasking` with zero
  polling bypasses), `PNC_CoPresenceService`, and `PNC_ScenarioScheduler`:
  compiled-IR `OPTIONAL`/`IDLE` autonomy scoring, hysteresis, co-presence
  situations, and time-of-day scenario chaining (with canonical Core-backed
  persistence, SurvivorWorld, and social adapters without pre-publication
  migration shims)
- `PNC_AgitationService`, `PNC_ReactionPolicyEvaluator`, and
  `PNC_ShockingReactionTaskProvider`: sparse lazy-decay agitation and 5-intent
  non-lethal reactivity (`StopAndAssess`, `BackAway`, `Investigate`,
  `WarnGroup`, `SmartFlee`) subscribed to Core `PsychopatzShockingEventBus`
- `PNC_DialogueMicroBeatDirector`, `PNC_JointSceneLeaseService`, and
  `PNC_StreetInteractionService`: zero-LLM 5-stage micro-beat dialogue director
  atop `ConvoEngine`, 2–4 participant `JointSceneLease`, global mix-ins,
  `FinishTick` O(1)-guarded timeout/lease sweeps, and RDR2-style
  `GREET`/`ANTAGONIZE`/`DEFUSE` street acts
- `PNC_UnifiedAIDebugService`: server-authoritative Unified AI & Cone Debug Lab
  snapshot builder and live trigger dispatcher (`emit_gunfire`, `emit_explosion`,
  `emit_weapon_aimed`, `emit_suspicious_sound`, `street_greet`,
  `street_antagonize`, `street_defuse`, `trigger_copresence`, `inject_mixin`,
  `reevaluate_ai`, `clear_npc_ai`)

## Client
- `PNC_Client`: roster cache, character-payload cache, sync requests, context menu debug tools
- `PNC_RelationshipDebugWindow` and `PNC_RelationshipDebugModel`:
  admin/debug-only directed relationship inspection, reverse-direction
  comparison, memory/revision diagnostics, and guarded named-event triggers
- `PNC_FactionDebugWindow` and `PNC_FactionDebugModel`: admin/debug-only
  source/target organization inspection with both directed opinions, policy,
  incident/intent diagnostics, and service-backed incident, treaty,
  membership, player-faction, role/rank, leader, transfer, and archive controls
- `PNC_CommunityDebugWindow`, `PNC_CommunityDebugModel`,
  `PNC_CommunityDebugOverlay`, and `PNC_MapLayer_Communities`: guarded
  fixed-community inspection, service-backed controls, NPC diagnostics,
  hideout map shapes, and vacant-site claim dispatch
- `PNC_ColonistWindow`: normal player-facing roster, Needs, Activities, and
  Task pages, plus the gated storage/provision `DEBUG` tab
- `PNC_ColonyManagementWindow`: normal player-facing overview, people, and
  colony-management pages opened from the in-game radio UI; its migrated
  debug tab is no longer exposed
- `PNC_DebugSpawnMenu`: nested faction/equipment debug-spawn presentation
- `PNC_ClientPresenceSync`: multiplayer live-body reconciliation for nearby
  embodied NPCs, including canonical-instance selection and duplicate shell
  pruning
- `PNC_ClientHumanNPCSafeguards`: client-local correction for vanilla
  `IsoPlayer.updateLOS` treating managed human bodies as visible zombies,
  including panic, sleep, and single-player fast-forward side effects;
  preserves all ordinary-zombie threat behavior
- `PNC_LiveBodyControl`: pre-AI `OnZombieUpdate` safety plus world-ready scans
  ensure persisted and legacy NPC bodies cannot target or bite during relog
- `PNC_HumanNPCSleepPatch`: refreshes corrected threat counters immediately
  before delegating to the unmodified vanilla sleep decision
- `PNC_VehicleSeatPatch`: prevents vanilla seat-item movement from extracting
  an abstract NPC reservation token and reports the named occupant
- `PNC_ContextHub`: central reusable NPC selection and right-click hub
- `PNC_NPCSelection`: cursor-space NPC selection helper used by context providers
- `PNC_Nameplates`: overhead name, HP, stamina, and live combat/perception
  debug overlay (compiled cone radius/FOV, `2.5m` peripheral ring, clue
  markers, and `VISION`/`REACT` telemetry rendered both in combat and idle)
- `PNC_UnifiedAIDebugWindow` (`pnc.unifiedAI` in PsychopatzCore Debug Hub):
  SP & MP Unified AI & Cone Debug Lab inspecting live perception cones, clues,
  agitation, secondary channel, claims, autonomy, and micro-beat scenes with
  one-click live event triggers
- `PNC_CharacterWindow`: vanilla-like NPC character shell and tabs
