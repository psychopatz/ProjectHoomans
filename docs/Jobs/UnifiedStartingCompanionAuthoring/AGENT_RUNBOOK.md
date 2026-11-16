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

### P5R — final-screen entry-point repair

Treat the user's native failure as authoritative acceptance evidence that the
previous automated journey coverage was insufficient.

Do not replace the accepted P1/P4 authoring and authority foundations. Repair
the creation lifecycle around them:

1. Remove profession `screen_shown -> OpenComposer` navigation. Visibility
   events may reconcile state but must not unexpectedly open the editor.
2. Introduce one logical creation-session identity across profession screen,
   final `CharacterCreationMain`, composer, and local/co-op equivalents.
3. Add an explicit **COMPANIONS** button beside Play on the final customization
   screen. Reuse a provider-neutral Core final-action seam if a small generic
   extension is justified; otherwise keep any Hoomans patch narrow and ensure
   normal + co-op parity.
4. On button activation, re-read selected companion traits and the CURRENT final
   player descriptor, reconcile the existing session, and only then open the
   shared composer.
5. Track authored intent canonically. Trait selection and open/close-without-
   change remain default. Field edits, preset/template application, sanitized
   import, and explicit Randomize create authored intent.
6. Rework Play into a pre-commit flow: Hoomans validates/stages authored intent
   before invoking vanilla NEXT. Validation failure must leave the final screen
   active. Default/no-authored intent must not block Play.
7. Clear stale staged envelopes when the current session returns to default or
   the selected trait set changes so an older customization cannot leak into a
   later Play.
8. Preserve P4 server authority and delayed MP transmission semantics.

Do not key the final-screen call to `Adapter.GetSession(CharacterCreationMain)`
if that creates a second session. Session identity is the creation flow/player
slot, not the current UI object.

### P5R2 — shared editor parity and usability repair

Treat the user's second native screenshot as authoritative evidence that the
P5R entry point works but the editor presentation gate does not.

Do not rewrite the canonical registry/resolver/session/P4 authority stack.
Repair the presentation layer around those accepted foundations:

1. Audit the current Unique NPC editor and extract/refactor its reusable General,
   Appearance, portrait, skills, traits, and preview controls into one shared
   Project Hoomans authoring editor component.
2. Make the debug Unique NPC creator and starting-companion editor instantiate
   that same component with different context/action adapters. Do not merely
   share the data model while keeping two primitive editor implementations.
3. Introduce a reusable presentation schema/profile over canonical field IDs:
   labels, grouping/order, control type, option provider, normal/advanced/
   diagnostic visibility. Relationship policy then locks/derives/inherits
   those shared controls.
4. Add canonical `identity.nickname` to the shared General editor so both
   surfaces expose the field consistently.
5. Reuse the existing portrait/runtime-preview machinery. Normal edits and
   player-context rebinding update the portrait in place; only Randomize changes
   generation state.
6. Replace the companion window's ordinary `PsychopatzWindow` collapse/pin
   behavior with `PsychopatzFixedWindow` (or the exact existing equivalent).
   Keep Close, responsive layout, and resizing.
7. Resolve all slot/relationship labels through translations. Normal UI must
   not expose raw `PNC_*`, `UI_*`, canonical IDs, `[absent]`, or `<table>` as
   its primary presentation.
8. Wire the existing starter preset store into the companion toolbar:
   LOAD, SAVE selected template, SAVE SET, Randomize, Reset, Revert, Close.
   Saving alone must not mutate spawn intent.
9. Keep raw field/source detail in the Resolution Inspector/advanced diagnostics
   rather than the normal editor.
10. Preserve P5R opt-in/default behavior, one-session ownership, pre-commit
    ordering, dynamic inheritance, and P4 server authority.

Do not solve the registry-field leakage by adding a large companion-only hidden
field list. The presentation profile is shared and policy-aware.

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
- normal and co-op profession screens emit the same generic extension events;
- final normal and co-op creation screens expose the same semantic Companions
  action;
- one logical creation session survives profession -> final -> composer -> final
  transitions;
- no companion trait / skipped editor / open-close-without-change produce no
  authored customization envelope;
- explicit field edit/preset/import/Randomize produces authored customization;
- Play validates/stages authored customization before vanilla NEXT/world
  transition and validation failure leaves the final screen active;
- stale staged customization is cleared when session intent returns to default;
- add/remove/re-add preserves unchanged slot edits;
- Reset/Randomize/Load Build reconcile by actual selected set;
- Gay/Bisexual changes invalidate Lover preview;
- player surname/skin/gender context changes do not mutate saved preset data;
- per-relationship inheritance matrix;
- canonical preset round-trip across two player contexts;
- whole-setup and individual-template persistence;
- Unique NPC import sanitization/reporting strips runtime/authority fields;
- source indicators and Resolved Preview agree with resolver trace;
- debug Unique NPC and starting-companion surfaces instantiate the same reusable
  authoring editor/presentation component;
- companion window is non-collapsible/non-pinnable and exposes no pin/collapse
  title-bar control;
- shared portrait preview renders and updates in place for edits/rebinding;
- General/Appearance controls use translated human labels and appropriate
  controls instead of raw field IDs/`[absent]`/`<table>` rows;
- canonical nickname is editable in the shared General editor;
- skills, NPC traits, vanilla traits, and dynamic traits use the shared
  selector/repeater controls when starter policy permits them;
- relationship-bound fields remain human-facing but locked/read-only with
  correct source explanation;
- companion labels/relationships contain no raw `PNC_*`/`UI_*` keys in normal
  presentation;
- selected-template SAVE, whole-set SAVE SET, and LOAD use the existing
  canonical starter preset store;
- saving without blueprint mutation does not mark customization authored;
- raw resolution rows remain available through diagnostics but are not the
  primary editor;
- Reset, Randomize, and Revert-to-Preset remain distinct;
- final summary includes only selected active slots;
- server strips/rejects spoofed authority;
- delayed/missing MP payload falls back without duplicate NPCs;
- reconnect and old saves remain idempotent.

Native user-owned after P5R2 developer gates:

- final Customise Character screen exposes Companions beside Play for selected
  companion traits;
- companion editor has no pin/collapse control and uses the shared
  Unique-NPC-style General/Appearance editor with a rendered portrait;
- translated human labels replace raw canonical/trait/UI keys;
- Save selected template, Save whole set, and Load are usable;
- nickname, appearance, skills, NPC traits, vanilla traits, and dynamic traits
  use appropriate shared controls where policy permits;
- skipping the editor preserves former default/randomized starter behavior;
- opening/closing without changes also preserves default behavior;
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
- invalid authored customization blocks only the vanilla transition and reports
  the error; missing/no-authored customization remains non-blocking.

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
