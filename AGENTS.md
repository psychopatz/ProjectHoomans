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
