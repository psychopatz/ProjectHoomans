# Project Hoomans working rules

## Repository instruction-file hygiene

`AGENTS.md` is always-loaded repository policy. Keep it small, durable, and useful across unrelated goals.

- Never put the active goal, current phase, current Next Chunk, implementation progress, accepted-phase history, migration status, audit findings, or superseded instructions in this file.
- Goal-specific execution truth belongs under `docs/Jobs/<Goal>/`: use that job's roadmap for the full objective and gates, progress ledger for current state, and runbook/architecture documents for job-specific procedure and contracts.
- Do not preserve obsolete instructions here as `HISTORICAL`, `SUPERSEDED`, or `DO NOT EXECUTE`. Git history and job-local historical documents are the archive.
- The executable `/goal` bootstrap is delivered in ChatGPT. Do not create or update checked-in `GOAL_PROMPT.md` files unless the user explicitly changes this repository-wide policy.
- A phase or bounded implementation chunk is an execution unit, not the completion boundary for the parent goal.

## Project Zomboid mod layout

- Treat `Contents/mods/ProjectHoomans/42.20/` as the current Project Zomboid runtime layer. Executable Lua, lifecycle services, UI integrations, registries, and engine/API adapters belong under its `media/` tree.
- Treat `Contents/mods/ProjectHoomans/common/` as version-agnostic packaged content. Keep reusable declarative definitions, translations, animations, clothing, sounds, textures, and similar shared assets under its `media/` tree.
- Keep Build 42 JSON translations at `common/media/lua/shared/Translate/<LANG>/*.json`. Do not create a repository-root translation source tree outside the Project Zomboid mod.

## Protected calls

- Do not use `pcall` or `xpcall` for normal control flow, input validation, or engine-bug workarounds. Prefer explicit guards and direct fixes.
- Use a protected call only when an external or addon-owned callback is an unavoidable failure boundary after ordinary validation, and document that reason beside the call.

## Never stage a temporary directory under watched `media/`

Project Zomboid recursively watches every loaded mod's `media/` tree with `DebugFileWatcher`. A short-lived staging directory can break the watcher for the rest of the running session.

- While `ProjectZomboid64`/`ProjectZomboid` is running, only write or replace files under `Contents/mods/**/media/` in ways that create a file or rename a file into place.
- Never create a staging directory inside a watched `media/` tree, including `.Foo.lua.<pid>.<uuid>.tmpdir`-style directories.
- Treat `git checkout`, `git stash`, `rsync`, `unzip`, and tooling that stages directory swaps as potentially unsafe while the watched tree is live.
- If a staging directory is required, keep it outside `media/` or stop Project Zomboid first. Restarting the game is the only reliable way to re-arm a broken watcher.

## Git and concurrent-work policy

- Never create a new Git branch for ProjectHoomans work. This standing user rule also applies when coordinating PsychopatzCore and DynamicTrading.
- Use the existing `main` branch for authorized new work only after checking the actual local branch/HEAD, upstream/remote state, dirty worktree, worktrees, and concurrent edits.
- Remote GitHub state does not prove the user's local worktree is clean.
- Preserve unrelated user/agent work. Never use blind `git pull`, force-push, destructive reset, destructive rebase, automatic stash/discard, or conflict resolution that overwrites uncertain changes.
- If safe integration cannot be proven, report the concrete conflict or ownership ambiguity rather than creating another branch or discarding work.

## Native runtime and publication authority

- A Git commit or GitHub push is not Steam Workshop publication.
- Do not publish or republish Workshop content unless the user explicitly authorizes that action.
- Do not launch, drive, or require native Project Zomboid as part of ordinary developer-side acceptance unless the active user request explicitly assigns that work.
- When live SP/MP validation is user-owned, complete every developer-implementable code, harness, and regression gate before handing off the remaining live test.
