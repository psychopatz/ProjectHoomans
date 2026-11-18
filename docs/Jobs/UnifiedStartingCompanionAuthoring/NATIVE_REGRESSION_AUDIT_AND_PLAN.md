# Native creator regressions: audit, repair and acceptance

Date: 2026-11-18. Status: P5R4 implemented and developer-verified after user
authorization. Native acceptance is pending. The findings below preserve the
pre-repair audit; they describe the rejected P5R3 state.

## P5R4 result and evidence

The shared editor now buffers native text without rewriting it per keystroke,
commits validated candidates, and retains accepted state on rejection. Compact
fields keep derived values in disabled native inputs with lock tooltips; gender
uses icon toggles. The installed -100..100 pitch contract is canonical, slider
movement commits once on release, and voice-only changes cannot invalidate
inventory, visual caches or portrait descriptors. Actorless UI audio owns and
stops its own handle on Stop, tab/selection changes and close.

Loadout now presents grouped equipment icon tiles and a dedicated paged Item
Explorer. It discovers loaded vanilla/mod scripts, filters by mod/module,
category and compatibility, searches display names/IDs, and provides details,
quantity/destination, refresh and explicit apply actions. Outfit selection uses
the same explorer. The normal loadout flow has no combobox. Incompatible items
remain inspectable with compatibility filtering off, but cannot be equipped.
Existing native clothing state is frozen when changing one slot. New drafts
start clothed; named legacy presets capture stable preview-only exact clothing
without serializing generated state into the source preset. Explicit empty
outfits remain supported. Native capture never registers a world survivor.

`TEST_VERIFIED`: focused suite 51/51, full suite 1044/1048. The four prior failures
remain animation scene debug routes, context debug scene lab, population
director initialization and Debug Hub translation expectation. Regression
coverage includes production form rollback/recovery, pending edits and caret,
actorless audio ownership, 201 slider moves with one release commit, 521 catalog
items across pages beyond the former 200-result boundary, grid/modal geometry
at 780x420, 1060x620 and 1540x900 with 1/1.25/1.5 font scales, clothed defaults,
legacy preset capture caching, and audio-independent clothing/portrait identity.

`STATIC_ONLY`: 44 Lua syntax checks, 30 production-file Kahlua checks, JSON,
32 new EN/TL keys, PNG and whitespace checks passed. These bounded widget/native
API fixtures do not prove native input, rendered geometry or audible playback.
No game launch/control or Workshop publication was performed.

## Required user-owned native retest

Use the installed PZ 42.22.2 in a fresh session, exercising both creators:

1. Type, paste, backspace and insert in the middle of every editable name/search
   entry; commit by focus change and Enter, then switch NPCs/tabs. Invalid state
   must retain the accepted preview and recover after correction.
2. Check derived surname/appearance/gender controls stay visible, refuse edits,
   and show the right native lock reason on hover; verify editable gender icons.
3. Drag pitch repeatedly to -100 and +100, then change hair and switch NPCs.
   Clothing colors/items must remain stable; inspect console for new exceptions.
4. Play/stop several voice styles/samples before a player exists; confirm audible
   pitch changes and that tab/selection/close stops only the creator sound.
5. Browse grouped slot tiles, outfits and the Item Explorer: search/filter all
   loaded mods, page results, inspect incompatible/missing items, equip/replace/
   clear clothing, hands and attachments, and add bags/contents. Verify untouched
   clothing colors, saved intent and round trips.
6. Resize and change game font scale; check fields, tile labels, modal hit targets,
   scrollbars and portrait bounds. Fresh NPCs must start clothed; saved explicit
   empty outfits must remain empty.
7. Run the existing P6 Save/Load/Produce, finalization and SP/MP/co-op matrix.

A failing native outcome reopens developer acceptance; record build, action and
bounded console delta. Do not infer native success from these harness results.


## Current acceptance state

The user's four screenshots reject native acceptance of P5R3 (`86000e26`). The
shared roster/page foundation remains useful, but developer-side acceptance must
be reopened for input, preview mutation, validation, audio and loadout UX. The
prior passing suites are evidence about their bounded contracts, not evidence
that typing, voice playback or visual stability works in the game.

Observed Git state: existing main, HEAD 86000e26, initially clean, one active
primary worktree plus two prunable historical worktrees; locally recorded
origin/main is eight commits behind. No fetch, branch, runtime edit, native game
launch/control, push or Workshop publication was performed.

The inspected console identifies **Project Zomboid 42.22.2**, revision
3d39148846, five loaded mods. The installed current native Lua is the API evidence;
42.20 remains the mod's runtime content directory. Earlier instructions to test a
42.20 game session should be read as historical, not the current installed build.

## Findings and evidence strength

### 1. Confirmed validation crash, with a reproducible cause

The pitch control and its handler allow -100 through +100; the canonical registry
limits appearance.voicePitch to -32 through +32. BuildDefinition therefore
returns nil plus number_above_max for a UI-permitted value such as 100.
ApplyDraftToRuntime immediately indexes def.startingItems without checking
whether BuildDefinition succeeded.

The console reports seven occurrences of signature E1DE30E: attempted index:
startingItems of non-table: null. The latest expanded occurrence includes
ApplyDraftToRuntime -> refreshPreview -> onAppearanceChanged -> markChanged ->
onHairChanged. The user's pitch screenshot shows the same update path with
number_above_max on the object stack. A previously invalid draft can therefore
also poison a subsequent hair edit.

Read-only diagnostic using the production model reproduced:

- PITCH_100 definition=nil reason=number_above_max
- INVALID_APPLY success=false nil_definition_crash=true

The log proves repeated Lua exceptions. A native process crash is user-reported;
this bounded log inspection does not independently establish process termination.

Repair: validate a candidate before replacing accepted state; propagate exact
validation failure through BuildBlueprint/BuildDefinition/EnsureRuntimeRecord;
retain the last valid preview. Ordinary invalid input must not throw or leave
commit/refresh guards stuck. Verify the installed engine's supported pitch range,
then use one canonical range across registry, UI, presets and wire validation.
Installed CharacterCreationMain uses -100..100 directly, so expanding a tested
canonical range is preferable to silently truncating the native control to 32.

### 2. Confirmed pitch-to-clothing mutation path

A voice edit changes the full appearance signature. ApplyDraftToRuntime treats
that as a clothing change, clears the appearance cache and recreates inventory.
Native item creation/capture can then choose clothing/texture/color state again.

An isolated production-model diagnostic with a valid pitch change reproduced:
PITCH_ONLY inventory_rebuilds=1 appearance_cache_cleared=true. This supports the
user's observed item/clothing color changes. The audit did not independently
render or inspect every resulting native texture.

Repair: separate audio, identity/body visual and outfit/loadout invalidation.
Changing voice/style/sample/pitch must not recreate clothing or inventory.
Retain exact item visual state and generated look across ordinary edits, tab
changes and roster switches. Only the documented Randomize operation advances
random generation. Coalesce continuous slider updates and avoid synchronous
full-editor rebuilds inside a drag callback.

### 3. Confirmed player-dependent voice preview

The creator's onPlayVoice requires AudioDebug.GetCurrentPlayer and calls the
live-player dialogue backend. During character creation there may be no player;
it reports Voice preview unavailable, matching the screenshot.

The installed vanilla CharacterCreationMain already demonstrates an actorless
UI-emitter path: getUIEmitter, playUISound, CharacterVoicePitch and
CharacterVoiceType parameters, followed by emitter tick. Use that as the native
contract to verify, not a guessed actor API or a temporary spawned NPC. Do not
mutate the main player's descriptor or copy unrelated vanilla music-state
workarounds. Own/stop only the creator's preview handle on Stop, selection
change, hide and close; handle unavailable/dummy audio explicitly.

### 4. Typing failure is user-confirmed; exact focus mechanism unresolved

The current text callback pulls the entire form on every keystroke, trims names,
commits through the companion adapter, rebuilds the resolved draft, synchronizes
all controls and calls setText back into the native entries. setField does so
unconditionally. Vanilla setText invokes UITextBox2:SetText. This is a concrete
feedback-loop/caret-reset risk and prevents preserving ordinary partial text
such as a trailing space. It is not yet proof that one particular native focus
or hit-test mechanism explains every textbox refusing input.

The composition test replaces native entries with table fields and replaces
syncControls/refreshPreview with no-ops. It therefore cannot certify this path.

Repair: introduce one shared field-edit boundary: a field-local text buffer,
unchanged-value guards, preserved caret/selection/focus, and a validated commit
on Enter/focus loss or another explicit action. Switching NPCs, saving or closing
must flush the focused edit exactly once. Keep partially typed text out of
resolved-state feedback until accepted. Cover keyboard routing and scrolling
hit testing before calling input fixed; implement basic cursor editing,
backspace, spaces, paste and selection replacement tests.

### 5. Naked initial preview is an explicit default, not an asset failure

Model.New initializes appearance.outfit.mode to none. Existing tests explicitly
expect that. Appearance resolution describes none as starting empty. Importing
an otherwise sparse definition can retain that default.

Repair: new/unmodified creators should resolve a stable, clothed archetype/game
look without manufacturing authored outfit intent. Existing presets that
explicitly select none must retain that choice. First open, no-op close, player
rebinding and final spawn must agree about the default look. Equipping one slot
must preserve all other clothing; current slot editing also changes the whole
outfit policy to none and needs review as part of this rule.

### 6. Loadout is still an internal-slot list with dropdowns

The supplied screenshot proves the gap: raw names such as ammostrap,
calf_left_texture and full item IDs remain visible, and the layout uses large
comboboxes and lists instead of the requested equipment overview.

The code strips namespace prefixes and looks up translations using the remaining
raw lowercase ID. Native translation keys use names such as AmmoStrap/Jacket;
case/identity normalization is missing. The slot renderer concatenates item.type
rather than consistently showing the item's display name.

The current catalog already uses getAllItems, so it includes loaded mod scripts.
The missing feature is a proper explorer and equipment presentation, not a
vanilla-only whitelist. It currently caches the result and exposes only the
first 200 matches without paging. Clothing lookup, attachments, usability and
item instantiability need their own verified compatibility rules.

### 7. Derived-field treatment and sizing do not meet the requested UX

Surname/gender controls are currently replaced by labels for some locks; skin
selection is hidden, hair color is merely disabled, and explanations are mixed
into labels. Fields can stretch across the entire central pane. Gender is still
a combobox. These are inconsistent applications of the same capability policy.

Use one reusable field presentation for both creator callers. Keep the visible
control and its value, apply read-only/edit-disabled behavior appropriate to its
native control type, and place a lock affordance inside the field cell. Load the
verified native asset media/ui/MP/mp_ui_passwordOn.png. The lock is informational,
not an unlock action. Hovering the lock or field must explain the actual binding
rule/source (player surname, family appearance, relationship gender, server
ownership). A wrapper hover target must work even when the control cannot edit.
Support all inherited/derived fields, not a surname/gender special case.

Gender becomes two icon toggle buttons with clear selected state and accessible
Male/Female labels/tooltips. Apply the same lock treatment when relationship
policy determines gender; the toggle cannot bypass the rule. Verify native icon
assets or add small shared UI assets; do not assume unsupported icon filenames.

## Proposed shared screen and controls

Retain the left roster, topic tabs and persistent character preview. Use two
compact form columns when space permits, with bounded input widths measured from
text/font metrics, rather than making every entry a pane-wide strip. At narrow
widths stack fields and scroll their page. Slider, color swatch and voice actions
belong to a compact Voice/Appearance section with no unexplained blank locked
rows. Preserve full values via focus/selection and tooltips when display space
is limited. Support English, Tagalog and long modded item names.

Loadout follows the original slot reference:

- Named equipment groups: Head/Face, Neck, Torso layers, Hands, Waist, Back/Bags,
  Legs, Feet, held items and attachments. Use icon tiles with equipped item or
  clear empty state, grouped dynamically from supported native/modded slots.
- Keep engine IDs as internal authority. Canonicalize labels correctly; modded
  slots fall into a readable Other group rather than disappearing or exposing
  implementation IDs as the main interface.
- Clicking a slot opens the shared **Item Explorer** with that slot's compatibility
  filter. Clear/remove and inspect are direct slot actions. Category tabs and
  buttons replace loadout-selection comboboxes. Outfit presets use a browseable
  preset choice, and generation policy uses a small segmented control.
- Explorer has search, category/module filters, compatible-only toggle, icon
  grid/list, item details, quantity and an explicit destination/Equip/Add action.
  Provide bounded paging or virtualized results; no silently inaccessible items
  after result 200. Explain unavailable or incompatible choices.
- Discover the loaded script registry, including enabled mods; filter obsolete,
  hidden or unusable entries through verified engine contracts. Lazily validate
  item creation and cache results; never instantiate the whole catalog or rebuild
  it every frame. Refresh/invalidate caches when script availability changes.
- Keep selection stable through search and paging, handle missing mod items on
  preset reload, and preserve exact clothing visuals and bag contents.
- Explorer is a shared picker component. It writes through the existing canonical
  appearance/startingItems authoring commands and companion policy adapter; it
  does not introduce another inventory model, save format, or companion editor.

## Implementation order and acceptance gates

1. **State and validation safety.** Reproduce invalid pitch and other invalid
   fields; validate/propagate failures without modifying accepted state. Test
   that valid edits recover after an invalid one and no commit guard stays set.
2. **Editing and preview isolation.** Prove real keyboard/caret behavior; isolate
   pitch/style/name edits from inventory/outfit invalidation. Establish clothed,
   deterministic default/no-op behavior. This is a gate before adding more UI.
3. **Actorless voice preview.** Verify the installed UI-emitter API, then test
   no-player Play/Stop/replay, parameters and lifecycle cleanup with a faithful
   boundary fixture. No live actor or player descriptor mutation.
4. **Consistent compact field controls.** Shared read-only boxes + lock/tooltips,
   gender icons/toggles and responsive field sizing. Apply through capabilities
   to every derived/inherited field and both callers.
5. **Slot overview and dedicated Item Explorer.** Build the grouped equipment
   tiles, loaded-mod catalog, paging/filtering and details. Prove one clothing,
   held, attached, bag and carried-item path through preset and final definition.
6. **Regression gates and handoff.** Run affected suites, syntax/Kahlua checks,
   translation/icon checks and developer-implementable input/emitter/geometry
   fixtures. Then record native visual/audio/SP/MP/co-op acceptance separately.

Required scenarios include continuous pitch dragging at both endpoints, edit
recovery after invalid data, first/middle/last text edits and paste, no player,
slot replacement/clearing without unrelated outfit removal, exact texture/color
stability, empty and large mod catalogs, module filter/paging, missing mod items,
locked-field hover and gender policy, every supported scale and both callers.

The user did not assign agent-driven native Project Zomboid control in this
planning request. Native results supplied by the user remain the runtime evidence;
all developer-side fixes/tests must be completed before returning that work.

## Audit verification

- Console overview and bounded issue expansion; session 262d2c6a, cursor
  262d2c6a:68064. Preserve the session identity when checking a later retest delta.
- Structural discovery/trace/snippet and current source reads. Graph generation
  2026-11-18T02:01:45Z; 20 relied-on paths returned metadata_match and no recorded
  coverage issue, with no additional path page. Static call-resolution artifacts
  were checked against source rather than treated as complete dataflow proof.
- Six focused existing Lua tests passed unchanged. The isolated production-model
  diagnostics above reproduced invalid-pitch failure and pitch-only inventory
  invalidation despite those passing tests.
- No runtime, asset or test changes were made. No new native, full-suite or
  multiplayer result is claimed for the proposed repairs.
