# Roadmap — Semantic Social Conversation Director

**Status:** DEVELOPER COMPLETE — D0-D8 accepted; READY FOR USER LIVE TEST.

**Parent objective:** implement the complete agnostic Social Conversation Director so multiple Project Hoomans NPCs can engage in grounded, performant, emergent semantic conversations by reusing the existing Scene Runtime and semantic affordance/choice system across companions, neutral/faction NPCs, hostile teams and player-participating scenes.

All D0-D8 phases were mandatory developer-side work and are now accepted. Native SP/MP timing/readability/noise tuning remains user-owned.

## D0 — Baseline and affordance authority freeze

Characterize current behavior before refactoring.

Required:
- freeze generated player-affordance candidate shapes and maximums;
- freeze current player button/typed-input behavior for representative semantic contexts;
- characterize recurrence policy and player-specific dependencies;
- freeze Scene Runtime participant/turn/observer behavior;
- identify all production consumers of GeneratedAffordanceProvider;
- identify where semantic candidate labels/UI metadata diverge from semantic meaning;
- establish focused harness fixtures and real-worker traces.

Do not introduce ambient chatter in D0.

**Gate:** current player affordance behavior and Scene interoperability are evidence-backed, and the exact actor-neutral extraction seam is documented in code/tests.

## D1 — Actor-neutral semantic affordance frontier

Refactor/generalize the reusable semantic candidate layer.

Required:
- actor-neutral responder/counterpart context;
- actor-neutral traits/relationship/knowledge/capability eligibility;
- bounded semantic candidate contract;
- recurrence policy independent of hard-coded player-turn assumptions;
- existing player provider/UI becomes an adapter/consumer of the common frontier;
- typed player NLU remains unaffected;
- no rendered text/button label parsing.

**Gate:** both player and synthetic NPC responders can consume the same semantic frontier, while focused player semantic/button regressions remain green.

## D2 — Social motive and opportunity director

Introduce the generic social opportunity/dramaturgy layer above SceneRuntime.

Required:
- SocialOpportunity contract with grounded event/fact refs;
- motive families such as INFORM/WARN/REQUEST/CHECK/ACKNOWLEDGE/REACT/SOCIALIZE/DISPUTE/REPAIR/COORDINATE/SILENCE;
- explainable admission/rejection;
- bounded explicit candidate actors;
- opening speaker/recipient selection;
- social purpose/topic metadata passed into one existing Scene;
- no domain-specific conversation engine.

**Gate:** at least two unrelated synthetic opportunity families can open or reject one canonical Scene through the same generic Social Director.

## D3 — NPC semantic choice policy

Let NPC responders select from the same semantic affordance frontier.

Required:
- hard eligibility before ranking;
- personality/trait influence;
- directed relationship/disposition influence;
- knowledge/evidence constraints;
- current condition/activity context where meaningful;
- recent semantic act/strategy suppression;
- deterministic fixture/tie-break behavior;
- explicit silence/no-response candidate or threshold;
- explainable selection trace.

The policy selects semantic acts, never rendered text.

**Gate:** controlled fixtures demonstrate materially different but grounded NPC choices for different personalities/relationships, including silence, without changing the underlying valid affordance set incorrectly.

## D4 — Multi-participant turn arbitration

Add coherent group turn-taking above existing Scene continuation.

Required:
- current recipient gets normal reply priority;
- other participants may join/interject only through explicit motives;
- at most one ordinary semantic speaker wins each turn;
- recipient may change across turns;
- one Scene supports A->B, B->A, C->A, A->C style topology;
- no chorus response;
- no pairwise scene explosion;
- actor leave/death remains owned by Scene Runtime;
- player observer/participant role remains correct.

**Gate:** 2-, 3- and 4-actor fixtures produce deterministic coherent speaker/recipient sequences and terminate cleanly.

## D5 — Ambient chatter budgets, novelty and interruption

Make emergence performant and non-spammy.

Required:
- actor cooldown;
- pair cooldown;
- topic/motive recurrence suppression;
- local group/area chatter budget;
- scene opening rate limit;
- novelty/urgency ranking;
- lower-value opportunities commonly reject;
- explicit interaction with existing combat chatter priority without replacing Combat Banter Arbiter;
- bounded urgent interruption/preemption policy where existing Scene/runtime contracts permit it.

No per-NPC recurring conversation poll.

**Gate:** burst/stress fixtures show bounded openings/turns, silence under low-value repetition, no starvation of urgent valid events, and no global actor scans.

## D6 — Production grounded adopters

Prove the generic architecture with real Project Hoomans domains.

Mandatory production families:

### D6A Post-combat/social decompression
Reuse actual combat/encounter facts and current combat banter/event authorities. Demonstrate non-tactical social reactions after meaningful combat without duplicating combat authority.

### D6B Task/work coordination
Use authoritative task/work state for request/status/acknowledgement/complaint/coordination conversation. Dialogue may not directly assign or mutate work outside Tasking authority.

### D6C Grounded social knowledge / settlement event
Use actual knowledge/news/gossip or community/settlement/excursion facts. Speakers cannot disclose unknown/private facts.

At least one adopter must exercise a hostile/raider or otherwise non-companion NPC team with no player required.

**Gate:** all three production families use the same Social Director + Scene Runtime + affordance frontier + NPC choice path with no feature-owned generic dialogue scheduler.

## D7 — Player interop and consequential social events

Complete mixed player/NPC group behavior.

Required:
- observer-only player hears eligible presentation but receives no buttons;
- addressed player receives existing response affordances;
- player typed/button semantic response returns to the same Scene;
- after player response, NPC group may continue using NPC choice policy;
- semantic/social acts can route into existing conduct/relationship/knowledge/etc. event paths;
- generic director never directly writes relationship/faction/task values;
- UI closure does not corrupt autonomous Scene state.

**Gate:** one mixed 3+ actor scene transitions NPC->NPC -> NPC->player -> player->NPC -> NPC->NPC without duplicate authority or observer leaks.

## D8 — Observatory, extensibility, scale and developer acceptance

### Observatory
Expose bounded read-only diagnostics:
- opportunity provider/motive;
- admission/rejection/silence reason;
- participant candidates and selected participants;
- speaker/recipient candidate rows;
- affordance frontier IDs/strategies;
- NPC choice ranking/rejection reasons;
- chatter budget/cooldown state;
- continuation/termination;
- grounded refs;
- LOD/observer state;
- query/candidate counts.

No transcript dump.

### Extensibility
Add a synthetic fourth future social provider/motive through public seams without editing generic SceneRuntime, InteractionDirector, generic Social Director algorithm or generic NPC choice algorithm.

### Scale/stress
Prove:
- large registered population with tiny local candidate set;
- 20+ opportunity burst;
- multiple simultaneous social/combat scenes;
- 4 participants remain one Scene;
- repeated low-value event suppression;
- urgent event remains serviceable;
- actor leave/death;
- distant semantic-only LOD;
- no routine LLM;
- no new persistence root/transcript.

### Final validation
Run:
- full isolated Lua suite;
- focused semantic/dialogue/player regressions;
- Social Director/affordance/group-turn Lua tests;
- real Semantic Harness worker suites;
- production adopter matrices;
- Observatory assertions;
- deterministic CodeBuilder double generation if content changed;
- EN/TL/source consistency if content changed;
- installed-PZ Kahlua compile checks;
- static no-scan/no-text-reparse/no-routine-LLM/no-transcript guards;
- source/save immutability where applicable;
- Python `py_compile` for changed harness code;
- `git diff --check`.

**Gate:** D0-D8 developer-side objective is complete. Native SP/MP timing/readability/noise-level validation is accurately handed to the user.

## Non-goals / future only

Do not add these merely to claim completion:
- routine LLM-driven chatter;
- persistent conversation transcripts;
- cinematic scripted scene editor;
- large-group voting/deliberation;
- radio/remote social scenes;
- romance-specific engine;
- companion-only or hostile-only generic dialogue engines;
- full settlement simulation changes unrelated to conversation.
