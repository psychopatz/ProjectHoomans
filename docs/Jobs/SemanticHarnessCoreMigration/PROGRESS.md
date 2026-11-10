# Progress — Semantic Harness Core Migration

**Status:** IN PROGRESS

**Primary repository:** ProjectHoomans (`main`)

**Participant repositories:** PsychopatzCore (`main`), DynamicTrading (`main`)

## Verified baseline

- Core owns the JSON-lines Lua protocol and explicit JSON-null marker.
- Hoomans-local `tools/semantic_harness/lua/worker/Protocol.lua` is deleted.
- Hoomans still owns the active Semantic Harness worker, runtime, UI, authoring
  surface, and provider-specific test estate.
- Current tracked Hoomans scope includes 95 Lua worker modules, 404 harness
  Python files, and 212 harness tests.
- Core currently contains the generic foundation, 10 Lua harness files, 18
  harness Python files, and 9 harness Python test modules.
- Hoomans `runtime/config.py` still selects the Hoomans worker for the default
  `hoomans` profile; Core has a separate minimal `core` worker.
- DynamicTrading has no standalone `tools/semantic_harness` tree yet. Its
  provider/gameplay modules and tests consume selected Core runtime contracts,
  but not the complete Core worker.
- All three repositories are clean at the start of this goal.

## Evidence

- `CODE_VERIFIED`: Core protocol and JSON smoke tests pass.
- `TEST_VERIFIED`: Hoomans worker-module, persistence, and persistent-worker
  integration tests pass.
- `STATIC_ONLY`: full provider-neutral harness migration is not complete; the
  file counts and worker entry-point inspection above show the remaining split.
- `UNVERIFIED`: native Project Zomboid SP/MP acceptance for the future unified
  worker is not claimed.

## P1-A result

The move matrix is recorded in `P1A_MOVE_MATRIX.md`. Python process/protocol/
worker-session paths are already Core-backed compatibility façades. The first
safe Lua extraction is `RuntimeState.lua` plus `Values.lua`; ScenarioSession,
Conversation, OutputProjection, CommandRouter, and RuntimeEnvironment remain
mixed until typed provider callbacks exist. No source or test file was deleted.

## P1-B result

Core now owns the bounded Lua `RuntimeState` and `Values` kernel. The Hoomans
duplicates were deleted only after Core Lua/Python worker tests and Hoomans
worker/persistence tests passed. The Core worker advertises the kernel
capabilities; Hoomans resolves the modules through its Core-first package path.

## P1-C result

Core now owns generic transport evidence partitioning and annotation. Hoomans
configures the existing interaction-lifecycle fact command during worker
bootstrap; unknown commands remain dispatch evidence. The Hoomans duplicate
was deleted only after Core transport/worker tests and Hoomans worker,
persistence, and integration checks passed.

## P1-E result

Core now owns the provider-neutral `SessionEnvelope` projection and its
compact mutation-response form. Hoomans includes the envelope beside its
existing compatibility payload fields, preserving provider rehydration and
legacy response policy in the adopter. Explicit snapshots remain an inspector
boundary with raw source/provider data; mutation responses compact those
fields. Core and Hoomans focused envelope tests pass.

## P1-F result

Hoomans `ScenarioSession` now creates one Core session envelope per response
and feeds the legacy `sourceSnapshot` and `workingWorld` compatibility
projections from it. The old wire shapes, patch list, provenance overrides,
and compacting behavior remain intact; duplicate source/working selection is
no longer the canonical path. Provider rehydration, PNC relationship/knowledge
state, synthetic defaults, and legacy fields remain Hoomans-owned. The boundary
and focused contract are recorded in `P1F_ENVELOPE_INTERNAL.md`.

## P1-G result

Core now owns the bounded `WorkingWorld` mechanics: deterministic patch
projection, `HARNESS_MUTATION` provenance, source-baseline selection, working
revision/reset counters, and first-baseline capture. Hoomans delegates to that
module while retaining provider rehydration, actor setup, and gameplay reset
policy. Numeric-key patch handling is covered by the Core implementation, and
Hoomans compatibility tests verify patch shape and source provenance.

## P1-H result

Core now owns the provider-neutral ordered worker-router loop. Hoomans keeps
its existing handler composition, session command policy, transport evidence
configuration, and provider-specific catalogs while delegating dispatch and
unknown-command behavior to Core. Core router smoke coverage and Hoomans boot
smokes pass. The exact split is recorded in `P1H_ROUTER_BOUNDARY.md`.

## P1-I result

The Python process lifecycle was already Core-backed through Hoomans' thin
`runtime/process.py` compatibility facade. Core now also owns the shared Lua
JSON-lines `WorkerLoop`; Core and Hoomans supply only provider-specific
bootstrap, hello, and dispatch callbacks. Handshake, request IDs, protocol
failure handling, and quit behavior are covered by Core smoke tests and both
worker profiles boot successfully. The boundary is recorded in
`P1I_LIFECYCLE_BOUNDARY.md`.

## P1-J result

Core now owns the provider-neutral Python source/working-world state engine.
Hoomans `runtime/state.py` is a compatibility re-export; its save-backed and
worker callers retain their established import paths without a duplicate
implementation. Hoomans scenario defaults, health normalization, validation,
save import, and production rehydration remain local. The boundary is recorded
in `P1J_STATE_BOUNDARY.md`.

## P1-K result

The mixed Hoomans scenario façade was audited. Core already owns generic
display-name/actor-ID derivation, deep merge, JSON load, and atomic save.
Hoomans-only defaults, health normalization, NPC validation, available-mod
policy, and save/import normalization remain provider/domain policy and were
not moved into Core. The boundary is recorded in `P1K_SCENARIO_BOUNDARY.md`.

## P2-A audit result

Core already owns the semantic parser/IR, actor conversation service, identity,
social, knowledge, journey, and conversation-landing primitives. Hoomans'
worker conversation files are mixed PNC adapters: they combine generic turn
bookkeeping with provider health/faction/knowledge projections, authority,
translation, and interaction-lifecycle policy. No mixed file was moved
wholesale. The typed execution boundary and extraction sequence are recorded
in `P2A_SEMANTIC_EXECUTION_BOUNDARY.md`.

## P2-B result

Core now owns the typed `SemanticExecution` callback contract. Hoomans wires
context, text, preview, semantic-frame, and snapshot operations through it
while retaining PNC policy and physical-adopter behavior. The contract exposes
materialization metadata and fails closed for optional operations; DTAbstract,
DTHoomans, and DTCommon adapter gates remain next. The boundary is recorded in
`P2B_EXECUTION_CONTRACT.md`.

## Next Chunk

**P2-C — register Dynamic Trading adopters against the contract.** Add
provider-neutral DTCommon descriptors plus DTAbstract abstract and DTHoomans
physical callback adapters, keeping merchant policy in DTCommon and physical
materialization in DTHoomans only.

## P2-C result

Core provider descriptors now carry the bounded
`semantic.harness_execution.v1` callback declaration. DynamicTrading adds a
thin `tools/semantic_harness/provider_adapters.py` manifest that composes
`PsychopatzCore + DTCommon + DTAbstract` as `dtabstract` and
`PsychopatzCore + DTCommon + DTHoomans` as `dthoomans`. The profiles share the
same callback contract; only materialization mode and provider capabilities
differ. DTCommon remains merchant-policy owner and no legacy worker files were
deleted.

## Next Chunk

**P2-D — connect profile selection to the Core-owned worker.** Add an explicit
Core profile-loader/worker bootstrap seam that can consume the optional DT
manifest without importing Hoomans or creating a DT worker. Keep the current
Hoomans worker as a compatibility path until P3/P4 gates pass.

## P2-D result

Core now owns `profile_loader.py`, which composes optional adopter registrars
and returns validated profile selections with neutral worker launch metadata.
`WorkerLaunchSpec` forwards provider IDs and materialization mode through the
same environment contract, and the Core worker advertises that selected
metadata without importing an adopter. DynamicTrading resolves `dtabstract`
through this loader. This is bootstrap metadata only; merchant callback
execution and physical materialization remain the P3 boundary.

## Next Chunk

**P3-A — connect provider callbacks to Core execution.** Add the first
provider-backed execution bootstrap for DTCommon while keeping DTAbstract
abstract and DTHoomans physical behavior behind their existing adapters.

## P3-A result

Core now owns the provider-neutral bounded activity stream in
`semantic_harness/activity.py`. Hoomans `runtime/activity.py` is a
compatibility facade exporting the Core implementation; no duplicate activity
engine remains. Core activity tests and Hoomans activity/app/profile/runtime-
package checks pass.

## Next Chunk

**P3-B — move the remaining provider-neutral Python client seams.** Audit the
Hoomans runtime package for generic configuration, worker-session, worker
client, and projection helpers; move one cohesive boundary at a time and keep
facades only until all callers and tests import Core directly.

## P3-B result

Core now owns `runtime_discovery.py` for numeric Build-runtime selection and
Lua executable probing. Hoomans `runtime/config.py` retains only Hoomans
repository/DT discovery and `HarnessConfig`; its generic runtime helpers are
Core imports. Core and Hoomans configuration/profile/runtime-package tests pass.

## Next Chunk

**P3-C — move the provider-neutral worker client configuration seam.** Keep
Hoomans worker selection and scenario policy local, but move generic launch
configuration and adapter metadata into Core before deleting any remaining
facades.

## P3-C result

Core `WorkerLaunchSpec` now accepts validated profile selections and exposes a
neutral worker environment. Hoomans keeps repository/runtime/worker-argument
selection in `build_worker_launch_spec()` while using Core's process client
directly. Production and test callers no longer import Hoomans process,
protocol, or worker-session facades; those three duplicate files were deleted.
Core (36 tests), the Hoomans migration/regression slice, and DynamicTrading's
provider adapter gates pass. The remaining Hoomans activity/scenario/config
surfaces are intentionally provider policy or compatibility boundaries and
are not deleted in this chunk.

## Next Chunk

**P3-D — migrate remaining projection facades and cross-provider worker
metadata.** Audit activity/state/scenario compatibility paths and the Hoomans
worker handshake for direct Core imports, then add a Core-only matrix that
proves optional DTAbstract and DTHoomans metadata can be enabled independently
without importing provider-owned gameplay policy.

## P3-E result

Hoomans launch metadata now includes DTCommon/DTHoomans only when the optional
DynamicTrading runtime is present. DynamicTrading abstract and physical
profile selections both round-trip through Core `WorkerLaunchSpec` with the
same neutral environment contract. Provider policy remains in the adopters.

## Next Chunk

**P4 — remove remaining obsolete harness ownership and complete acceptance.**
Audit all remaining Hoomans runtime/worker Lua modules for provider-neutral
duplicates, migrate only behavior-covered boundaries into Core, remove stale
tests/docs/imports, and run the Core/Hoomans/DT matrix plus the user-owned
native SP/MP handoff gates.

## P4-A result

The import-zero audit removed the last pure Hoomans Python facades for Core
activity/state and Core CodeBuilder naming/translation, along with duplicate
generic tests. Remaining Hoomans runtime and Lua modules carry provider policy
or physical-worker integration; no further deletion is justified without a
behavior-preserving Core contract and matrix coverage.

## Next Chunk

**P4-B — final ownership audit and acceptance matrix.** Verify Core contains
no adopter imports, enumerate every remaining Hoomans/DynamicTrading harness
module by ownership, run optional-provider enable/disable tests, and prepare
the native SP/MP handoff. Do not mark the parent goal complete until the
ownership report and all developer-side gates are current.

## P3-D result

Core now owns the shared Lua launch-metadata parser and both Core and Hoomans
workers advertise the same profile/provider/materialization handshake. Hoomans
activity and state compatibility-only facades were removed after every caller
was moved to Core; scenario defaults/validation and repository configuration
remain local adopter policy. Core, Hoomans, and DynamicTrading provider gates
pass.

## Next Chunk

**P3-E — compose and exercise the cross-provider matrix.** Add explicit
Core-owned matrix coverage for Core-only, Hoomans physical, DTAbstract
abstract, and DTHoomans physical metadata, then wire optional-provider
composition so disabling either adopter leaves Core and the other profile
loadable without stale module imports.
