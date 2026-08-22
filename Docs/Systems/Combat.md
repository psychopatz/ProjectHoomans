# Combat

## Shared Services
- `PNC_Combat` is the entry layer only
- the bootstrap explicitly loads pathing, reaction, tactics, zombie aggro, and
  attack-action modules in dependency order; combat correctness must not rely
  on incidental automatic Lua file ordering
- `PNC_Combat_Melee`, `PNC_Combat_Ranged`, `PNC_Combat_Firearms`,
  `PNC_Combat_AttackActions`, `PNC_Combat_Tactics`, and
  `PNC_Combat_Unarmed` own focused combat responsibilities
- custom damage routes through `PNC_Health`
- player weapon hits damage neutral and hostile NPCs through a server-authoritative hit bridge; colonists are protected from player damage
- hostile NPCs treat companions and neutral survivors as enemies; companions
  and neutrals reciprocally recognize hostile NPCs while remaining peaceful
  with each other
- an accepted player weapon hit converts a neutral NPC to hostile, immediately
  assigns hostile hunting behavior, and makes it a valid companion target
- live NPC bodies use a high engine-health safety buffer so vanilla zombie-body damage cannot bypass custom HP, incapacitation, or multiplayer validation
- players, NPCs, and zombies use the same target format

## Current Rules
- melee and ranged attacks are server-authoritative delayed-hit actions, not immediate damage writes
- attack start is an immediate state-transition snapshot. Native zombie
  networking owns the remote body's position, while the hit frame uses a small
  range tolerance rather than movement-sized reach padding
- attack actions explicitly release the engine bump channel when the animation
  finishes, the target is lost, or the bounded action timeout expires; release
  remains pending until the ActionContext acknowledges that it left `bumped`
- the authority selects the combat animation and owns hit timing/damage but
  does not enter the visual bump state. The rendering client plays and
  finishes attack snapshots in single-player, listen-server, and dedicated
  multiplayer alike; native zombie networking owns replicated movement
- one- and two-handed melee families each rotate between two PNC human attack
  nodes using the engine/Bandits bump identifiers (`Attack1H1`, `Attack2H1`,
  and variants). A short bounded client retry repairs packet-interrupted action
  entry without looping completed swings
- melee swing audio reuses the already resolved live hand weapon instead of
  constructing another inventory item for the same attack
- once an attack windup is committed, its action pump temporarily owns the
  behavior tick independently of fresh perception. A short LOS/index miss
  therefore cannot cancel the swing, holster its weapon, or skip its delayed
  hit/finish frame
- weapon hits use a short passive settlement lease: vanilla hit/stagger owns
  animation, while PNC aggro temporarily refrains from clearing the attacker or
  issuing path/bite commands that would freeze the reaction state
- multiplayer weapon hits publish the resulting nonlethal health and cosmetic
  hit reaction to clients; only the server applies damage, wear, death, and
  target provocation
- zombie-on-NPC pursuit uses throttled coordinate repaths because the NPC's
  embodied engine type is also `IsoZombie`; bite bump state is explicitly
  entered and cleared so a completed bite cannot strand the attacker
- PNC zombie-side work is limited to an expiring active set populated by
  spatial proximity, provocation, aggro leases, and bite leases. The server
  processes at most 64 active zombies and issues at most 16 pursuit path
  requests per tick; unrelated zombies remain entirely vanilla-owned
- nearest NPC acquisition queries nearby numeric spatial cells instead of
  scanning every live NPC for every zombie
- committed point-blank melee swings tolerate transient LOS changes during the
  windup, revalidate range at the hit frame, and verify that the engine hit
  actually changed zombie health before using authoritative fallback damage
- delayed attacks retain a runtime-only direct zombie reference plus the stable
  spatial ID, and cancel immediately with `target_lost_or_dead` if neither
  resolves before the hit frame
- companions and hostiles can acquire zombie targets; neutrals reserve combat
  for hostile NPCs until their disposition changes
- companions prioritize an ordinary zombie whose live engine target is their
  owner. This urgent defense lane bypasses follow-stealth suppression and the
  rotating LOS budget because the owner is already under active attack
- companion, roaming, and hostile behaviors share periodic target
  reassessment. A nearby enemy actively attacking the NPC takes priority over
  a passive target; otherwise a substantially closer candidate may replace the
  current target, with a short reassessment interval and distance hysteresis
  preventing target flicker
- recent validated damage identifies NPC and player attackers as immediate
  threats for a bounded memory window
- initial player, NPC, and zombie acquisition requires an unobstructed visual
  trace; closed doors and walls do not count as visible
- zombie acquisition reuses a 200 ms per-NPC perception frame. It performs one
  spatial query, derives all combat-pressure radii from the same sorted
  candidate list, and limits LOS work to a rotating window of six candidates
  plus a remembered attacker. A fully blocked window advances on the next
  frame so farther visible threats are not permanently hidden. Pressure counts
  are intentionally geometric while attack selection remains LOS-gated
- a lost target is investigated at its last seen position for a short memory
  window, but its live position is not tracked and attacks are cancelled while
  line-of-sight is blocked
- unarmed combat uses shove and ground-finisher behavior instead of weapon swings
- armed melee detection follows the actual equipped weapon item, not its optional
  animation-family classification; a valid modded weapon therefore cannot
  silently become a barehand shove
- ranged NPCs require a validated firearm instance. Spawn templates satisfy
  that contract through inventory equipment generation
- in-range ranged NPCs explicitly replace any previous travel intent with an
  aim hold, face the live target through both the engine object-facing API and
  the replicated combat-facing lease, and keep that aim through cooldowns
- ranged facing falls back to the target's last authoritative coordinates when
  its live engine object is temporarily unresolved, and the direct normalized
  heading is replicated for remote attack animations
- firearm attack nodes initialize their animation speed/scalar variables before
  entering the bump channel, allowing the vanilla handgun/rifle shot animation
  to reach its visible recoil frames on both the server body and client replicas
- `Companion Ammo Realism` retains the legacy `NPCAmmoConsumption` sandbox key
  for save compatibility. Every ranged NPC uses the equipped firearm's script
  clip size, persists the loaded round count on that inventory weapon, and
  performs a timed weapon-family reload when the magazine is empty. When
  realism is enabled, recruited/player-owned companions consume matching loose
  rounds and stop when their reserve is empty. Autonomous NPCs—and companions
  with realism disabled—reload from an infinite reserve instead of bypassing
  magazine limits
- reload and magazine changes are server-authoritative inventory deltas. Reload
  start/finish transitions use the normal presence snapshot stream so remote
  clients see the same pistol, rifle, shotgun, revolver, or double-barrel
  animation without applying ammunition locally
- a firearm produces its shot at the authoritative delayed-hit frame, not at
  animation start. `PNC_Combat_FirearmEffects` derives the ammo ItemKey,
  ammo-per-shot, shot/shell/impact sounds, noise radius and volume, projectile
  count/spread, range, and piercing flag from the equipped `HandWeapon`; this
  keeps modded guns data-driven instead of adding PNC weapon-name tables
- the server consumes the weapon-defined rounds and publishes the vanilla-style
  world sound that attracts zombies. A transient shot event lets clients play
  that firearm's positional audio and render its native muzzle hook, a bounded
  two-tick orange light, and projectile-count-aware tracers; clients
  never apply firearm damage or ammunition changes
- tracer rendering follows the proven Bandits-style screen-space flight model:
  a floor-level isometric origin, direction-corrected 600-pixel streak, and
  12 draw-frame lifetime. Weapon projectile count and spread still come from
  the current `HandWeapon`, so shotguns and modded multi-projectile guns fan out
  without hardcoded weapon names
- the debug overlay exposes loaded rounds, magazine capacity, reload state, and
  either the companion's loose reserve count or `infinite`; this row has its
  own in-game overlay toggle
- idle NPCs keep both melee weapons and firearms out of their hands. The active
  primary weapon is attached to the best compatible holster/belt/back slot and
  transitions to the hands only while the combat target is active; the same
  attack-mode transition is replicated to multiplayer clients
- combat-hand state is verified against the live body before the presentation
  cache returns `unchanged`. If an engine action transition discards the hand
  item, only the hand model is repaired; worn clothing is never rebuilt
- ranged attacks use half the base stamina of melee attacks (10 versus 20)
- ranged combat owns locomotion before the aim/fire branch. Shooters maintain a
  preferred minimum distance of 5 tiles and, under zombie pressure, retreat
  away from the local horde centroid instead of allowing roam/follow movement
  to pull them into the target
- retreat locks preserve the chosen escape vector between AI ticks. A ranged
  NPC runs while stamina permits and degrades to walking when exhausted;
  reload and committed attack actions still halt movement for their timed
  animation, leaving the intended windows in which enemies can catch it
- when a finite-reserve shooter reaches `out_of_ammo`, the authoritative
  equipment service deterministically equips a usable carried melee weapon,
  preferring the generated reserve slot. If none exists it clears the firearm
  from the primary hand and enters the existing barehand shove lane
- natural equipment generation can produce melee-only, ranged-only, both, or
  unarmed NPCs; combat mode follows the generated equipment rather than the
  NPC archetype
- combat can trigger conservative kiting and repositioning through `PNC_Combat_Tactics`
- horde-aware combat now prefers lower-density zombie picks over blindly taking the nearest body
- low-stamina combat below the retreat threshold enters a recovery retreat instead of standing in place
- surrounded melee pressure can add a shove-back stagger to create breathing room after a hit
- combat debug state exposes target kind, resolved mode, weapon status, and block reason
- repeated identical combat-block diagnostics are rate-limited per NPC and
  combat lane so the 75 ms combat cadence cannot flood the Lua log

## Zombie-to-NPC Damage Model (Design Before Implementation)

This section is the design target for the next zombie damage implementation. It
is intentionally separate from the current `PNC_Combat_Defense` behavior above;
the implementation must not be started until this model and its sandbox
surface are accepted.

The model treats stamina as a temporary defensive resource. While the NPC is
above the configured stamina-safe ratio, zombie damage rolls are impossible.
When stamina falls below that ratio, each valid zombie attack gets one
authoritative damage roll. Fitness and related defensive skills reduce the
resulting exposure, but do not make an exhausted NPC invulnerable.

### Resolution order

Every live zombie attack must use this order on the authority. In multiplayer,
the server owns the roll; in single-player, the host/authority owns it. Clients
only receive the resolved result for presentation.

```text
valid zombie attack
    -> obtain cached hit-zone pressure
    -> stamina-safe gate and fatigue exposure
    -> crowd chance calculation
    -> Fitness/skill mitigation
    -> one damage-exposure roll for this bite lease
    -> choose body part and roll initial wound type
    -> clothing protection roll
    -> sacrifice clothing durability
    -> block the wound, or downgrade/apply the wound
    -> publish the authoritative result and mark zombie pressure
```

The native Java `BodyDamage.AddRandomDamageFromZombie(...)` lane must not be
allowed to apply a second independent wound. The `NoTeeth` safeguard remains a
visual/engine safety measure, but it is not a substitute for routing every
damage result through this resolver.

### Stamina gate

Normalize stamina once for the attack:

```lua
s = clamp(currentStamina / maxStamina, 0, 1)
safe = Sandbox.NPCZombieDamageStaminaStartRatio()

if safe <= 0 then
    fatigueExposure = 1
elseif s >= safe then
    fatigueExposure = 0
else
    t = clamp((safe - s) / safe, 0, 1)
    fatigueExposure = t * t * (3 - 2 * t) -- smoothstep
end
```

With the proposed default `safe = 0.30`, an NPC above 30% stamina cannot take
zombie damage through this lane. Below 30%, exposure rises smoothly instead of
turning on at one exact frame. Setting the sandbox value to `1.0` makes only
full stamina safe; setting it to `0.0` disables stamina immunity and restores a
normal damage-roll model.

This protection applies only to incoming zombie damage. Attack stamina costs,
movement exhaustion, retreat decisions, wounds, infection, and native damage
suppression remain separate systems.

### Crowd chance

`N` is the number of valid, living zombies inside the configured hit zone on
the same floor. The primary attacker counts as one. The query does not depend
on rendering; it may use the existing spatial/perception result for abstract
or unrendered threats that are still represented as valid attackers.

The crowd component is:

```lua
extra = math.max(0, N - 1)
crowdChance =
    (extra * Sandbox.NPCZombieDamageCrowdChancePerExtra())
    + (
        math.max(0, extra - 2) ^ 2
        * Sandbox.NPCZombieDamageCrowdEscalation()
    )
crowdChance = math.min(crowdChance, Sandbox.NPCZombieDamageCrowdChanceCap())
```

With the proposed defaults (`5` percentage points per extra zombie and `2`
percentage points of escalation), the crowd component is:

| Zombies in hit zone | Crowd chance |
| ---: | ---: |
| 1 | 0% |
| 2 | 5% |
| 3 | 10% |
| 4 | 17% |
| 5 | 26% |
| 6 | 37% |

The first three values match the requested mapping exactly. Setting escalation
to `0` produces a purely linear sequence (`0, 5, 10, 15, ...`), while a
positive escalation makes being genuinely surrounded increasingly dangerous.

The hit-zone count should remain a bounded same-floor spatial query. It should
not perform a fresh global zombie scan for every attack or every zombie update.

### Skill mitigation and final damage chance

Fitness is the first verified skill available to this resolver. Normalize it
from the current `0..10` range:

```lua
fitness = clamp(Fitness / 10, 0, 1)
skillMitigation = clamp(
    (
        Sandbox.NPCZombieDamageMinimumSkillMitigation()
        + fitness * Sandbox.NPCZombieDamageFitnessMitigationScale()
    ) / 100,
    0,
    Sandbox.NPCZombieDamageMaximumSkillMitigation() / 100
)
```

The final roll chance is:

```lua
rawChance = Sandbox.NPCZombieDamageBaseChance() + crowdChance
damageChance = clamp(rawChance / 100, 0, 1)
damageChance = damageChance * fatigueExposure
damageChance = damageChance * (1 - skillMitigation)
```

The proposed starting values are:

- base chance: `0%`; therefore one zombie contributes `0%` by default;
- minimum skill mitigation: `15%`;
- Fitness mitigation scale: `45%`, giving Fitness 10 a total `60%`
  mitigation before the configured cap;
- maximum skill mitigation: `60%`.

The old `NPCZombieWoundChance` option must not silently remain as an additional
roll, because that would break the requested one-zombie result. It can remain
readable for save compatibility, but the new resolver should use the new
options when the new model is enabled. `NPCZombieBiteChance` and
`NPCZombieLacerationChance` remain wound-severity weights for the separate
wound-type roll; they are not part of the damage-exposure roll.

### Independent wound-type roll (preserved bite mechanics)

Passing the stamina/crowd/skill damage-exposure roll does not automatically
create a bite. The wound type remains a separate RNG layer, preserving the
existing bite gate:

```lua
woundTypeRoll = randomPercent()
biteChance = Sandbox.NPCZombieBiteChance()
lacerationChance = Sandbox.NPCZombieLacerationChance()

if woundTypeRoll < biteChance then
    initialWoundType = "bite"
elseif woundTypeRoll < math.min(100, biteChance + lacerationChance) then
    initialWoundType = "laceration"
else
    initialWoundType = "scratch"
end
```

With the existing defaults, a damage-exposure event has a `20%` chance to be
an initial bite, a `30%` chance to be an initial laceration, and a `50%`
remaining chance to be an initial scratch. The bite chance is therefore not
merged into the crowd chance, skill mitigation, or clothing block chance. An
attack that passes the first roll but fails this type roll is not a bite and
must not start bite-specific infection handling.

The initial wound type selects the clothing defense to test. Clothing may then
block the wound or downgrade its final type, but it must not reroll the bite
chance. Infection and any bite-specific consequence must inspect the final
applied wound type: a blocked bite, or a bite downgraded to laceration or
scratch, is not a final bite wound.

### Clothing interception

Clothing is a second defensive layer after the damage roll. It does not make an
NPC dodge; it either absorbs the attack, loses durability while doing so, or
fails and allows a dampened wound through.

The body part and initial severity are selected by the independent wound-type
roll above. For every worn item covering that part, use the defense matching
the initial attack:

- bites use `getBiteDefense()`;
- scratches and lacerations use `getScratchDefense()`;
- unrelated item defenses do not participate.

For each layer:

```lua
conditionRatio = itemCondition / itemConditionMax
effectiveDefense =
    clamp(itemDefense / 100, 0, 1)
    * conditionRatio ^ Sandbox.NPCZombieClothingConditionExponent()
```

Combine layers without allowing protection to exceed 100%:

```lua
blockChance = 1
for each effectiveDefense do
    blockChance = blockChance * (1 - effectiveDefense)
end
blockChance = 1 - blockChance
blockChance = clamp(
    blockChance * Sandbox.NPCZombieClothingBlockMultiplier(),
    0,
    1
)
```

Roll the clothing result once:

- if the roll is protected, consume durability from one sacrificial layer and
  apply no wound;
- if the roll penetrates, consume more durability and apply a wound;
- if the protection is strong enough but the roll still penetrates, downgrade
  the wound rather than pretending the clothing had no effect.

Use the layer with the greatest effective contribution as the sacrificial item.
This avoids iterating or mutating every worn item and makes heavy outer clothing
protect the body part that was actually struck.

Recommended failed-roll downgrade thresholds:

| Combined protection | Penetrating result |
| ---: | --- |
| below laceration threshold | original severity |
| laceration threshold or higher | bite becomes laceration; laceration becomes scratch |
| scratch threshold or higher | bite or laceration becomes scratch |

A scratch cannot be downgraded into no wound by this table; only a successful
clothing block prevents the wound. Durability wear must be applied on both
blocked and penetrated results, with the penetrated result using the larger
wear amount.

### Proposed sandbox surface

The following options should be added to `media/sandbox-options.txt` and read
through `PNC_Sandbox`. Percent values are displayed as `0..100`; ratios are
displayed as `0..1` or exposed as percentages in the UI.

| Option | Proposed default | Purpose |
| --- | ---: | --- |
| `NPCZombieDamageModel` | enabled | Selects the stamina/crowd/clothing resolver |
| `NPCZombieDamageStaminaStartRatio` | `0.30` | Below this ratio, damage exposure begins |
| `NPCZombieDamageBaseChance` | `0` | Low-stamina chance before crowd pressure |
| `NPCZombieDamageHitRadius` | `2.2` | Same-floor zombie hit-zone radius |
| `NPCZombieDamageCrowdChancePerExtra` | `5` | Added chance for each zombie after the first |
| `NPCZombieDamageCrowdEscalation` | `2` | Quadratic escalation after three zombies |
| `NPCZombieDamageCrowdChanceCap` | `100` | Maximum crowd contribution |
| `NPCZombieDamageMinimumSkillMitigation` | `15` | Mitigation at Fitness 0 |
| `NPCZombieDamageFitnessMitigationScale` | `45` | Additional Fitness-based mitigation |
| `NPCZombieDamageMaximumSkillMitigation` | `60` | Skill mitigation cap |
| `NPCZombieBiteChance` | `20` | Independent bite roll after exposure succeeds |
| `NPCZombieLacerationChance` | `30` | Independent laceration roll after the bite check |
| `NPCZombieClothingConditionExponent` | `1.15` | How worn condition reduces defense |
| `NPCZombieClothingBlockMultiplier` | `1.0` | Global clothing protection tuning |
| `NPCZombieClothingDowngradeLaceration` | `25` | Protection needed to downgrade one severity step |
| `NPCZombieClothingDowngradeScratch` | `60` | Protection needed to force a penetrating scratch |
| `NPCZombieClothingSafeDurabilityLoss` | `1` | Wear when clothing blocks the attack |
| `NPCZombieClothingPenetratingDurabilityLoss` | `2` | Wear when clothing fails and a wound enters |

The exact item-condition mutation must be verified against the current Java
item API through the Java harness before implementation. The documentation
defines the gameplay contract, not an assumed Lua setter or Java overload.

### Performance and authority constraints

- Reuse the existing bounded per-NPC perception/spatial frame to obtain `N`;
  do not scan the global zombie list per attack.
- Compute one hit-zone count per cached frame and reuse it for all bite events
  in that frame.
- Cache a clothing protection profile by worn-item identity, body-part
  coverage, damage type, and condition signature. Rebuild it only after an
  equipment or durability change.
- Mutate durability only for the selected sacrificial item.
- Roll once per committed bite lease, guarded by the bite identifier; never
  roll from both the animation callback and the server damage callback.
- Apply the result only through the authority-gated PNC health path. Native
  Java attack collision must be suppressed or converted into a presentation
  event, never allowed to create a second wound.
- Emit compact diagnostics containing stamina ratio, hit-zone count, crowd
  chance, skill mitigation, damage roll, block roll, selected item, durability
  loss, and final wound severity. These values are needed to tune sandbox
  defaults without flooding the 75 ms combat loop.

Abstract combat should use the same expected-value contract rather than making
one random clothing and durability roll for every virtual zombie. Live combat
uses the individual attack roll described above; abstract combat may aggregate
the expected result over its bounded round.
