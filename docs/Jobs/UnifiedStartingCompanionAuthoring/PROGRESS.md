# Progress — Unified Starting Companion Authoring

## Current state — 2026-11-18 P5R3

The requested shared NPC creator redesign is implemented. Both callers use the
same left roster, compact pages and embedded slot/catalog loadout authoring.
General/Appearance overlap, preview-inventory overwrite, explicit clearing,
keyless imported-item removal and bag-before-contents ordering have regression
coverage. Rotation/zoom and compact expanded preview are available.

`TEST_VERIFIED`: 45 focused authoring/inventory tests passed. Full Lua suite
passed 1038/1042; the four prior scene-route/context-debug, population-director
initialization and Debug Hub translation-expectation failures remain unrelated.
`STATIC_ONLY`: changed Lua syntax, Kahlua compatibility, 40 new EN/TL Character
keys, JSON parsing and whitespace checks passed. Graph freshness/coverage was
checked; dirty/new files were verified directly against current source.

Current Next Chunk: **P6 user-owned native acceptance of P5R3**. Open both
creators in a fresh Build 42.20 session. Verify left roster selection, every tab,
compact preview and font scaling, slot equip/replace/clear, bags and contents,
Save/Load/Produce, companion finalization and SP/MP/co-op lifecycle. Native PZ
was not launched, driven or required for developer acceptance. This is the
current responsibility; the earlier P5R2 handoff below is historical evidence.


**Status:** P5R2 developer repair accepted — P6 native SP/MP/co-op acceptance pending

**Primary repository:** ProjectHoomans (`main`)

**Participant repository:** PsychopatzCore (`main`), changed only for the
provider-neutral character-creation seam in P2

## Accepted phases

### P1 — canonical NPC authoring pipeline

Accepted in local commit `a6381bf4`.

The canonical registry, sparse blueprint, explicit-clear semantics, compact
codec, fingerprints, policy resolver, bounded field trace, Unique NPC cutover,
and canonical nickname round-trip are shared by debug authoring and starter
contexts. Superseded authoring aliases are not registered or loaded.

### P2 — provider-neutral character-creation seam

Accepted in local commits `dfcf9f6e` (PsychopatzCore) and `9778522f`
(ProjectHoomans).

PsychopatzCore owns only the generic lifecycle extension. Project Hoomans owns
the starting-companion adapter, trait IDs, policies, presets, and services.
Normal and co-op profession screens use the same extension path.

### P3 — session, composer, presets, and import sanitization

Accepted in local commit `c7904a78`.

The selected-trait keyed session reconciles added/removed/unchanged slots,
retains removed-slot caches, preserves deterministic seeds, reuses the generic
composer and resolution trace, and serializes canonical whole/per-slot presets.
Unique NPC import uses the shared relationship policy and reports preserved,
removed, rebound, and regenerated fields.

### P4 — authority handoff and lifecycle

Accepted in local commit `e15aefea`.

The versioned sparse envelope supports SP, listen-server, and MP with explicit
protocol/registry compatibility, atomic compact decode, strict authority-key
rejection, and a bounded pending/received/validated/defaulted/grants-complete
state machine. Final resolution uses the actual character UUID, descriptor,
social orientation, relationship policy, and existing
`StartingCompanionService`. Timeout/default behavior, payload ordering,
reconnect idempotence, replacement-survivor UUID semantics, and the
millisecond-vs-world-age clock boundary are covered.

## P5 verification evidence

`TEST_VERIFIED`:

- focused authoring/starter suite: **18/18 passed**;
- full Project Hoomans harness: **1028/1032 passed**; the four remaining
  failures are the pre-existing animation-scene debug route, context debug
  scene-lab, population-director initialization, and dirty-work translation
  expectation failures;
- direct authoritative-resolution smoke covers canonical nickname
  preservation, current-player surname/appearance rebinding, relationship sex
  authority, and the shared resolution trace;
- customization smoke covers compact round-trip, explicit clear/value,
  registry/protocol mismatch, spoofed authority, lifecycle ordering, timeout
  fallback, and reconnect idempotence;
- registry/serializer smoke covers immutable wire codes, fingerprints,
  deterministic generation, source tracing, mandatory binding clears, and
  inherited-name projection;
- existing Unique NPC editor/storage, Unique NPC resolver, debug Resolution
  Inspector, starter relationship, social-trait, preset, and character-
  creation extension tests remain green.

`STATIC_ONLY`:

- all changed/new Lua files pass `luac -p`;
- all changed production Lua files pass targeted `pz_verify --kahlua`;
- `git diff --check` passes;
- no native Project Zomboid SP/MP session has been run, per repository policy;
- no Workshop publication or push was performed.

## USER_VERIFIED regression — native entry-point failure

The user tested a new-save character creation in Build 42.20 and reached the
final **Customise Character** screen, but no usable starting-companion editor
entry point was visible. The supplied native screenshot shows vanilla final
character customization with Random and Play controls and no companion action.

`CODE_VERIFIED` audit explains the failure:

- `PNC_StartingCompanionCharacterCreationAdapter.HandleEvent()` calls
  `OpenComposer()` only on profession `screen_shown`;
- `OpenComposer()` returns `no_active_companions` when no starter trait is active
  at that instant;
- later trait-set events reconcile session state but do not reopen the composer;
- therefore the feature can remain invisible even though the session/resolver
  tests pass;
- `PNC_SocialTraitCharacterCreationPatch` currently wraps
  `CharacterCreationMain.onOptionMouseDown` by invoking vanilla Play/NEXT first
  and `Adapter.Submit()` afterward;
- vanilla NEXT hides the final screen, initializes the player/world, and enters
  `LoadingQueueState`, so this is the wrong pre-commit ordering;
- the adapter's current session lookup is screen-object oriented, so a naïve
  final-screen `GetSession(CharacterCreationMain)` would risk creating a second
  logical companion session;
- existing focused tests did not assert the real profession -> final character
  screen -> visible Companions action -> composer -> return -> Play journey.

The prior P1/P2/P4 foundations remain useful and accepted. P3 functionality is
implemented but its entry-point UX acceptance was incomplete. P5 verification
is now insufficient for parent-goal completion because it missed this native
journey regression.

## P5R target

Repair the character-creation lifecycle so the final screen becomes the explicit
entry point:

```text
profession selects companion traits
        -> one logical creation session
        -> final Customise Character screen
        -> optional COMPANIONS button beside Play
              -> shared composer using CURRENT final player context
              -> return to final screen
        -> Play
              -> skipped/unmodified: original default/randomized path
              -> authored: validate/stage before vanilla transition
```

Native P6 acceptance resumes only after P5R automated/UI-harness gates pass.
Do not launch native PZ or publish Workshop content without explicit user
authorization.

## P5R — developer acceptance complete

P5R repaired the real final-screen journey without changing the accepted
authoring, resolver, or P4 authority foundations:

- profession visibility now reconciles only; it never navigates into the
  composer;
- normal and co-op final character screens expose an explicit **COMPANIONS**
  action beside **PLAY**, disabled when no starting-companion trait is active;
- session identity is keyed by creation player index, so profession, final
  screen, composer, and back-navigation share one logical session and removed
  slot caches;
- every open and Play pre-commit re-reads selected traits and the current final
  player descriptor, then rebuilds social/orientation and inherited appearance
  context without mutating blueprint intent;
- blueprint-vs-default fingerprints make customization opt-in. Skipped and
  open/close-without-change flows clear/omit customization intent, while edits
  and explicit Randomize stage canonical authored envelopes;
- authored Play validates and stages before vanilla NEXT/world transition.
  Invalid authored state remains on the final screen with a reason; default
  state never blocks Play. Remote MP keeps the validated envelope pending until
  the player exists and submits it idempotently;
- the focused final-screen journey harness covers normal/co-op entry, session
  continuity, dynamic player rebinding, Lover orientation, back-navigation,
  Randomize determinism, invalid-state blocking, default paths, and MP pending
  submission. Existing authoring, preset/import, customization, starter, and
  authority tests remain green.

## USER_VERIFIED regression — companion editor presentation unusable

The user reran native Build 42.20 acceptance after P5R. The final-screen
**COMPANIONS** button now works and the editor opens, confirming P5R's entry
point/session repair. The opened editor is nevertheless borderline unusable:

- the title bar exposes the normal pin/collapse control even though this
  character-creation editor should remain fixed;
- the main form exposes raw canonical/diagnostic rows such as
  `appearance.beardModel`, `[absent]`, `<table>`, and source-state text;
- the slot/summary presentation leaks untranslated keys and implementation IDs
  such as `UI_PNC_Trait_HasBrother` and `PNC_HasBrother`;
- there is no rendered NPC portrait/live character preview;
- the existing starter preset store is not exposed through practical Save/Load
  controls;
- skills/traits/appearance are not presented through the mature controls
  already available in the debug Unique NPC editor.

`CODE_VERIFIED` audit explains the mismatch:

- `PNC_StartingCompanionComposerWindow.lua` is a separate lightweight window
  that builds generic text controls from `NPCAuthoringComposer:FieldRows()`;
- `FieldRows()` enumerates every canonical registry field marked `authorable`,
  so relationship policy alone cannot produce a curated human editor and
  unrelated authoring fields may appear;
- the debug Unique NPC editor already implements General/Appearance tabs,
  hair/beard/options, voice controls, skills/traits, portrait rendering,
  persistence actions, and deterministic preview refresh;
- the canonical model already supports `identity.nickname`, but the current
  debug presentation does not yet expose it as a normal shared control;
- `StartingCompanionPresetStore` already implements canonical Save/Load, so the
  missing persistence is a UI-integration gap;
- PsychopatzCore already provides `PsychopatzFixedWindow`, whose explicit
  purpose is to remove native pin/collapse behavior.

The accepted P1-P5R data, authority, session, and final-screen lifecycle work
remains valid. P5R2 repairs the presentation layer and completes the original
no-split UI objective.

## P5R2 target

Extract/refactor one shared Project Hoomans NPC authoring editor presentation
from the mature Unique NPC creator and make both debug and starting-companion
surfaces consume it with different action/policy adapters.

The companion adapter must add:

- fixed/non-collapsible window behavior;
- human translated slot/relationship labels;
- real portrait/runtime preview;
- shared General + Appearance controls;
- canonical nickname control;
- skills, NPC traits, vanilla traits, and dynamic traits where policy allows;
- relationship-bound fields shown read-only with compact source explanation;
- LOAD, SAVE selected template, and SAVE SET using the existing starter store;
- Randomize, Reset, Revert, Close;
- Resolution Inspector kept as diagnostics rather than the primary form.

P6 native acceptance resumes after the P5R2 developer gate; it remains
user-owned and has not been run by the agent.

## P5R2 — developer acceptance complete

The shared authoring presentation repair is complete in the current
ProjectHoomans worktree:

- `PNC_NPCAuthoringEditor` now owns the mature Unique NPC General,
  Appearance, skills, traits, portrait, preview, and persistence presentation;
- the debug creator and starting-companion editor both instantiate that same
  component, with a canonical presentation profile and relationship-aware
  adapter rather than a second companion primitive editor;
- the companion host uses `PsychopatzFixedWindow`, translated relationship
  labels, SAVE/LOAD/SAVE SET, RANDOMIZE, RESET, REVERT TO PRESET, and CLOSE;
- `identity.nickname` is a shared canonical control; inherited/derived fields
  remain read-only with human source explanations, while raw resolver rows are
  available only through the Resolution Inspector;
- preview edits and final-player rebinding preserve blueprint intent and the
  deterministic generation seed; only explicit Randomize advances it.

Developer evidence:

- R1-R5 interaction/layout/collection, shared-editor, adapter, P5R journey,
  starter-authority, customization, relationship, and Unique NPC suites passed;
- full harness: **1035/1039 passed**; the four failures remain the documented
  unrelated animation-scene route, context scene-lab, population-director
  initialization, and dirty-work translation expectation failures;
- `luac -p`, targeted production `pz_verify --kahlua`, refactor-binding smoke,
  translation JSON parsing, and `git diff --check` passed;
- no native Project Zomboid session, push, or Workshop publication was run.

## USER_VERIFIED regression — native selector/preview desynchronization and layout debt

The latest native Build 42.20 acceptance proves the shared P5R2 editor opens
and is structurally richer, but full P5R2 acceptance fails.

Visible native symptoms:

- selecting another companion in the top combo can change the displayed label
  while the form and portrait continue showing the previous companion;
- the same desync can leave the footer/status at `No starting companion trait
  selected` while stale Brother/Sister data remains visible;
- after that state divergence, outer Randomize can silently do nothing;
- preset selection is subject to the same selector callback contract;
- General still behaves like a transplanted debug form: large dead regions and
  Add-skill/Add-trait controls without a normal visible/removable configured
  collection;
- Appearance is too dense for character creation and exposes long per-body-slot
  authoring lists, including raw/internal `base:*`-style locations.

`CODE_VERIFIED` root cause and supporting evidence:

- vanilla `ISComboBox` invokes `onChange(target, combo, ...)`;
- `PNC_StartingCompanionComposerWindow.addCombo()` assigns the window as
  `combo.target`, but its slot and preset callbacks currently treat their first
  argument as the combo;
- when that callback path loses `selectedTraitID`, `refreshSelected()` detaches
  the adapter but does not clear the old shared-editor draft/portrait, producing
  stale visible state;
- the outer Randomize/Reset/Revert action exits early when
  `selectedTraitID == nil`, explaining the native Randomize no-op after selector
  desynchronization;
- session-level `RandomizeSlot()` itself changes the canonical generation seed
  correctly; existing tests cover that lower layer but do not exercise the real
  native widget callback signature;
- existing P5R2 smoke tests are mostly structural/model tests and still pass,
  proving they are insufficient as UI acceptance coverage;
- companion mode hides the existing details collection used by the mature debug
  editor for configured skills/traits while retaining the Add rows;
- the shared Appearance editor enumerates every Human body location, which is
  useful for advanced/debug authoring but too dense as the default companion
  creation workflow.

The P5R2 shared component and fixed-window work remain accepted. R1-R5 repair
is closed in the local Project Hoomans phase commit rather than replaced by
another parallel editor.

## P5R2 repair state

- **R1 UI event/state correctness:** ACCEPTED
- **R2 preview identity/invalidation:** ACCEPTED
- **R3 General-tab character-creation UX:** ACCEPTED
- **R4 Appearance normal/advanced UX:** ACCEPTED
- **R5 native-style UI interaction/layout harness:** ACCEPTED

P5R2 is accepted for developer-side work. P6 remains user-owned native
SP/MP/co-op acceptance.

## Next Chunk

**P6 — user-owned native SP/MP/co-op acceptance after the local P5R2 developer
repair commit. Start a fresh Build 42.20 session and validate the final-screen
Companions workflow, relationship policy, presets, default/no-op paths, visual
preview, and SP/MP/co-op reconnect/replacement-survivor authority behavior.**

## Repository safety

ProjectHoomans and PsychopatzCore remain on existing `main` branches. Current
ProjectHoomans HEAD observed during this audit is
`1c7fe2c87908fd5cf0aa4b3b3995baf5eaa3c9c1`.
The worktree contains unrelated active semantic/UI edits; preserve them. No new
branch, push, Workshop publication, reset, stash, broad staging, or agent-run
native PZ validation is authorized. All native regressions were supplied by
the user and are acceptance evidence, not agent-run native tests.
