---
handoff_schema: 3
checkpoint_mode: committed_handoff
target_repo: /home/psychopatz/Zomboid/Workshop/ProjectHoomans
branch: main
phase: Nested Conversation source and bundle sharding
retrieval_tier: COMPLETE
primary_phase_commit: 5ad172fe0fe06e7139c1d2030c8232196767aa3a
participant_commits:
  psychopatzCore: c079cbf8cde239f903c057a07c193af7e05ff75f
  DynamicTrading: 77d29f8a9017a4692f9edde5185a6df2f38d81d3
state: COMMITTED_UNRELATED_DIRTY_PRESERVED
updated_at: 2026-11-12T00:00:00+08:00
---

# Unified Semantic Catalog Handoff

## Contract delivered

PsychopatzCore owns the semantic harness, manifest, compiler, validators, and
generated semantic contracts. Project Hoomans and Dynamic Trading consume the
same Core-owned graph through their package-owned output routes.

Conversation authoring is self-contained and nested by domain. The bundle
catalog is indexed by `conversation/bundles/manifest.json` and has 15 domain
shards. Bundle ownership, duplicate IDs, locale completeness, safe runtime
paths, and package filtering are validated before rendering.

No old bundle source file, copied harness, or compatibility bridge remains.
Generated EN/TL output remains under each mod's `common/media/translation`
tree, and the direct PNC build does not include Dynamic Trading content.

## Acceptance evidence

- Core CodeBuilder: **86/86**.
- Dynamic Trading: **88/88**.
- Affected PNC shard/authority/compiler tests: **20/20**.
- PNC-only build: **339** generated files; all-enabled build: **351**.
- Both builds preserve 505 phrase families and 56 patterns.
- Source audit: no legacy authoring fields, locale-split filenames, or size
  violations.
- Full PNC Lua runner: **1016/1018 passed**; the two known unrelated smoke
  failures are recorded in `PROGRESS.md` and were not modified.

## Repository state

All phase-owned changes are committed on `main`. Existing unrelated dirty
files remain preserved and unstaged. No Workshop publication or native live
game acceptance was performed.

## Future extension rule

Future expansion packs add provider manifests and external shards to the Core
graph. They must not add a second semantic harness, a parallel bundle reader,
or a compatibility layer.
