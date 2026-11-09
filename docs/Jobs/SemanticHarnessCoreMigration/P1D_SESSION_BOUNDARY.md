# P1-D ScenarioSession boundary

`ScenarioSession` is not safe to move as one family. The current Hoomans
implementation combines a reusable source/working-world lifecycle with
provider-owned rehydration and payload policy.

## Core-neutral portion

Core can own a bounded `SessionEnvelope` with these namespaced sections:

```text
sessionEnvelope
  schemaVersion
  source: { data, metadata, provenance }
  working: { effective, baseline, revision, resetCount }
  providerPayloads: { <providerID>: <opaque bounded payload> }
  extensions: { <providerID>: <opaque bounded projection> }
```

The envelope owns copying, immutable-source labeling, working revision/reset
accounting, and bounded projection. It must not interpret PNC, merchant, or
Project Zomboid gameplay records.

## Hoomans adapter portion

Keep these in Hoomans behind the envelope adapter:

- `ScenarioSession_Lifecycle.lua` production rehydration and actor fixture setup;
- `ScenarioSession_Payloads.lua` PNC cognition, relationship, quest, and
  conversation presentation fields;
- `ScenarioSession_Projections.lua` relationship proposal and PNC presentation
  projections;
- `ScenarioSession_Defaults.lua` synthetic Hoomans scenario defaults;
- `ProductionRehydration*.lua`, `SemanticAdapters*.lua`, and their provider
  payloads.

## Compatibility rule

The first implementation adds a neutral `sessionEnvelope` projection while
retaining existing Hoomans response fields. Existing Hoomans tests remain
contract tests for those fields; Core tests cover only the envelope. Removal of
legacy response fields requires a separate caller-zero and adopter matrix gate.

## P1-D acceptance

- Exact source/caller boundary is recorded.
- Core owns no Hoomans production policy.
- The first safe implementation is a standalone Core envelope plus a Hoomans
  compatibility projection, not a wholesale ScenarioSession move.
