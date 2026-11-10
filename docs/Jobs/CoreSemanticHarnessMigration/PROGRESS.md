# Core Semantic Harness Migration Progress

## Status

Implementation and developer-side acceptance complete. Participant checkpoints
are committed on `main`; the primary ProjectHoomans checkpoint is being closed
after this handoff is recorded.

## Completed ownership cutover

- `psychopatzCore/tools/semantic_harness/` is the only physical harness tree.
- ProjectHoomans and DynamicTrading no longer contain `tools/semantic_harness`
  or the old harness package metadata.
- Core owns identity facets, deterministic seed-based nickname/name projection,
  static suggestions, and radio broadcast contracts.
- PNC and DT retain only provider adapters/content outside the harness
  namespace. The DT conversation pack is sourced from DynamicTrading and is
  optional when compiling PNC-only output.
- Profiles are explicit: `core`, `pnc`, `dtabstract`, `dthoomans`, and
  `combined`; DTAbstract does not require PNC.

## Verification evidence

- Core semantic harness Python suite: 48/48.
- PNC provider harness suite: 24/24.
- DT adapter Python suite: 5/5.
- Core, PNC identity, and DT adapter Lua smoke tests: passed.
- Deterministic CodeBuilder regeneration: 205 generated files, 505 phrase
  families, 56 patterns, 13 UI definitions.
- Optional DT source manifest behavior is covered by Core tests; PNC-only
  compilation succeeds without DynamicTrading and combined compilation emits
  the DT pack into DTCommon.
- Static scans: only Core has a `semantic_harness` directory; no obsolete
  adopter package metadata or harness bridge symbols remain in executable
  source.

## Remaining handoff

The only remaining validation is user-owned live Project Zomboid SP/MP loading.
Unrelated dirty work in all three repositories remains intentionally
unstaged.
