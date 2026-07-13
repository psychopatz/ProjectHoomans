# System Map

## Shared Core
- `PNC_Core`: environment helpers, time, players, logging, and the canonical managed-NPC-body predicate
- `PNC_Archetypes`: self-registering archetype registry plus preload-safe archetype bundle application
- `PNC_ArchetypeLoader`: imports registered archetype modules, applies pending bundles, and logs bootstrap health
- `PNC_Identity_Factory`: `SurvivorFactory`-first identity resolution
- `PNC_Identity_Profile`: persisted identity and appearance resolution
- `PNC_Inventory`: compact player-like inventory tree with template-plus-delta persistence
- `PNC_Persistence`: versioned canonical save schema, migration, and runtime rehydrate
- `PNC_Registry`: authoritative NPC records and live body lookup
- `PNC_SpatialIndex`: indexed nearby player, NPC, and zombie queries
- `PNC_Stealth`: follow-stealth state and stealth-based combat suppression
- `PNC_Perception`: target selection, zombie lookup, and nearby threat counting
- `PNC_Stamina`: stamina authority, recovery, attack costs, and visibility timers
- `PNC_Visuals`: owns appearance application and reusable body-visual operations such as clothing visuals, attached-item cleanup, and model refresh
- `PNC_Animation`: single animation state writer
- `PNC_Health`: custom HP, incapacitation, death ownership
- `PNC_Combat`: combat entry
- `PNC_Combat_Melee`: melee attack start rules
- `PNC_Combat_Ranged`: ranged attack start rules
- `PNC_Combat_AttackActions`: delayed hit windows and attack pumping
- `PNC_Combat_Tactics`: conservative kiting and repositioning
- `PNC_Combat_Unarmed`: shove and stomp helpers
- `PNC_PathService`: live stepping and abstract travel
- `PNC_OrderSystem`: order normalization and ownership
- `PNC_JobSystem`: selects active job from order and state
- `PNC_BehaviorSystem`: thin coordinator that executes the active job
- `PNC_Behavior_MoveIntent`: single behavior-side move intent writer consumed by pathing
- `PNC_Behavior_Common`: shared owner, movement, and combat-debug helpers
- `PNC_Behavior_Targeting`: target refresh and facing helpers
- `PNC_Behavior_Combat`: combat engage sequencing
- `PNC_Behavior_Companion`: follow, guard, and patrol job handlers
- `PNC_Behavior_Hostile`: roam, hunt, and direct engage job handlers
- `PNC_Behavior_Incapacitated`: crawl and downed shove handling
- `PNC_Presence`: live and abstract transitions, body cleanup
- `PNC_Scheduler`: cadence rules
- `PNC_Network`: roster snapshots, live presence snapshots, and on-demand character payloads
- `PNC_ZombieAggro`: zombie-to-NPC aggro bridge and bite flow
- `PNC_API`: external entry points

## Layout Rule
- reusable archetype definitions, translation files, clothing XML, and other version-agnostic content belong in `common/media/...`
- `42.16/media/...` should hold only build-specific runtime Lua and assets that genuinely differ by Project Zomboid version
- common archetype definition files must store declarative bundles only; runtime registry ownership stays in the versioned core loader/registry

## Ownership and Load-Order Rules
- use `PNC.Core.IsManagedNPCBody` instead of defining subsystem-local checks for the `PNC_NPC` body marker
- equipment describes and applies loadout state, but reusable model and clothing-visual mutations belong to `PNC_Visuals`
- modules required before one of their collaborators must resolve that collaborator from `PNC` at call time; do not capture a not-yet-loaded table in a file-local variable
- multi-job behavior entry points dispatch to one handler per job so follow, guard, and patrol control flow remains independently testable

## Server
- `PNC_Server`: authority tick, full sync, debug commands

## Client
- `PNC_Client`: roster cache, character-payload cache, sync requests, context menu debug tools
- `PNC_ClientPresenceSync`: multiplayer live-body reconciliation for nearby embodied NPCs
- `PNC_ContextHub`: central reusable NPC selection and right-click hub
- `PNC_NPCSelection`: cursor-space NPC selection helper used by context providers
- `PNC_Nameplates`: overhead name, HP, stamina, and AI debug overlay
- `PNC_CharacterWindow`: vanilla-like NPC character shell and tabs
