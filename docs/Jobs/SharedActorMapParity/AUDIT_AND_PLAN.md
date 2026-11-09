# Shared actor map parity — audit and implementation plan

Scope: Project Hoomans and DTAbstract actor hover, abstract journey motion and debug routes.

The corrected knowledge contract and follow-up fixes are recorded in [KnowledgeDialogueHover](../KnowledgeDialogueHover/AUDIT_AND_FIX_PLAN.md): debug visibility never grants unknown actor hover. DTHoomans remains the commercial-to-Hoomans physical NPC adapter; it is not DTAbstract.

## Evidence

- Core ActorMap owns canonical actor markers, selection, tracking, routes and Hover. The earlier cache changes preserve that renderer but only redraw positions received in snapshots.
- Core Hover must refuse unknown identities. Visible debug dots are not evidence of learned identity; known non-colonists use the player knowledge adapter. Stale projection flags and pending presentation rows must not override an arrived name fact.
- Hoomans' hover adapter interprets every portrait as legacy PNC appearance data, even when Core supplies its canonical face/gender portrait schema.
- The PNC abstract-group overlay projects movement independently. Core already owns GroupJourney.Normalize/ProjectPosition, but its client actor-list presentation does not use that math between received projections.
- DynamicTrading's discovery debug geography independently decides debug visibility. Generic actor and debug presentation must not require parallel provider-specific implementations.

## Ownership

PsychopatzCore owns permission-checked debug presentation, actor hover lifecycle, compact journey projection, actor-map routes and cached rendering. Hoomans supplies learned identity, legacy portrait conversion and its existing raw-overlay menu adapter. DTAbstract supplies abstract actor/world state and commercial decoration; it reuses Core presentation. DTHoomans continues its existing provider handoff and physical NPC responsibilities.

## Plan

1. Add an explicit, authorization-checked Core debug-presentation state, without mutating discovery/learned facts or save state.
2. Connect the Hoomans raw-overlay action and DTAbstract debug geography to that public contract; keep actor cards gated by learned identity in every mode.
3. Prefer Core portrait conversion for canonical portraits; retain legacy conversion only for legacy records.
4. Project abstract group-position actors using existing Core journey math at presentation refresh cadence, preserving canonical inputs and provider-owned live positions. Carry wait state/arrival radius in the bounded projection so projection does not skip stops.
5. Show shared routes during debug inspection; refresh a hovered card when its actor projection changes instead of keeping the first actor-ID-only binding indefinitely.
6. Add provider-parity, authorization, non-mutation, movement/wait/live-body and cache regressions. Run related Core/DT tests, Hoomans full suite and Kahlua checks.

Native confirmation: after restart, toggle raw debug on/off, verify known non-colonist Hoomans and DTAbstract actors have cards and unknown actors do not, observe movement along routes and waits, then confirm normal-play identity restrictions and smooth map rendering. Native verification remains user-owned; static/mocked evidence is not an FPS measurement.

## Implementation completed

- Added the shared Core Map Tools action **Show survivor debug inspection**. Core checks current debug authorization on enable and on use. Its three menu/help strings have matching EN/TL entries in the existing Debug catalogs.
- Hoomans' raw-overlay controller now delegates to Core. Its old menu entry is hidden when the shared action exists, and its three raw/discovery layer consumers read the shared state. DTAbstract reads that same state; its local `showAll` hint cannot bypass the shared contract.
- Core hover requires learned identity in both normal and debug modes; learned facts and discovery are not written. New projection objects refresh the hovered target, while the portrait panel's appearance/equipment key avoids unnecessary model rebinding. Canonical face/gender portraits use Core conversion; legacy PNC portraits retain their adapter.
- Shared actor-map routes render for debug inspection as well as selection/tracking. Existing group/site diagnostic overlays remain domain-specific summaries, not a second canonical actor renderer.
- Found and repaired an additional transport defect: `ActorProjection.ValidateEntry` discarded `positionSource`. It now preserves the field, plus journey wait duration and arrival radius.
- `Client.ListActors(false)` projects group-position abstract actors using existing GroupJourney normalization/projection math before overlap spreading. Raw entries stay untouched. Per-member server offsets are preserved by applying movement relative to the snapshot's world-hour timestamp. Materialized/live/provider-controlled positions are not extrapolated. Backward clocks, incomplete journeys and route-distance mismatches retain the received position rather than inventing movement.
- Marker/decorator and directory caches remain in place; movement refresh uses the existing 500 ms presentation cadence. This does not simulate or spawn NPCs in DTAbstract and does not modify provider leases or Hoomans follow AI.

## Verification

- Hoomans: full Lua suite 1008/1008 passed.
- Core: related map/world/portrait/projection tests 25/25 passed.
- DynamicTrading: map/presentation tests 5/5 passed.
- Kahlua: 13 affected/current map-related runtime files checked with zero errors.
- EN/TL: three new shared Debug keys, valid JSON and matching keys.
- Added parity tests for ProjectHoomans, DTAbstract and DTHoomans journey projection; wait/pause/live-body guards; raw-state non-mutation; the real shared client list; debug authorization and permission revocation; unknown-hover rejection in both modes; refreshed portrait targets; canonical female portrait conversion; shared debug routes and DTAbstract geography. Earlier repeated-frame cache assertions still pass.

Graph coverage checks reported no recorded parser gaps for inspected paths. Several files were changed or absent from the older index; those were inspected directly. This remains a bounded source-and-harness audit, not proof of native UI behavior or measured FPS.

## Remaining native acceptance

Restart with the updated local Core, Hoomans and DynamicTrading files. In Map Tools enable **Show survivor debug inspection**. Verify non-colonist portraits and routes, movement of a known travelling DTAbstract/Hoomans group, pause/wait behavior, and live body marker accuracy. Verify unknown identities remain non-hoverable with inspection both enabled and disabled. Test DTAbstract with no Hoomans loaded, and MP admin/non-admin permission changes. Compare map performance with the previous smooth version. Existing standalone group/site summaries do not guarantee a portrait for a marker that represents a whole entity rather than an individual actor.

No Workshop upload, save mutation, discovery grant, native gameplay control, or profiler-setting change was performed. All unrelated in-progress edits were preserved.
