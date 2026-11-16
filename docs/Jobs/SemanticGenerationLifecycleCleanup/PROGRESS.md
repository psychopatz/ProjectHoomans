# Progress — G9 PSDL Package Ownership & Human-Readable Generated Layout

**Status:** COMPLETE.
**Current phase:** G9E — committed-vector migration/rebuild closure.
**Next Chunk:** None (G9A–G9E accepted).

## Completed Gates

- **G9A (Self-Contained Adopter Packages)**:
  - `PsychopatzCore`, `ProjectHoomans`, and `DTCommon` each own their own `package.json` (`psychopatz.psdl.package.v2`) and `provenance.lock` (`psychopatz.psdl.provenance.v1`).
  - Removed adopter-specific `externalSourceRoots` from `PsychopatzCore`; adopter packages import `PsychopatzCore` via generic `"imports"` resolution in `conversation_manifest.py` and `targets/pz_packages.json` (`sourceRootRelative`).
- **G9B (Semantic Ownership Audit & Migration)**:
  - Audited all 3 beats, 30 behaviors, and 35 realizations: kept reusable social beats (3), realizations (35), and generic social behaviors (14) in `PsychopatzCore`; migrated 16 Hoomans-domain scene behaviors (`scene_horde_*`, `scene_excursion_*`, `scene_task_work_*`, `scene_post_combat_clear`, `scene_grounded_news_share`, `scene_news_followup*`) to `ProjectHoomans/tools/providers/pnc/codebuilder/sources/conversation/behavior/social/`.
- **G9C (Human-Readable Deterministic Generated Shard Naming)**:
  - Added `semantic_chunk_label()` and `audit_hashed_module_names()` in `catalog_naming.py` and raised `compact_segment` default `maximum` to `64`.
  - Split oversized domains into readable semantic chunk modules (e.g. `Dialogue/CompanionCommandsLifecycle/{CampToFollow,ReturnHomeToStay,CommandStopFollowing}.lua`), reducing `ProjectHoomans` `__<8hex>.lua` files from 26 to **0**.
- **G9D (Package/Source/Generated Navigation UX)**:
  - Added `locate_psdl()` in `psdl_inspect.py` and `convo_engine_cli.py locate <id>` deriving package, owner, authored source path, imported packages, capabilities, portable plan section, generated modules, and consumers from the canonical compiler model.
- **G9E (Committed-Vector Closure)**:
  - All 38 G9/G8R7/G8/lifecycle tests, `reconcile --check` (`desired=385, clean=true`), `audit-s6m8 --check-determinism` (`violationCount=0, diffs=[]`), and isolated `git archive HEAD` clean rebuild/no-op/equivalence checks pass.
