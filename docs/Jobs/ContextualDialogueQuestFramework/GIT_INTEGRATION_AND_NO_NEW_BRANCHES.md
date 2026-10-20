# Repository publication and no-new-branches contract

**Active durable user instruction, 2026-10-20: create ZERO new Git branches.** Prefer the existing `main` branch as the final implementation destination; preserve existing branch commits until safely integrated. There is no need to create a docs branch, PR branch, scratch branch, Codex workspace branch or temporary merge branch. Do not use automatic agent branch creation.

## Audited GitHub state at documentation transition

- ProjectHoomans `main`: `bc9c64d0fbf6cdefb0e63c242ac028e0ce2796c1`.
- Existing (NOT newly created) Hoomans `docs/contextual-dialogue-quest-framework-20261018`: `9b123bd352b0e08ec7a60d6748e01ef322656cf2`; PR #4 open, unmerged. Github comparison: `ahead_by=144`, `behind_by=1` against `main`. PR is marked mergeable by GitHub at inspection, but that does NOT verify source/test compatibility.
- PsychopatzCore `main`: `298df66381b7c04475074ef947362b96fed0e9bc`, with developer-accepted P1–P9 Foundation code but no native game acceptance.
- DynamicTrading `main`: `2d1ee62a227062457e8b233e37a7e288c6351a66`, with related provider adapters.

These are remote snapshots, NOT local working-tree evidence. Independently inspect local/upstream state before every write.

## Existing branch -> main safe reconciliation, NOT a new goal phase

1. Inspect all three checked out repositories, any concurrent changes, exact upstream and new commits. `fetch` but no ambiguous pull/reset/rebase/force. Inspect what the existing PR/branch contains, paying special attention to previously changed engine media, translations and test harnesses.
2. Perform conflict analysis without creating a branch or touching watched `media/` directories (e.g. `git merge-base`, `git diff`, `git log --left-right`, `git merge-tree`).
3. If source ownership and correct dependency pairing are confirmed and integration is safe, merge using **existing main**, run actual relevant Hoomans/Core/DT Lua/harness checks, commit and publish only to already authorized `main`; no new branch or Workshop operation.
4. If merging the extensive divergent history is unsafe or clashes with parallel work, do NOT force/rebase/squash away ownership or invent a new branch. Record concrete conflicts and complete independent permitted work on the already-existing checked-out ref. Resolve/reconcile into existing main when safe.
5. After integration, maintain code and `docs/Jobs/ContextualDialogueQuestFramework/` on existing `main`. Do not prematurely delete PR/branch; ensure no commits or data are lost and do not claim merge before confirming GitHub main SHA.

## Goal continuity

The complete active user product goal is B0–B6 grounded personal dialogue, not merely the Foundation P1–P9 or one B0 correction. One safe implementation chunk per iteration, **automatic continuation** after each accepted chunk; final developer READY only when everything in B0–B6 passes. Native SP/MP and Workshop actions are user-owned. User can authorize further Git changes on existing refs, not new branch creation.
