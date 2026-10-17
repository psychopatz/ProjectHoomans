# Stable target architecture and ownership rules

## End-to-end shape

Player/NPC utterance -> existing Core parser + candidate IR -> existing Project Hoomans semantic policy and flow kernel -> context references + pure gate eligibility + dialogue act/response plan -> existing translated response pipeline -> optional PBrainZ verbalization. If a validated player choice requests gameplay: server command -> authoritative domain check/transaction -> result event -> dialogue follow-up. No client-side suggestion is an authoritative mutation.

## Ownership table

| Owner | Canonical responsibility | Consumer relationship |
| --- | --- | --- |
| PsychopatzCore | Generic deterministic NLU normalization, patterns, candidate parsing, IR and reusable router mechanisms | Hoomans consumes published generic contracts; do not put quests/personality in Core |
| Hoomans Semantics / Flow Kernel | Select flow based on IR, bounded active/suspended state, references, dialogue policy, response plan | Query read-only context/gates; never directly own item or quest truth |
| Conversation Blocks | Existing authorable block/choice gates and effects; service validation and authoritative command bridge | Reuse existing condition contracts via a narrow adapter; avoid a duplicate evaluator |
| Context Providers | Snapshot actual world/time/weather/perceived facts, per-actor NPC state and relationship/knowledge | Bounded, read-only, provenance-marked; unknown is not false or true |
| Personality / Relationships | Existing stable profiles and directed social state | Influence eligibility/willingness/wording; no synthetic personality copies |
| Knowledge / Memory | What an NPC actually knows or remembers, with provenance and retention | Semantics stores lightweight discourse pointers; query existing owners for facts |
| Quest domain (new if audit confirms absence) | Quest definitions, instance scope, status, objectives, events, deadlines, persistence, reward idempotency | Semantic dialogue may ask; only authoritative quest commands commit |
| Inventory, Tasks, Facilities, Needs, World | Own gameplay state and effects | Quest objectives consume authenticated events/queries, not UI claims |
| Semantic Lab | Test/author drafts, graph/code view, production Lua worker, diagnostics | Does not become an alternate parser, authority or quest executor |
| PBrainZ | Optional natural language realization/retrieval client | Never decides quest reward/state, invents authoritative memories or skips gates |

## Semantic turn contract

A turn is scoped by world/save, NPC ID, character/player UUID, speaker/addressee ID and conversation/session identity where relevant. Input contains bounded utterance, optional context snapshot, known references and revision identities. Output contains selected IR/candidate, eligible flow, gate decisions/reasons, dialogue acts or response plan, rendered EN/TL result, optional safe action request and trace. Every resulting mutation has a separately correlated authoritative result. Unknown context never fabricates NPC health, weather knowledge, injury origin, prior promise or quest completion.

## Context and memory rules

- Immediate: current location, known world/weather/time, NPC needs/health/activity and nearby perceived entities via existing providers. For NPC dialogue, do not treat a player-local weather observation as omniscient knowledge; use NPC observation or an explicitly marked shared/global fact. When offscreen or unloaded, represent UNKNOWN.
- Conversation: last utterance references, referents such as "it"/"some"/"there", active topic, pending question, offered quest, suspended stack and expiry. Bounded per conversation, no duplicated full chat transcript or per-tick polling.
- Durable: only meaningful accepted commitments, quest ownership and significant memory/evidence go to their authoritative domains. A player's "I will help" is a candidate claim; create a durable commitment only after the appropriate acknowledgement/authoritative state transition.
- Retrieval: query relevant durable evidence by speaker/NPC, entity, topic and state. Include provenance (who observed/said/confirmed, when, certainty), revisions and last-known vs current distinction. Do not grant all participants the same memory merely because they were nearby.
- Persona: existing personality and relationship snapshots alter speech tone, willingness and optional choice weighting; they must not contradict health/quest facts or turn a harmless question into an unrequested action.

## Gate decision contract

Condition evaluation is a pure, bounded lookup over typed read-only facts: PASS, FAIL or UNKNOWN, with machine reason, source/owner and revision. Composite all/any/not must define tri-state semantics. Unknown must not unlock a sensitive or action-bearing branch. Availability can map FAIL/UNKNOWN to hidden/disabled/clarification. Never run arbitrary authored Lua predicate source at evaluation time; use approved named handlers or declarative structured conditions. An action that followed a client PASS must be revalidated on the server before mutation. Gate checks must be in both natural-language flow admission and manual Conversation Blocks choices.

## Quest authority

Definitions are immutable data; state is server-owned per declared scope (player-character+NPC, player-character, community/faction, world). Instance transitions must validate current revision, progression prerequisites and objective evidence. Event ingestion and terminal reward/penalty application use dedupe/idempotency keys. Save only compact state, never duplicate inventory/crop/health truth. Objective progress is driven by real authoritative events (e.g. verified transfer to a named target), not typed player claims.

## Performance and compatibility

Event/turn driven. No every-tick parsing of all NPC conversations or full quest catalog. Compile/canonicalize definitions at load; index triggers and active objectives; evaluate only candidates with matching intents and relevant events. Bound flow stack, memory references, diagnostics, callback budget and persistence size; measure idle per-NPC CPU, event cost and memory growth before claiming scalable. Preserve existing public APIs, Build 42.20 layout, EN/TL keys, PBrainZ-off path and existing server-authoritative networking. No speculative whole-module refactor.
