# Architecture — Semantic Test Fixture Authority

## Ownership

PsychopatzCore owns generic testing machinery:
- fixture schema/validation;
- loader and deterministic matrix expansion;
- expectation comparator/projection;
- real-worker execution coordination;
- batching/resume;
- generic fixture-root resolution.

Providers own provider-specific fixture data:

```text
ProjectHoomans provider
  PNC semantic/observatory fixtures

DT provider
  DT-specific fixtures when needed
```

Core must not contain a mirrored PNC behavioural corpus.

## Resolution flow

```text
active harness provider/workspace
→ provider manifest/descriptor
→ declared fixture roots
→ generic fixture resolver
→ schema/loader
→ LuaSemanticWorker
→ real production Lua
→ bounded observation/assertions
```

Explicit fixture paths remain an override for focused tests.

## Fixture schema

Canonical envelope:

```text
semantic.harness-test.v1
```

Schema is provider-neutral. Provider identity belongs in fixture ownership/discovery, not the schema name.

## Safety assertions

Assert semantic authority outcomes, not brittle incidental telemetry.

For mutating requests distinguish:
- recognized intent/action;
- authorization/gate outcome;
- accepted vs blocked action result;
- authoritative transport emitted or absent;
- clarification/rejection reason.

A blocked action may still appear in diagnostic `toolCalls`; that alone is not authoritative mutation.

## UI/CLI parity

CLI, GUI regression tools and batch execution must resolve fixture data through the same authority. No surface may maintain a private hard-coded PNC fixture path.

## Efficiency invariant

Declarative fixtures are the compact behavioural acceptance surface. Imperative Lua/Python tests remain for low-level contracts that are not naturally declarative.
