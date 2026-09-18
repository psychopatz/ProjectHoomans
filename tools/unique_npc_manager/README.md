# Unique NPC Manager

This is a desktop Tkinter authoring tool for Project Hoomans. It manages the
JSON wrapper files produced by the in-game creator and emits one
self-registering Lua catalog for the game runtime.

```bash
./tools/run_unique_npc_manager.sh
```

The default folders are:

- definition root: `~/Zomboid/Lua/Hoomans`
- Unique NPC definitions: `~/Zomboid/Lua/Hoomans/NPC Definitions`
- shared definition index: `~/Zomboid/Lua/Hoomans/UniqueNPCIndex.txt`
- runtime Lua: `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Generated/UniqueNPC`

Project Hoomans keeps other authoring kinds beside the NPC files. Puppet Opera
definitions use `Hoomans/Opera Definitions`; both folders are indexed by the
same root index without sharing filenames.

The game imports one stable catalog:

```lua
require "PNC/Generated/UniqueNPC/PNC_UniqueNPCDefinitions"
```

The manager rebuilds that catalog whenever generated definitions change. Every
normalized definition is embedded in the catalog, so no per-NPC `require`
statement or generated child Lua file is needed. Do not edit generated Lua
directly; edit the Hoomans draft and export it again.

Deleting a draft permanently removes its source file and rebuilds the catalog;
the manager does not maintain a trash copy.

Appearance clothing is authored separately from loose inventory. An explicit
appearance slot carries the item type, worn location, and native `itemState`
metadata; this is what preserves colors, textures, decals, and model choices.
An authored item/none slot suppresses the archetype or named-outfit clothing.
