# P1-F Core envelope as the ScenarioSession source

## Audit result

Before P1-F, Hoomans built three parallel projections from the same runtime
state: the Core `sessionEnvelope`, the legacy
`semantic.imported_source_snapshot.v1` response, and the legacy
`semantic.harness_working_world.v1` response. This duplicated source metadata,
provider payload, effective scenario, baseline, source identity, and revision
selection in the adopter.

## Change

`ScenarioSession_Payloads.lua` now creates one Core envelope per response and
passes it to both compatibility projections. The compatibility projections
read source and working values from that envelope while retaining their legacy
schemas, patch list, provenance-overrides shape, and transport compaction
behavior.

This is an internal ownership change, not a wire-format removal. Existing
Hoomans callers still receive `sourceSnapshot` and `workingWorld`; Core owns
the canonical source/working selection underneath them.

## Deliberately retained in Hoomans

- `patchProjection` and its `HARNESS_MUTATION` compatibility records;
- production rehydration and actor fixture setup;
- relationship, knowledge, conversation, and PNC presentation projections;
- synthetic defaults and provider-specific response fields.

## Gate

The focused contract asserts that the compatibility source/effective/source-ID/
revision fields agree with the Core envelope. Core and Hoomans worker smoke
tests remain green. Native Project Zomboid runtime behavior is not claimed by
this developer-side gate.
