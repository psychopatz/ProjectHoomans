# Condition gates, engine hooks and dialogue context — design contract

## Reuse-before-rewrite audit

Two existing interfaces must be reconciled before implementing new rule types:

A. **Conversation Blocks** (docs/Systems/ConversationBlocks.md): typed conditions including pnc:skill, pnc:trait, pnc:personality, pnc:relationship, pnc:relationship_state, pnc:audience, pnc:time, pnc:history; all/any/not composition; hidden/disabled locked presentation; handler registration; server authority for effects.

B. **Semantic flows** (PNC_SemanticDialogueFlowRegistry.lua and FlowKernel.lua): version-1 data-only trigger/accept frames, response pool, slots, next/onMatch/onRefuse/onUnrelated, bounded sessions, preview and commit. V1 NormalizeNode does NOT accept arbitrary gate fields. Any new node condition must have an explicit versioned validation/normalization and migration strategy.

Do not fork the gate language unnecessarily. First audit whether Conversation Blocks' pure evaluator and registered typed handlers can be consumed through a small, side-effect-free public adapter in semantic flow preview/commit. If not, extract the smallest genuinely shared pure condition primitive while keeping current IDs/contracts stable. The authoritative engine/source of truth remains each owning domain.

## Typed fact providers (planned public contract, not current API)

- world.time: in-game hour, game day, time band, season when exposed reliably.
- world.weather: raining, precipitation severity, fog; whether NPC/player actually observes it.
- npc.self: injury/needs/activity/threat/mood derived from existing NPC systems.
- social: directed trust/familiarity/relationship state, traits, personality.
- knowledge: observed facts and verified shared history, with source and age.
- quest: definition/instance status, objective completion, availability and reward claim, from Quest queries.
- optional addon facts: named and registered capability-gated providers, not arbitrary filesystem/eval.

Fact shape must distinguish {known, value, provenance, sampledAtOrRevision} to avoid treating unknown as clean/false. Server authority reads from server APIs during action commit; client/world snapshot can optimize presentation/preview but cannot authorize rewards, inventory moves or quest progress.

## Example behavior matrix

| Input | Additional facts | Expected branch behavior |
| --- | --- | --- |
| "Are you okay?" | npc.healthState=injured, known | Genuine injury disclosure, not fabricated cause |
| "What happened?" | prior accepted injury disclosure | Resolve "what" to current topic; if no verified incident memory, say unknown |
| "How's the weather?" | outdoor NPC, rain observed | Weather-appropriate answer |
| "How's the weather?" | indoor/offscreen NPC, unknown observation | Qualify ignorance rather than claim direct observation |
| "Do you need help?" | injury or need, quest AVAILABLE | Allowed help/offer branch; does not autostart quest |
| "I'll bring some." | pending bandage offer; matching reference | Resolve referent; request explicit confirmation as needed |
| "Did I bring the bandages?" | quest ACTIVE, no authenticated delivery event | Do not report completion |
| "Let's return to my name" | identity flow suspended | Resume only matching participant's identity flow |
| "You owe me the reward" | quest REWARDED | Refuse duplicate reward with correct status |

## Context reference resolution

Reuses current semanticDialogueState's currentTopic/previousTopic/pendingQuestion/pendingRequest and flow active/suspended stacks. Introduce only a bounded discourse reference table when a verified gap exists: referent kind/id, utterance index, speaker, addressee, source memory/quest ID, confidence, expiry. Entity/reference resolution must check topic, grammatical compatibility, authority, available memory and participant identity; tie/unknown -> clarify, not guessed action.

A request may be interpreted when PBrainZ is off. The semantic plan is the single bridge to optional LLM realization; never send a giant NPC history or source-owned private state wholesale to the provider.

## Security, rollback and testing

Pure preview cannot write context/memory/quest/inventory. A successful turn may record a bounded conversation pointer; any meaningful gameplay transition requires an accepted authoritative command. Handle world changes between preview and commit by re-evaluating. Observe gate status and reason in the Semantic Lab Turn facts and Raw record.

Proof requires at least one **real-Lua weather or time branch** that changes when a harness scenario fact changes, plus the same branch refusing or clarifying when the value is unknown. Test established identity/wellbeing flow interleaving and the previously reported "im fine thanks" false identity-capture regression. Record selected reply, transition, gate and side effects, not just green fixture status.
