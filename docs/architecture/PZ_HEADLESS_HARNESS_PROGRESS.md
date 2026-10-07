# Project Zomboid Headless Harness Progress

> **ARCHITECTURE:** See `PZ_HEADLESS_HARNESS.md`  
> **PURPOSE:** Living implementation ledger. Keep this concise.  
> **RULE:** Update this file after each coherent implementation chunk. Do not copy the full architecture into this file.

## Current Status

**Phase:** Phase 0 - Baseline audit / pre-implementation  
**State:** Existing foundations identified; generalized native PZ harness not yet implemented.  
**Next recommended chunk:** Complete a repository/local-runtime-backed Phase 0 audit, then define the smallest native dedicated-server proof-of-concept.

## Audited Starting Point

### Project Hoomans repository

The current Project Hoomans repository already contains a substantial testing foundation.

#### Semantic Harness

Relevant path:

```text
tools/semantic_harness/
```

Observed capabilities include:

- persistent Python <-> Lua JSON-lines worker;
- real production Project Hoomans/PsychopatzCore semantic module loading;
- scenario documents and configurable runtime seams;
- request IDs and serialized worker requests;
- startup handshake/capability reporting;
- request timeouts and crash handling;
- bounded stderr/transcript/conflict diagnostics;
- CLI, GUI, doctor, and automated tests sharing the same worker/session backend.

Important constraint:

The Semantic Harness intentionally loads a narrow semantic dependency closure rather than the complete PZ/Project Hoomans composition root. Native UI/world/Java/network edges remain mocked or omitted where required.

This must be preserved as a focused fast test lane unless a later chunk demonstrates a specific reason to change it.

#### Lua smoke-test runner

Relevant paths:

```text
tests/run_tests.py
tests/support/test.lua
tests/README.md
```

Observed capabilities include:

- isolated Lua process per smoke test;
- parallel execution;
- per-test timeout;
- bounded captured output;
- fail-fast support;
- process-group termination;
- lifecycle/conflict reporting;
- filters for focused runs;
- runtime path helpers through `T.load`, `T.path`, `T.read`, and `T.addPackagePaths`;
- newest numeric runtime discovery in the main smoke-test runner.

Do not replace this runner without a concrete deficiency.

### Runtime-version inconsistency to audit

The main smoke-test runner resolves the newest numeric Project Hoomans/PsychopatzCore runtime.

The Semantic Harness configuration/worker still contains `42.20` defaults when environment overrides are absent.

A future chunk should centralize runtime selection rather than letting multiple harness components own separate fallback logic.

Do not change this blindly during Phase 0; first enumerate all current runtime-selection paths.

### Decompiled Project Zomboid Java

The Project Hoomans repository contains a checked-in `output/source/` area with at least part of the decompiled PZ Java baseline visible in GitHub, currently including inventory-related Java sources.

Project documentation also references a fuller local decompiler output outside the repository.

Before building the Java contract scanner, verify:

- the authoritative local decompiled-source location;
- which PZ build it represents;
- whether the full source tree is available locally;
- what should be indexed versus kept out of Git;
- whether any current tooling already consumes it programmatically.

Do not assume the checked-in subset is the complete baseline.

### Standalone reusable harness repository

Repository:

```text
psychopatz/pz-headless-harness
```

At the time of this baseline audit, GitHub reports it as effectively empty.

Do not immediately migrate existing Project Hoomans harness code into it.

First define reusable boundaries, then extract/generalize incrementally.

## Current Capability Matrix

| Area | Current state | Notes |
| --- | --- | --- |
| Isolated Lua process execution | GOOD | Existing smoke runner |
| Parallel/time-bounded Lua tests | GOOD | Existing bounded runner |
| Runtime-path abstraction | GOOD | `tests/support/test.lua` |
| Real production Lua loading | GOOD/PARTIAL | Strong for selected semantic path |
| Persistent worker protocol | GOOD | Semantic Harness |
| Scenario fixtures | GOOD/PARTIAL | Semantic-oriented |
| General PZ Events emulation | PARTIAL/MISSING | Needs audit/generalization |
| Deterministic general PZ clock | MISSING/PARTIAL | Needs audit |
| General character engine model | MISSING | Not a reusable runtime yet |
| General ItemContainer/InventoryItem engine model | PARTIAL | Semantic fixtures exist; no general PZ layer |
| General world/square model | MISSING | Not yet a reusable runtime |
| Client/server loopback | PARTIAL/MISSING | Semantic/network-specific mocks exist |
| Native PZ dedicated-server runner | MISSING | High-priority proof |
| Native PZ test bridge | MISSING | High-priority proof |
| Java API manifest scanner | MISSING | Decompiled source currently acts mainly as reference |
| Versioned PZ compatibility baseline | MISSING | First-class roadmap goal |
| PNC -> PZ dependency impact mapping | MISSING | Later compatibility phase |
| Graphical client integration | NATIVE_ONLY / FUTURE | Not required for initial native server lane |

This matrix is provisional and must be verified against the working tree/local runtime before implementation.

## Phase 0 Required Audit

The next agent should verify and record:

### Existing harness inventory

- all relevant Semantic Harness modules;
- all current engine mocks/stubs;
- existing fake globals/classes/events;
- any duplicated fake PZ behavior across tests;
- existing scenario/fixture builders;
- existing native/process launch utilities.

### Version resolution

Find every location that selects or hard-codes:

- Project Hoomans runtime version;
- PsychopatzCore runtime version;
- Project Zomboid version/build;
- decompiled-source baseline.

### Native dedicated-server feasibility

Verify locally rather than assuming:

- installed PZ dedicated-server path;
- launch script/binary;
- JVM/native-library requirements;
- current build/version detection;
- safe disposable absolute cachedir behavior;
- server config generation;
- mod loading from local development repositories;
- deterministic server-ready signal;
- clean shutdown method;
- log locations;
- whether the server can execute a tiny development-only bridge mod unattended.

### Current test baseline

Record:

- number of discovered Lua smoke tests;
- current pass/fail baseline;
- known pre-existing failures;
- Semantic Harness test baseline;
- selected runtime versions.

This baseline is necessary so future PZ updates can distinguish existing failures from new regressions.

### Decompiled Java baseline

Verify:

- authoritative full local source tree;
- current PZ build;
- source fingerprint strategy;
- useful annotations/contracts to index;
- whether current code consumes any of it automatically.

## Native Proof-of-Concept Target

The first native implementation milestone should be deliberately small.

Target flow:

```text
agent / CLI
   |
   v
native launcher
   |
   v
actual PZ dedicated server
   |
   +-- PsychopatzCore
   +-- ProjectHoomans
   +-- PZHarnessBridge
   |
   v
one real Kahlua test
   |
   v
one real PZ Java-backed assertion
   |
   v
structured PASS/FAIL
   |
   v
clean server shutdown
```

A good initial native assertion should prove a real Java-backed API, for example a basic `InventoryItemFactory` / `ItemContainer` round trip, without requiring graphics, native pathfinding, or complex world setup.

Do not broaden scope until this works reliably.

## Architecture Guardrails for Current Work

- Do not build one giant `NativeRunner.py`.
- Do not build one giant `PZHarness.lua`.
- Do not build one giant Java scanner.
- Do not introduce generic `Utils.lua` / `Common.lua` dumping grounds.
- Do not reproduce Project Hoomans policy in fixtures.
- Do not silently no-op unknown engine APIs.
- Do not migrate the whole Semantic Harness to the standalone repository in one chunk.
- Do not claim native server tests validate graphical client behavior.
- Do not automatically accept new PZ compatibility baselines.

## Update Format After Each Chunk

Append or replace the sections below rather than growing an endless chronological diary.

### Completed

- Phase 0 architecture/source-of-truth docs added.

### Current Chunk

- Complete the verified Phase 0 repository/local-runtime audit.

### Known Blockers

- Native dedicated-server installation/launch path has not yet been verified in this ledger.
- Full authoritative decompiled Java baseline location/build has not yet been verified in this ledger.
- Current full Lua smoke-test pass/fail baseline has not yet been recorded here.

### Newly Added Contracts

None yet.

### Native-Only Limitations

Currently expected:

- rendered client UI;
- actual sprite/AnimationPlayer visuals;
- FMOD/audio output;
- rendering/physics details;
- native client-only visual behavior.

These remain provisional until native-server/client feasibility is audited.

### Tests Last Run

Not recorded by this documentation-only change.

### Recommended Next Chunk

Perform the Phase 0 audit against the current working tree and local PZ installation. Then implement only the smallest native dedicated-server proof-of-concept needed to boot the real engine, run one Java-backed Lua assertion through `PZHarnessBridge`, emit a structured result, and shut down cleanly.
