# PNC Traversal Query

## Ownership

`PNC_TraversalQuery.lua` is the read-only owner for grid occupancy, door/window
passage, and fence-edge queries. It does not move bodies or play animations.

- `PNC_FakeLocomotion` asks whether a small controlled step is safe.
- `PNC_PathService_Interactions` owns door, window, and fence actions after a
  blocked step.
- Behaviors continue to publish movement intent only.

## Runtime Contract

- Live body transforms remain server-authoritative in singleplayer and
  multiplayer.
- Closed passages and fences block ordinary fake steps so the interaction lane
  can handle them explicitly.
- Full wall and blocked-edge checks prevent free destination squares on the
  other side of a wall from being treated as reachable.
- Doors, windows, and fences return distinct block reasons. A direct passage
  block is offered to the interaction owner before wall-follow steering.
- Local steering keeps one side preference around solid obstacles to avoid
  left/right oscillation, then clears it after sustained direct progress.
- Fence traversal uses one obstacle edge and one validated landing square; the
  same special-move lease and motion hint used by windows is replicated to
  clients.
