# Existing-main-only Git integration policy

**User instruction:** Absolutely NO new Git branches and no continuing new implementation commits on the legacy development branch. Target the already-existing `main` for authorized development; do not use new PR, test, merge, scratch, worktree or automatic agent branches. Do not run an ambiguous `git pull` (especially `git pull --tags origin docs/contextual-dialogue-quest-framework-20261018`). No blind rebase, reset, force push, stash/discard or overwrite of user/other-agent work.

## Audited remote state before this documentation commit (2026-10-20)

- Hoomans `main`: `baec079e9718606f8510f72fb129f4cd82ae24db`; job docs did NOT exist there before this update.
- Existing dev history `docs/contextual-dialogue-quest-framework-20261018`: `4755622022f244f9cd890039b705c0badf0cf57a` with B0–B6 code, acceptance ledger and a **legacy checked-in `GOAL_PROMPT.md`**. The legacy file is historical and MUST NOT be copied or maintained on main. User receives actual prompt in chat only.
- Existing PR #4 open/unmerged, `mergeable=false` at inspection; this does not establish what local worktrees contain or exactly which files conflict.
- Core `main`: `2179ee19307a993e186e6da661ad4212e984e0b4`; DT source state must be inspected again at execution time.

## Required safe process

1. Inspect local `git status --porcelain=v1 -b`, `git branch -vv`, worktrees, exact upstream/remotes, `git fetch origin`, `git log --left-right`, `git diff` and `git merge-base` of preexisting history versus main. Never assume a clean local branch from a remote result. Do not create/checkout a newly created branch.
2. Analyze conflict possibilities with read-only `git merge-tree` (and inspect commit/diff), including changed `AGENTS.md`, docs, generated media, backstory/Knowledge, CodeBuilder and translations; coordinate source ownership with existing parallel work. Main has the NEW current docs; old branch's obsolete `PROGRESS.md` and checked-in `GOAL_PROMPT.md` must not overwrite/recreate them.
3. If safe, bring necessary old source and history into already-existing `main` using a reviewed merge or exact file-level integration without discarding other legitimate commits. Carefully resolve documentation conflicts toward CURRENT main docs and user rules; verify generated assets, scripts, manifest and source behavior. Run real targeted worker/harness before any remote publish. Apply only allowed fast-forward-safe main push.
4. If unsafe, report exact conflicting files/dependencies and complete only nonconflicting work safely on main. Do not continue new feature development on another branch as a workaround and never claim finished-main integration until verified.
5. Track exact Core and DT pairing and never require Workshop republication, installation or native PZ startup as part of developer acceptance.

Historical B0–B6 source/ledger must be preserved, but the active task is H0–H4 full harness-first authoring/localization/privacy acceptance. User prompt is **chat-only**.
