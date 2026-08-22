# Zombie-to-NPC damage audit

Status: current B42.20 implementation, audited 2026-08-23.

This is a standalone research note for the currently observed zombie-to-NPC
damage behavior. It records the present code and math only.

## Executive finding

The current PNC damage path does not use stamina as an incoming-damage gate.
Full stamina does not make an NPC invulnerable or harder to hit. Stamina is
currently used for attack spending, movement drain, recovery, and deciding
when a retreating NPC may re-engage.

The authoritative PNC path is:

```text
zombie reaches bite range
    -> PNC bite entry starts
    -> 450 ms windup
    -> CombatDefense performs one avoid roll
    -> on failure, one wound and one health reduction are applied
    -> 700 ms bite lease clears
```

The main potential conflict is a second, native Java zombie-attack lane. The
client temporarily gives a real zombie the NPC shell as its native target, but
also sets the real zombie to `NoTeeth` so the native collision does not apply
vanilla damage. If that flag is stale or cleared for a collision frame, native
damage bypasses PNC defense and stamina.

## 1. PNC bite lifecycle

`PNC_ZombieAggro_Bite.TryStartBite()` validates the target, floor, bite lane,
and zombie cooldown. It creates one bite entry with:

```text
applyAt = startTime + 450 ms
clearAt = startTime + 700 ms
appliedDamage = false
```

The bite entry owns the attacker through the windup. At `applyAt`,
`applyBiteDamage()` sets `appliedDamage = true`, resolves defense, and applies
damage only when the defense roll fails.

Source: `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Zombies/PNC_ZombieAggro_Bite.lua:232-410`.

## 2. Avoidance math

The current defense calculation uses:

- Fitness skill;
- zombies counted within `NPC_ZOMBIE_DEFENSE_RADIUS = 2.2` tiles;
- protection on the selected body part;
- a random roll.

It does not read `record.stamina.current`.

Let:

```text
F = Fitness, clamped to 0..10
N = nearby zombies counted within 2.2 tiles on the same floor
P = matching body-part protection, expressed as 0..100
```

### Base avoid chance

For Fitness below 2:

```text
baseChance = 0.90 + (F * 0.04)
```

For Fitness 2 or higher:

```text
baseChance = 0.98 + ((F - 2) * 0.0015)
```

### Crowd penalty

```text
crowdPenalty = max(0.075, 0.14 - (F * 0.005))
rawChance = clamp(
    baseChance - ((N - 1) * crowdPenalty),
    0.05,
    0.995
)
```

### Armor/protection adjustment

Protection reduces the remaining chance of harm rather than adding directly
to the avoid chance:

```text
finalAvoidChance = clamp(
    1 - ((1 - rawChance) * (1 - P / 100)),
    0.05,
    0.995
)
```

The outcome is:

```text
random < finalAvoidChance  -> avoided, no PNC damage
random >= finalAvoidChance -> hit, apply one PNC wound
```

### Default examples without armor

| Fitness | Nearby zombies | Avoid chance | Hit chance |
|---:|---:|---:|---:|
| 0 | 1 | 90% | 10% |
| 2 | 1 | 98% | 2% |
| 0 | 4 | 48% | 52% |
| 2 | 4 | 59% | 41% |

Therefore a close four-zombie group can legitimately produce frequent PNC
hits even when stamina is full. The defense crowd count is local to 2.2 tiles;
it is not the same as the broader tactical horde radius of 5.5 tiles.

Source: `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Combat/PNC_Combat_Defense.lua:109-286` and
`Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Base/PNC_Constants.lua:401-410`.

## 3. Wound and health math

After a failed avoid roll, the wound type is selected independently:

```text
roll < 20%                     -> bite
20% <= roll < 50%              -> laceration
roll >= 50%                    -> scratch
```

These are the current default per-wound type chances:

```text
bite       = 20%
laceration = 30%
scratch    = 50%
```

The corresponding damage values are:

```text
scratch    = 4
laceration = 8
bite       = 12
```

The selected wound is recorded first. `Health.ApplyDamage()` then applies the
same damage amount to the PNC body-health model. It does not subtract stamina
and does not check stamina before accepting zombie damage.

For a selected body part, the body-health distribution is:

```text
selected part: 2.0 * damage
each of the other 16 parts: 0.9375 * damage
```

The total distributed loss is 17 damage-units, so the average health value
loses the original damage amount. The selected part loses twice the normal
per-part amount, while the overall NPC health loses 4, 8, or 12 points for
scratch, laceration, or bite respectively.

Source: `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Health/PNC_NPCWounds.lua:506-539` and
`:749-820`, plus `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Health/PNC_Health.lua:430-499`.

## 4. What stamina currently does

The current stamina state is classified as:

```text
ratio <= 0.15 -> exhausted
ratio <= 0.40 -> winded
ratio <= 0.70 -> working
ratio >  0.70 -> fresh
```

Stamina is used by:

- `CanSpendAttack()` to require an attack reserve;
- `SpendAttack()` to drain melee, ranged, or downed-shove stamina;
- movement drain and recovery;
- retreat recovery and re-engagement checks.

The retreat re-engagement threshold is currently:

```text
current stamina >= max(35, stamina.max * 0.28)
```

None of these rules are consulted by `CombatDefense.ResolveZombieAttack()` or
`Health.ApplyDamage()`.

Sources: `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Stamina/PNC_Stamina.lua:183-301` and
`Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Combat/CombatTactics/PNC_CombatTactics_State.lua:154-165`.

## 5. Retreat timing

`Health.ApplyDamage()` calls `MarkZombieDamage()` only after the damage has
passed the authority and target-validity checks. That records the attacker and
opens the retreat pressure window:

```text
lastZombieAttackOutcome = "damaged"
attackPressureUntil = now + COMBAT_KITE_DAMAGE_PRESSURE_MS
damagePressureUntil = attackPressureUntil
```

This is a reaction to damage, not a pre-hit protection rule. It cannot prevent
the bite that caused the event.

Source: `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Combat/CombatTactics/PNC_CombatTactics_State.lua:211-229`.

## 6. Native Java attack-lane risk

The MP client aggro controller gives a real zombie the managed NPC shell as a
native target when close enough. It then sets:

```text
NoLungeAttack = true
ZombieBiteDone = true
realZombie:setNoTeeth(true)
```

The B42.20 Java `AttackState` skips its native collision callback when
`isNoTeeth()` is true. Without that guard, the Java state directly calls:

```text
target.getBodyDamage().AddRandomDamageFromZombie(...)
```

That native lane does not use PNC's Fitness/crowd/protection roll or stamina.
The client releases the managed target by clearing the target and setting
`NoTeeth` back to false. The server-side aggro code deliberately preserves
native target state during multiplayer ownership, so this needs runtime
instrumentation if extra hits continue to appear.

Sources:

- `Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/PresenceSync/PNC_ClientZombieAggroController.lua:270-337`.
- `zombie/ai/states/AttackState.java:151-155` and `:232-237` in the current Java baseline at `/home/psychopatz/Desktop/Projects/ZomboidDecompiler/output/source`.
- `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Zombies/PNC_ZombieAggro_State.lua:107-132` and `:298-315`.

The native duplicate is a risk, not yet a proven source of every observed hit:
the intended client safeguard should suppress the native collision. The
authoritative PNC damage path itself is server/authority-gated.

## 7. Additional state-consistency issue

`ApplyResolvedZombieAttack()` adds the wound before calling
`Health.ApplyDamage()`, and ignores the health function's return value. If the
health call is rejected because authority, lifecycle, or target protection
changed between resolution and application, the wound and sync event can
still be recorded. This is primarily a state/diagnostic desynchronization,
not the main cause of excessive health loss.

The legacy fallback `Wounds.ResolveZombieAttack()` uses a separate default
45% wound chance. It is reached only when the new defense result is unavailable,
but it should eventually fail closed rather than silently switch to different
damage math.

## Current conclusion

The confirmed behavior is:

1. Full stamina does not protect against zombie hits.
2. Close hordes sharply reduce the current avoid chance.
3. Retreat starts after accepted damage, so it cannot prevent that hit.
4. A native Java attack can bypass PNC math if `NoTeeth` protection is not
   continuously valid.
5. PNC and native damage should ultimately have one authoritative damage lane.

The next implementation should explicitly decide how stamina modifies the
authoritative defense roll, then add diagnostics that distinguish
`pnc_bite_damage` from any native `BodyDamage.AddRandomDamageFromZombie` event.
