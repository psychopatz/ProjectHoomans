# Progress — Portable PSDL / ConvoEngine Production Integration

**Status:** COMPLETE.
**Current phase:** G8R6 — final closure.
**Next Chunk:** None (all G8R1–G8R6 gates accepted).

## Completed Gates

- **G8R1 (Compact PSDL Production Adoption)**:
  - Added production `package.json` (`psychopatz.psdl.package.v2`) and `provenance.lock` (`psychopatz.psdl.provenance.v1`) in `psychopatzCore/tools/semantic_harness/codebuilder/sources/conversation/`.
  - Migrated all 576 existing ConvoEngine source files (126 Core, 439 ProjectHoomans, 11 DTCommon) + new `social_profanity.json` (577 total) to `psychopatz.psdl.v2` (`0` remaining `psychopatz.convo-engine.v1` production files), with family-owned `translations/*.json` sidecars and ~32.8% main-source byte reduction.
- **G8R2 (Portable Dialogue Plan Production Seam)**:
  - Routed `compile_conversation_sources()` through `compile_portable_plan()` -> `render_pz_backend_from_portable_plan()`; bypassing `portablePlan` fails closed.
- **G8R3 (Special-Logic Migration)**:
  - Removed handwritten `pnc.social.profanity*` registrations from `Catalog_Register.lua` and regenerated them from canonical `social_profanity.json` (`pack.projecthoomans.social_profanity`).
  - Wired `command.camp` to `hoomans.camp.establish` (`mutating: true`, `safe_recovered` fuzzy confirmation safety) and verified real beat/behavior execution via `PortableReferenceVM`.
- **G8R4 (Data-Driven Package/Owner/Target Routing)**:
  - Externalized package/target descriptors to `targets/pz_packages.json` and `generation_ownership.py` (`load_package_descriptors`, `temporary_package_descriptors`), removed hard-coded owner branching in `generation_recipe.py` / `owner_repository`, and enforced `validate_target_capabilities()` in `compile_conversation_sources()`.
  - Verified synthetic adopter (`SyntheticSurvivalMod`) routing through the normal production build with zero compiler routing edits.
- **G8R5 (Cross-Backend Trace Equivalence & Clean Rebuild)**:
  - Verified `PortableReferenceVM` vs PZ backend projections on real production profanity, beat, behavior, camp, fuzzy safety, and realization scenarios.
  - Verified isolated `git archive HEAD` clean rebuild, second-pass no-op, `reconcile --check` (`desired=384, clean=true`), and `audit-s6m8 --check-determinism` (`violationCount=0, diffs=[]`).
- **G8R6 (Final Closure)**:
  - Committed all participant and primary repository changes cleanly on `main` and re-verified on the final committed vector.
