# Architecture — Unified Starting Companion Authoring

## Governing rule

**There is one NPC authoring model and one concrete-definition resolution
pipeline. Debug creation and starting-companion creation are policy/action
adapters over that model, not separate NPC systems.**

## Layering

```text
Reusable character-creation extension seam
                    |
                    v
        adopter/session adapters
          /                   \
 debug/unique NPC          starting companion
 authoring policy          relationship policy
          \                   /
           v                 v
              NPC Blueprint
        (sparse authored intent)
                    |
                    v
          NPC Blueprint Resolver
      (blueprint + context + policy)
                    |
                    v
     concrete normalized NPC definition
          /                   \
  debug-authorized action      server-authoritative
                               starter service
```

The action layer may differ because permissions differ. The blueprint schema,
field semantics, resolution, and concrete validation must not.

## Canonical NPC authoring field registry

Unique NPC and starting companions must share one field vocabulary. The registry
is the authoritative description of authorable NPC fields and is consumed by
serializers, preset persistence, import sanitization, network codecs, composer
controls, and resolver tracing.

Each registry entry should contain at minimum:

- stable logical string ID;
- canonical runtime/definition accessor or adapter;
- value type and normalizer/limits;
- authorable/persistable/networkable flags;
- whether relationship/context binding is allowed;
- optional explicit compact wire code and protocol introduction version.

The registry's logical ID is the only active authoring identity after cutover.
Project Hoomans-owned Unique NPC definitions and code are converted to this
canonical model rather than keeping old physical table shapes readable forever.

Serializers, deserializers, sanitizers, and compact codecs should enumerate the
registry by capability instead of maintaining independent hard-coded field
lists. A newly registered persistable field must therefore automatically enter
the canonical serializer path unless its descriptor explicitly opts out. UI may
still choose which registered fields to display for a given policy, but it must
not redefine their storage semantics.

Initial identity canon:

| Logical field | Canonical meaning/location | Cutover rule |
| --- | --- | --- |
| `identity.forename` | `identity.survivor.forename` | remove `firstName` authoring alias |
| `identity.surname` | `identity.survivor.surname` | remove `lastName` authoring alias |
| `identity.nickname` | `identity.nickname` | remove `alias`/survivor nickname duplicates |
| `identity.isFemale` | resolved `identity.isFemale` | use the canonical registry accessor |
| `identity.displayName` | resolved `identity.displayName`; normally derived from name parts | remove duplicate `name` authoring truth |

The same cutover applies to existing split pairs such as
`skillLevels/skillBaseLevels`, `vanillaTraits/physiologicalTraits`, and
`inventoryTemplateRef/startingInventoryTemplate`: choose the registry canonical
field, convert owned code/data, then remove the redundant active-path name.

`identity.nickname` is canonical. `alias` is not retained as an authoring or
persistence compatibility field.

### Sparse value and explicit-clear semantics

Sparse data needs three distinct states:

1. **absent** — the user did not author the field; policy may inherit, derive,
   or generate it;
2. **value** — an explicit authored value exists;
3. **clear** — the user explicitly requests no value, but only where policy
   permits an explicit empty/none state.

Lua `nil` cannot safely represent both absent and explicit clear through JSON
round-trips. The canonical blueprint should therefore represent explicit clears
separately, for example with a bounded `clears` set keyed by stable field ID.
A clear never overrides a mandatory relationship binding. This is especially
important for fields such as beard, hair/style choices, optional nickname,
voice overrides, outfit slots, and equipment selections.

### Compact representation safety

Compactness is a codec concern, not a second schema. Durable presets/Unique
files use stable string field identities and sparse canonical values. Internal
compiled/network forms may use explicitly assigned numeric wire codes, but:

- codes are declared in the same registry;
- codes never depend on Lua array/order position;
- a code is never reassigned to a different semantic field;
- protocol/schema version gates decode behavior;
- decode always produces the same canonical blueprint before resolution.

This permits compact MP payloads without making the Unique NPC system consume a
different data model.

Field IDs and wire codes have a lifecycle. Removed/deprecated codes are never
reassigned to a different meaning. Registry entries
should record the schema/protocol version that introduced and, if applicable,
deprecated a field or wire code.

### Registry/protocol compatibility fingerprint

The canonical registry should expose a deterministic compatibility fingerprint
from its stable network-visible descriptors. MP customization envelopes include
a protocol version and compatible registry fingerprint. The server never
partially interprets an incompatible compact payload: it rejects/defaults the
customization through the normal fallback path and emits bounded diagnostics.

This fingerprint is compatibility metadata, not security authority. The server
still validates every decoded field and recomputes authoritative/inherited
values.

### Blueprint fingerprint

A normalized blueprint may expose a deterministic fingerprint/hash over its
canonical sparse values, explicit clears, seed, and schema version. It is useful
for preview-cache invalidation, stale-editor detection, request deduplication,
and diagnostics. It is not a runtime NPC ID and must never replace server
ownership or authorization checks.

## Blueprint contract

A blueprint is an unresolved, serializable description of author intent. It
must be safe to keep in a preset and safe to send through a bounded MP request.

A blueprint may contain only registry-defined canonical fields, including:

- authored forename/name intent;
- authored canonical nickname intent (`identity.nickname`);
- authored hair/beard/style choices;
- appearance/outfit choices that are not mandatory relationship inheritance;
- archetype where allowed;
- NPC/vanilla/dynamic traits where allowed;
- skills;
- equipment/starting-item intent where allowed;
- other generic NPC authoring fields explicitly supported by policy.

A blueprint does **not** own:

- runtime NPC ID;
- player character UUID;
- owner username/online ID;
- faction/community membership authority;
- relationship kind authority;
- runtime position/body lease;
- debug authorization;
- grant status;
- canonical starter state.

Those are supplied by the action/context owner after blueprint resolution.

## Field-state model

Do not infer whether a value is authored merely because a resolved preview
contains it.

Each effective field is one of these semantic sources:

1. **explicit** — authored by the user/preset;
2. **generated** — deterministic/default NPC generation;
3. **inherited** — resolved from the current player/context;
4. **derived** — computed from policy + current context;
5. **authoritative** — supplied only by the server/action owner.

The serialized blueprint stores explicit intent plus enough schema metadata to
preserve unresolved behavior. It does not need to serialize every inherited or
derived value.

The resolver returns bounded source metadata for explainable fields: semantic
source, binding/rule ID, relevant dependency keys, resolved value, and current
editability where appropriate. UI labels and debug inspection consume this
metadata; they must not independently rediscover why a field has a value.

## Dependency/invalidation model

Dynamic preview updates are dependency-driven rather than surface-specific
if-statements. Examples include `player.surname -> family/lover surname`,
`player.sex + social.orientation -> lover sex`, player skin/hair fields ->
family appearance, and `slot.generationSeed -> generated/default fields`.
Changing a dependency invalidates affected resolved preview values without
rewriting the unresolved blueprint or preset.

## Deterministic generation contract

Every generated/random preview field resolves from an explicit stable seed
owned by the slot/session context. Reopening or rebuilding the preview with the
same inputs returns the same result. Randomize explicitly changes the seed.
Seeds are generation inputs only; they are never runtime NPC IDs or ownership
authority.

## Resolution precedence

For a concrete spawn definition, precedence is:

```text
authoritative runtime/action fields
        >
mandatory policy bindings
        >
explicit blueprint values
        >
generated/default values
```

A mandatory relationship binding cannot be defeated by a preset.

Example: if a Brother blueprint contains an explicit surname, the
starting-companion Brother policy replaces/omits that value with the current
player's surname before concrete validation.

Debug/manual policy has no mandatory player bindings, so its explicit fields
remain authoritative within the debug action's permission boundary.

## Starting-companion policy matrix

The initial compatibility policy is the current behavior:

| Trait | Relationship | Sex policy | Surname | Family appearance |
| --- | --- | --- | --- | --- |
| `PNC_HasBrother` | brother | fixed male | inherit player | inherit |
| `PNC_HasSister` | sister | fixed female | inherit player | inherit |
| `PNC_HasMom` | mother | fixed female | inherit player | inherit |
| `PNC_HasDad` | father | fixed male | inherit player | inherit |
| `PNC_IsMarried` | lover | derive from player sex + orientation | inherit player | independent |
| `PNC_HasFriend` | friend | current deterministic/random default | independent | independent |

"Family appearance" currently means the same fields already applied by
`StartingCompanionService`: compatible skin texture/body index, skin color,
and hair color. Do not silently expand this to every face/style/clothing field.

The relationship policy may later classify a field as overridable/defaulted,
but P1-P4 must preserve the current mandatory semantics unless explicitly
approved.

## Orientation and dynamic Lover sex

Do not duplicate orientation rules.

Client preview should resolve the currently selected social traits through the
existing `PNC.SocialTraits.ResolveTraits` contract. Server resolution uses the
canonical server social profile / actual player traits.

Current rule:

```text
gay       -> lover sex matches player sex
straight  -> lover sex differs from player sex
bisexual  -> deterministic relationship roll
```

A preset never serializes this resolved boolean as authoritative starter intent.

## Dynamic player-context bindings

Character creation spans more than the profession/trait screen. The user can
later change name, sex, skin, hair color, and other player appearance fields.

Therefore:

- the creation session stores unresolved blueprint intent;
- preview context may be recomputed whenever the companion editor is shown;
- changing Gay/Bisexual while on the trait screen should immediately invalidate
  and recompute Lover preview;
- changing the final player descriptor later must not require rewriting the
  preset;
- the final concrete companion definition is resolved from the actual final
  player, not from a stale preview snapshot.

The preview is informative. The unresolved blueprint + binding policy are
canonical until final resolution.

## Final-screen entry-point and creation-session ownership

The logical starting-companion creation session spans multiple vanilla screens.
It must not be keyed solely by the `CharacterCreationProfession` Lua object or
by `CharacterCreationMain` object identity.

One logical creation session owns:

- selected companion trait slots from the profession screen;
- unresolved companion blueprints and removed-slot cache;
- authored/default state for each active slot;
- deterministic generation seeds;
- current preview context derived from the final player descriptor;
- staged submit intent, if and only if customization is explicitly authored.

The final **Customise Character** screen is the user-facing entry point for
companion authoring. Its bottom action row should expose an explicit
**COMPANIONS** action beside Play when the selected trait set contains at least
one starting-companion trait. No companion editor opens merely because a screen
became visible.

Opening Companions performs a fresh reconciliation:

```text
profession selected traits
        +
current CharacterCreationMain descriptor/UI state
        +
existing creation session
        -> reconcile slots
        -> rebuild current player/social context
        -> resolve previews
        -> open shared composer
```

Returning from the composer does not commit character creation. The user may
continue changing the player. Reopening the composer must reuse the same
blueprints while recomputing inherited/derived preview values from the current
player.

### Optional customization contract

Starting-companion customization is opt-in.

A selected Brother/Lover/etc. trait by itself means **default starter behavior**.
The established deterministic/randomized `StartingCompanionService` generation
remains canonical when the player never authors customization.

The session therefore distinguishes at least:

- **default/unmodified** — no authored companion customization should be sent;
- **authored** — at least one meaningful authoring action exists and a validated
  customization envelope may be staged.

Merely opening and closing the composer does not change default/unmodified to
authored. Meaningful authoring includes explicit field edits, preset/template
application, sanitized Unique NPC import, and explicit Randomize. Reset may
return a slot to default semantics when no authored difference remains; the
implementation should derive authored state from canonical blueprint/baseline
state rather than from a fragile one-way boolean where practical.

No-authored-customization must also clear/avoid stale staged envelopes so a
back/edit/re-enter flow cannot accidentally submit an earlier customization.

### Play pre-commit contract

The Hoomans pre-commit hook runs before vanilla Play/NEXT transitions away from
`CharacterCreationMain`.

```text
PLAY
  -> reconcile current selected traits + final player context
  -> if default/unmodified: clear/omit customization intent
  -> if authored: validate and stage canonical envelope
       -> failure: remain on final screen and surface reason
       -> success: continue
  -> invoke vanilla Play/NEXT
```

For a remote MP client, network transmission may still wait until the player
entity exists. That transport timing does not change the rule that the validated
canonical intent is staged before character creation leaves the final screen.

Normal and local/co-op creation share this semantic pre-commit action even
though `CoopCharacterCreationMain` overrides `onOptionMouseDown`.

## Reusable authoring presentation contract

The canonical registry/resolver is not by itself a player-facing editor. P5R2
requires the useful Unique NPC editor controls to be extracted behind one
reusable **authoring presentation component** consumed by both the debug creator
and starting-companion editor.

The shared component owns primitive NPC-editing presentation:

- General identity controls;
- canonical nickname control;
- archetype and equipment-mode controls;
- hair/beard/style controls;
- Appearance tab and clothing/outfit controls;
- voice/style/pitch controls and preview actions;
- skill controls;
- NPC trait controls;
- vanilla/physiological trait controls;
- dynamic trait controls;
- rendered portrait/runtime preview;
- human-readable validation/status presentation.

Outer surfaces own only workflow-specific chrome/actions:

```text
Shared NPCAuthoringEditor
        |
        +-- Debug Unique NPC adapter
        |     New / Load / Save / Produce / Inventory / Randomize
        |
        +-- Starting Companion adapter
              Companion slot / Load / Save / Save Set
              Randomize / Reset / Revert / Close
```

The two adapters may expose different action buttons and policies, but they must
not maintain separate primitive implementations for identity, appearance,
traits, skills, or portrait rendering.

### Presentation schema vs canonical field registry

The canonical field registry defines data meaning, type, persistence/network
capability, and normalization. A separate reusable **presentation schema/profile**
maps registered canonical fields to player-facing presentation metadata:

- translated label/description key;
- editor group/tab;
- ordering;
- control type (text, combo, slider, color, repeater, custom appearance control);
- option provider/catalog;
- whether the field belongs in normal, advanced, or diagnostic presentation;
- compact source/help presentation.

This presentation schema is shared infrastructure, not a companion-specific deny
list. It must reference canonical field IDs and never redefine their storage
semantics.

Relationship/context policy is a separate layer that modifies capabilities of
those shared controls:

- visible/editable;
- required;
- inherited/derived and read-only;
- hidden;
- allowed value set;
- validation policy;
- server-controlled.

Examples:

- debug Unique NPC context: broad manual identity and debug-authoring fields;
- starter Brother context: forename/nickname editable, surname inherited/read-
  only, sex fixed/read-only, family color bindings read-only, hairstyle/outfit
  still authorable where permitted;
- starter Lover context: surname inherited, sex orientation-derived/read-only.

The policy must not replace a shared field with a raw diagnostic row. A locked
field remains a normal human-facing control/value with a compact explanation
such as **Inherited from Player** or **Relationship Rule**.

### Normal presentation vs diagnostics

`NPCAuthoringComposer:FieldRows()` and the resolver trace remain useful
diagnostic/introspection APIs, but they are not the normal character editor.

Normal players must not primarily see:

- canonical IDs such as `appearance.beardModel`;
- implementation IDs such as `PNC_HasBrother`;
- untranslated keys such as `UI_PNC_Trait_HasBrother`;
- raw `[absent]` state markers;
- `<table>` placeholders for structured values;
- unrelated runtime/AI authoring fields merely because the registry marks them
  authorable.

Those details belong in the Resolution Inspector/advanced diagnostics.

All companion/relationship labels shown in the normal editor must be resolved
through translations and human-facing relationship names.

### UI event contract

Native Project Zomboid widget callback signatures are part of the integration
contract. In particular, `ISComboBox` change handlers receive
`onChange(target, combo, ...)`; adapters must not treat the first argument as
the combo merely because a headless stub accepted that shape.

Starting-companion slot selection and preset selection must flow through bounded
selection methods rather than mutating several state fields inside widget
callbacks. A valid slot-selection transaction updates, as one coherent state:

- selected companion trait ID;
- relationship-aware adapter;
- shared editor draft and controls;
- current summary/highlight;
- status text;
- resolved preview identity and portrait.

Invalid/no selection clears or hides the editable/portrait state. The previous
companion must never remain visible while the session reports no active selected
slot.

### Portrait and deterministic preview

Both debug and starter surfaces use the same portrait/runtime-preview component
and preview-spec path. Edits refresh the current preview in place.

```text
same active slot + same blueprint + same context + same generation seed
        -> same preview identity
        -> same resolved preview
        -> same rendered portrait
```

Preview identity/invalidation is explicit. It is derived from the active
canonical companion trait ID plus the canonical blueprint fingerprint,
generation seed, and relevant current-player/context fingerprint. Switching
active companion slots or explicit Randomize changes preview identity and must
rebuild the preview runtime record. Ordinary same-slot edits preserve generated
fallbacks and update the existing preview in place. Rebinding player surname,
sex, skin, hair, or orientation invalidates only the context-dependent preview
result without rewriting authored blueprint intent.

The selector, adapter, form, summary, portrait target/spec, and status must
always describe the same active preview identity.

### Companion window behavior

The starting-companion editor is a focused character-creation workflow and must
not be collapsible/pinnable. Use the existing `PsychopatzFixedWindow` behavior
(or the same Core primitive) so title-bar pin/collapse controls are absent while
the window remains closeable, responsive, and resizable.

Shared primitive controls do not require identical surface composition. The
debug creator may expose dense diagnostic/authoring workflows, while the
character-creation companion profile must compose those same primitives into a
clear normal workflow.

Normal companion **General** presentation is sectioned and scrollable rather
than a sparse debug form with large dead regions. It must make configured skills
and traits visible and removable, not merely expose Add controls while hiding
the collection.

Normal companion **Appearance** prioritizes common character-authoring choices:
outfit, skin, hair, beard where applicable, voice/style/sample/pitch, and other
high-value appearance controls. Per-body-location overrides belong under an
explicit Advanced Clothing Overrides surface with its own bounded scroll area.
Raw/internal engine location IDs such as `base:*` are diagnostic/advanced data,
not the primary normal presentation.

Locked relationship values are rendered as read-only human values plus compact
source explanation, not as controls that visually appear interactive but happen
to be disabled.

The debug Unique NPC editor may retain its own normal window behavior unless a
separate product decision changes it.

### Starter preset actions

The companion outer adapter exposes persistence through the existing canonical
starter preset infrastructure:

- **SAVE** — save the selected active companion as an individual template;
- **SAVE SET** — save the currently selected companion setup;
- **LOAD** — load/apply a compatible saved template/setup using the existing
  `StartingCompanionPresetStore` and session preset semantics.

Saving must not itself alter the authored spawn intent. Loading does alter the
blueprint and therefore may make customization authored. Revert restores the
loaded preset/template baseline already owned by the session.

### Blueprint vs resolved preview

The editor renders resolved preview values while retaining unresolved blueprint
state underneath. Important fields expose semantic source compactly: Custom,
Generated, Inherited from Player, Relationship Rule, or Server Controlled.

Randomize, Reset, and Revert to Preset remain separate actions. A compact final
summary of active slots should still be available before character creation
commits and must use the same resolved preview path.

## Field validation and limits

String lengths, collection counts, numeric ranges, enum domains, and nested
value limits belong to the registry/field codec rather than separate UI and
server copies. Client UI may prevalidate for feedback, but server decode and
resolution use the same canonical constraints.

Unknown fields are never executed or silently accepted over the network. Files
whose schema ID/version does not match the supported canonical format are
rejected as unsupported; the runtime does not carry legacy conversion code.
Future third-party/adopter fields should use registered namespaced stable IDs
instead of arbitrary passthrough tables.

## Canonical schema cutover boundary

P1 performs a deliberate clean cutover. Inventory all Project Hoomans-owned
Unique NPC definitions, examples, fixtures, editor/storage outputs, and active
identity authoring paths; convert them to the canonical registry; then remove
obsolete authoring aliases and compatibility loaders. Do not add runtime
migration scripts or golden legacy fixtures.

A required regression is full nickname preservation entirely inside the new
schema:

```text
canonical identity.nickname
    -> Unique draft
    -> BuildDefinition / storage
    -> reload
    -> Unique.Resolve
    -> runtime identity.nickname
```

At no point should `alias` reappear as a second persistent truth.

## Definition validation boundary

Keep two validation levels.

### Blueprint validation

Checks schema, field types, allowed values, policy capabilities, limits, and
whether every unresolved required field has a valid binding.

A starter blueprint may therefore omit concrete surname or `isFemale` when
its relationship policy guarantees those values.

### Resolved definition validation

After resolution, the output must be fully concrete and pass the canonical PNC
definition normalization used by runtime NPC creation. Existing
`UniqueNPCs.NormalizeDefinition` behavior should be reused/refactored rather
than reimplemented.

No spawn occurs from an unresolved blueprint.

## Compact data representations

Use one schema with multiple representations:

```text
readable sparse preset / Unique definition
        -> canonical blueprint
        -> optional compact compiled/network codec
        -> resolved concrete definition
        -> existing PNC runtime record
```

Do not store values that are mandatory-derived or authoritative when they can
be recomputed safely. Do not use compact numeric keys in durable presets merely
to save bytes; omission of derived/default data provides the meaningful size
reduction while keeping files migratable and debuggable.

## Preset contract

A starter preset is data-only and explicitly versioned. Use a stable schema
identifier plus an integer schema version. This implementation supports the new
canonical schema only; incompatible older formats are rejected rather than
keeping migration logic in the runtime.

It contains:

- schema ID/version;
- optional human label;
- one or more slot blueprints keyed by stable canonical companion trait ID;
- sparse authored fields;
- stable generation state where required for deterministic preview;
- schema/protocol metadata needed for validation.

It must not contain authoritative runtime ownership or resolved mandatory
bindings.

Saving a preset uses the unresolved blueprint. Loading it restores authored
intent and then resolves against the **current** creation context.

Preset storage supports both whole companion setups and individual companion
templates. Loading either does not purchase/add traits. Only currently selected
companion traits become active; additional whole-setup slots may remain dormant
until their trait is subsequently selected.

Existing Unique NPC definitions may be imported as source templates. Import
must strip or downgrade fields that the starter policy does not permit and
must never reuse the imported runtime/definition ID as a starter runtime ID.
Import returns a sanitization report suitable for preview before application,
including fields that will be removed, rebound, regenerated, or preserved. The
report comes from the same sanitizer used for the actual import.

## Resolution Inspector

Debug mode exposes a bounded read-only Resolution Inspector backed by the
shared resolver trace. For a selected slot it can show field source, binding or
rule, relevant context/dependencies, and resolved value. It is diagnostics, not
another editor or resolver, and does not gain authority-sensitive mutation
rights merely because it is visible in debug mode.

## Trait reconciliation

Maintain a selected-companion fingerprint from the actual
`CharacterCreationProfession.listboxTraitSelected` contents.

Reconciliation is set-based:

```text
added     = current - previous
removed   = previous - current
unchanged = intersection(previous, current)
```

Do not infer state from which button was pressed. This naturally covers add,
remove, randomize, reset, profession changes, vanilla build loading, and other
mods that repopulate the list.

Removed slot blueprints remain in a session-only cache so accidental
remove/re-add does not erase work. The final envelope includes only selected
traits.

## Character-creation extension ownership

PsychopatzCore may own provider-neutral character-creation extension seams
because it already owns reusable character trait integration. The existing
profession/trait lifecycle seam remains useful for selected-set reconciliation,
but it is not sufficient as the user-facing navigation boundary.

If P5R needs a reusable final-screen action/pre-commit seam, Core may expose a
small provider-neutral mechanism around `CharacterCreationMain` and inherited
co-op creation. It may expose generic final actions and/or pre-commit callbacks,
but it must not know what a companion is.

Project Hoomans owns:

- companion trait IDs;
- companion session state;
- relationship binding policy;
- composer/preset UI;
- starter request creation.

Core must never import PNC or encode Brother/Lover semantics.

## SP/MP authority

Use one semantic service with two transports:

```text
SP: creation session -> submit/resolve service directly
MP: creation session -> client command -> same server submit/resolve service
```

Multiplayer server validation always recomputes:

- actual player character UUID;
- selected starter traits;
- relationship kind;
- player surname/appearance;
- orientation/social profile;
- faction/community ownership;
- runtime NPC IDs;
- spawn position.

The client provides only permitted blueprint intent.

## Lifecycle race contract

Today server `OnCreatePlayer` immediately calls
`StartingCompanions.Ensure`. A customized MP envelope may arrive later.

The new state must distinguish at least:

- customization pending;
- customization received/validated;
- defaulted/no customization;
- grants complete.

`Ensure` must not duplicate the starter. A bounded fallback eventually uses
the current deterministic starter generator if a valid customization never
arrives.

Reconnects must read durable grant state and never reopen the creation
handshake for an already-resolved survivor.

## Persistence ownership

- Local presets: user-side data-only files through the Hoomans definition
  storage boundary.
- Creation-session cache: transient and never canonical after character
  creation.
- Starter grant state: server/world persistence by player character UUID.
- NPC record/body/faction/community: existing Hoomans services.
- MP request payload: not a new persistence authority.

## Forbidden designs

- A `StartingCompanionDraft` clone that diverges from the debug/Unique NPC
  blueprint model.
- Copy/paste of the Unique NPC editor into character creation.
- Saving a resolved preview as if it were the preset's authored source.
- Client-provided starter runtime IDs, relationship kinds, ownership, or
  faction state.
- A server path that trusts a client-resolved surname/sex/skin value when the
  policy says it is inherited/derived.
- A separate SP resolver and MP resolver.
- A Core character-creation hook containing Project Hoomans semantics.
- Automatic companion-editor navigation from generic screen visibility events.
- Separate profession-screen and final-screen companion sessions.
- A Play wrapper that calls vanilla NEXT/world transition before Hoomans
  validates explicitly-authored customization.
- Treating trait selection alone as authored customization.
- Sending a default blueprint envelope when the player intentionally skips
  customization; the established starter default generator owns that path.


## Reusable character export (P5R8)

Companion presets continue to store sparse blueprint intent in the starter
namespace. The optional encounter export captures a separate, exact resolved
character with a stable `user:<filename>` definition identity in the NPC
namespace. It does not convert inherited companion fields into authored preset
values. Both creator hosts use the same NPC definition file codec and storage.
Only produced NPC files enter world generation; ordinary drafts/presets do not.

Authority discovery is bounded to 256 indexed files and joins the existing
Unique NPC catalog before reservation. Its existing generation chance and
world-owned alive/dead entries remain authoritative. Registration/reloading
never clears world death state; reusable files survive for other worlds.
Multiplayer clients do not automatically contribute files. Publishing requires
an admin player on both client presentation and authoritative mutation paths;
the server persists its copy and may discover its own administrator-controlled
local files on subsequent worlds. Semantic backstories remain deferred.


## Loadout presentation and saved-record deletion (P5R9)

Body-part metadata, equipment navigation/tiles, carried inventory and camera
framing have separate presentation responsibilities. Canonical slot/item edits
remain in the existing loadout model. Native exclusivity derives visibility;
no hide-state is persisted, equipped entries stay removable and unknown modded
locations have a fallback view. Carried quantities/destinations use startingItems
and the same dynamic Item Explorer rather than an equipment-slot abstraction.

Face framing projects a copy of the body portrait spec, removes obscuring gear
only in that copy and keeps separate camera preferences. It never author-controls
clothing or changes saved NPC values. Menu voice owns one handle and a shared
menu routing lease; completing/stopping the last owned preview restores MainMenu,
while in-game playback never changes world music state.

Saved-record deletion erases the data payload with a non-loadable marker and
removes its exact kind/filename entry. It does not unlink the physical file.
Catalog withdrawal is limited to file-owned definitions; existing actors and
world death/reservation state are preserved. Recreated files with the same ID
cannot revive a dead identity. Remote server-library mutation requires admin
access; local private preset records remain user-owned. Browser confirmation
is selection-bound and resets when the selection disappears or changes.


## Visual loadout navigation and saved previews

The authoring body map reuses native male/female silhouette textures, trimmed
texture bounds and native region z-order. It is a draft navigation projection,
not a health/temperature model and never requires a live actor or BodyDamage.
Region/group counts derive from visible canonical loadout rows; exclusive empty
alternatives remain owned by slot compatibility. Bags, carried inventory,
weapons and unfamiliar mod locations retain explicit accessible views.

Saved portraits resolve data without applying it. Companion presets use the
current relationship/player resolver; debug presets use the same draft model.
Only visited members create a portrait snapshot, with a bounded per-browser
member cache. Member cycling and empty/error selections cannot mutate session
blueprints or leave a visible stale NPC. The shared browser owns portrait layout;
preset providers own read-only resolution.

Explicit weapons remain ordinary startingItems with equipSlot and native item
state. The picker uses loaded vanilla/mod script weapon types without eagerly
constructing catalog items. Two-hand constraints precede mutation. Generated
weapon modes are debug fallback policy; an authored primary weapon determines
the resulting generated-inventory combat mode. No new persistence schema or
parallel loadout authority is introduced; canonical foreign inventory providers
keep their existing combat policy ownership.
