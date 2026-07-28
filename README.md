# ProjectHoomans

Standalone NPC framework for Project Zomboid Build 42.

This repository starts with a server-authoritative V1 slice:

- colonist NPCs with `Follow`, `Guard`, and `Patrol`
- hostile NPCs with shared `Melee` and `Ranged` combat
- live/abstract presence switching with runtime body leases and automatic stale-body cleanup
- vanilla-owned, lootable NPC corpses with lightweight death-location markers and authority-owned infected reanimation
- phased zombie-bite recovery that releases the engine bump state on interruption or timeout
- body-part wounds with vanilla-style timed bandaging, gradual First Aid-based
  healing, threat-aware NPC self-treatment, and server-side item consumption
- configurable bite infection, staged fever and health decline, infection death, and corpse reanimation
- multiplayer-safe authority flow with the same codepath used by singleplayer host
- population-scaled simulation with a shared zombie census, bounded aggro and
  NPC scheduler work, cached perception, and elapsed-time abstract travel
- persistent named journeys with waypoint waits, ETA/progress queries,
  live/abstract handoff, and an extensible vanilla-world-map overlay
- relationship-ready map visibility, role postfixes, pluggable marker icons,
  and per-client name controls
- budgeted native-engine routing for meaningful local/travel movement,
  combat approach, doors, and level transitions, while sub-tile corrections
  and committed attacks stay on the lightweight fake-locomotion lane
- pluggable route and speed providers plus configurable live-body admission
  caps, allowing large populations to travel abstractly while nearby NPCs
  materialize in distance-priority order
- an admin/debug-only NPC Monitor with lifecycle audits, filters, recovery controls, and overlay states

The framework is split into small subsystem files under `PNC/Core` so future work can extend jobs, behaviors, pathing, combat, and migration adapters without rebuilding the base.

## Journey API

Authority-side mods can start travel without touching NPC internals:

```lua
local journey, reason = PNC.API.Travel.Start(npcId, {
    destination = { x = 10600, y = 9800, z = 0 },
    routeProvider = "direct",
    speedProfile = "walk",
    ownerMod = "MyMod",
    ownerRef = "delivery:42",
    metadata = { purpose = "delivery" },
    -- Optional. When omitted, arrival becomes an area-roam order centered on
    -- the destination using the framework's default roam radius.
    arrivalAction = { type = "roam", radius = 8 },
})
```

`PNC.API.Travel.GetProgress(npcId)` returns current coordinates, percentage,
remaining distance, ETA in world hours, owner fields, and copied metadata.
Journeys can be paused, resumed, cancelled, or retargeted while retaining their
stable journey ID. Extensions can register route providers, speed profiles,
arrival handlers, travel listeners, client visibility filters, and independent
ordered map layers; each registration type has a matching unregister operation
for safe mod reloads. Canonical journey state remains server-owned and persists
independently of whether the NPC currently has a live engine body.

Arrival actions are serializable handler IDs plus configuration, so they work
across saves and multiplayer without persisting Lua functions. For example, a
trading integration can register its behavior once:

```lua
PNC.API.Travel.RegisterArrivalHandler("trading",
    function(record, journey, action)
        -- Install the trading mod's own order/job here.
        DynamicTrading.StartAtMarket(record.id, action.marketID)
        return true, "trading_started"
    end
)

PNC.API.Travel.Start(npcId, {
    destination = marketLocation,
    arrivalAction = {
        type = "trading",
        marketID = "west_point_hardware",
    },
})
```

An omitted action defaults to roaming, `{ type = "roam", radius = 12 }`
overrides its radius, and `{ type = "none" }` deliberately leaves the arrived
journey without a follow-up order.

## Map command framework

In debug mode, open the NPC Monitor, select a living NPC, and press
`Command Map`. The map centers on that NPC and remains unpaused so simulation
continues. Right-click a valid destination and choose
`NPC Commands → Move <name> here`. Idle and travelling NPCs are both displayed;
the selected NPC stays highlighted and its name remains visible.

The `NPC NAMES` button immediately left of the vanilla bottom map controls
toggles ordinary name labels. Selected and hovered NPCs remain identifiable
when labels are off. Marker colors are green for companions, yellow for
neutral NPCs, and red for hostile NPCs.

Map actions have separate client presentation and authority-side handlers:

```lua
PNC.API.MapCommands.RegisterProvider("scavenge", {
    order = 20,
    label = "Scavenge this area",
    canExecute = function(selection, target, map)
        return #selection > 0
    end,
    execute = function(selection, target)
        return PNC.MapCommands.Dispatch("scavenge", target, {
            searchRadius = 12,
        })
    end,
})

PNC.API.MapCommands.RegisterHandler("scavenge", {
    authorize = function(player, npcIds, target, options, context)
        -- Validate ownership, faction, range, permissions, or job capacity.
        return true
    end,
    execute = function(player, npcIds, target, options, context)
        -- Create a scavenging job for each accepted NPC.
        return { ok = true, accepted = #npcIds, rejected = 0 }
    end,
})
```

This split keeps world-map UI concerns independent from server-owned gameplay.
Future building, guard, investigate, trade, and scavenging commands can register
their own providers and handlers without adding branches to the map hook.

## Map presentation API

Map visibility and marker styling are independent of travel, so relationship,
trading, quest, and job mods can use the same contract for idle or moving NPCs:

```lua
PNC.API.MapPresentation.Set(npcId, {
    visibility = "known", -- all | known | selected | hidden
    roleTag = "trader",   -- rendered as [trader]
    iconID = "my_trader",
})

PNC.API.MapPresentation.SetKnown(npcId, playerUsername, true)

-- Client-side icon registration; texturePath or glyph may be used.
PNC.API.MapPresentation.RegisterIcon("my_trader", {
    texturePath = "media/ui/MyTraderMarker.png",
    size = 12,
})
```

`known` is a bounded persisted set keyed by player username. `selected` is
resolved locally per player, while `hidden` suppresses the marker unless that
player explicitly selects the NPC. The built-in placeholder icon IDs are
`trader`, `quest_giver`, `guard`, and `worker`. The debug NPC Monitor exposes
visibility, known/forgotten state, role tags, icon IDs, and trader/quest-giver
presets through its `Map Marker` menu.

Live NPC engine bodies are identified only by protected mod-data tags (`PNC_UUID`, body kind, and a runtime lease). Appearance, clothing, nakedness, and persistent outfit IDs are never authoritative identity. At death the full NPC record is retired; every immediate or delayed conversion path ensures exactly one named ID card on the final vanilla corpse, while the save keeps only a compact location marker until the corpse is confirmed missing. Corpse injection and replication are server-authoritative through PsychopatzCore. Live-body leases deliberately reset every session so bodies left behind by a prior session are quarantined before presence reconciliation.

The `NPC Bite Infection Chance (%)` sandbox option is evaluated only after a
zombie attack has already produced a bite. Setting it to `0` disables Knox
infection without altering combat, bite frequency, or the resulting bite wound.
Infection mortality and the real-time reanimation delay remain separately configurable.
