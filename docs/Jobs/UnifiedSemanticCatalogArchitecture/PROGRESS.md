# Unified Semantic Catalog Progress

**Status:** IN_PROGRESS
**Primary repository:** `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`
**Participants:** PsychopatzCore, DynamicTrading
**Current phase:** P4 — runtime migration and legacy removal
**Accepted slices:** P0A, P0B, P1A, P1B, P1C, P2A, P2B, P3A, P3B, P3C, P3D, P3E
**Next chunk:** P5 — composition-matrix and harness acceptance

## Verified baseline

- PsychopatzCore is the only semantic CodeBuilder authority.
- Core owns the typed shard schema, manifest, compiler modules, validators,
  authoring catalogs, and generated semantic registries.
- Project Hoomans and Dynamic Trading consume Core-generated artifacts; neither
  carries a second semantic harness.
- Authoring translations are one complete JSON catalog per locale
  (`EN.json`, `TL.json`, and future locale files).
- Existing unrelated dirty work in all three repositories is preserved.

## Accepted P1C — catalog-only source contract

- Canonical shards reject inline translation maps and inline fallback wording.
- Compiler hydration supplies wording from complete locale catalogs.
- Locale validation enforces exact key parity, placeholders, stable source-shard
  references, and deterministic duplicate-key rejection.

## Accepted P2A/P2B — explicit, normalized shard architecture

- All 122 canonical shards use `psychopatz.semantic.shard.v2`.
- Every shard has a deterministic `shardId`, explicit `owner`, and
  `sourceProfile`.
- Repeated provenance is manifest-owned; stable record IDs are independent of
  physical file paths.
- External Dynamic Trading packs mount into the Core graph and do not create a
  second compiler or copied source tree.

## Accepted P3 — modular compiler

- Manifest loading, shard validation, catalog hydration, assembly, rendering,
  discovery, health checks, registry serialization, and shared contracts live
  in dedicated Core modules.
- `conversation_compiler.py` remains the public orchestration hub.
- Core’s semantic-harness suite passed 89 tests at the P3 extraction gate.
- Real Core → Project Hoomans → Dynamic Trading builds remained stable at
  205 generated files, 505 phrase families, 56 patterns, and 13 UI
  definitions before the legacy-bundle migration.

## P4 implementation evidence

- The 44 Project Hoomans legacy conversation bundles and 2 Dynamic Trading
  bundles are represented in Core `legacy_bundles.json` with explicit
  `owner` and `modID`.
- Their wording is merged into the Core EN/TL authoring catalogs and rendered
  into package-owned runtime paths under
  `common/media/translation/<LANG>/Conversation/Legacy/`.
- The old PNC loader was renamed to the catalog boundary and every runtime
  consumer was migrated to the generated translation path.
- The old PNC conversation tree and the old DTCommon/DTHoomans conversation
  trees have no runtime files remaining.
- JSON parity is clean for all 88 PNC and 4 DT legacy locale files.
- Verification currently passes: Core unittest suite 92/92, focused PNC
  conversation smoke suite 4/4, four DT conversation bridge smokes, and
  `pz-verify` with zero i18n/Kahlua/bloat findings.

## Remaining acceptance

- Commit the phase-owned Core, Dynamic Trading, and Project Hoomans changes
  without staging unrelated dirty work.
- Run the composition matrix for Core dependency closure, PNC-only,
  PNC + Dynamic Trading, DTAbstract, DTHoomans, and an optional expansion pack.
- Verify the harness GUI starts and selects real repository-backed compositions
  with no fixture-only or compatibility-shim path.
