local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "client" } })

PNC = {}
local mode = "Multiplayer"
local save = "/home/player/Zomboid/Saves/Multiplayer/TestServer"
getWorld = function()
    return {
        getGameMode = function() return mode end,
        getWorld = function() return "Muldraugh, KY" end,
    }
end
getCurrentSaveName = function() return save end
getServerName = function() return "TestServer" end
getServerIP = function() return "127.0.0.1" end
getServerPort = function() return "16261" end

local identity = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Integrations/PNC_HoomansLLMIdentity.lua"
)
local multiplayer = identity.Current()
T.equal(multiplayer.world_mode, "multiplayer", "multiplayer mode")
T.equal(multiplayer.server_instance_id, "TestServer|127.0.0.1|16261",
    "stable multiplayer server identity")
T.equal(multiplayer.server_world_generation, "Multiplayer/TestServer",
    "portable multiplayer world generation")

mode = "Apocalypse"
save = "C:/Users/player/Zomboid/Saves/Apocalypse/Save One"
local singleplayer = identity.Current()
T.equal(singleplayer.world_mode, "singleplayer", "singleplayer mode")
T.equal(singleplayer.save_relative_path, "Apocalypse/Save One",
    "Windows save path normalized below Saves")

T.finish("pnc_hoomans_llm_identity_smoke")
