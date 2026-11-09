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
- Core currently contains the generic foundation, 9 Lua harness files, 18
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

## Next Chunk

**P2-B — add the typed Core semantic-execution contract.** Define the callback
surface for context, text/frame submission, snapshots, bounded turn results,
interaction operations, and materialization metadata; wire Hoomans to it before
moving any mixed conversation module.
