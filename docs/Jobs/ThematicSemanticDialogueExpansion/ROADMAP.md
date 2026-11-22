# Roadmap — Thematic Semantic Dialogue Expansion

## Parent objective

Transform the current Project Hoomans dialogue estate into a coherent actor-agnostic semantic system with two clearly bounded runtime lanes: full interactive Scenes and lightweight transient Beat threads. Consolidate semantic meaning, branching, grounded constraints, numeric-personality influence, structured context/memory provenance, presentation parity and in-world voice without creating a parallel engine or undoing the recent performance gains.

## Re-audited planning baseline — 2026-11-22

Current local participant heads at planning re-audit:
- ProjectHoomans main: 2b9d579df8cd67c623027fde3715a77ec4219d90;
- psychopatzCore main: 89f7b85add7ff317bbac3c66bb004d35fda24f4a.

Important changes since the original planning baseline:
- first-party InlineChat replaced the old PBrainZ-owned inline-chat surface and now submits through the canonical semantic conversation path;
- threadID is carried through Scene/transient speech presentation and Core SocialFlavor arbitration;
- PNC.Semantics.DialogueBeats now owns a bounded transient opening/reply queue and shared-pump scheduling for situational/world speech;
- BeatContext provides cached actor/environment projections;
- new combat ally, stamina/medical, player-assault, weather, utilities, world-object, house-alarm and TV semantic content was added;
- relationship/persistence paths were optimized and should remain authoritative rather than copied into Conversation;
- several combat/pathing/persistence/data-mutation optimizations materially improved runtime lag and must be protected by regression gates.

Current corpus spot-check at this HEAD:
- 353 canonical dialogue JSON definitions;
- only 5 definitions currently contain an actual flow structure;
- 1 explicit branchOffers occurrence and 3 onUnrelated occurrences;
- 35 filenames/IDs still encode player/NPC identity in some form;
- 26 files still encode personality/style labels such as brave/aggressive/cold/reserved/shaken/supportive;
- 15 farewell definitions now split player/non-player and relationship variants even though representative files have no actual flow graph;
- large variant pools include combat.ally_warn.reply (32), combat.kill.killer (26), combat.ally_warn.callout (18), and world.beats.* multi-event packs;
- direct temperament trait checks remain in ChoicePolicy and GeneratedAffordanceProvider; SemanticCombatReactionProfile also reclassifies direct traits alongside numeric personality, and BeatContext has fallback threshold logic.

These are verified planning findings, not a substitute for D0's exhaustive manifest.

## Non-goals

- no second dialogue engine/parser/social scheduler/relationship or memory store;
- no giant static sentence-tree replacement for semantic composition;
- no requirement that transient barks become interactive flows;
- no fake positive/neutral/negative branches for atomic/factual terminals;
- no routine LLM requirement or transcript ModData;
- no actor-count/player-vs-NPC/personality-class dialogue libraries;
- no manual edits to generated Lua/translations;
- no compatibility-shim graveyard;
- no per-turn randomness project: seeded personality/context is the intended emergent variation source;
- no arbitrary content-volume target.

## D0 — Live topology + exhaustive corpus/consumer audit

Audit the current system as it exists now, including both interactive Scene and transient Beat-thread lanes.

Build a machine-readable manifest for every canonical conversation source and relevant runtime consumer with:
- semantic family/path/domain/kind;
- interactive Scene vs transient Beat vs shared realization/presentation classification;
- actual flow nodes, branches, continuation, thread/scene ownership;
- stance/outcome/frame completeness;
- roles/cardinality and typed slots/grounded refs;
- hard predicates and soft utility inputs;
- numeric personality/trait/relationship/item/world/knowledge usage;
- direct trait-ID checks and duplicate personality projection logic;
- player/NPC/actor-count-specific identity;
- overpacked families where variants may hide different meanings;
- memory/provenance semantics;
- localization/generated ownership;
- all input/presentation surfaces: full UI, InlineChat, group input, nameplate/social flavor/TTS;
- tests/fixtures/benchmarks and performance budgets.

Also map current hard-coded DialogueBeats hook policy, pool IDs, event IDs, cooldowns and world-event selection that could be declarative.

Gate: no-silent-omission corpus/runtime manifest, duplicate and overpacking clusters, direct-trait/projection duplication map, Scene-vs-thread topology map, domain-leak map, exact migration targets. No broad rewrite before this gate.

## D1 — Canonical semantic-family normalization

Normalize meaning-driven IDs and family granularity.

Tasks:
- consolidate player/NPC, actor-count, relationship/style and personality-labelled duplicates where semantic meaning is actually the same;
- split overpacked families when variants differ in intent, required slots, grounding, outcome, continuation or consequence rather than wording/style;
- remove misleading naming such as flow.* where no real flow contract exists, unless the definition is migrated into a true flow;
- preserve true mechanic/authority distinctions as predicates/role constraints rather than family identity when possible;
- add lint/audit rules preventing both duplicate families and multi-meaning dumping grounds.

High-priority D0/D1 exemplars include event_reactions_farewell, combat_player_assault_reactions, combat ally warning pools, combat kill reaction pools and world_event_beats.

Gate: canonical IDs/families reflect semantic meaning; automatic audits reject new duplication/overpacking patterns; all migrated callers/generated artifacts reconcile.

## D2 — Unified actor disposition/personality projection

Converge generic dialogue/social decision consumers onto one resolved numeric disposition projection.

Audit and normalize ActorAdapter, Social ChoicePolicy, GeneratedAffordanceProvider, SemanticCombatReactionProfile, BeatContext actor_stats/fallback, SpeechStyleContext and any content predicates that independently classify Brave/Shaken/Aggressive/etc.

Rules:
- traits remain upstream inputs to personality/behavior/speech effects;
- no generic direct trait bonus after the same trait already influences numeric personality;
- presentation style may be derived from the resolved profile but should not reimplement different trait matrices per subsystem;
- special direct trait checks remain only for unique semantics/capabilities with documented justification;
- stored personalities are not rerolled.

Gate tests:
- same trait set + different identity seeds -> different resolved tendencies;
- high numeric bravery/confidence without literal Brave still affects courageous choices;
- brave-like trait does not force brave behavior when resolved profile/context disagrees;
- no double-counting;
- Scene and transient Beat style derivation agree on the same actor profile.

## D3 — Scene/thread boundary and domain-neutral semantic speech transport

Formalize the two runtime lanes and remove current cross-domain transport leakage.

Interactive Scene responsibilities remain with Scene Runtime/Social Director. DialogueBeats remains a bounded transient event thread only.

Extract/reuse a domain-neutral semantic realization/presentation seam so world/weather/TV/social/medical beats do not need combat_ally_warn_* event IDs or CombatTargetCallouts delivery merely to speak. CombatTargetCallouts becomes a combat adopter of the shared seam.

Preserve one Core SocialFlavorClient queue/arbitrator and its thread-aware/TTS behavior; do not create a second client speech queue.

Define lifecycle rules for sceneID vs threadID, actor death/leave, expiry, interruption, cooldown continuity and handoff from transient beat -> interactive Scene when interaction becomes player-responsive.

Gate: domain-neutral transport tests, no combat-named semantic dependency for non-combat beats, bounded thread cleanup, no thread/scene identity collision, no duplicate client queues.

## D4 — Declarative thematic interactive branching

Upgrade interactive themes: greeting/first contact, wellbeing/needs, identity/personal history, gossip/news/knowledge, colony life/work, travel/excursions, combat/aftermath, relationship/conflict.

Use small bounded semantic graphs (generally 2–5 meaningful exchanges), reply outcomes, recommendations, goto/resume/end, typed slots and reusable families.

Every non-atomic interactive family gets meaningful alternatives. Positive/neutral/negative are preferred stance coverage where appropriate; informational/transactional meanings use domain outcomes when better.

Gate: thematic multi-turn coverage, no accidental one-shot dead ends, no artificial trinary, no actor-count duplication, typed/clicked/InlineChat semantic equivalence.

## D5 — Grounded constraints, meaning and memory provenance

Expand contextual branches using authoritative directed relationship, resolved disposition, condition/needs, inventory/item capability, actor capability, knowledge/evidence, witnessed events, task/work state, location/world/danger and scene roles.

Hard eligibility fails closed; soft utility ranks eligible choices. Prefer semantic item capabilities/categories and typed slots over exact Base.* IDs unless exact identity is necessary.

Normalize structured meaning/provenance: family, intent/speech act, subject/topic, outcome, stance, grounded refs, scene/thread/reply relation, fact/evidence refs, bounded salience.

Only existing memory/social/evidence authorities may persist consequential meaning. Ordinary dialogue and transient beats remain non-durable by default.

Gate: no fabricated facts/items/relationships/world state; context resolves without rendered-text reparse; durable-memory decisions are inspectable and bounded.

## D5A — Chronology milestones, scoped world events and demeanor integration

Before final grounding/memory normalization, establish the semantic consumption contract for personal chronology and shared world conditions.

Audit first:
- existing world-age/calendar/scheduler seams;
- SurvivorWorld / region / faction / settlement identities;
- GroupNeeds, IndividualNeeds and starvation/health consequences;
- abstract scavenging, faction/mobile-group behavior and encounter systems;
- WorldKnowledge fact/provenance;
- Dynamic Trading MarketEvents/MarketEventProducer/SettlementMarket and DTHoomans adapters.

Implement only the smallest reusable shared mechanism required by evidence.

Required capabilities:

1. **Data-driven personal milestones**
   - actor survival-age/calendar milestones such as first month/year;
   - exactly-once/bounded triggering without per-NPC tick polling;
   - semantic milestone fact/provenance;
   - transient Beat realization and optional Scene follow-up.

2. **Scoped world-event input**
   - global/region/faction/settlement and bounded local-area targeting where current world topology supports it;
   - stable event identity, duration, severity, provenance and typed effect descriptors;
   - bounded active-event queries/indexes rather than registry-wide scans per NPC.

   - one server-authoritative coarse event scheduler/director with deterministic world/region/time-bucket seeding, eligibility weights, cooldowns, mutual exclusion/stacking policy, and bounded active-event count;
   - no per-NPC random-event rolls and no live RNG/clock-dependent authority.

3. **Temporary demeanor/affect**
   - event/milestone effects project into a bounded mutable overlay, not base seeded personality;
   - decay/recovery and caps;
   - semantic-choice/style integration through the unified disposition/context projection;
   - no unbounded per-event arrays on NPC ModData.

4. **Simulation projection**
   - food-crisis events influence food availability/needs/scavenging/settlement behavior so existing starvation and health consequences create mortality pressure naturally;
   - raider-surge events influence owning hostile/mobile-faction activity and risk policies rather than Dialogue spawning actors;
   - dialogue remains observational/presentational.

5. **Dynamic Trading projection**
   - adapt authoritative world-event effects into DTCommon MarketEvents using existing global/region/faction/settlement scopes;
   - food crisis can lower Food supply, raise demand/availability/price pressure;
   - raider activity can influence relevant trade risk/opportunity categories through Dynamic Trading-owned policy;
   - Dynamic Trading remains economic authority only;
   - market-native events such as pressure-derived shortages remain valid and must not feed back recursively into duplicate world events.

6. **Knowledge propagation**
   - actors only discuss events they know through WorldKnowledge provenance;
   - direct experience, faction/public knowledge, radio, told/gossip and inference remain distinguishable;
   - rumor must not become objective fact merely through dialogue.

Required acceptance exemplars:
- an NPC crosses a configured first-month or first-year survival milestone exactly once and can produce a context-appropriate Beat;
- two NPCs react differently to the same milestone/event because stable personality + relationship + demeanor differ;
- a global or regional food-crisis fixture increases Hoomans food/scavenging pressure and produces a bounded DT Food market projection without direct arbitrary death;
- prolonged lack of food can still lead to higher mortality through the existing Needs/health consequence path;
- a raider-surge fixture increases owning hostile/mobile-group activity policy and produces grounded warning/news dialogue plus an appropriate economic projection;
- deterministic replay of the same world seed/time bucket produces the same scoped random-event selection while a different eligible bucket may produce a different event;
- a nearby-settlement event affects only the bounded resolved settlements/region;
- expired events stop affecting demeanor/simulation/markets while durable historical facts may remain when retention policy says so;
- no duplicate world-event authority, no recursive DT<->Hoomans event loop, and no full-registry-per-NPC scan.

Gate: chronology/world-event/demeanor semantics are reusable, bounded and cross-mod consumable before D6 content expansion.

## D6 — Declarative transient Beat migration + world/voice normalization

Keep engine/game detection in Lua but move reusable transient dialogue policy into canonical ConvoEngine Beat/Behavior/Dialogue definitions wherever expressible.

Targets include combat ally/stamina/medical beat plans, player-assault reaction wording/style selection, weather/utilities, house alarms, world-object vicinity and TV/device reactions.

Runtime adapters should emit typed event/context rather than owning growing role/pool/personality matrices.

Then perform the corpus-level voice pass: grounded Project Zomboid survivor language, no UI/debug/system phrasing, contextual tactical speech, no personality variant changing facts, reduced repetitive quips, EN/TL parity through canonical generation.

Gate: transient beat policy is declarative where practical, adapters remain thin/bounded, sampled world/combat/social transcripts are coherent and in-world.

## D7 — Input/presentation parity and Semantic Lab/Observatory

Treat first-party InlineChat, full conversation UI, group input, clicked affordances, fuzzy typed input, nameplate/social flavor and optional TTS as surfaces over the same semantics.

Explicitly test:
- InlineChat -> semantic submission -> same context/scene;
- group input/fanout without duplicate semantic authority;
- relationship-aware farewell close/handoff;
- typed/fuzzy/button equivalence;
- observer-only transient speech vs addressed interactive Scene;
- sceneID/threadID diagnostics;
- TTS/presentation timing without semantic ownership.

Extend existing Semantic Lab/Observatory, not a new GUI, to expose family granularity, branch reachability, stance/outcome, constraint reasons, disposition contribution, grounding, scene/thread identity, memory/salience, terminology/duplication warnings and 2/3/4 actor role binding.

Gate: authors can explain why content existed, which lane owned it, why a branch/beat won, what it meant, and what persisted.

## D8 — Exhaustive developer acceptance + performance regression

Run deterministic matrices across personality dimensions/trait combinations, relationships, condition states, item/fact presence, work/travel/combat/social/world contexts, 2/3/4 actors, player observer/addressee/NPC-only cases, Scene/thread handoff, interruption/resume, typed/fuzzy/button/InlineChat parity, EN/TL/source ownership and memory bounds.

Re-run relevant Lua/Semantic Harness/CodeBuilder/Kahlua suites plus current dialogue/combat/data-mutation benchmarks.
When D5A touches shared event/economic seams, also run the relevant PsychopatzCore world-knowledge/event tests and DynamicTrading MarketEvents/SettlementMarket/market-pricing/caravan mobility tests.

Performance acceptance explicitly preserves the recent lag fixes:
- no new independent OnTick/per-NPC dialogue loops;
- no full registry/faction/zombie scan;
- shared pump and local spatial queries remain bounded;
- no unbounded beat/thread/client queue;
- no routine LLM;
- no transcript persistence;
- no pairwise Scene explosion;
- generated ownership remains clean;
- git diff --check passes.

Gate: D0–D8 developer objective complete with measured regression evidence.

## D9 — User native SP/MP acceptance

User verifies thematic coherence, NPC uniqueness from seeded personality, readable group scenes, truthful contextual/special branches, natural transient beats, InlineChat/full-conversation continuity, and no lag/save-growth regression.

Reopen only the smallest owning layer if native evidence fails.
