# Semantic Dialogue Decoupling — Codex operating policy

## Authority: implement + test in Semantic Lab, then user handoff

**The user exclusively owns final Project Zomboid live tests** and all Steam Workshop publishing decisions. This agent is authorized to work on source, tests, the Semantic Lab interface and normal safe Git operations in the already authorized repositories. A local path containing `Workshop` is simply a workspace directory, not publishing consent.

**Never** run Steam Workshop upload/republish, steamcmd, workshop packaging/release, PZ start/restart, PZ process/app polling, MP host setup or native-game acceptance loops. Never request Workshop publication authorization as a condition for ordinary development. Never set `blocked` just because `apps=[]`, PZ isn't running, or SP/MP isn't tested.

## One goal / Git safety
- Work in existing checkout; read `AGENTS.md`. Inspect actual Hoomans/Core status, heads, upstream, uncommitted changes and ownership. Do not overwrite the user's radio asset/harness JSON files or unrelated edits.
- No new branch/PR. Normal source commits to `main` only when already authorized and fast-forward-safe; a Git commit/push is **NOT** a Workshop upload. Check Core-specific Git authorization independently; never force/reset/stash unrelated work, never ambiguous `git pull`.
- Maintain just `docs/Jobs/SemanticDialogueDecoupling/PROGRESS.md` and `ROADMAP.md`, not separate dialogue/translation goals. `IMPLEMENTATION_EVIDENCE.md` remains historical.

## Execution loop
1. Read root AGENTS and all this job's current docs, then verify current local code. Prefer current source over historical progress prose.
2. Complete one bounded Next Chunk. When a Core API is already present, don't spend another phase waiting for publication; if a true local mismatch exists, make the narrow compatible source correction (with Core authorization).
3. Use **existing Semantic Lab GUI + real production Lua worker** as the primary agent debugging/testing interface. Repair its viewer, module loader, state injection or UI if needed. Don't create redundant harnesses or endless headless JSON fixture tests.
4. Make a concrete production-path improvement (flow reply ownership, real branch authoring, composition). Confirm selected actual responses, transitions, state and side effects using harness. Preserve the identity regression and server-authoritative gameplay domains.
5. Run focused automated tests for real modified behavior; classify unrelated full headless suite failures honestly. If no GUI display, work on verified code/harness startup defects, use production Lua worker as fallback and record GUI pending without treating it as a general blocker.
6. Update PROGRESS with actual tests run, selected reply/context evidence, Git SHAs, limitations and one Next Chunk. Continue phase sequence autonomously without asking the user to start PZ.
7. When D0–D5 implementation gates are complete, prepare `USER_LIVE_TEST_HANDOFF.md`, mark `READY FOR USER LIVE TEST`, stop. Native SP/MP remains user-owned and **not a Codex failure**.

## Safety
Offline Lua without PBrainZ, Parser/IR compatibility, context-bounded preview/commit, names/needs/relationships and multiplayer action admission, MarketSense, EN/TL translation keys, Build 42 watch-dir precautions. No routine protected-call blanket, runtime WordNet scanning, per-tick full-NPC semantic loops or duplicate response engine.

## True blockers
Unsafe conflicting worktree changes, unavailable *necessary* source/toolchain capability with no safe alternative, or missing authorized Git access. Not native game availability, Workshop publication, unrelated headless fixture failures, or the need for a later user live test.
