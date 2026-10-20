# Project Hoomans working rules

## Project Zomboid mod layout

- Treat `Contents/mods/ProjectHoomans/42.20/` as the current
  Project Zomboid runtime layer. Executable Lua, lifecycle services, UI
  integrations, registries, and engine/API adapters belong under its `media/`
  tree.
- Treat `Contents/mods/ProjectHoomans/common/` as version-agnostic packaged
  content. Keep reusable declarative definitions, translations, animations,
  clothing, sounds, textures, and similar shared assets under its `media/`
  tree.
- Keep Build 42 JSON translations at
  `common/media/lua/shared/Translate/<LANG>/*.json`. Do not create a
  repository-root translation source tree outside the Project Zomboid mod.

- Do not use `pcall` or `xpcall` for normal control flow, input validation, or
  engine-bug workarounds. Prefer explicit guards and direct fixes.
- Use a protected call only when an external or addon-owned callback is an
  unavoidable failure boundary after ordinary validation, and document that
  reason beside the call.

## Never stage a write through a temporary directory under `media/`

Project Zomboid recursively watches every loaded mod's `media/` tree with
`DebugFileWatcher`. On a directory `ENTRY_CREATE` it walks that directory; if
the directory is already gone it logs `NoSuchFileException`, sets its internal
`WatchService` to `null`, and every later `update()` throws
`NullPointerException: ... "this.watcher" is null` for the rest of the session.
The engine never re-initializes the watcher, so mod hot-reload stays dead until
the game is restarted.

- While `ProjectZomboid64`/`ProjectZomboid` is running, only write or replace
  files under `Contents/mods/**/media/` in ways that create a *file* or rename
  a file into place.
- Never create a staging *directory* inside a watched `media/` tree, e.g.
  `.Foo.lua.<pid>.<uuid>.tmpdir` next to the target file. Such a directory
  lives for about a millisecond and is exactly what trips the engine.
- `git checkout`, `git stash`, `rsync`, `unzip`, and tooling that stages
  directory swaps (agent file writers, sync tools) are the same hazard.
- If a staging directory is required, keep it outside `media/`, or stop
  Project Zomboid first. Restarting the game is the only way to re-arm the
  watcher.

## No-new-branches and safe main integration (user rule, 2026-10-20)

**NEVER CREATE A NEW GIT BRANCH** for implementation, test, audit, documentation, agent work or pull request. Do not use `git checkout -b`, `git switch -c`, `git branch <new>`, a scratch worktree branch, or agent automatic branch creation. This rule also applies when coordinating PsychopatzCore and DynamicTrading.

For new authorized work use **existing `main`**, after checking local and remote HEAD/upstream and concurrent changes. Do not assume existing PR history is present in main. As of 2026-10-20, existing `docs/contextual-dialogue-quest-framework-20261018` branch / PR #4 is 144 commits ahead and 1 behind main; preserve it and reconcile safely using `fetch`/`merge-base`/`merge-tree`/source diff, then merge onto existing main only when conflicts, dependencies and tests are resolved. No new integration branch, blind pull, force push, destructive reset/rebase/stash or overwritten agent/user work. If safe integration cannot be proven, report the precise conflict and continue independent work on an already existing checked-out ref; do NOT create another branch.

Root `AGENTS.md` is durable policy, not authority to publish Steam Workshop content or launch native Project Zomboid. For the ongoing personal NPC dialogue/backstory goal, detailed documentation currently lives on the **preexisting** Hoomans PR #4 branch at `docs/Jobs/ContextualDialogueQuestFramework/`. Full developer B0–B6 acceptance, not a passing B0 subphase, determines the parent goal handoff. Review that goal's `GIT_INTEGRATION_AND_NO_NEW_BRANCHES.md` before any integration.

