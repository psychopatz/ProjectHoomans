# P4-D — canonical actor and SurvivorWorld adoption

## Problem

Native diagnostics showed Hoomans records whose `coreActorID` could not be
resolved by Core, followed by Core group commits that referenced Hoomans
factions missing from the canonical SurvivorWorld registry. These are partial
migration failures, not a reason for DTAbstract or DTHoomans to maintain a
second harness.

## Contract

- Core provides the provider-neutral idempotent actor ensure operation.
- Hoomans owns the adapter that maps its stable record and affiliation into
  Core, and remains responsible for physical materialization.
- Hoomans repairs only missing Core SurvivorWorld records. It never overwrites
  an already-canonical Core record during repair.
- Repair order is factions, locations, communities, then groups so Core's
  dependency checks are satisfied.
- DTAbstract and DTHoomans continue to consume the same Core actor/world
  contracts; no DT-specific or Hoomans import is added to Core.

## Evidence and gate

Developer-side smokes pass for Core actor ensure, Hoomans actor adoption,
SurvivorWorld repair, social mutation, and semantic diagnostics. A fresh native
SP/MP run remains the P4-C acceptance gate for restart persistence, nearby
materialization, abstract traversal, and conversation/trade behavior.
