# Progress — Portable PSDL / ConvoEngine Production Integration

**Status:** COMPLETE.
**Current phase:** G8R7D — final committed closure.
**Next Chunk:** None (G8R1–G8R6 and G8R7A–D accepted).

## Completed Gates

- **G8R1–G8R6**: Compact `psychopatz.psdl.v2` production corpus (577 files, `0` remaining `psychopatz.convo-engine.v1`), `package.json` + `provenance.lock`, `compile_portable_plan()` production seam, `pnc.social.profanity*` & `command.camp` migration, and data-driven package/owner routing.
- **G8R7A (Descriptor-Selected Backend Dispatch)**:
  - Added [backend_registry.py](file:///home/psychopatz/Zomboid/Workshop/psychopatzCore/tools/semantic_harness/codebuilder/backend_registry.py) (`register_backend`, `resolve_backend`, `render_portable_plan_for_target`, `render_portable_json_backend`).
  - `combined_target_descriptor()` derives `backend` from active package descriptors and fails closed on incompatible backends or unknown backend IDs.
  - `compile_conversation_sources()` dispatches via `render_portable_plan_for_target()` with zero hard-coded PZ backend selection; proven with non-PZ `portable-json` backend.
- **G8R7B (Executed Reference VM <-> Lua/PZ Trace Equivalence)**:
  - Added [semantic_trace.py](file:///home/psychopatz/Zomboid/Workshop/psychopatzCore/tools/semantic_harness/codebuilder/semantic_trace.py) (`psychopatz.psdl.semantic-trace.v1`) comparing `PortableReferenceVM` against live Lua `ConvoProbe` (`evaluate_predicate` + `simulate_exchange`) on real production profanity, beat (`beat.argument_escalation`), behavior (`behavior.retaliate_verbally`), camp result branching (`command.camp`: `queued`/`rejected`/`failed`), realization template identity (`question.knowledge`), and fuzzy mutating confirmation safety.
- **G8R7C (Authored vs Canonical Source Lineage)**:
  - Preserved `authoringSchema` (`psychopatz.psdl.v2`), `canonicalSchema` (`psychopatz.convo-engine.v1`), truthful `sourceSchema`, and `sourcePath` across `dialogue`, `behavior`, `beat`, and `realization` IR records.
- **G8R7D (Final Committed Closure)**:
  - Committed participant repositories first (`DynamicTrading`, `psychopatzCore`) and `ProjectHoomans` last, and verified isolated `git archive HEAD` clean rebuild, second-pass no-op, `audit-s6m8 --check-determinism`, and `test_psdl_portability_g8r7` against the final committed vector.
