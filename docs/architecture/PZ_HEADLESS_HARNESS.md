# Project Zomboid Headless Harness

> **STATUS:** Architecture source of truth  
> **PROGRESS:** See `PZ_HEADLESS_HARNESS_PROGRESS.md`  
> **RULE:** Do not turn this document into an implementation-completion ledger. Keep implementation history and current chunk status in the progress document.

## Purpose

Build an agent-friendly Project Zomboid testing system that allows Codex/LLM agents to verify Project Hoomans and future Psychopatz mods without requiring a human to manually launch Project Zomboid.

The system has two complementary test lanes:

```text
                 CODING AGENT
                       |
          +------------+------------+
          |                         |
          v                         v
   FAST LUA HARNESS          NATIVE PZ RUNNER
          |                         |
   deterministic seams       actual dedicated server
   selected PZ contracts     actual PZ JVM
   real production Lua       actual Kahlua
   fast iteration            actual Java engine
          |                  actual Project Hoomans
          +------------+------------+
                       |
                       v
                 UNIFIED REPORT
```

The fast lane answers:

> Does our Lua/domain logic behave correctly?

The native lane answers:

> Does this actually work inside the current Project Zomboid engine?

For server/shared engine integration, the native dedicated-server lane is authoritative.

## Core Principles

1. **Run real production mod Lua.** The harness emulates Project Zomboid underneath Project Hoomans; it must not reimplement Project Hoomans gameplay rules.
2. **Native PZ behavior is authoritative.** If the simulated lane disagrees with the real dedicated-server runtime, the simulation must be fixed, downgraded, or removed.
3. **PZ update detection is first-class.** The system must make engine-version drift visible and localize likely breakage to affected PZ contracts, PNC modules, and tests.
4. **No monoliths.** Split by subsystem ownership and responsibility. Do not create giant runtime, native-runner, Java-scanner, compatibility, or utility files.
5. **No false confidence.** Unsupported or native-only behavior must be classified explicitly. Unknown engine calls must never silently return `nil`.
6. **Preserve existing working infrastructure.** Reuse the current Semantic Harness, bounded Lua test runner, JSONL protocol, runtime loaders, and diagnostics where appropriate.
7. **Incremental migration.** Establish contracts and vertical slices before moving generic code into the standalone harness repository.

## Repository Ownership

Reusable Project Zomboid testing mechanisms should eventually live in:

```text
psychopatz/pz-headless-harness
```

Project-Hoomans-specific policy, scenarios, fixtures, expectations, and integration tests stay in:

```text
psychopatz/ProjectHoomans
```

Generic examples:

- runtime lifecycle
- deterministic clock
- PZ event runtime
- engine contract registry
- Java API manifest scanner
- world/inventory/character primitives
- native dedicated-server launcher
- client/server loopback transport
- scenario framework
- compatibility diffing
- reporting

Project-Hoomans-specific examples:

- NPC fixtures
- faction scenarios
- facility scenarios
- Project Hoomans composition adapters
- expected PNC behavior
- PNC integration tests

Do not move working code merely to make folder ownership look cleaner. Establish the reusable contract first.

## Architecture: Avoid Monolithic Files

Do not create catch-all files such as:

```text
PZHarness.lua
RuntimeEverything.lua
MockProjectZomboid.lua
NativeRunner.py
JavaScanner.py
Utils.lua
Common.lua
```

Prefer strong subsystem boundaries with cohesive files inside them.

A useful responsibility map is:

```text
pz-headless-harness/
|
+-- runtime/
+-- events/
+-- time/
+-- globals/
+-- contracts/
+-- java_contracts/
+-- compatibility/
+-- simulated/
+-- native/
+-- characters/
+-- inventory/
+-- world/
+-- moddata/
+-- network/
+-- pathing/
+-- scenarios/
+-- loader/
+-- protocol/
+-- reporting/
+-- cli/
+-- tests/
```

This is a responsibility map, not an instruction to create every directory immediately.

### File cohesion guidance

Avoid both extremes.

Bad:

```text
Runtime.lua   # 6,000 lines and owns everything
```

Also bad:

```text
GetX.lua
GetY.lua
SetX.lua
SetY.lua
AddItem.lua
RemoveItem.lua
```

Prefer meaningful modules such as:

```text
inventory/
    Inventory.lua
    InventoryItem.lua
    ItemContainer.lua
    ItemFactory.lua
    InventoryDiagnostics.lua
```

A file around 100-400 lines is generally comfortable. A file around 500-700 lines should trigger a cohesion review. A file approaching 1,000+ lines should normally be treated as an architecture warning unless there is a documented reason.

Split by responsibility, not by arbitrary line count.

### Public entry points

Each substantial subsystem should expose a small obvious public contract.

Example:

```text
inventory/
+-- Inventory.lua
+-- InventoryItem.lua
+-- ItemContainer.lua
+-- ItemFactory.lua
+-- Internal/
```

External code should start from the subsystem contract rather than arbitrary internals.

Anything under `Internal/` should not be imported cross-subsystem without a documented exception.

### No god-object runtime

The runtime/session may hold references to subsystem services:

```lua
Runtime = {
    Events = events,
    Time = time,
    World = world,
    Network = network,
}
```

It must not itself own all subsystem state and implement all behavior.

Avoid:

```lua
Runtime = {
    eventListeners = {},
    items = {},
    characters = {},
    squares = {},
    packets = {},
    paths = {},
    animations = {},
}
```

with all behavior implemented in Runtime.

### Dependency direction

The composition root may know all major subsystems. Subsystems should not all import the composition root back.

Prefer explicit dependencies and narrow contracts. Stop and repair circular dependencies instead of hiding them through globals.

## Existing Project Hoomans Foundation

The current Project Hoomans repository already contains substantial useful infrastructure and must not be treated as greenfield.

Important existing areas include:

```text
tools/semantic_harness/
tools/semantic_harness/lua/
tools/semantic_harness/lua/worker/
tests/
tests/support/test.lua
tests/run_tests.py
output/source/
```

The existing Semantic Harness already provides a persistent Python <-> Lua JSON-lines worker, real production Lua loading for a narrow semantic dependency closure, deterministic scenarios, bounded process handling, startup handshake/capabilities, diagnostics, and regression tests.

The current Lua smoke infrastructure already provides isolated Lua processes, parallel execution, timeouts, bounded output, process cleanup, structured lifecycle reporting, and runtime-path helpers such as `T.load`, `T.path`, `T.read`, and `T.addPackagePaths`.

Preserve these behaviors while generalizing reusable mechanisms.

## Test Lane A: Fast Simulated Lua Harness

Purpose:

- fast agent iteration
- deterministic behavior
- isolated tests
- real production mod Lua
- selected emulated or contract-stubbed PZ APIs

Good uses include:

- domain logic
- task decisions
- needs
- supply
- work orders
- semantic logic
- state machines
- validation
- network payload logic
- deterministic scheduling
- pure inventory policy

Do not attempt to reproduce every Project Zomboid subsystem.

### Simulated support levels

Every simulated engine API must be classified as one of:

```text
EMULATED
CONTRACT_STUB
NATIVE_ONLY
UNSUPPORTED
```

**EMULATED** means the harness reproduces enough meaningful behavior for assertions.

**CONTRACT_STUB** means the harness validates/records the native request but does not claim to reproduce actual engine behavior.

**NATIVE_ONLY** means validation requires the real PZ runtime.

**UNSUPPORTED** means production code reached an API the simulated harness does not currently implement.

Unknown API calls must fail loudly and diagnostically.

Never install a catch-all mock like:

```lua
__index = function()
    return function() return nil end
end
```

A useful failure should identify the subsystem, class/namespace, method, caller when available, whether the PZ contract is known, and current harness support level.

## Test Lane B: Native Project Zomboid Dedicated-Server Runner

The native runner must launch the actual installed Project Zomboid dedicated-server runtime automatically.

It should use:

- actual PZ JVM
- actual Kahlua
- actual Project Zomboid Java classes
- actual server/shared events
- actual world implementation
- actual ItemContainer/InventoryItem behavior
- actual server persistence/network boundaries where testable
- actual Project Hoomans production Lua

Do not recompile the complete decompiled Project Zomboid source as the primary runtime.

The decompiled source is a contract/debugging oracle; the installed dedicated-server runtime is the authoritative integration environment.

### Native test bridge

Create a development-only bridge such as:

```text
PZHarnessBridge/
+-- TestRegistry
+-- TestRunner
+-- Assertions
+-- ScenarioBootstrap
+-- ResultWriter
+-- Diagnostics
+-- ControlChannel
```

The bridge must contain test orchestration only. It must not implement Project Hoomans gameplay.

Its job is to select/receive a test, prepare test state, execute real Lua against real PZ Java, record assertions and build metadata, return a structured result, and support clean shutdown.

### Native runner workflow

The external native runner should eventually:

1. locate the installed PZ dedicated server;
2. detect the current PZ build;
3. create an isolated **absolute** cachedir;
4. create an isolated disposable server configuration;
5. create an isolated disposable world/save;
6. enable PsychopatzCore, ProjectHoomans, and PZHarnessBridge;
7. launch the actual dedicated server;
8. wait for deterministic readiness;
9. execute the selected native test/scenario;
10. capture structured test results, PZ logs, Lua errors, Java exceptions, mod-load failures, build metadata, and timing;
11. request clean server shutdown;
12. force-terminate only when clean shutdown fails;
13. preserve failed-run logs/worlds when useful;
14. return a normalized report.

The goal is one-command native execution by an agent.

Conceptual CLI:

```text
pztest fast inventory
pztest native inventory
pztest native --test inventory/container_roundtrip
pztest affected
pztest compatibility
pztest doctor
```

Exact syntax is not sacred; agent usability is.

## Decompiled Java Contract System

The decompiled Project Zomboid Java source remains important for:

- API discovery
- behavior understanding
- debugging
- update compatibility diffing
- test planning
- locating native changes after failures

Do not compile the complete decompiled game as the main harness.

Build a machine-readable contract index in its own subsystem.

Conceptually:

```text
java_contracts/
+-- scanner/
|   +-- SourceScanner
|   +-- ClassScanner
|   +-- AnnotationScanner
+-- model/
|   +-- ClassContract
|   +-- MethodContract
|   +-- FieldContract
+-- manifest/
|   +-- ManifestBuilder
|   +-- ManifestReader
|   +-- ManifestWriter
|   +-- ManifestDiff
+-- baseline/
    +-- BuildFingerprint
    +-- BaselineRegistry
```

Do not put scanning, parsing, diffing, baseline management, reporting, and CLI behavior in one Java scanner file.

Where practical, capture:

- package/class
- superclass/interfaces
- method name
- visibility
- static/instance
- parameters
- return type
- relevant fields
- annotations such as `UsedFromLua`
- source path
- build/source fingerprint

Start with a robust bounded scanner rather than a perfect Java compiler.

## Project Zomboid Update Compatibility

Engine-update detection is a core project objective.

When PZ changes from one build to another, the harness should answer:

- Did the engine/API change?
- Did a Lua-exposed Java contract change?
- Did the mod stop booting?
- Which native tests started failing?
- Which Project Hoomans modules depend on changed contracts?
- Which tests cover those modules?
- Is a failure likely a PNC regression, harness gap, or PZ compatibility break?

### Versioned baselines

Maintain derived per-build metadata, for example:

```text
baselines/
+-- 42.20/
|   +-- java_api.json
|   +-- build.json
|   +-- fingerprints.json
+-- 42.21/
    +-- java_api.json
    +-- build.json
    +-- fingerprints.json
```

Do not vendor copyrighted full decompiled source into the reusable harness merely for baselines. Derived manifests/fingerprints are the intended artifact.

### Build fingerprints

Keep PZ engine version separate from ProjectHoomans/PsychopatzCore runtime version.

A report should be able to show:

```text
PZ engine:                  42.21
ProjectHoomans runtime:     42.20
PsychopatzCore runtime:     42.20
```

Capture enough engine metadata to detect meaningful changes even if a visible version string is insufficient:

- reported game version
- selected JAR/binary fingerprints where useful
- decompiled source fingerprint
- platform
- Java runtime
- mod runtimes selected

### Semantic API diff

Compatibility comparison should classify meaningful changes, not just hashes.

Examples:

```text
REMOVED METHOD
SIGNATURE CHANGE
NEW METHOD
LUA-EXPOSURE CHANGE
INHERITANCE CHANGE
RELEVANT IMPLEMENTATION CHANGE
UNCHANGED REFERENCED CONTRACT
```

### Project Hoomans engine dependency index

Build or derive a mapping from production PNC Lua to PZ APIs it uses.

Possible sources:

- static Lua scanning
- native runtime telemetry
- existing test coverage

The initial mapping does not need perfect static analysis.

Example:

```text
PNC_FarmingAdapter.lua
    -> IsoGridSquare:getObjects
    -> IsoObject:getModData
    -> GameTime:getWorldAgeHours

PNC_InventoryService.lua
    -> ItemContainer:AddItem
    -> ItemContainer:Remove
```

This allows:

```text
PZ contract changed
        |
        v
which PNC modules are exposed?
        |
        v
which tests should run?
```

### Update workflow

Target:

```text
detect new PZ build
        |
        v
fingerprint engine
        |
        v
generate/update Java API manifest
        |
        v
compare with previous known baseline
        |
        v
calculate Project Hoomans exposure
        |
        v
run affected fast tests
        |
        v
run affected native tests
        |
        v
produce compatibility report
```

A baseline must never be automatically accepted just because the engine changed.

Baseline acceptance must be explicit.

## Compatibility Subsystem

Update detection owns its own logic.

Conceptually:

```text
compatibility/
+-- BuildDetector
+-- BuildFingerprint
+-- BaselineRegistry
+-- ApiDiff
+-- DependencyImpact
+-- TestImpact
+-- CompatibilityReport
```

JavaContracts gathers facts.

Compatibility interprets version differences.

NativeRunner executes tests.

Reporting presents results.

Do not mix these responsibilities into one file.

## Reporting

All test lanes should produce normalized results.

Conceptually:

```text
reporting/
+-- TestResult
+-- FailureClassifier
+-- BaselineComparison
+-- ReportBuilder
+-- JsonReporter
```

Useful failure classifications include:

```text
MOD_LOGIC_REGRESSION
PZ_ENGINE_COMPATIBILITY
HARNESS_GAP
HARNESS_INFRASTRUCTURE
TEST_FIXTURE
NATIVE_ONLY
KNOWN_BASELINE_FAILURE
UNKNOWN
```

Classification can be imperfect, but raw evidence must always be preserved.

The agent should receive actionable failures, not merely `server exited 1`.

## Runtime Resolution

Centralize ProjectHoomans and PsychopatzCore runtime selection.

Do not let tests, Semantic Harness, native runner, compatibility scanner, and composition loader each invent their own version-selection logic.

Desired precedence:

```text
explicit argument/environment
        |
        v
detected compatible runtime metadata
        |
        v
newest valid numeric runtime
```

Hard-coded `42.xx` values may exist only as explicit compatibility fixtures/baselines or temporary documented fallback, not as scattered architecture.

## Events Subsystem

The simulated runtime should eventually expose deterministic PZ-style events such as:

```lua
Events.OnTick.Add(callback)
Events.OnTick.Remove(callback)
Events.OnGameStart.Add(callback)
Events.OnSave.Add(callback)
Events.OnClientCommand.Add(callback)
```

Event listener ordering must be deterministic and diagnosable.

Events owns listener registration/emission.

RuntimeSession coordinates it; RuntimeSession does not implement listener internals.

## Time Subsystem

All simulated gameplay time comes from one deterministic fake clock.

Provide explicit advancement such as:

```text
StepTicks
AdvanceMilliseconds
AdvanceSeconds
AdvanceMinutes
AdvanceHours
```

The same clock should feed GameTime-facing behavior, tick scheduling, leases, cooldowns, needs, work orders, retries, and other deterministic time consumers.

## Inventory Subsystem

Inventory is an engine subsystem, not a Character helper.

Conceptually:

```text
inventory/
+-- Inventory.lua
+-- InventoryItem.lua
+-- ItemContainer.lua
+-- ItemFactory.lua
+-- ItemRegistry.lua
+-- InventoryDiagnostics.lua
```

Implement only the PZ-facing behavior production code actually requires.

Project Hoomans reservation, transfer, stockpile, and ownership policy remains production PNC code.

## Characters Subsystem

Avoid one giant fake IsoGameCharacter.

Conceptually:

```text
characters/
+-- Characters.lua
+-- Character.lua
+-- Player.lua
+-- Zombie.lua
+-- CharacterVariables.lua
+-- CharacterStats.lua
+-- CharacterDiagnostics.lua
```

Add PZ-facing behavior only as production usage requires it. Register every simulated contract/support level.

## World Subsystem

Do not recreate Knox County.

Provide a small deterministic spatial model only as needed.

Conceptually:

```text
world/
+-- World.lua
+-- Cell.lua
+-- GridSquare.lua
+-- WorldObject.lua
+-- Room.lua
+-- Building.lua
+-- SpatialIndex.lua
+-- WorldDiagnostics.lua
```

Small scenarios should be able to define squares, rooms, buildings, containers, moving objects, and obstruction metadata.

## Network Subsystem

Plan for deterministic in-process client/server loopback.

Long-term:

```text
real client PNC code
        |
        v
sendClientCommand
        |
        v
Headless NetworkBus
        |
        v
real server PNC handler
        |
        v
sendServerCommand
        |
        v
real client response handler
```

NetworkBus must not know Project Hoomans command semantics.

## Pathing

Do not recreate native PZ pathfinding early.

The simulated lane should expose a contract boundary that can record origin, destination, request type, retarget/cancel, and allow deterministic outcomes such as:

```text
SUCCESS
FAILED
BLOCKED
CANCELLED
```

Actual native path quality remains native-only until a specific reason justifies more simulation.

## Native-Only Boundaries

Dedicated-server native tests can validate a large amount of server/shared gameplay, but they do not prove graphical client behavior.

Likely native/client-only areas include:

- UI rendering/layout
- textures
- AnimationPlayer visuals
- sprite animation
- FMOD/audio output
- visual path traversal
- rendering/physics details

A future real-client integration lane may automate those areas, but it is not required to build the native dedicated-server lane.

## Scenarios

Scenario data defines state; it must not implement gameplay rules.

Correct:

```text
NPC at x,y,z
container nearby
container contains Base.CannedBeans
```

Incorrect:

```text
scenario implements custom Project Hoomans scavenging
```

Keep scenario loading/validation/fixture building separate from engine behavior.

## Agent Workflow: Normal Code Change

Target:

```text
agent changes production Lua
        |
        v
affected-test resolver
        |
        v
fast tests
        |
        v
native tests when relevant
        |
        v
PASS / localized failure
```

If the native lane fails, the agent should use normalized failure evidence plus the decompiled Java/API manifest to inspect the actual integration point.

## Agent Workflow: Project Zomboid Update

Target:

```text
PZ updated
   |
   v
compatibility scan
   |
   v
new engine build detected
   |
   v
Java/API diff
   |
   v
PNC dependency impact
   |
   v
affected fast tests
   |
   v
affected native tests
   |
   v
localized compatibility report
```

A useful report should identify newly failing tests, changed engine contracts they share, impacted PNC files, previous passing baseline, and recommended next inspection.

## Development Phases

### Phase 0 - Baseline audit

Before major implementation:

- audit existing Semantic Harness/test infrastructure;
- audit reusable vs semantic-specific components;
- audit existing mocks/stubs by subsystem;
- audit runtime/version resolution;
- audit decompiled source availability and current programmatic use;
- audit native dedicated-server installation/launch feasibility;
- capture current test baseline;
- identify monolith/duplication risks;
- propose subsystem boundaries.

No large refactor in this phase.

### Phase 1 - Shared contracts and result model

Implement the smallest reusable foundation:

- support levels
- normalized test result
- build/version metadata
- runtime capabilities
- error/failure classification

### Phase 2 - Native dedicated-server proof

Highest-value proof:

- locate real PZ dedicated server;
- create isolated absolute cachedir/config/world;
- load PZHarnessBridge, PsychopatzCore, ProjectHoomans;
- boot actual server;
- execute one native Lua assertion against real PZ Java/Kahlua;
- write structured result;
- shut down cleanly.

Success criterion:

> An agent can launch actual PZ headlessly and receive a deterministic PASS/FAIL result.

### Phase 3 - Native diagnostics

Add startup timeout, readiness detection, Lua/Java error extraction, mod-load failure classification, forced cleanup, failed-run artifact preservation.

### Phase 4 - Version fingerprint and Java baseline

Capture build metadata and a useful derived Java API manifest/fingerprint.

### Phase 5 - Compatibility diff

Compare PZ baselines and classify relevant API changes.

### Phase 6 - Project Hoomans impact mapping

Map changed PZ contracts to PNC modules/subsystems/tests.

### Phase 7 - Automated update check

One command should detect a changed PZ build, generate a diff, select affected tests, run fast/native validation, compare against the previous baseline, and produce a compatibility report.

### Phase 8+ - Expand native coverage

Prioritize high-value server/shared systems:

- Inventory
- Needs
- Tasks/Work Orders
- Supply
- Facilities
- Research/Crafting
- Farming
- Scavenging
- Factions/Settlement
- Persistence
- Networking authority
- world/container queries

Do not maximize test count blindly. Expand according to risk and value.

## Architecture Review Gate

At the end of each major phase, inspect for:

- RuntimeSession accumulating subsystem logic
- circular dependencies
- giant World/Character objects
- Character duplicating Inventory
- Scenario implementing runtime behavior
- ContractRegistry knowing implementation internals
- Network knowing PNC commands
- Java scanner coupled directly to runtime execution
- generic Utils/Common dumping grounds
- compatibility logic buried inside native runner

Correct architectural drift before building more on top.

## Validation Requirements

For every implementation chunk:

1. run harness subsystem tests;
2. run affected Project Hoomans smoke tests;
3. run existing Semantic Harness regression tests where relevant;
4. verify unknown APIs fail clearly;
5. verify test state isolation;
6. verify processes terminate;
7. run repository Lua/Kahlua validation where applicable;
8. run `git diff --check`;
9. review changed file sizes/responsibilities;
10. record new PZ contracts/support levels;
11. update `PZ_HEADLESS_HARNESS_PROGRESS.md`.

Before completing a chunk, report:

- files added/modified
- subsystem ownership
- files above the cohesion-review threshold and why
- new cross-subsystem dependencies
- new unsupported/native-only contracts
- tests run/results
- recommended next chunk

## Explicit Non-Goals

Do not:

- compile the full decompiled Project Zomboid game as the primary test runtime;
- reproduce Project Hoomans gameplay logic in the harness;
- create one giant PZHarness/Runtime/NativeRunner/JavaScanner file;
- create generic Utils/Common dumping grounds;
- silently swallow unknown PZ calls;
- claim simulated behavior overrides native PZ behavior;
- claim server-native tests prove graphical client behavior;
- scatter PZ/runtime version resolution;
- automatically accept a newly failing compatibility baseline;
- rewrite the working Semantic Harness without a demonstrated need;
- move the whole existing test framework in one migration;
- create hundreds of microscopic files without meaningful ownership.

## Long-Term Success Criteria

The project is successful when a coding agent can:

1. modify Project Hoomans;
2. run focused fast tests;
3. run actual Project Zomboid dedicated-server integration tests without human interaction;
4. receive structured failures with useful engine/mod context;
5. inspect decompiled Java/API contracts when native integration breaks;
6. detect a new PZ build automatically;
7. compare the new engine against the previous known baseline;
8. identify which Project Hoomans modules/tests are exposed to changed contracts;
9. distinguish existing failures from newly introduced compatibility regressions;
10. continue implementation using small, explicit subsystem boundaries rather than a growing harness monolith.

The overriding goals are:

> **Give the coding agent access to real Project Zomboid integration testing without manual game launches.**

and

> **Make Project Zomboid engine updates produce an immediate, localized compatibility report showing what changed, what Project Hoomans depends on, and what actually broke.**
