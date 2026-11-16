# Roadmap — Unified Starting Companion Authoring

**Status:** P5 developer gates complete — P6 native acceptance is user-owned

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
- keep the server authoritative in multiplayer.

Target flow:

```text
CharacterCreationProfession selected traits
        |
        +--> generic character-creation extension notification
        |
        v
Starting Companion creation session
        |
        +--> selected trait IDs -> active companion slots
        +--> player descriptor/social traits -> dynamic preview context
        |
        v
Reusable NPC Blueprint Composer
        |
        +--> sparse authored values
        +--> relationship/player binding policy
        |
        v
NPC Blueprint Resolver
        |
        +--> debug context: manual/no inherited bindings
        +--> starting companion context: relationship + player bindings
        |
        v
Concrete normalized NPC definition
        |
        +--> debug action OR server-authoritative StartingCompanionService
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

**Current state:** documentation created; user review is still the acceptance
boundary.

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

### P6 — Native acceptance

After all developer-side gates pass, perform the user-owned native matrix
unless the user explicitly delegates native control:

- new SP survivor with one and multiple companion traits;
- change Gay/Bisexual and verify Lover preview/final sex;
- change player surname/skin/gender after loading a preset and verify final
  companion inheritance;
- save/load companion presets across different survivors;
- whole-setup, individual-companion, and Unique NPC import workflows;
- verify source indicators and Resolved Preview update without mutating saved
  blueprint intent;
- reopen the editor repeatedly and confirm no reroll until Randomize is used;
- verify Reset, Randomize, and Revert to Preset are distinct;
- verify the final active-companion summary before world entry;
- use the Resolution Inspector to confirm shared field-source traces when
  diagnosing a mismatch;
- MP host + remote client with different companion selections;
- disconnect/reconnect;
- death -> replacement survivor under the same MP account;
- local/co-op character creation;
- missing/invalid customization fallback;
- old save without new customization fields.

**Gate:** native Build 42.20 proves the UI, final bindings, server authority,
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
- Do not launch native Project Zomboid or publish Workshop content unless
  explicitly authorized.
