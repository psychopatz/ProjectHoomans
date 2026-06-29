---
name: monolith-decoupler
description: Decouples monolithic source files into focused modules while preserving load order, dependency behavior, and naming conventions. Use when asked to split a large file into scalable submodules, especially for Lua or Project Zomboid files with explicit require ordering.
---

# Monolith Decoupler

This skill standardizes how to break a large file into small, purpose-specific modules without changing behavior accidentally. It is designed for repository code that depends on explicit load order, shared namespaces, and stable entry-point filenames.

## When to use this skill

- Use this when the user asks to split, modularize, decouple, or refactor a monolithic file.
- Use this when a large file should become a foldered entry point plus submodules.
- Use this when the code relies on ordered `require` statements, shared namespace tables, or lazy module access.
- Use this when the user wants a proposed hierarchy and dependency map before implementation.
- Use this when working with Lua or Project Zomboid code where moving a file changes the `require` path and load behavior.

## How to use it

### 1. Read the target file and its callers first

- Read the full target file before proposing a split.
- Search for all direct `require` references to the current file path.
- Search for lazy runtime usage of the namespace the file exports.
- Identify whether the file is a hub already, a consumer, or both.
- Do not assume the current load path can move without updating callers.

### 2. Preserve behavior before optimizing structure

- Keep the public namespace and public function names unchanged unless the user explicitly requests API changes.
- Preserve lazy-loading behavior. If the original file uses `pcall(require, ...)` or nil-safe module lookup, keep that pattern.
- Avoid logic changes during the split. The goal is decoupling, not redesign.
- Keep external callers working with the same exported table.

### 3. Build the folder and naming scheme from the entry file

- Create a folder named after the entry file with the mod prefix removed and `.lua` removed.
- Example: `DC_ColonyCompanion.lua` becomes folder `ColonyCompanion`.
- Keep the original entry filename as the actual entry point inside that folder.
- Example: `Companion/ColonyCompanion/DC_ColonyCompanion.lua`.

### 4. Apply the naming rules consistently

- Convert underscore-separated descriptors to PascalCase when they are descriptor segments.
- Example: `Manager_Respawn` becomes `ManagerRespawn`.
- Keep the module prefix such as `DT`, `DC`, or `DTNPC` in the filename.
- Submodules should follow `Prefix_BaseName_ModuleName.lua`.
- Example: `DC_ColonyCompanion_CommanderValidation.lua`.
- Do not append `_logic` unless the user explicitly requests it.
- If the original file is already effectively a submodule, combine the base descriptor before appending the new role.
- Example: `DT_Trading_ItemUtils.lua` refactored further should become `DT_TradingItemUtils_Price.lua`, not a nested duplicate pattern.

### 5. Propose the hierarchy before editing when planning is requested

- Group functions by narrowly scoped responsibility, not by arbitrary size.
- Prefer many small provider modules over a few medium monoliths.
- Separate pure constants from behavior.
- Separate low-level data access from orchestration.
- Separate public API attachment from internal helper ownership when the file is complex.
- Show the user the proposed hierarchy before implementation if they ask for review or adjustment first.

### 6. Use a hub-and-spokes entry file

- The entry file should do only namespace bootstrap plus explicit ordered `require` statements.
- Load providers before consumers.
- Load public API wiring after lower-level internals are available.
- Return the same namespace table the original monolith returned.

Recommended pattern:

```lua
MyNamespace = MyNamespace or {}
MyNamespace.Feature = MyNamespace.Feature or {}

local Feature = MyNamespace.Feature

Feature.Internal = Feature.Internal or {}

require "Path/To/FeatureFolder/Prefix_Feature_Constants"
require "Path/To/FeatureFolder/Prefix_Feature_Internal"
require "Path/To/FeatureFolder/Prefix_Feature_ProviderA"
require "Path/To/FeatureFolder/Prefix_Feature_ProviderB"
require "Path/To/FeatureFolder/Prefix_Feature_ConsumerA"
require "Path/To/FeatureFolder/Prefix_Feature_Api"

return Feature
```

### 7. Prefer an internal shared table over wide forward declarations

- When modules need to share helpers, create a small internal table early.
- Attach provider functions onto that table in early-loaded modules.
- Let consumer modules call through the internal table.
- Only use forward declaration placeholders if a real cycle cannot be removed by load order.

Recommended pattern:

```lua
local Feature = MyNamespace.Feature
Feature.Internal = Feature.Internal or {}

local Internal = Feature.Internal

function Internal.GetThing()
    return value
end
```

This is preferred over scattering `local someFunction` placeholders across many files.

### 8. Split modules by role, not by line count alone

Good role examples:

- `Constants`
- `Internal`
- `RegistryAccess`
- `TimeAccess`
- `PlayerLookup`
- `FactionValidation`
- `DataAccess`
- `SoulStoreAccess`
- `LoadoutBuilder`
- `CommanderValidation`
- `ReturnFlow`
- `UpdateLoop`
- `ApiCommands`

Avoid vague buckets like:

- `Helpers2`
- `Misc`
- `Extra`
- `PartA`

### 9. Audit dependencies after moving the entry file

- If the entry file moves into a subfolder, direct `require` paths must be updated unless the user explicitly wants a compatibility shim.
- Search for the original require string and update all direct callers.
- Search for namespace usage to confirm lazy references still resolve after the new load order.
- Check whether other hubs depend on the old file path being loaded at a specific point.

### 10. Keep Project Zomboid load behavior intact

- Preserve the entry filename exactly when the user says it must remain the PZ entry point.
- Explicitly require submodules in the same order the monolith originally depended on local definitions.
- Keep optional integrations optional. Do not turn lazy integrations into hard requirements.
- If the original code tolerated missing modules or globals, keep that tolerance.

### 11. Validate after the split

- Check editor diagnostics on the new folder and any caller files you changed.
- Search for stale direct requires to the old path.
- Confirm the new folder contains the intended entry file and all submodules.
- If a Lua parser such as `luac` is available, run syntax checks on the new files.
- If parser tooling is unavailable, state that explicitly and rely on editor diagnostics plus targeted code review.
- Recommend runtime smoke testing for the highest-risk flows.

### 12. Report outcome clearly

- Summarize the new folder path and entry file.
- Mention caller require-path updates.
- Mention validation performed and any remaining validation gaps.
- If the user asked for planning only, stop at hierarchy and dependency analysis rather than editing.

## Practical checklist

1. Read the monolith.
2. Search direct requires and lazy namespace consumers.
3. Propose hierarchy if requested.
4. Create the folder named from the entry file without mod prefix.
5. Add the new entry hub inside that folder.
6. Add constants and internal shared-table modules first.
7. Add provider modules.
8. Add consumer and orchestrator modules.
9. Add public API wiring modules.
10. Update direct require callers.
11. Remove the old monolith only after the new entry path is live.
12. Validate diagnostics, stale references, and syntax where possible.

## Example application

For `DC_ColonyCompanion.lua`:

- Folder: `ColonyCompanion`
- Entry file: `DC_ColonyCompanion.lua`
- Submodules:
  - `DC_ColonyCompanion_Constants.lua`
  - `DC_ColonyCompanion_Internal.lua`
  - `DC_ColonyCompanion_PlayerLookup.lua`
  - `DC_ColonyCompanion_CommanderValidation.lua`
  - `DC_ColonyCompanion_UpdateLoop.lua`
  - `DC_ColonyCompanion_ApiCommands.lua`

This keeps the original feature namespace intact while making each responsibility independently editable and scalable.
Refactor the following file into modules for scalability. Follow these rules:
1. Naming: Convert underscores in descriptors to PascalCase (e.g., Manager_Respawn → ManagerRespawn).
2.Submodules: Use the format Prefix_ModuleName_logic (e.g.,DTNPC_ManagerRespawn_logic).
3. Create the folder that houses these files, on the previous example its "ManagerRespawn",The entry file is also housed in here for better organization so remove the ".lua" and mod prefix such as "DTNPC", "DC" or "DT".
4. PZ Loading: Keep [Filename].lua as the entry point. Name submodules [Filename]_[ModuleName].lua, if the previous file DT_Trading_ItemUtils.lua just combine them on the new version DT_TradingItemUtils_Price.lua since were refactoring a submodule already.
5.Entry point should explicitly require the modules in the correct order to maintain the same hierarchical loading as the original monolithic file. Dont forget to scan for its dependencies too since we moved it inside the folder. Avoid Making a Shim if not explicitly requested by the user. We should update the direct callers to the new path instead.
Analyze the file and show me the potential file hierarchy so that i can do some adjustments if i want to before we proceed.
