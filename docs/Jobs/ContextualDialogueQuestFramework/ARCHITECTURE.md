# Architecture — semantic authoring, production authority and modular compilation

## Desired pipeline

Semantic Lab user/agent editing (Language + Dialogue + Conditions + Action references + Responses)
→ one validated canonical **data-only semantic definition**
→ deterministic offline compiler (existing `tools/semantic_compiler` extended, not copied)
→ modular Build 42 Lua registrations + response pools/EN/TL shards + explicit manifests
→ production PsychopatzCore parser/IR
→ Project Hoomans policy, context/flow kernel and shared Conversation Blocks gates
→ existing client action or gift/task/command adapter
→ server/domain authority result
→ grounded NPC response/pending follow-up
→ Semantic Lab trace of real worker behavior.

**No Python runtime reimplementation of the parser, Lua compiler side effects during preview, direct node-level calls to an arbitrary function, or fake game authority.**

## Domain owners (non-negotiable)

| Owner | Owns | What the workbench may do |
| --- | --- | --- |
| PsychopatzCore | Generic NLP normalize, concepts, grammar, IR, router | Register compiled reviewed terms/patterns through public API; no Hoomans-specific quest state in Core |
| Hoomans Semantics/Flow Registry/Kernel | Frames, bounded transitions, dialogue context pointers, response plan | Consume compiled definitions and typed **capability references**, not perform gameplay |
| Hoomans Conversation Blocks | Existing gate rules, compositional PASS/FAIL/UNKNOWN, locked presentation | Reuse pure evaluator; client previews cannot authorize actions |
| Engine facts/events and NPC domains | Observation provenance, time/weather, health/needs, personality, relationship, knowledge | Read bounded snapshots; never treat all NPCs as omniscient |
| Registered command, gift, inventory and task adapters | Prepare and route actual requests, capture results | Bind a capability ID/type to its owner; no duplicate transport |
| Server/domain service | Validate conversation/ownership/lease, execute, persist/emit authoritative outcome | Revalidate at command time; no mutation through editor/preview |
| Compiler | Deterministic derivation of validated data to modular artifacts | Fail on collisions/incompatible contracts; produce inspectable diffs |
| Semantic Lab | UX, typed editors, worker lifecycle, preview/committed replay, generator orchestration | Never become another NLP/policy authority |
| Quest domain (future) | Bounded authoritative states, objectives and idempotent rewards | Expose status/commands as typed bindings after owned domain exists |
| PBrainZ (optional) | Verbalization of authorized plans, optional contextual retrieval | Cannot grant quests, fabricate facts or bypass permission |

## Strict separation of meaning and effects

- **Utterance frame:** intent/speechAct/action/subject/entity slots plus confidence/negation/provenance, all validated by existing Core.
- **Flow state:** eligible nodes, pending question, interruptions, conditions, response pool and references. Meaning alone cannot mutate inventory/orders/quests.
- **Action binding:** named capability with typed required parameters and a service owner; optional flow/branch lifecycle mapping. The existing action dispatch remains the sole effect path (or its narrowly extended registered adapter).
- **Effect report:** request issued, authorization, server admission, completion/failure and correlated actual state. "Accepted" must be disambiguated (input accepted is not server order completed).
- **Response:** must be selected from actual route/authority outcome. No success claim on rejected, pending or unexecuted action.

For action-bearing requests ensure exact speaker+addressee+target and action slot resolution; fuzzy/negated/question phrasing must not execute. Preview and validation must be effect-free. Maintain group target semantics and server permission checks.

## Compilation and modularity

Source-of-truth is **versioned declarative definitions** in a reviewed authoring directory outside the PZ watched runtime path. Build artifacts are **owned Lua modules** under existing Build 42.20/common conventions, rather than monolithic if/elseif edits. Use existing semantic catalog and flow registry loading contracts; generate stable explicitly required module indexes and translation keys. Never run untrusted Lua pasted into a draft. Unsupported handwritten source stays untouched; unsupported round-trip must fail with reason.

Generated source is never committed before a precise review of file paths/diff and actual load/restart semantic tests. A compiled definition is considered deployed only after fresh worker loads its module and the predicted real NPC response/action/result route is observed.

## Context and quests

Retain existing context-state/knowledge/social/relationship ownership; store bounded discourse pointers and committed promises, not a full NPC transcript. Facts carry known/unknown, source, time and identity. Reuse current weather/fact gate code (recorded PASS/FAIL/UNKNOWN). Event bus is observation only; subscription does not imply action or quest progress. Quest instances and reward idempotency will be defined by a separate authority service once action binding/compiler are proven.

## Performance, limits and compatibility

Compile offline; minimal runtime registration and indexed evaluation. Respect current finite flow limits (registry MAX_NODES=32, default MAX_FLOWS=32 as audited) or explicitly version/benchmark justified changes. Avoid per-frame scans or dynamic heavyweight parsing. Preserve old flows, Core IR schema, Build 42.20 Kahlua, EN/TL fallback, server action permissions, SP/MP scope and PBrainZ-off determinism. Deterministic regeneration must produce byte-stable output when inputs unchanged. Measure parser conflicts and end-to-end latency; do not equate a count of generated patterns with accuracy.

Detailed contracts: `CAPABILITY_ACTION_BINDINGS.md`, `PROCEDURAL_NLP_COMPILER.md`, `CONDITION_CONTEXT.md`, `QUEST_CONTRACT.md`.
