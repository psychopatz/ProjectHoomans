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

## Git branch policy — permanent user instruction (2026-10-20)

**DO NOT CREATE ANY NEW GIT BRANCHES.** This includes feature/docs/test branches, temporary staging branches, Codex-generated work branches, `git checkout -b`, `git switch -c`, `git branch <name>`, and any automated PR branch-creation path. The user has explicitly prohibited new branches for this repository and its Core/DynamicTrading dependencies.

Use the existing `main` branch for future implementation, documentation and integration only after verifying local changes, current remote HEAD/upstreams, ownership and safe compatibility. **Legacy already-existing branches are not permission to create more.** The existing `docs/contextual-dialogue-quest-framework-20261018` branch and PR #4 hold 144 commits ahead of and one behind `main` as observed on 2026-10-20. Preserve this history. Before moving work to `main`, inspect `git fetch`, `git merge-base`, `git log --left-right`, `git diff`, test a merge without changing working tree using `git merge-tree`, and validate actual source/conflicts and dependencies. Integrate/merge into the EXISTING `main` branch only when safe; no rewrite, rebase/reset of uncertain user work, force push, blind `git pull`, or replacement branch. If unsafe, report the exact blocking files/dependencies and continue only work safely allowed on the already-existing checked-out branch until safe reconciliation is possible. Do not claim work on an unmerged branch is published to main.

For any direct push, require explicit durable authorization to the destination and a checked clean/safely-owned tree, fast-forward-compatible remote and matching expected HEAD; never infer a clean local checkout from GitHub remote state. This documentation rule does NOT authorize Workshop publication or native Project Zomboid launching.
