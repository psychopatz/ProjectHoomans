# ProjectHoomans Full System Audit Index

**Audit date:** 2026-08-23  
**Repository commit:** `d8cf0fd`  
**Scope:** all 92 production subsystems emitted by the architecture-audit analyzer.

This folder is the phase-one refactor ledger. It contains one system audit per analyzer subsystem, the existing deep NPC traversal audit, and the complete token-bloat inventory. The reports identify seams and risks; they do not modify production code.

## Executive baseline

| Measure | Result |
|---|---:|
| Production files scanned | 699 |
| Production LOC | 147,491 |
| Logical production subsystems | 92 |
| Production architecture findings | 148 |
| High-severity findings | 14 |
| Medium-severity findings | 127 |
| Low-severity findings | 7 |
| Files token-scanned | 676 |
| Files over 2,000 tokens | 214 |
| Production health | 82.7 |
| Architecture coverage | 70.6 |
| Evidence confidence | 56.8 |

The finding totals are the analyzer baseline; extra large-module and large-function rows are shape indicators included in the individual reports.

## Recommended refactor queue

Start with the highest-pressure seams, then work down only when characterization tests exist:

| Priority | System | Pressure | Health | Findings | Audit |
|---|---|---:|---:|---:|---|
| P1 | UI | 100 | 53.2 | 30 | [System_UI_Audit.md](System_UI_Audit.md) |
| P1 | Composition | 75.6 | 61.1 | 6 | [System_Composition_Audit.md](System_Composition_Audit.md) |
| P1 | (composition) | 54.3 | 61.1 | 4 | [System_Composition_Aggregate_Audit.md](System_Composition_Aggregate_Audit.md) |
| P1 | Conversation | 53.1 | 64.2 | 9 | [System_Conversation_Audit.md](System_Conversation_Audit.md) |
| P2 | Pathing | 36.1 | 69.1 | 15 | [System_Pathing_Audit.md](System_Pathing_Audit.md) |
| P2 | Inventory | 28.6 | 84.3 | 4 | [System_Inventory_Audit.md](System_Inventory_Audit.md) |
| P2 | Factions | 24.5 | 80.5 | 9 | [System_Factions_Audit.md](System_Factions_Audit.md) |
| P2 | Colony | 20.7 | 88.2 | 1 | [System_Colony_Audit.md](System_Colony_Audit.md) |
| P2 | Scavenge | 20.2 | 88.2 | 1 | [System_Scavenge_Audit.md](System_Scavenge_Audit.md) |
| P2 | Networking | 14.4 | 91 | 5 | [System_Networking_Audit.md](System_Networking_Audit.md) |
| P2 | Combat | 12 | 91 | 5 | [System_Combat_Audit.md](System_Combat_Audit.md) |
| P2 | Communities | 10.3 | 88.9 | 4 | [System_Communities_Audit.md](System_Communities_Audit.md) |
| P2 | Relationships | 10.1 | 88 | 4 | [System_Relationships_Audit.md](System_Relationships_Audit.md) |
| P2 | Health | 9.5 | 92.9 | 4 | [System_Health_Audit.md](System_Health_Audit.md) |
| P2 | PresenceSync | 9 | 92.8 | 4 | [System_PresenceSync_Audit.md](System_PresenceSync_Audit.md) |
| P3 | Visuals | 8.9 | 88.5 | 3 | [System_Visuals_Audit.md](System_Visuals_Audit.md) |
| P3 | Persistence | 7.3 | 90.5 | 3 | [System_Persistence_Audit.md](System_Persistence_Audit.md) |
| P3 | FactionIncident | 7.2 | 90.5 | 3 | [System_FactionIncident_Audit.md](System_FactionIncident_Audit.md) |
| P3 | Presence | 6.9 | 94.6 | 3 | [System_Presence_Audit.md](System_Presence_Audit.md) |
| P3 | Supply | 6.9 | 98 | 2 | [System_Supply_Audit.md](System_Supply_Audit.md) |

Immediate themes: UI/composition cycles, Conversation/UI cycles, Colony/Inventory coupling, the Pathing traversal state machine, persistence bridges, and high-token debug/snapshot builders.

## Complete subsystem coverage

| Priority | System | Files | LOC | Health | Coverage | Confidence | Findings | Audit |
|---|---|---:|---:|---:|---:|---:|---:|---|
| P1 | UI | 120 | 29727 | 53.2 | 72.2 | 59.3 | 30 | [System_UI_Audit.md](System_UI_Audit.md) |
| P1 | Composition | 3 | 308 | 61.1 | 73 | 59.7 | 6 | [System_Composition_Audit.md](System_Composition_Audit.md) |
| P1 | (composition) | 7 | 467 | 61.1 | 77.2 | 63.8 | 4 | [System_Composition_Aggregate_Audit.md](System_Composition_Aggregate_Audit.md) |
| P1 | Conversation | 53 | 6640 | 64.2 | 80.4 | 67.2 | 9 | [System_Conversation_Audit.md](System_Conversation_Audit.md) |
| P2 | Pathing | 18 | 8362 | 69.1 | 78.5 | 63.7 | 15 | [System_Pathing_Audit.md](System_Pathing_Audit.md) |
| P2 | Inventory | 18 | 3356 | 84.3 | 74.5 | 63.4 | 4 | [System_Inventory_Audit.md](System_Inventory_Audit.md) |
| P2 | Factions | 13 | 7275 | 80.5 | 81.5 | 65 | 9 | [System_Factions_Audit.md](System_Factions_Audit.md) |
| P2 | Colony | 12 | 1928 | 88.2 | 70.5 | 56.7 | 1 | [System_Colony_Audit.md](System_Colony_Audit.md) |
| P2 | Scavenge | 20 | 2402 | 88.2 | 71.2 | 57.3 | 1 | [System_Scavenge_Audit.md](System_Scavenge_Audit.md) |
| P2 | Networking | 39 | 5352 | 91 | 78.1 | 62.4 | 5 | [System_Networking_Audit.md](System_Networking_Audit.md) |
| P2 | Combat | 35 | 5489 | 91 | 78.5 | 62.7 | 5 | [System_Combat_Audit.md](System_Combat_Audit.md) |
| P2 | Communities | 7 | 2960 | 88.9 | 57.7 | 47.1 | 4 | [System_Communities_Audit.md](System_Communities_Audit.md) |
| P2 | Relationships | 16 | 4021 | 88 | 54.6 | 44.8 | 4 | [System_Relationships_Audit.md](System_Relationships_Audit.md) |
| P2 | Health | 5 | 2540 | 92.9 | 67 | 55.2 | 4 | [System_Health_Audit.md](System_Health_Audit.md) |
| P2 | PresenceSync | 25 | 3603 | 92.8 | 78.5 | 62.7 | 4 | [System_PresenceSync_Audit.md](System_PresenceSync_Audit.md) |
| P3 | Visuals | 6 | 3000 | 88.5 | 54.6 | 44.8 | 3 | [System_Visuals_Audit.md](System_Visuals_Audit.md) |
| P3 | Persistence | 1 | 1056 | 90.5 | 54.6 | 44.8 | 3 | [System_Persistence_Audit.md](System_Persistence_Audit.md) |
| P3 | FactionIncident | 1 | 800 | 90.5 | 54.6 | 44.8 | 3 | [System_FactionIncident_Audit.md](System_FactionIncident_Audit.md) |
| P3 | Presence | 16 | 2705 | 94.6 | 76.3 | 61.1 | 3 | [System_Presence_Audit.md](System_Presence_Audit.md) |
| P3 | Supply | 9 | 1434 | 98 | 67.9 | 55.9 | 2 | [System_Supply_Audit.md](System_Supply_Audit.md) |
| P3 | Behaviors | 21 | 2891 | 96.4 | 78.5 | 62.7 | 2 | [System_Behaviors_Audit.md](System_Behaviors_Audit.md) |
| P3 | Equipment | 3 | 2059 | 93 | 54.6 | 44.8 | 2 | [System_Equipment_Audit.md](System_Equipment_Audit.md) |
| P3 | PlayerCharacter | 2 | 1028 | 93.5 | 57.7 | 47.1 | 2 | [System_PlayerCharacter_Audit.md](System_PlayerCharacter_Audit.md) |
| P4 | Events | 1 | 29 | 100 | 49.2 | 36.9 | 0 | [System_Events_Audit.md](System_Events_Audit.md) |
| P3 | FactionBehavior | 1 | 833 | 93 | 54.6 | 44.8 | 2 | [System_FactionBehavior_Audit.md](System_FactionBehavior_Audit.md) |
| P3 | Production | 19 | 3598 | 96.7 | 79.5 | 64.6 | 2 | [System_Production_Audit.md](System_Production_Audit.md) |
| P3 | Director | 36 | 6000 | 98.3 | 81.5 | 65 | 1 | [System_Director_Audit.md](System_Director_Audit.md) |
| P3 | ColonyManagement | 1 | 667 | 95.4 | 57.7 | 47.1 | 2 | [System_ColonyManagement_Audit.md](System_ColonyManagement_Audit.md) |
| P3 | SocialEvent | 2 | 745 | 95 | 54.6 | 44.8 | 2 | [System_SocialEvent_Audit.md](System_SocialEvent_Audit.md) |
| P3 | Settlement | 18 | 3042 | 98.1 | 69.2 | 56.9 | 2 | [System_Settlement_Audit.md](System_Settlement_Audit.md) |
| P3 | Travel | 8 | 1978 | 98.2 | 78.5 | 62.7 | 1 | [System_Travel_Audit.md](System_Travel_Audit.md) |
| P4 | Knowledge | 4 | 647 | 100 | 54.6 | 41 | 0 | [System_Knowledge_Audit.md](System_Knowledge_Audit.md) |
| P3 | Perception | 2 | 1146 | 95.5 | 54.6 | 43.7 | 1 | [System_Perception_Audit.md](System_Perception_Audit.md) |
| P3 | SocialEncounterTracker | 1 | 718 | 97.2 | 54.6 | 46 | 2 | [System_SocialEncounterTracker_Audit.md](System_SocialEncounterTracker_Audit.md) |
| P3 | Base | 4 | 1266 | 97.5 | 54.6 | 44.8 | 1 | [System_Base_Audit.md](System_Base_Audit.md) |
| P3 | Zombies | 5 | 1256 | 98.2 | 78.5 | 62.7 | 1 | [System_Zombies_Audit.md](System_Zombies_Audit.md) |
| P3 | API | 1 | 785 | 97.5 | 54.6 | 44.8 | 1 | [System_API_Audit.md](System_API_Audit.md) |
| P3 | FactionToll | 1 | 496 | 97.5 | 54.6 | 44.8 | 1 | [System_FactionToll_Audit.md](System_FactionToll_Audit.md) |
| P3 | MobileGroupDirector | 1 | 481 | 97.5 | 54.6 | 44.8 | 1 | [System_MobileGroupDirector_Audit.md](System_MobileGroupDirector_Audit.md) |
| P3 | CommunityDirector | 1 | 405 | 97.5 | 54.6 | 44.8 | 1 | [System_CommunityDirector_Audit.md](System_CommunityDirector_Audit.md) |
| P3 | PersistenceCoordinator | 1 | 182 | 97.7 | 57.7 | 47.1 | 1 | [System_PersistenceCoordinator_Audit.md](System_PersistenceCoordinator_Audit.md) |
| P4 | Journals | 1 | 138 | 100 | 67 | 50.2 | 0 | [System_Journals_Audit.md](System_Journals_Audit.md) |
| P3 | Needs | 17 | 2214 | 100 | 78.3 | 58.7 | 0 | [System_Needs_Audit.md](System_Needs_Audit.md) |
| P4 | Commands | 6 | 1216 | 100 | 71.1 | 53.4 | 0 | [System_Commands_Audit.md](System_Commands_Audit.md) |
| P4 | Provision | 10 | 1025 | 100 | 78.3 | 58.7 | 0 | [System_Provision_Audit.md](System_Provision_Audit.md) |
| P4 | Tasking | 8 | 760 | 100 | 78.5 | 58.9 | 0 | [System_Tasking_Audit.md](System_Tasking_Audit.md) |
| P4 | Debug | 3 | 1187 | 100 | 78.5 | 58.9 | 0 | [System_Debug_Audit.md](System_Debug_Audit.md) |
| P4 | Archetypes | 3 | 341 | 100 | 78.5 | 58.9 | 0 | [System_Archetypes_Audit.md](System_Archetypes_Audit.md) |
| P3 | IndividualNeeds | 1 | 270 | 99.7 | 54.6 | 43.3 | 1 | [System_IndividualNeeds_Audit.md](System_IndividualNeeds_Audit.md) |
| P4 | Patches | 6 | 248 | 100 | 57.4 | 43 | 0 | [System_Patches_Audit.md](System_Patches_Audit.md) |
| P4 | Skills | 2 | 320 | 100 | 67 | 50.2 | 0 | [System_Skills_Audit.md](System_Skills_Audit.md) |
| P4 | HumanNPCSafeguards | 1 | 409 | 100 | 54.6 | 41 | 0 | [System_HumanNPCSafeguards_Audit.md](System_HumanNPCSafeguards_Audit.md) |
| P4 | Farming | 5 | 1134 | 100 | 54.6 | 41 | 0 | [System_Farming_Audit.md](System_Farming_Audit.md) |
| P4 | Conduct | 6 | 857 | 100 | 54.6 | 41 | 0 | [System_Conduct_Audit.md](System_Conduct_Audit.md) |
| P4 | Integrations | 6 | 944 | 100 | 65.9 | 49.4 | 0 | [System_Integrations_Audit.md](System_Integrations_Audit.md) |
| P4 | Registry | 2 | 758 | 100 | 57.7 | 43.3 | 0 | [System_Registry_Audit.md](System_Registry_Audit.md) |
| P4 | WorldDiscovery | 9 | 995 | 100 | 81.5 | 61.1 | 0 | [System_WorldDiscovery_Audit.md](System_WorldDiscovery_Audit.md) |
| P4 | CommunitySiteResolver | 1 | 495 | 100 | 54.6 | 41 | 0 | [System_CommunitySiteResolver_Audit.md](System_CommunitySiteResolver_Audit.md) |
| P4 | Identity | 7 | 742 | 100 | 54.6 | 41 | 0 | [System_Identity_Audit.md](System_Identity_Audit.md) |
| P4 | NPCKnowledge | 1 | 674 | 100 | 57.7 | 43.3 | 0 | [System_NPCKnowledge_Audit.md](System_NPCKnowledge_Audit.md) |
| P4 | PlayerIdentityMigration | 1 | 535 | 100 | 57.7 | 43.3 | 0 | [System_PlayerIdentityMigration_Audit.md](System_PlayerIdentityMigration_Audit.md) |
| P4 | Scheduling | 3 | 523 | 100 | 54.6 | 41 | 0 | [System_Scheduling_Audit.md](System_Scheduling_Audit.md) |
| P4 | SocialEventHooks | 1 | 459 | 100 | 54.6 | 41 | 0 | [System_SocialEventHooks_Audit.md](System_SocialEventHooks_Audit.md) |
| P4 | SocialProfile | 2 | 485 | 100 | 54.6 | 41 | 0 | [System_SocialProfile_Audit.md](System_SocialProfile_Audit.md) |
| P4 | Stamina | 2 | 484 | 100 | 78.5 | 58.9 | 0 | [System_Stamina_Audit.md](System_Stamina_Audit.md) |
| P4 | Vehicles | 1 | 626 | 100 | 54.6 | 41 | 0 | [System_Vehicles_Audit.md](System_Vehicles_Audit.md) |
| P4 | World | 3 | 657 | 100 | 54.6 | 41 | 0 | [System_World_Audit.md](System_World_Audit.md) |
| P4 | Actions | 1 | 182 | 100 | 54.6 | 41 | 0 | [System_Actions_Audit.md](System_Actions_Audit.md) |
| P4 | ArchetypeDefinitions | 7 | 364 | 100 | 49.2 | 36.9 | 0 | [System_ArchetypeDefinitions_Audit.md](System_ArchetypeDefinitions_Audit.md) |
| P4 | DebugCompanionRecruit | 1 | 353 | 100 | 57.7 | 43.3 | 0 | [System_DebugCompanionRecruit_Audit.md](System_DebugCompanionRecruit_Audit.md) |
| P4 | Diagnostics | 1 | 298 | 100 | 54.6 | 41 | 0 | [System_Diagnostics_Audit.md](System_Diagnostics_Audit.md) |
| P4 | Facilities | 2 | 419 | 100 | 54.6 | 41 | 0 | [System_Facilities_Audit.md](System_Facilities_Audit.md) |
| P4 | FactionMembership | 1 | 231 | 100 | 54.6 | 41 | 0 | [System_FactionMembership_Audit.md](System_FactionMembership_Audit.md) |
| P4 | FactionTelemetry | 1 | 162 | 100 | 54.6 | 41 | 0 | [System_FactionTelemetry_Audit.md](System_FactionTelemetry_Audit.md) |
| P4 | FirearmEffects | 1 | 345 | 100 | 54.6 | 41 | 0 | [System_FirearmEffects_Audit.md](System_FirearmEffects_Audit.md) |
| P4 | GroupNeeds | 1 | 189 | 100 | 54.6 | 41 | 0 | [System_GroupNeeds_Audit.md](System_GroupNeeds_Audit.md) |
| P4 | Map | 1 | 155 | 100 | 54.6 | 41 | 0 | [System_Map_Audit.md](System_Map_Audit.md) |
| P4 | MapCommands | 2 | 219 | 100 | 54.6 | 41 | 0 | [System_MapCommands_Audit.md](System_MapCommands_Audit.md) |
| P4 | PlayerCharacterLifecycle | 1 | 311 | 100 | 57.7 | 43.3 | 0 | [System_PlayerCharacterLifecycle_Audit.md](System_PlayerCharacterLifecycle_Audit.md) |
| P4 | PlayerKnowledge | 1 | 283 | 100 | 54.6 | 41 | 0 | [System_PlayerKnowledge_Audit.md](System_PlayerKnowledge_Audit.md) |
| P4 | Spatial | 1 | 299 | 100 | 54.6 | 41 | 0 | [System_Spatial_Audit.md](System_Spatial_Audit.md) |
| P4 | StartingCompanion | 1 | 354 | 100 | 54.6 | 41 | 0 | [System_StartingCompanion_Audit.md](System_StartingCompanion_Audit.md) |
| P4 | Stealth | 1 | 410 | 100 | 54.6 | 41 | 0 | [System_Stealth_Audit.md](System_Stealth_Audit.md) |
| P4 | Activities | 1 | 128 | 100 | 54.6 | 41 | 0 | [System_Activities_Audit.md](System_Activities_Audit.md) |
| P4 | Discovery | 2 | 49 | 100 | 54.6 | 41 | 0 | [System_Discovery_Audit.md](System_Discovery_Audit.md) |
| P4 | EquipmentDefinitions | 1 | 48 | 100 | 49.2 | 36.9 | 0 | [System_EquipmentDefinitions_Audit.md](System_EquipmentDefinitions_Audit.md) |
| P4 | FactionLeadership | 1 | 110 | 100 | 54.6 | 41 | 0 | [System_FactionLeadership_Audit.md](System_FactionLeadership_Audit.md) |
| P4 | Jobs | 1 | 31 | 100 | 54.6 | 41 | 0 | [System_Jobs_Audit.md](System_Jobs_Audit.md) |
| P4 | KnowledgeSocialEventAdapter | 1 | 49 | 100 | 54.6 | 41 | 0 | [System_KnowledgeSocialEventAdapter_Audit.md](System_KnowledgeSocialEventAdapter_Audit.md) |
| P4 | NeedsScheduler | 1 | 93 | 100 | 54.6 | 41 | 0 | [System_NeedsScheduler_Audit.md](System_NeedsScheduler_Audit.md) |
| P4 | Orders | 1 | 149 | 100 | 54.6 | 41 | 0 | [System_Orders_Audit.md](System_Orders_Audit.md) |
| P4 | Traits | 1 | 87 | 100 | 54.6 | 41 | 0 | [System_Traits_Audit.md](System_Traits_Audit.md) |

## Companion evidence

- [NPC traversal deep audit](NPC_Traversal_Refactor_Audit.md) — detailed traversal/state-machine findings and focused test evidence from the previous audit.
- [Token bloat index](Token_Bloat_Index.md) — every production Lua file over the 2,000-token threshold.
- Analyzer baseline: `.architecture-refactor/output/architecture-audit.md` (generated scan report, retained outside this folder).
- Persistent tokenizer: `tiktoken 0.14.0` with `o200k_base`.

## Coverage and limitations

The inventory is exhaustive for the 92 logical production subsystems emitted by the analyzer at this commit. Graph coverage was checked for the production Lua scope, shared animation assets, tests, and tools; the graph reported no parse-partial or skipped files in those scopes, with the cache directory deliberately excluded. Static graph and token evidence cannot prove runtime correctness, save compatibility, multiplayer authority correctness, or absence of unrecognized coupling. Each P1/P2 report should receive focused characterization tests before code movement.
