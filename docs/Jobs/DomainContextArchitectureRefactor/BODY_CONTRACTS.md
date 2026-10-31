# BodyLifecycle external contracts

Public entry: `shared/PNC/Core/Presence/PNC_BodyLifecycle.lua`.
Presence owns the lifecycle; Pathing and Tasking consume its public functions.
`PNC.BodyLifecycle.Internal` is private and guarded against foreign access.

| Surface | Meaning |
| --- | --- |
| `BodyLifecycle.MatchesRecordBody(record, body)` | Existing read-only ownership/lease predicate, including foreign ownership, attachment, UUID and incarnation checks. |
| `BodyLifecycle.Corpses.ForEach(square, callback)` | Enumerate one square's corpse lists with existing deduplication. No region/world scan is added. |
| `Corpses.Move(corpse, square, x, y, z)` | Existing square transfer and exact-object rollback. |
| `Corpses.Follow(corpse, x, y, z)` | Existing same-tile repair or cross-tile handoff. |
| `Corpses.Remove(corpse)` | Existing membership/world removal. |
| `Corpses.Stamp(record, corpse, token)` | Existing inert corpse/death-marker identity and dirty-state update. |
| `Corpses.Transmit(corpse, fullSync)` | Existing distinction between metadata updates and first-materialization packets. |

These are direct references to the existing owner functions. No new mutable
body state, wrapper calls, runtime scans or event fanout are introduced. The
mutation operations are for authority-owned lifecycle/task execution. Tasking
retains its server-role guards, work admission, haul tokens/reservations and
bounded carry cadence; native pathing retains its authority and lease gates.

M12 remains authoritative: durable NPC records differ from disposable carriers;
MP server human visuals, client replica non-ownership, saved-live restart proof,
late-stream retirement and the SP local path are unchanged. The engine policy
providers are byte-identical in this migration.

MCP discovers the public module before the implementation. Its current indexer
does not emit these function-reference fields as searchable functions or fully
resolve callers through them. Read the small public entry, then the named owner
function snippet. A reduced private-function caller count is not dead-code proof.
`P7A_BODY_BOUNDARY_PROOF.json` records source and validation evidence.
