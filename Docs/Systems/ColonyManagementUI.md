# Colony Management UI

The client UI is a registered-tab subsystem rooted at:

`PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement.lua`

The entry file loads providers in dependency order and preserves the public
`PNC.ColonyManagementUI` API.

Provision Settings, Change Name, and Change Emblem are now owned by the main
Command Hub's `Colony` branch. Change Name opens the shared faction-name modal;
Change Emblem opens the reusable layered faction-emblem editor. Both retain
the existing authoritative client request paths. The legacy Colony Management
window now retains only the faction summary.

Workshop is now owned by the Command Hub's `Workshop` branch. It opens as the
persisted, detachable `PNC.WorkshopUI` widget; the legacy production renderer
is retained only as the shared catalog/action compatibility layer, and the
legacy Colony Management navigation no longer exposes a Workshop tab.

## Responsibilities

- `Components` owns panes, list renderers, and deterministic row binding.
- `Presentation` converts snapshots and selected NPCs into display rows.
- `Layout` owns responsive rectangles and pane bounds.
- `Registry` owns tab ordering and exposes `PNC.ColonyManagementUI.RegisterTab`.
- `Tabs` registers built-in tabs and adapts storage/research providers.
- `Controller` owns selection, refresh, tab switching, and row binding.
- `Diagnostics` owns the debug-only, event-focused UI trace.
- `UI/Workshop` owns the standalone Workshop widget lifecycle and delegates
  production rendering/actions through its controller.
- The Colonist `DEBUG` tab owns authorized storage/provision diagnostics and
  its dedicated control container; it sends authoritative colony actions and
  never mutates snapshot rows locally.
- `Window` owns the Project Zomboid window lifecycle and summary rendering.

## Adding a tab

Create a module that calls `PNC.ColonyManagementUI.RegisterTab` before the
window is instantiated, then require it from the entry hub before `Window`.

```lua
PNC.ColonyManagementUI.RegisterTab({
    id = "morale",
    title = "MORALE",
    detailTitle = "COLONY MORALE",
    showRoster = true,
    buildRows = function(context)
        return MyMoralePresentation.Build(context.selectedPerson,
            context.snapshot)
    end,
})
```

Optional hooks are `create`, `layout`, `apply`, `rebuild`, `render`, and
`action`. A tab can use `buildRows` for ordinary data-driven detail views or
`rebuild` when it owns specialized widgets such as the storage inventory.

Specialized controls must be children of a tab-owned panel. The tab's `apply`
hook sizes that panel from the current `layout.content` or pane rectangle and
resizes the ordinary pane around it. Do not position buttons or scrollbars
directly against the window: they will drift when the window scale, navigation
flow, or compact split changes. `Components.LayoutScrollbar` remains the single
place that synchronizes a list's native scrollbar to its container.

Presentation builders should return rows without mutating UI controls. The
controller resets list scroll state and binds returned rows, keeping data
availability independent from rendering and resize behavior.

## Diagnostics

When Project Zomboid debug/admin access is available, the navigation bar shows
an `UI DIAGNOSTICS` checkbox. It logs only layout changes, snapshot requests
and application, tab/companion selection, and detail row counts. It never logs
per-frame render activity or full snapshot payloads.

The same authorization exposes the `DEBUG` tab in the Colonists window. Its
selected-colonist view contains only the storage/provision diagnostics and
facility controls; need meters remain on the `NEEDS` tab. Increase hunger,
thirst, or fatigue by 0.25, reset needs, force provisions, inspect provision
diagnostics, or run a facility test. Every action is authorized and applied on
the server (or the single-player authority) and returns a fresh Colony
Management snapshot.
The tab's `Provision Diagnostics` control opens a separate responsive modal for
the selected colonist. The same modal is available as `Provision Stats` in the
debug NPC Monitor/directory.
