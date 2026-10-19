# Contextual Dialogue & Quest Framework — Project Hoomans

**ACTIVE goal: Semantic Studio Recovery (2026-10-19).** The earlier S0–S6 compiler, worker, dataset adapter and GUI-pane milestones are recorded technical achievements, but do not yet satisfy the user's original product goal: create and debug new modular NPC conversations inside Semantic Lab, inspect all semantic paths including INSULT, and verify actual final NPC responses. The expanded goal is IN PROGRESS, not READY FOR USER LIVE TEST.

**Audited remote baseline:** 36f0beb2dc8a280094307700d601adc60c93d07b on branch docs/contextual-dialogue-quest-framework-20261018, PR #4 open at inspection. No local agent checkout, GUI test or native game runtime has been inspected during this documentation-only transition. The previous S0–S6 PROGRESS ledger is preserved in HISTORY_S0_S6_20261019.md.

The user journey must be: search an interaction or lexical source -> inspect real parser/policy/flow/action/response ownership -> instantiate and connect reusable semantic blocks -> edit one canonical composition in graph or supported code view -> validate -> preview the ACTUAL changed Lua/EN/TL/manifest diff -> approve -> generate -> restart REAL Lua worker -> talk to NPC and inspect final text, context, errors and side effects. CodeBuilder remains a subsystem of the existing Semantic Lab, not a separate engine or app.

**Current authoritative design:** SEMANTIC_STUDIO_RECOVERY.md. Ordered phases: ROADMAP.md. **Exactly one Next Chunk:** PROGRESS.md (read LAST). Earlier accepted infrastructure is not to be reimplemented.

Read root AGENTS.md then job AGENT_RUNBOOK.md, AUDIT.md, ARCHITECTURE.md, SEMANTIC_STUDIO_RECOVERY.md, SEMANTIC_STUDIO_CONSOLIDATION.md, AUTOMATIC_FLOW_GENERATION.md, CAPABILITY_ACTION_BINDINGS.md, CONVERSATIONAL_INTELLIGENCE.md, DATASET_CONVERSATION_PIPELINE.md, PROCEDURAL_NLP_COMPILER.md, AUTHORING_WORKBENCH.md, ROADMAP.md, HARNESS_ACCEPTANCE.md, CONVERSATION_ACCEPTANCE.md, PROGRESS.md LAST. Historical records only for evidence.

The user alone handles native Project Zomboid SP/MP testing, Steam Workshop install/publish/republish and live external PBrainZ. Codex CLI CUA absence is not a developer blocker; use actual production Lua worker and X11/Tk automation where appropriate.
