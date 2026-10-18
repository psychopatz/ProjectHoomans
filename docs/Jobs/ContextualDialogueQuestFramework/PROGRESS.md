# Contextual Dialogue & Quest Framework — CURRENT progress

**Updated:** 2026-10-18 (goal scope expansion, documentation-only).
**Remote implementation inspected:** `docs/contextual-dialogue-quest-framework-20261018` @ `f0b6e41b90b025d64ccd7578e526d80876de4969`; PR #4 remains open/unmerged at inspection. This does **not** assert a clean local Codex worktree, latest installed mod parity or fresh test execution.
**Current goal status:** **IN PROGRESS — G0 Automatic Production Flow Generation**.
**ONE Next Chunk:** **G0A — Generic registered simple-command flow template: auto-discover eligible capabilities, generate and execute at least FOLLOW and STAY through real production flows with result transitions.**

## Accepted historic foundation (do not redo)

Older job ledger recorded accepted weather/context gate, real Lua worker FOLLOW/STAY/WAIT_AT/GIFT dispatch (mocked authority), reviewed single-FOLLOW compiler+EN/TL modular generation, source preview, source approval/restart and X11 mouse-click testing. These prove useful infrastructure; they do **NOT** prove generic automatic flow population. Full prior progress/evidence copied unchanged to `HISTORY_20261018.md` for traceability.

## Actual source limitations behind new scope

1. `PNC_SemanticDialogueFlowCatalog.lua` registers four manual conversation flows and one generated FOLLOW terminal response flow; no full registered GIFT/STAY/WAIT_AT action lifecycle flows.
2. `PNC_SemanticGeneratedDefinitions_Flows_01.lua` FOLLOW node is only `accepted` terminal response; no typed binding/result edge. Policy flow response eligibility suppresses executable action result's flowPool.
3. `tools/semantic_compiler/semantic_definitions.json` is one handwritten FOLLOW source; compiler restricts REQUEST/REQUEST and action-less node schema, so multi-stage GIFT cannot be authored/generated.
4. `flow_editor.py` Add action creates recognition trigger only, not production flow; Generate source selects an existing authored file, not "generate all from registry".
5. `ROADMAP.md` previously stale (showed 2A next when already recorded done). New ROADMAP now reconciles source/evidence with expanded requirement.
6. Contextual memory/personality and authoritative Quest workflows were planned, not accepted. Prior full-suite contextual social regression failures remain known from historical ledger; latest state must be retested, not presumed fixed.

**Previous status `READY FOR USER LIVE TEST` applied to a smaller pilot. It is not acceptance of the clarified automatic-generation requirement.** No new generator implementation or runtime verification is claimed by this document.

## EXACT Next Chunk G0A

1. Inspect **actual local** repo/Core checkout, branch, HEAD, status, all concurrent work and prior latest modules. Reconcile current files vs remote audit before edits. Root AGENTS.md and job docs are authoritative.
2. Audit existing registry/descriptors and public command/gift/task adapters for the minimum safe typed metadata, plus FlowRegistry/Kernel/policy/response arbitration and compiler output. Define ONE versioned action-capable node/result contract with *exactly one* approved existing dispatch path; Preview remains pure. Do not invent Lua function names or bypass authority.
3. Implement a **metadata-driven `simple_command` template** that enumerates the registered compatible simple companion-command capabilities. Automatically generate the canonical flow definitions, module shards/manifests and EN/TL response mapping in normal PZ paths. At minimum prove independently generated FOLLOW and STAY from one template, not a manual two-command list. Report every discovered capability as generated/eligible/metadata incomplete/recognition only/legacy/unsupported with reason.
4. Integrate/observe actual production Lua FlowRegistry/Kernel and existing DialogueInput/CommandAdapter result route: selected generated flow and permission branch + queued/denied/failure branch + real NPC text. Avoid duplicate command caused by both legacy policy and new action node, and do not override authoritative admission results with success text.
5. Run **fresh Lua worker** with authorized/unauthorized FOLLOW and STAY, negation, question, ambiguous target, repeated Preview, duplicate/replayed result, EN/TL, identity/weather/wellbeing regressions; inspect request/correlation and effects. Deterministic regeneration, Lua/manifest syntax, Kahlua checks, no flow count boot failure. Show coverage as actual Semantic Lab output or minimal UI/worker integration for this first slice.
6. Update only this job `PROGRESS.md` with code SHA, actual flow IDs and IR→node→binding→mock authority→response traces, exact test results and **ONE next chunk** (G0B parameterized task generator on success; otherwise G0A remains open with concrete defect). Commit coherent changes only to authorized inspected branch and preserve unrelated files.

## Exit / stop conditions

Not accepted if only adds a generated FOLLOW terminal pool, handcrafted STAY flow, discovery table, flow screenshot, or Python-only JSON test. No CUA dependency: real X11 GUI available in recorded older slice and Lua worker suffices for source acceptance; CLI native CUA absence not a blocker. Native Project Zomboid SP/MP and Steam Workshop publishing remain solely user-owned and never part of source-development blocking.

If all supported families, coverage, code/graph source editing, context/quest integrations and acceptance gates are later complete, mark developer **READY FOR USER LIVE TEST** and stop. Until then, don't claim the whole goal finished.
