# Semantic Lab: PRIMARY agent test/debug surface

The user built the Semantic Lab so an agent can understand and change the **real production Lua dialogue path without loading Project Zomboid**. Restore that purpose. It is the PRIMARY developer-facing test/debugging interface. Final in-game SP/MP acceptance belongs to the user and is not a condition for Codex to finish implementation.

## Primary workflow

1. Inspect current `tools/semantic_harness/` and its GUI, session, worker, scenario adapter and module loader. Run the intended **visual/interface workflow**, not just a CLI/headless JSON case, where possible.
2. A successful usable harness must load actual Core/PNC Lua modules; visualize current flow branches and selected nodes, accept player utterances, show NPC reply text with selected EN/TL key, and expose IR candidates/eligibility, context, transport and flow before/after. Trace must come from production decisions, not reconstructed test-only Python logic.
3. If any harness layer is broken, repair **that existing layer** in the smallest practical change. Don't treat its brokenness as an excuse to abandon visualization or launch the game.
4. Run a short meaningful conversation: pending identity -> `are you okay` -> `im fine thanks` -> genuine explicit name. Assert **selected displayed reply and flow state**, no unintended identity/evasion transport, and current participant context; do not stop at JSON validity.
5. For new flows and multi-act replies, use the GUI plus the production worker to verify selected response pool, next node, rendered EN/TL text, translation provenance and single accepted commit.
6. Add narrow automated checks for the exact behavior being changed, only when they protect meaningful regressions. Headless-only tests, arbitrary script proliferation or larger passing test counts cannot substitute for an observable, working harness workflow.

## When interactive GUI cannot launch in Codex

Record exact GUI startup failure/environment and fix code-level issues where feasible. Use the **existing real-Lua worker** for focused decisions as a fallback development aid, plus static checks on UI integration. Continue other safe implementation chunks instead of repeatedly polling for a desktop/PZ surface or declaring the goal blocked merely because no GUI display is attached.

For interface usability not verifiable in that environment, provide a short **user-run Semantic Lab verification procedure** in PROGRESS, clearly marked pending. Do not represent an unrun GUI interaction as a pass; keep the implementation moving on independent tasks.

## Existing baseline failures

Historical report: Python 97/97, targeted Lua 68/68, full headless Lua suite with 12 failures and one stale Core translation-key count assertion. Preserve labels and investigate only relevant failures that affect the changed conversation/translation path. Never hide, exempt or delete failures to claim success, but do not let unrelated native-mock headless failures stop meaningful work.

## Completion gate for a development chunk

A concrete production Lua behavior change, accurate harness GUI/worker trace where available, focused regressions, EN/TL verification when relevant, no unauthorized side effects, a short evidence record (source SHAs, tests actually run, observed outcomes), and one bounded Next Chunk. **No native PZ process or Workshop upload required.**

Final live-game acceptance is a **USER HANDOFF**, not a Codex implementation gate. See `USER_LIVE_TEST_HANDOFF.md`.
