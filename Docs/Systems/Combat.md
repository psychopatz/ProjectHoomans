# Combat

## Shared Services
- `PNC_Combat` is the entry layer only
- `PNC_Combat_Melee`, `PNC_Combat_Ranged`, `PNC_Combat_AttackActions`, `PNC_Combat_Tactics`, and `PNC_Combat_Unarmed` own focused combat responsibilities
- custom damage routes through `PNC_Health`
- players, NPCs, and zombies use the same target format

## Current Rules
- melee and ranged attacks are server-authoritative delayed-hit actions, not immediate damage writes
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
