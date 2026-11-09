# Progress — Semantic Harness Core Migration

**Status:** IN PROGRESS

**Primary repository:** ProjectHoomans (`main`)

**Participant repositories:** PsychopatzCore (`main`), DynamicTrading (`main`)

## Verified baseline

- Core owns the JSON-lines Lua protocol and explicit JSON-null marker.
- Hoomans-local `tools/semantic_harness/lua/worker/Protocol.lua` is deleted.
- Hoomans still owns the active Semantic Harness worker, runtime, UI, authoring
  surface, and provider-specific test estate.
- Current tracked Hoomans scope includes 98 Lua worker modules, 403 harness
  Python files, and 211 harness tests.
- Core currently contains the generic foundation, 2 Lua harness files, 16
  harness Python files, and 8 harness tests.
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

## Next Chunk

**P1-A — classify the Hoomans harness into Core-kernel, provider-policy, and
adopter-acceptance modules.** Use Codebase Memory plus exact source reads to
produce a bounded move list for transport/session/scenario/projection/runtime
modules, their callers, and their tests. Do not move production policy or
delete files in this chunk.
