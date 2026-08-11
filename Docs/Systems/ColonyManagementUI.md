# Colony Management UI

The client UI is a registered-tab subsystem rooted at:

`PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement.lua`

The entry file loads providers in dependency order and preserves the public
`PNC.ColonyManagementUI` API.

## Responsibilities

- `Components` owns panes, list renderers, and deterministic row binding.
- `Presentation` converts snapshots and selected NPCs into display rows.
- `Layout` owns responsive rectangles and pane bounds.
- `Registry` owns tab ordering and exposes `PNC.ColonyManagementUI.RegisterTab`.
- `Tabs` registers built-in tabs and adapts storage/research providers.
- `Controller` owns selection, refresh, tab switching, and row binding.
- `Diagnostics` owns the debug-only, event-focused UI trace.
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

Presentation builders should return rows without mutating UI controls. The
controller resets list scroll state and binds returned rows, keeping data
availability independent from rendering and resize behavior.

## Diagnostics

When Project Zomboid debug/admin access is available, the navigation bar shows
an `UI DIAGNOSTICS` checkbox. It logs only layout changes, snapshot requests
and application, tab/companion selection, and detail row counts. It never logs
per-frame render activity or full snapshot payloads.
