# Networking

## Purpose
- `PNC_Network` owns client-facing payload construction and replication only.
- the server registry remains authoritative; clients never create canonical NPC records.

## Current Payload Lanes
- `BuildRosterSnapshot`: compact list data for joins and broad roster views
- `BuildSnapshot`: live-presence and nearby view state
- `BuildCharacterPayload`: on-demand detailed payload for `View Character`
- `BroadcastRecord` and `BroadcastFullSync`: server dispatch only
- `BroadcastZombieReaction`: transient server-authored visual result for an
  NPC zombie-body hitting a normal zombie; clients resolve engine online IDs
  and replay reaction flags without running damage logic
- `BroadcastZombieBite`: two transition packets (`start` and `clear`) for the
  normal-zombie bite animation; canonical NPC damage remains server-only

## Current Rules
- snapshot building reuses cached equipment and appearance data where possible
- full inventory payloads are on-demand, not sent every tick
- live-body client reconciliation is handled by `PNC_ClientPresenceSync`, not by networking itself
- movement stays on periodic compact snapshots, while attack starts, newly
  assigned body online IDs, and bite damage request one immediate transition
  snapshot instead of increasing the global movement frequency

## Forbidden Responsibilities
- does not tick AI
- does not resolve presence transitions
- does not write persistence records
- does not apply client visuals directly
