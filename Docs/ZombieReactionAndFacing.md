# Zombie Reaction And Facing

## Ownership

- `PNC_Combat_ZombieReaction.lua` owns short NPC-on-zombie shove and hit
  reactions.
- `PNC_LocomotionProfiles.lua` owns shared fake-locomotion profile resolution
  for walk, run, sneak, crawl, and recovery cadence.
- `PNC_PathService.lua` owns facing leases and decides whether combat or
  locomotion currently controls body facing.
- `PNC_FakeLocomotion.lua` owns travel transport and asks pathing to face the
  body along the actual step direction.

## Rules

- Zombie shove reactions are server-owned short windows, not one-frame flag
  flips.
- Default shove behavior is stagger plus pushback; knockdown is reserved for
  explicit heavy reactions.
- Combat may lease facing briefly for attack windup, attack follow-through, or
  close repositioning.
- Re-publishing a combat lease does not force another engine facing request.
  Direction/interval throttling remains authoritative so `turnalerted` cannot
  race locomotion on every update.
- Outside those leases, locomotion owns facing and points the NPC along travel
  direction.
- Retreat movement does not renew combat-facing leases; NPCs face their travel
  direction instead of fighting the movement controller or fake-backpedaling.
- Zombie hit reaction selectors are written once at impact and stagger flags
  are cleared when the short reaction lease expires.
- Snapshot `visualState` mirrors the resolved motion profile fields so nearby
  clients replay the same walk, run, sneak, and crawl choice instead of
  inferring posture from reduced hints.
- SP and listen-server bodies are faced only by `PNC_PathService`; the client
  snapshot loop faces only remote visual replicas and throttles repeated
  directions.
