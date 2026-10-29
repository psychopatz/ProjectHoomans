# Harness Acceptance — Semantic NPC Group Conversation

The production Lua worker/Semantic Harness is the primary semantic behavior surface. Isolated Lua tests own runtime grouping, spatial, faction and network contracts. Native Project Zomboid remains the final feel/visual gate.

## Acceptance principle

An NPC line existing in a catalog is not acceptance.

Every autonomous exchange must prove:
1. an authoritative event/fact triggered it;
2. correct local cohort/participants were resolved;
3. the previous semantic act is known without text reparsing;
4. arbiter admitted or rejected the turn for an explainable reason;
5. gameplay intent/result came from the correct authority;
6. actor/recipient/observer identities are correct;
7. realization is grounded;
8. routine speech left no durable transcript/ModData/LLM work.

## G0 boundary matrix

Prove current state:
- companion encounter intent requires owner/follower identity;
- owner-group NPC threat propagation works and is bounded;
- faction ID/member indexes exist;
- nearby neutral/hostile NPCs may be combat-banter candidates;
- NPC self-kill speech currently targets nearby player presentation;
- NPCSpeech envelope preserves actor/target IDs;
- Combat Banter Arbiter is the current budget owner.

## Combat Cohort matrix

| Scenario | Expected cohort |
| --- | --- |
| two followers same owner | same `owner_team` |
| followers different owners | different cohorts |
| two live NPCs same faction | same `faction` |
| hostile faction members | same hostile faction cohort |
| neutral NPCs different factions | different cohorts |
| unaffiliated unrelated NPCs nearby | separate `solo` cohorts |
| remote faction member | same identity but not a local participant |
| dead/abstract/nonlocal member | rejected from local exchange |

Assert no persistent membership copy.

## Encounter intent matrix

For every supported cohort:
- start -> `undecided`;
- real decision -> engage/avoid/hold;
- stale event ref rejected;
- clear removes live state;
- self-defense not blocked.

Follower cohort additionally:
- player semantic choice and typed equivalent converge;
- implicit player combat -> engage;
- permanent `attackType` unchanged.

Autonomous faction cohort:
- decision source identifies existing AI/faction/combat policy;
- dialogue cannot directly overwrite behavior outside that policy.

## NPC-to-NPC audience matrix

Required:
- NPC A -> NPC B: B is semantic recipient;
- nearby player hears line but is observer only;
- observer receives no response offers;
- player-addressed NPC A -> player can expose eligible offers;
- target NPC leaves/dies -> pending turn terminates or retargets only by explicit policy;
- no duplicate line per nearby observing player in local presentation state.

## Exchange coherence matrix

Use semantic acts, not exact prose.

Required sequences include:
- `WARN_THREAT -> PROPOSE_AVOID -> ACCEPT -> ACK`;
- `WARN_THREAT -> PROPOSE_ENGAGE -> DISAGREE -> COMMAND/ACK` when final intent is independently resolved;
- panic response can occur under grounded pressure/personality;
- supportive/reassure response requires relevant distressed ally context;
- no `COMMAND_*` line before the gameplay/group decision exists.

Assert:
- previous rendered English/TL is never reparsed;
- max turn budget enforced;
- TTL enforced;
- fact refs bounded;
- strategy anti-repeat bounded.

## Group personality matrix

Personality changes expression/response weighting, not truth.

Examples:
- brave/aggressive: more willing to propose/challenge engage;
- nervous/shaken: more likely to object/panic;
- practical/leader: terse decision/command;
- supportive: reassure/ack;
- hostile/cold: harsher wording.

Negative assertions:
- no single-trait deterministic profanity stereotype;
- no fearless claim for panicked/unsupported context;
- no fake tactical action.

## Combat event matrix

At minimum:
- horde start/escalation;
- ally hurt/downed;
- zombie kill;
- hostile-human kill;
- retreat/engage resolution.

Reload/cover is included only if a real authoritative gameplay fact is available during implementation; otherwise document it as deferred rather than fabricate state.

## Arbiter/performance matrix

Stress multiple local NPCs/factions:
- candidate list capped before semantic ranking;
- active speaker <= 1;
- optional respondent <= 1;
- turns <= configured cap (initial target <= 4);
- urgent warning can preempt ordinary boast;
- repeated kills commonly become silence;
- cohort/family/speaker budgets visible;
- no per-tick dialogue scan;
- no all-faction-member local-speech loop;
- event-local spatial query reused where available;
- any fallback query is bounded and occurs once at admission, not per turn.

Do not claim FPS improvement from unit tests. Record query/fanout counters where available.

## Persistence/safety

Routine NPC group conversation:
- runtime-only exchange state;
- no new ModData root;
- no transcript;
- `memoryEligible=false` by default;
- `llmEligible=false`;
- no relationship/faction mutation solely because a line was spoken.

Meaningful pre-existing social/gameplay events may continue to mutate through their existing authorities exactly once.

## Language/content acceptance

New content:
- canonical CodeBuilder source;
- EN and TL coverage;
- neutral/hostile/companion differences expressed through semantic predicates/style, not separate engines;
- anti-repeat available;
- profanity bounded/style-aware;
- no internal IDs.

## Observatory acceptance

For a real worker fixture, inspection must answer:
- cohort and why;
- participants/rejections;
- current intent;
- exchange topic/turn;
- who addressed whom;
- expected reply;
- arbiter result;
- recipient vs observers;
- offers/no-offers reason.

Inspection must be bounded and read-only.

## Final G8 gate

Before developer completion:
- G0-G7 matrices green;
- full Lua suite green;
- affected real-worker suites green;
- deterministic CodeBuilder generation;
- Kahlua errors = 0 for changed/generated closure;
- `git diff --check` clean;
- static guard proves no new global scan / persistent transcript / routine LLM;
- source save unchanged when save-backed cases are used;
- native SP/MP status stated accurately.

Native feel tests should focus on overlapping speech, whether exchanges are understandable while fighting, silence frequency, faction personality distinction, and whether overheard NPC talk feels natural rather than staged.
