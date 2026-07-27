# PNC Traversal Query

## Ownership

`PNC_TraversalQuery.lua` is the read-only owner for grid occupancy, door/window
passage, and fence-edge queries. It does not move bodies or play animations.

- `PNC_FakeLocomotion` asks whether a small controlled step is safe.
- `PNC_PathService_Interactions` owns door, window, and fence actions. It can
  consume an exact passage returned by the goal-directed adjacent-edge probe
  before a blocked step occurs.
- Behaviors continue to publish movement intent only.

## Runtime Contract

- Live body transforms remain server-authoritative in singleplayer and
  multiplayer.
- Closed passages and fences block ordinary fake steps so the interaction lane
  can handle them explicitly.
- Full wall and blocked-edge checks prevent free destination squares on the
  other side of a wall from being treated as reachable.
- `IsoGridSquare:isVehicleIntersecting()` is part of destination occupancy;
  vehicle chassis squares are therefore routed through obstacle steering
  instead of being entered by fake locomotion.
- Doors, windows, and fences return distinct block reasons. A direct passage
  block is offered to the interaction owner before wall-follow steering.
- `FindPassageToward` probes the dominant goal axis and then the secondary
  cardinal axis, avoiding diagonal edge ambiguity while still recognizing
  doors and windows owned by either adjacent square.
- Local steering keeps one side preference around solid obstacles to avoid
  left/right oscillation, then clears it after sustained direct progress.
- Fence traversal uses one obstacle edge and one validated landing square; the
  same special-move lease and motion hint used by windows is replicated to
  clients.
