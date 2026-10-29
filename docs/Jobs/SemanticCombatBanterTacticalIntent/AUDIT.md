# Audit — Semantic Combat Banter & Tactical Intent

**Audit base:** ProjectHoomans `8632bc30` on existing `main`.
**Native evidence:** user live test plus current console/runtime observations.
**Status:** new job justified; no implementation accepted yet.

## Product gap

The accepted combat-awareness foundation can detect zombie pressure, publish kills, produce bounded kill reactions, and hold short-lived event follow-up context. The live game still does not behave like active co-op banter.

Current combat speech has four separate problems:
1. wrong semantic family can be selected for real combat events;
2. stable threats can repeatedly re-announce themselves;
3. NPC chatter is not grounded deeply enough in the actual combat action/weapon;
4. interactive prompts are tied too closely to conversation UI instead of moment-to-moment gameplay.

## Live regression: wrong horde line

The live line:

`Good work. Keep watching the area.`

is canonical `semantic.combat.reaction.default`, not a horde-specific or kill-specific response.

Runtime emits `social:zombie_horde_encounter`. The response catalog's dedicated combat-awareness branch recognizes `combat_awareness` / `zombie_horde_detected`, so `zombie_horde_encounter` falls through to the generic combat default.

The same source currently has the TL entry equal to the English sentence, so this fallback also exposes stale localization quality.

The same live session showed the actual kill path separately producing a correct kill-family line such as:

`Good kill. Don't let up.`

Therefore kill reaction and horde reaction are distinct; the screenshot regression is a horde semantic-routing bug, not proof that the new kill pool failed.

## Horde episode repetition

`PNC_SocialEventHooks_CombatAdapter_Awareness.ObserveZombieHorde` maintains episode timing state, but production callers invoke observation from multiple combat/follow paths while already above threshold.

The current architecture does not reliably deliver the below-threshold observation needed to close the semantic episode. A still-active horde can therefore be presented again after timing/presentation cooldowns.

Correct behavior is edge/episode based:
- horde appears;
- pressure materially changes;
- horde remains stable -> silence;
- horde clears.

## Branching inconsistency

The semantic infrastructure can carry `offerIDs`, event facts, transient lifecycle beats, typed/clicked semantic frames, and generated Response Channel rows.

Kill reactions already expose grounded follow-ups.

However not every ambient/event family declares offers. Some are correctly terminal, but the architecture does not currently require a family to explicitly declare:
- interactive tactical prompt;
- autonomous bark;
- intentional terminal response.

This makes "forgot to define branches" indistinguishable from "no reply should exist".

## Closed-conversation interaction gap

Ambient speech can present outside the full conversation UI, but the normal semantic response buttons are primarily projected into the open conversation Response Channel.

A follower asking a time-sensitive question such as "We taking these?" should not force the player to stop combat and open the portrait conversation UI.

The missing product surface is a non-modal transient combat-choice renderer that consumes the same semantic offer frames/click authority as the conversation UI. It must not become a second semantic/button system.

## Follower decision ownership

Follower combat already distinguishes:
- permanent `record.attackType` policy;
- owner engaged state;
- immediate self-defense;
- horde/retreat behavior;
- companion target resolution.

There is no short-lived current-encounter team intent.

Using `attackType` for "fight this horde or avoid it" would incorrectly turn a situational team decision into a persistent companion combat preference.

## Weapon/action grounding already exists

CombatResolution/AttackExecution already possesses stronger facts than the current semantic kill service receives:
- actual `hit.weaponItem`;
- `weaponFullType`;
- melee/ranged attack type;
- attack kind;
- wound/body part;
- authoritative killed state;
- weapon skill classification;
- aiming/melee skill levels;
- Equipment firearm/melee descriptor.

`Skills.ResolveWeaponSkill` already maps weapons to `Aiming`, `Axe`, `LongBlade`, `ShortBlade`, `Spear`, `ShortBlunt`, `LongBlunt`, etc.

But `CombatResolution.ApplyZombieDamage` currently calls `SemanticCombatReactionService.OnNPCKill` with only location/source data. The semantic kill path therefore discards useful authoritative weapon/action facts.

## Hostile-human kill gap

NPC-vs-NPC combat resolution knows when the target becomes dead, but the current semantic combat-reaction service is specifically wired for zombie self-kills/player zombie kills.

A hostile-human kill therefore has no equivalent personality/weapon-aware semantic commentary path.

Human-kill commentary must not simply reuse zombie-gore jokes; emotional/moral tone is different.

## Chatter arbitration gap

The current kill service has useful cooldown/coalescing, but there is no general combat-moment arbiter spanning:
- horde warnings;
- tactical questions;
- kill boasts;
- weapon comments;
- panic/hesitation;
- urgent warnings;
- low-value routine events.

Without a shared priority/budget layer, richer content risks becoming noisy and less immersive.

Silence must be a valid and common decision.

## Architectural conclusion

Do not fix this by:
- adding more generic combat fallback sentences;
- attaching `Say()` calls directly to combat files;
- changing permanent `attackType` for a temporary horde choice;
- adding another zombie scanner;
- persisting a combat transcript/kill ledger;
- making every bark interactive;
- forcing every semantic event into the portrait conversation UI;
- hardcoding weapon names into dialogue logic;
- using LLM calls per kill.

Proceed through the new roadmap using the existing combat, perception, semantic, lifecycle, content compiler, and gameplay authorities.
