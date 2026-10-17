# Semantic Dialogue Orchestrator — current progress

**Date:** 2026-10-17. **Status:** planned/documentation only. **Current phase:** Phase 0 — collision reproduction and containment. **Runtime evidence:** not run for this new job.

## Evidence anchors
- Inspected ProjectHoomans main `c96cadda1570f59810552f9d3fc55d5c957ba670`.
- Existing ContextualSemanticIntelligence implementation branch observed at `fd852d746241d7e2f61df1c349ff63754afbe5ed` on 2026-10-17. Its progress ledger **reports** Phase 6/native SP/MP open, with previous bounded Semantic Lab tests passed; not independently rerun here.
- Parser wildcard `im + any_phrase`, competing self-state grammar, identity priority, evasion classifier and effect-bearing request path all verified in source. Exact screenshot test **not replayed** in this audit.
- No code, native game, Core parser or Semantic Lab implementation changed by this documentation job.

## One Next Chunk — Phase 0A screenshot reproduction + effect trace
1. Inspect local repo statuses, newest Hoomans/Core SHAs and PR dependencies. Coordinate ownership with existing semantic agent; do not modify its live branch/worktree.
2. Add/execute **one** focused real-Lua worker scenario reproducing: pending NPC name request -> `are you okay` -> NPC reciprocal wellbeing question -> `im fine thanks`. Record actual IR pattern, candidate when available, pending state, policy branch, identity request/transport and relationship deltas, including the exact Hoomans/Core revisions.
3. Add nearby control cases: `I'm fine thank you`, `im hungry`, explicit truthful name, explicit false name, unrelated question and preview-only turn. Identify which branch and lifecycle step owns wrongful mutation; check mocked identity authority vs actual game.
4. Preserve failing diagnostics and make an acceptance matrix before introducing a policy fix. If enough evidence is collected, advance to 0B: **smallest safe containment patch**, not flow engine implementation.

**Exit gate 0A:** production-worker reproduction characterized with trace and no ungrounded claims; expected outputs and effect differences documented. If current branch no longer reproduces, capture new evidence and revise next chunk rather than forcing a failure.

## After 0A
0B narrow containment -> 1 bounded typed candidates -> 2 flow kernel -> 3 identity/wellbeing modules -> 4 harness authoring -> 5 response composition -> 6 integration -> 7 native acceptance. Each gate needs separate recorded evidence. No runtime checks claimed in this planning commit.
