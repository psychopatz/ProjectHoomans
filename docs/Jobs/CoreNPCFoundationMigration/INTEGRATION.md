# Project Hoomans -> Core NPC Foundation: Adopter Contract

Status: target only; no Hoomans production code moved. Authoritative goal: https://github.com/psychopatz/psychopatzCore/tree/main/Docs/npc_foundation. Read its AGENT_RUNBOOK, ARCHITECTURE, ROADMAP, PROGRESS and Phase 0 doc before code changes. Hoomans existing semantic, dialogue, body, and NPC goals remain active and separate.

## Existing Hoomans source owners at planning baseline (main a3eb2e4d)
- shared/PNC/Core/Identity/PNC_Identity_Factory.lua and PNC_Identity_Profile.lua — resolved SurvivorFactory identity and appearance.
- shared/PNC/Core/Base/PNC_Types/PNC_Types_Record.lua — NewRecord mixes canonical and Hoomans-specific health, order and runtime data. Do NOT wholesale relocate.
- shared/PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Templates.lua and Equipment/PNC_Inventory_EquipmentGeneration.lua — seeded worn outfit, bags, weapons and supplies.
- shared/PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Persistence.lua — seed-only/baseline-delta/full codec. Preserve exact item IDs, equipped/worn references and portable state.
- server/PNC/Social/RelationshipService/ and docs/Systems/Relationships.md — persistent directed approval/respect/familiarity/personality/memories.
- client/PNC/UI/Map/PNC_MapLayerRegistry.lua, .../Layers/PNC_MapLayer_Travel.lua, PNC_MapHoverPortrait.lua and PNC_MapHoverPortraitCard.lua — world map integration and actor portrait.
- shared/PNC/Core/Presence/PNC_Presence/PNC_Presence_Materialize.lua — Hoomans live-body owner; keep physical spawn/AI/combat/needs/colonies in Hoomans.

## Required migration behavior
- Before changing persistence code, audit docs/Systems/Persistence.md: current exact-version mismatch semantics can RESET old records. Provide a new staged read-only export/import lane with known source versions and non-destructive recovery. Never overwrite unknown data.
- A Core factory resolves each actor's name/gender/voice/visuals/clothes/portable personal inventory ONCE. Hoomans becomes an archetype provider and live-body adapter; no fresh identity/loot rolls on re-materialization.
- PNC facade retains legacy caller compatibility until every adopter is audited. Hoomans-only fields may be extensions or live runtime state, but must not become unconditional Core dependencies.
- Core becomes the social record authority while Hoomans-specific social-event producers and tactical/faction consequences remain Hoomans-owned.
- Physical bodies are leases to one Core actor ID, with at-most-once allocation and explicit reconciliation of moved/changed clothes, inventory, position and health when appropriate.
- Register Hoomans map layers through one Core registry; avoid duplicate ISWorldMap monkey patches; preserve viewer discovery/knowledge restrictions on faces and location.
- Core-only Dynamic Trading must never import the Hoomans mobile-group director or force NPC AI, combat, needs, settlement/community lifecycle to initialize.

## Acceptance gates
Source-backed parity fixture, idempotent import and rollback, Hoomans NPC construction from preexisting Core actor, identical face/outfit/item ID/state/social record after abstract->live->abstract save/restart, zero duplicate bodies, SP/MP authority validation, no unrelated Hoomans regression.

Do not publish/re-publish Workshop. Live Project Zomboid user acceptance stays with the user; static/synthetic/harness tests do not substitute. Read AGENTS.md and respect its media file-watcher and protected-call rules. The initial Next Chunk (Core P0A) is an audit/fixture, not permission to migrate Hoomans production code prematurely.
