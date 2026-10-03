# Faction Diplomacy Live Validation

## Scope

This matrix validates callback delivery, exact character attribution, attack
aggregation, treaties, runtime reconciliation, and persistence in an actual
Project Zomboid session. Automated Lua previews do not mark any live row as
passed.

Enable only the diagnostics needed for the session:

```lua
PNC.Config.Factions.DebugDiplomacyCallbacks = true
PNC.Config.Factions.DebugIncidentAggregation = true
PNC.Config.Factions.DebugIntentResolution = true
PNC.Config.Factions.DebugTreatyReconciliation = true
PNC.Config.Factions.EnableValidationTelemetry = true
```

All flags default to `false`. Restart or reload Lua after changing them, or
use **Diagnostics > Enable Live Diagnostics** to toggle the master runtime
telemetry flag on the authoritative server for the current session. Open the
admin/debug-only **PNC Faction Inspector** to inspect callbacks,
attribution, active aggregation episodes, escalation, intent traces,
reconciliation jobs, and invariant results. `Export Snapshot` writes a
primitive-only summary to the server log; it does not write arbitrary files.

## In-game debug GUI

Open the Psychopatz Core Debug Hub and choose **PNC Faction Inspector**. The
inspector is organized into four views:

- **Overview** creates/selects factions and summarizes the chosen pair.
- **Diplomacy** exposes treaties, guarded incident triggers, directional
  metrics, the selected intent rule, and attack/pursuit authorization.
- **Members** assigns or transfers NPCs and shows affiliation, role, rank,
  record revision, and presence revision separately.
- **Diagnostics** runs scenarios and invariant checks, repairs derived indexes,
  reconciles treaty targets, enables/disables or clears runtime telemetry, and
  displays active attack episodes.

Choose a source faction, a different target faction, and an NPC. The
inspector's **Overview** view contains the read-only diplomacy dashboard and
shows:

- the directed source-to-target treaty state;
- standing, trust, fear, and grievance bars;
- resolved intent and the selected rule;
- attack, pursue, and commandable results;
- selected NPC role/rank and record/presence revisions;
- active aggregation and treaty-reconciliation counts;
- invariant status and the latest telemetry result.

Press **Toggle NPC World Overlay** to show faction diagnostics directly above
each visible NPC, alongside the existing AI/animation debug nameplates. It
shows:

- organizational faction, archetype, role, and rank;
- relation and war state toward the current player's faction;
- authoritative intent, reason, and attack authorization;
- tactical class and player/NPC/zombie hostility flags;
- current order, active job, and target.
- directed player relationship approval, respect, familiarity, state,
  revision, and morale;
- the newest social mutation type and approval/respect/familiarity/morale
  deltas for 12 seconds.

The world overlay is also a separate tool in the Debug Hub and a checkbox in
Options > Mods. Red means the authoritative intent permits attacking the
current player. Yellow means a war is recorded but attack is blocked, which
is the key diagnostic for identity or treaty mismatches. The inspector and
world overlay consume the guarded server snapshot and cannot directly set
scores or bypass server authority.

### Phase 5B.1 live-status gate

As of Phase 5C implementation, the overlay's automated smoke coverage has run,
but no recorded Project Zomboid live session has validated opening/closing,
duplicate-handler behavior, 1280×720, normal development resolution, UI scale
above 100%, source/target refresh, telemetry toggling, attack episode
visualization, or treaty reconciliation visualization. Every one of those live
checks remains **NOT TESTED** until a result is recorded below.

## Result Record

Copy this row for every run.

| Field | Result |
|---|---|
| Scenario | |
| Game mode | |
| Server type | single-player / hosted / dedicated |
| Player count | |
| Mod version or commit | |
| Sandbox/config settings | |
| Callback telemetry | |
| Incident result | |
| Relation result | |
| Intent result | |
| Persistence result | |
| Pass/fail | NOT RUN |
| Notes | |

## Single-player matrix

| # | Scenario | Expected evidence | Result |
|---|---|---|---|
| 1 | Identity save/reload | Same character UUID and player faction | NOT RUN |
| 2 | One minor attack | One episode and one minor incident | NOT RUN |
| 3 | Repeated attacks | Same incident ID upgraded; no second incident | NOT RUN |
| 4 | Severe attack | Severe classification and expected effects | NOT RUN |
| 5 | Member killed | Kill incident and policy escalation trace | NOT RUN |
| 6 | Leader killed | Leader flag and stronger escalation | NOT RUN |
| 7 | War then peace | Stale human target cleared; zombie target retained | NOT RUN |
| 8 | War then truce | Ordinary faction aggression blocked | NOT RUN |
| 9 | Attack during truce | Truce broken and war reason recorded | NOT RUN |
| 10 | Alliance | Allied human targets cleared | NOT RUN |
| 11 | Break alliance | Protection removed without automatic war | NOT RUN |
| 12 | Neutral looter | Threaten weaker target; avoid stronger target | NOT RUN |
| 13 | War looter | Attack/pursue authorized | NOT RUN |
| 14 | Save/reload | Metrics, incidents, treaty, revisions preserved | NOT RUN |
| 15 | Transfer companion into active enemy faction | Ownership clears; overlay shows war/attack/hostile hunt; NPC acquires player | NOT RUN |
| 16 | Trigger a relationship debug event | Overlay `REL` values update and `CHANGE` shows the memory/event type and exact deltas | NOT RUN |

## Hosted multiplayer matrix

| # | Scenario | Expected evidence | Result |
|---|---|---|---|
| 1 | Player A attacks faction | A's exact `player:account:UUID` is actor | NOT RUN |
| 2 | Player B present | No attribution or relation change for B | NOT RUN |
| 3 | A and B own different factions | Only A's faction is source | NOT RUN |
| 4 | Compare revisions | Only involved pair changes | NOT RUN |
| 5 | A reconnects | UUID attribution survives online-ID change | NOT RUN |
| 6 | Verify binding | No `stale_runtime_binding` acceptance | NOT RUN |
| 7 | New survivor after death | New UUID does not inherit dead owner faction | NOT RUN |
| 8 | Peace with both online | Only involved faction-war targets clear | NOT RUN |

## Dedicated-server matrix

| # | Scenario | Expected evidence | Result |
|---|---|---|---|
| 1 | Identity and attribution | Exact character UUID on authority | NOT RUN |
| 2 | Callback order | Monotonic telemetry sequences | NOT RUN |
| 3 | Aggregation timeout | Episode expires at configured world age | NOT RUN |
| 4 | Member death | One idempotent kill upgrade/finalization | NOT RUN |
| 5 | Disconnect mid-episode | Episode cleanup is safe and traced | NOT RUN |
| 6 | Server restart | Persistent diplomacy survives; telemetry resets | NOT RUN |
| 7 | Large faction treaty | Queue completes in bounded batches | NOT RUN |
| 8 | Unrelated player targeting | No blame or attack authorization | NOT RUN |

## Factionless-player rule

A valid authoritative attack involving a player character and an
organizational faction calls the existing player-faction service. It ensures
exactly one personal faction owned by the exact character entity key, then
records the incident. This applies when the player is the attacker and when a
faction NPC attacks the player; harmless callbacks do not create factions.
Username-only and online-ID-only attribution are never accepted, and a later
survivor receives a different character identity.

## Save/reload revision check

Before saving, record registry, both faction, both relation, NPC
`recordRevision`, and `presenceRevision` values. After reload, confirm values
and incident IDs are unchanged. Runtime telemetry, active aggregation
episodes, and reconciliation jobs must be empty after a full server restart.
