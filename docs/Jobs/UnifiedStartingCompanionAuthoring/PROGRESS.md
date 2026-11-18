# Progress — Unified Starting Companion Authoring

## Current state — 2026-11-19 P5R11

The creator preview now retains the exact tint, texture and decal of an existing
backpack across inventory and body reconstruction. Previously a fresh generated
bag had no visual state, so the next native capture randomized its tint again.
Preview-only continuity matches item type and logical template/placement, never
new runtime item IDs. It fills only absent visual state; explicit replacement
visuals and new generations remain authoritative. Nonvisual item state and sparse
authored intent are unchanged. Both creator hosts use this shared model fix.

`TEST_VERIFIED`: **67/67** focused; full **1060/1064**, same four known failures
(animation-scene debug routes, context debug, population initialization and
translation-manager TL expectation). The new regression uses the real preview
model, visual codec and inventory-to-equipment projection. It covers name,
skin/hair/pitch, carried-item and outfit-policy edits, body rebuilds, replacement
visuals/types/keys, fresh seeds/previews and nonvisual state preservation. With
continuity disabled at the module boundary, it reproduces the carried-edit tint
change (.1 to .2); the repaired path passes. Three Lua syntax checks, two
production Kahlua checks and whitespace checks pass. Coverage/current source
checked for the twelve implementation/test evidence paths. No strings/schema or
Core edits were needed; concurrent semantic-tooling work remains unowned.

Next: user-owned fresh-session test in both creators: note backpack color, edit
name, skin/hair, pitch, carried contents and gender where allowed, and switch tabs.
The same backpack should retain its exact color. Deliberate replacements and
Loadout rerolls should still work. Continue the remaining P6 matrices; native
visual/audible success is unverified and no game launch/control was performed.

## P5R10 startup repair — native acceptance pending

The native startup regression is repaired on the developer side. Console session
`4c35d197` confirms `E4A983F`: Item Explorer onResize indexed `options.onDelete`
while options was nil during composer construction. The explorer now explicitly
starts idle and defers layout until Show supplies a browsing session.

The new regression reproduces pre-child and post-child idle resize, the real
companion-host startup layout, then normal Show/Delete/Hide behavior. This also
removes the widget fixture's implicit empty-options table from the production
constructor contract, which had masked the native lifecycle difference.

`TEST_VERIFIED`: **66/66** focused; full **1059/1063**, with the same four known
scene-route/context-scene/population/translation failures. `STATIC_ONLY`: both
owned Lua files parse, the production file passes Kahlua error checks, whitespace
passes, and seven evidence paths have coverage/current-source checks. No strings
or schemas changed. No native game launch/control or native success is claimed.

Next: restart the installed game, open the companion composer and debug creator,
then run the P5R9 native matrix below. Actual opening/rendering/audible acceptance
remains user-owned.

## P5R9 implemented features — native acceptance pending

Developer-side modular loadout, dynamic portrait, native audio routing and local
record-deletion work is verified. Native acceptance remains **UNVERIFIED**.
Both creator hosts keep one canonical authoring model and shared editor.

- Loadout has selectable body-part views and a separate carried-inventory list.
  Metadata classification avoids substring collisions such as forearm/ear,
  underwear/ear and socket/sock; unfamiliar mod locations remain accessible.
  Empty native-exclusive alternatives hide while their blocking item is worn,
  then return after clearing. Equipped slots remain available to remove.
- Carried money/food/supplies have explicit quantity/destination, Add/Edit/Remove
  actions and the same loaded-game/mod Item Explorer. Body equipment and held
  attachments keep their equipment controls. Model edits/persistence stay shared.
- Appearance uses vanilla face framing (zoom 14, Y offset -.85), strips obscuring
  clothes only from its copied descriptor projection, and restores body framing
  on other pages. Body/face zoom preferences are separate. NPC data is unchanged.
- Voice preview now follows native PLAYDEMOVOICE's menu FMOD InGame routing,
  then returns to MainMenu on completion/stop. Owned-handle stopping and menu
  origin/pitch/type handling remain. In-game debug playback does not change
  music state. Native playback, rather than a catalog precheck, determines success.
- Both saved-record browsers expose select/Delete/Confirm delete. Selection or
  filter changes cancel stale confirmation. Deletion erases the payload, removes
  only that namespace/index record and leaves a non-loadable marker file on disk.
  Rebuild cannot resurrect it. A deleted local encounter definition leaves the
  future catalog while existing actors and per-world death records remain.
  MP server-library deletion independently requires admin access.

`TEST_VERIFIED`: **65/65** focused tests; full suite **1058/1062**, with the same
four known scene-route/context-scene/population-initialization/translation
failures. New regressions cover classification, slot hide/restore, carried
editing, non-mutating face/body transitions and stale deletion confirmation.
Existing database/library/audio tests cover namespace isolation, payload erasure,
admin deletion rejection, retained world death and FMOD routing/cleanup.

`STATIC_ONLY`: **28** owned Lua syntax/**21** production Kahlua checks pass.
Six new EN/TL Character keys, JSON/key/placeholder parity, static/dynamic key
references and whitespace checks pass. Coverage checked for 38 Hoomans, three
Core and five Java evidence paths; dirty/new source read directly. Installed
CharacterCreationMain/Avatar and current Java baseline supplied native contracts.

Next: **P6 user-owned fresh-session retest** in
[LOADOUT_AUDIO_CRUD_RETEST.md](LOADOUT_AUDIO_CRUD_RETEST.md), followed by prior
skin/save/library and SP/MP/co-op matrices. No native game launch/control,
rendered/input/audible success, push or Workshop publication is claimed.

## Historical developer checkpoints

### P5R4 — preceding developer checkpoint

Developer-side repair of the user-reported native regressions is complete.
Both creator entry points retain one shared editor and canonical data model.
Native acceptance remains **UNVERIFIED**; the P5R3 screenshots are the latest
native evidence, not a rendering of these changes.

- Text owns its pending buffer and caret until Enter/focus loss or an explicit
  action commits it. Candidate validation rejects invalid state before preview
  mutation and keeps the last valid preview.
- The canonical pitch range matches installed native creation (-100..100).
  Slider drags commit once on release. Audio changes preserve inventory, visual
  caches and portrait descriptors. Voice preview owns an actorless UI sound.
- Compact fields retain disabled controls for derived values, with native lock
  icons and explanatory tooltips. Gender uses male/female icon toggles.
- Loadout uses grouped equipment tiles and a shared paged Item Explorer with
  search, mod/module/category/compatibility filters, details and explicit equip
  actions. Loaded vanilla/mod scripts are discovered dynamically; native items
  are created lazily. Exact existing clothing state survives individual edits.
- New NPCs use stable randomized clothing. Older named presets materialize once
  into preview-only exact clothing; saved intent and explicit empty outfits stay
  valid. Native capture uses an unregistered descriptor.

`TEST_VERIFIED`: **51/51** focused authoring/inventory tests; full suite
**1044/1048**. The same four recorded failures remain: animation scene debug
routes, context debug scene lab, population director initialization, and the
Debug Hub translation expectation. Six new regressions cover real form commits,
pending text, catalog paging, explorer geometry/modal input, pitch release and
owned UI audio. Existing model/loadout/cache tests cover the remaining changes.

`STATIC_ONLY`: all 44 owned Lua files parse; all 30 production Lua files pass
Kahlua error checks. JSON, EN/TL key parity, PNG validation and whitespace checks
pass. Installed PZ 42.22.2 Lua/Java APIs were inspected. The graph is a committed
baseline; dirty/new source was inspected directly where coverage was stale.

Next responsibility: **P6 user-owned native acceptance of P5R4** using the matrix
in [NATIVE_REGRESSION_AUDIT_AND_PLAN.md](NATIVE_REGRESSION_AUDIT_AND_PLAN.md).
Native typing/hit testing, audible sound, rendered geometry and SP/MP/co-op
outcomes have not been established by the developer harness. No native game
was launched or driven, and no remote push or Workshop publication occurred.

### P5R3 — preceding implementation

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

Historical next chunk at that checkpoint: **P6 native acceptance of P5R3**. Open both
creators in a fresh Build 42.20 session. Verify left roster selection, every tab,
compact preview and font scaling, slot equip/replace/clear, bags and contents,
Save/Load/Produce, companion finalization and SP/MP/co-op lifecycle. Native PZ
was not launched, driven or required for developer acceptance. That native run exposed the regressions repaired in P5R4; it is historical evidence.


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

**P6 — user-owned fresh-session backpack-color retest after P5R11, then the
loadout/audio/CRUD, skin/save/library and SP/MP/co-op matrices. Developer-side
P5R11 gates pass; native rendering/audio/lifecycle acceptance remains open.**

## Repository safety

ProjectHoomans and PsychopatzCore remain on existing `main` branches. Current
ProjectHoomans pre-P5R11 HEAD observed is
`5ced43e44d957ff1fe090cb16cc224d3d4aeabbd`.
The worktree contains unrelated active semantic/UI edits; preserve them. No new
branch, push, Workshop publication, reset, stash, broad staging, or agent-run
native PZ validation is authorized. All native regressions were supplied by
the user and are acceptance evidence, not agent-run native tests.
