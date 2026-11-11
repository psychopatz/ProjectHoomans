# Unified Semantic Catalog Progress

**Status:** COMPLETE
**Primary repository:** `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`
**Participants:** PsychopatzCore, DynamicTrading
**Current phase:** P5 — composition-matrix and harness acceptance
**Accepted slices:** P0A, P0B, P1A, P1B, P1C, P2A, P2B, P3A, P3B, P3C, P3D, P3E, P4A, P4B, P4C, P5A
**Next chunk:** none — all goal gates are complete.

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

## Accepted P4 — canonical runtime bundle rendering

- The 44 Project Hoomans conversation bundles and 2 Dynamic Trading bundles
  are represented in Core `conversation_bundles.json` with explicit `owner`
  and `modID`.
- Their wording is merged into the Core EN/TL authoring catalogs and rendered
  into package-owned runtime paths under
  `common/media/translation/<LANG>/Conversation/Bundles/`.
- Every runtime consumer uses the canonical generated translation path.
- Migration-only catalog utilities and the old conversation trees have no
  runtime files or source references remaining.
- JSON parity is clean for all 88 PNC and 4 DT locale files.
- Verification passes: Core unittest suite 92/92, focused PNC
  conversation smoke suite 4/4, four DT conversation bridge smokes, and
  `pz-verify` with zero i18n/Kahlua/bloat findings.

## Accepted P5 — composition matrix and harness startup

- PNC resolves to `PsychopatzCore → ProjectHoomans` and boots successfully.
- PNC + Dynamic Trading resolves to
  `PsychopatzCore → ProjectHoomans → DTCommon → DTHoomans` and boots
  successfully.
- DTAbstract resolves to
  `PsychopatzCore → DTCommon → DTAbstract` and boots successfully without
  Project Hoomans.
- Core-only selection is rejected as infrastructure, not exposed as a
  standalone product profile.
- A direct future-expansion provider manifest is discovered and dependency
  resolved without Core code changes.
- `run_harness.sh --gui` created the live `Semantic Lab — pnc` Tk window
  at `1320x860`; the process stayed alive until explicitly stopped.
- The doctor regression was fixed and covered by Core’s 93/93 unittest suite.

The unified semantic catalog architecture and harness migration are complete.
