# Roadmap — Semantic NPC Group Conversation

**Parent objective:** generalize the accepted combat semantic architecture so companions, neutral NPCs, hostile NPCs and faction squads can participate in coherent, grounded, bounded NPC-to-NPC and NPC-to-player encounter conversations without split dialogue systems, expensive polling, text reparsing or new persistent transcript state.

All phases G0-G8 are mandatory unless explicitly marked optional.

## G0 — Production baseline and ownership contracts

Characterize current production truth before behavior changes:
- follower-only `CombatEncounterIntent` team identity;
- owner-only NPC threat-group propagation;
- faction identity/member indexes and leader ownership;
- existing combat candidate spatial queries/fanout;
- current NPC self-kill speech transport to nearby players;
- `NPCSpeech(actorID,targetID)` envelope behavior;
- existing in-world NPC speech renderer;
- Combat Banter Arbiter budgets and decision trace.

Add focused regression tests that freeze these boundaries.

**Gate:** the missing generic cohort/audience/exchange seams are mechanically demonstrated; no behavior change required.

## G1 — Generic runtime Combat Cohort

Introduce one bounded `CombatCohort` resolver/read model.

It must:
- resolve owner teams, authoritative explicit groups when available, factions and solo NPCs;
- use existing owner/faction/group authority;
- never persist duplicate membership;
- distinguish cohort identity from local participant eligibility;
- accept/reuse bounded local candidates rather than scanning faction membership;
- expose leader/spokesperson hints without becoming combat authority.

Migrate shared team-key logic toward this resolver.

**Gate:** companion, neutral faction, hostile faction and solo fixtures resolve deterministically; unrelated nearby strangers do not become teammates; zero new ModData/global scan.

## G2 — Generalize Encounter Intent

Refactor the accepted `CombatEncounterIntent` behind the generic cohort identity.

Preserve follower behavior exactly while enabling autonomous cohorts.

Requirements:
- `undecided / engage / avoid / hold` remains the canonical live contract;
- encounter-scoped/runtime-only;
- self-defense remains immediate;
- player followers still accept player semantic choices/implicit player action;
- autonomous cohorts resolve through existing AI/faction/combat authority;
- leader/spokesperson selection is cohort-aware;
- clear/stale encounter invalidation works for every cohort kind.

Do not leave a permanent companion-only intent service beside a new faction service.

**Gate:** old companion tests pass unchanged or by compatible contract migration; neutral/hostile cohort fixtures resolve without player ownership.

## G3 — NPC-to-NPC semantic speech and audience transport

Make `actorID -> targetID` a first-class transient NPC speech path.

Add/extend transport/presentation so:
- NPC A may address NPC B or its cohort;
- nearby players may observe the speech;
- observer != recipient;
- player buttons appear only when the player is actually targeted/eligible;
- existing NPC `:Say()` / semantic presentation remains renderer;
- no conversation UI is required for NPC-to-NPC speech.

Do not create a second response/presentation engine.

**Gate:** one semantic NPC-to-NPC turn renders to legitimate nearby observers, preserves actor/target provenance, and produces zero player choices when the player is merely overhearing.

## G4 — Bounded Combat Exchange Director

Add one ephemeral semantic exchange state machine.

It owns:
- exchange ID;
- encounter/cohort/topic;
- bounded participants/fact refs;
- previous semantic act/speaker/target;
- expected response relation;
- turn budget;
- TTL;
- bounded anti-repeat strategy state.

It does not own:
- rendered prose;
- perception scans;
- gameplay combat decisions;
- durable memory.

NPC replies consume the prior semantic frame directly; never reparse realized text.

**Gate:** deterministic worker cases prove coherent `WARN -> PROPOSE -> ACCEPT/DISAGREE -> ACK/COMMAND` chains, max-turn termination, timeout and no text reparsing.

## G5 — Dynamic autonomous squad conversation

Use the exchange layer for grounded combat scenarios, initially:
- horde warning and engage/avoid/hold debate;
- ally hurt/downed warning/reassurance;
- NPC kill acknowledgement/boast/reaction;
- retreat/advance acknowledgement;
- reload/cover only if authoritative gameplay facts already exist.

Neutral/hostile/follower cohorts share the same semantic acts and realization architecture; predicates/style differ by context.

Autonomous group decisions must reflect actual AI/faction/combat intent. Dialogue may debate or express the decision but must not fabricate unsupported tactics.

**Gate:** neutral and hostile squads form coherent exchanges without a player participant; companions retain existing behavior; incompatible facts cannot select lines.

## G6 — Unified chatter arbitration and performance

Route exchange admissions/turns through the existing Combat Banter Arbiter.

Requirements:
- urgent warning > optional reply > ordinary boast;
- at most one active speaker and bounded optional respondent;
- cohort/family/speaker/global budgets;
- repeated low-value events commonly produce silence;
- reuse existing event candidate/spatial query when possible;
- at most one additional bounded spatial query at exchange admission when unavoidable;
- no per-frame/per-NPC polling;
- no whole-faction iteration for local speech.

**Gate:** multi-faction burst/horde stress proves bounded query/fanout/turn counts and explainable silence.

## G7 — Combat Observatory / Semantic Lab extension

Expose bounded read-only inspection for:
- resolved `cohortKey/kind`;
- local participant candidates and rejection reasons;
- leader/spokesperson;
- active encounter intent;
- active exchange ID/topic;
- current/previous semantic act;
- speaker -> target;
- expected response;
- remaining turn budget/TTL;
- arbiter admission/rejection reason;
- presentation recipient vs observers;
- why a player did or did not receive response offers.

Do not add a transcript dump.

**Gate:** an agent can explain why NPC B replied to NPC A, why another NPC stayed silent, and why the player only overheard the exchange.

## G8 — Broad regression, scale and developer acceptance

Run:
- full Lua suite;
- focused faction/perception/combat/semantic tests;
- real Semantic Harness worker matrices;
- NPC-to-NPC exchange matrices;
- multiplayer/local-observer transport model tests;
- deterministic CodeBuilder double generation;
- EN/TL/source consistency;
- installed-PZ Kahlua verification;
- static scan/performance guards;
- transient lifecycle/no-ModData/no-LLM assertions;
- save/source immutability where applicable.

Stress:
- multiple nearby factions;
- large faction registry with few local participants;
- simultaneous horde and NPC-vs-NPC combat;
- burst kills;
- player entering/leaving observation range;
- cohort leader death/change during an exchange;
- encounter clear while a reply is pending.

**Gate:** all developer-side acceptance is green with exact evidence. Native SP/MP timing, overlapping speech readability and subjective conversational feel remain user-owned.

## Explicit future/optional extensions

Do not make these mandatory for G0-G8:
- non-combat settlement small talk;
- long-form autonomous NPC social scenes;
- persistent remembered conversations;
- routine LLM-generated NPC group chatter;
- radio/remote squad conversations;
- large command-wheel redesign;
- fully simulated debate/voting beyond the bounded encounter decision policy.
