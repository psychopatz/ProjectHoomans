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
- `PNC_Persistence`: versioned canonical save schema, migration, runtime
  rehydrate, and compact prior-body instance hints used only for relog cleanup
- `PNC_Registry`: authoritative NPC records and live body lookup
- `PNC_Performance`: debug-only runtime counters, gauges, and timings; no
  performance telemetry is persisted
- `PNC_WorldCensus`: one cadence-bounded loaded-zombie snapshot shared by
  spatial indexing, lifecycle auditing, and aggro discovery
- `PNC_EntityRef`: stable `npc:` and account-plus-character `player:` keys
- `PNC_RelationshipTypes`, `PNC_RelationshipMath`, and
  `PNC_RelationshipStates`: serialization-safe directed social records,
  deterministic memory decay, cached score calculation, and hysteresis
- `PNC_Relationships`: server-authoritative personal relationship API plus the
  faction-aware enemy matrix and disposition transitions; Phase 5B escalates
  a faction member's `enemy` state toward a player into faction war
- `PNC_SocialEventDefinitions`: data-only balance, allowed-source, cooldown,
  saturation, and observer rules for the five Phase 2 events
- `PNC_ConductConstants`, `PNC_ConductTypes`, `PNC_ConductMath`, and
  `PNC_ConductDefinitions`: actor-owned behavioral schema, objective score
  derivation/decay, evidence limits, and the five accepted-event mappings
- `PNC_FactionConstants`, `PNC_FactionArchetypes`, and `PNC_FactionTypes`:
  organizational/diplomacy enums, four data-only archetypes, faction
  registry/record normalization, player keys, and primitive NPC
  affiliation/history
- `PNC_SpatialIndex`: nested numeric-cell player, NPC, and zombie queries built
  from the shared world census; player identity maps also provide constant-time
  owner lookup
- `PNC_Stealth`: follow-stealth state and stealth-based combat suppression
- `PNC_Perception`: target selection, zombie lookup, and nearby threat counting
- `PNC_Perception_Frame`: short-lived per-NPC zombie candidate, LOS, and
  multi-radius threat-count cache
- `PNC_Stamina`: stamina authority, recovery, attack costs, and visibility timers
- `PNC_Visuals`: owns appearance application and reusable body-visual operations such as clothing visuals, attached-item cleanup, and model refresh
- `PNC_Animation`: single animation state writer
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
- `PNC_Behavior_Companion`: colonist follow, guard, and patrol job handlers (legacy module filename)
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
- `PNC_Network`: roster snapshots, live presence snapshots, instance-specific
  stale-body removals, and on-demand character payloads
- `PNC_ZombieAggro`: zombie-to-NPC aggro bridge and bite flow
- `PNC_ZombieAggro_ActiveSet`: expiring spatially discovered zombie work set
  with separate per-tick update and pursuit-path budgets
- `PNC_API`: external entry points

## Layout Rule
- reusable archetype definitions, translation files, clothing XML, and other version-agnostic content belong in `common/media/...`
- `42.16/media/...` should hold only build-specific runtime Lua and assets that genuinely differ by Project Zomboid version
- common archetype definition files must store declarative bundles only; runtime registry ownership stays in the versioned core loader/registry

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
- `PNC_FactionService` and `PNC_FactionDebug`: separate `PNC_Factions`
  ModData ownership, generated identity, copied queries, atomic membership,
  player factions, symmetric war/peace, aggression adapters,
  leadership/archive operations, index repair, and sanitized inspection
- `PNC_FactionBehavior`: centralized derivation of legacy companion,
  ownership, order, and hostility fields from canonical faction state
- `PNC_RelationshipService`: authoritative directed relationship mutations
- `PNC_RelationshipDebug`: read-only selected-pair snapshots/formatting plus
  admin/debug-only named-event test dispatch through the real event service
- `PNC_SocialEventService`: validation, dedupe, cooldown/saturation, memory
  construction, and atomic event processing
- `PNC_SocialEventHooks`: stable-identity milestone adapters and verified
  incapacitation rescue attribution
- `PNC_SocialEncounterTracker`: non-persistent, stable-key combat aggregation
  for protection, shared survival, and conservative abandonment
- `PNC_SocialEventDebug`: opt-in read-only processed-event diagnostics

## Client
- `PNC_Client`: roster cache, character-payload cache, sync requests, context menu debug tools
- `PNC_RelationshipDebugWindow` and `PNC_RelationshipDebugModel`:
  admin/debug-only directed relationship inspection, reverse-direction
  comparison, memory/revision diagnostics, and guarded named-event triggers
- `PNC_FactionDebugWindow` and `PNC_FactionDebugModel`: admin/debug-only
  organization/member inspection and service-backed create, membership,
  player-faction, war/peace, role/rank, leader, transfer, and archive controls
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
- `PNC_Nameplates`: overhead name, HP, stamina, and AI debug overlay
- `PNC_CharacterWindow`: vanilla-like NPC character shell and tabs
