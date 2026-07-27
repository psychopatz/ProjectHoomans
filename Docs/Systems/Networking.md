# Networking

## Purpose
- `PNC_Network` owns client-facing payload construction and replication only.
- the server registry remains authoritative; clients never create canonical NPC records.

## Current Payload Lanes
- `BuildRosterSnapshot`: compact list data sent in 50-record join chunks and batched roster deltas
- `BuildSnapshot`: live-presence and nearby view state
- `BuildCharacterPayload`: on-demand detailed payload for `View Character`
- `BroadcastRecord` and `BroadcastFullSync`: server dispatch only
- `BroadcastZombieReaction`: transient server-authored visual result for an
  NPC zombie-body hitting a normal zombie; clients resolve engine online IDs
  and replay reaction flags without running damage logic
- `BroadcastZombieBite`: two transition packets (`start` and `clear`) for the
  normal-zombie bite animation; canonical NPC damage remains server-only
- NPC bandaging is presented as a local timed action, but only its completion
  sends `CMD_BANDAGE`; the server revalidates the item, range, wound, and debug
  authorization before mutating or broadcasting the record

## Current Rules
- snapshot building reuses cached equipment and appearance data where possible
- full inventory payloads are on-demand, not sent every tick
- live snapshots and combat events are sent only to players inside the NPC interest set
- interest enters at 48 tiles and leaves at 56 tiles
- full character payloads require owner, admin, or same-level five-tile access
- inventory revisions use deltas while the operation log covers the client revision; gaps receive a full refresh
- roster removals are id-only tombstones and never build a character snapshot;
  optional nil payloads must use an explicit branch rather than Lua's
  `condition and nil or value` idiom, which always evaluates the fallback
- live-body client reconciliation is handled by `PNC_ClientPresenceSync`, not by networking itself
- movement stays on periodic compact snapshots, while attack starts, newly
  assigned body online IDs, and bite damage request one immediate transition
  snapshot instead of increasing the global movement frequency
- detailed health payloads carry the persisted infection stage, progress,
  fever, and temperature; clients never advance infection or subtract health
- corpse-to-zombie conversion runs only on the authority. The vanilla corpse
  reanimation routine allocates the server zombie ID, inserts the zombie,
  transfers corpse equipment, and removes the corpse; vanilla synchronization
  owns the resulting zombie while PNC sends only the NPC-record removal tombstone

## Forbidden Responsibilities
- does not tick AI
- does not resolve presence transitions
- does not write persistence records
- does not apply client visuals directly
