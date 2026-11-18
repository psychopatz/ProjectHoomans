# Shared NPC creator UI: audit and proposed redesign

Latest state: P5R6 control/frame/audio repair is verified; native acceptance is pending. See
[RANDOMIZATION_AND_BROWSER_AUDIT_AND_PLAN.md](RANDOMIZATION_AND_BROWSER_AUDIT_AND_PLAN.md)
for the implementation evidence and native retest; earlier design/verification below is historical.

Native P5R3 acceptance was rejected in the 2026-11-18 follow-up. The current
regression findings, implemented P5R4 repair and native retest matrix are in
[NATIVE_REGRESSION_AUDIT_AND_PLAN.md](NATIVE_REGRESSION_AUDIT_AND_PLAN.md).

Date: 2026-11-18. Status: user-approved design, repaired in P5R4; native acceptance remains unverified.
Scope: the starting-companion composer and debug Unique NPC Creator, using one shared authoring UI and the existing canonical NPC authoring system.

## Requested result

Use the supplied RimWorld reference for information structure: a selectable NPC roster at the left and compact topic tabs. Use the supplied Bandits reference for recognizable equipment slots with item icons. Keep Project Hoomans labels, relationship policies, data contracts, and existing runtime ownership. The references are visual guidance, not an instruction to copy their source or hard-code their slot catalogs.

This is a functional UI redesign, including reliable selection, editing, preview, presets and loadout persistence. Repositioning the current controls alone will not satisfy it.

## Evidence and limits

- User screenshot 1 is native visual evidence of overlapping General/Appearance controls and an inefficient roster/workflow layout.
- Inspected current Lua in `Contents/mods/ProjectHoomans/42.20/media/`, plus existing job documents and focused tests. Existing shared assets remain under `common/media/`.
- Graph discovery, a bidirectional inventory-entry trace, and a tab-builder snippet were followed by source reads. Coverage checks for 21 relied-on production/test paths returned `no_recorded_issue`, `metadata_match`, with no additional coverage pages.
- The graph generation is 2026-11-17T20:20:33Z. An attempted refresh aborted before publication and preserved the old graph; the service reports it is not watching this project. Therefore current source, rather than an exhaustive graph claim, supports the findings below.
- Architecture scan: UI pressure 47/100; a CharacterCreation/UI dependency cycle is a follow-up ownership concern. These heuristic scores do not establish the visual defects.
- Seven focused Lua tests passed (command below). No native game was launched or driven, and no claim of native visual or SP/MP acceptance is made.
- Repository observed on existing `main`, HEAD `75906e99`, six commits ahead of the locally recorded `origin/main`. Remote refs were not fetched. Unrelated semantic work is dirty and must be preserved. This audit adds only this proposal; it does not reopen or rewrite prior acceptance history.

## Findings

### 1. Confirmed tab visibility defect — highest priority

`UI/NPCAuthoring/PNC_NPCAuthoringEditor.lua:81` (`setAdapter`) explicitly sets both `formView` and `appearanceTab` visible. Both views occupy the same rectangle. This occurs when selecting a companion and bypasses the tab panel's active-view ownership.

The installed Build 42 `ISUI/ISTabPanel.lua:484` hides noninitial pages in `addView`; `activateView` at line 438 hides the previously active page and shows the selected one. The shared editor defeats that contract by revealing both pages itself. This is a direct explanation for the supplied overlap, though it does not establish that every visible problem has the same cause.

Repair contract: selected tab is the only visible/input-active page after construction, selection, refresh, no-selection recovery, preset loading, randomize, reset, and resize. Empty selection disables/hides the editor body through a container state, without independently revealing inactive pages.

### 2. Shared foundation exists and should be retained

`PNC_UniqueNPCEditorWindow.lua:45` and `PNC_StartingCompanionComposerWindow.lua:127` instantiate `ISPNCNPCAuthoringEditor`. The shared editor currently loads its body implementation from the UniqueNPCEditor module family.

Preserve one roster/editor/preview composition and one set of page controls. Workflow hosts supply roster entries, selection, permissions and actions. Companion mode keeps relationship inheritance and session writes; debug mode keeps draft/library and produce behavior. Different workflow policies do not justify duplicated forms or a second loadout system.

### 3. Roster is fragmented across top and bottom

`PNC_StartingCompanionComposerWindow.lua:69`, `refreshSlots`, `refreshSummary`, and `onResponsiveLayout` use a top dropdown plus a bottom summary. Neither gives the requested persistent selectable roster. The bottom summary consumes height that the form needs.

Replace these with a left roster: display name, relationship or archetype subtitle, selected state, and validation/dirty indicators. Companion entries come from active trait slots; adding/removing a roster entry must not bypass trait selection. Debug entries represent editable drafts/library entries, not a live-world NPC browser. Selecting a saved entry loads one editable draft rather than creating duplicate authorities.

### 4. Two broad tabs still contain multiple unrelated tasks

`PNC_UniqueNPCEditorWindow_Lifecycle.lua:50` builds General and Appearance only. `PNC_UniqueNPCEditorWindow_Layout.lua:177` places identity, background, configured collections and four Add rows into one companion page. Appearance combines outfit, voice, skin, hair/beard and advanced clothing overrides.

The profile has field metadata, but the builders and layouts still hard-code much of the grouping. Extend that presentation metadata into a small page registry and give each page cohesive controls. Do not create a generic UI framework or replace canonical storage.

### 5. Scaling has fixed minimums that can exceed available space

The companion host places seven actions in one row with a minimum per-button width (`ComposerWindow.lua:287`), while reserving a fixed footer summary. The shared layout reserves portrait/form minimum heights even when space is scarce (`EditorWindow_Layout.lua:5`). Appearance uses a minimum inner width and fixed multi-control skin-row offsets (`AppearanceWindow_Layout.lua:55`, `:86`). These assumptions can overflow at narrow widths or larger UI scales.

Use measured text/font heights, available-space allocation, wrapping action groups, bounded scroll regions and explicit compact breakpoints. Keep every interactive control inside its parent viewport; scroll content vertically instead of expanding the window beyond the screen.

### 6. Existing inventory editing is not an embedded loadout author

The debug toolbar has Inventory; the companion toolbar has Inspector only (`EditorWindow_Lifecycle.lua:25`). The debug action calls `InventoryWindow.OpenLocalDraft` (`EditorWindow_Actions.lua:270`), which opens another window (`InventoryWindow/_Lifecycle.lua:78`). Its LocalDraft endpoint copies from player inventory or removes/acts on draft items, synchronizes the runtime record back into that draft, and sets `_dirty` (`PNC_InventoryTransferEndpoint/_LocalDraft.lua`).

That path is useful existing inventory machinery, but it is not the requested catalog-backed, slot-oriented creator, particularly before a player inventory exists.

The canonical registry already describes `equipment`, `startingItems`, `inventory.startingTemplate`, and appearance. Equipment runtime normalization supports primary, secondary, worn, attached, and visual state (`PNC_Equipment_Slots/LoadoutState.lua`). Reuse those concepts after verifying exact slot compatibility and serialization; do not invent parallel slot storage.

### 7. A companion loadout edit needs explicit adapter coverage

`StartingCompanionAuthoringAdapter:CommitDraft` snapshots and writes fields from `NPCAuthoringEditorProfile.List("companion")`. The profile currently exposes appearance and `equipmentSpawnMode`, but does not include `equipment`, `startingItems`, or `inventory.startingTemplate`.

Merely embedding the debug inventory window or mutating a draft would not establish a persisted companion loadout edit. Extend presentation/capability and adapter coverage deliberately, then test save/load, final companion generation and transfer/server validation. The registry marks `equipment` nonnetworkable while `startingItems` is networkable: establish the supported payload/materialization path before changing any flag or promising multiplayer parity.

### 8. Existing passing tests miss the visible failure

`pnc_starting_companion_ui_interaction_smoke.lua:181` implements a replacement editor's `setAdapter`, so it does not exercise production tab visibility. The layout test supplies standalone controls and a tab-height table; `Layout.Pixels` ignores scale. Its assertions cover selected bounds, not actual tab lifecycle, all control intersections, text measurement, or hidden-page hit testing. The shared-editor smoke also contains source-string assertions.

Retain useful model tests; add production-component lifecycle/interaction coverage and stronger geometry checks. Passing bounds/model tests must not be described as native visual acceptance.

## Proposed screen

```text
+---------------------------------------------------------------------+
| Creator title                       Presets / Save / workflow actions |
+------------------+--------------------------------+------------------+
| NPC roster       | Bio | Appearance | Attributes | Character preview |
|                  | Loadout | Relationships       |                  |
| Phil Bishop      +--------------------------------+                  |
| Brother          | Active page only               | Rotate / zoom    |
|                  |                                |                  |
| ...              | Local scrolling as needed      | Name / summary   |
+------------------+--------------------------------+------------------+
| Validation / save status                         Close / host action |
+---------------------------------------------------------------------+
```

| Page | Contents |
| --- | --- |
| Bio | First name, nickname, surname, gender, archetype; faction where permitted |
| Appearance | Body/skin, hair/beard and colors; compact Face/body, Hair, Voice sections; only expose face controls actually supported by the runtime |
| Attributes | Skills with editable levels; separate NPC, physiological and dynamic trait collections with visible remove actions |
| Loadout | Outfit preset, clothing/body slots, held weapons, attachments, bags and carried items; equipment generation policy in this context |
| Relationships | Companion relationship and inherited field explanations; authorable relationship controls only where supported by existing data |

Appearance uses sections first; add subtabs only if content measurement warrants them. Do not invent unsupported age, face morph, or relationship editing just to resemble the references. Diagnostics remain a secondary inspector, outside ordinary editing.

Roster and preview widths are bounded proportions, leaving the middle the remaining space. Wide layouts show all three panes. Compact layouts reduce the preview footprint and allow a deliberate collapse/expand control; the roster stays readily accessible. Tabs may scroll horizontally when labels do not fit. Avoid shrinking all text to force a fit.

Use a sufficiently opaque panel background, consistent spacing, short labels, tooltips for policy explanations, and clear disabled/selected states. Long inherited-source text belongs below a field or in a tooltip rather than inside its label width.

## Loadout interaction contract

- Show icon tiles grouped by supported body/attachment location, with localized names and readable empty states. Grouping is presentation; engine-compatible slots remain the authority.
- Clicking a slot opens a searchable compatible-item picker. Equip/replace/clear must work with clicks; drag/drop is optional polish, not the only interaction.
- Show item name, slot, count where relevant, and incompatibility reason. Validate two-handed conflicts, clothing exclusions/layers, attachment compatibility and containers using existing runtime rules after verifying them.
- Distinguish generated/default, explicit override, and explicitly empty. Clearing an item must not silently restore it from the outfit/archetype on the next refresh.
- Clothing/outfit and equipment views must describe the same effective loadout. Changing an outfit must apply a defined preserve-or-replace policy to explicit overrides.
- Apply edits through one draft/session command path, refresh the portrait once per accepted change, and preserve generated seed/state on ordinary edits.
- Item catalog lookup must work during character creation without a live player. Bound/filter/cache catalog work and do not rebuild it every frame.
- Resolve equipment flags, starting-item representation, preview materialization, preset serialization, and server validation together. No new save format unless an evidenced gap requires it and compatibility is defined.

## Implementation sequence and gates

1. **Repair page lifecycle and strengthen regression coverage.** Exercise the production shared editor with vanilla-faithful tab behavior. Cover companion switching, active-tab retention, empty roster, preset load, reset/randomize and reopen. Gate: exactly one page visible/input-active; no stale portrait or draft from another NPC.
2. **Build the shared roster/layout shell.** Both hosts use the same component and page registry. Move companion summary into selectable roster rows; give debug draft/library entries the same selection UI. Gate: selection consistently identifies the roster row, form, portrait and save target.
3. **Move existing controls into compact pages.** Preserve canonical field IDs, inherited locks and normal/advanced presentation. Gate: every existing supported field/action remains reachable; traits/skills are visibly editable/removable; edits survive page/NPC changes.
4. **Implement the shared embedded Loadout page end to end.** First prove a clothing slot, a held item, and a carried item through draft edit, preview, preset save/reload and final definition. Then expand slot groups and conflict handling. Gate: both host modes persist identical supported intent through their existing policy adapters; no preview-only success.
5. **Complete scaling, accessibility and acceptance.** Test the matrix below and run relevant authoring, appearance, inventory, creation and server regression suites plus Lua/PZ compatibility and translation checks. Developer checks precede user-owned native acceptance. Native SP/MP results are recorded separately.

Each implementation slice must leave both callers usable. Reuse/move existing ownership rather than leave old and new editors as parallel systems. Do not broadly refactor PsychopatzCore: change shared UI primitives only if an independently reproduced primitive defect requires it, after checking that repository's instructions and state.

## Acceptance matrix

- Layout: 1280x720, 1366x768, 1920x1080, 2560x1440; available UI/font scales including 100%, 125%, 150%; resize through actual breakpoints; long/localized names and labels. Clamp restored geometry to the current screen.
- Geometry: all visible controls inside their viewport, no unintended sibling overlap, scrollbar width reserved, scroll offsets clamped after shrinking content, menus/modals visible, tabs and roster remain reachable.
- Lifecycle: open/reopen, switch every tab, select each NPC while a noninitial tab is active, lose/reacquire selection, add/remove active companion traits, last roster item removed, validation errors.
- Editing: text still focused when selecting another NPC or saving; visible selection/form/portrait/save target agree; invalid changes get readable feedback; inherited locks cannot be bypassed; no cross-NPC edit leakage.
- Workflows: randomize/reset/revert semantics, preset template vs set, old presets, missing item/mod identifiers, no live player inventory, unchanged draft round trip, preview stability for ordinary edits.
- Loadout: equip/replace/clear, outfit interaction, clothing layering, two-hand conflicts, attachment slots, bags/contents, counts, generated versus explicit-empty intent, save/load and final materialized NPC equivalence.
- Authority: final character creation, SP save/reload, MP/co-op server acceptance/reconnect/replacement-survivor behavior. Native execution remains user-owned unless explicitly assigned.

## Baseline verification

From repository root:

```sh
python3 tests/run_tests.py pnc_starting_companion_ui_layout pnc_starting_companion_ui_interaction pnc_shared_npc_authoring_editor pnc_starting_companion_shared_adapter pnc_unique_npc_editor_transfer pnc_unique_npc_appearance pnc_starting_companion_general_collections
```

Result: **7/7 passed**. This is a baseline and evidence of coverage gaps, not acceptance of the broken UI.

P5R3 implementation completed the developer-side sequence above. Production
lifecycle/composition and loadout regressions are in the Lua harness. Focused
suite: 45/45; full suite: 1038/1042 with the four previously documented unrelated
failures. Syntax/Kahlua/JSON/key-parity/whitespace checks pass. The implementation
uses icon slot rows and searchable lists rather than copying Bandits source;
compact widths expose a deliberate expanded-preview control. Native rendering,
font behavior and SP/MP/co-op outcomes still require P6 acceptance.
