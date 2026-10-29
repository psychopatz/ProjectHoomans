# B0 Baseline — Combat Banter/Tactical Intent

**Revision characterized:** ProjectHoomans `206af2b4`.
**Scope:** production-grounded regression/ownership characterization only.

## Reproduced semantic routing bug

Real semantic response selection for runtime event `zombie_horde_encounter` resolves:

```text
pool: semantic.combat.reaction
realization: semantic.combat.reaction.default
text: Good work. Keep watching the area.
offers: generic combat only
```

The older `zombie_horde_detected` event selects `semantic.combat.reaction.threat` and its three horde follow-ups. This proves the native screenshot regression is an event-name/catalog mismatch, not a failure of the separate kill-reaction pool.

## Horde episode characterization

Current `ObserveZombieHorde`:
- starts above threshold;
- suppresses repeats only while the last-above-threshold timestamp is < 3000 ms old;
- returns early below threshold without clearing the episode state;
- may emit a new event for the same still-present horde after the timing gap.

Semantic horde observation currently enters from:
1. `PNC_ZombieObservation` only while `tacticalHorde=true`;
2. follower hazard logic, which returns before calling below threshold;
3. combat threat assessment, which returns before calling below threshold.

Therefore no current owner reliably drives the semantic clear transition.

## Response-classification baseline

| Current family | Effective role | Offers | B0 classification |
| --- | --- | ---: | --- |
| `semantic.combat.kill.witness.*` | routine player-kill reaction | 4 grounded event offers | BARK with optional continuation |
| `semantic.combat.kill.killer.*` | NPC self-kill reaction | 4 grounded event offers | BARK with optional continuation |
| `semantic.combat.reaction.retreat` | stamina/status callout | 1 | BARK |
| `semantic.combat.reaction.threat` | old horde/threat line | 3 | UNCLASSIFIED (intended horde interaction) |
| `semantic.combat.reaction.default` | generic fallback | 1 | UNCLASSIFIED |
| companion command rejection/default | acknowledgement/rejection | 0 | TERMINAL/BARK depending producer |
| conversation safety danger | urgent warning | grounded follow-up | BARK |
| corpse reaction | event reaction | mixed | UNCLASSIFIED for this job |

The catalog currently has no explicit `presentationClass` contract, so intended terminal/bark/prompt behavior cannot be mechanically audited.

## Interaction-surface baseline

Delivered semantic event offers are projected into lifecycle suggestions only when an active conversation view exists. `projectEventIntoConversation` returns when no `view.spec.context` exists.

No general closed-conversation combat tactical-choice renderer exists.

## Kill-context loss

Authoritative combat hit/resolution already has:
- `weaponItem`;
- `weaponFullType`;
- `partId`;
- `woundType`;
- melee/ranged attack type;
- kill outcome.

The current `SemanticCombatReactionService.OnNPCKill` call receives location/source only. Weapon/item/body-part/wound/skill context is discarded before semantic kill commentary.

## B0 acceptance evidence

```text
python3 tests/run_tests.py   pnc_semantic_combat_banter_b0_routing_smoke   pnc_semantic_horde_episode_characterization_smoke   pnc_semantic_combat_banter_b0_boundaries_smoke --jobs 1
```

Result: **PASS 3/3**.

B0 closes characterization only. Desired behavior begins in B1.
