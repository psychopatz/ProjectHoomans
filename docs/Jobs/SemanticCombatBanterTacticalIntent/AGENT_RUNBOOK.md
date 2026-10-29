# Agent Runbook — Semantic Combat Banter & Tactical Intent

Use this runbook for the active combat-banter/tactical-intent job only.

## Read order

Read root `AGENTS.md`, then this job's `AUDIT.md`, `ARCHITECTURE.md`, `ROADMAP.md`, `HARNESS_ACCEPTANCE.md`, and `PROGRESS.md` last.

Also read the accepted foundation only when needed:
- `docs/Jobs/OpenEndedSemanticCombatAwareness/PROGRESS.md`;
- `docs/Jobs/PragmaticDialogueBeatDirector/ARCHITECTURE.md`;
- `docs/Jobs/SemanticInteractionLifecycle/ARCHITECTURE.md`.

Do not reload completed-job history wholesale.

## Parent objective

Make Project Hoomans combat dialogue feel like active co-op game banter rather than a chatbot: NPCs should notice combat situations, speak autonomously when something is worth saying, ask the player/team only when a real tactical decision exists, react to the resulting team choice without blocking combat, and ground kill/weapon commentary in what actually happened.

The full roadmap is the completion boundary. A phase/chunk is only an implementation unit.

## Existing authorities to preserve

Do not create a second:
- zombie/world scanner;
- combat resolver;
- companion attack-order authority;
- relationship/conduct memory path;
- conversation/NLU engine;
- semantic suggestion renderer;
- speech realization/translation system;
- durable combat transcript or kill ledger.

Reuse:
- `PNC_ZombieObservation` / Perception / SpatialIndex for threat pressure;
- companion behavior and `attackType` for durable attack policy;
- CombatResolution/AttackExecution for actual hit/kill facts;
- Equipment / Firearms / Skills for weapon facts;
- SemanticInteractionLifecycle for bounded transient context;
- SemanticSocialReaction / SpeechRealization / CodeBuilder for dialogue selection and EN/TL realization;
- existing conversation suggestion/click frame authority for semantic choices.

## Tactical-intent rule

Permanent `record.attackType` is not a horde decision.

Introduce only a bounded live encounter intent for the current combat episode, for example:
`undecided / engage / avoid / hold`.

It must:
- be runtime-only;
- expire when the encounter clears;
- never weaken immediate self-defense;
- never overwrite the player's durable attack-type preference unless an existing command explicitly does so;
- allow owner action to resolve intent implicitly (player attacks -> engage, player withdraws -> avoid) without waiting for UI.

## Presentation classes

Treat event dialogue as one of two explicit classes:

### BARK
Autonomous non-blocking combat chatter.
- no player response required;
- combat continues;
- normally no response buttons;
- transient, non-LLM, non-memory;
- cooldown/coalescing/priority controlled.

Examples: kill boast, nervous swear, weapon joke, reload complaint, "behind you", "nice shot".

### TACTICAL_PROMPT
A real short-lived team decision.
- carries typed semantic offer frames;
- can render in the full conversation UI when open;
- must also have a non-modal combat response surface when conversation UI is closed;
- timeout/implicit player action may resolve it;
- the selected semantic choice must call existing gameplay authority, not a dialogue-only fake action.

A response family must declare whether it is `BARK`, `TACTICAL_PROMPT`, or intentionally terminal. Missing classification is an acceptance failure for new combat content.

## Combat-moment grounding

Build dialogue from authoritative moment facts, not post-hoc guesses.

Preferred kill context includes where available:
- event kind and target kind;
- actor/target IDs;
- killed vs hit/miss;
- attack type and attack kind;
- actual weapon item/full type;
- normalized weapon family/skill;
- skill level;
- wound/body-part result;
- horde/pressure band;
- actor health/panic/stress;
- relationship/personality/traits;
- owner/team encounter intent;
- burst/streak/coalescing state.

Do not persist these routine facts merely for chatter.

Exact weapon display names are optional flavor and should appear sparingly. Never expose internal IDs such as `Base.Machete` to the player.

## Personality and profanity

Profanity is a style/intensity consequence, not a bravery boolean.

Use existing traits/personality/mood plus current pressure. For example:
- aggressive/brave may celebrate;
- nervous/cowardly may swear from hesitation;
- veteran/practical may stay terse;
- supportive may reassure;
- reserved may say little;
- hostile/cold may react differently to the player.

Do not make every brave NPC say "fuck yeah" or every nervous NPC say "fuck".

## Banter arbiter

Routine combat must support silence.

Add or extend one bounded arbiter that decides:
- whether the moment is worth speaking about;
- which nearby NPC may speak;
- urgency/priority;
- semantic-family cooldown;
- same-speaker cooldown;
- team/global chatter budget;
- repetition suppression;
- whether an urgent warning preempts a joke/boast.

Do not emit one line per kill/hit.

## Horde episode ownership

Fix the current repeated `zombie_horde_encounter` behavior at the episode boundary.

The system must distinguish at least:
- clear -> encounter started;
- material pressure escalation/de-escalation;
- encounter active/stable;
- encounter cleared.

Do not treat "still above threshold after cooldown" as a new horde.

Keep one observation authority; do not add another `getZombieList()` scan.

## Weapon commentary

Reuse existing Equipment/Skills/CombatResolution facts.

Examples are style targets, not hardcoded mandatory sentences:
- blade/head kill: gruesome or darkly humorous observation;
- blunt kill: impact/crushing commentary;
- firearm kill: aim/shot placement/weapon-confidence commentary;
- low-skill lucky shot: relief/surprise rather than false sharpshooter bragging;
- weapon-specific mention only when a safe display name is available and variation selects it.

NPC-vs-hostile-human kill commentary must be semantically distinct from zombie-kill commentary.

## Content/compiler rules

New dialogue content is canonical CodeBuilder source, then generated through the existing compiler. Never hand-edit generated Conversation Lua.

Keep content semantically sharded by event/role/style/weapon family. Do not create one giant combat sentence list.

All player-facing new content requires EN and TL authored/localized coverage through the existing locale ownership.

Run deterministic second generation after content changes.

## Validation discipline

For each chunk:
- focused Lua tests;
- real Semantic Harness worker tests for semantic selection/branching;
- no-LLM/no-memory assertions for routine bark paths;
- gameplay authority assertions for tactical prompts;
- performance/fanout/cooldown assertions;
- CodeBuilder deterministic generation when content changes;
- Kahlua/static checks;
- `git diff --check`;
- source save immutability.

Native Project Zomboid SP/MP remains user-owned unless explicitly reassigned.

## Git/publication

Use existing `main` only. Preserve unrelated work. Do not stash/reset/rebase/discard uncertain changes. Do not publish or republish Steam Workshop content without explicit user authorization.

## Stop conditions

Continue automatically through documented mandatory phases after each accepted chunk.

Stop only when:
- the parent objective reaches developer-side acceptance;
- a genuine repository/runtime/auth blocker exists;
- scope/authority conflicts with the user-approved objective;
- or all implementable work is complete and only the explicitly user-owned native live gate remains.
