# Progress — G9R Semantic Domain Decomposition & Generated Surface Normalization

**Status:** COMPLETE.
**Current phase:** G9R5 — final committed-vector closure.
**Next Chunk:** None (G9A–G9E and G9R1–G9R5 accepted).

## Completed Gates

- **G9R1 (Global Generated-Topology Audit & Semantic Path Contract)**:
  - Audited all generated surfaces and proved both remaining Core hash files (`Behavior/Social__d6475647.lua` and `Dialogue/CoreKnowledgeFacts__d73c98cf.lua`) were cross-owner false collisions caused by sharing an unrouted `"ConvoEngine"` prefix in `ModuleNameRegistry`.
  - Added `derive_subdir_domain_path()` in `source_manifest.py` and propagated `domainPath` through `conversation_manifest.py`, `psdl_compiler.py`, and `conversation_compiler.py`.
- **G9R2 (Semantic Source Decomposition)**:
  - Reorganized Core's 14 behaviors into `behavior/social/{acknowledgement,conflict,repair,context,world_events}/` and Core's 3 beats into `beat/social/{conflict,repair,first_contact}/`.
  - Reorganized ProjectHoomans's 16 scene behaviors into `behavior/scene/{horde,excursion,task_work,news,post_combat}/`.
- **G9R3 (Owner-Isolated & Decomposed Generated Surfaces)**:
  - Scoped `ModuleNameRegistry` in `conversation_rendering.py` (`_chunk_records`) and `conversation_compiler.py` (`psdlRuntimePlans`) by `conversation_prefix(owner)` and `domainPath`.
  - Split `Behaviors/Director/*`, `Beats/Director/*`, `Behavior/*`, and `Beat/*` by `owner + domainPath` so Core directors contain zero ProjectHoomans scene behaviors.
- **G9R4 (Global Readable Naming, Variant-Growth Stability & Navigation)**:
  - Reduced avoidable `__<8hex>.lua` hash modules to **0** across all three repositories (`PsychopatzCore: 0`, `ProjectHoomans: 0`, `DTCommon: 0`).
  - Exposed `domain` and `domainPath` in `psdl_inspect.py` (`locate_psdl`).
- **G9R5 (Committed-Vector Closure)**:
  - Verified all 42 tests, `reconcile --check` (`desired=407, clean=true`), `audit-s6m8 --check-determinism` (`violationCount=0, diffs=[]`), and isolated `git archive HEAD` clean rebuild, no-op second pass, and Reference VM ↔ Lua ConvoProbe trace equivalence.
