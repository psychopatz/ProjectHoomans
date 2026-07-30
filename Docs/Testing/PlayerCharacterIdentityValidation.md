# Player-Character Identity Live Validation

Automated Lua tests validate identity logic and persistence shape, but cannot
prove which Build 42.20 callbacks arrive in every runtime mode. Enable:

```lua
PNC.Config.Relationships.DebugPlayerIdentity = true
PNC.Config.Relationships.DebugCombatCallbacks = true
```

Expected concise lines resemble:

```text
[PNC PlayerIdentity] callback=authoritative_sweep accountIdentity=Patrick characterUUID=char_... status=active worldAgeHours=182.5 onlineID=0 result=assigned reason=new_identity
[PNC CombatCallback] callback=OnWeaponHitCharacter event=weapon_hit worldAgeHours=183.1 onlineID=0 result=received
```

Failures include a new UUID on ordinary reconnect, `account_identity_unavailable`
for a valid server player, two simultaneous players logging the same UUID,
repeated death revisions, missing combat callback lines, or memories keyed only
by a username/online ID.

## Single Player

1. Start a new survivor and record the assigned UUID.
2. Save, exit, and reload; verify the UUID is unchanged.
3. Treat an NPC wound and inspect the NPC memory target
   `player:<account>:<recordedUUID>`.
4. Fight zombies with an NPC present; verify weapon-hit, identity-resolution,
   encounter, neutralization, and encounter-end diagnostics that actually
   arrive.
5. Die; verify the old registry record becomes `dead` once.
6. Create a new survivor; verify its UUID differs.
7. Verify old NPC memories still target the dead UUID and the new survivor has
   no inherited personal relationship.

## Hosted Multiplayer

1. Connect the host and a second account with new survivors.
2. Verify each receives a distinct UUID and account-qualified entity key.
3. Disconnect and reconnect each survivor; verify both UUIDs remain stable.
4. In a controlled debug save, place the other account's UUID in one survivor
   mirror; verify the claim is rejected and ownership is unchanged.
5. Treat an NPC wound from each player and verify the correct stable target
   keys.
6. Trigger player/NPC combat and record which callback diagnostics arrive.

## Dedicated Server

1. Connect a new survivor and record its UUID.
2. Disconnect cleanly; verify status remains `active` and the runtime binding
   is cleared by the authoritative sweep.
3. Restart the server and reconnect the same survivor; verify the UUID is
   unchanged.
4. Trigger treatment and combat social events and verify server-side
   processing.
5. Die and create a new survivor; verify old=`dead`, new=`active`, and UUIDs
   differ.
6. Verify no duplicate runtime binding remains after disconnect or death.

`OnPlayerDeath` is statically known to be local-player-only in the inspected
Build 42.20 bytecode. Dedicated-server death should therefore be observed
through the one-second authoritative `isDead()` sweep. If it is not, retain the
diagnostic logs and add a proven server callback adapter; do not guess a
callback name or accept a client death command.

## Recording Results

For each mode record the game build, server type, callback lines observed,
initial/reloaded/dead/new UUIDs, the inspected relationship key, and any
failure. Do not mark a scenario passed from static or automated tests alone.
