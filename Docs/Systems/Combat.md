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
- attack start is an immediate state-transition snapshot. Remote clients snap
  the visual body to the authoritative attack origin before playing the attack,
  while the hit frame uses a small range tolerance rather than movement-sized
  reach padding
- attack actions explicitly release the engine bump channel when the animation
  finishes, the target is lost, or the bounded action timeout expires; release
  remains pending until the ActionContext acknowledges that it left `bumped`
- weapon hits use a short passive settlement lease: vanilla hit/stagger owns
  animation, while PNC aggro temporarily refrains from clearing the attacker or
  issuing path/bite commands that would freeze the reaction state
- multiplayer weapon hits publish the resulting nonlethal health and cosmetic
  hit reaction to clients; only the server applies damage, wear, death, and
  target provocation
- zombie-on-NPC pursuit uses throttled coordinate repaths because the NPC's
  embodied engine type is also `IsoZombie`; bite bump state is explicitly
  entered and cleared so a completed bite cannot strand the attacker
- committed point-blank melee swings tolerate transient LOS changes during the
  windup, revalidate range at the hit frame, and verify that the engine hit
  actually changed zombie health before using authoritative fallback damage
- delayed attacks retain a runtime-only direct zombie reference plus the stable
  spatial ID, and cancel immediately with `target_lost_or_dead` if neither
  resolves before the hit frame
- companions and hostiles can acquire zombie targets; neutrals reserve combat
  for hostile NPCs until their disposition changes
- companion, roaming, and hostile behaviors share periodic target
  reassessment. A nearby enemy actively attacking the NPC takes priority over
  a passive target; otherwise a substantially closer candidate may replace the
  current target, with a short reassessment interval and distance hysteresis
  preventing target flicker
- recent validated damage identifies NPC and player attackers as immediate
  threats for a bounded memory window
- initial player, NPC, and zombie acquisition requires an unobstructed visual
  trace; closed doors and walls do not count as visible
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
