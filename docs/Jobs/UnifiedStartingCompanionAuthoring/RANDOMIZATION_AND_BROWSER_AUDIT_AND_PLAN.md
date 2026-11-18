# Creator randomization and browser audit / proposed P5R5

Date: 2026-11-18. Status: P5R6 developer follow-up verified; native acceptance
pending. The historical P5R4/P5R5 audit below is preserved for provenance.

## P5R6 clarification and repair

The latest user report requests editable Friend gender, persistent selected
button color, a wide explicit appearance-variation action, proper title-bar
spacing and working menu voice playback. This supersedes the earlier blanket
ban on companion random actions; Random **policies in selectors** remain hidden.

The shared resolver now treats free-sex traits as editable generated defaults,
with fixed family/orientation rules still locked. Male/female values round-trip
and body changes refresh the native preview. Selected theme variants survive
control updates. The composer uses Core's title inset; variation occupies a
bounded wide footer. Companion variation generates concrete appearance fields,
projects only editable visuals and wardrobe, preserves nonvisual generation and
commits once after validation. Audio follows native CharacterCreationMain's menu
resume/emitter-origin contract, retains owned-handle stopping, and reports
specific localized failures. Music state is not changed.

Evidence: **56/56** focused, **1049/1053** full suite (same four known failures),
**20** Lua syntax/**12** production Kahlua checks, **five** new EN/TL keys plus
JSON/static references/parity/whitespace. Native audio/rendering remains
unverified; the harness checks the call sequence, not audible sound.

Current native retest: choose Friend male then female, confirm colors survive
refresh, verify family locks, resize/change fonts without header overlap, use
the wide variation action while preserving name/skills/gender/gear, and play/stop
voice before entering the world. Complete the earlier browser/preset and P6
lifecycle matrix afterward. Native game control remains user-owned.

## Implemented result and validation

The shared editor implements the proposed companion/debug capability, explicit
debug Randomize look transaction, corrected native combo/font/label metrics,
contextual browser modes and compact Attributes/preset workflows. Complete outfit
Apply uses the exact focused preview clothing state, removes old authored clothes
and retains held gear/bags; Cancel changes nothing. Hidden filtered selections
are cleared/revalidated, and disabled actions use neutral styling.

Four new regressions plus extended existing tests pass: **55/55** focused and
**1048/1052** full suite. The four prior failures remain animation scene debug
routes, context debug scene lab, population initialization and Debug Hub
translation expectation. **33** owned Lua files parse; **22** production Kahlua
checks pass. **15** new EN/TL keys, JSON, static references, parity and whitespace
checks pass. Current dirty/new sources were read/tested directly where the graph
baseline was stale or untracked. This does not establish native visual success.

## User-owned P5R5 native retest

Use a fresh installed PZ42.22.2 session and both entry points:

1. In companion customization, inspect every page/browser after new generation,
   reset and loading old presets: no Random policy option should be exposed; the
   wide explicit appearance-variation action should be available.
   Opening/closing without edits must preserve generated/inherited defaults.
2. In debug, select explicit hair, body tone and clothes; use Randomize look.
   Confirm controls, slot icons and portrait agree, old visual overrides are
   replaced, and biography, skills, traits, voice, bags and weapons are retained.
   Ordinary text/audio edits and NPC/tab switches must keep that result stable.
3. Check dropdown arrows, long EN/TL/mod names, list font sizes, labels and
   neutral disabled states at compact/desktop resolutions and game font scales.
4. Browse outfits: select/reselect, inspect the single focused preview, Cancel,
   Apply and None. Confirm Apply matches the reviewed colors and does not
   resurrect old clothes; bags/weapons remain present.
5. Browse equipment: select A, filter/page/refresh it away, then confirm Apply
   cannot target A. Test compatibility, missing mod items, bags/contents and
   attachment conflicts; quantity/destination should appear only when relevant.
6. Exercise compact presets with one-companion/whole-set scope, grouped trait
   selection/removal and skill 0-10 steppers; scroll on narrow/large-font layouts.
7. Complete prior input/voice/save/load/produce and P6 SP/MP/co-op/finalization
   checks. Record build/action and a bounded console delta for any failure.

Registered native outfit names still come from the engine. No authoritative
user-facing eligibility metadata was established, so this repair does not hide
engine/mod outfits by guessing from their names. Actual native styling,
rendering/hit testing and outfit diversity remain user-owned acceptance.


## Requested behavior

Keep one editor and canonical model for companion customization and debug.
Character customization must expose **no Random options or Randomize actions**.
Debug retains explicit randomization, with defined visual behavior. Repair the
native widget defects and make Attributes, presets, outfit selection and item
browsing compact, legible and consistent with the roster/tab/slot structure.

Interpret the random restriction as a user-facing/action capability. Automatic
initial companion generation, relationship inheritance and old randomized
presets still resolve normally; opening the editor must not author their
resolved values. This preserves the accepted skip-customization/no-op contract.

## Evidence and repository state

- User screenshots 1-4 show full-width Attributes selectors, a sparse item
  browser with clipped filter labels, a full-width preset popup, and an outfit
  browser of blank icon cards with irrelevant inventory controls. The user
  reports stale clothing after Randomize.
- Existing main at f749d7ef; initially clean. Locally recorded upstream is seven
  commits behind; no fetch/integration was performed. Read-only Core inspection
  does not widen implementation ownership to that repository.
- Graph generation 2026-11-18T09:18:04Z. Structural randomize discovery and a
  bidirectional two-hop model trace were followed by exact source reads.
  Coverage of 30 relied-on Hoomans and five Core files reports metadata_match,
  no recorded gaps and no remaining pages. This supports the bounded paths
  below, not an exhaustive architecture claim.
- Installed native ISComboBox/ISScrollingListBox/ISLabel are outside the graph;
  relevant source was read directly. Console session 20bf705d identifies PZ
  42.22.2, five mods, cursor 20bf705d:28549. Its eight reported errors are font
  loading and fluid-container sanitization signatures; the bounded overview
  supplies no current editor Lua exception. It does not prove editor correctness
  or causally connect every layout issue to the font warnings.
- Five current tests pass: catalog, explorer layout, composition, editor model,
  starting-companion shared adapter. Two temporary diagnostics use production
  model/blueprint functions and the existing widget fixture; no persistent tests
  were changed. Prior 1044/1048 full-suite evidence was not rerun in this audit.

## Findings

### 1. Random controls are not a presentation capability (confirmed)

The companion host constructs and lays out a Randomize toolbar button, its
workflow accepts randomize, the Appearance tab exposes another action, and
voice/outfit/hair/beard/skin/hair-color option builders add Random regardless of
host context. Hiding the top button alone leaves several routes available.

Repair: one shared presentation capability, derived from host mode, controls
all random actions and option builders. Companion handlers must reject the
operation even if invoked through a hidden/stale control. Debug keeps it.
Bind controls to semantic values, not shifted option indexes. Display generated
or inherited **current values** in companion mode without turning them into
chosen values on sync. Imported random policies remain valid behind the view.

### 2. Randomize changes generation but retains visual overrides (confirmed)

Blueprint.Randomize copies all fields/clears and changes only generationSeed.
Session:RandomizeSlot uses it directly. A production diagnostic with explicit
appearance reports seed_changed=true and appearance_unchanged=true. Rerolling a
seed cannot replace a fixed named outfit or explicit clothing slots.

The debug model normalizes its appearance policy but retains explicit survivor
hair/skin/color fields. A second production-model diagnostic changes seed from
123 to 987 and still emits hairModel=Long. Its action also adopts/synchronizes
preview state before randomization, so blanket cache clearing is not a sound
substitute for a deliberate replacement contract. The exact contribution of
native descriptor caching to every reported stale item remains unverified.
The loadout caption also describes the draft outfit policy, while slot tiles
use effective preview inventory. A caption such as None can therefore appear
beside a dressed preview; show the effective clothing summary and separate the
source/policy explanation instead.

Proposed debug action: **Randomize look** replaces body/hair/beard/color, outfit
and clothing-slot overrides with one newly generated visual result. Preserve
bio, skills, traits, relationship rules and authored carried/held inventory.
Generated clothing must not be recaptured from the old preview into the new
candidate. Commit the candidate/seed once, rebuild the affected visual and
inventory state once, then refresh slot tiles and portrait from the same result.
Ordinary edits continue to preserve exact clothing/item colors. A random draw
may repeat; tests should prove use of the new controlled generation result,
not assume every uncontrolled draw must differ.

### 3. Misplaced dropdown arrows have a native-contract cause (confirmed)

The shared newCombo helper calls ISComboBox:new with height=1. Layout.SetBounds
later changes height, but vanilla renders the arrow using baseHeight saved by
the constructor. Therefore its arrow remains centered around the original
one-pixel height. This matches the arrows at the top edge in screenshot 1.
The companion preset combo starts at 24 and still needs scaled base-height
synchronization. Its huge popup in screenshot 3 also follows the deliberately
full-width preset field; it is not proof of a separate popup event exception.

Repair widget sizing before visual polish. Use valid initial heights and a
shared Hoomans combo sizing adapter that synchronizes native baseHeight and
font metrics on resize. Keep any remaining small-enum dropdowns bounded.
Replace the full-window preset dropdown with a compact Presets browser that
makes selected/whole-set scope clear. Avoid a global Core widget behavior change
unless an independent audit proves it belongs there.

### 4. Explorer list font and label contracts are incomplete (confirmed)

UI.CreateList does not choose a font. Vanilla ISScrollingListBox defaults to
UIFont.Large, while the explorer sets row heights from UIFont.Small and caps
filter columns at 150px. It also outputs raw category IDs without localization
or measured truncation. This explains the inconsistent size and clipping in
screenshots 2/4. Native ISLabel:setName also resets position to originalX and
resizes to text; the current fixture implements neither behavior.

Repair: explicitly choose fonts/padding, measure localized labels, provide
bounded ellipsis plus full tooltips, and derive filter/detail widths from actual
font metrics and available area. Synchronize native row/font metrics rather
than assigning itemheight alone. Use safe supported range punctuation: source
uses an en dash while screenshots show 12 / 2 and 148 / 244. A missing glyph is
an inference; verify it and use an ASCII range separator regardless.

### 5. Outfit browsing is an inappropriate item-dialog mode (confirmed)

Outfit records have no item script/texture. The generic tile renderer draws
nothing above their label, producing blank cards. The browser still exposes
compatibility, quantity, bag destination and Equip / Add for outfits. It has no
initial selection prompt or persistent selected-tile border, and no contextual
empty state. Empty details/disabled Apply in a screenshot alone do not prove
that native clicking fails; the current fixture can select and enable Apply.

Repair through **modes of the same shared browser**, not another NPC system:

- Outfit mode: searchable readable outfit rows/cards, named/saved source where
  available, one bounded selected-outfit preview, and **Apply outfit**. Hide
  quantity, bag and compatibility controls. Avoid dozens of native descriptors
  for thumbnails; generate only the focused preview lazily.
- Equipment mode: visible selected tile, item details/compatibility, and clear
  empty/loading/unavailable states. Worn/held/attached modes hide irrelevant
  quantity/destination controls; carried items expose them when meaningful.
- Both modes preserve the selected NPC and accepted draft until explicit Apply;
  Cancel changes neither. Make the destination slot/NPC and failure reason clear.
- Use native/mod display metadata when available and retain raw IDs in details.
  getAllOutfits currently includes engine test names; investigate authoritative
  visibility/eligibility metadata before promising to filter them. Do not guess
  APIs, use raw-name substring blacklists, or hide mod content arbitrarily.

### 6. A filtered-out item remains actionable (reproduced)

refreshResults updates visible rows but does not reconcile selectedItem. In the
widget-boundary diagnostic: select A -> filter to B -> selectedItem is still A
and confirm remains enabled. This can apply an item that is no longer visible.
Refresh/invalidation similarly leaves a pointer to the old catalog entry.

Repair: track selection by stable ID; clear/revalidate it against current mode,
query, source/category/slot and catalog generation. Refresh the details and Apply
state atomically. Revalidate compatibility and availability at the apply
boundary. Preserve selection only when it remains valid and visible.

### 7. Attributes uses available width without information hierarchy (confirmed)

layoutAttributes stretches every selector across the whole content width, and
splits the skill name/0-10 value evenly. All kinds feed one lower list with a
full-width Remove action. In screenshot 1 this creates a large empty area and
weakens the distinction between skills and the different trait kinds.

Repair: compact skill rows with a short numeric stepper/value and nearby add/
remove controls; separate labeled trait groups with searchable add selectors.
Use two columns only when measured width permits, then stack/scroll at compact
sizes. Show empty-state guidance and group-specific selected rows/actions.
Retain canonical IDs, conflict validation, relationship locks and adapter edits.

### 8. Existing geometry tests miss the observed native defects (confirmed)

The fixture uses setName as a string assignment, does not model combo
baseHeight/arrow rendering, uses a single font enum, replaces Appearance and
preview refresh, and makes Ellipsize a no-op. Explorer layout tests check bounds
and Next but never select an item, filter it away or apply an outfit. Current
randomize assertions check seed/mode, not the resulting visual clothing.
Their passing results do not cover the newly observed contracts.

## Proposed implementation sequence

1. **Behavior contracts and regressions first.** Add shared host capabilities;
   tests for every companion random route being absent/inert, semantic option
   binding and legacy random presets staying no-op. Add controlled native-style
   sizing/font/label tests and the stale-selection regression.
2. **Debug generation correctness.** Implement the defined Randomize look
   transaction and generation/override ownership. Verify a controlled alternate
   look reaches canonical output, inventory, portrait and slot tiles; unrelated
   edits and roster/tab switches remain stable. Keep ordinary audio isolation.
3. **Native widgets and compact shell.** Correct combo initialization/resizing;
   cap field widths; introduce the compact presets browser; repair font/row and
   label bounds. This establishes correct geometry for every later page.
4. **Browser modes and equipment workflow.** Add clear selection/details,
   dedicated outfit presentation, contextual actions, correct filtered selection,
   supported pagination text and single focused preview. Keep dynamic mod item
   discovery and lazy creation.
5. **Attributes organization.** Compact skill rows and grouped traits using the
   same shared selector/policy mechanism. Check large translated labels and font
   scales without using full-width controls by default.
6. **Developer gate, local checkpoint, then native retest.** Run affected model,
   adapter, no-op/preset/clears, inventory and interaction tests; syntax/Kahlua,
   translation parity and full suite. Record any prior failures separately.
   Native PZ remains user-owned unless explicitly delegated.

## Acceptance gates

- Companion customization contains no Random label/choice/action on any page,
  preset-browser workflow or hidden handler. Open/close, reset, load/import and
  relationship rebinding preserve canonical generated/inherited intent.
- Debug Randomize look replaces the defined visual scope from a controlled new
  generation, updates the visible NPC/tiles, preserves biography/attributes and
  authored carried/held items, and stays stable until another explicit action.
- Native combo arrows align with the resized control at all tested font scales;
  list font metrics match row sizing; label updates cannot restore stale x/y.
- Presets and catalog selection are identifiable and bounded, with translated
  readable labels and useful empty states. Normal outfit selection has no
  irrelevant item controls or blank icon-only cards.
- Select -> search/filter/page/refresh -> apply cannot equip a hidden/stale item.
  Cancel never mutates accepted draft or another roster member. Missing/modded
  content reports a recoverable reason and remains inspectable when appropriate.
- Test viewport/font combinations cover compact, desktop and large layouts,
  long EN/TL/mod labels, scroll extents, mouse hit targets and popup clipping.
  Native event/draw-boundary tests complement, rather than merely repeat, the
  rectangular bounds fixture.
- Both entry points round-trip presets and exact item visual state. SP/MP/co-op
  finalization stays under the existing P6 matrix.

## Remaining uncertainty

No agent native interaction or audible/rendered acceptance was performed.
The screenshots do not establish a new typing, voice or process-crash regression.
The bounded console overview has font warnings but no demonstrated causal chain
to the whole interface. Native outfit metadata/eligibility and the precise final
look-reroll diversity need implementation-time API/content checks. These limits
must remain explicit when claiming the repair is complete.
