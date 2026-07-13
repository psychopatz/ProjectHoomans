# Combat

## Shared Services
- `PNC_Combat` is the entry layer only
- the bootstrap explicitly loads pathing, reaction, tactics, zombie aggro, and
  attack-action modules in dependency order; combat correctness must not rely
  on incidental automatic Lua file ordering
- `PNC_Combat_Melee`, `PNC_Combat_Ranged`, `PNC_Combat_AttackActions`, `PNC_Combat_Tactics`, and `PNC_Combat_Unarmed` own focused combat responsibilities
- custom damage routes through `PNC_Health`
- players, NPCs, and zombies use the same target format

## Current Rules
- melee and ranged attacks are server-authoritative delayed-hit actions, not immediate damage writes
- attack actions explicitly release the engine bump channel when the animation
  finishes, the target is lost, or the bounded action timeout expires; release
  remains pending until the ActionContext acknowledges that it left `bumped`
- weapon hits use a short passive settlement lease: vanilla hit/stagger owns
  animation, while PNC aggro temporarily refrains from clearing the attacker or
  issuing path/bite commands that would freeze the reaction state
- committed point-blank melee swings tolerate transient LOS changes during the
  windup, revalidate range at the hit frame, and verify that the engine hit
  actually changed zombie health before using authoritative fallback damage
- delayed attacks retain a runtime-only direct zombie reference plus the stable
  spatial ID, and cancel immediately with `target_lost_or_dead` if neither
  resolves before the hit frame
- companions and hostiles can both acquire zombie targets
- initial player, NPC, and zombie acquisition requires an unobstructed visual
  trace; closed doors and walls do not count as visible
- a lost target is investigated at its last seen position for a short memory
  window, but its live position is not tracked and attacks are cancelled while
  line-of-sight is blocked
- unarmed combat uses shove and ground-finisher behavior instead of weapon swings
- combat can trigger conservative kiting and repositioning through `PNC_Combat_Tactics`
- horde-aware combat now prefers lower-density zombie picks over blindly taking the nearest body
- low-stamina combat below the retreat threshold enters a recovery retreat instead of standing in place
- surrounded melee pressure can add a shove-back stagger to create breathing room after a hit
- combat debug state exposes target kind, resolved mode, weapon status, and block reason
