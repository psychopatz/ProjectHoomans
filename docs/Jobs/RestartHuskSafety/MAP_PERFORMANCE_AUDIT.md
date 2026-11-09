# Map performance follow-up — 2026-11-07

## Findings

The previous body-binding repair addressed recycled IsoZombie identity/cleanup feedback. It did not address repeated presentation work while the map is open. This audit found three map-specific costs:

1. PsychopatzCore `PsychopatzSurvivorWorldActorMap.BuildMarkers` reused projected entries for 500 ms, but still rebuilt decorator order, invoked every adopter decorator for every actor, allocated styles/markers, and sorted the markers on every render. At 60 FPS, two unchanged projection refreshes per second could trigger 60 complete marker builds.
2. `PsychopatzSurvivorWorldClient.GetTracked` called `ListActors(true)` before checking whether an actor was tracked. `ActorProjection.Store:List` allocates and sorts the population list. `BuildMarkers` called this every frame, including when nothing was tracked.
3. DynamicTrading `DTAbstract_WorldMap.GetDiscoveryMarkers` rebuilt and sorted discovery markers every render. When debug geography was visible it also called `SettlementDirectory.List`, which clones entries and invokes directory providers. This cost was uncached even though discovery refreshes only every five seconds.

These are demonstrated unnecessary render-path costs. Their share of the user's total FPS loss has not been measured in a controlled native map-open/map-closed comparison. In particular, the available profiler report does not time individual map overlays. Do not present these fixes as proof that every source of the slowdown is resolved.

## Implemented corrections

- Cache decorated world-space actor markers for the existing 500 ms projection cadence. Invalidate on entry refresh, selection/tracking change, decorator registration/removal, or clock rollback. Screen-coordinate conversion, drawing and hover hit tests remain per-frame, so panning and zooming retain responsiveness.
- Resolve tracked actors from the projection store's existing ID index. No list/sort for either tracked or untracked lookup; preserve SurvivorWorld source filtering.
- Cache DynamicTrading discovery/debug markers for 500 ms. Invalidate on snapshot replacement/revision, debug visibility changes, expiry or clock rollback. The TTL bounds freshness for in-place directory changes that expose no revision API.
- Preserve the existing hover-owner edits and all unrelated work. No population, spawn, follow, or combat rules changed in this follow-up.

## Screenshot logs

`SUPPRESSION_CHANGED ... NO_DEFICIT` means the population director found no population shortage for that sector/type. `STARTUP_DRY_RECONCILIATION` records the diagnostic bootstrap pass. `BOOTSTRAP_DRY_RECONCILIATION ... processed=8 nextInHours=0.25` reports eight sector/type checks and the scheduled follow-up interval in game-world hours. Suppression messages are emitted only when their stored reason changes. The initial inspected log contained two bootstrap reports across loaded sessions, not a per-frame loop. These lines are normal diagnostics and do not demonstrate a map-render defect.

The relevant `traversal_complete` entries contain `crossed=true finished=false timedOut=true`: the NPC crossed the obstacle, but completion used a timeout fallback because the expected animation completion signal was absent. Nearby `fence_transfer_signal_missing` warnings likewise indicate a recovery path. These are meaningful traversal diagnostics, not evidence of flawless animation; they do not establish the map slowdown's cause. No traversal fix was attempted as part of this render-cost repair.

## Evidence and validation

Read-only profiler capture was applied to runtime `1793979183549-257798904` during the initial investigation (2026-11-06 23:41 +08). Its snapshot reported approximately 28 FPS, 32 ms frame CPU, 31 ms GPU, and 30.6 Server.Update calls/second. BodyCleanup averaged approximately 0.36 ms/call in that report. Historic peaks and inclusive timer totals cannot identify the current map cost. The user's map-open/hover state was not confirmed, so this is not a controlled before/after measurement.

Regression assertions:

- 120 unchanged actor-marker builds cause zero additional decorator calls after warm-up.
- 120 tracked lookups cause zero population list calls; untracked lookup also avoids listing.
- 120 unchanged discovery-marker builds cause zero additional settlement-directory copies after warm-up.
- Expiry, selection changes, decorator removal, snapshot revisions and backward clock changes refresh the relevant cache.

Validation passed: 8/8 Core map/client smoke tests; 5/5 DynamicTrading map/presentation smoke tests; 1008/1008 Hoomans Lua tests; zero Kahlua errors in all three changed runtime files. Graph coverage was checked for modified paths and supporting implementations; changed/older-index files were read directly. Graph metadata is not a runtime performance measurement.

## Native confirmation remaining

Fully restart PZ to replace cached modules/callbacks. At the same stationary location and zoom, compare map closed, map open without a hovered marker, and map open with an NPC portrait hovered. Compare equivalent durations after startup has settled. Check FPS/frame time and periodic spikes, not just historical profiler maxima. If only portrait hover remains slow, investigate UI3DModel rendering separately rather than attributing it to these list/sort costs. No profiler settings were changed, no arbitrary live Lua was injected, and no Workshop publication was performed.
