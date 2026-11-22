# Architecture — Thematic Semantic Dialogue Expansion

## Core thesis

Expand Project Hoomans dialogue on top of the accepted ConvoEngine, Semantic Social Director, Scene Runtime, relationship/knowledge/memory authorities, CodeBuilder pipeline, first-party InlineChat, and the newer bounded DialogueBeats/event-thread path. Do not create a parallel dialogue engine, parser, social scheduler, relationship store, memory store, transcript store, or per-NPC polling system.

The target is one semantic language with two runtime lanes:

    INTERACTIVE SCENE
      participant continuity + player/NPC response authority
      + semantic frontier + branching + possible consequences

    TRANSIENT BEAT THREAD
      event-driven opening + bounded delayed replies
      + no interactive choice + transient presentation by default

Both lanes consume canonical semantic meaning and shared realization/presentation contracts. Neither owns gameplay truth.

## 1. Interactive Scene vs transient Beat thread

Interactive Scenes own conversations that require any of: player-selectable response, open-ended semantic continuation, knowledge Q&A, relationship negotiation, meaningful multi-turn branching, participant admission/leave, suspend/resume, or consequences that may reach existing social/memory/task authorities.

Transient DialogueBeats own low-latency event speech such as combat warnings, stamina/medical callouts, weather/world-object comments, TV/device reactions, and similar short situational exchanges. They may schedule a bounded opening and replies, but they must not grow into a second Social Director.

Rules:
- sceneID is interactive conversation authority;
- threadID is transient/correlation identity for presentation, cooldown continuity and short reply chains;
- threadID must not become a durable memory key or replacement scene authority;
- a transient beat that becomes interactive must hand off into the existing Scene Runtime instead of adding response selection to DialogueBeats;
- transient beats are non-persistent and non-consequential by default;
- relationship/task/world mutation remains in existing domain authorities.

## 2. N-actor invariant

Actor count is runtime Scene/thread state, never semantic-family identity. Authoring separates scene roles (initiator, subject, victim, witness, leader, bystander), turn roles (speaker, addressee, audience), typed grounded slots, and runtime participant identity.

Never encode player/NPC identity, actor count, actor ordinals, or pair topology into ordinary semantic IDs. Prefer combat.warning.horde, medical.concern.check_victim, social.knowledge.ask_person over npc_to_player_warn_horde, three_actor_horde_warning, or witness2_check_victim.

Authority-specific mechanics may still constrain a role to a player or NPC at runtime, but that does not automatically justify a player/npc-specific semantic family.

## 3. Canonical semantic naming and family granularity

Use <domain>.<subdomain>.<semantic_action> for meaning-driven IDs.

Do not create separate semantic families merely for personality style, locale, player-vs-NPC, actor count, phrase alternatives, or relationship tier when the meaning is the same.

Also avoid the opposite failure: one giant family must not hide unrelated meanings only through variant IDs. A family should be split when variants differ in semantic intent, required slots, outcome, grounding, continuation, or consequence policy rather than merely wording/style.

Current high-priority audit examples include large multi-meaning pools such as combat.ally_warn.reply, combat.ally_warn.callout, combat.kill.killer, and world.beats.*. D0 must classify which variants are true realization/style alternatives versus distinct semantic meanings.

Before creating or retaining a family, decide whether the difference is a semantic meaning, reply outcome, stance, realization/style variant, predicate, typed slot, runtime role binding, or Beat reusing another family.

## 4. Branching contract

Every non-atomic interactive family must expose meaningful semantic continuation. Atomic urgent warnings, acknowledgements, transient barks and explicit terminal acts may remain one-shot.

Each branch carries machine-readable meaning/frame, outcome, stance where applicable, eligibility, continuation, and grounded refs/slots where applicable.

Recommended social stances are positive, neutral, negative and contextual. Outcome and stance are separate. Positive/neutral/negative are preferred social coverage where appropriate, not a forced trinary for every family; informational families may use known/unknown/uncertain/refused/evasive.

## 5. Hard constraints vs soft preferences

Hard predicates represent impossibility/authority: required item/capability, known fact, relationship state, witnessed event, injury/task/world state, valid slot/entity, required role, speech/action capability. Hard eligibility is evaluated before utility.

Ordinary temperament, relationship strength, mood, panic, fatigue, injury pressure, novelty and local context normally influence soft utility rather than binary access.

## 6. One resolved disposition projection

Project Hoomans already generates persistent identity-seeded numeric personality and composes trait effects onto those values. Generic dialogue behavior must consume a single normalized resolved disposition projection rather than independently reinterpreting trait names and thresholds in multiple systems.

Current audit found overlapping personality interpretation in ActorAdapter, ChoicePolicy, GeneratedAffordanceProvider, SemanticCombatReactionProfile, BeatContext fallback logic, and speech-style selection. D2 must converge these onto one shared resolved projection/API where practical, with presentation-specific style derived from that projection rather than duplicated trait classifiers.

Canonical numeric inputs include compassion, sociability, forgiveness, bravery/confidence, materialism, aggression and loyalty, plus current relationship/state/context.

Bad: hasTrait(Brave) gives CHALLENGE a fixed bonus after the same trait already changed bravery.
Preferred: CHALLENGE utility derives from resolved confidence/bravery, aggression, respect, panic, relevance and context.

Direct trait-ID predicates require documented semantic justification where trait identity itself is essential and cannot be represented by normalized capability/fact. Prefer projecting special traits into capabilities/knowledge first.

Do not reroll stored personalities. The uniqueness mechanism is identity seed + archetype + trait effects + current context. This goal does not add per-turn randomness merely for variety.

## 7. Declarative content vs runtime adapters

Runtime Lua detects game events and exposes typed context; canonical ConvoEngine/CodeBuilder sources own reusable semantic meaning and conversational policy wherever the existing IR can express it.

Do not hard-code growing content catalogs, role strings, pool IDs, personality-style matrices, reply plans or world-event dialogue policy in event adapter Lua when they can be declarative Beat/Behavior/Dialogue definitions.

Game-specific adapters may remain code for engine hooks, object matching, spatial queries, player-damage detection, inventory inspection, etc., but they should emit typed event/context into canonical semantic policy.

## 8. Domain-neutral semantic speech transport

The new DialogueBeats path currently reuses CombatTargetCallouts delivery/resolution for non-combat content, including weather/world events. That is acceptable as current working code but is architectural debt.

D3 should extract/reuse a domain-neutral semantic realization/presentation seam so world, social, medical, combat and future beat adopters do not need combat-named event IDs or combat-specific delivery modules merely to speak. CombatTargetCallouts should become a combat adopter of that shared mechanism, not the universal transport owner.

Do not duplicate the SocialFlavorClient or create another client queue. Preserve its bounded presentation arbitration, thread continuity and optional TTS integration.

## 9. Meaning, context and memory

Every meaningful act exposes structured meaning independent of wording: family, intent, speechAct, subject/topic, outcome, stance, speaker/addressee/audience, grounded refs/slots, reply/scene/thread relation, evidence/fact refs, and bounded provenance/salience where applicable.

Rendered text is presentation, never context/memory authority. Context should resolve structured semantic history and grounded refs rather than reparsing old prose.

Not every spoken line becomes durable memory. Ordinary chatter and transient beats remain ephemeral; consequential confession, betrayal, promise, threat, rescue or relationship-changing acts may persist only through existing memory/social authorities. No transcript persistence.

## 10. Fuzzy input and presentation surfaces

Fuzzy parsing, typo recovery, confidence and semantic candidates remain shared parser/Core responsibilities. Equivalent typed, clicked, InlineChat and supported group-input paths must converge on the same semantic meaning.

InlineChat is now first-party Conversation UI, not PBrainZ-owned. PBrainZ remains optional fallback/rephrasing/integration and must never own semantic authority.

Full conversation UI, InlineChat, nameplate/transient speech and SocialFlavor/TTS are presentation/admission surfaces, not separate dialogue semantics.

## 11. World and voice bible

Dialogue should sound like survivors in Project Zomboid's 1990s Kentucky apocalypse. Remove UI/system/development phrasing when ordinary survivor language exists. Use grounded camp/home, supplies, work/runs, roads/places, injuries/needs, weather, zombies/the dead, known people/factions, witnessed/remembered events and real task/world state.

Tactical language is contextual rather than universal. Personality/style changes tone, openness, confidence, aggression, humor and wording, but never objective facts.

## 12. Themes and Beats

Initial interactive thematic coverage remains: greeting/first contact; wellbeing/needs; identity/personal history; gossip/news/grounded knowledge; colony life/work; travel/excursion; combat/aftermath; relationship/social conflict.

Transient Beat coverage now also explicitly includes combat ally warnings, stamina/medical situational replies, environmental weather/utilities, world-object vicinity events, house alarms, TV/device text, and player-assault reactions. These must use canonical semantic definitions and typed adapters rather than becoming another content authority in Lua.

## 13. Performance and authority invariants

Preserve the recent lag improvements. Do not introduce new independent OnTick/per-NPC loops, full registry/faction/zombie scans, routine LLM dependency, transcript persistence, pairwise Scene explosion, or unbounded candidate/participant/beat queues.

Reuse the existing shared subsystem pump and event hooks. Bounded cadence/local spatial queries are allowed when they remain explicitly budgeted and benchmarked. Current DialogueBeats/SocialFlavor queue and cadence bounds are baseline evidence, not permission to add additional polling layers.

Generated Lua/translations remain downstream of canonical CodeBuilder sources. Native SP/MP naturalness/performance remains a user-owned final acceptance gate.

## 14. Chronology milestones, scoped world events and demeanor

The dialogue/beat architecture must support both personal chronology milestones and shared world-state events.

### Personal chronology milestones

Examples include:
- surviving a first week/month/season/year;
- crossing data-driven survival-age milestones;
- anniversaries of major remembered events where policy marks them salient.

Milestones are semantic events/facts, not hard-coded dialogue timers. Their schedule must be data-driven and derived from stable world age / actor chronology. Do not poll every NPC every tick. Prefer coarse scheduler boundaries, due-index/bucket processing, actor materialization/reconciliation, or another existing bounded scheduler seam.

A milestone may:
- emit a one-time transient Beat when an eligible actor is present;
- become a bounded autobiographical/world-knowledge fact when semantically important;
- influence temporary demeanor;
- expose an interactive follow-up through Scene Runtime if the player engages.

The same milestone semantic identity must work for NPC->NPC and NPC->player realization.

### Scoped world events

Future random/world events may affect global, region, faction, settlement, or bounded spatial scopes. Examples include:
- food crisis / widespread starvation pressure;
- agricultural surplus;
- bandit/raider activity surge;
- epidemic, severe weather, migration/refugee pressure, utility failure, trade disruption, or other future events.

The reusable contract should carry typed data such as:

    eventID
    type / semantic tags
    startsAt / endsAt
    scope
    severity
    source/provenance
    effect descriptors
    presentation/knowledge metadata

Core may own a reusable bounded scoped-event contract/registry only if current audit proves no equivalent exists and multiple adopters need it. Project Hoomans owns its gameplay/world-simulation event definitions and consequences. Dynamic Trading owns its economic projections. Neither may treat the other's event store as the global simulation authority.

Avoid long event-ID switch statements in consumers. Consumers should normally react to typed effect tags/capabilities such as food availability pressure, scavenging priority, hostile-group activity, travel risk, morale pressure, medical demand, or trade scarcity.


World-event selection itself must be server-authoritative, bounded, and reproducible. Prefer a coarse calendar/time-bucket scheduler with a stable world/region/scope seed, weighted eligibility, cooldown/exclusion rules, and deterministic duration/severity selection. Do not run per-NPC random-event rolls or use live math.random/clock state as semantic authority. Event definitions should be data-driven so themed events such as a food-crisis/starvation period or a "Bandit Bonanza" raider surge are authored policy rather than hard-coded branches.

### Demeanor overlay

Do not rewrite persistent seeded personality merely because an event is active.

Use a separate bounded mutable demeanor/affect projection, conceptually including values such as:

    morale / hope
    scarcity anxiety
    vigilance / fear
    hostility / irritability
    grief / stress
    confidence pressure

Exact dimensions must be audited against existing mood/condition/social-state authorities before adding new fields.

Resolved dialogue behavior becomes:

    stable seeded personality
      + trait effects
      + directed relationship
      + current physical condition
      + bounded demeanor/affect
      + current scoped world events
      + knowledge/memory
      + scene context
      -> semantic utility/style

Demeanor changes must be deterministic, bounded, inspectable, and decay/recover according to policy. Important events may create durable memories; the transient demeanor response itself must not become unbounded history.

True long-term personality development, if added later, is a separate explicit policy with bounded drift and must not be implemented by directly accumulating temporary world-event modifiers into base personality.

### Simulation projections

A world event should affect simulation through owning systems rather than arbitrary direct mutations.

Example: widespread food crisis should primarily project into food availability/reserve pressure, group/individual needs, scavenging priority/yield policy, settlement behavior and market scarcity. Existing starvation/health consequence systems should then produce increased sickness/death risk naturally. Do not implement a generic "kill NPC because food_crisis event is active" shortcut.

Example: a raider-activity surge should project into the owning hostile/mobile-faction generation, mobility, intent/risk or encounter policies. Dialogue observes the resulting event/facts/context; it does not spawn raiders itself.

### Dynamic Trading projection

Dynamic Trading already owns a generic bounded MarketEvent registry with global/region/faction/settlement scopes and category supply/demand/availability/price modifiers.

The cross-mod direction should be:

    scoped world event / authoritative simulation fact
        -> bounded DTHoomans/DTCommon adapter
        -> Dynamic Trading MarketEvent projection
        -> settlement market pressure / trader opportunity / pricing

Dynamic Trading may still create market-native events from its own economic conditions. It must not become the authority for Hoomans starvation, raider activity, NPC mortality, faction behavior, or world chronology.

Where a local spatial event affects nearby settlements, resolve the bounded affected settlement set once through authoritative world/settlement spatial services and project settlement/region-scoped economic effects; do not make every consumer independently scan all settlements.

### Knowledge and dialogue propagation

Actors should only discuss a world event when they can plausibly know it:
- directly experienced/witnessed;
- faction/shared settlement knowledge;
- public/environmental observation;
- radio/news;
- told/gossip;
- inferred from grounded conditions.

WorldKnowledge facts should carry event provenance and scope so dialogue can distinguish:
- "we are starving here";
- "I heard Riverside is running out of food";
- "roads are crawling with raiders";
- uncertain rumor vs directly experienced fact.

Milestone/world-event Beats should therefore reuse structured world facts rather than generating omniscient dialogue.
