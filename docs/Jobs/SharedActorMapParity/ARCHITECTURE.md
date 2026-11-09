# Shared actor map and travel parity architecture

## Decision

PsychopatzCore owns one canonical survivor-world model and one actor-map
presentation engine. Project Hoomans, DTHoomans, and DTAbstract are adapters
over that model; they must not create competing actor identities, journey
registries, map renderers, or settlement geographies.

The only world-presence distinction between the two supported Dynamic Trading
providers is materialization:

| Provider profile | Nearby presence | Remote presence | Map contract |
| --- | --- | --- | --- |
| Project Hoomans + DTHoomans | Materialize the canonical actor into a Hoomans NPC when it is nearby and eligible for live simulation. | Dematerialize the body while retaining the same Core actor, group, journey, and projected position. | The Core actor marker remains continuous across the handoff. |
| Standalone DTAbstract | Never materialize a physical NPC. | Always use the Core abstract actor/group projection. | The same Core actor marker, hover, route, tracking, and discovery contract is used. |

DTHoomans may own body, inventory, and Hoomans-specific trade hooks. DTAbstract
may own abstract commercial policy. Those provider-specific hooks must not
change the canonical actor ID, group membership, settlement identity, journey
ID, route, arrival event, or map marker identity.

## Ownership boundaries

### PsychopatzCore

Core owns:

- canonical actor, group, settlement, and journey identity;
- persistence and save/reload reconciliation for the canonical world;
- journey start, advance, projection, rebase, cancel, and lifecycle events;
- actor projection transport and bounded client caches;
- one actor-map renderer for dots, icons, hover, selection, tracking, and routes;
- provider-neutral presence metadata, including abstract versus materialized.

### Project Hoomans

Project Hoomans contributes:

- Hoomans faction/community policy and learned identity presentation;
- the physical NPC controller and Project Zomboid pathing adapter;
- the DTHoomans materialization and dematerialization hooks;
- optional Hoomans debug summaries and presentation decorations.

Hoomans movement must commit or consume the Core journey contract through an
adapter. Its physical controller may own local pathfinding details, but it may
not become a second journey authority.

### DTHoomans

DTHoomans is the physical Dynamic Trading provider. Its expected flow is:

`traderID -> actorID -> Hoomans faction/group -> Core journey -> Hoomans body`

It asks Hoomans to execute commercial group movement and asks Core to preserve
the canonical actor and journey state. Nearby materialization is a presence
transition, not a new trader or a new route.

### DTAbstract

DTAbstract is the permanently abstract Dynamic Trading provider. Its expected
flow is:

`traderID -> actorID -> Core group -> Core abstract journey -> Core map projection`

It must remain functional with Project Hoomans disabled and must not require
Hoomans faction, body, pathing, or map-layer modules.

## Non-negotiable invariants

1. A trader has one canonical actor ID in both provider profiles.
2. Materializing or dematerializing never changes actor ID, group ID, journey
   ID, destination, or arrival history.
3. A physical body is optional runtime presence, not world identity.
4. A yellow Hoomans abstract-group marker is not automatically a trader.
5. A discovery signal is not proof of a physical NPC or settlement site.
6. The map renders one canonical actor marker; provider decorators only add
   commercial or Hoomans metadata.
7. Disabling either provider removes only its adapter behavior. Core remains
   loadable, and the other provider cannot call the disabled provider.

## Current migration boundary

The Core actor-map engine and provider-neutral travel primitives are already
present. Hoomans' abstract traversal bridge and DTAbstract use those primitives.
The remaining migration surface is the complete Hoomans physical travel
controller: Project Zomboid pathing, live/abstract handoff, watchdog recovery,
arrival forwarding, and the public Hoomans travel API must consume the same Core
journey ID, progress, rebase, and arrival events.
