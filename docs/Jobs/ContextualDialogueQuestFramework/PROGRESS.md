# Contextual Dialogue & Quest Framework — current state

**Updated:** 2026-10-18
**Baseline inspected:** remote ProjectHoomans main a3eb2e4db553f9c03b7f66a6ff6717878e1668e0
**Phase:** 0 — Gate bridge vertical slice
**Status:** PLANNED; no implementation tests run by this planning work.
**Next Chunk:** 0A — Connect ONE semantic-flow world condition to the existing typed gate contract, and prove it through real Lua.

## Accepted foundation from remote-source inspection

- Semantic Lab includes a Tk graph editor, production-worker Validate/Register, and actual-Lua flow regression tests; it is not yet complete drag/drop/source-code authoring.
- Production flow registry validates bounded declarative frames/nodes and has a preview/commit kernel with limited active/suspended sessions.
- World context and situation providers expose time, rain, fog, indoors and NPC/social facts.
- Conversation Blocks already own a mature declarative condition system and server-side effect boundary.
- Prior SemanticDialogueDecoupling job says READY FOR USER LIVE TEST; user native game tests not conflated with this new workstream.

## Unaccepted gaps

- No verified shared typed condition evaluator between Blocks and semantic flows; semantic Registry V1 currently rejects unknown node fields.
- No real-Lua contextual branch demonstration with PASS/FAIL/UNKNOWN gate diagnostics in this new job.
- Graph CRUD/drag/link and synchronized code editor/source persistence missing.
- Cross-session contextual memory/commitments and standalone authoritative Quest domain not accepted.
- No new job-specific harness GUI click-through, performance, hosted CI, or native PZ tests.

## EXACT Next Chunk 0A

1. Inspect the current local Hoomans and Core checkout/branch/HEAD and existing Blocks condition implementation, semantic FlowRegistry/Kernel, world context projection, worker's scenario/observation routes and relevant tests. Do not assume the planning remote baseline is identical to local checkout.
2. Choose an existing pure condition pathway to reuse for one semantic flow world fact (prefer rain or time). If no reusable public contract exists, introduce only the narrow read-only adapter/typed validator necessary; do not duplicate the full Blocks engine or reimplement NLU.
3. Add a minimal context-gated production Lua flow behavior: when input intent is eligible and fact is known, follow the appropriate branch; when fact is false/unknown, choose deterministic different/clarifying response. Do not overwrite existing identity/wellbeing behavior. Preserve preview purity and recheck gameplay action conditions on server if any (prefer an entirely response-only pilot).
4. Expose selected gate result/reason and from/to node + rendered text in the **existing** Semantic Lab worker observation and visual inspector, rather than only returning a JSON validation success.
5. Through real Lua worker, run one multi-turn replay with rain=true, rain=false and unknown fact; show actual selected response and absence of tool/transport/LLM calls. Run focused identity/wellbeing/flow tests and doctor/smoke where available; record exact commands/results, GUI inspection if available, and any failures.
6. Update PROGRESS with accepted/unaccepted result and select precisely one next chunk in Phase 1 (node CRUD), or keep 0A open with a concrete defect. Commit coherent source/test/docs only per actual Git safety and authorization.

## Exit checks

- Existing parser/candidate IR unchanged; at least one safe semantic flow truly gates on authoritative-sourced/read-only world fact in production Lua.
- Clear testable behavioral contrast for fact TRUE/FALSE/UNKNOWN; no guessed fact, no misrouted identity/relationship mutation.
- Real worker observation contains gate selection reason and actual rendered NPC reply, not just a graph/JSON record.
- No new per-tick scan, arbitrary user code execution or independent Python semantic evaluator.
- Developer runtime not falsely presented as live game acceptance.

## Git/publication note

Planning docs are being prepared on a dedicated documentation branch for review. No local worktree condition is inferred; Codex must inspect its actual checkout and know which branch contains these docs. Workshop upload and native game testing remain user-owned. Do not silently mark planned code as implemented.
