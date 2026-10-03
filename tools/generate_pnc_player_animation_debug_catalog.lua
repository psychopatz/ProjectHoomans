-- Generates the player-animation debug catalog from the vanilla player
-- actions/emotes and the Project Hoomans player/zombie AnimSets. Run from the
-- ProjectHoomans repository root with the installed Project Zomboid root as
-- the first argument. The stable command-line entry delegates to ordered,
-- cohesive providers under tools/pnc_player_animation_debug_catalog/.

local providerRoot = "tools/pnc_player_animation_debug_catalog"
local function loadProvider(name)
    return dofile(providerRoot .. "/" .. name .. ".lua")
end

local config = loadProvider("Config").build(arg)
local source = loadProvider("Source").collect(config)
local policy = loadProvider("Policy").configure(config, source)
local bridge = loadProvider("Bridge").configure(config, policy)
local catalog = loadProvider("Catalog").configure(config, source, policy, bridge)
local result = catalog.build()

bridge.removeStale(config.bridgeRoot, "actions/", result.generatedBridgeFiles)
bridge.removeStale(config.emoteBridgeRoot, "emote/", result.generatedBridgeFiles)
catalog.write(result)
