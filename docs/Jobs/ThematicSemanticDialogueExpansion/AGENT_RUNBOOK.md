# Agent Runbook — Thematic Semantic Dialogue Expansion

## Startup

Read repository AGENTS.md, then PROGRESS.md, HANDOFF.md, the active ROADMAP phase, ARCHITECTURE.md, and exact current source/tests. Verify ProjectHoomans and any required PsychopatzCore participant HEAD/worktree before edits. Preserve unrelated work.

## Source authority

Canonical CodeBuilder conversation source/manifests own authored semantics. Generated Lua/translations are downstream. Current source/runtime/tests are truth. Job docs carry scope/continuity.

Do not patch generated drift by hand.

## D0 audit requirements

Do not treat 'dialogue definition' as one homogeneous class. Classify every source/runtime consumer into at least:
- interactive Scene semantic family/flow;
- transient Beat-thread semantic family/plan;
- shared realization/style;
- event/context adapter;
- presentation/input surface;
- generated artifact/index;
- static UI/support content.

For each canonical family record semantic meaning, variants, actual branches/continuation, stance/outcome, roles/cardinality, slots/grounding, predicates, disposition/trait use, relationship/world/knowledge use, memory/provenance, locale ownership, callers, tests and generated ownership.

Flag both duplicate families and overpacked families. Do not assume many variants are good reuse if they represent different intents/slots/outcomes.

## Scene vs Beat rule

Interactive Scene: player/NPC response authority, semantic frontier, open continuation, relationship/knowledge negotiation, participant lifecycle, suspend/resume or consequential acts.

Transient Beat thread: short event-driven opening/replies, transient by default, no player-selectable response, no durable conversational authority, no independent relationship/task/world mutation.

If a beat needs interaction, hand off to Scene Runtime. Do not expand DialogueBeats into another Social Director.

threadID correlates transient presentation/cooldowns; sceneID owns interactive state. Do not persist threadID as a substitute conversation history.

## Semantic-family migration

Consolidate differences caused only by actor type/count, relationship/style, locale or phrase wording when meaning is identical. Split a family when variants differ in meaning, required slots, grounding, outcome, continuation or consequence policy.

Do not preserve obsolete internal IDs with compatibility aliases unless a current external contract proves the need.

## Resolved disposition rule

Generic dialogue decisions consume one resolved numeric disposition/personality projection plus relationship/current state/context. Traits are upstream influences.

Before retaining a direct trait check, document why normalized numeric/capability/knowledge projection cannot express it.

Audit ActorAdapter, ChoicePolicy, GeneratedAffordanceProvider, SemanticCombatReactionProfile, BeatContext and SpeechStyleContext together. Avoid different Brave/Shaken/Aggressive classifiers in each layer.

Do not reroll stored personalities. Do not add per-turn random selection as part of this goal.

## Declarative policy rule

Runtime adapters may detect PZ events, objects, damage, inventory, spatial context and other engine facts. Reusable semantic meaning, style/role selection, branch plans, and beat/conversation policy should be canonical ConvoEngine/CodeBuilder definitions wherever the accepted IR can express them.

Do not grow hard-coded pool IDs, role strings, personality matrices or world-event dialogue catalogs inside Lua adapters.

## Domain-neutral transport rule

Non-combat speech must not need combat-named event IDs/modules merely because CombatTargetCallouts currently owns reusable delivery helpers. D3 should extract/reuse one domain-neutral semantic realization/presentation seam while preserving one SocialFlavorClient queue and existing client presentation/TTS authority.

## Branching and grounding

Every non-atomic interactive family has meaningful continuation. Positive/neutral/negative are stance coverage, not compulsory fake outcomes. Hard predicates fail closed; soft utility ranks eligible choices.

Dialogue cannot fabricate unavailable items, unknown facts, false relationships, unwitnessed events, task/world state or unresolved entities.

## Meaning/memory

Rendered text is presentation. Structured semantic meaning/provenance is context authority. Ordinary dialogue and transient beats remain non-durable by default; consequential events persist only via existing memory/social/evidence authorities. No transcript store.

## Input/presentation parity

First-party InlineChat, full conversation UI, group input, clicked affordances and fuzzy typed input must converge semantically. Nameplate/SocialFlavor/TTS are presentation surfaces, not separate semantics. PBrainZ remains optional and cannot own semantic truth.

## Validation

Focused checks during implementation; full gates at phase close. Final developer acceptance includes relevant Lua suites, Semantic Harness fixtures/workers, deterministic CodeBuilder reconcile, EN/TL parity, Kahlua checks, Scene/thread lifecycle tests, 2/3/4 actor tests, disposition matrices, InlineChat/group/farewell parity, current dialogue/combat/data-mutation benchmarks, static no-new-loop/no-global-scan/no-transcript/no-routine-LLM guards and git diff --check.

## Phase discipline

A chunk is not a phase. When a developer phase gate passes, reconcile ROADMAP/PROGRESS/HANDOFF, stage only phase-owned paths, preserve unrelated changes, commit locally on existing main, do not push, and continue automatically.

## Stop conditions

Stop only for a genuine blocker, unsafe concurrent ownership conflict, material source contradiction requiring user scope choice, or D9 user-owned native acceptance after D0–D8 complete.

## Chronology / world-event / demeanor rule

Treat stable personality, temporary demeanor, world-event state, knowledge and economic projection as separate authorities.

- Base personality remains identity-seeded and trait-shaped.
- Temporary crisis/celebration response belongs in a bounded demeanor/affect overlay with decay/recovery.
- A world event is not a dialogue definition; dialogue/Beats consume its structured fact/context.
- Dialogue never directly mutates markets, faction spawning, needs, mortality or trader stock.
- Hoomans simulation effects go through Needs/Factions/Director/Settlement/etc. owners.
- Dynamic Trading effects go through a bounded adapter into DTCommon MarketEvents/SettlementMarket.
- Do not let DT market-native events recursively create the same Hoomans world event.
- Do not implement starvation as a direct random NPC-kill event when existing needs/health consequences can model the causal path.
- Milestone checks must be coarse/bucketed/reconciled, never a new per-NPC OnTick loop.
- Random/world-event selection must be server-authoritative and deterministic from stable world/scope/time inputs; do not scatter math.random event rolls through NPC/settlement ticks.
- Event definitions own eligibility/weight/duration/severity/cooldown/stacking policy as data where practical.
- Event knowledge must respect WorldKnowledge provenance; NPCs are not omniscient.
