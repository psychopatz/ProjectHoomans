# Contextual Dialogue & Quest Framework — Project Hoomans

**New mandatory product objective (2026-10-18): Semantic Lab is the procedural author, generator, editor and production-Lua test harness for ALL supported Project Hoomans semantic interactions.** This includes conversation states, world/personality/memory/quest context and capability-bound action workflows. It is NOT sufficient to discover FOLLOW/GIFT actions, draw nodes for them, or generate one hardcoded example while their actual production lifecycle lives outside the flow.

## Core workflow

**Discover** production semantic patterns, registered capabilities, condition providers, response catalogs and existing flows → **classify** each by reusable workflow shape → **plan generation** (explicit coverage/unsupported reasons) → **generate a canonical editable semantic specification** → **compile reviewed specs into modular production Lua, EN/TL and manifests** → **load a fresh production worker** → **run scenario/negative/permission tests** → **inspect and edit in the existing Semantic Lab UI** → **regenerate only affected assets**.

Every supported registered capability should either appear as an executable production flow with explicit condition/dispatch/result semantics, or be reported as **unsupported/missing metadata/recognition-only/legacy** with exact reason and owner. There must be NO silent gaps and NO invented handlers. Handwritten domain gameplay implementations remain modular and authoritative; generated flows merely orchestrate through published typed bindings.

Use generic capability templates, NOT per-action if/elseif branches in the generator. At minimum support: simple companion commands; parameterized tasks with target/slot resolution; multi-stage gift/inventory consent workflows; response-only contextual and social dialogue. Later add personality/knowledge/quest-gated flows through the same engine. End goal is breadth of generated *supported* semantics, not an unsupported claim of infinite natural language understanding.

## State and boundary

- **Remote source audited:** branch `docs/contextual-dialogue-quest-framework-20261018` at `f0b6e41b90b025d64ccd7578e526d80876de4969`. Previous phases 2A/2B/2C/3A/4A/4B/4C have recorded worker/X11 acceptance in the historical progress ledger; they are valid *narrow slice* evidence, **not acceptance of automatic generation of full production action flows**.
- **Current status:** new mandatory Generation phase OPEN. See `PROGRESS.md` for the ONE Next Chunk. Prior `READY FOR USER LIVE TEST` only referred to earlier limited scope and is superseded for this expanded goal.
- No new production code or test run is established by this documentation change.
- Actual Project Zomboid SP/MP testing and Steam Workshop publication remain **user-owned**. Codex CLI does NOT need CUA to proceed: use existing X11/Tk and worker tests, mark external unavailable UI only as pending.

## Read order for Codex

1. Root `AGENTS.md`
2. This job: `AGENT_RUNBOOK.md`, `AUDIT.md`, `ARCHITECTURE.md`
3. **`AUTOMATIC_FLOW_GENERATION.md`** (current phase's canonical contract)
4. `CAPABILITY_ACTION_BINDINGS.md`, `PROCEDURAL_NLP_COMPILER.md`, `AUTHORING_WORKBENCH.md`
5. `CONDITION_CONTEXT.md`, `QUEST_CONTRACT.md`
6. `ROADMAP.md`, `HARNESS_ACCEPTANCE.md`
7. **`PROGRESS.md` LAST** (current phase / one Next Chunk); `GOAL_PROMPT.md` bootstrap.
8. `HISTORY_20261018.md` only when needing detailed older test/commit evidence.

Reference: `tools/semantic_compiler/`, `tools/semantic_harness/`, Hoomans `PNC_SemanticCapabilityCatalog`, `PNC_SemanticDialogueFlowRegistry/Kernel/Catalog`, `PNC_SemanticDialogueInput_Actions`, command/task/gift adapters, and PsychopatzCore parser contracts.

## Completion definition

"Generate all" means: inventory all registrable semantic capabilities; generate every template-compatible one without manual per-command files; report unsupported ones explicitly; compile to correct tracked modular PZ assets; execute production-worker positive and denied/ambiguous scenarios for each template family; verify no duplicate dispatch/false acknowledgement; confirm restart/rebuild idempotency, code/graph editing and coverage UI. Context/memory/personality/quest extensions have their own gate and remain unaccepted until proven. Do not stop at static catalog counts, JSON fixtures, a screenshot or CUA availability.
