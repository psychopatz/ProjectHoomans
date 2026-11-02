# Progress — Core Semantic & Relationship Foundation

**State:** IN PROGRESS — planning complete; production implementation not started by this documentation change.

## Planning evidence

Verified on 2026-11-02:

- Core already has semantic IR/parser/registry/router/dialogue-turn machinery.
- Core capability catalog already exposes semantics, conversation, translation and actors.
- Core Actor Social already stores approval/respect/familiarity/personality/memories with server-authorized events.
- Accepted Core NPC Foundation already establishes Core actor/social/provider-switching ownership developer-side.
- Hoomans still has a richer RelationshipService/social stack and extensive Hoomans-specific semantic action/runtime behavior.
- DTCommon depends on Core; DTAbstract has no audited direct PNC gameplay dependency; DTHoomans remains the optional Hoomans bridge.
- DTHoomans conversation currently uses Hoomans semantic/conversation APIs, demonstrating why standalone DT needs its own Core-registered semantic pack.

## Repository state observed during planning

- ProjectHoomans: existing `main`, locally ahead of origin at planning time.
- DynamicTrading: existing `main` with a tracked local modification in `DTHoomans_Conversation.lua` at planning time.
- PsychopatzCore: existing `main`, clean at planning time.

These are planning observations only. Recheck before every write; never assume they remain current.

## Accepted dependency

`psychopatzCore/Docs/npc_foundation/` P0A-P9 is accepted developer foundation and must not be restarted absent a concrete regression.

`ProjectHoomans/docs/Jobs/DomainContextArchitectureRefactor/` is also recorded developer-complete and supplies the current domain/public-boundary discipline.

## Current phase

**P0 — Cross-repository convergence audit and contracts.**

### Next Chunk — P0A

Perform a fresh source-backed three-repository ownership/convergence audit before production edits.

Required output:

1. exact branch/HEAD/status/upstream for Core, DT and Hoomans;
2. inventory of Core public actor/social/semantic/conversation APIs actually available now;
3. field-by-field mapping of Core Social versus Hoomans RelationshipService shared/common and Hoomans-only state;
4. call/dependency map for DT standalone conversation versus DTHoomans/Hoomans integration;
5. list of Hoomans semantic runtime modules classified as:
   - generic mechanism candidate for Core,
   - Hoomans content/policy that must remain,
   - compatibility/adapter,
   - obsolete/duplicate;
6. migration hazards and baseline focused tests;
7. update this PROGRESS with the smallest safe P0B contract implementation chunk.

Do not move production ownership during P0A merely to make the audit cleaner.

## Parent goal status

Still IN PROGRESS until P0-P7 acceptance passes. A completed audit or Core API addition does not complete the goal.
