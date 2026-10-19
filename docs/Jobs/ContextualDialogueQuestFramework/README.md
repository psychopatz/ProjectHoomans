# Contextual Dialogue & Quest Framework — Project Hoomans

**Current product direction (2026-10-19):** Make **Semantic Lab the sole user/agent-facing NLP development application**. The existing semantic compiler becomes its **embedded CodeBuilder**; datasets, reusable semantic blocks, visual/code authoring, approved generation and real-Lua simulation are all subparts of ONE workspace. We are consolidating the developer workflow, not changing the current authoritative game runtime.

The repository already records accepted action-flow, quest, context/memory, reviewed dataset and optional-provider developer slices through C6-C at `71162cb4f78cc4cd408a4a145486d5ebadc943c1`. Those are archived in `HISTORY_C0_C6_20261019.md`, and their READY FOR USER LIVE TEST status remains true **for that narrower previous scope**. The new Semantic Studio productization goal S0–S6 is **IN PROGRESS**, beginning with a no-output-change compiler integration.

## What a finished Semantic Lab must enable

Browse a registered dataset/concept/capability → inspect provenance and examples → reuse typed semantic blocks → visually edit a contextual conversation tree OR its synchronized declarative codeblock source → validate actual Core/production flow contract → preview and approve modular Lua/EN+TL/manifest diff → reload real Lua worker → click an actual response and inspect IR, context agenda/memory, selected flow, action authority and generated source. Most operations must no longer depend on manually locating JSON files and editing multiple Lua modules.

**No second NLP parser, no separate compiler app, no duplicate artifact generator, no arbitrary executable node Lua and no full corpus at game runtime.** The UI and CLI must call the same headless authoring/build service. Preserve lightweight offline Lua and optional PBrainZ using authorized facts.

## Developer sequence

**S0A:** embed compiler in Semantic Lab with byte-identical compiled output and compatibility shim; **S0B:** one authoring/artifact service; **S1:** dataset library; **S2:** typed reusable block registry; **S3:** graph+source synchronized composer; **S4:** licensed corpus imports; **S5:** complete one-app generation loop; **S6:** UX/performance and parity acceptance.

Only `PROGRESS.md` determines ONE current Next Chunk. Full target architecture and migration gates: `SEMANTIC_STUDIO_CONSOLIDATION.md`; phase ordering: `ROADMAP.md`.

## Read order for /goal

Root `AGENTS.md` → job `AGENT_RUNBOOK.md`, `AUDIT.md`, `ARCHITECTURE.md`, `SEMANTIC_STUDIO_CONSOLIDATION.md`, `AUTOMATIC_FLOW_GENERATION.md`, `CAPABILITY_ACTION_BINDINGS.md`, `CONDITION_CONTEXT.md`, `QUEST_CONTRACT.md`, `CONVERSATIONAL_INTELLIGENCE.md`, `DATASET_CONVERSATION_PIPELINE.md`, `PROCEDURAL_NLP_COMPILER.md`, `AUTHORING_WORKBENCH.md`, `ROADMAP.md`, `HARNESS_ACCEPTANCE.md`, `CONVERSATION_ACCEPTANCE.md`, **`PROGRESS.md` LAST**. Historical ledgers for evidence only: `HISTORY_20261018.md` and `HISTORY_C0_C6_20261019.md`.

**No production code changed by this documentation commit.** Codex must inspect its own checkout; remote planning baseline `71162cb4f78cc4cd408a4a145486d5ebadc943c1` is not proof of local status. Only the user performs native Project Zomboid SP/MP acceptance and any Steam Workshop install/publish/release. Missing Codex CLI CUA `apps=[]` is not an implementation blocker; use available X11/Tk and production worker instead.
