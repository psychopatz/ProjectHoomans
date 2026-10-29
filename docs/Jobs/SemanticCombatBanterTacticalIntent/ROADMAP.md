# Roadmap — Semantic Combat Banter & Tactical Intent

**Parent objective:** make combat dialogue an active, grounded, non-blocking co-op gameplay system: correct horde episodes, real follower tactical decisions, autonomous personality-aware combat banter, weapon/action-aware kill commentary, and appropriate interactive response surfaces, while preserving existing combat/perception/semantic authorities and performance.

**Developer status:** B0–B9 ACCEPTED / maintenance-ready. Native SP/MP visual/feel validation remains user-owned.

All phases below are mandatory unless explicitly marked future/optional.

## B0 — Reproduce and contract the current regressions

**B0A — immediate Next Chunk**
- add real-worker/static regression coverage proving `zombie_horde_encounter` currently falls to generic `semantic.combat.reaction.default`;
- characterize repeat-horde episode timing from the production awareness callers;
- enumerate combat response families as `BARK / TACTICAL_PROMPT / TERMINAL / UNCLASSIFIED`;
- characterize open-conversation vs closed-conversation offer projection;
- record current kill context fields lost between CombatResolution and SemanticCombatReactionService.

**Gate:** evidence is production-grounded; no semantic behavior changed yet; exact missing ownership seams are documented/tested.

## B1 — Canonical horde episode and semantic routing

- make the current horde event resolve a dedicated horde semantic family;
- repair EN/TL horde content and remove the stale generic fallback from this path;
- introduce edge-triggered runtime episode state using existing ZombieObservation/Perception facts;
- stable horde does not repeatedly reannounce;
- material escalation and clear transitions are explicit;
- remove/merge duplicate semantic emitters where necessary without changing combat sensor ownership.

**Gate:** one encounter-start event for a stable horde, bounded escalation behavior, clear closes episode, no new world scan, correct EN/TL family selected.

## B2 — Tactical follower prompt + encounter intent

- add runtime-only `undecided/engage/avoid/hold` encounter intent;
- do not mutate permanent `attackType`;
- choose at most one follower spokesperson per prompt window;
- produce personality-aware "fight or avoid?" tactical prompt;
- offer grounded semantic choices such as engage/avoid/hold;
- self-defense remains authoritative;
- player beginning combat implicitly resolves engage;
- obvious withdrawal can resolve avoid without waiting for a click.

**Gate:** semantic choice and equivalent player behavior converge on the same encounter intent; no stale prompt, no duplicate spokespersons, no combat pause.

## B3 — Non-modal combat response surface

- render active tactical prompt offers outside the full conversation UI;
- reuse existing semantic offer/click frames and eligibility;
- no second action/semantic authority in UI;
- when conversation UI is open, same prompt projects to normal Response Channel;
- expiry/resolution removes both surfaces.

**Gate:** headless presentation contract proves one semantic prompt can render through both surfaces without duplicate execution; native visual gate remains user-owned.

## B4 — Unified Combat Moment Context + arbiter

- project authoritative combat facts into one bounded moment contract;
- add/extend one banter arbiter with urgency, novelty, semantic-family cooldown, speaker cooldown, team budget and silence;
- urgent tactical/warning speech outranks jokes/boasts;
- routine kills do not produce one bark each;
- integrate existing kill coalescing rather than creating a parallel throttle.

**Gate:** burst/stress tests prove bounded fanout and silence; no all-NPC scan, no per-kill persistence/LLM.

## B5 — Weapon/action-aware zombie kill banter

- pass actual kill weapon/action facts from CombatResolution;
- normalize weapon family through existing Equipment/Skills;
- use body-part/wound/skill/pressure/personality predicates;
- add authored EN/TL variants for firearm/blade/axe/spear/blunt/unarmed groups where useful;
- allow occasional sanitized weapon-name lexical slots;
- differentiate confident skillful shot vs lucky/nervous shot;
- keep generic safe fallback.

**Gate:** real worker/resolver cases prove incompatible lines cannot select (no blade gore for firearm, no sharpshooter boast for low-skill nervous shooter unless authored as irony with explicit predicate); weapon ID never leaks.

## B6 — Hostile-human kill commentary

- emit an authoritative semantic combat moment when an NPC kills a hostile human NPC;
- reuse weapon/action context;
- separate moral/emotional content from zombie commentary;
- personality/relationship/faction context may affect tone only when grounded;
- routine chatter remains transient; existing faction/social death authorities remain unchanged.

**Gate:** zombie and hostile-human kill families stay distinct, no duplicate death side effect, no invented morality/faction fact.

## B7 — Combat-language quality and branching standardization

- classify all combat event response families explicitly as `BARK`, `TACTICAL_PROMPT`, or intentional terminal;
- require tactical prompts to have grounded offers;
- require bark families to be valid with zero offers;
- add varied personality/intensity/profanity realization without mechanical one-trait stereotypes;
- add anti-repeat and nearby semantic-family diversity;
- ensure typed equivalent replies converge with generated tactical choices.

**Gate:** catalog audit has zero unclassified non-legacy combat families; EN/TL coverage complete; button/typed parity passes.

## B8 — Semantic Lab / Observatory observability

Expose bounded inspection for:
- horde episode state and transitions;
- current encounter intent;
- combat moment context;
- arbiter candidates/rejections;
- selected presentation class;
- response-plan offers;
- weapon-family/skill predicates;
- cooldown/budget reason for silence.

Do not add monolithic trace dumps.

**Gate:** an agent can explain "why did this NPC speak / stay silent / ask / choose this line?" through bounded real production state.

## B9 — Broad regression, performance and developer acceptance

Run:
- focused Lua tests;
- full affected semantic/combat suites;
- real Semantic Harness worker matrices;
- transient lifecycle/persistence guards;
- deterministic CodeBuilder double-generation;
- Kahlua verification;
- static guards for new scans/ModData/LLM hot paths;
- performance/fanout stress cases;
- source-save immutability checks.

**Gate:** developer-side acceptance is green with exact evidence. Native SP/MP visual/feel validation remains user-owned unless reassigned.

## Explicit future/optional extensions

Do not implement as mandatory B0–B9 work unless needed for architecture correctness:
- reload/out-of-ammo banter;
- weapon-break comments;
- friendly-fire banter;
- special infected concepts not present in Project Zomboid;
- large-scale squad command wheel redesign;
- LLM-authored routine combat chatter.
