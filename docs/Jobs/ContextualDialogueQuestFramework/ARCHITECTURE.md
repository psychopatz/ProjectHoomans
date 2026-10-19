# Semantic NLP architecture — generated production flows own interaction policy

## Target runtime

Natural language → **existing PsychopatzCore parser + candidate IR** → **Project Hoomans production flow registry/kernel (generated or legacy)** → typed context/permission/slot checks → **named, registered gameplay capability** routed exactly once via existing approved Input Actions / command/task/gift adapter → real server/domain admission and eventual completion result → explicit *flow result* transition → matching localized NPC response and bounded memory/quest consequences.

The **flow is the declarative owner of interaction sequencing, gates and outcome-to-response choices**. The existing gameplay owners retain the effect implementation, target authority, MP admission, inventory mutation and task scheduling. A response-only flow or merely attaching an action trigger must never be reported as a complete executable interaction.

## Canonical authoring/generation pipeline

Live published production metadata (capabilities, existing parser patterns, facts/gates, response catalogs, workflow descriptors, existing/legacy flows) → template classifier + support inventory → typed versioned editable definition → validator + collision/ownership checks → deterministic compiler → module shards + explicitly required manifests + EN/TL → fresh production worker → trace → graph/code edit in Semantic Lab → regenerate.

Do not create a second dynamic NLP runtime, generic LUA scripting VM or arbitrary source `eval`. Python handles *offline authoring/compilation*; Lua registry handles runtime semantics. Do not use raw JSON artifacts as the only deliverable. Generated node kinds must be versioned in Registry and observable in worker trace.

## Runtime ownership and dispatch invariant

- **Core** generic parse/IR, Hoomans policy/flow, Conversation Blocks pure gate evaluation.
- **Capability registry/owners** expose IDs, semantic frame descriptors, typed arguments, permissions, known outcome classes, execution route, workflow category, applicable contexts; no serializing Lua callbacks.
- **Production dispatcher** is the *only* owner of action invocation. FlowKernel Preview never invokes; committed admission stays in existing ActionInput→adapter route or a narrowly integrated orchestration seam; do NOT dispatch both legacy policy and flow callback.
- **Server/domain** validates and may return rejected / admitted-queued / applied / failed / eventually-completed. Never acknowledge successful completion solely because parsing/flow matching succeeded.
- **NPC context, relationship, personality, knowledge, quest** remain domain-owned, consumed as provider facts; unknown fails closed on sensitive branches. Event bus gives observations, not automatic execution or quest award.
- **PBrainZ** optional output realization, never permission or quest authority.

## Generated definition guarantees

Namespaced stable IDs; template version + capability contract version; no per-command hardcoded generator switches beyond reusable workflow categories; deterministic ordering; isolated edit metadata; preserve existing hand-authored custom flows and their IDs; generated file path/manifest accuracy; diff and approval; incremental regeneration from source-of-truth not generated Lua. A capability without requisite metadata produces `UNSUPPORTED` with field-level reason, not guessed behavior. Indexed/bounded runtime (existing flow-node limits evaluated before bulk expansion); measured no per-tick scans; EN/TL graceful fallback.

### Rule for legacy behavior

Existing FOLLOW/STAY/WAIT_AT/GIFT routes cannot disappear when adding new flows. Introduce routing precedence/compatibility explicitly. The Flow Registry must not swallow requests or duplicate dispatch. For an action-capable generated flow, the outcome response should follow actual adapter result, not a prior terminal pool. If registry selection fails, preserve current safe legacy route and explain fallback in traces.

## Non-goals

Not automatically inventing arbitrary human meanings, quest implementation, translations or custom gameplay services. Generation is only for reviewed/registered semantics and validated templates; unsupported metadata is visible. Native game testing and Steam Workshop uploads are user-owned.

Detailed operational contracts: `AUTOMATIC_FLOW_GENERATION.md`, `CAPABILITY_ACTION_BINDINGS.md`, `PROCEDURAL_NLP_COMPILER.md`, `AUTHORING_WORKBENCH.md`.


## Contextual conversational intelligence extension (approved 2026-10-19; planned)

This new major phase extends the existing semantic parser/flow action architecture WITHOUT changing authoritative owners. See `CONVERSATIONAL_INTELLIGENCE.md` for exact context frame, dialogue-act planner, topic stack, bounded memory references and unknown-fact semantics. Parser candidates are interpreted with scoped discourse context before response planning; unsupported interpretations clarify rather than assume actions. Durable memories/quest commitments are linked to existing Knowledge/Cognition/Quest owners, not stored in a new ModData chat log.

The same typed ContextState + DialogueActPlan supports offline Lua and optional PBrainZ realization. PBrainZ may phrase a grounded authorized plan but cannot independently create facts or effects. The build-time dataset ingest and `tools/semantic_compiler` integration are specified in `DATASET_CONVERSATION_PIPELINE.md`; no corpus download or embeddings at game runtime.

Existing generated companion/task/gift/quest flows remain intact; conversational agenda helps interpret requests and follow-ups but does not introduce a second dispatcher. Re-run the social-action final response/INSULT regression and recorded four THREAT social-reaction failures as acceptance gates, not by counting successful IR recognition alone.


## Semantic Studio tool ownership update (2026-10-19; S phase planned)

Developer-facing tooling now has ONE ownership root: `tools/semantic_harness/`. The existing compiler package is to be embedded as `semantic_harness/codebuilder/`, sharing a single canonical authoring spec, one build/write/path authority and one service used by GUI and headless CLI. `tools/semantic_compiler/` may temporarily hold compatibility wrappers for verified callers but must not maintain another writer/definition source/compiler implementation. Dataset library and reusable block composition are internal Semantic Lab subsystems, not standalone applications.

**This changes developer-tool organization, NOT production Lua semantic/gameplay authority.** Compilation produces deterministic modular Lua/EN-TL/manifest outputs; Core remains the parser, Hoomans remains flow/policy/context, and gameplay domains remain side-effect owners. Schema validation/collision checks happen at authoring time; arbitrary typed blocks must not execute untrusted Lua. Details and staged acceptance in `SEMANTIC_STUDIO_CONSOLIDATION.md`. Previous C0–C6 accepted evidence archived in `HISTORY_C0_C6_20261019.md`.

## Current C7 conversational competence boundary (2026-10-19)

`CONVERSATIONAL_COMPETENCE_C7.md` defines the active extension. The existing FlowKernel generated command/task/quest result graph represents authorization/action sequencing; it is **not** a complete diagram of player sentence → Core IR → target/attribute → NPC fact → dialogue plan → NPC next turn. The latter should be separately shown as a conversation view, backed by real worker trace and one canonical source, not a parallel interpreter.

Recognizing meaning and knowing a fact are distinct outcomes. A bitten-status QUESTION may be correctly parsed while medical evidence is unknown; respond with truthful uncertainty, not unsupported denial or generic inability to understand. Generalize by typed question/attribute, legitimate NPC fact provider, context, relationship and response-plan selections; don't add brittle literal-per-sentence rules or invent an authority outside Core/Hoomans. Quest/gift/companion authoritative side effects are unchanged. Optional PBrainZ uses same grounded state.
