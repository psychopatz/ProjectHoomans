# Networking

Online player ownership lookup is backed by the refreshed spatial player maps.
Replicated zombie online-ID lookup consumes `PNC_WorldCensus`, so several
reaction packets in one frame do not each traverse the full engine zombie list.

## Purpose
- `PNC_Network` exposes the stable shared networking facade.
- the server registry remains authoritative; clients never create canonical NPC records.

## Module Layout

Shared networking modules:

- `PNC_Network`: public `PNC.Network` facade and shared state
- `PNC_Network_SnapshotParts`: reusable identity, movement, combat, roster,
  and debug-state payload sections
- `PNC_Network_Snapshots`: detailed snapshots, presence deltas, and character
  payloads
- `PNC_Network_Server`: transport fan-out, interest sets, roster deltas,
  removals, and server response payloads
- `PNC_Network_CombatEvents`: transient zombie reaction, bite, and firearm
  replication

Client networking modules:

- `PNC_Client`: bootstrap and top-level event wiring
- `PNC_ClientCommandRouter`: inbound command registry and dispatcher
- `PNC_ClientCombatCommands`: transient combat-event application and bite
  replica lifecycle
- `PNC_ClientRequests`: full-sync, debug-roster, and character-detail requests
- `PNC_ClientRosterCommands`: roster chunks, record deltas, and removal handlers
- `PNC_ClientInventoryCommands`: character payload, inventory delta, and result
  handlers
- `PNC_ClientActions`: outbound debug, map, health, companion, and inventory
  commands

Server command-routing modules:

- `PNC_ServerCommandRouting`: canonical ordered entry point for authoritative
  client-command routing
- `PNC_ServerCommandRouter`: thin command-to-handler registry and dispatcher;
  it does not reinterpret handler results or catch domain failures
- `PNC_ServerInventoryCommandHandler`: network adapter for inventory transfer
  and action requests; `PNC_ServerInventory` retains validation and mutation
- `PNC_ServerKnowledgeCommandHandler`: network adapter for player bootstrap,
  NPC presentation, knowledge disclosure, and world-discovery requests; the
  existing knowledge/discovery services retain validation, persistence, and
  response construction
- `PNC_ServerConversationCommandHandler`: adapter for conversation scene,
  category, choice, and recruit commands; scene and Authority services retain
  leases, eligibility rules, mutations, history, and response construction
- `PNC_ServerCharacterReplicationCommandHandler`: owns full-roster request
  assembly and authorized character-detail response selection; existing
  Registry and Network services retain record ownership, visibility policy,
  snapshot schemas, deltas, and transport
- `PNC_ServerHealthCombatCommandHandler`: adapter for revive, bandage, and
  player-weapon-hit requests; Revive, Treatment, and PlayerDamage retain
  validation and authoritative mutation
- `PNC_ServerGameplayRequestCommandHandler`: boundary adapter for companion
  orders, map commands, and faction-toll responses; their existing domain
  services retain policy, validation, and mutation ownership
- `PNC_ServerDiagnosticQueryCommandHandler`: authorized debug-roster,
  relationship, conversation-safe relationship, NPC-knowledge, and
  knowledge-debug query adapter; domain services retain snapshot policy
- `PNC_ServerAuthorityDiagnosticCommandHandler`: faction debug/member,
  community debug, Needs debug, and Director debug adapter; membership and
  diagnostic services retain validation, snapshot, and mutation policy
- `PNC_ServerColonyManagementCommandHandler`: colony snapshot/action adapter;
  ColonyManagement retains action policy while the adapter preserves
  action-result attachment and settlement delta/full response selection
- `PNC_ServerLegacyDebugCommandHandler`: compatibility adapter for the legacy
  `CMD_DEBUG` action envelope; it preserves one authorization gate and delegates
  to existing debug/domain APIs
- `PNC_ServerCommandRouter.CanUseDebug`: preserves the existing SP debug-mode
  and multiplayer-admin authorization policy for routed commands
- `PNC_ServerCommandRouter.Handle`: supplies handlers a normalized payload and
  the untouched raw payload as an optional third argument where legacy nil
  semantics must be preserved
- `PNC_Server`: retains the single `Events.OnClientCommand` registration and
  validates the `PNC` module namespace before router dispatch

All current server command families register through the canonical routing
entry. Unknown commands are consumed by neither the router nor a fallback
dispatcher and therefore remain no-ops.

Client presence-reconciliation modules:

- `PNC_ClientPresenceSync`: public facade, shared body maps, reset handling, and
  event wiring
- `PNC_ClientPresenceRuntime`: replica-mode policy and deduplicated diagnostics
- `PNC_ClientPresenceFacing`: throttled replicated facing
- `PNC_ClientPresenceVisuals`: identity, appearance, equipment, treatment
  audio, and animation application
- `PNC_ClientPresenceBodies`: body indexing, directed removal, and duplicate
  shell cleanup
- `PNC_ClientNativePathController`: nearest-client `PathFindBehavior2`
  ownership for MP live bodies. Presence ticks bind goals; actual native
  requests and updates run from that body's `OnZombieUpdate`, matching Bandits.
- `PNC_ClientPresenceTick`: snapshot refresh, body resolution, visual
  reconciliation, and per-frame orchestration. It does not write replicated
  NPC positions; native zombie networking owns MP transport.

New inbound commands should register a handler from their domain module through
`PNC.Client.Internal.RegisterServerCommand`. Existing callers should continue
using the public `PNC.Network.*` and `PNC.Client.*` APIs rather than requiring
feature modules directly.

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
- `BroadcastFirearmShot`: one transient, deduplicated visual/audio packet built
  from the equipped gun at its hit frame. It carries weapon/ammunition and
  projectile metadata but no permission to apply damage or consume ammo
- companion vehicle travel remains authority-owned. Clients receive at most
  the compact abstract passenger metadata (`vehicleId`, reserved seat, owner,
  and board time); they never attach an NPC zombie to a vehicle or decide when
  it should disembark. The authority mirrors each active reservation into the
  matching vanilla seat container with one private weighted token, using the
  normal container add/remove replication lane so every client sees the same
  occupied capacity. Clients may reject interaction with that token but never
  create, transfer, or remove authoritative reservations
- NPC bandaging is presented as a local timed action, but only its completion
  sends `CMD_BANDAGE`; the server revalidates the item, range, wound, and debug
  authorization before mutating or broadcasting the record
- NPC self-treatment runs only on the authority. Compact treatment phase,
  body-part, material, and timing fields replicate for nameplates; clients
  never choose a wound, consume companion inventory, finish an action, or
  advance gradual healing

## Current Rules
- snapshot building reuses cached equipment and appearance data where possible
- full inventory payloads are on-demand, not sent every tick
- live snapshots and body-bound combat events are sent only to players inside
  the NPC interest set. Firearm shots use the larger of that visual radius and
  the equipped gun's sound radius so players who can hear a loud gun are not
  omitted merely because they do not subscribe to the shooter's live snapshot
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
- client appearance identity is keyed by the live body lease/instance and
  actual appearance or worn-equipment fields. Combat draw/holster state has a
  separate hand key, so entering combat cannot recreate clothing, reroll its
  tint, or reset a committed attack animation
- attack mode remains replicated while a delayed attack action is active, even
  if target reassessment temporarily yields no target
- detailed health payloads carry the persisted infection stage, progress,
  fever, and temperature; clients never advance infection or subtract health
- client locomotion/resync diagnostics are deduplicated per NPC and state for
  five seconds, so enabling record diagnostics remains useful without
  producing a line every render/update frame
- corpse-to-zombie conversion runs only on the authority. The vanilla corpse
  reanimation routine allocates the server zombie ID, inserts the zombie,
  transfers corpse equipment, and removes the corpse; vanilla synchronization
  owns the resulting zombie while PNC sends only the NPC-record removal tombstone
- death immediately sends that removal tombstone and retires the full roster
  record. Lightweight death markers stay server-owned and are exposed only
  through authorized lifecycle diagnostics

## Forbidden Responsibilities
- does not tick AI
- does not resolve presence transitions
- does not write persistence records
- does not apply client visuals directly
