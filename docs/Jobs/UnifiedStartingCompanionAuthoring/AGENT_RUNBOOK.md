# Agent Runbook — Unified Starting Companion Authoring

## Scope

Primary repository:

- Project Hoomans: `/home/psychopatz/Zomboid/Workshop/ProjectHoomans`

Conditional participant:

- PsychopatzCore: `/home/psychopatz/Zomboid/Workshop/psychopatzCore`

Use existing `main` branches. Never create a new branch, blind-pull, reset,
rebase, auto-stash/discard, or overwrite unrelated work.

The current worktrees are dirty from other active jobs. Preserve all unrelated
changes and stage/commit only exact phase-owned paths if/when a phase is
accepted.

## Startup order

1. Read both repositories' root `AGENTS.md` before editing that repository.
2. Read this job's `PROGRESS.md` and `HANDOFF.md`.
3. Recheck branch, HEAD, upstream/ahead-behind state, worktrees, and dirty paths.
4. Inspect exact current runtime source before relying on this audit; Build
   42.20 runtime files are authoritative for this goal.
5. Query Codebase Memory if useful, but direct source/tests remain truth when
   the worktree is dirty.
6. Never touch unrelated semantic-dialogue/harness edits merely to make this
   job clean.

## Implementation discipline

### P1 — canonical fields/blueprint/resolver before companion UI

Do not start by copying the Unique NPC editor.

First establish the canonical NPC authoring field registry and compact/validation
codec, then the reusable blueprint, context/policy, resolver, and concrete
validation seam. Migrate the existing debug/Unique NPC creator to prove that
the new abstraction is real. New variables are added to this shared registry
once rather than separately to Unique NPC and companion code. Prefer
registry-driven encode/decode/serialization over new manual field arrays.

Define explicit absent/value/clear semantics before migrating the editor so
fields that intentionally mean `none` cannot be confused with un-authored
fields. Add deterministic registry and blueprint fingerprints only for
compatibility/cache/deduplication; never use them as authority IDs.

Audit every field currently accepted/emitted by `PNC_UniqueNPCs`,
`PNC_UniqueNPCDraft`, identity generation/repository code, the Unique NPC
editor, and owned definition files before freezing the first registry. Convert
all Project Hoomans-owned code/data to the new canonical schema in the same P1
cutover. Include `identity.nickname` as canonical and remove `alias` from active
authoring/persistence paths. Do not add legacy migration scripts/loaders or
golden migration fixtures.

P1 also establishes reusable resolution metadata and deterministic generation:
the same resolver must return bounded field-source traces and stable output for
the same blueprint/context/seed. The debug Resolution Inspector is only a
consumer of that trace; do not create diagnostic-only resolution logic.

### P2 — one character-creation patch seam

Prefer one Core-owned provider-neutral extension seam if it prevents multiple
adopter patches. Keep Hoomans semantics out of Core.

If direct implementation evidence proves the smaller existing patch can expose
a safe generic callback without a new registry, use the smaller design. The
acceptance invariant is one reusable patch point.

### P3 — session and presets

Key session state by stable starting-companion trait ID. Reconcile from the
actual selected set, never from button intent.

Use existing social-trait resolution for orientation. Do not copy Gay/Bisexual
logic into UI code.

Persist sparse blueprint intent. Mandatory inherited/derived fields stay
unresolved in preset storage. Normal UI exposes field-source indicators and a
Resolved Preview without mutating the blueprint. Keep Randomize, Reset, and
Revert-to-Preset as separate operations.

Preset work includes explicit schema ID/version, whole-setup and
per-slot templates, and sanitized Unique NPC import. Import preview must be
produced by the same sanitizer used for application. Provide a compact
pre-commit summary of active companion slots.

### P4 — server authority

Production companion customization gets a dedicated non-debug command/service.
SP invokes the same semantic service directly.

Server-side resolver uses the actual final player and server trait/social
state. Treat all client authority-sensitive fields as untrusted. Require
protocol/registry compatibility before compact payload decode and fail the
customization atomically to the existing default fallback on mismatch.

Preserve the existing `StartingCompanionService` as spawn/recruitment/
relationship/knowledge/faction owner.

### P5 — tests

Extend existing root Lua tests and Core tests. Do not create a second harness
framework.

When a new UI engine stub is needed, add it to the current harness support in
the smallest reusable place.

## Required focused verification

At minimum during implementation, keep these existing tests passing:

```sh
lua tests/pnc_social_traits_smoke.lua
lua tests/pnc_starting_companion_relationship_key_continuity_smoke.lua
lua tests/pnc_starting_companion_service_presence_boundary_smoke.lua
lua tests/pnc_starting_companion_smoke.lua
lua tests/pnc_starting_companion_state_normalization_smoke.lua
```

Use `python3 tests/run_tests.py --list` / focused domains to locate additional
owner tests rather than introducing a new runner.

For changed Lua:

- run focused owner tests;
- compile/check with the repository's existing Lua/PZ verifier path;
- run `python3 tests/refactor_binding_smoke.py` when split modules or private
  bindings change;
- run `git diff --check`.

For PsychopatzCore changes, run its focused trait/UI tests plus the smallest
relevant shared harness checks.

## Required new acceptance matrix

Automated:

- debug creator and companion authoring use the same field registry and
  blueprint/resolver;
- every currently authorable Unique NPC variable has a registry descriptor;
- all Project Hoomans-owned Unique NPC definitions/data are converted to the
  canonical schema;
- canonical nickname survives draft/save/load/resolve/runtime round-trip;
- obsolete alias fields are absent from active authoring/persistence paths;
- new registered persistable fields cannot be silently dropped by the
  serializer/codec;
- absent/value/explicit-clear round-trip is lossless and mandatory bindings
  cannot be cleared;
- deterministic registry fingerprint detects incompatible wire schemas;
- deterministic blueprint fingerprint supports cache/dedupe without becoming
  runtime identity/authority;
- shared resolver emits correct bounded field-source traces;
- same blueprint/context/seed resolves identically across preview rebuilds;
- explicit Randomize changes only the intended generation seed/path;
- debug Resolution Inspector consumes the shared trace;
- unresolved starter blueprint resolves concrete surname/sex/appearance;
- normal and co-op character screens emit the same generic extension events;
- add/remove/re-add preserves unchanged slot edits;
- Reset/Randomize/Load Build reconcile by actual selected set;
- Gay/Bisexual changes invalidate Lover preview;
- player surname/skin/gender context changes do not mutate saved preset data;
- per-relationship inheritance matrix;
- canonical preset round-trip across two player contexts;
- whole-setup and individual-template persistence;
- Unique NPC import sanitization/reporting strips runtime/authority fields;
- source indicators and Resolved Preview agree with resolver trace;
- Reset, Randomize, and Revert-to-Preset remain distinct;
- final summary includes only selected active slots;
- server strips/rejects spoofed authority;
- delayed/missing MP payload falls back without duplicate NPCs;
- reconnect and old saves remain idempotent.

Native user-owned:

- SP;
- host/client MP;
- local/co-op;
- reconnect;
- replacement survivor;
- presets across different survivors;
- whole-setup/per-companion/import workflows;
- stable preview across repeated editor opens;
- field-source indicators and Resolved Preview updates;
- Reset/Randomize/Revert-to-Preset behavior;
- final pre-commit companion summary;
- Resolution Inspector diagnostics;
- final appearance/name changes;
- invalid/missing customization.

## Runtime safety

Project Zomboid watches loaded `media/` trees. Never create staging
directories under a watched `media/` tree while the game is running. Avoid
directory-swap operations. Use safe file writes/rename-into-place or stop the
game first.

Do not use `pcall`/`xpcall` for ordinary validation/control flow. Existing
protected calls at external engine boundaries are not a pattern to copy.

## Documentation and phase close

Update `PROGRESS.md` with verified truth only and keep exactly one immediate
Next Chunk.

Before a voluntary stop or model/session handoff, rewrite `HANDOFF.md` with
the current checkpoint and exact next action.

After a developer-side phase gate is accepted, stage only exact phase-owned
paths and make the local phase commit. Do not push or publish without explicit
authorization.
