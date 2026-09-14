# Unique NPC Manager

This is a desktop Tkinter authoring tool for Project Hoomans. It manages the
JSON wrapper files produced by the in-game creator and emits self-registering
Lua modules for the game runtime.

```bash
./tools/run_unique_npc_manager.sh
```

The default folders are:

- drafts: `~/Zomboid/Lua/Hoomans`
- runtime Lua: `Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Generated/UniqueNPC`

The game imports one stable loader:

```lua
require "PNC/Generated/UniqueNPC/PNC_UniqueNPCDefinitions"
```

The manager rebuilds that loader whenever generated definitions change. Do not
edit generated Lua directly; edit the Hoomans draft and export it again.

Runtime modules use the survivor's canonical name, for example
`RobertFurhrer.lua`. The stable definition ID is embedded in each generated
module, so a renamed legacy module can be migrated without changing the NPC's
identity. If two definitions have the same name, the manager adds a
deterministic ID suffix to the second filename.

Appearance clothing is authored separately from loose inventory. An explicit
appearance slot carries the item type, worn location, and native `itemState`
metadata; this is what preserves colors, textures, decals, and model choices.
An authored item/none slot suppresses the archetype or named-outfit clothing.
