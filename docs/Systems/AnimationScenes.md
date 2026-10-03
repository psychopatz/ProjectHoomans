# Animation scenes

PNC animation scenes are named, authority-owned requests that replicate the
same bump animation to single-player and multiplayer clients. They are intended
for optional idle gestures, emotes, conversations, surrender, scripted jobs,
and other animations that should not be hard-coded into locomotion or combat.

## Registering a scene

Register shared definitions after `PNC/00_PNC_Init` has loaded:

```lua
PNC.API.AnimationScenes.Register("my_mod.wave", {
    label = "Friendly Wave",
    description = "A short greeting gesture.",
    category = "social",
    bump = "WaveHi",
    durationMs = 2400,
    priority = 20,
    loop = false,
    blocking = false,
    interrupts = {
        movement = true,
        externalBump = true,
    },
})
```

Registering an existing scene ID replaces its policy and selector globally.
This is the supported way to swap a built-in scene without editing PNC:

```lua
PNC.API.AnimationScenes.Register("idle.shift_weight", {
    bump = "MyMod_ShiftWeight",
    durationMs = 2800,
    priority = 10,
    pool = "idle",
    weight = 5,
})
```

`bump` is the PNC selector without the optional `PNC_` prefix. The matching
XML node still needs `PNCActor=true` and a namespaced
`BumpType=PNC_<selector>` condition.

Supported policy fields:

- `label`, `description`, and `category`: optional scene-lab metadata. Category
  defaults to the prefix before the first dot in the scene ID.
- `durationMs`: authority window for a finite scene; zero means persistent.
- `priority`: higher requests replace lower scenes. Lower requests are rejected.
- `loop`: keeps the selector leased and repairs it if the engine drops it.
- `blocking`: pauses behavior and movement until the scene stops.
- `pool`: optional weighted injection pool such as `"idle"`.
- `weight`: selection weight inside the pool.
- `interrupts.movement`: movement requests may stop the scene.
- `interrupts.externalBump`: combat, treatment, traversal, and other bump
  actions may replace the scene.
- `interrupts.abstract`: materialization changes may discard the scene.

Definitions must contain serializable data. Do not put Lua callbacks in a scene
definition; gameplay conditions belong in the behavior that requests it.

## Playing and stopping

Authority-side code can play by NPC ID:

```lua
PNC.API.AnimationScenes.Play(npcId, "my_mod.wave", {
    reason = "greeting",
})

PNC.API.AnimationScenes.Stop(npcId, "greeting_finished")
```

Code that already owns a record and live body can avoid another lookup:

```lua
PNC.AnimationScenes.Request(record, zombie, "social.surrender")
PNC.AnimationScenes.StopSurrender(record, zombie)
```

Scene identity, revision, selector, loop policy, and timing are carried in the
normal NPC visual snapshot. Clients select the XML node once and only maintain
looping scenes, preventing snapshot replays from restarting one-shot clips.

## Built-in scenes

- `idle.shift_weight`
- `idle.smell_bad`
- `idle.smell_gag`
- `idle.sneeze`
- `social.surrender`

The four idle scenes use the weighted `idle` pool. Idle injection is evaluated
on the existing NPC behavior cadence, not every render frame, and is only
eligible while the NPC has no movement, traversal, treatment, target, attack,
or incapacitation state. A movement or external bump immediately interrupts
them.

`social.surrender` is a blocking persistent loop. Stop it explicitly when the
surrender gameplay state ends. An external bump, such as taking a hit, may
interrupt it so the NPC cannot remain animation-locked through damage.

## Scene lab

With debug access, right-click an NPC and choose **Debug → Animation Scene
Lab**, or open it from the XML animation player. The lab enumerates the live
scene registry, so newly registered categories, pools, and variants appear
after **Refresh Registry** without adding UI code.

- **Play Scene** requests the selected scene through the real authority route.
- **Roll Pool Once** performs one weighted selection from the selected scene's
  pool.
- **Auto Cycle Pool** repeatedly plays complete variants with the configured
  gap. It avoids an immediate repeat when the pool has alternatives.
- **Stop Scene / Cycle** releases both the active bump and test controller.

The detail panel deliberately shows both the authoritative replicated scene
and the local client body's `BumpType`/action state. A scene showing as active
on the authority but absent on the local body therefore identifies a
replication or XML-selection failure instead of producing a false-positive
client preview.
