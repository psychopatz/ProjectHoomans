# Roadmap — Unified Starting Companion Authoring

**Status:** P5R12 save repair and workflow clarity verified — P6 native acceptance pending

**Primary repository:** ProjectHoomans (`main`)

**Participant repository:** PsychopatzCore (`main`) only where a reusable
character-creation extension seam is required. Core must remain free of
Project Hoomans relationship or companion semantics.

## Objective

Allow players to choose and customize NPC companions while creating a new
survivor whenever Project Hoomans starting-companion traits are selected
(Brother, Sister, Married/Lover, Mom, Dad, Friend).

The system must:

- work in singleplayer, multiplayer, and local/co-op character creation;
- reuse the existing NPC authoring/debug creator instead of creating a split
  companion-only NPC editor;
- expose one reusable, context-agnostic NPC blueprint/composer model that debug,
  starting companions, and future authoring surfaces can consume;
- dynamically detect companion trait additions/removals and reconcile the
  visible companion slots without destructive resets;
- save/load companion presets without freezing values that are inherited or
  derived from the current player;
- visibly explain whether important resolved values are Custom, Generated,
  Inherited from Player, Relationship-Derived, or Server-Controlled;
- keep random/generated values deterministic inside a creation session so
  reopening the editor never silently rerolls a companion;
- support versioned whole-setup presets, per-companion templates, and sanitized
  import from existing Unique NPC definitions;
- expose a debug Resolution Inspector backed by the same resolver trace used by
  the normal UI rather than a second diagnostic resolver;
- preserve all current starting-companion relationship behavior, ownership,
  persistence, reconnect idempotence, faction/community assignment, knowledge,
  and relationship baselines;
- keep the server authoritative in multiplayer;
- expose companion customization explicitly from the final **Customise
  Character** screen beside Play rather than surprise-opening it from the
  profession/trait screen;
- preserve the original randomized/deterministic starter behavior when the
  player never authors companion customization;
- make the starting-companion editor a policy-adapted reuse of the same
  human-facing NPC authoring controls/portrait used by the Unique NPC creator,
  not a raw canonical-field/diagnostic table;
- make the character-creation companion window fixed/non-collapsible while
  remaining closeable, responsive, and resizable;
- expose practical preset/template Save/Load actions directly in the companion
  editor;
- offer nameable reusable NPC snapshots for normal world encounters through the
  existing Unique NPC catalog, with singleplayer access, multiplayer admin
  publication, per-world permanent death and reuse across different worlds.

Target flow:

```text
CharacterCreationProfession
    select Brother / Sister / Lover / Mom / Dad / Friend
        |
        v
one creation-session state
    selected companion trait slots + unresolved blueprints
        |
        v
CharacterCreationMain — final player customization
    name / surname / sex / skin / hair / appearance / voice
        |
        +--> COMPANIONS (explicit optional action)
        |       |
        |       v
        |   shared NPC Blueprint Composer
        |       |
        |       v
        |   resolve preview from CURRENT final-player context
        |       |
        |       +--> close -> return to final player screen
        |
        +--> PLAY
                |
                +--> no authored companion customization
                |       -> preserve original default/randomized starter path
                |
                +--> authored companion customization
                        -> validate/stage canonical envelope BEFORE vanilla
                           world transition
                        -> server-authoritative StartingCompanionService
```

## Audit conclusion

### Existing foundation

1. `PNC_StartingCompanionTraits.lua` already owns six canonical companion
   trait definitions and their relationship rules.
2. Current relationship policies already contain dynamic semantics:
   - Brother: male, shared surname, shared family appearance.
   - Sister: female, shared surname, shared family appearance.
   - Mom: female, shared surname, shared family appearance.
   - Dad: male, shared surname, shared family appearance.
   - Married/Lover: sex derived from player sex + orientation, shared surname.
   - Friend: current default sex is deterministic/random and surname is
     independent.
3. `PNC_StartingCompanionService` already owns durable spawn, recruitment,
   ownership, relationship, knowledge, faction/community, reconnect, and
   character-UUID idempotence.
4. The server stores starter grants by **player character UUID**, which is the
   correct multiplayer ownership boundary.
5. Vanilla Build 42.20 uses `CharacterCreationProfession` for the normal trait
   screen. `CoopCharacterCreationProfession` derives from it, so one reusable
   extension can cover both normal and local/co-op creation.
6. The existing Unique NPC editor already provides name, gender, archetype,
   appearance, clothing/equipment, skills, traits, portrait preview, JSON
   storage, save/load, and randomization.
7. The Unique NPC draft is currently client-oriented and requires a concrete
   surname and boolean `isFemale` before validation. That is too resolved for
   dynamic starter presets and must be generalized rather than copied.
8. Current starter resolution reads the selected companion traits once and
   sets `state.resolved = true`. After that it deliberately stops rereading
   the live trait set. This is correct after character creation/reconnect, but
   it is not a character-creation editing model.
9. The existing root Lua test harness already covers trait registration,
   character-creation trait injection, starter state normalization, starter
   grants, persistence, relationship-key repair, and reconnect idempotence.
   Focused starter/trait tests passed during this P0 audit.

### Current split that this goal must remove

There are currently different surface-specific layers around NPC creation:

- the Unique NPC debug/editor owns a concrete client draft and storage;
- raw debug spawning can call `PNC.API.Spawn` directly;
- starting companions construct identity separately inside
  `StartingCompanionService`.

The goal is **not** to force all actions through a debug command. The goal is
to make the *authoring/definition path* single and reusable:

```text
one blueprint schema
one resolver/compiler
one concrete-definition validation path
one reusable composer control set
many policy/action adapters
```

Debug permissions and production multiplayer authority remain different action
adapters, but they must not maintain different NPC model logic.

## Dynamic inheritance requirement

A preset must store author intent, not the resolved values from the survivor
who happened to create it.

Example:

A Brother preset saved by survivor "Morgan Reyes" must not permanently save
"Reyes", Morgan's skin color, or a resolved body texture as authored Brother
values. When loaded by "Taylor Cruz", the Brother must resolve to Cruz and
Taylor's family appearance according to the same current relationship policy.

Likewise, a Married/Lover preset must not freeze a sex chosen from the previous
survivor. The concrete lover sex is derived from the **current** survivor sex
and current social-trait orientation:

- straight -> opposite sex;
- gay -> same sex;
- bisexual -> deterministic relationship roll, preserving current behavior.

The client preview may show a resolved value, but the preset and MP request
must preserve the binding/intent so the authoritative resolver can recompute it.

## Phases and gates

### P0 — Documentation and evidence baseline

Create this job package from direct source inspection. Record current seams,
constraints, test evidence, dynamic inheritance rules, no-split requirement,
SP/MP authority, and implementation order.

**Gate:** README, ROADMAP, ARCHITECTURE, RUNBOOK, PROGRESS, and HANDOFF agree on
one blueprint/resolver architecture and explicitly forbid a companion-only
clone of the debug NPC model.

**Current state:** accepted baseline; subsequent phases P1–P4 and the P5R
final-screen lifecycle repair were implemented and locally committed. Native
acceptance then exposed the P5R2 shared-editor usability gap, so developer work
is reopened before P6 resumes.

### P1 — Canonical NPC authoring schema, blueprint, and resolver contract

Generalize the current Unique NPC draft/definition model into a reusable
Hoomans-owned authoring contract. Start by establishing one canonical NPC
authoring field registry/codec used by Unique NPC, starting companions, preset
storage, compact network encoding, and the resolver. Do not let each surface
maintain its own field list.

The reusable model must distinguish:

- sparse authored values;
- generated/default values;
- context-derived bindings;
- mandatory authoritative fields.

The field registry defines stable logical field IDs, value type/normalizer and
bounds, whether a field may be authored/persisted/networked, binding capability,
lifecycle metadata, and an optional explicitly assigned compact wire code. Stable string field IDs are persisted; compact numeric wire
codes are protocol-scoped and are never inferred from table order or reused for
a different field. Registry-driven codecs replace surface-specific serializer
field lists so a new registered variable cannot silently disappear from one
consumer.

Existing split names in the current codebase are conversion targets, not a
permanent compatibility contract. Examples include `displayName/name`,
`forename/firstName`, `surname/lastName`, `nickname/alias`,
`skillLevels/skillBaseLevels`, `vanillaTraits/physiologicalTraits`, and
`inventoryTemplateRef/startingInventoryTemplate`. P1 converts Project
Hoomans-owned code/data to the chosen canonical names and removes the redundant
active-path aliases.

`nickname` is a required first-class identity field and uses
`identity.nickname` as the canonical variable. `alias` must not survive as a
second authored/runtime truth after the cutover.

The canonical sparse blueprint must also distinguish **absent**, **explicit
value**, and **explicit clear**. Explicit clears use a dedicated bounded clear
set/operation rather than overloading Lua `nil`; mandatory relationship
bindings ignore/reject clears that would violate policy.

Use a two-stage validation model:

1. **Blueprint validation** may allow unresolved fields when the active policy
   guarantees a binding (for example surname or sex).
2. **Resolved definition validation** receives concrete name, sex, appearance,
   traits, gear, etc. and must pass the existing canonical NPC normalization
   rules before any spawn/action.

The existing Unique NPC debug editor must move to this shared field registry,
blueprint, and resolver. Its debug/manual policy may require concrete values
where no binding exists. This is a coordinated cutover rather than a legacy
compatibility layer: convert all Project Hoomans-owned Unique NPC definitions,
fixtures, examples, and persistence output to the new canonical schema and
remove obsolete alias/load paths afterward. Old external/user files using the
superseded schema are unsupported unless explicitly converted outside the
runtime.

The current audit found a concrete drift to eliminate: runtime identity already
supports canonical `identity.nickname`, while the Unique NPC draft serializer
currently rebuilds `def.identity` from survivor fields and does not preserve an
authored identity nickname. P1 must fix this through the shared schema rather
than a one-off companion patch.

The resolver must return reusable field-resolution metadata in addition to the
final definition: semantic source, relevant binding/rule, dependencies, and
resolved result where appropriate. Normal UI source indicators and the debug
Resolution Inspector consume that same trace.

Generated/default values use an explicit stable slot/session seed. Rebuilding
or reopening a preview with unchanged blueprint/context/seed must not reroll the
NPC. Only an explicit Randomize operation changes the relevant generation seed.
A deterministic blueprint fingerprint covers normalized sparse values, explicit
clears, seed, and schema version for cache invalidation/deduplication only; it
is never an NPC identity or authority token.

**Gate:** the debug creator behaves through the canonical field registry and
generic blueprint/resolver; all Project Hoomans-owned Unique NPC definitions
and persistence paths use the new schema only; there is no second companion
field vocabulary or draft schema; authored `nickname` round-trips through
Unique draft -> save -> load -> resolve -> runtime as `identity.nickname`;
obsolete aliases such as `alias` are absent from active authoring/persistence
paths; repeated resolution with the same inputs is stable; and the shared
resolver produces a bounded field-resolution trace.

### P2 — Reusable character-creation extension seam

Prefer one generic PsychopatzCore character-creation extension mechanism over
multiple adopter monkey patches if direct source work confirms that it can be
introduced without unnecessary complexity.

The reusable seam may expose bounded notifications such as:

- profession/trait screen created;
- selected trait set changed/repopulated;
- screen shown/hidden;
- build/reset/randomize/load completed.

Project Hoomans registers its starting-companion adapter. PsychopatzCore must
not know companion trait IDs, relationship kinds, PNC services, or Hoomans
preset formats.

If a smaller already-existing hook proves sufficient, do not overbuild Core;
the invariant is one reusable patch point, not a mandatory new framework.

**Gate:** normal and `CoopCharacterCreationProfession` both exercise the same
extension path; other adopters can register without editing the vanilla class
again.

### P3 — Starting companion creation session, composer UI, and presets

Add a character-creation session keyed by companion trait ID.

On every relevant selection change:

```text
previous selected companion traits
current selected companion traits
        -> added
        -> removed
        -> unchanged
```

Rules:

- added trait -> create/activate one slot with a new/default blueprint;
- unchanged trait -> preserve the user's current blueprint;
- removed trait -> deactivate it but keep a temporary session cache;
- re-added trait in the same session -> restore the cached blueprint;
- final request includes only traits actually selected.

The companion UI must reuse the generic NPC composer controls. Context policy
controls which fields are editable, inherited, derived, hidden, or locked.
Important resolved fields expose a compact source indicator such as Custom,
Generated, Inherited from Player, Relationship Rule, or Server Controlled.
The UI keeps Blueprint/Intent distinct from the Resolved Preview for the current
survivor.

Per-slot actions are distinct: Randomize changes the deterministic generation
seed while preserving mandatory bindings; Reset clears authored customization
back to Hoomans defaults; Revert to Preset restores the loaded preset/template
baseline when present. Before character creation commits, show a compact final
summary of the active selected companion slots.

Presets use a dedicated schema ID plus explicit integer version and must never
depend on vanilla `saved_builds.txt` for rich NPC data. During this feature
cutover, all Project Hoomans-owned preset/definition data is written directly in
the new schema; do not add legacy migration scripts or compatibility fixtures.
Preset storage supports whole companion setups and individual companion
templates, and may use the existing Hoomans
definition database or a compatible extension of it.

A starter preset contains sparse blueprints/intent, stable slot keys based on
canonical companion trait ID, and stable generation state where required. It
never stores runtime NPC IDs or resolved mandatory inherited fields. Loading a
preset must not bypass trait point costs or silently add traits. Matching
selected slots receive preset content; inactive whole-setup slots may remain
dormant until their trait is selected.

Existing Unique NPC definitions may be imported as source templates only through
the same starter sanitizer used for application. Import must show a sanitization
preview/report for fields that will be removed, rebound, regenerated, or kept.

**Gate:** add/remove/re-add, Reset, deterministic Randomize, Revert to Preset,
vanilla build load, whole-setup/per-slot preset load, sanitized Unique NPC
import, and co-op all reconcile without losing unchanged edits; source
indicators explain effective values; presets use the new canonical schema and
remain dynamic across different player surnames, appearance, sex, and
orientation.

### P4 — Authoritative SP/MP handoff and starter-service integration

Add a dedicated production starter-customization request/submit path. Do not
use a debug command as production authority.

The client sends only the bounded blueprint/intent for selected companion
traits. Compact envelopes include an explicit protocol version and canonical
registry compatibility fingerprint. An incompatible client/server field codec
fails the customization as a whole and uses the normal bounded fallback rather
than partially decoding a different schema.

The server independently re-reads the actual player traits and rejects or
ignores:

- companion slots without the corresponding trait;
- client-supplied runtime NPC IDs;
- player/owner UUID or username authority;
- faction/community membership authority;
- relationship kind overrides;
- runtime positions;
- debug flags;
- other fields outside the allowed starter blueprint contract.

The server resolves dynamic bindings from the **actual final player** and
server social profile, then feeds the concrete result into the existing
`StartingCompanionService`.

Handle the MP race where server `OnCreatePlayer` currently calls
`StartingCompanions.Ensure` before the client can deliver its customization.
Use a bounded pending/received/defaulted handshake and retain the existing
deterministic default generator as fallback when no valid customization
arrives.

Singleplayer should call the same submit/resolve service directly rather than
implementing separate rules.

**Gate:** SP and MP produce identical concrete definitions for identical
player/context input; spoofed client authority is rejected; reconnect never
duplicates grants; old/no-customization clients fall back safely.

### P5 — Harness and regression expansion

Extend existing tests; do not create a new generic PZ harness.

Required synthetic coverage:

- canonical authoring-field registry coverage for every Unique/companion
  authorable field;
- canonical-field cutover removes redundant active-path aliases from Project
  Hoomans-owned code/data;
- `nickname` Unique draft/save/load/resolve/runtime round-trip using only
  canonical `identity.nickname`;
- compact wire-code encode/decode uses explicit immutable codes and protocol
  versioning rather than array position;
- absent vs explicit-value vs explicit-clear semantics survive save/load and
  compact encode/decode without allowing clears to defeat mandatory bindings;
- serializer/codec coverage is registry-driven so newly registered persistable
  fields cannot be silently omitted;
- registry/protocol fingerprint mismatch rejects the MP customization envelope
  atomically and reaches the safe default fallback;
- deterministic blueprint fingerprints remain stable for equivalent canonical
  blueprints and change when authored value/clear/seed/schema changes;
- generic blueprint validation vs resolved definition validation;
- stable field-source/resolution traces from the shared resolver;
- deterministic preview resolution and explicit Randomize seed changes;
- debug Resolution Inspector consuming the shared resolver trace;
- debug editor cutover and canonical-definition parity;
- character-creation extension callbacks for normal + co-op inheritance;
- trait add/remove/re-add reconciliation;
- social trait orientation changes updating Lover preview/resolve;
- final surname/appearance changes resolving from the final player;
- per-relationship binding matrix;
- canonical preset round-trip without frozen inherited values;
- whole-setup and per-slot template persistence;
- Unique NPC import sanitization/reporting and runtime-ID stripping;
- Reset vs Randomize vs Revert-to-Preset semantics;
- final companion summary reflects only selected active slots;
- server request sanitization/spoof rejection;
- request-before/after lifecycle ordering;
- timeout/default fallback;
- reconnect/reload idempotence;
- old save normalization;
- unchanged starter relationship/faction/knowledge behavior.

Update the existing root Lua harness stubs or PsychopatzCore test support only
where the new reusable seam needs it. Do not introduce a second harness runner.

**Gate:** focused tests pass, changed Lua compiles/verifies using existing
repository tools, and no regression requires a parallel debug/gameplay model.

### P5R — Final-screen entry-point and optional-customization repair

Native Build 42.20 user testing after the original P5 checkpoint exposed a
missing end-to-end UX journey. The existing adapter opens the composer only on
`CharacterCreationProfession.screen_shown`. If no companion trait is active at
that instant, `OpenComposer()` returns `no_active_companions`; later trait-set
reconciliation does not reopen it. The implementation can therefore pass
headless/session tests while the real feature remains undiscoverable.

The current final Play hook also invokes vanilla `NEXT` before calling the
starter customization submit path. Vanilla can already hide the creation
screen, initialize the player, create the world, and transition to
`LoadingQueueState` before Hoomans stages customization. That ordering is not
an acceptable commit boundary.

P5R must repair the flow without replacing the accepted authoring/resolver and
server-authority foundations:

- remove automatic composer navigation from profession-screen visibility;
- add an explicit **COMPANIONS** action beside **PLAY** on
  `CharacterCreationMain` and its local/co-op equivalent;
- keep one creation session across profession screen, final player screen, and
  companion composer; screen object identity must not create a second session;
- on every Companions open, re-read the actual selected companion traits and
  current final player descriptor, reconcile the existing session, and rebuild
  previews from current surname/sex/appearance/orientation;
- companion customization is opt-in: merely selecting a companion trait does
  not create an authored customization request;
- opening and closing the composer without changing anything still preserves
  the original default/randomized starter path;
- authoring a field, loading a preset/template, importing/sanitizing a Unique
  NPC, or explicit Randomize marks the relevant customization as authored;
- Play performs Hoomans validation/staging **before** vanilla commits the
  character/world transition; invalid explicitly-authored customization keeps
  the user on the final character screen with a useful error;
- no-authored-customization must never block Play and must clear/avoid stale
  envelopes so `StartingCompanionService` uses its established default path;
- MP may still transmit after an `IsoPlayer` exists, but the validated intent
  must already be staged before leaving character creation;
- normal and `CoopCharacterCreationMain` must share the same semantic action
  and session ownership even though co-op overrides `onOptionMouseDown`.

Required developer-side UI journey coverage:

1. no companion trait -> Companions unavailable/disabled -> Play succeeds;
2. companion trait selected, composer never opened -> no authored envelope ->
   original default/randomized starter behavior;
3. companion trait selected -> Companions visible/enabled -> editor opens ->
   edit -> close -> Play -> authored request staged;
4. open/close without edits -> remains default path;
5. edit companion -> change player surname/sex/appearance -> reopen -> same
   blueprint resolves against the new final player context;
6. Lover preview responds to current orientation/player sex;
7. Back to profession -> remove/re-add/change companion traits -> return to
   final screen -> same creation session reconciles without lost unchanged edits;
8. Randomize marks customization authored and remains deterministic thereafter;
9. invalid authored data prevents vanilla transition and explains the failure;
10. local/co-op follows the same Companions action and commit semantics;
11. SP/MP default path still reaches canonical starter generation;
12. MP authored path still follows the P4 handshake without duplicate grants.

**Gate:** accepted in the local P5R phase commit. Automated/UI-harness evidence
proves the button is reachable and the entire profession -> final customization
-> optional companion editor -> Play journey works for default and authored
paths in normal + co-op creation. The submit order is pre-commit, one session
survives the screen transition, and the existing default/randomized path is
unchanged when customization is skipped. Native validation is deferred to P6.

### P5R2 — Shared authoring UI parity and companion-editor usability repair

Native Build 42.20 acceptance after P5R confirms the final-screen **COMPANIONS**
entry point now opens successfully, but the actual editor is not yet acceptable.
The tested window exposes internal canonical field IDs, `[absent]` states,
`<table>` values, registry source labels, and unrelated authorable fields rather
than a usable character editor. It has no rendered NPC portrait, no accessible
Save/Load workflow, and uses the normal collapsible/pinnable window behavior.

`CODE_VERIFIED` audit explains the gap:

- `PNC_StartingCompanionComposerWindow.lua` builds a separate lightweight UI
  directly from `NPCAuthoringComposer:FieldRows()` rather than reusing the
  Unique NPC editor's General/Appearance/portrait controls;
- `FieldRows()` enumerates every registry field marked `authorable`, while the
  starter relationship policy mostly expresses bindings/authority rather than a
  human-facing field presentation set, so unrelated fields such as jobs,
  hostility, patrol/map/combat metadata can leak into the normal editor;
- the window displays `slot.spec.uiName` and trait IDs without consistently
  resolving translations, exposing keys such as `UI_PNC_Trait_HasBrother` and
  IDs such as `PNC_HasBrother`;
- the existing Unique NPC editor already owns the useful form controls, tabs,
  appearance editor, trait/skill selectors, portrait preview, persistence
  actions, and deterministic preview refresh behavior;
- starter preset/template persistence already exists through
  `StartingCompanionPresets` and `StartingCompanionPresetStore`, so Save/Load is
  missing UI integration rather than missing storage infrastructure;
- PsychopatzCore already provides `PsychopatzFixedWindow`, explicitly removing
  native pin/collapse controls while retaining shared window behavior.

P5R2 must finish the original no-split UI objective without discarding the
accepted P1-P5R data/lifecycle foundations:

1. extract/refactor the useful Unique NPC editor body into a reusable authoring
   presentation component owned by Project Hoomans;
2. make both the debug Unique NPC creator and starting-companion editor consume
   that same reusable editor component rather than maintaining separate primitive
   character-editing controls;
3. preserve different outer action adapters: debug may keep New/Load/Save/
   Produce/Inventory, while starting companions use slot selection, Load, Save
   Template, Save Set, Randomize, Reset, Revert, Close;
4. reuse the same portrait/preview machinery so name, appearance, outfit, voice,
   traits, and skills visibly update the NPC without rerolling the deterministic
   seed unless Randomize is explicitly used;
5. expose canonical `identity.nickname` as a normal shared General-field control
   in both authoring surfaces;
6. add a reusable authoring presentation schema/capability layer that maps
   canonical fields to human labels, appropriate control types, grouping/order,
   and visibility while the relationship policy separately supplies locking,
   inheritance, derivation, allowed values, and authority;
7. do not hide dozens of fields through companion-specific ad hoc conditionals;
   irrelevant advanced/runtime fields simply are not part of the normal starter
   presentation profile, while the raw resolver trace remains available through
   the Resolution Inspector/debug diagnostics;
8. inherited/derived starter fields remain visible where useful but read-only,
   with compact human-readable explanations such as `Inherited from Player` or
   `Relationship Rule`; never show raw `[absent]`/internal IDs as the primary UX;
9. resolve all trait/relationship labels through translations and present human
   names rather than `PNC_*`/`UI_*` implementation keys;
10. make the starting-companion editor use `PsychopatzFixedWindow` or the
    equivalent existing Core primitive so pin/collapse controls cannot appear;
11. wire the already-existing starter preset store into the companion UI:
    **SAVE** saves the selected companion template, **SAVE SET** saves the whole
    current setup, and **LOAD** applies compatible canonical presets/templates;
12. preserve P5R opt-in semantics: inspecting/opening/closing the richer editor
    still does not author customization unless the canonical blueprint actually
    changes; save-only operations should not accidentally alter the spawn intent;
13. keep relationship inheritance, final-player rebinding, P4 authority, and
    default/no-customization behavior unchanged.

Required developer-side P5R2 evidence:

- debug and starting-companion surfaces instantiate the same reusable authoring
  editor/presentation component;
- companion window is fixed/non-collapsible and has no visible pin/collapse
  control;
- companion editor has a real rendered portrait preview using the existing
  preview/runtime-record path;
- General and Appearance controls are human-facing controls, not raw field IDs;
- nickname is editable through the shared canonical field;
- hair/beard/skin/outfit/voice controls behave like the debug editor where
  policy permits them;
- skill, NPC trait, vanilla trait, and dynamic trait controls are available when
  allowed by the starter presentation/policy;
- Brother/Sister/Mom/Dad/Lover bindings appear locked/read-only with correct
  resolved values and source explanation rather than editable duplicates;
- Friend/default-unbound fields remain editable according to policy;
- translated companion/relationship labels contain no raw `PNC_*` or `UI_*`
  keys in normal presentation;
- selected-template Save, whole-set Save, and Load work through the existing
  canonical preset store;
- preview updates in place for edits/rebinding and only explicit Randomize
  changes generation state;
- raw resolution details remain available through the Resolution Inspector but
  are not the default form;
- existing P5R final-screen/default/pre-commit journeys remain green.

**Gate:** P5R2 is accepted only when the debug creator and companion editor
share the same reusable authoring presentation component, the companion editor
is visually/practically usable with portrait + real controls + preset actions,
relationship policy modifies that shared editor rather than replacing it, and
all P1-P5R behavior remains verified. Native P6 resumes only afterward.

**Developer gate result:** R1-R5 are accepted in the local Project Hoomans
repair commit. The shared component now uses the real vanilla combo callback
contract and one atomic selected-slot transaction; preview identity and
invalidation cover slot, blueprint, seed, and relevant context; General and
Appearance use character-creation composition with visible collections,
bounded Advanced Clothing Overrides, and explicit no-selection clearing. The
definition-index `files` initialization repair remains accepted. Full harness
verification is 1035/1039, with four unrelated documented failures. Native
SP/MP/co-op acceptance remains user-owned.

### P5R2-R1 — UI event and selected-slot state correctness

Fix the real native event contract before further visual polish.

Vanilla `ISComboBox` invokes change callbacks as `onChange(target, combo, ...)`.
The current starting-companion host assigns `combo.target = window` but its slot
and preset callbacks treat the first argument as the combo. Native selection can
therefore change the visible dropdown while clearing or retaining the wrong
internal `selectedTraitID`/`selectedPresetFile`.

R1 requirements:

- use the real vanilla combo callback signature for companion-slot and preset
  selection;
- centralize companion selection through one bounded method such as
  `SelectCompanion(traitID)` rather than duplicating state mutation in callbacks;
- validate the chosen trait ID against the currently active session slots;
- on valid selection, atomically update selected trait ID, adapter, shared
  editor draft, form controls, summary/current selection, status, and portrait;
- on invalid/no selection, clear or hide stale editor/portrait state rather than
  leaving the previous companion visible;
- make Load/preset selection obey the same event contract;
- Randomize, Reset, Revert, and Load must target the same currently-selected
  slot visible in the UI and must never silently no-op because the selector and
  internal state diverged.

**R1 gate:** a native-style UI harness invoking the real
`onChange(target, combo, ...)` signature proves Brother -> Sister and preset
selection update internal IDs and all visible state atomically.

### P5R2-R2 — Preview identity and invalidation correctness

Make preview freshness an explicit contract rather than relying on scattered
`previewDraft = nil` / `force = true` calls.

The effective preview identity must include the active companion slot plus the
state that can change its resolved visual result, including at least:

- canonical companion trait ID;
- canonical blueprint fingerprint;
- generation seed;
- current player/context fingerprint relevant to bindings.

Switching companion slots or explicit Randomize must invalidate/rebuild the
preview runtime record. Ordinary same-slot edits should preserve deterministic
fallback values and update in place. Player surname/sex/appearance/orientation
rebinding must update the same companion preview without mutating blueprint
intent.

The form, relationship summary, current selection, resolved draft, portrait
spec/target, and status must always describe the same active slot and preview
identity.

**R2 gate:** tests prove slot switch changes portrait/form identity, Randomize
changes seed and preview identity, ordinary edits do not reroll, and context
rebinding updates inherited/derived values deterministically.

### P5R2-R3 — General-tab character-creation UX

The shared primitive editor remains shared, but the companion presentation must
be reorganized for character creation instead of inheriting debug layout gaps.

Use a scrollable/sectioned normal companion presentation such as:

- Identity — first name, nickname, human read-only surname/gender source rows;
- Background — archetype/equipment choices where policy allows;
- Skills — visible currently-added skills with level and Remove, plus an Add
  control;
- Traits — visible currently-added NPC/vanilla/dynamic traits with Remove, plus
  Add controls.

Do not hide the normal configured-skill/trait list while leaving only Add
controls. Locked relationship fields should look read-only and explain the
source; they should not look like enabled dropdowns merely disabled by policy.
Avoid large dead regions created by hidden debug-only controls.

**R3 gate:** a player can inspect, add, and remove every supported skill/trait
without opening the Resolution Inspector, and representative window sizes/UI
scales remain usable without overlap or unusable empty regions.

### P5R2-R4 — Appearance workflow UX

Keep the shared appearance engine, but separate common character creation from
advanced equipment-slot authoring.

Normal Appearance should prioritize:

- outfit;
- skin;
- hair;
- beard where applicable;
- voice/style/sample/pitch;
- other high-value appearance controls already supported by the shared model.

Per-body-location overrides move under an explicit **Advanced Clothing
Overrides** section/panel. Translate/group native body locations where possible
and do not expose raw/internal `base:*` slot IDs as the normal experience.
The advanced list must own its own bounded scrolling area and must not collide
with the companion summary/footer/portrait.

**R4 gate:** the normal Appearance tab is concise and understandable; advanced
clothing remains available without overwhelming or clipping the primary flow.

### P5R2-R5 — Native-style UI interaction and layout harness

Extend the existing harness rather than creating another framework.

Required interaction coverage includes:

1. construct the real companion window with multiple active slots;
2. invoke slot combo change using vanilla `onChange(target, combo)` semantics;
3. assert selected trait ID, adapter trait ID, form gender/name, summary, status,
   and portrait target/spec all move to the new companion;
4. invoke Randomize and assert generation seed + preview identity change while
   the selected slot remains unchanged;
5. invoke preset combo with the same native callback contract and prove Load
   applies the selected file;
6. invalid/no active selection clears stale editor/portrait instead of showing
   the previous companion;
7. configured skills/traits are visible and removable in normal General UI;
8. normal Appearance does not expose raw `base:*` slot IDs as the primary list;
9. layout-bound checks cover representative 16:9 and smaller supported window
   sizes/UI scales, with portrait, tabs, footer/summary, and scroll regions not
   overlapping;
10. existing P5R/P4/default/no-op/authored paths remain green.

**P5R2 repair gate:** ACCEPTED for developer-side work. R1-R5 interaction,
layout, preview, policy, persistence, and regression gates pass. The roadmap
now returns to the user-owned P6 native acceptance matrix.

### P5R3 — Shared roster, compact pages and embedded loadout

User-approved implementation of [the UI redesign](UI_REDESIGN_AUDIT_AND_PLAN.md).
Developer-side implementation is complete; native acceptance is unverified.

- Both entry points use the same roster, Bio/Appearance/Attributes/Loadout pages,
  preview controls and canonical authoring model. Companion Relationships and
  debug Details use the same page shell with their existing policy differences.
- Exactly one tab page is visible after selection, refresh and empty-selection
  recovery. Roster selection flushes the focused form, keeps its save target
  aligned, and retains per-NPC preview state.
- Loadout edits use canonical appearance/startingItems, icon slot rows, a
  searchable script catalog, quantity/destination controls, attachment resolution,
  explicit clearing and conflict checks. Bags serialize before their contents.
- Pending slot edits take precedence over retained preview inventory; unchanged
  previews do not rebuild inventory. Companion snapshots include startingItems.
- Layout wraps actions, reserves bounded scrolling and native model-view bounds,
  and provides an expanded preview at compact widths. Hair color presets and
  inherited color locks remain part of shared Appearance.
- Production lifecycle/composition, scale geometry, model materialization,
  transaction rejection, bag and preset round-trip regressions pass. Full Lua
  suite: 1038/1042; the four recorded unrelated failures remain.
- Forty new Character catalog keys have English/Tagalog parity. Changed Lua
  syntax, targeted Kahlua checks, JSON parsing and whitespace checks pass.

**P5R3 gate:** developer-side implementation accepted at its local phase commit.
P6 must verify actual native rendering, interactions and SP/MP/co-op outcomes;
no native visual or multiplayer result is claimed by the harness.

### P5R4 — Native regression repair and equipment explorer

User-authorized implementation of [the native regression repair](NATIVE_REGRESSION_AUDIT_AND_PLAN.md).
Both entry points continue to consume the same editor and canonical model.

- Buffered text with explicit commits, validation rollback and last-valid preview.
- Canonical native pitch range, one commit per drag, audio-independent clothing/
  inventory/portrait invalidation, and owned actorless UI voice preview.
- Compact input geometry, disabled derived controls with native lock/reason
  tooltips, and gender icon toggles.
- Grouped equipment icon tiles and a dedicated paged explorer for loaded vanilla/
  mod items, source/category/search/compatibility filters, details and explicit
  apply actions. Normal loadout authoring does not use dropdowns.
- Stable clothed defaults, exact retained clothing state, and cached preview-only
  materialization of legacy named outfits using unregistered native descriptors.
- Focused tests **51/51**; full suite **1044/1048**, with the same four recorded
  unrelated failures. All owned Lua syntax, production Kahlua checks, EN/TL keys,
  JSON, PNG and whitespace checks pass.

**P5R4 gate:** developer implementation verified; closed by its exact local phase
commit. Native input/rendering/audio and P6 lifecycle results remain unverified.
Use the revised native matrix in the linked audit; the installed game is PZ
42.22.2 while the packaged runtime directory remains 42.20.

### P5R5 — Randomization policy and browser usability repair

User-authorized repair from
[RANDOMIZATION_AND_BROWSER_AUDIT_AND_PLAN.md](RANDOMIZATION_AND_BROWSER_AUDIT_AND_PLAN.md).
Developer-side implementation is complete; native acceptance remains unverified.

- One shared capability excludes companion Random actions/choices and rejects
  stale handler/adapter routes, preserving automatic/default/no-op generation.
- Debug Randomize look releases explicit visual overrides, materializes exact
  new clothing once and updates controls/portrait/slots while retaining unrelated
  biography, attributes, voice and carried/held gear.
- Combo baseHeight, explicit list fonts/row metrics and label-position contracts
  are corrected. Disabled buttons have neutral styling.
- One shared contextual browser presents outfit rows/focused preview, item icon
  tiles, compact presets/scope and searchable attribute choices. Apply/Cancel,
  invalid/filtered selection, contextual quantity/destination and empty states
  have production-boundary coverage.
- Skills/trait groups use bounded controls and local removal; font/viewport
  matrices exercise stacking, scrolling and browser modes.
- Focused suite **55/55**; full suite **1048/1052**, with the same four known
  failures. All 33 Lua syntax/22 production Kahlua checks, JSON, 15 new EN/TL keys,
  static references, parity and whitespace checks pass.

**P5R5 gate:** closed only by the exact local phase commit after these developer
checks. P6 must establish actual native rendering/input/audio and SP/MP/co-op
outcomes. Registered native outfit names remain available; no guessed test-name
blacklist or fabricated outfit-visibility API was introduced.

### P5R6 — Free companion gender, explicit variation and native frame/audio

The latest native report reopens P5R5 acceptance and clarifies that a wide
quick appearance-variation action is wanted in companion creation. Random
selector policies remain excluded; the explicit action is allowed.

- Free-sex traits use an editable generated default; family/orientation-bound
  gender stays protected. Concrete male/female values round-trip and a body
  change rebuilds its gender-specific generated preview.
- Selected buttons retain their themed background through enable/theme updates.
- The composer reserves the native title bar and the shared editor has a wide
  variation footer, hidden behind modal browsers.
- Companion variation projects concrete editable visuals in one validated
  transaction, retaining biography generation, gender, locks and unrelated data.
- Menu voice follows the native resume/origin sequence and reports localized
  failures, while debug playback preserves paused gameplay audio ownership.
- **56/56** focused, **1049/1053** full suite; same four recorded failures.
  Twenty Lua syntax checks, twelve production Kahlua checks, five new EN/TL
  keys, JSON/static references/parity and whitespace checks pass.

**P5R6 gate:** developer checks verified; exact local phase commit required.
Native rendered/input/audio acceptance remains P6, including the new Friend,
selection-color, title-frame, wide-action and menu-voice retest.

### P5R7 — Per-tab dice and live relationship constraints

The latest request replaces the wide appearance action with dice on Bio,
Appearance, Attributes, Loadout and Relationships. Semantic backstory generation
is explicitly deferred; Relationships explains current meaning and has disabled
TODO dice.

- Each shared page owns a dice control above its form. Bio varies names/nickname
  and preserves chosen body/archetype; Appearance varies editable face/hair/voice;
  Attributes generates compatible loaded skills/traits without companion-selection
  traits; Loadout captures concrete clothing/equipment. Every companion result is
  projected through editable scope fields and committed atomically without
  changing unrelated generation or inherited fields.
- Relationship rows explain NPC-to-player and player-to-NPC roles, originating
  trait and current inherited/independent fields. Long explanations wrap.
- Only actual constraints display locks; current surname/trait/orientation supply
  dynamic explanations. Policy is recomputed from live context. Bisexual Lover
  and Friend sex are editable; fixed and straight/gay rules retain final authority.
- Complete manual candidates commit before repaint; stale locked callbacks are
  rejected. Native tone selection removes stale cached custom skin RGB.
- **58/58** focused and **1052/1056** full suite; the same four known unrelated
  failures. **32** Lua syntax and **22** production Kahlua checks, JSON,
  26 new/one updated EN/TL keys, parity/reference and whitespace checks pass.

**P5R7 gate:** developer verification complete; exact local phase commit required.
Native hit testing, rendering/audio and final SP/MP/co-op behavior remain P6.
Backstory generation is a future feature and not a condition of this repair.

### P5R8 — Native tone, readable locks and reusable character saves

- Reconcile native/materialized clothing exclusivity and prevent stale preview
  garment capture from rejecting unrelated edits. Preserve manual validation.
- Suppress factory RGB when a native texture is explicitly chosen; remove old
  retained-record tint after canonical rebind. Core applies native tone index
  and neutral RGB unless inherited/custom RGB was explicitly provided.
- Keep disabled gender icons readable while preserving native input gating.
- Add a shared editable save-name dialog with NPC-name default. Keep companion
  preset intent sparse and export an independent exact encounter character
  through the same codec/storage as the Unique NPC creator.
- Discover produced characters on the authority into the existing unique pool.
  Preserve normal chance, reservations and per-world permanent death. The user
  explicitly chose reuse across different worlds with no template deletion.
- Prevent client-side automatic MP import. Require admin publication on both
  presentation and server mutation boundaries; server-local files remain an
  administrator-controlled source.
- **62/62** focused Hoomans tests plus Core portrait smoke pass; full Hoomans
  **1055/1059**, same four known failures. Hoomans 24 Lua syntax/17 production
  Kahlua and Core two syntax/one Kahlua checks pass, as do six new EN/TL keys,
  JSON/parity/reference and whitespace checks.

**P5R8 gate:** developer checks verified; participant-then-primary exact local
commits required. Fresh native rendering/input, saved-file reload and MP admin
transport acceptance remain user-owned; see the focused retest document.

### P5R9 — Body-part loadout, carried inventory, framing, voice and CRUD

- Selectable modular body-part views replace the all-slots scroll wall. Native
  exclusivity hides only blocked empty alternatives and clearing restores them;
  unknown mod locations stay reachable. Equipped entries remain clearable.
- Carried inventory owns a distinct list and Add/Edit/Remove/quantity/destination
  workflow over existing canonical startingItems and dynamic item discovery.
- Appearance uses vanilla face zoom/offset in a copied portrait projection;
  other tabs restore body view and independent camera preferences. Preview
  framing never edits appearance, inventory or preset data.
- Menu voice mirrors native PLAYDEMOVOICE's FMOD InGame state and restores
  MainMenu at completion/stop. Debug audio preserves world music state.
- Add saved-record deletion in companion and Unique NPC browsers, with explicit
  two-click confirmation and stale-selection cancellation. Erase payload, remove
  its index entry and retain a non-loadable marker. Preserve other namespaces,
  living actors and world death state. MP library deletion remains admin gated.
- **65/65** focused and **1058/1062** full suite, same four known failures;
  28 Lua syntax/21 production Kahlua, six new EN/TL keys, JSON/parity/reference
  and whitespace checks pass.

**P5R9 gate:** developer verification complete; exact owned local phase commit
required. Native layout/hit testing and audible playback remain user-owned; see
LOADOUT_AUDIO_CRUD_RETEST.md.

### P5R10 — Explorer idle-resize startup regression

The user native retest confirms a nil `options.onDelete` access while the host
resizes its hidden Item Explorer before any Show call. The constructor now
explicitly owns the idle nil-options state; onResize defers until both children
and browsing configuration exist. A new regression covers early/constructed idle
resize, actual host startup and subsequent Show/Delete/Hide behavior.

**Gate:** **66/66** focused and **1059/1063** full (same four known failures), two
Lua syntax checks, one production Kahlua check and whitespace/coverage checks
pass. Exact owned local commit required. Native startup and the previous P5R9
interaction/audio matrix remain P6 user-owned acceptance.

### P5R11 — Preserve backpack visuals across creator edits

The user reports a backpack changing color after other edits. Preview inventory
reconstruction discarded its captured native tint. Retain visual state for the
same item type and logical template/placement across inventory/body rebuilds,
without overriding explicit visuals, new generations or nonvisual state. Keep
this continuity preview-only and share it between both creator hosts.

**Gate:** **67/67** focused; full **1060/1064**, same four known failures. A new
behavioral regression reproduces the tint change with continuity disabled and
passes for ordinary edits, reconstruction and deliberate replacement/reroll
boundaries. Three Lua syntax, two production Kahlua, whitespace and twelve-path
coverage/current-source checks pass. Exact owned local phase commit required;
native backpack-color confirmation remains user-owned P6 acceptance.

### P5R12 — Native save-dialog repair and clear preset scopes

Repair console-confirmed SaveDialog.Open line 29: ISTickBox has disableOption,
not setEnable. Follow installed native filename validation and retain SP/MP admin
publication boundaries, including rechecking authority on submission.

The user explicitly places Save roster preset inside Presets, not the editing
toolbar. Make it available in empty browsers too, preserve reviewed snapshots,
refresh the browser after success and reserve layout space for the action.
Use primary Done for applying companion edits, optional Save NPC preset for a
reusable full NPC, and explicit Equip/Add/Update wording for Loadout. Keep invalid
pending edits open and distinguish debug encounter export from local presets.

**Gate:** **68/68** focused including translation catalogs; full **1060/1064**,
same four known failures. Native-shaped checkbox test reproduces old line 29;
save scope/snapshots, permission changes, filename validation, empty presets,
context-action isolation, geometry and Done validation/audio cleanup pass.
Nine Lua syntax, six production Kahlua, EN/TL parity and whitespace checks pass;
ten new/six updated Character keys. Sixteen repo plus two installed native Lua
evidence paths checked with direct source fallback. Exact local commit required;
native interaction/rendering/audio remains user-owned P6 acceptance.

### P6 — Native acceptance

After all developer-side gates pass, perform the user-owned native matrix
unless the user explicitly delegates native control:

- verify the final Customise Character screen visibly exposes **COMPANIONS**
  beside Play when companion traits are selected;
- verify the companion editor cannot pin/collapse and exposes the shared
  human-facing Unique-NPC-style General/Appearance editor with a real portrait;
- verify human trait/relationship labels are translated and no raw canonical
  field IDs/`PNC_*`/`UI_*` keys dominate the normal editor;
- verify Save selected template, Save whole set, and Load are usable;
- verify nickname, appearance, skills, NPC traits, vanilla traits, and dynamic
  traits use appropriate shared controls where policy allows them;
- verify selecting a companion trait and pressing Play without opening/editing
  Companions preserves the former randomized/default starter behavior;
- verify opening/closing Companions without changes also preserves that default
  path;
- new SP survivor with one and multiple companion traits;
- change Gay/Bisexual and verify Lover preview/final sex;
- change player surname/skin/gender after loading a preset and verify final
  companion inheritance;
- save/load companion presets across different survivors;
- whole-setup, individual-companion, and Unique NPC import workflows;
- verify source indicators and Resolved Preview update without mutating saved
  blueprint intent;
- reopen the editor repeatedly and confirm no reroll until Randomize is used;
- verify companion Reset/Revert and debug Randomize look have distinct behavior;
- verify companion customization exposes no Random policy choices, while the
  per-tab dice changes only its documented scope, including after loading older
  presets; Relationships dice remains disabled with its backstory TODO reason;
- verify repeated gender/skin edits, live orientation changes, constraint-specific
  lock visibility/tooltips and directional relationship explanations;
- verify browser selection, focused outfit preview, Apply/Cancel, grouped
  attributes and compact preset scope using the P5R5 native matrix;
- verify native tone changes remove old tint; disabled selected gender remains
  legible; save filenames default to NPC names and can be edited;
- verify sparse companion presets and independent exact encounter exports,
  produced-only discovery, same-world death/reload and reuse in another world;
- verify remote non-admin cannot publish, admin publication reaches server
  storage/catalog, and ordinary client-local files are never auto-imported;
- verify body-part navigation, native blocked-slot hide/restore and the separate
  carried inventory quantity/destination workflow on both creator hosts;
- verify Appearance face framing and body restoration without data mutation;
- verify audible menu/debug voice, stop/replay, tab/close cleanup and return of
  menu music after completion;
- verify Delete/Confirm delete, filter/selection cancellation, restart/index
  reload, namespace isolation and preserved per-world death/actors;
- verify the final active-companion summary before world entry;
- use the Resolution Inspector to confirm shared field-source traces when
  diagnosing a mismatch;
- MP host + remote client with different companion selections;
- disconnect/reconnect;
- death -> replacement survivor under the same MP account;
- local/co-op final-screen Companions button and character creation;
- invalid explicitly-authored customization remains on the final character
  screen instead of transitioning first;
- missing/no customization fallback;
- old save without new customization fields.

**Gate:** native installed Build 42.22.2 proves the UI, final bindings, server authority,
persistence, and reconnect behavior all reference the same canonical starter
companions.

## Non-goals

- Do not create a second companion-only NPC draft model or companion-only field
  vocabulary.
- Do not keep a legacy debug model and merely copy fields into a new gameplay
  model.
- Do not route production companion creation through debug authorization.
- Do not serialize resolved inherited surname/skin/hair/relationship-derived
  sex as preset authored values.
- Do not let a preset add paid traits or bypass character build points.
- Do not make mandatory relationship bindings user-overridable in the first
  implementation merely because the generic resolver can support future policy
  overrides.
- Do not silently reroll generated values when a preview/editor is reopened.
- Do not persist compact numeric wire codes as the durable preset field identity;
  persist stable string IDs and scope numeric codes to a versioned protocol.
- Do not keep obsolete aliases such as `name`, `firstName`, `lastName`, or
  `alias` in active authoring/persistence code after the cutover.
- Do not maintain hand-written serializer field lists in each authoring surface
  once the canonical registry exists.
- Do not overload missing/`nil` with explicit-clear semantics.
- Do not partially decode a compact MP payload when registry/protocol
  compatibility does not match.
- Do not build a separate diagnostic resolver for the Resolution Inspector.
- Do not trust client ownership, faction, relationship, or runtime identity
  fields in MP.
- Do not replace the existing StartingCompanionService spawn/relationship
  lifecycle with the editor.
- Do not create a separate SP implementation and MP implementation.
- Do not auto-open the companion composer merely because a profession/trait
  screen became visible.
- Do not key the logical creation session to one UI screen object.
- Do not generate/send a customization envelope merely because a companion
  trait is selected or the composer was opened and closed unchanged.
- Do not call vanilla Play/NEXT before validating/staging explicitly-authored
  companion customization.
- Do not treat `NPCAuthoringComposer:FieldRows()` or the raw resolver trace as
  the normal player-facing character editor.
- Do not maintain a second set of primitive name/appearance/trait/skill editor
  controls solely for starting companions after P5R2.
- Do not hide registry leakage with a growing companion-only deny list; use the
  shared presentation schema/profile plus relationship policy.
- Do not remove the Resolution Inspector; raw field/source diagnostics belong
  there rather than in the default form.
- Do not launch native Project Zomboid or publish Workshop content unless
  explicitly authorized.
