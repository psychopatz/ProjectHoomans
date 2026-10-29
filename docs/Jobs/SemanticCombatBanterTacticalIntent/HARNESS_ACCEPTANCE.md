# Harness Acceptance — Semantic Combat Banter & Tactical Intent

The existing Semantic Harness/production Lua worker is the primary semantic-behavior test surface. Isolated Lua tests are required for combat/runtime contracts that the worker does not execute. Native Project Zomboid remains the final visual/feel gate.

## Acceptance principle

A line existing in a JSON catalog is not acceptance.

Every new behavior must prove:
1. authoritative combat/world facts were observed;
2. correct semantic moment/event was built;
3. arbiter selected speak/silence/prompt for an explainable reason;
4. realization matched grounded predicates;
5. any offers were generated from real semantic response plans;
6. any selected tactical offer reached existing gameplay authority exactly once;
7. routine chatter did not create durable memory/ModData/LLM work.

## B0 baseline cases

Capture the current regressions before fixing:
- `zombie_horde_encounter` -> generic `semantic.combat.reaction.default`;
- repeated stable-horde presentation;
- current TL generic combat fallback equals English;
- kill event uses kill-specific family separately;
- kill reaction can expose grounded offers;
- non-offer combat families are enumerated;
- closed conversation has no equivalent transient tactical-choice renderer.

These are regression anchors, not desired final behavior.

## Horde episode matrix

At minimum:

| Scenario | Expected |
| --- | --- |
| clear -> few | no horde prompt |
| clear -> dangerous horde | one encounter-start semantic moment |
| same stable horde over presentation cooldown | no new encounter-start |
| horde grows materially | optional escalation moment, bounded |
| horde shrinks but remains dangerous | no fake new encounter |
| horde -> clear | episode closes |
| clear -> new later horde | new episode ID/prompt allowed |
| two followers | at most one spokesperson for unresolved team prompt |

Assert no additional global zombie scan.

## Tactical intent matrix

For a follower-owned dangerous horde:

- initial intent = `undecided`;
- prompt offers semantic engage/avoid/hold when eligible;
- click engage -> encounter intent `engage`;
- typed equivalent -> same semantic/action result;
- owner attacks before click -> `engage`, stale prompt removed;
- owner withdraws -> `avoid` when policy says retreat is established;
- hold -> no proactive engagement, but immediate self-defense still works;
- permanent `record.attackType` unchanged;
- encounter clear -> intent removed.

No option may directly mutate health/damage/pathing.

## Presentation parity

For one active tactical prompt prove:
- full conversation UI projection uses existing Response Channel rows;
- closed-conversation combat strip receives the same offer IDs/semantic click frames;
- both submit through the same semantic dispatcher;
- resolving one invalidates/removes the other;
- duplicate clicks/replays cannot execute twice;
- timeout/implicit resolution clears both.

Headless/UI-model evidence does not claim native visual quality.

## Banter arbiter matrix

Stress with multiple nearby NPCs and repeated kills:
- urgent warning can preempt ordinary boast;
- only bounded speakers present;
- same family does not repeat every kill;
- low-value moment may intentionally produce silence;
- burst coalescing occurs before expensive presentation/spatial work where possible;
- semantic-family/speaker/team budgets are visible in trace;
- no new ModData or transcript.

## Weapon commentary matrix

Use actual CombatResolution facts.

Required positive/negative cases include:

### Firearm
- high Aiming + confident/brave + firearm kill -> eligible skilled-shot family;
- low Aiming + nervous/shaken + firearm kill -> relief/surprise family;
- firearm kill must not select blade/axe gore family;
- optional weapon-name variant renders human-readable display name only.

### Blade
- ShortBlade/LongBlade head/neck kill -> blade-specific family may be eligible;
- torso blade kill does not claim teeth/head result;
- aggressive/dark-humor style may use gore joke;
- reserved/supportive style can remain terse/non-gory.

### Axe / spear / blunt
At least one grounded family each or an explicit documented generic-melee fallback. Predicates must prevent cross-family leakage.

### Unknown/modded weapon
Graceful generic melee/ranged fallback; no internal full-type string shown.

## Hostile-human kill matrix

- authoritative NPC kills hostile human;
- semantic targetKind = human/NPC;
- zombie-only wording is ineligible;
- aggressive, shaken/compassionate, practical variants differ;
- existing death/faction/social side effects occur exactly once through their owners;
- semantic bark adds no duplicate relationship/faction mutation.

## Language/content acceptance

For new combat content:
- EN and TL authored/localized;
- no accidental English text copied into TL unless intentionally identical proper noun/token;
- profanity variants are style/intensity selected;
- non-profane variants remain available;
- exact weapon names are optional, bounded, sanitized;
- anti-repeat works across repeated eligible moments.

## Persistence/safety

Routine BARK:
- `memoryEligible=false`;
- `llmEligible=false`;
- transient only;
- ignored bark leaves no lifecycle ModData pair/event.

TACTICAL_PROMPT:
- live prompt/episode state runtime-only;
- only actual conversation/meaningful existing pathways may promote durable state;
- tactical choice does not create relationship/conduct evidence merely by existing.

No new ModData root.

## Performance acceptance

Instrument/guard:
- no new `getCell():getZombieList()` traversal;
- no per-frame semantic generation;
- no all-roster witness scan;
- bounded spatial query;
- bounded moment candidate count;
- bounded speaker count;
- cooldown/coalescing before presentation;
- no routine LLM;
- no unbounded queue/list/map.

Record before/after stress metrics where the harness/runtime exposes them. Do not invent FPS claims from unit tests.

## CodeBuilder acceptance

When content changes:
1. edit canonical semantic source only;
2. generate;
3. validate context-health/reference checks;
4. hash generated Conversation output;
5. generate again;
6. prove byte-identical output;
7. verify no opaque/numeric overflow shard was introduced.

## Final developer gate

Before B9 closure:
- all focused roadmap matrices green;
- affected full Lua suites green;
- affected Semantic Harness Python/real-worker suites green;
- generated source deterministic;
- Kahlua errors = 0 for changed/generated Lua;
- `git diff --check` clean;
- static scan proves no new global zombie scan / ModData root / routine LLM;
- source save hash unchanged when save-backed cases are used;
- native SP/MP status stated accurately.

Native feel checks should specifically verify chatter frequency, timing, non-modal choice usability, simultaneous speaker noise, personality distinction, and whether silence feels natural.
