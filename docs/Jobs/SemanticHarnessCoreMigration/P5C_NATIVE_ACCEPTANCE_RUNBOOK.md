# P5-C — native SP/MP acceptance runbook

This is the remaining user-owned gate for the Semantic Harness Core Migration.
It is an executable checklist, not evidence that native Project Zomboid behavior
has already passed. Do not mark P5-C accepted until the observations and logs
below are recorded for every applicable matrix row.

## Authority and scope

- PsychopatzCore is the provider-neutral owner of actor identity, persistence,
  group/community state, traversal contracts, discovery/projection state,
  semantic execution, conversation landing-page contracts, and worker loading.
- Project Hoomans and DTHoomans are physical adopters. A nearby actor may
  materialize into a real survivor, use the shared identity/conversation path,
  and dematerialize when it leaves the materialization range.
- DTAbstract is an abstract adopter. It must retain actor/group/trader state,
  route traversal, discovery, conversation, and trade without creating a
  physical survivor.
- DynamicTrading owns trading policy/data through DTCommon. It must not require
  a second generic actor, semantic, traversal, or conversation engine.

## Before testing

1. Verify the committed checkpoint in the job `HANDOFF.md` and confirm that the
   three repositories are on the recorded `main` commits.
2. Capture the active mod list and a fresh `console.txt` before each row. Use a
   disposable copy of an existing save when testing restart behavior.
3. Keep the in-game debug/map diagnostics available, but record whether each
   tool is enabled. Debug overlays are evidence aids, not a substitute for
   normal discovery or conversation behavior.
4. For each actor under test, record its stable Core actor ID, provider ID,
   faction/owner, group/community, map location, and materialization state.
5. Treat any `Unknown` faction/owner/identity after reload, duplicate physical
   body, stale provider import, missing callback, or `core_actor_not_found`
   error as a failure until repaired and retested.

## Native matrix

### N1 — Core + DTAbstract, without Hoomans

1. Start a save with PsychopatzCore, DTCommon, and DTAbstract only.
2. Confirm abstract trader/group actors and their discovery signals exist.
3. Trigger or observe a route between two map points and record the actor/group
   ID and route state before and after traversal.
4. Open the shared conversation landing page for an abstract trader and perform
   a trade or other supported semantic interaction.
5. Confirm that no Project Hoomans/DTHoomans physical survivor is created.
6. Save, quit, reload, and repeat identity, discovery, traversal, conversation,
   and trade checks.

Pass requires stable Core identity and route state, usable abstract interaction,
and zero physical NPC creation or Hoomans dependency.

### N2 — Core + Project Hoomans, without DynamicTrading

1. Start a fresh Hoomans save with DynamicTrading disabled.
2. Locate a nearby Hoomans survivor and record its Core actor ID, ownership,
   faction, group/community, and initial abstract/physical state.
3. Move into range and confirm the actor materializes as one selectable survivor
   with the same identity; open the shared conversation landing page.
4. Move out of range and confirm the actor dematerializes without losing its
   Core record, route/group state, or discovery state.
5. Save, quit, reload, and repeat the owner, faction, identity, and conversation
   checks. In particular, verify the actor does not become `Unknown`.

Pass requires one physical representation while nearby, no duplicate actor, and
stable Core-owned identity/affiliation across materialization and restart.

### N3 — Core + Project Hoomans + DTCommon + DTHoomans

1. Start a combined save and locate an abstract trader signal before entering
   materialization range.
2. Record the trader's Core actor ID, DT provider identity, group/community,
   route, stock/budget state, and abstract state.
3. Enter range and confirm exactly one DTHoomans survivor materializes with the
   same actor/trader identity. Do not accept a new provider-specific actor ID as
   a successful handoff.
4. Open the same conversation landing page used by Hoomans actors and complete
   a supported trade/semantic interaction. Record the response and resulting
   stock/budget changes.
5. Move between map points and verify the route is advanced by the shared Core
   traversal state. Leave range and confirm dematerialization preserves the
   actor, route, and trade state.
6. Save, quit, reload, and verify the same ID, faction/owner, route, and trade
   state. Repeat the interaction after reload.

Pass requires Core identity/traversal, DTCommon trading authority, and Hoomans
physical projection to cooperate without a split actor or split conversation
engine.

### N4 — native multiplayer authority and reconnect

1. Start a server with Core plus the selected adopter combination and connect
   two clients.
2. Observe the same abstract actor/trader from both clients. For DTHoomans,
   bring one client into materialization range and confirm the server owns one
   physical representation rather than creating one per client.
3. Have one client perform conversation/trade and verify the other client sees
   the same identity, route, and resulting state.
4. Move the actor between map points, leave/re-enter materialization range, and
   reconnect a client. Check that no duplicate body, group, marker, or provider
   record appears.
5. Save/restart the server and repeat the identity, faction/owner, traversal,
   materialization, conversation, and trade checks.

Pass requires server-authoritative Core state, consistent projections, and no
client-local duplicate or stale actor records.

## Independent toggle and restart sweep

Repeat the applicable portions of N1–N3 with these configurations:

| Configuration | Expected result |
| --- | --- |
| Core only | Loads with no adopter import or missing-module error. |
| Core + Hoomans | Hoomans physical behavior works with DynamicTrading absent. |
| Core + DTAbstract | Abstract trading/traversal works with Hoomans absent. |
| Core + Hoomans + DTHoomans | Nearby traders materialize through the shared path. |
| Disable Hoomans after a DTAbstract run | No stale Hoomans import or nil callback. |
| Disable DynamicTrading after a Hoomans run | Hoomans identity/conversation remains loadable. |

For every restart, compare the recorded stable IDs and state. A successful load
alone is insufficient if ownership, faction, route, discovery, or trade state is
lost.

## Evidence and disposition

For each row, attach:

- active mod list and save/configuration name;
- `console.txt` excerpt covering worker/provider loading, semantic execution,
  conversation, traversal, and reload;
- screenshots or a short recording showing the relevant map/debug state and
  physical/abstract distinction;
- before/after table of stable actor ID, provider, faction/owner, group, route,
  materialization state, and trade result;
- PASS, FAIL, or BLOCKED with the exact first failing observation.

If a row fails, preserve the save and logs, disable only the suspected adopter
for isolation, and return the failure to the migration job. Do not delete the
save or reset discovery before the failure evidence is captured.

## Current status

Developer-side Core, Hoomans, and DynamicTrading gates are complete through P5-B.
P5-C remains **UNVERIFIED / user-owned** until native SP/MP evidence is supplied
or the user explicitly authorizes native operation.
